// Issue #138 blinky: a one-bit clock divider on the single-LOGIC4 harness,
// the smallest design that shows a freshly built bitstream running:
//   q <= rst ? 1'b0 : (en ? ~q : q)     synchronous, reset over enable
// i.e. the BEL's flop semantics (rtl/common/rtl/lut4_slice.v: reset
// independent of / priority over clock-enable, reset value 0) with the data
// function tied to the flop's own output. yosys maps the inverter to a
// combinational LOGIC4 BEL (FF=0) and the flop to a second LOGIC4 BEL
// (FF=1, INIT = pass I0; ff_map.v), so the feedback net q is a real routed
// net (BEL output -> track -> CAP turnaround -> track -> LUT input), the
// same route class tb_logic_tile_bitstream's LOOP manifest entries model.
// `clk` is the BEL's implicit UserCLK (no fabric pin): it is a runtime
// *harness* input, stripped from the nextpnr JSON by verification/blinky.sh.
//
// After reset the output pad reads 0 and then toggles on every enabled
// clock edge: verification/blinky/tb_blinky.v samples it and checks the
// sequence 0, 1, 0, 1, 0. Single-LOGIC4 scope; multi-tile routing and
// simulation are issue #65.
module top (input clk, input rst, input en, output q);
    reg r;
    always @(posedge clk)
        if (rst) r <= 1'b0;
        else if (en) r <= ~r;
    assign q = r;
endmodule
