// G2 cross-tile acceptance design (issue #80): a chain of six lut4_ff_bel
// cells, which cannot be placed inside a single LOGIC4 tile and therefore
// forces at least one net across a tile boundary.
//
// Why six. rtl/common/fabulous/Tile/LOGIC4/LOGIC4.csv declares exactly four
// BELs per logic tile (LA_, LB_, LC_, LD_), so any design with five or more
// lut4_ff_bel cells must straddle a tile boundary by pigeonhole -- a property
// of the fabric, not of the placer's choice, which is what makes the crossing
// reproducible. Six leaves margin so a crossing remains forced even if the
// placer spreads the chain unevenly.
//
// Shape follows rtl/common/fabulous/nextpnr/top.v: structural, (* keep *) on
// every instance and wire, and no top-level ports and no constants. Both
// restrictions are recorded findings of the G1 record, not style -- the
// generated fabric has no IO BEL (a top-level port driven by a LUT fails with
// "must be PAD") and no constant driver (a tied-off pin makes $PACKER_GND
// unroutable). Confirmed again for this fabric: the generated
// .FABulous/template.pcf is empty, so no pads are declared.
//
// LUT INIT is 16'h6996, the 4-input parity, the same function the G1 design
// uses. Unconnected LUT inputs, SR and EN are left floating, as in top.v.
module top;
    (* keep *) wire n1;
    (* keep *) wire n2;
    (* keep *) wire n3;
    (* keep *) wire n4;
    (* keep *) wire n5;
    (* keep *) wire n6;
    (* keep *) lut4_ff_bel #(.INIT(16'h6996), .FF(1'b0)) u0 (.O(n1));
    (* keep *) lut4_ff_bel #(.INIT(16'h6996), .FF(1'b0)) u1 (.I0(n1), .O(n2));
    (* keep *) lut4_ff_bel #(.INIT(16'h6996), .FF(1'b0)) u2 (.I0(n2), .O(n3));
    (* keep *) lut4_ff_bel #(.INIT(16'h6996), .FF(1'b0)) u3 (.I0(n3), .O(n4));
    (* keep *) lut4_ff_bel #(.INIT(16'h6996), .FF(1'b0)) u4 (.I0(n4), .O(n5));
    (* keep *) lut4_ff_bel #(.INIT(16'h6996), .FF(1'b0)) u5 (.I0(n5), .O(n6));
endmodule
