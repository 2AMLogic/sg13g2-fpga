# Tile characterization report (issue #40, T1 item 8)

Append-only. Corrections go in a new record, not an edit to this one.

One row per ratified row of `spec/target-spec.md` (ADR-0001): the three
architectural rows and parameter rows 1–6. Every physical figure comes from the
single record `layout/records/20261027-5171c5d/` (paths below are relative to
it unless they start with another directory). Nothing here is inherited from
sky130 or from FABulous placeholder timing. The older measurement documents
(`20261018-tile-*.md`, `20261023-tile-sdf.md`) cite earlier records and are
method notes only; none of their figures is used.

## Basis and caveats

- **Tool / flow**: klt `0.8.1.dev55+g879d39bad82b`, OpenROAD `26Q3-1510-g6cb3f2b704`,
  PDK `ihp-sg13g2` `fetched:0.3.0`.
- **Clock period**: 20.0 ns, fixed in the generated `sta.tcl/*.tcl` (`create_clock -period 20.0`).
  Spec row 5 ratifies no period, slack or Fmax figure; slack is reported *at* this period.
- **Parasitics**: SPEF-annotated, 365 of 365 nets at every corner (`sta.json`
  `corners[].spef_annotation`; `annotation_complete: true`).
- **Power is a default-activity estimate.** `sta.json` `corners[].power_basis` is
  `activity_source: engine_default`, `activity: null`; the generated STA scripts
  contain no `set_power_activity` or `read_vcd`. These are OpenSTA default-activity
  figures, **not workload power**.
- **Fmax is not claimed.** `sta.json` also carries a per-corner `fmax_mhz`
  (386.52 / 616.729 / 943.776 MHz at the three claim corners). That is unratified
  tool output (row 5 defers whether any Fmax is ratified); it is listed here for
  transparency only and no row below rests on it.
- **Single tile only.** The demonstration fabric has not been assembled.

## Architectural rows (inherited from `sky130-fpga`)

| Row | Result | Corner | Verdict | Evidence |
|---|---|---|---|---|
| Logic tile: 4× LUT4 + 1 FF per LUT, no carry | RTL and generated modules pass the stamped benches and the bitstream-level tests: `tb_lut4_slice`, `tb_logic_tile`, `tb_logic_tile_routed`, bitstream `comb` (5409 checks, 26/26 perturbations detected) and `reg` (139651 checks, 27/27) | n/a (functional) | pass (see scope note) | `measurements/v1-bitstream-verification/summary.txt` (19 PASS, 0 FAIL, 5 NOT-RUN). Synthesized cell mix in `synthesize.json` `instance_counts_by_type` has 4× `sg13g2_dfrbpq_1`. |
| Routing architecture: 4 tracks/edge, FABulous-style switch matrix | Switch matrix passes `tb_switch_matrix` (469 checks) and the FABulous equivalence bench (1343744 checks). The matrix is the sibling's same-index stand-in, not a verified Wilton-class matrix. Pin placement: 4 + 4 track pins per side; `layout/check-pin-abutment.py` is the audit. | n/a | pass for the stated scope; no inter-tile routing test | `measurements/v1-bitstream-verification/summary.txt`; `measurements/20261024-tile-pin-placement.md` (older record, method note); `place-and-route.json` `pins[]` (193 entries) |
| Bitstream: open, documented, FABulous-generated | FABulous 2.2.0 generates the stamped description with exit 0; the vendored assembler reproduces `bit_gen` output byte-for-byte; the loader rejects 11/11 malformed streams per fixture | n/a | pass | `measurements/g1-fabulous-generation/README.md`; `measurements/v1-bitstream-verification/summary.txt` |

## Parameter rows

| # | Parameter | Result | Corner | Verdict | Evidence |
|---|---|---|---|---|---|
| 1 | Cell library, supply, corners | `sg13g2_stdcell`, 1.2 V core. Claim corners analysed: `slow_1p08V_125C`, `typ_1p20V_25C`, `fast_1p32V_m40C`. Information-only 1.5 V-class corners (outside the claim): `slow_1p35V_125C`, `typ_1p50V_25C`, `fast_1p65V_m40C`; all six ran, none was dropped. | all six | pass (claim corners) | `sta.json` (claim), `sta-info.json` (information-only) |
| 2 | Routing layers for the switch matrix | Routed on Metal1–Metal5 with 0 route DRC violations, 0 unrouted of 359 signal nets, global-route overflow 0. Layer usage: Metal2 35.25 %, Metal3 26.98 %, Metal4 1.92 %, Metal1/Metal5/TopMetal1/TopMetal2 0 % demand. TopMetal1/TopMetal2 carry power straps only. | `interconnect_corner: nom` | pass (routes at the tile's own 4-track topology; no track-count change) | `place-and-route.json` `route_drc_violation_count`, `congestion.global_route`, `congestion.completeness`, `power.straps` |
| 3 | Tile area budget and aspect ratio | Die 10468.4 µm², core 8491.39 µm², utilization 43.8462 %, wirelength 14023 µm. Synthesized cell area 3557.4336 µm² (181 instances; sequential 195.9552 µm²). No area figure is ratified; this is the measured value only. | n/a | measured, not a pass/fail (spec ratifies no number) | `place-and-route.json` `die_area_um2`, `core_area_um2`, `utilization_pct`, `wirelength_um`; `synthesize.json` `area_um2`, `sequential_area_um2`, `instance_count` |
| 4 | Demonstration fabric size (2×2 to 4×4) | No fabric has been assembled; only a single-LOGIC4 harness on a 3×3 grid with `CAP_*` boundary cells. | n/a | **no evidence** | none; the fabric is out of scope until the tile is verified (see spec scope) |
| 5 | Timing | Setup/hold-clean at 20.0 ns at every claim corner, positive slack, 0 violations; table below. SDF-annotated gate-level re-run (slow corner) passes with partial annotation (see caveat). No Fmax claimed. | three claim corners | pass | `sta.json`; `functional-verification-sdf-slow.json`, `functional-verification-sdf-fast.json`, `functional-verification-sdf-negative.json` |
| 6 | Signoff: DRC and LVS | Tile DRC `status: clean`, 0 violations. Tile LVS `status: match`, `error_count: 0`, 2 warnings (`topology.power_only_pruned`: filler cells `SG13G2_FILL_1/2` pruned; `topology.top_level_pins_anchored`: 191 pins anchored by name). ERC `erc_status: clean` (0 findings) but its antenna check is `not_checked` (`missing_antenna_pdk`). DRC and LVS on the assembled fabric: no evidence. | n/a | pass for the tile; fabric **no evidence** | `drc.json`, `lvs.json`, `erc.json` |

### Row 5: setup and hold at 20.0 ns (claim corners)

| Corner | Worst setup slack (ns) | Worst hold slack (ns) | Setup / hold violations | Estimated power (mW, default activity) |
|---|---|---|---|---|
| `slow_1p08V_125C` | 17.4128 | 0.05689 | 0 / 0 | 0.0642 |
| `typ_1p20V_25C` | 18.3785 | 0.0359 | 0 / 0 | 0.0821 |
| `fast_1p32V_m40C` | 18.9404 | 0.02672 | 0 / 0 | 0.1006 |

Source fields: `sta.json` `corners[].worst_slack_ns`, `worst_hold_slack_ns`,
`setup_violation_count`, `hold_violation_count`, `estimated_power_mw`. Total
negative slack is 0 at every corner; `timing_status` is `constrained`;
`constraint_completeness.status` is `complete`.

### Row 1 information-only corners (outside the claim)

| Corner | Worst setup slack (ns) | Worst hold slack (ns) | Estimated power (mW, default activity) |
|---|---|---|---|
| `slow_1p35V_125C` | 18.355 | 0.03779 | 0.1025 |
| `typ_1p50V_25C` | 18.9278 | 0.02603 | 0.1303 |
| `fast_1p65V_m40C` | 19.2608 | 0.02033 | 0.164 |

Source: `sta-info.json` `corners[]`, same fields; SPEF-annotated 365 of 365 nets.

## Disclosures

- **SDF partial annotation (row 5)**: `environment.sdf.partial: true` in the cited
  gate-level report. Icarus annotates IOPATH/INTERCONNECT delays but drops the
  SDF `TIMINGCHECK` sections, so setup/hold are covered by the STA rows above, not
  by that run. The fast-corner report passes; the negative control (corrupted
  50 ns IOPATH) fails as intended (exit 3).
- **Hold margin is small** (0.02672 ns at the fast claim corner, 0.0359 ns typ); it is
  positive, with 0 violations, at the stated period.
- **Antenna**: `place-and-route.json` reports `antenna_violation_count: 0`, but the
  ERC antenna table is `not_checked` (no antenna rules in the PDK data supplied), so
  antenna compliance is not independently established.
- **Metal density**: `place-and-route.json` `coverage` records density fill and density
  compliance as `unsupported`; a zero route DRC count does not imply density compliance.
- **Tapcells/endcaps**: none (`power.placed.tapcells: 0`, `endcaps: 0`); the item-11 PDN
  grade for this is tracked in the manifest README, not here.
- **V1 record vintage**: the bitstream-level results come from
  `measurements/v1-bitstream-verification` (run at `dcca7fa`, 2026-10-18), not from a
  re-run at this record's commit. 5 benches are NOT-RUN there and are listed in that
  record.
- **No benchmarking against sky130** is made or implied.
