// SPDX-FileCopyrightText: 2026 Chipathon 2026 workshop
// SPDX-License-Identifier: Apache-2.0
//
// chip_core.sv  -  Block-A core, Team A10 Cryptoaccel
//
//   chip_top.sv  ->  chip_core.sv  ->  spi_slave  (Ascon-AEAD128 accelerator)
//
// chip_top.sv is template-owned: it instantiates every pad cell and passes
// flat vectors here. This file maps those vectors onto the design.
//
// All six signals use BIDIR pads (see pad_map.svh); the dedicated
// clk / rst_n input ports from chip_top are intentionally left unused.

`default_nettype none

`include "pad_map.svh"

module chip_core #(
    parameter NUM_INPUT_PADS,
    parameter NUM_BIDIR_PADS,
    parameter NUM_ANALOG_PADS
    )(
    `ifdef USE_POWER_PINS
    inout  wire VDD,
    inout  wire VSS,
    `endif

    input  wire clk,       // dedicated clk pad   - UNUSED (clk comes from bidir)
    input  wire rst_n,     // dedicated rst_n pad - UNUSED (rst_n comes from bidir)

    input  wire [NUM_INPUT_PADS-1:0] input_in,   // Input value
    output wire [NUM_INPUT_PADS-1:0] input_pu,   // Pull-up
    output wire [NUM_INPUT_PADS-1:0] input_pd,   // Pull-down

    input  wire [NUM_BIDIR_PADS-1:0] bidir_in,   // Input value
    output wire [NUM_BIDIR_PADS-1:0] bidir_out,  // Output value
    output wire [NUM_BIDIR_PADS-1:0] bidir_oe,   // Output enable
    output wire [NUM_BIDIR_PADS-1:0] bidir_cs,   // Input type (0=CMOS, 1=Schmitt)
    output wire [NUM_BIDIR_PADS-1:0] bidir_sl,   // Slew rate (0=fast, 1=slow)
    output wire [NUM_BIDIR_PADS-1:0] bidir_ie,   // Input enable
    output wire [NUM_BIDIR_PADS-1:0] bidir_pu,   // Pull-up
    output wire [NUM_BIDIR_PADS-1:0] bidir_pd,   // Pull-down

    inout  wire [NUM_ANALOG_PADS-1:0] analog     // Analog
);

    // ---------------------------------------------------------
    // Design instance
    // ---------------------------------------------------------
    wire clk_i, rst_ni, sclk_i, mosi_i, csn_i, miso_o;

    spi_slave dut_ascon (
    `ifdef USE_POWER_PINS
        .VDD   (VDD),
        .VSS   (VSS),
    `endif
        .clk   (clk_i),
        .rst_n (rst_ni),
        .sclk  (sclk_i),
        .mosi  (mosi_i),
        .cs_n  (csn_i),
        .miso  (miso_o)
    );

    // =========================================================
    // PAD MAPPING
    // =========================================================
    generate
        for (genvar i = 0; i < NUM_BIDIR_PADS; i++) begin : gen_pad
            if (i == `PAD_CLK) begin : pad_clk
                // Pad PAD_CLK: core clock (Input, Schmitt)
                assign bidir_out[i] = 1'b0;
                assign bidir_oe[i]  = 1'b0;
                assign bidir_ie[i]  = 1'b1;
                assign bidir_cs[i]  = 1'b1;   // Schmitt: clean edges on a clock
                assign bidir_pu[i]  = 1'b0;
                assign bidir_pd[i]  = 1'b0;
            end else if (i == `PAD_RST_N) begin : pad_rst_n
                // Pad PAD_RST_N: async reset, active low (Input, Schmitt)
                assign bidir_out[i] = 1'b0;
                assign bidir_oe[i]  = 1'b0;
                assign bidir_ie[i]  = 1'b1;
                assign bidir_cs[i]  = 1'b1;   // Schmitt: slow external edge
                assign bidir_pu[i]  = 1'b0;   // if 1 then -> NOT held in reset
                assign bidir_pd[i]  = 1'b0;
            end else if (i == `PAD_SCLK) begin : pad_sclk
                // Pad PAD_SCLK: SPI clock (Input, Schmitt)
                assign bidir_out[i] = 1'b0;
                assign bidir_oe[i]  = 1'b0;
                assign bidir_ie[i]  = 1'b1;
                assign bidir_cs[i]  = 1'b1;   // Schmitt: it is a clock
                assign bidir_pu[i]  = 1'b0;
                assign bidir_pd[i]  = 1'b0;
            end else if (i == `PAD_MOSI) begin : pad_mosi
                // Pad PAD_MOSI: SPI data in (Input)
                assign bidir_out[i] = 1'b0;
                assign bidir_oe[i]  = 1'b0;
                assign bidir_ie[i]  = 1'b1;
                assign bidir_cs[i]  = 1'b0;
                assign bidir_pu[i]  = 1'b0;
                assign bidir_pd[i]  = 1'b0;
            end else if (i == `PAD_CS_N) begin : pad_cs_n
                // Pad PAD_CS_N: SPI chip select, active low (Input)
                assign bidir_out[i] = 1'b0;
                assign bidir_oe[i]  = 1'b0;
                assign bidir_ie[i]  = 1'b1;
                assign bidir_cs[i]  = 1'b0;
                assign bidir_pu[i]  = 1'b1;   // float -> deselected, chip idle
                assign bidir_pd[i]  = 1'b0;
            end else if (i == `PAD_MISO) begin : pad_miso
                // Pad PAD_MISO: SPI data out (Output)
                assign bidir_out[i] = miso_o;
                assign bidir_oe[i]  = 1'b1;
                assign bidir_ie[i]  = 1'b0;
                assign bidir_cs[i]  = 1'b0;
                assign bidir_pu[i]  = 1'b0;
                assign bidir_pd[i]  = 1'b0;
            end else begin : pad_unused
                // Unused pads -> driven low and disabled
                assign bidir_out[i] = 1'b0;
                assign bidir_oe[i]  = 1'b0;
                assign bidir_ie[i]  = 1'b0;
                assign bidir_cs[i]  = 1'b0;
                assign bidir_pu[i]  = 1'b0;
                assign bidir_pd[i]  = 1'b0;
            end
        end
    endgenerate

    // ---------------------------------------------------------
    // Pad inputs -> design
    // ---------------------------------------------------------
    assign clk_i  = bidir_in[`PAD_CLK];
    assign rst_ni = bidir_in[`PAD_RST_N];
    assign sclk_i = bidir_in[`PAD_SCLK];
    assign mosi_i = bidir_in[`PAD_MOSI];
    assign csn_i  = bidir_in[`PAD_CS_N];

    // ---------------------------------------------------------
    // Static pad electrical configuration
    // ---------------------------------------------------------
    assign bidir_sl = '0;   // 0 = fast slew on every bidir pad
    assign input_pu = '0;   // no pulls on the pure-input pads (unused)
    assign input_pd = '0;

(* keep *) wire _keep_clk   = clk;
(* keep *) wire _keep_rst_n = rst_n;

    // Keep synthesis from optimising unused inputs (and their pads) away.
(* keep *) logic _unused;
    assign _unused = &{1'b0, bidir_in, input_in, clk, rst_n};

endmodule

`default_nettype wire
