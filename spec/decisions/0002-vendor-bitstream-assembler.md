# ADR-0002: Vendor the sibling's FASM assembler and pad overlay

- **Status**: Proposed — accepted upon the PR for issue #11 merging.
- **Date**: 2026-10-18
- **Decided by**: Builder (issue #11)
- **Related**: #11, #8, [`spec/porting-plan.md`](../porting-plan.md),
  `reuse.lock.json`, ADR-0001

## Context

Issue #11 needs a bitstream "produced by the pinned flow" for
`tb_logic_tile_bitstream.v`. The bench takes a frame stream, a ConfigMem map
and a wiring manifest. The porting plan left the sibling's `flow/` unstamped
(sky130 flow glue) and assigned fixture regeneration to this issue. #8 stopped
before the `top_io`/`top_reg` stages because `flow/nextpnr_io_overlay.py` was
not available. Where the FASM-to-frame step comes from had to be decided.

## Decision

1. Vendor exactly two sibling files at the pinned commit
   `42a8db00e138aa892a388b077a8ae2ea2ccab511`, by sha256 in `reuse.lock.json`:
   `flow/fasm_to_bitstream.py` and `flow/nextpnr_io_overlay.py`, into
   `verification/common/flow/`. Neither contains sky130 content. No other
   `flow/` file is vendored.
2. `fasm_to_bitstream.py` is the FASM-to-frame step, because it also produces
   the ConfigMem map and the wiring manifest that the bench requires; FABulous
   `bit_gen` produces only the frame stream. It is not trusted alone: for each
   fixture `verification/run.sh` requires its stream to be byte-identical to
   `bit_gen genBitstream` run from the pinned FABulous on the same FASM, and
   the bench's loader, the assembler's decoder and the recorded vector to agree.
3. `verification/bitstream_corrupt.py` (malformed-stream generator) is written
   here, not copied; it reads the stream layout from the fixture files.
4. No vendored file is modified, so this is not a divergence.

## Consequences

- Fixtures live in `verification/bitstream/` with `PROVENANCE.txt`; they are
  regenerated, not copied from the sibling.
- Sibling `lut_basis.py`, `route_diag.py`, `ctrl_route.py`, `output_route.py`
  and `configmem_frames.py` are not vendored, so the benches that consume
  them are reported NOT-RUN. Vendoring them is a follow-up decision.
- The claim stays single-LOGIC4 harness; the sibling's G5/G6 stay open.
