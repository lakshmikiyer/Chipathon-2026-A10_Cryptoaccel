// ============================================================================
// ascon_round_s1.v  -  Stage 1 of the (pipelined) Ascon round.
//   Computes:  pC (add round constant)  ->  input affine  ->  chi  =  b[]
//   Pure combinational. No function/task.
// ============================================================================

module ascon_round_s1 (
    input  wire [63:0] s0_i, s1_i, s2_i, s3_i, s4_i,
    input  wire [7:0]  rcon,
    output wire [63:0] b0_o, b1_o, b2_o, b3_o, b4_o
);
    // pC : add round constant to the low byte of S2
    wire [63:0] c2 = {s2_i[63:8], s2_i[7:0] ^ rcon};

    // input affine : x0^=x4 ; x2^=x1 ; x4^=x3   (x = s0,s1,c2,s3,s4)
    wire [63:0] a0 = s0_i ^ s4_i;
    wire [63:0] a1 = s1_i;
    wire [63:0] a2 = c2   ^ s1_i;
    wire [63:0] a3 = s3_i;
    wire [63:0] a4 = s4_i ^ s3_i;

    // chi : t_i = (~a_i) & a_{i+1} ;  b_i = a_i ^ t_{i+1}
    wire [63:0] t0 = (~a0) & a1;
    wire [63:0] t1 = (~a1) & a2;
    wire [63:0] t2 = (~a2) & a3;
    wire [63:0] t3 = (~a3) & a4;
    wire [63:0] t4 = (~a4) & a0;

    assign b0_o = a0 ^ t1;
    assign b1_o = a1 ^ t2;
    assign b2_o = a2 ^ t3;
    assign b3_o = a3 ^ t4;
    assign b4_o = a4 ^ t0;
endmodule
