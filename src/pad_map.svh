// ============================================================================
// pad_map.svh  -  Padframe pad mapping for Team A10 Cryptoaccel (Block A)
//
// Bidir pad indices used by the Ascon-AEAD128 SPI accelerator.
// All six signals come from bidir pads - the dedicated south-edge
// clk_pad / rst_n_pad are NOT used.
//
// Update these indices to match the pads actually allocated to Block A.
// ============================================================================

`define PAD_CLK    12
`define PAD_RST_N  13
`define PAD_SCLK   14
`define PAD_MOSI   15
`define PAD_CS_N   16
`define PAD_MISO   17
