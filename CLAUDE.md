# sg13g2-fpga — agent instructions

Open-source canary block: a small open-bitstream eFPGA tile on IHP SG13G2, a
130 nm SiGe BiCMOS open PDK, tile-scoped, designed and verified by AI agents. A port of
`sky130-fpga`. **Digital.**

- **PDK**: IHP SG13G2 (open PDK, IHP-GmbH/IHP-Open-PDK), `sg13g2_stdcell`
  library. Digital: cocotb + Icarus, Yosys, OpenROAD,
  with a FABulous-style tile/fabric description and nextpnr for mapping
  user designs onto the fabric. Layout, DRC, LVS and STA through
  klayout-tools (`klt`). A dense, regular logic tile is exactly the
  workout `klt` place-and-route exists to be stressed by — expect and
  welcome friction there.
- **The young deck and a changed stack are the risk.** The klayout-tools
  SG13G2 DRC/LVS deck is starter-grade and has mostly met analog blocks; a
  routing-dense switch matrix will hit it in new places. Every rule it
  cannot check and every device it cannot extract is friction to file, not a
  reason to waive. The stack (Metal1–Metal5 plus TopMetal1/TopMetal2) and
  the `sg13g2_stdcell` library replace sky130's; whether the inherited tile
  routes on the thin metals, and at what area, is the question this repo
  exists to answer. Do not quietly shrink the tile to make it route — that
  is a spec change.
- **The tile is the scope, not the FPGA.** One LUT4-class tile plus a 2×2
  to 4×4 demonstration fabric. Decline proposals to grow the fabric, add
  tile types or widen the routing before the tile is verified; record the
  proposal in an issue and move on.
- **Scope discipline: designed once.** `sky130-fpga` is the master by
  lineage. Its architecture (tile spec, framework choice, decision records)
  is inherited and cited, not re-argued. Its PDK-independent material —
  tile RTL, the FABulous tile/fabric description, bitstream-level test
  logic — is taken as stamped copies under `rtl/common/` (and the matching
  test directory) via `reuse.lock.json` at a pushed commit, never
  re-written. A vendored file diverges only with a decision record. What is
  re-derived here is device-level and physical: placement, routing, DRC/LVS
  and timing. Findings that bear on the master (a description defect, a
  test gap) are filed on `sky130-fpga`.
- **Friction protocol (the canary's job)**: every time klayout-tools is
  awkward, missing a capability, or wrong for what you need, file an issue at
  `2AMLogic/klayout-tools` describing the tool gap generically — that tracker
  is scoped to the tool, so keep design-specific detail out of it and describe
  the gap, not the design.
- **Verification is the product**: no claim without a testbench.
  Functional claims come from bitstream-level tests on the simulated
  fabric. Timing claims come only from characterized SG13G2 data — no
  number inherited from sky130 or from FABulous's placeholder BEL timing.
  Recorded results are append-only evidence.
- Spec changes go through `spec/` with a decision record; agents do not relax
  the ratified spec to make results pass.
