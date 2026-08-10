// ============================================================================
// axi_master.v  -  AXI4-Lite master that INSTANTIATES axi_ascon internally.
//
// External face (to spi_slave):  a simple command bus.
//     cmd_valid / cmd_ready : request handshake (accepted when both high)
//     cmd_write             : 1 = write, 0 = read
//     cmd_addr  [6:0]       : register address
//     cmd_wdata [31:0]      : data to write
//     cmd_done              : 1-cycle pulse when the transaction completes
//     cmd_rdata [31:0]      : read result (valid at cmd_done)
//
// Internally: the AXI4-Lite master FSM drives an embedded axi_ascon slave
// (which wraps ascon_core_adpt_encdec, which uses ascon_round). The AXI bus
// is private to this module - nothing AXI leaves the ports.
//
// No Verilog functions or tasks (matches the project style).
// ============================================================================

module axi_master (
    input  wire        clk,
    input  wire        rstn,
    // ---- command interface (the only external face) ----
    input  wire        cmd_valid,
    output wire        cmd_ready,
    input  wire        cmd_write,
    input  wire [6:0]  cmd_addr,
    input  wire [31:0] cmd_wdata,
    output reg         cmd_done,
    output reg  [31:0] cmd_rdata
);
    // ---- private AXI4-Lite bus to the embedded slave ----
    reg  [6:0]  m_awaddr;  reg [2:0] m_awprot; reg m_awvalid; wire m_awready;
    reg  [31:0] m_wdata;   reg [3:0] m_wstrb;  reg m_wvalid;  wire m_wready;
    wire        m_bvalid;  reg  m_bready;
    reg  [6:0]  m_araddr;  reg [2:0] m_arprot; reg m_arvalid; wire m_arready;
    wire        m_rvalid;  reg  m_rready;      wire [31:0] m_rdata;

    // ---- embedded AXI-Lite slave (Ascon accelerator) ----
wire [1:0] S_AXI_BRESP , S_AXI_RRESP;


    axi_ascon u_slave (
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(rstn),
        .S_AXI_AWADDR(m_awaddr), .S_AXI_AWPROT(m_awprot),
        .S_AXI_AWVALID(m_awvalid), .S_AXI_AWREADY(m_awready),
        .S_AXI_WDATA(m_wdata), .S_AXI_WSTRB(m_wstrb),
        .S_AXI_WVALID(m_wvalid), .S_AXI_WREADY(m_wready),
        .S_AXI_BRESP(S_AXI_BRESP), .S_AXI_BVALID(m_bvalid), .S_AXI_BREADY(m_bready),
        .S_AXI_ARADDR(m_araddr), .S_AXI_ARPROT(m_arprot),
        .S_AXI_ARVALID(m_arvalid), .S_AXI_ARREADY(m_arready),
        .S_AXI_RDATA(m_rdata), .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(m_rvalid), .S_AXI_RREADY(m_rready)
    );

    // ---- AXI master FSM ----
    localparam M_IDLE=3'd0, M_W=3'd1, M_WB=3'd2, M_R=3'd3, M_RR=3'd4;
    reg [2:0] st;

    assign cmd_ready = (st == M_IDLE);          // accept a command only when idle

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            st<=M_IDLE; cmd_done<=0; cmd_rdata<=0;
            m_awaddr<=0; m_awprot<=0; m_awvalid<=0; m_wdata<=0; m_wstrb<=0; m_wvalid<=0;
            m_bready<=0; m_araddr<=0; m_arprot<=0; m_arvalid<=0; m_rready<=0;
        end else begin
            cmd_done <= 1'b0;                    // default: one-cycle pulse
            case (st)
                M_IDLE: begin
                    m_awvalid<=0; m_wvalid<=0; m_bready<=0; m_arvalid<=0; m_rready<=0;
                    if (cmd_valid) begin
                        if (cmd_write) begin
                            m_awaddr<=cmd_addr; m_awprot<=3'b000; m_awvalid<=1'b1;
                            m_wdata<=cmd_wdata;  m_wstrb<=4'hf;   m_wvalid<=1'b1;
                            st<=M_W;
                        end else begin
                            m_araddr<=cmd_addr; m_arprot<=3'b000; m_arvalid<=1'b1;
                            st<=M_R;
                        end
                    end
                end
                M_W: begin
                    if (m_awready) m_awvalid<=1'b0;
                    if (m_wready)  m_wvalid<=1'b0;
                    if (!m_awvalid && !m_wvalid) begin m_bready<=1'b1; st<=M_WB; end
                end
                M_WB: if (m_bvalid) begin m_bready<=1'b0; cmd_done<=1'b1; st<=M_IDLE; end
                M_R:  if (m_arready) begin m_arvalid<=1'b0; m_rready<=1'b1; st<=M_RR; end
                M_RR: if (m_rvalid) begin cmd_rdata<=m_rdata; m_rready<=1'b0; cmd_done<=1'b1; st<=M_IDLE; end
                default: st<=M_IDLE;
            endcase
        end
    end
endmodule
