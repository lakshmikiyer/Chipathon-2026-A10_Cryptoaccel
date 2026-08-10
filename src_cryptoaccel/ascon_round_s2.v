// ============================================================================
// ascon_round_s2.v  -  Stage 2 of the (pipelined) Ascon round.
//   Takes the chi output b[] from stage 1 and computes:
//     output affine  ->  pL (linear diffusion)  =  one full round result
//   Pure combinational. No function/task. rotr(v,n) inlined as shift-or.
// ============================================================================

module ascon_round_s2 (
    input  wire [63:0] b0_i, b1_i, b2_i, b3_i, b4_i,
    output wire [63:0] s0_o, s1_o, s2_o, s3_o, s4_o
);
    // output affine : y0=b0^b4 ; y1=b1^b0 ; y2=~b2 ; y3=b3^b2 ; y4=b4
    wire [63:0] y0 = b0_i ^ b4_i;
    wire [63:0] y1 = b1_i ^ b0_i;
    wire [63:0] y2 = ~b2_i;
    wire [63:0] y3 = b3_i ^ b2_i;
    wire [63:0] y4 = b4_i;

    // pL : linear diffusion, rotr(v,n) = (v>>n)|(v<<(64-n))
    assign s0_o = y0 ^ ((y0 >> 19) | (y0 << 45)) ^ ((y0 >> 28) | (y0 << 36));
    assign s1_o = y1 ^ ((y1 >> 61) | (y1 <<  3)) ^ ((y1 >> 39) | (y1 << 25));
    assign s2_o = y2 ^ ((y2 >>  1) | (y2 << 63)) ^ ((y2 >>  6) | (y2 << 58));
    assign s3_o = y3 ^ ((y3 >> 10) | (y3 << 54)) ^ ((y3 >> 17) | (y3 << 47));
    assign s4_o = y4 ^ ((y4 >>  7) | (y4 << 57)) ^ ((y4 >> 41) | (y4 << 23));
endmodule
