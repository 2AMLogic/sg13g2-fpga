# Roadmap

`sg13g2-fpga` ports the `sky130-fpga` LUT4-class logic tile to IHP SG13G2 and
carries it up the README's maturity ladder, with every claim backed by a
committed record.

Status as of 2026-11-13, `main` @ `266c56a`; tracker as read that day.
`WORK_PLAN.md` is the generated label-state view; this file says where the
work stands and what comes next.

## Where it stands

Ladder position (README): **tile layout DRC/LVS-clean and tile timing closed
at the claim corners; demonstration fabric not yet assembled.**

| Ladder rung | State | Evidence |
|---|---|---|
| Framework and port plan | done | `spec/porting-plan.md`, `reuse.lock.json` |
| Tile spec ratified | done | `spec/target-spec.md`, ADR-0001 (#2) |
| Tile RTL and fabric description pass bitstream-level tests | done for the single-tile harness | `measurements/v2-stream-benches/summary.txt`: 24 PASS, 0 FAIL, 0 NOT-RUN (#11, #68, PR #71) |
| Tile layout DRC/LVS-clean | done | `layout/records/20261030-09fa1bd/` (`drc.json`, `lvs.json`, committed GDS) |
| Tile timing characterized | done at a 20.0 ns period | same record, `sta.json` (three claim corners), `sta-info.json`, SDF re-runs (#10, #27) |
| Demonstration fabric assembled and re-verified | **not started**; spec rows 4 and the fabric half of row 6 have no evidence | #65, parked |
| Shuttle seat, measured silicon | not started | none |

Evidence grade: `manifests/sg13g2-fpga.signoff.json` (klt v0.9.0 grader,
re-checked by CI) reads `tier: T1`: 10 of 11 items met, item 6 `not_applicable`.

Not covered by that grade, per the records:

- The switch matrix is the sibling's same-index stand-in, not a verified
  Wilton-class matrix; sibling gaps G5 and G6 are inherited open
  (`verification/README.md`).
- No inter-tile routing has been simulated; the only fabric is the 3×3
  single-`LOGIC4` harness in `rtl/common/fabulous/fabric.csv`.
- ERC antenna is `unchecked` in the cited record; metal density is
  `unsupported`; power is a default-activity estimate; no Fmax is claimed
  (`measurements/characterization.md`, Disclosures).

Drift picked up below:

- `measurements/characterization.md` (T1 item 8) and the item-1, item-9 and
  item-10 inventories still cite record `20261027-5171c5d`; the report also
  cites the V1 bench record (5 NOT-RUN). The rest of the manifest cites
  `20261030-09fa1bd`, and V2 has no NOT-RUN row.
- Three klt pins are in use: `flow/toolchain.json` names `bf24d46`
  (0.7.1.dev), the cited record was produced by `0.8.1.dev849`, and CI grades
  with v0.9.0.
- Every klayout-tools issue this repo cites as an open gap is now closed
  upstream (#3571, #3784, #3785, #3786, #3900, #4083, #4194, #4199), but the
  records and READMEs still describe several as open.

## Now

Startable today, one pull request each. None has an issue yet.

1. **Re-run the tile flow on one released klt and record what the closed
   upstream gaps now give.** Move the `flow/toolchain.json` klt pin to the
   v0.9.0 commit CI already uses, run `layout/run.sh` and the STA/SDF steps,
   commit a new `layout/records/<id>/`.
   Done when: the record's envelopes pass `--check` and a new `measurements/`
   note states, for antenna (klayout-tools#3784), n-well tie (#4194), SPEF
   annotation (#3900) and NWell rules (#3571), whether the gap is closed,
   quoting the envelope field.
2. **Generate a 2×2 `LOGIC4` fabric and map a cross-tile design** (the part of
   #65 that does not need the single-tile assembler or bench).
   Done when: `rtl/fabric-2x2/fabric.csv` and a
   `measurements/g2-fabric-2x2-generation/` record are committed with
   generated-file hashes, a design with a net between two `LOGIC4` tiles
   reaches FASM through nextpnr, and FABulous `bit_gen` emits a reference
   bitstream whose hash is recorded.
3. **Run the bench suite in CI.** `.github/workflows/` has only `signoff.yml`,
   so nothing re-runs `verification/cold-start.sh` on a pull request.
   Done when: a workflow runs it with the pinned toolchain cached, fails on
   any FAIL row, and T1 item 10 is re-attested with the new workflow listed.
4. **Correct stale documentation.** `measurements/README.md` says "Empty
   until the first work lands here"; the README layout block calls
   `measurements/` "empty until tape-out"; `layout/README.md` says item 11
   "stays `unmet`" while the committed grade is `met`.
   Done when: the three passages match the tree and CI stays green.

## Next

- **New characterization record and manifest re-citation** (after Now 1).
  Done when: a new append-only characterization report cites the new layout
  record and the V2 bench record, `manifests/characterization.json`, the
  item-1, item-9 and item-10 inventories cite one record, and the regenerated
  `manifests/sg13g2-fpga.signoff.json` still reads T1.
- **Inter-tile bitstream-level test on the 2×2 fabric** (#65; after Now 2 and
  the assembler decision under Blocked). Done when #65's acceptance criteria
  hold: a cross-tile design passes with its negative control detected.
- **2×2 fabric layout** (after Now 2 gives a fabric netlist). Done when: four
  abutted copies of the routed tile have committed `drc.json` and `lvs.json`
  envelopes, or the klt gap that prevents it is filed upstream. This is the
  Target of spec row 6.
- **Ratify a measured tile area** (spec row 3 Target; after Now 1). Done
  when: a decision record in `spec/decisions/` fixes the area and aspect
  figure from a named record.

## Later

- **Fabric above 2×2 (up to 4×4).** First: do the 2×2 assembler, bench and
  layout assembly scale without per-size hand work?
- **Wilton-class switch matrix (G5/G6).** First: does the sibling close
  G5/G6, and is the result a re-stamp or a spec change here?
- **Workload power.** First: can `klt sta` take a simulation activity file?
- **Fmax figure.** First: spec row 5 defers whether any Fmax is ratified; is
  one worth ratifying given a 0.027 ns fast-corner hold margin at 20.0 ns?
- **Shuttle seat and measured silicon.** First: an assembled, re-verified
  fabric and a pad-level top, neither of which exists.

## Blocked and waiting

- **#65 is parked with no dependency named.** The vendored
  `verification/common/flow/fasm_to_bitstream.py` and
  `tb_logic_tile_bitstream` accept exactly one `LOGIC4` tile. A maintainer
  must choose: extend them in `sky130-fpga` and re-stamp through
  `reuse.lock.json`, or ratify a local divergence with a decision record in
  `spec/decisions/`. No sibling issue existed on 2026-11-13 (Guide note on
  #65). Now 2 does not wait on this; the Next item does.
- **#3 (gap-to-T1 tracker)** has no open child and waits on a maintainer to
  close it; its body checklist is stale.
- **Sibling ADR-0004/0005/0006** are inherited as *Proposed*
  (`spec/porting-plan.md`); the `CAP_*` reading follows whatever the sibling
  ratifies.

The tracker has no ready (`loom:issue`) item today; the Now items need filing.

## Not planned

- New tile types, wider routing, or a fabric above 4×4 (spec scope).
- Any timing, area or pitch figure inherited from sky130, or benchmarking
  against it (`measurements/characterization.md`).
- TopMetal1/TopMetal2 signal routing without a decision record (spec row 2).
