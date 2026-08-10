// ============================================================================
// spi_slave.v  -  TWO-CLOCK-DOMAIN SPI slave that instantiates axi_master.
//
//   External ports: clk, rst_n (single async reset), and the 4 SPI pins.
//   SPI: mode 1 (CPOL=0, CPHA=1) - sample MOSI on sclk FALLING, drive MISO on
//        sclk RISING; MSB-first; active-low cs_n. 40-bit frame:
//          bits 39..32 = command {rw, addr[6:0]}   (rw=1 write, 0 read)
//          bits 31..0  = 32-bit data (write: MOSI ; read: MISO)
//
//   Two clock domains:
//     * sclk domain : receive shift reg + counter (negedge), MISO shift (posedge)
//     * clk  domain : command FSM + embedded axi_master (-> axi_ascon -> core)
//   A reset synchronizer sits in EACH domain (fed by the one async rst_n pin).
//   Crossings: sclk->clk via toggle + 2FF sync (write frame, and read request);
//              clk->sclk read data is a held bus, sampled once when stable.
//
//   TIMING REQUIREMENT: sclk <= clk/20 (so a read completes in the half-bit
//   gap before its data shifts out on MISO). At clk=25 MHz use sclk <= ~1 MHz.
//   No functions/tasks in synthesizable RTL.
// ============================================================================

module spi_slave (
    input  wire clk,
    input  wire rst_n,      // single asynchronous, active-low reset pin
    input  wire sclk,
    input  wire mosi,
    output reg  miso,
    input  wire cs_n
);
    // ---- reset synchronizers: one per clock domain -------------------------
    wire rst_n_clk, rst_n_spi;
    reset_sync u_rs_clk (.clk(clk),  .arst_n(rst_n), .srst_n(rst_n_clk));
    reset_sync u_rs_spi (.clk(sclk), .arst_n(rst_n), .srst_n(rst_n_spi));

    wire cs_active = ~cs_n;

    // read result produced by the clk domain, consumed by the sclk TX side
    reg  [31:0] rd_data_clk;

    // =======================================================================
    // STAGE 1 - sclk domain, RECEIVE (sample MOSI on falling edge)
    // =======================================================================
    reg  [39:0] rx_sr;      // receive shift register (MSB-first)
    reg  [5:0]  bitcnt;     // received-bit index 0..39
    reg  [39:0] frame_hold; // full frame, captured for writes
    reg         is_read;    // latched rw of the current frame (1 = read)
    reg  [6:0]  rd_addr_s;  // latched read address
    reg         wreq_tgl;   // write-request toggle  -> clk domain
    reg         rreq_tgl;   // read-request toggle   -> clk domain

    // command byte becomes complete as the 8th bit (bitcnt==7) is sampled:
    wire        cmd_rw   = rx_sr[6];             // becomes command bit 7 (rw)
    wire [6:0]  cmd_addr = {rx_sr[5:0], mosi};   // becomes command bits 6..0

    always @(negedge sclk or negedge rst_n_spi) begin
        if (!rst_n_spi) begin
            rx_sr<=0; bitcnt<=0; frame_hold<=0; is_read<=0; rd_addr_s<=0;
            wreq_tgl<=0; rreq_tgl<=0;
        end else if (cs_active) begin
            rx_sr  <= {rx_sr[38:0], mosi};       // shift MOSI in, MSB-first
            bitcnt <= bitcnt + 6'd1;
            if (bitcnt == 6'd7) begin            // command byte just completed
                is_read   <= ~cmd_rw;
                rd_addr_s <= cmd_addr;
                if (~cmd_rw) rreq_tgl <= ~rreq_tgl;   // READ: request AXI read NOW
            end
            if (bitcnt == 6'd39) begin           // full 40-bit frame complete
                frame_hold <= {rx_sr[38:0], mosi};
                if (~is_read) wreq_tgl <= ~wreq_tgl;  // WRITE: request AXI write
            end
        end else begin
            bitcnt <= 6'd0; rx_sr <= 40'd0;      // cs high: idle / clear
        end
    end

    // =======================================================================
    // STAGE 2 - sclk domain, TRANSMIT (drive MISO on rising edge)
    // =======================================================================
    reg [5:0]  txcnt;       // rising-edge index 0..39
    reg [31:0] miso_sr;     // MISO shift register (read data)

    always @(posedge sclk or negedge rst_n_spi) begin
        if (!rst_n_spi) begin
            txcnt<=0; miso_sr<=0; miso<=0;
        end else if (cs_active) begin
            txcnt <= txcnt + 6'd1;
            if (txcnt == 6'd8) begin             // first data bit: grab read result
                miso    <= rd_data_clk[31];      // rd_data_clk is stable by now
                miso_sr <= {rd_data_clk[30:0], 1'b0};
            end else if (txcnt > 6'd8) begin     // shift out remaining 31 data bits
                miso    <= miso_sr[31];
                miso_sr <= {miso_sr[30:0], 1'b0};
            end else begin
                miso    <= 1'b0;                 // command phase: MISO idle
            end
        end else begin
            txcnt<=0; miso<=1'b0;
        end
    end

    // =======================================================================
    // STAGE 3 - CDC sclk -> clk : synchronize request toggles, edge-detect
    // =======================================================================
    reg r0,r1,r2, w0,w1,w2;
    always @(posedge clk or negedge rst_n_clk) begin
        if (!rst_n_clk) begin r0<=0;r1<=0;r2<=0; w0<=0;w1<=0;w2<=0; end
        else begin
            r0<=rreq_tgl; r1<=r0; r2<=r1;        // 2-FF sync (+1 for edge detect)
            w0<=wreq_tgl; w1<=w0; w2<=w1;
        end
    end
    wire rd_pulse = r1 ^ r2;                     // 1-clk pulse per read request
    wire wr_pulse = w1 ^ w2;                     // 1-clk pulse per write request

    // =======================================================================
    // STAGE 4 - clk domain : command FSM driving axi_master's command bus
    // =======================================================================
    localparam [1:0] C_IDLE=2'd0, C_ISSUE=2'd1, C_WAIT=2'd2;
    reg  [1:0]  cst;
    reg         cmd_valid;  wire cmd_ready;
    reg         cmd_write;  reg [6:0] cmd_addr_q;  reg [31:0] cmd_wdata_q;
    wire        cmd_done;   wire [31:0] cmd_rdata;

    always @(posedge clk or negedge rst_n_clk) begin
        if (!rst_n_clk) begin
            cst<=C_IDLE; cmd_valid<=0; cmd_write<=0;
            cmd_addr_q<=0; cmd_wdata_q<=0; rd_data_clk<=0;
        end else begin
            case (cst)
                C_IDLE: begin
                    if (rd_pulse) begin          // read: rd_addr_s is stable
                        cmd_write<=1'b0; cmd_addr_q<=rd_addr_s;
                        cmd_valid<=1'b1; cst<=C_ISSUE;
                    end else if (wr_pulse) begin // write: frame_hold is stable
                        cmd_write<=1'b1; cmd_addr_q<=frame_hold[38:32];
                        cmd_wdata_q<=frame_hold[31:0];
                        cmd_valid<=1'b1; cst<=C_ISSUE;
                    end
                end
                C_ISSUE: if (cmd_ready) begin cmd_valid<=1'b0; cst<=C_WAIT; end
                C_WAIT:  if (cmd_done) begin
                             if (!cmd_write) rd_data_clk <= cmd_rdata;
                             cst<=C_IDLE;
                         end
                default: cst<=C_IDLE;
            endcase
        end
    end

    // =======================================================================
    // STAGE 5 - embedded AXI master (clk domain) -> axi_ascon -> core -> round
    // =======================================================================
    axi_master u_master (
        .clk(clk), .rstn(rst_n_clk),
        .cmd_valid(cmd_valid), .cmd_ready(cmd_ready), .cmd_write(cmd_write),
        .cmd_addr(cmd_addr_q), .cmd_wdata(cmd_wdata_q),
        .cmd_done(cmd_done), .cmd_rdata(cmd_rdata)
    );
endmodule
