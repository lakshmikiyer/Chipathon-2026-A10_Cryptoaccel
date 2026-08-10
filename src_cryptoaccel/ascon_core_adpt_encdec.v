
// ============================================================================
// ascon_core.v  -  Ascon-AEAD128 core (NIST SP 800-232)  ENCRYPT + DECRYPT
//   dec_mode = 0 : encrypt  (din = plaintext,  dout = ciphertext, tag output)
//   dec_mode = 1 : decrypt  (din = ciphertext, dout = plaintext,  auth_ok out)
//
//   Init / AD-absorb / finalization are identical in both modes. Only the data
//   loop and the tag step differ:
//     dout      = old_rate XOR din          (both modes)
//     new rate  = din (decrypt)  |  dout (encrypt)
//     last blk  : pad bit at byte din_bytes; truncated dout; no permutation
//     tag       : encrypt outputs T; decrypt compares recomputed T' to tag_in
//   Block-streaming valid/ready. Key/nonce/tag are 64-bit words.
// ============================================================================

module ascon_core_adpt_encdec
 (
    input  wire        clk, rst_n, start,
    input  wire        dec_mode,
    input  wire [63:0] k0_in, k1_in, n0_in, n1_in,
    input  wire [63:0] tag0_in, tag1_in,      // expected tag (decrypt only)
    // associated-data input stream
    input  wire        ad_empty, ad_valid, ad_last,
    input  wire [127:0]ad_data,
    input  wire [4:0]  ad_bytes,
    output wire        ad_ready,
    // data input stream  (plaintext if enc, ciphertext if dec)
    input  wire        din_valid, din_last,
    input  wire [127:0]din_data,
    input  wire [4:0]  din_bytes,
    output wire        din_ready,
    // data output stream (ciphertext if enc, plaintext if dec)
    output reg         dout_valid, dout_last,
    output reg [127:0] dout_data,
    output reg [4:0]   dout_bytes,
    // status + results
    output reg         busy, done,
    output reg         auth_ok,               // decrypt: 1 = tag verified
    output reg [63:0]  t0_out, t1_out         // encrypt: the tag (T'); dec: T'
);
    localparam [63:0] init_val = 64'h00001000808c0001;
    localparam [63:0] DOMSEP   = 64'h8000000000000000;

    localparam [3:0] S_IDLE=4'd0, S_RUN=4'd1, S_INITKEY=4'd2, S_AD_WAIT=4'd3,
                     S_DOMSEP=4'd4, S_DAT_WAIT=4'd5, S_FINKEY=4'd6, S_TAGS=4'd7,
                     S_DAT_APPLY=4'd8;

    reg [3:0]  st, ret_st;
    reg [3:0]  ci;
    reg [63:0] S0, S1, S2, S3, S4;
    reg [63:0] B0, B1, B2, B3, B4;   // pipeline register: chi output (mid-round)
    reg        ph;                    // round phase: 0 = stage 1, 1 = stage 2

    // data-block datapath pipeline: register the deep byte-mux, select next cycle
    reg [127:0] last_nrate_q, last_dout_q, full_dout_q;
    reg [63:0]  full_nS0_q, full_nS1_q;
    reg         din_last_q;
    reg [4:0]   din_bytes_q;

    assign ad_ready  = (st == S_AD_WAIT);
    assign din_ready = (st == S_DAT_WAIT);

    // ---- round-constant ROM -------------------------------------------------
    reg [7:0] rcon;
    always @(*) begin
        case (ci)
            4'd4: rcon=8'hf0; 4'd5: rcon=8'he1; 4'd6: rcon=8'hd2; 4'd7: rcon=8'hc3;
            4'd8: rcon=8'hb4; 4'd9: rcon=8'ha5; 4'd10:rcon=8'h96; 4'd11:rcon=8'h87;
            4'd12:rcon=8'h78; 4'd13:rcon=8'h69; 4'd14:rcon=8'h5a; 4'd15:rcon=8'h4b;
            default: rcon=8'h00;
        endcase
    end

    // ---- AD padding for the last AD block ----------------------------------
    reg [127:0] ad_pad;
    reg [4:0] ai;
    always @(*) begin
        for (ai=0; ai<16; ai=ai+1) begin
            if      (ai <  ad_bytes) ad_pad[ai*8 +: 8] = ad_data[ai*8 +: 8];
            else if (ai == ad_bytes) ad_pad[ai*8 +: 8] = 8'h01;
            else                     ad_pad[ai*8 +: 8] = 8'h00;
        end
    end
    wire [63:0] ad_lo = ad_last ? ad_pad[63:0]   : ad_data[63:0];
    wire [63:0] ad_hi = ad_last ? ad_pad[127:64] : ad_data[127:64];

    // ---- data-block logic (unified enc/dec) --------------------------------
    wire [127:0] rate128 = {S1, S0};
    wire [63:0]  din_lo = din_data[63:0];
    wire [63:0]  din_hi = din_data[127:64];
    // full block:
    wire [127:0] full_dout = {S1 ^ din_hi, S0 ^ din_lo};        // dout = rate ^ din
    wire [63:0]  full_nS0  = dec_mode ? din_lo : (S0 ^ din_lo); // rate <- din(dec)/dout(enc)
    wire [63:0]  full_nS1  = dec_mode ? din_hi : (S1 ^ din_hi);
    // last (partial) block, byte-granular:
    reg [127:0] last_dout, last_nrate;
    reg [4:0] di;
    always @(*) begin
        for (di=0; di<16; di=di+1) begin
            if (di < din_bytes) last_dout[di*8 +: 8] = rate128[di*8 +: 8] ^ din_data[di*8 +: 8];
            else                last_dout[di*8 +: 8] = 8'h00;
            if      (di <  din_bytes) last_nrate[di*8 +: 8] = dec_mode ? din_data[di*8 +: 8]
                                                                       : (rate128[di*8 +: 8] ^ din_data[di*8 +: 8]);
            else if (di == din_bytes) last_nrate[di*8 +: 8] = rate128[di*8 +: 8] ^ 8'h01; // pad bit
            else                      last_nrate[di*8 +: 8] = rate128[di*8 +: 8];          // unchanged
        end
    end

    // ---- round split into two pipeline stages (balanced for timing) --------
    //   stage 1 (S -> B): pC + input-affine + chi   (B registered in S_RUN ph0)
    //   stage 2 (B -> S): output-affine + linear pL (applied in S_RUN ph1)
    wire [63:0] b0, b1, b2, b3, b4;     // stage-1 (chi) output, combinational
    wire [63:0] r0, r1, r2, r3, r4;     // stage-2 (round) output, combinational
    ascon_round_s1 u_s1 (
        .s0_i(S0), .s1_i(S1), .s2_i(S2), .s3_i(S3), .s4_i(S4), .rcon(rcon),
        .b0_o(b0), .b1_o(b1), .b2_o(b2), .b3_o(b3), .b4_o(b4)
    );
    ascon_round_s2 u_s2 (
        .b0_i(B0), .b1_i(B1), .b2_i(B2), .b3_i(B3), .b4_i(B4),
        .s0_o(r0), .s1_o(r1), .s2_o(r2), .s3_o(r3), .s4_o(r4)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st<=S_IDLE; ret_st<=S_IDLE; ci<=4'd0; busy<=1'b0; done<=1'b0; auth_ok<=1'b0;
            S0<=0; S1<=0; S2<=0; S3<=0; S4<=0; t0_out<=0; t1_out<=0;
            B0<=0; B1<=0; B2<=0; B3<=0; B4<=0; ph<=1'b0;
            last_nrate_q<=0; last_dout_q<=0; full_dout_q<=0;
            full_nS0_q<=0; full_nS1_q<=0; din_last_q<=1'b0; din_bytes_q<=0;
            dout_valid<=1'b0; dout_data<=0; dout_bytes<=0; dout_last<=1'b0;
        end else begin
            done <= 1'b0; dout_valid <= 1'b0;
            case (st)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        S0<=init_val; S1<=k0_in; S2<=k1_in; S3<=n0_in; S4<=n1_in;
                        ci<=4'd4; ret_st<=S_INITKEY; st<=S_RUN; busy<=1'b1; ph<=1'b0;
                    end
                end
                S_RUN: begin
                    if (ph == 1'b0) begin                  // stage 1: S -> B
                        B0<=b0; B1<=b1; B2<=b2; B3<=b3; B4<=b4;
                        ph <= 1'b1;
                    end else begin                         // stage 2: B -> S
                        S0<=r0; S1<=r1; S2<=r2; S3<=r3; S4<=r4;
                        ph <= 1'b0;
                        if (ci==4'd15) st<=ret_st; else ci<=ci+4'd1;
                    end
                end
                S_INITKEY: begin S3<=S3^k0_in; S4<=S4^k1_in; st<=S_AD_WAIT; end
                S_AD_WAIT: begin
                    if (ad_empty) st<=S_DOMSEP;
                    else if (ad_valid) begin
                        S0<=S0^ad_lo; S1<=S1^ad_hi;
                        ci<=4'd8; ret_st <= ad_last ? S_DOMSEP : S_AD_WAIT; st<=S_RUN; ph<=1'b0;
                    end
                end
                S_DOMSEP: begin S4<=S4^DOMSEP; st<=S_DAT_WAIT; end
                S_DAT_WAIT: begin
                    if (din_valid) begin
                        // stage 1: register the deep byte-mux datapath (from current S0/S1)
                        last_nrate_q <= last_nrate; last_dout_q <= last_dout;
                        full_nS0_q   <= full_nS0;   full_nS1_q  <= full_nS1;
                        full_dout_q  <= full_dout;
                        din_last_q   <= din_last;   din_bytes_q <= din_bytes;
                        st <= S_DAT_APPLY;
                    end
                end
                S_DAT_APPLY: begin
                    // stage 2: shallow select of the registered results into S0/S1
                    dout_valid<=1'b1; dout_last<=din_last_q;
                    if (din_last_q) begin
                        S0<=last_nrate_q[63:0]; S1<=last_nrate_q[127:64];
                        dout_data<=last_dout_q; dout_bytes<=din_bytes_q;
                        st<=S_FINKEY;                      // no permutation
                    end else begin
                        S0<=full_nS0_q; S1<=full_nS1_q;
                        dout_data<=full_dout_q; dout_bytes<=5'd16;
                        ci<=4'd8; ret_st<=S_DAT_WAIT; st<=S_RUN; ph<=1'b0;
                    end
                end
                S_FINKEY: begin S2<=S2^k0_in; S3<=S3^k1_in; ci<=4'd4; ret_st<=S_TAGS; st<=S_RUN; ph<=1'b0; end
                S_TAGS: begin
                    t0_out <= S3^k0_in; t1_out <= S4^k1_in;
                    auth_ok<= dec_mode ? (((S3^k0_in)==tag0_in) && ((S4^k1_in)==tag1_in)) : 1'b1;
                    done<=1'b1; busy<=1'b0; st<=S_IDLE;
                end
                default: st<=S_IDLE;
            endcase
        end
    end
endmodule