// ============================================================================
// axi_ascon.v  -  AXI4-Lite slave wrapper around ascon_core (NIST SP 800-232)
//
// This is the "Ascon accelerator IP": an AXI4-Lite slave (32-bit data,
// 7-bit byte address) that any AXI master (e.g. a RISC-V) can drive through
// a simple register map. Internally it instantiates the verified ascon_core
// and bridges the CPU's register-poll model to the core's valid/ready streams.
//
// Register map (byte offsets; each 128-bit value = 4 little-endian words):
//   0x00-0x0C  KEY0..3    (W)
//   0x10-0x1C  NONCE0..3  (W)
//   0x20       CTRL       (W)  bit0 start, bit1 dec_mode, bit2 ad_empty
//   0x24       STATUS     (R)  bit0 busy,bit1 done,bit2 auth_ok,
//                              bit3 in_ready,bit4 dout_ready
//   0x28       BLK        (W)  bit0 stream(0=AD,1=data), bit1 last,
//                              bits[6:2] bytes(0..16)
//   0x30-0x3C  DIN0..3    (W)  writing DIN3 pushes the assembled block
//   0x40-0x4C  DOUT0..3   (R)  reading DOUT3 drains the captured block
//   0x50-0x5C  TAG0..3    (R/W) write before decrypt; read after encrypt
//
// Design notes:
//  - dout_valid from the core pulses for ONE cycle -> captured into dout_sh.
//  - Interlock: a data block is not fed (din_valid) while a previous output
//    is still pending, so the CPU can never lose an output block.
//  - The core does its own padding; the wrapper feeds raw bytes + a byte count.
//  - No Verilog functions or tasks (matches the project style).
// ============================================================================

module axi_ascon (
    input  wire        S_AXI_ACLK,
    input  wire        S_AXI_ARESETN,
    // write address channel
    input  wire [6:0]  S_AXI_AWADDR,
    input  wire [2:0]  S_AXI_AWPROT,
    input  wire        S_AXI_AWVALID,
    output reg         S_AXI_AWREADY,
    // write data channel
    input  wire [31:0] S_AXI_WDATA,
    input  wire [3:0]  S_AXI_WSTRB,
    input  wire        S_AXI_WVALID,
    output reg         S_AXI_WREADY,
    // write response channel
    output reg [1:0]   S_AXI_BRESP,
    output reg         S_AXI_BVALID,
    input  wire        S_AXI_BREADY,
    // read address channel
    input  wire [6:0]  S_AXI_ARADDR,
    input  wire [2:0]  S_AXI_ARPROT,
    input  wire        S_AXI_ARVALID,
    output reg         S_AXI_ARREADY,
    // read data channel
    output reg [31:0]  S_AXI_RDATA,
    output reg [1:0]   S_AXI_RRESP,
    output reg         S_AXI_RVALID,
    input  wire        S_AXI_RREADY
);
    // ---- register/shadow storage -------------------------------------------
    reg [31:0] key0,key1,key2,key3;
    reg [31:0] non0,non1,non2,non3;
    reg [31:0] tagw0,tagw1,tagw2,tagw3;   // expected tag (decrypt input)
    reg [31:0] blk0,blk1,blk2,blk3;       // shared input-block shadow
    reg        dec_q, adempty_q;
    reg        blk_sel, blk_last;
    reg [4:0]  blk_bytes;
    reg        start_pulse;

    // ---- bridge flags / output buffer --------------------------------------
    reg         blk_pending, dout_pending, done_sticky, authok_q;
    reg [127:0] dout_sh;
    reg [4:0]   dout_b;       // valid-byte count of captured output (status/debug)
    reg         dout_l;
    reg [31:0]  tagr0,tagr1,tagr2,tagr3;  // latched tag result (encrypt)

    // ---- AXI handshake bookkeeping ------------------------------------------
    reg        aw_hs, w_hs, ar_hs;
    reg [6:0]  awaddr_q, araddr_q;
    reg [31:0] wdata_q;

    // ---- core connections ---------------------------------------------------
    wire        core_ad_ready, core_din_ready;
    wire        core_dout_valid, core_dout_last;
    wire [127:0]core_dout_data;
    wire [4:0]  core_dout_bytes;
    wire        core_busy, core_done, core_auth;
    wire [63:0] core_t0, core_t1;

    wire [127:0] blk_data   = {blk3,blk2,blk1,blk0};
    wire         ad_valid_w  = blk_pending & ~blk_sel;
    wire         din_valid_w = blk_pending &  blk_sel & ~dout_pending; // interlock
    wire         ad_consume  = ad_valid_w  & core_ad_ready;
    wire         din_consume = din_valid_w & core_din_ready;

    ascon_core_adpt_encdec u_core (
        .clk(S_AXI_ACLK), .rst_n(S_AXI_ARESETN),
        .start(start_pulse), .dec_mode(dec_q),
        .k0_in({key1,key0}),  .k1_in({key3,key2}),
        .n0_in({non1,non0}),  .n1_in({non3,non2}),
        .tag0_in({tagw1,tagw0}), .tag1_in({tagw3,tagw2}),
        .ad_empty(adempty_q), .ad_valid(ad_valid_w), .ad_last(blk_last),
        .ad_data(blk_data),  .ad_bytes(blk_bytes), .ad_ready(core_ad_ready),
        .din_valid(din_valid_w), .din_last(blk_last), .din_data(blk_data),
        .din_bytes(blk_bytes), .din_ready(core_din_ready),
        .dout_valid(core_dout_valid), .dout_last(core_dout_last),
        .dout_data(core_dout_data),   .dout_bytes(core_dout_bytes),
        .busy(core_busy), .done(core_done), .auth_ok(core_auth),
        .t0_out(core_t0), .t1_out(core_t1)
    );

    // ---- single sequential block: AXI slave + bridge glue ------------------
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY<=0; S_AXI_WREADY<=0; S_AXI_BVALID<=0; S_AXI_BRESP<=0;
            S_AXI_ARREADY<=0; S_AXI_RVALID<=0; S_AXI_RRESP<=0; S_AXI_RDATA<=0;
            aw_hs<=0; w_hs<=0; ar_hs<=0; awaddr_q<=0; araddr_q<=0; wdata_q<=0;
            key0<=0;key1<=0;key2<=0;key3<=0; non0<=0;non1<=0;non2<=0;non3<=0;
            tagw0<=0;tagw1<=0;tagw2<=0;tagw3<=0; blk0<=0;blk1<=0;blk2<=0;blk3<=0;
            dec_q<=0; adempty_q<=0; blk_sel<=0; blk_last<=0; blk_bytes<=0;
            start_pulse<=0; blk_pending<=0; dout_pending<=0; done_sticky<=0;
            authok_q<=0; dout_sh<=0; dout_b<=0; dout_l<=0;
            tagr0<=0;tagr1<=0;tagr2<=0;tagr3<=0;
        end else begin
            start_pulse <= 1'b0;                       // one-cycle pulse default

            // ----- glue: clear pending input on consume -----
            if (ad_consume | din_consume) blk_pending <= 1'b0;

            // ----- glue: capture single-cycle core output -----
            if (core_dout_valid) begin
                dout_sh <= core_dout_data; dout_b <= core_dout_bytes;
                dout_l  <= core_dout_last; dout_pending <= 1'b1;
            end

            // ----- glue: latch results on done -----
            if (core_done) begin
                done_sticky <= 1'b1; authok_q <= core_auth;
                tagr0 <= core_t0[31:0];  tagr1 <= core_t0[63:32];
                tagr2 <= core_t1[31:0];  tagr3 <= core_t1[63:32];
            end

            // ================= AXI WRITE =================
            if (!aw_hs && S_AXI_AWVALID && !S_AXI_AWREADY) S_AXI_AWREADY<=1'b1;
            else                                           S_AXI_AWREADY<=1'b0;
            if (S_AXI_AWREADY && S_AXI_AWVALID) begin aw_hs<=1'b1; awaddr_q<=S_AXI_AWADDR; end

            if (!w_hs && S_AXI_WVALID && !S_AXI_WREADY) S_AXI_WREADY<=1'b1;
            else                                        S_AXI_WREADY<=1'b0;
            if (S_AXI_WREADY && S_AXI_WVALID) begin w_hs<=1'b1; wdata_q<=S_AXI_WDATA; end

            if (aw_hs && w_hs && !S_AXI_BVALID) begin
                case (awaddr_q[6:2])
                    5'd0:  key0<=wdata_q;  5'd1:  key1<=wdata_q;
                    5'd2:  key2<=wdata_q;  5'd3:  key3<=wdata_q;
                    5'd4:  non0<=wdata_q;  5'd5:  non1<=wdata_q;
                    5'd6:  non2<=wdata_q;  5'd7:  non3<=wdata_q;
                    5'd8:  begin                          // CTRL
                               dec_q<=wdata_q[1]; adempty_q<=wdata_q[2];
                               if (wdata_q[0]) begin
                                   start_pulse<=1'b1; done_sticky<=1'b0;
                                   dout_pending<=1'b0;  authok_q<=1'b0;
                               end
                           end
                    5'd10: begin                          // BLK
                               blk_sel<=wdata_q[0]; blk_last<=wdata_q[1];
                               blk_bytes<=wdata_q[6:2];
                           end
                    5'd12: blk0<=wdata_q;  5'd13: blk1<=wdata_q;
                    5'd14: blk2<=wdata_q;
                    5'd15: begin blk3<=wdata_q; blk_pending<=1'b1; end  // push
                    5'd20: tagw0<=wdata_q; 5'd21: tagw1<=wdata_q;
                    5'd22: tagw2<=wdata_q; 5'd23: tagw3<=wdata_q;
                    default: ;
                endcase
                S_AXI_BRESP<=2'b00; S_AXI_BVALID<=1'b1; aw_hs<=1'b0; w_hs<=1'b0;
            end
            if (S_AXI_BVALID && S_AXI_BREADY) S_AXI_BVALID<=1'b0;

            // ================= AXI READ =================
            if (!ar_hs && S_AXI_ARVALID && !S_AXI_ARREADY) S_AXI_ARREADY<=1'b1;
            else                                           S_AXI_ARREADY<=1'b0;
            if (S_AXI_ARREADY && S_AXI_ARVALID) begin ar_hs<=1'b1; araddr_q<=S_AXI_ARADDR; end

            if (ar_hs && !S_AXI_RVALID) begin
                case (araddr_q[6:2])
                    5'd9:  S_AXI_RDATA<={27'd0, dout_pending, ~blk_pending,
                                         authok_q, done_sticky, core_busy};   // STATUS
                    5'd16: S_AXI_RDATA<=dout_sh[31:0];
                    5'd17: S_AXI_RDATA<=dout_sh[63:32];
                    5'd18: S_AXI_RDATA<=dout_sh[95:64];
                    5'd19: S_AXI_RDATA<=dout_sh[127:96];
                    5'd20: S_AXI_RDATA<=tagr0; 5'd21: S_AXI_RDATA<=tagr1;
                    5'd22: S_AXI_RDATA<=tagr2; 5'd23: S_AXI_RDATA<=tagr3;
                    default: S_AXI_RDATA<=32'd0;
                endcase
                if (araddr_q[6:2]==5'd19) dout_pending<=1'b0;   // DOUT3 read drains
                S_AXI_RRESP<=2'b00; S_AXI_RVALID<=1'b1; ar_hs<=1'b0;
            end
            if (S_AXI_RVALID && S_AXI_RREADY) S_AXI_RVALID<=1'b0;
        end
    end
endmodule
