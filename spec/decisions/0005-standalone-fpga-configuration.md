# ADR-0005: A standalone-FPGA configuration stays out of scope until the tile area is ratified and the demonstration fabric is verified

- **Status**: Proposed — takes effect on merge.
- **Date**: 2026-11-19
- **Decided by**: Builder (issue #139)
- **Related**: [`spec/target-spec.md`](../target-spec.md) Scope line and
  rows 3–4 (no ratified area; ≤4×4 fabric), [`CLAUDE.md`](../../CLAUDE.md)
  "The tile is the scope, not the FPGA",
  [`measurements/20261018-tile-place-and-route.md`](../../measurements/20261018-tile-place-and-route.md)
  (measured tile),
  [`measurements/20261024-tile-pin-placement.md`](../../measurements/20261024-tile-pin-placement.md)
  (constrained-pin re-run, abutment satisfied),
  [`measurements/20261118-tile-period-rerun.md`](../../measurements/20261118-tile-period-rerun.md)
  (area unchanged),
  [`measurements/v1-bitstream-verification/`](../../measurements/v1-bitstream-verification/)
  (tile bitstream verification),
  [`measurements/g2-fabric-2x2-generation/`](../../measurements/g2-fabric-2x2-generation/)
  (2×2, description-level only),
  [sky130-fpga#325](https://github.com/2AMLogic/sky130-fpga/issues/325)
  (the master's identical question)

## Context

[Issue #139](https://github.com/2AMLogic/sg13g2-fpga/issues/139) asks whether
a tiny standalone FPGA configuration of this fabric on
SG13G2 (a few hundred to ~1000 LUT4s with I/O in a small package) is worth
specifying. It is a research-and-record decision, not a design commitment:
`CLAUDE.md` declines fabric growth "before the tile is verified" and says such
proposals are recorded in an issue and moved on from — this record is that
proposal's disposition. The master recorded its decision in [sky130 ADR-0007],
merged in [PR #326](https://github.com/2AMLogic/sky130-fpga/pull/326), which
closed [sky130-fpga#325](https://github.com/2AMLogic/sky130-fpga/issues/325).

## Decision

**Out of scope, not now.**

1. **The spec ratifies no tile area, so a standalone configuration cannot be
   costed honestly.** Row 3 of [`spec/target-spec.md`](../target-spec.md)
   states "**No area number is ratified now**"; an area becomes a ratified
   figure only "recorded as a ratified figure by a later decision record",
   and no such record exists (the decision records to date are
   [0001](0001-ratify-target-spec.md)–[0004](0004-vendor-bench-stimulus-generators.md)).
   The measured tile is real evidence but not a ratified figure: the routed
   tile die is 10468.4 µm², 102.315 × 102.315 µm
   (`die_area_um2`, `measurements/20261018-tile-place-and-route.md`), and that
   area is unchanged in the constrained-pin re-run
   ([20261024](../../measurements/20261024-tile-pin-placement.md)) and the
   ratified-20 ns re-run ([20261118](../../measurements/20261118-tile-period-rerun.md)).
   Repo rules allow area claims only from characterized SG13G2 data promoted
   through a decision record — never a sky130 figure or a FABulous placeholder.
   Sizing a standalone part from that area, choosing its I/O and package,
   and specifying its configuration path belong to a future design study.

2. **What the decision waits on** (each condition checkable by a later
   issue):

   - Row 3's later decision record exists and ratifies a tile area/aspect
     figure from the measured records above — the promotion of the 10468.4 µm²
     measured die into `spec/target-spec.md` through a decision record.
   - The demonstration fabric (row 4, 2×2–4×4) has its own verification
     evidence. Row 4 calls for bitstream-level tests on the simulated fabric.
     The [2×2 generation record](../../measurements/g2-fabric-2x2-generation/)
     maps a design across tiles and generates a bitstream. Simulation of that
     bitstream and physical layout of the fabric remain open. A fabric-level
     assembly record through `klt` must document place-and-route, DRC and LVS.
     The [tile place-and-route record](../../measurements/20261018-tile-place-and-route.md)
     explicitly lists fabric-level DRC/LVS under “Not established here”.

   [Tile bitstream verification (V1)](../../measurements/v1-bitstream-verification/)
   recorded 19 PASS, 0 FAIL, 5 NOT-RUN. The tile also has timing and SDF
   records and a routed layout with abutting pins. The standalone question
   depends on how those tiles work together. At the [row 4 ceiling](../target-spec.md),
   a 4×4 fabric has 16 LOGIC4 tiles. Each [LOGIC4 tile](../../rtl/common/fabulous/Tile/LOGIC4/LOGIC4.csv)
   contains four [single-LUT4 BELs](../../rtl/common/fabulous/Tile/LOGIC4/lut4_ff_bel.v),
   giving 64 LUT4s in total. The upper end of issue #139's range, about
   1000 LUT4s, is roughly 16 times that capacity. Verifying the demonstration
   fabric is the first step toward judging a larger one.

3. **Rejected: a standalone-package design study** (pad ring, I/O cells,
   configuration storage and load path, package selection). That is a spec
   change and a fabric-growth proposal, outside this issue's remit; declining
   it here records it. If the conditions above are met, a fresh issue may
   propose the study with evidence.

4. **Relation to the master.** [Sky130 ADR-0007] also defers a standalone
   FPGA until the tile and demonstration fabric have verification evidence.
   The two decisions agree on scope. Under the lineage rule in `CLAUDE.md`,
   this ADR uses SG13G2 measurements for the local area question. Reopening
   the question here also requires the row 3 area decision.

The existing scope rows in `spec/target-spec.md` continue to apply.

[sky130 ADR-0007]: https://github.com/2AMLogic/sky130-fpga/blob/d0c57f9ef3e70f75ee9137eb2e66fe9ecfcb7ea5/spec/decisions/0007-standalone-fpga-configuration.md
