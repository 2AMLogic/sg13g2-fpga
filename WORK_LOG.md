# Work Log

Chronological record of merged PRs and closed issues, newest first. Maintained by the Guide role.

### 2026-11-15

- **PR #104**: ci: correct the OSS cache-key rationale and key the iverilog cache on its build recipe
- **Issue #96** (closed): verification.yml:120-122 states a reason for the OSS cache key that #88 removed
- **PR #112**: fix(flow): pin klayout-tools to the v0.9.0 release tag, matching signoff.yml
- **Issue #99** (closed): Bump the klayout-tools pin: the pinned klt (bf24d463) refuses every routed-tile SDF that layout/sdf-verify.sh needs to annotate
- **PR #106**: fix: pin generation-stage yosys and mask checkout paths in the G2 manifest
- **PR #102**: docs: correct four stale status passages and regenerate the item-10 attestation
- **PR #93**: chore: delete the no-op npm scaffolding manifest, pin it against resync
- **Issue #90** (closed): Remove root package.json: a no-op npm test/check entry point in a repo with no JS
- **Issue #82** (closed): Correct four stale status passages in measurements/README.md, rtl/README.md, README.md and layout/README.md
- **PR #100**: fix: give FABulous the suite's yosys explicitly; drop the CI PATH workaround
- **PR #98**: fix: SDF bench clock_edge drives one full PERIOD_NS period, asserted at every rise
- **Issue #86** (closed): verification/cold-start.sh is not self-contained: fabulous_generate needs a host-wide yosys
- **Issue #84** (closed): Fix the SDF gate-level bench clock: the split half-waveform realizes a 25 ns period, not the 20 ns PERIOD_NS claims

### 2026-11-14

- **PR #89**: refactor(verification): read the suite tarball URL and sha256 from flow/toolchain.json
- **PR #87**: feat: generate a 2x2 LOGIC4 fabric and map a cross-tile design to FASM
- **PR #85**: ci: run the bench suite on changes to rtl/ and verification/
- **PR #78**: docs: roadmap as of 2026-11-13
- **Issue #92** (closed): verification.yml: the iverilog cache key omits the build recipe
- **Issue #88** (closed): Collapse the duplicated OSS CAD Suite pin: the tarball URL and sha256 live in both flow/toolchain.json and verification/run.sh
- **Issue #81** (closed): Run verification/cold-start.sh in CI so the bench suite is re-checked on every pull request
- **Issue #80** (closed): Generate a 2x2 LOGIC4 fabric with the pinned FABulous and map a cross-tile design to FASM
- **Issue #3** (closed): Track the gap to T1 (klayout-tools design-evidence-tiers.md)

### 2026-11-12

- **PR #75**: Bump Repo Skills 0.25.10 -> 0.26.1

### 2026-11-10

- **PR #71**: test: vendor bench stimulus generators and run the five stream benches
- **Issue #68** (closed): Five vendored testbenches (~1,900 LOC) are permanently NOT-RUN: vendor their generators or drop them

### 2026-11-07

- **PR #67**: Bump Repo Skills 0.25.1 -> 0.25.10

### 2026-11-05

- **PR #61**: chore(signoff): pin klt to v0.9.0 so item 11 grades the tapless PDN
- **PR #62**: feat(signoff): cite SDF functional-verification runs under T1 item 5
- **Issue #60** (closed): Cite a klt functional-verification run under item 5 (all evidence from record 20261030-09fa1bd)
- **Issue #59** (closed): Bump the signoff klt pin past klayout-tools#4250 so item 11 grades the tapless PDN

### 2026-11-02

- **Issue #55** (closed): main red: committed signoff report stale after #50 (t1_met_count 4 vs 5)

### 2026-11-01

- **PR #57**: Bump Repo Skills 0.24.7 -> 0.25.1

### 2026-10-31

- **PR #53**: docs(measurements): add tile characterization report and cite it as T1 item 8
- **PR #51**: feat(manifests): attest T1 item 9 with a testbench inventory
- **Issue #52** (closed): manifests/README.md still lists T1 item 1 as uncited
- **Issue #41** (closed): T1 item 9 (testbenches shipped): testbench inventory and klt signoff --attest 9
- **Issue #40** (closed): T1 item 8 (characterization): aggregated characterization report with area, timing and power per corner

### 2026-10-30

- **PR #49**: feat(layout): commit routed tile GDS and attest T1 item 2
- **Issue #38** (closed): T1 item 2 (layout): commit the routed logic_tile GDS (it is only in flow/build today) and attest it
- **PR #50**: feat(signoff): attest T1 item 1 with committed synthesized netlist and freshness check
- **PR #48**: feat(signoff): cite SDF-annotated gate-level re-run as T1 item 7
- **Issue #39** (closed): T1 item 7 (post-layout): cite the SDF-annotated klt functional-verification runs, all items from one record
- **Issue #37** (closed): T1 item 1 (design sources): commit the tile's synthesized netlist in the cited record and klt signoff --attest 1
- **PR #46**: ci(signoff): bump klt pin to v0.8.0, attest T1 item 10, refresh README status
- **Issue #36** (closed): T1 item 10 (repo hygiene): bump the signoff klt pin (attest and SDF support), fix README status, attest item 10

### 2026-10-27

- **PR #43**: feat(erc): declare VDD/VSS supplies and substrate tie in ERC spec, re-cite item 11
- **Issue #42** (closed): T1 item 11 (power delivery): add nets[]/ties[] to the ERC supply spec and resolve tapcell_master null

### 2026-10-24

- **PR #34**: feat(layout): constrain tile track pins to facing edges for abutment
- **Issue #28** (closed): Remove five stamped benches this repo cannot drive (permanent NOT-RUN)
- **Issue #14** (closed): Tile pin placement for grid abutment once klt can constrain I/O pins

### 2026-10-23

- **PR #30**: feat: SDF-annotated gate-level re-simulation of the routed tile at slow and fast corners
- **Issue #27** (closed): SDF-annotated gate-level re-simulation of the routed tile at the claim corners (T1 item 7)
- **PR #29**: feat(signoff): cite committed tile envelopes in the klt signoff manifest
- **Issue #26** (closed): Cite the committed tile envelopes in the klt signoff manifest and regenerate the verdict record

### 2026-10-21

- **PR #23**: Bump Repo Skills 0.24.3 -> 0.24.7

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
