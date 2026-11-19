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

The issue asks whether a tiny standalone FPGA configuration of this fabric on
SG13G2 (a few hundred to ~1000 LUT4s with I/O in a small package) is worth
specifying. It is a research-and-record decision, not a design commitment:
`CLAUDE.md` declines fabric growth "before the tile is verified" and says such
proposals are recorded in an issue and moved on from — this record is that
proposal's disposition. The same question is open on the master
([sky130-fpga#325](https://github.com/2AMLogic/sky130-fpga/issues/325), open
and in progress as of 2026-11-19).

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
   Any LUT count, I/O count or package estimate for a standalone configuration
   built today would rest on an un-ratified number. Accordingly no LUT, I/O,
   package or configuration-path figure is derived here: deriving them is the
   standalone design study this ADR declines.

2. **What the decision waits on** (each condition checkable by a later
   issue):

   - Row 3's later decision record exists and ratifies a tile area/aspect
     figure from the measured records above — the promotion of the 10468.4 µm²
     measured die into `spec/target-spec.md` through a decision record.
   - The demonstration fabric (row 4, 2×2–4×4) has its own verification
     evidence: bitstream-level tests on the simulated fabric (row 4's stated
     evidence — today only
     [`g2-fabric-2x2-generation/`](../../measurements/g2-fabric-2x2-generation/)
     exists, a description-level 2×2 generation with a cross-tile mapping, and
     no fabric bitstream test record), and a fabric-level assembly record
     through `klt` (fabric place-and-route, DRC and LVS remain in
     [`20261018-tile-place-and-route.md`](../../measurements/20261018-tile-place-and-route.md)'s
     "Not established here" list).

   The tile itself is close to verified — bitstream-level tile verification
   ([V1, 19 PASS](../../measurements/v1-bitstream-verification/)), tile
   timing and SDF records, routed tile with abutment satisfied — but a
   standalone configuration is the *fabric* scaled up by two orders of
   magnitude beyond the ratified ≤4×4 (row 4: "No fabric above 4×4"), so the
   verification bar that matters is the fabric's, and it is not met.

3. **Rejected: a standalone-package design study** (pad ring, I/O cells,
   configuration storage and load path, package selection). That is a spec
   change and a fabric-growth proposal, outside this issue's remit; declining
   it here records it. If the conditions above are met, a fresh issue may
   propose the study with evidence.

4. **Relation to the master.** Per the lineage rule (`CLAUDE.md` "Scope
   discipline: designed once"), [sky130-fpga#325](https://github.com/2AMLogic/sky130-fpga/issues/325)
   decides the same question for the master and is cross-referenced, not
   absorbed. The two answers are expected to share a shape — each repo is
   tile-first and each waits on its own ratified area and verified fabric —
   but this ADR decides for this repo on this repo's measured SG13G2 records
   only. A finding here that bears on the master is filed there, not re-argued.

`spec/target-spec.md` is not edited: the decision is "out", so the scope rows
stand unchanged. No number in this ADR is a spec figure; every number cites
its committed record.
