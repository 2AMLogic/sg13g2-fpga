# Tile timing: `logic_tile_routed` at the SG13G2 core corners (issue #10)

Append-only. Corrections go in a new record, not an edit to this one.

## Inputs

| Item | Value |
|---|---|
| Clock, period, constraints | Fixed in commit `a059427` (`layout/timing-period.md`, `layout/requests/sta.json`), before any tile STA number existed: port `clk`, **20.0 ns**, input/output delay 0.0 ns, propagated clock. 20 ns is an a-priori stated period, not tuned and not an Fmax. |
| Run | `layout/run.sh` at repo HEAD `92a63aa` (the script commit), envelopes in `layout/records/20261018-92a63aa/` |
| Geometry | `geometry_source: routed`: the post-CTS routed DEF from the same run's `klt place-and-route` (top `logic_tile_routed`, 181 cells; see `20261018-tile-place-and-route.md`) |
| Parasitics | SPEF from `klt extract --parasitics --def-net-names --def-net-connections --def-pins` on the routed GDS, `read_spef` in `klt sta` (`clock_mode: propagated`) |
| Tools | klt `7ee09483…` (`0.7.1.dev1743+g7ee09483b748`), OpenROAD `26Q3-1510-g6cb3f2b704`; PDK `flow/pdk.json` (IHP-Open-PDK `v0.3.0`) |
| Liberty files | One `sta.tcl` per corner kept under `layout/records/20261018-92a63aa/sta.tcl/` and `sta-info.tcl/`; the `read_liberty` lines name `<PDK>/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_<corner>.lib` for each corner below |
| Timing source | Only this run. No number is taken from `sky130-fpga` or from FABulous placeholder BEL timing. |

Single `klt sta` request per corner set over one fixed DEF; no place-and-route per corner.

## Result: claim corners (1.2 V core)

All three corners ran. Setup and hold violations: 0 at every corner. `timing_status: constrained`,
`constraint_completeness: complete`, max-transition and max-capacitance checks `checked`, 0 violations.

| Corner (Liberty file) | Worst setup slack | Worst hold slack | Critical setup path | Worst hold path |
|---|---|---|---|---|
| `slow_1p08V_125C` (`sg13g2_stdcell_slow_1p08V_125C.lib`) | +17.500 ns | +0.0538 ns | `cfg[132]` → `e_out[3]` | `cfg[81]` → `e_out[0]` |
| `typ_1p20V_25C` (`sg13g2_stdcell_typ_1p20V_25C.lib`) | +18.434 ns | +0.0341 ns | `cfg[132]` → `e_out[3]` | `cfg[81]` → `e_out[0]` |
| `fast_1p32V_m40C` (`sg13g2_stdcell_fast_1p32V_m40C.lib`) | +18.976 ns | +0.0255 ns | `cfg[132]` → `e_out[3]` | `cfg[81]` → `e_out[0]` |

Reading it:

- Setup: the longest path is an input-to-output combinational path through the switch matrix, about 2.5 ns at the slow corner (20 ns period minus slack).
  Every reported worst path (setup and hold) starts at a `cfg` bit and ends at an edge output, i.e. an in-to-out path. These are timed as ordinary
  paths with 0 ns I/O delays; `cfg` is quasi-static and was deliberately not false-pathed (`layout/timing-period.md`).
  The registered paths do not appear as the worst path in either direction.
- Hold: the worst slack is smallest at the **fast** corner (+0.0255 ns), as expected. It is positive but small, and it is a 0 ns-input-delay,
  0 ns-output-delay output hold check, not a register-to-register one. The margin is a property of those constraints, not of the tile.
- `clock_skew_ns` is reported as 0 and the clock network latency as at most 0.198 ns (propagated).
  `clock_sinks` is reported as 2 for a tile with 4 flops; I did not investigate this, it may count CTS leaf nets.

## Information only: 1.5 V-class corners (outside the setup/hold claim)

Same DEF, SPEF, period and constraints (`layout/requests/sta-info.json`). All ran, 0 violations.

| Corner | Worst setup slack | Worst hold slack |
|---|---|---|
| `slow_1p35V_125C` | +18.415 ns | +0.0358 ns |
| `typ_1p50V_25C` | +18.963 ns | +0.0248 ns |
| `fast_1p65V_m40C` | +19.284 ns | +0.0195 ns |

## What `klt sta` can and cannot run

- **Corners.** `klt sta` resolved all six SG13G2 corner names as written in `pdk.corners`
  (`slow_1p08V_125C`, `typ_1p20V_25C`, `fast_1p32V_m40C`, `slow_1p35V_125C`, `typ_1p50V_25C`, `fast_1p65V_m40C`). None failed; no error text to quote.
- **SPEF extraction.** `klt extract --parasitics --spef` ran on SG13G2 and `klt sta` read it (`spef_path` set), with **incomplete annotation**:

  | Field (`spef_annotation`) | Value |
  |---|---|
  | `design_nets_annotated` / `design_nets_total` | 325 / 365 |
  | `unannotated_driver_count` | 40 |
  | `reader_warning_count` | 330 (`STA-1650`, "net … not found") |
  | `annotation_complete` | `false` |

  The 40 unannotated nets are the internal nets under the four generate-block slice instances (`g_slice[i].u_slice/…`):
  the SPEF spells them with the escaped bracket and a `_` where the linked design has `.`. Those drivers are timed with LEF capacitance only. **The slacks above are therefore
  not a full real-parasitics measurement**; they are real-parasitics for 325 of 365 nets. Retested the same extract and a single typical-corner `klt sta`
  with klt `0.7.1.dev1865+g1c5546271c61` (host install): identical 325 / 365 and identical slacks. Filed as
  [2AMLogic/klayout-tools#3900](https://github.com/2AMLogic/klayout-tools/issues/3900).
- Not run, by choice: SDF-annotated gate-level re-simulation (spec row 5 stretch), power analysis, OCV/MC derates.

## Friction

- #3900 (above). The envelope still does not name the Liberty file per corner (klayout-tools#3785 is closed upstream but the pinned `7ee09483` predates the fix), so the generated scripts are kept as evidence.

## What this does and does not establish

Supports: with the period fixed at 20.0 ns beforehand, the routed tile shows no setup or hold violation at the three claim corners under the
stated constraints and 89 % net-level parasitic annotation (325 / 365). Does not support: an Fmax (none is reported; the stated period is far above the longest path, so slack is not a speed figure),
register-to-register timing at tile boundary budgets from a fabric, or a fully back-annotated number until #3900 is resolved. `layout/run.sh`'s `--check` runs
on the DRC/LVS/ERC envelopes passed (exit 0). Not verified: re-running from a clean clone.
