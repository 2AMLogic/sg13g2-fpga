# Work Log

Chronological record of merged PRs and closed issues, newest first. Maintained by the Guide role.

### 2026-10-20

- **PR #6**: ci: grade a committed klt signoff manifest and byte-diff it on every push
- **Issue #4** (closed): T1 item 10: commit a klt signoff block manifest and a CI job that keeps it graded

### 2026-10-18

- **PR #19**: refactor(flow): share one klt step runner between smoke and tile flows
- **PR #18**: feat(layout): three-corner tile STA with extracted SPEF and timing record
- **PR #16**: feat(verification): run stamped benches and regenerated bitstream fixtures under the pinned flow
- **PR #15**: feat(layout): place and route the stamped tile and record routing, DRC/LVS and abutment gap
- **PR #13**: feat(flow): pin FABulous and nextpnr, record G1 generation of the stamped fabric
- **Issue #17** (closed): Consolidate flow/smoke/run.sh and layout/run.sh into one klt step runner
- **Issue #11** (closed): Bitstream-level verification of the stamped tile on the simulated fabric
- **Issue #10** (closed): Timing characterization of the tile at the SG13G2 core corners
- **Issue #9** (closed): Tile physical design on SG13G2: place and route the stamped tile and decide the switch-matrix routing pitch
- **Issue #8** (closed): Check that the pinned FABulous generates an SG13G2 fabric from the stamped description

### 2026-10-17

- **PR #12**: docs(spec): ratify SG13G2 target spec, port plan and vendored sibling tile
- **PR #7**: feat(flow): pin SG13G2 PDK and klt, add klt digital-flow smoke run
- **PR #1**: chore(loom): Install Loom 0.19.1181
- **Issue #5** (closed): PDK and toolchain bring-up: pin SG13G2 and klt, and commit a smoke run through synthesize, place-and-route, DRC, LVS, ERC and STA
- **Issue #2** (closed): Draft and ratify the target spec
