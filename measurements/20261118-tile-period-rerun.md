# Tile re-run at the ratified 20.0 ns implementation period (issue #91)

`synthesize.json` and `place-and-route.json` now carry `clock_period_ns: 20.0`,
matching `sta.json` and `sta-info.json`.

| | Baseline | New |
|---|---|---|
| Record | `layout/records/20261030-09fa1bd` (period 10.0 ns) | `layout/records/20261118-c1e517b` (period 20.0 ns) |
| klt | `0.8.1.dev849+gf05774458ae2` | `0.9.0.dev1379+g5dbbad05ff42` (pinned v0.9.0, via uvx) |

The baseline predates the v0.9.0 pin, so the klt change is a second variable.
#79's v0.9.0 10 ns record had not landed, so it was not used.

## Area and utilization (final top-level fields of `place-and-route.json`)

| Field | 10.0 ns | 20.0 ns | Delta |
|---|---|---|---|
| `die_area_um2` | 10468.4 | 10468.4 | 0 |
| `core_area_um2` | 8491.39 | 8491.39 | 0 |
| `utilization_pct` | 43.8462 | 43.8462 | 0 percentage points |

A zero delta is the result. The routed stream (`logic_tile_routed.gds`), the
routed netlist and the synthesized netlist (`netlist_sha256` `0ce67b67...`) are
byte-identical to the baseline, as are synthesized area (3557.4336 µm²) and the
instance count (181). The only synthesis field that changed is
`clock_targets.delay_target_ps` (10000 to 20000). In this flow, with this klt,
the implementation period did not change cell sizing, buffering or placement.

Two place-and-route outputs changed alongside the period (the second has an unexcluded second cause, below). Both are in
`layout/records/20261118-c1e517b/place-and-route.json`:

- **Setup slack moved by +10 ns.** All six per-corner `setup_slack_ns` values
  and both top-level fields shift: `worst_setup_slack_ns` 9.29232 to 19.2923
  and `worst_slack_ns` 9.56681 to 19.5668 (per corner: 9.71672 to 19.7167,
  9.80473 to 19.8047, 9.29232 to 19.2923, 9.56705 to 19.5671, 9.56681 to
  19.5668, 9.71878 to 19.7188). Hold slack is unchanged at 0.14403. With a
  byte-identical GDS and netlist and unchanged path delays, this shift is the
  in-record evidence that the 20.0 ns constraint reached place-and-route, not
  just the request file.
- **`estimated_power_mw` 0.1643 to 0.0822** (a factor of 1.9988), on an
  identical netlist and placement. The mechanism was not instrumented. The klt
  bump is a second variable that is not excluded: `power_basis` is a new
  v0.9.0 field absent from the baseline record, so a changed place-and-route
  power model cannot be ruled out from the records alone. One control points
  against the klt bump moving the number: `sta.json`'s own
  `estimated_power_mw` is identical across the version change at the fixed
  20 ns STA period (slow 0.0642, typ 0.0821, fast 0.1006 in both records), and
  the new place-and-route value 0.0822 now agrees with the typ corner.

These are the only period-associated deltas in the tile-flow envelopes (`sta`,
`sta-info`, `extract`, `drc`, `lvs`, `synthesize`, the SDF runs and
`place-and-route`). The following also differ between the two records but are
klt v0.9.0 tool-version artifacts, not period effects:
`applied.{placement_density,route_allow_congestion,route_congestion_iterations,signal_layers}`,
`power_basis.*`, `abc_constr.*`, `timing.regions[].module`, the extra
`synthesize.check.*`, `*.stderr` and `logic_tile_routed_synth.v` outputs, and
SDF `schema_version` 1 to 2.

## Verdicts observed

- Synthesis, place-and-route, DRC (`clean`), extract, LVS (`match`), parasitic
  extraction, STA and STA-info: step rc 0. `synthesize`, `drc`, `lvs` and `erc`
  `.check.rc` are 0.
- ERC step rc 4 with `erc_status: clean`, the same as the baseline record.
- STA (SPEF annotated, 0 violations): worst setup / worst hold slack in ns:
  slow_1p08V_125C 17.4128 / 0.05689, typ_1p20V_25C 18.3785 / 0.0359,
  fast_1p32V_m40C 18.9404 / 0.02672. These equal the baseline values.
- SDF simulation (`layout/sdf-verify.sh 20261118-c1e517b`, run with the
  `functional-verification` extra): slow exit 0, fast exit 0; the
  corrupted-delay negative control fails as required (exit 3, both bench tests
  fail).

No step failed at 20.0 ns and no corner was waived; nothing was tuned.
