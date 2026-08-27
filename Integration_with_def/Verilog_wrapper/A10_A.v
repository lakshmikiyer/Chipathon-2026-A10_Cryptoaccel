// ============================================================================
// A10_A BECOMES  THE TOP MODULE NOW, WHICH WILL CALL spi_slave (which was earlier the top module)/////////////////////////////////////
// A10_A.v - pad-facing wrapper for the A10 block-A tile.
//   Port names and directions must match A10_A.def exactly (50 pins).
//   Pad cell: gf180mcu_fd_io__bi_24t on slots W14..W19.
// ============================================================================
module A10_A (
    output clk_CS,   clk_SL,   clk_IE,   clk_OE,   clk_PU,   clk_PD,   clk_OUT,
    input  clk_IN,
    output rst_n_CS, rst_n_SL, rst_n_IE, rst_n_OE, rst_n_PU, rst_n_PD, rst_n_OUT,
    input  rst_n_IN,
    output sclk_CS,  sclk_SL,  sclk_IE,  sclk_OE,  sclk_PU,  sclk_PD,  sclk_OUT,
    input  sclk_IN,
    output mosi_CS,  mosi_SL,  mosi_IE,  mosi_OE,  mosi_PU,  mosi_PD,  mosi_OUT,
    input  mosi_IN,
    output cs_n_CS,  cs_n_SL,  cs_n_IE,  cs_n_OE,  cs_n_PU,  cs_n_PD,  cs_n_OUT,
    input  cs_n_IN,
    output miso_CS,  miso_SL,  miso_IE,  miso_OE,  miso_PU,  miso_PD,  miso_OUT,
    input  miso_IN
);

    // ---- receiver / driver enables -----------------------------------------
    // clk, rst_n, sclk, mosi, cs_n are chip inputs: receiver on, driver off.
    assign {clk_IE,   clk_OE,   clk_OUT  } = {1'b1, 1'b0, 1'b0};
    assign {rst_n_IE, rst_n_OE, rst_n_OUT} = {1'b1, 1'b0, 1'b0};
    assign {sclk_IE,  sclk_OE,  sclk_OUT } = {1'b1, 1'b0, 1'b0};
    assign {mosi_IE,  mosi_OE,  mosi_OUT } = {1'b1, 1'b0, 1'b0};
    assign {cs_n_IE,  cs_n_OE,  cs_n_OUT } = {1'b1, 1'b0, 1'b0};

    // miso is the only chip output: driver on, receiver off.
    assign  miso_IE = 1'b0;
    assign  miso_OE = 1'b1;

    // ---- no pull-up / pull-down on any pad ---------------------------------
    // {PU,PD} = 00 leaves the pad floating when OE=0. Every pin is externally
    // driven, so no pull device is needed on any of them.
    assign {clk_PU,  clk_PD,  rst_n_PU, rst_n_PD,
            sclk_PU, sclk_PD, mosi_PU,  mosi_PD,
            cs_n_PU, cs_n_PD, miso_PU,  miso_PD} = 12'b0;

    // ---- static drive-strength / slew configuration ------------------------
    assign {clk_CS,  clk_SL,  rst_n_CS, rst_n_SL,
            sclk_CS, sclk_SL, mosi_CS,  mosi_SL,
            cs_n_CS, cs_n_SL, miso_CS,  miso_SL} = 12'b0;

    // ---- core --------------------------------------------------------------
    spi_slave u_core (
        .clk   (clk_IN),
        .rst_n (rst_n_IN),
        .sclk  (sclk_IN),
        .mosi  (mosi_IN),
        .cs_n  (cs_n_IN),
        .miso  (miso_OUT)
    );

endmodule