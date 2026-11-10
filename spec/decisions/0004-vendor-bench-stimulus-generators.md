# ADR-0004: Vendor the sibling's bench stimulus generators

- **Status**: Proposed — takes effect on merge.
- **Date**: 2026-11-10
- **Decided by**: Operator ruling 2026-11-10 (rjwalters, `/fleet:decide` round
  20261110-r12 r12-q49); implemented by Builder (issue #68)
- **Related**: #68, ADR-0002 (supersedes its "Consequences" deferral),
  `reuse.lock.json`, [`verification/README.md`](../../verification/README.md)

## Context

ADR-0002 vendored two sibling `flow/` files and left five others unstamped:
`lut_basis.py`, `route_diag.py`, `ctrl_route.py`, `output_route.py` and
`configmem_frames.py`. Its Consequences section says vendoring them "is a
follow-up decision". The five benches that consume them (`tb_lut_basis`,
`tb_route_diag`, `tb_ctrl_route`, `tb_output_route`, `tb_configmem_equiv`, about
1,900 lines) were already stamped, so `verification/run.sh` could only record
them `NOT-RUN`. A Hermit proposal (#68) offered finishing, removing or keeping
them dormant.

## Decision

1. Take the deferral now. Vendor the five generators unmodified at the pinned
   sibling commit `42a8db00e138aa892a388b077a8ae2ea2ccab511`, by sha256 in
   `reuse.lock.json`, into `verification/common/flow/`. None contains sky130
   content (checked before copying), and none needs a helper beyond the already
   vendored `fasm_to_bitstream.py`, which the four route/LUT generators find at
   `<their dir>/../flow/` — the same relative layout as the sibling's.
2. `verification/run.sh` runs the five benches and records PASS or FAIL. The
   four stream benches run the repository composition (`logic_tile_routed`
   through its flat cfg port) on streams generated from the committed
   `verification/bitstream/fabric_spec.json`. `tb_configmem_equiv` runs against
   the FABulous-generated `LOGIC4_ConfigMem.v` with vectors sliced from the
   committed fixture streams by `configmem_frames.py`. A generator, compile or
   simulation failure is FAIL with its log, never skipped. NOT-RUN remains only
   for a missing prerequisite (no fixtures, or `fabulous_generate` not run).
3. No vendored file is modified, so this is not a divergence. A generator that
   later needs editing needs its own decision record.
4. The item-9 evidence inventory (`manifests/inventories/item-9.json`) is
   unchanged: these benches are not added to it, so no re-attestation is made
   here. Adding them is a separate step.

## Consequences

- The five NOT-RUN rows become PASS/FAIL evidence from runs made in this repo.
  The sibling's `-DGEN_TILE` configuration of the four stream benches is still
  not exercised.
- The claim boundary is unchanged: single-LOGIC4 harness, same-index stand-in
  switch matrix, no inter-tile routing, no timing, no area; sibling G5/G6 stay
  open.
- Recorded measurements are append-only. The V1 record keeps its NOT-RUN
  section as history; the new run is a separate record.
