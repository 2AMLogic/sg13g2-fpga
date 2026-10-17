# ADR-0001: Ratify the SG13G2 target spec and port plan

- **Status**: Proposed — ratified upon this PR merging, per the repo's
  ratification-via-PR flow. Nothing here is a measurement.
- **Date**: 2026-10-17
- **Decided by**: Builder (issue #2)
- **Related**: #2 (this issue), #5 (PDK/toolchain pin), #8–#11 (owners of
  the deferrals below), [`spec/porting-plan.md`](../porting-plan.md),
  [`spec/target-spec.md`](../target-spec.md), `reuse.lock.json`

## Context

`sky130-fpga` carries a ratified tile spec and a stamped-reusable
description. This repo ports the tile to SG13G2. The README table was a
draft. Rows needing a measurement cannot honestly be numbers yet, and the
sibling's own status (bitstream-level verification of the ratified fabric
not done; ADR-0004/0005/0006 *Proposed*) bears on what this port can claim.

## Decision

1. Ratify [`spec/target-spec.md`](../target-spec.md) as the spec. Rows
   that need a measurement are ratified as target / fallback / stretch with
   the evidence that will back them. No timing, area or pitch figure is
   ratified.
2. Ratify [`spec/porting-plan.md`](../porting-plan.md): every sibling read
   at `42a8db00e138aa892a388b077a8ae2ea2ccab511`; inherit / stamp /
   re-derive lists as written there; `reuse.lock.json` schema as defined
   there.
3. Inherit the sibling architecture and ADR 0001 (*Accepted*) unchanged.
   Inherit sibling ADR-0004/0005/0006 as *Proposed*. Do **not** inherit
   sibling ADR-0002/0003 (sky130 18-corner timing); timing is re-earned.
4. Claim corners are the three 1.2 V core liberty corners. The three 1.5 V
   class corners are reported, not claimed.
5. Stamp the `CAP_*` boundary tiles with the FABulous description, as
   harness-only cells. "Single tile type" means single *logic* tile type.
   This follows the sibling's *Proposed* reading and is revisited if the
   sibling decides ADR-0004 differently.

## Open questions: resolution or explicit deferral

| Question | Disposition |
|---|---|
| Does the pinned FABulous generate an SG13G2 fabric out of the box? | **Deferred to #8.** The stamped description is PDK-independent (no PDK string in any stamped file); that is not evidence the generator accepts it under this repo's pin. Any change to a vendored file needs a decision record. |
| Which SG13G2 deck rules and LVS devices does a dense digital tile need that the starter deck cannot check? | **Deferred to #9.** Each is filed generically at `2AMLogic/klayout-tools` when found. None was found in this issue: no layout was run. |
| Will the 4-track matrix route on the thin metals? | **Deferred to #9.** Spec row 2. A track-count or topology change is a recorded spec change, not a quiet one. |
| What does the sibling's incomplete verification mean for claims here? | **Resolved** in the porting plan: the stamped matrix is the sibling's same-index stand-in; G5/G6 are inherited as open; no functional claim comes from sibling results. Functional evidence is owned by #11. |
| Does an Fmax figure get ratified? | **Deferred to #10.** Row 5 ratifies setup/hold at a period fixed before measurement. |
| Which corners can `klt sta` run on SG13G2? | **Deferred to #10** (with #5's one-corner smoke). |

## Alternatives rejected

- *Run the sibling flow on SG13G2 to pre-measure.* That is #5's smoke and
  later tile work, not a spec.
- *Ratify placeholder numbers (period, area, pitch).* A number without a
  measurement is the failure the repo exists to avoid.
- *Treat all six liberty files as claim corners.* The tile is a 1.2 V core
  design.

## Consequences

- Later issues cite the rows and deferrals above.
- If #9 shows the inherited matrix does not route on the thin metals, the
  response is a new decision record that changes the spec.
- Klayout-tools gaps: none were hit scoping this spec, so none is filed.
