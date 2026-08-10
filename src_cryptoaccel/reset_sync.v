// ============================================================================
// reset_sync.v  -  Reset synchronizer (async assert, synchronous release).
//   Takes an asynchronous active-low reset and produces a reset for one clock
//   domain that de-asserts synchronously with `clk`, so every flop in that
//   domain leaves reset on the same edge (no recovery/removal hazard).
//   Instantiate ONE per clock domain, clocked by that domain's clock.
// ============================================================================

module reset_sync (
    input  wire clk,
    input  wire arst_n,     // asynchronous, active-low (from the chip pin)
    output wire srst_n      // synchronized: asserts async, releases on clk
);
    reg m, s;
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin m <= 1'b0; s <= 1'b0; end   // assert instantly (no clk needed)
        else         begin m <= 1'b1; s <= m;    end   // release 2 clks after arst_n rises
    end
    assign srst_n = s;
endmodule