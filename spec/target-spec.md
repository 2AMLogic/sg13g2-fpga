# Target spec: LUT4-class logic tile + demonstration fabric on SG13G2

- **Status**: Ratified by [ADR-0001](decisions/0001-ratify-target-spec.md).
  Rows that need a measurement are ratified as *target / fallback / stretch
  with the evidence that will back them*. This document contains no timing,
  area or pitch figure, and none is inherited.
- **Port plan**: [`porting-plan.md`](porting-plan.md) (sibling read at
  `42a8db00e138aa892a388b077a8ae2ea2ccab511`).
- **Scope**: one logic tile type plus a 2×2 to 4×4 demonstration fabric.
  Growing the fabric, adding tile types or widening the routing is out of
  scope until the tile is verified; such proposals go in an issue.

## Architectural rows (inherited from `sky130-fpga`, cited not re-argued)

| Parameter | Fallback | Target | Stretch |
|---|---|---|---|
| Logic tile | 4× LUT4 + 1 FF per LUT, no carry | same | carry chain as a later tile revision |
| Routing (architecture) | 4 tracks/edge, FABulous-style switch matrix | same | — |
| Bitstream | open, documented, FABulous-generated | same | — |

## Parameters decided here

| # | Parameter | Fallback | Target | Stretch | Binding conditions | Evidence that will back it |
|---|---|---|---|---|---|---|
| 1 | Standard-cell library, supply, corners | `sg13g2_stdcell`, 1.2 V core, the three 1.2 V core liberty corners (below) | same, plus the three 1.5 V-class corners reported as information, outside the claim | — | Corner set re-listed from the PDK commit pinned by #5. A corner a tool cannot run is recorded as such, not dropped. | `flow/pdk.json` from #5; liberty file list at that commit; STA records (#10) |
| 2 | Routing layers for the switch matrix | Metal1–Metal5 signal, TopMetal1/TopMetal2 reserved for power | same | TopMetal use for signal considered only by a later decision record | The inherited 4-track matrix has not been shown to route on the thin metals. A change of track count or topology is a spec change, never a quiet one. | Routed tile, route DRC count, observed pitch in `layout/` (#9) |
| 3 | Tile area budget and aspect ratio | Tile abuts in a grid; area is whatever the inherited tile needs, reported | Area and aspect ratio measured, then recorded as a ratified figure by a later decision record | — | **No area number is ratified now.** The tile is not shrunk to make it route. Abutment in a grid is binding. | Placed-and-routed tile area and utilization (#9) |
| 4 | Demonstration fabric size | 2×2 | 2×2 to 4×4, single logic tile type | — | Boundary `CAP_*` cells are harness-only, not logic tile types (see porting plan). No fabric above 4×4. | Bitstream-level tests on the simulated fabric (#11) |
| 5 | Timing | Setup/hold-clean at a stated clock period at every claim corner (row 1) | Same, with the period chosen before measurement, and an Fmax figure reported only if derived from characterized data | SDF-annotated gate-level re-simulation | **No period, Fmax or slack number is ratified now.** The period is fixed before the first measurement, not tuned after. Parasitics are extracted from the routed tile. No sky130 or FABulous placeholder number. Whether an Fmax figure is ratified at all is deferred. | `klt sta` records per corner with SPEF (#10) |
| 6 | Signoff | DRC clean; LVS gaps attributed to filed klayout-tools issues | DRC and LVS clean on the tile and on the assembled fabric | — | Every rule the deck cannot check and every device it cannot extract is filed, not waived. | DRC/LVS reports under `layout/` (#9) |

## Corners and liberty files

`sg13g2_stdcell` ships six liberty files (host PDK listing, 2026-10-17;
nominal supply and temperature read from each file header). The corner set
must be re-listed from the PDK commit that #5 pins.

| Liberty file | Supply | Temp | Class | Claim? |
|---|---|---|---|---|
| `sg13g2_stdcell_slow_1p08V_125C.lib` | 1.08 V | 125 °C | 1.2 V core, slow | **yes** |
| `sg13g2_stdcell_typ_1p20V_25C.lib` | 1.20 V | 25 °C | 1.2 V core, typical | **yes** |
| `sg13g2_stdcell_fast_1p32V_m40C.lib` | 1.32 V | −40 °C | 1.2 V core, fast | **yes** |
| `sg13g2_stdcell_slow_1p35V_125C.lib` | 1.35 V | 125 °C | 1.5 V class | information only |
| `sg13g2_stdcell_typ_1p50V_25C.lib` | 1.50 V | 25 °C | 1.5 V class | information only |
| `sg13g2_stdcell_fast_1p65V_m40C.lib` | 1.65 V | −40 °C | 1.5 V class | information only |

The tile runs on the 1.2 V core, so the claim is the 1.08 / 1.20 / 1.32 V
set. The 1.5 V-class files are characterized and reported but do not enter
the setup/hold claim.

### What `klt sta` can and cannot run

`klt sta` (installed `0.7.1.dev1765+gb61f753d0369`) documents multi-corner
analysis of one fixed geometry through `pdk.corners` and SPEF back-annotation.
**Not yet known:** which of the six corners it resolves on SG13G2, and whether
SPEF extraction runs on SG13G2. This issue ran no STA. #5's smoke run covers
one typical corner only; the full corner capability is established by #10,
and a corner it cannot run is recorded there as a gap.

## Open questions

Resolutions and deferrals are in
[ADR-0001](decisions/0001-ratify-target-spec.md).
