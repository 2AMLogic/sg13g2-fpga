# Tile place-and-route, DRC, LVS: `logic_tile_routed` on SG13G2 (issue #9)

Append-only. Corrections go in a new record, not an edit to this one.

## Inputs

| Item | Value |
|---|---|
| Synthesis / P&R top | `logic_tile_routed` (`rtl/common/rtl/logic_tile_routed.v`; includes `lut4_slice` and `logic_tile_switch_matrix`). Chosen over `logic_tile` because only it contains the switch matrix. |
| Vendored RTL source | `reuse.lock.json` `source_commit` `42a8db00e138aa892a388b077a8ae2ea2ccab511`; RTL not edited |
| PDK | `flow/pdk.json` (IHP-Open-PDK `v0.3.0`), `sg13g2_stdcell`, `typ_1p20V_25C` for synthesis |
| Tool | `flow/toolchain.json`: klt `7ee09483…`, run as `uvx --from git+…@7ee09483… klt` (`klt 0.7.1.dev1743+g7ee09483b748`); OpenROAD `26Q3-1510-g6cb3f2b704` |
| Run | `layout/run.sh`, repo HEAD `ce45577`; envelopes in `layout/records/20261018-ce45577/`; requests in `layout/requests/` |
| Layers | Metal1–Metal5 signal, TopMetal1/TopMetal2 power (`power.preset: "sg13g2"`), spec row 2 |
| Area target | None. Spec row 3 ratifies none; the floorplan is utilization-driven (`utilization_pct: 40`, aspect 1.0). 40 % is a run parameter, not a spec figure. |
| Clock | 10 ns, `clk` port. Needed by CTS only; **not** a timing claim (spec row 5, #10). |

Single local flow; no corner or Monte Carlo grid.

## Result: the 4-track matrix routed on Metal1–Metal5

`place-and-route.json`: `status: ok`, `stage_reached: route`, `route_drc_violation_count: 0`,
`antenna_violation_count: 0`, global-route `total_overflow: 0`. The tile was not shrunk and the
matrix was not narrowed, so no fallback and no decision record is needed.

| Quantity (envelope field) | Value |
|---|---|
| Synthesized cells (`synthesize.json` `instance_count`) | 181 (57 `mux4_1`, 20 `mux2_1`, 4 `dfrbpq_1` flops), 3557.4 µm² |
| Die (`die_area_um2`) | 10468.4 µm², 102.315 × 102.315 µm (aspect 1.0) |
| Core (`core_area_um2`) | 8491.39 µm² |
| Utilization (`utilization_pct`) | 43.85 % (after CTS/repair; request was 40 %) |
| Wirelength (`wirelength_um`) | 12727 µm |

Observed routing pitch (tech LEF `sg13g2_tech.lef`, the pitch the router used): Metal1 0.42 µm (H),
Metal2 0.48 µm (V), Metal3 0.42 µm (H), Metal4 0.48 µm (V), Metal5 0.42 µm (H).

Global-route demand against resource (`congestion.global_route.overflow_per_layer`):

| Layer | Resource | Demand | Usage |
|---|---|---|---|
| Metal1 | 0 | 0 | 0 % |
| Metal2 | 2604 | 815 | 31.3 % |
| Metal3 | 3121 | 711 | 22.8 % |
| Metal4 | 2604 | 75 | 2.9 % |
| Metal5 | 3082 | 1 | 0.03 % |
| TopMetal1 / TopMetal2 | 352 / 286 | 0 / 0 | 0 % (power only) |

Total usage 13.3 %, worst layer 31.3 % (Metal2). **Caveat on what "routed" means here:** this is
the flat 181-cell synthesized netlist of the tile, placed and routed in isolation. It shows that
the matrix logic routes with wide margin on Metal2–Metal4. It does not show that the same tile
routes once its 4 + 4 edge tracks must land at fixed edge positions (see Abutment below), which
is the case that adds constraints.

## DRC, LVS, ERC

- **DRC** (`klt drc --deck sg13g2`): `status: clean`, 0 violations. The `coverage` block, verbatim:
  - `layers_in_stream_without_rules`: `8/2, 8/25, 10/2, 10/25, 14/0, 30/2, 30/25, 31/0, 134/2, 134/25, 189/4`
  - `inapplicable` (reported as `no_applicable_geometry`): `metal5.enclosing.mim.1`, `mim.enclosing.topvia1.1`
  - `deck_scope`: Act, Cnt, Gat, M1–M5, MIM, TM1, TM2, TV1, TV2, V1–V4
  - 43 rules in `rules_checked`; `unchecked_rules` and `unknown` empty.
  A clean DRC is not a claim about NWell (`31/0`) or pSD (`14/0`); the other listed layers are pin/label/boundary layers.
- **LVS** (`klt extract --abstract-cells 'sg13g2_*' --def-net-names`, then `klt lvs` against
  `place-and-route`'s `verilog_path`): `status: match`, `power_connectivity.status: match`.
  `mismatch_count: 2` are two `severity: warning` disclosures (`topology.power_only_pruned`:
  `SG13G2_FILL_1`, `SG13G2_FILL_2`; `topology.top_level_pins_anchored`), not mismatches. LVS
  is therefore at gate level with standard cells as black boxes; no transistor-level device is checked.
- **ERC**: `erc_status: clean`, exit code 4 because the SG13G2 antenna table is absent
  (`not_checked`); same gap as klayout-tools#3784. The OpenROAD antenna count above is the only antenna evidence.
- `klt {drc,lvs,erc} --check` on the envelopes: all exit 0.

## Abutment: NOT satisfied

Adjacent-tile abutment (pins on opposing edges aligned) was checked from
`flow/build/tile/.klt/place-and-route/logic_tile_routed.def` (`PINS 193`). **It fails:** all 193
signal pins, including every `n_*`, `e_*`, `s_*`, `w_*` track pin, `clk` and all 158 `cfg[*]` pins,
are placed on the east edge (x = 101.955 µm) at scattered y positions (`n_in[0]` y = 17.22 µm,
`s_out[0]` y = 57.54 µm, …). No pin sits on the edge its name implies, so a tile placed to the
north, south or west of this one has nothing facing it. The cause is the tool, not the design:
the `place-and-route` request's `io` object takes only `layer_h`/`layer_v`, and the generated
script calls `place_pins` with no side or position constraint.

Because the tile has to tile in a grid (spec row 3, binding), this blocks fabric assembly until pin
placement can be constrained. Not worked around with hand-edited DEF or custom OpenROAD scripts
(that would bypass `klt`). The tile was not changed.

## klayout-tools issues

| Gap | Issue |
|---|---|
| `place-and-route` cannot constrain I/O pin edge or position (new, this run) | 2AMLogic/klayout-tools#3885 |
| `klt erc` has no SG13G2 antenna table | #3784 (existing) |
| NWell `31/0` has no DRC rule | #3571 (existing) |
| pSD `14/0` has no DRC rule; `rules_skipped` gives no reason | #3787 (existing) |

The two MIM rules are reported as `inapplicable`/`no_applicable_geometry` in this klt version, so
the skip is now explained; no new issue. `30/2` and `30/25` (Metal3 pin/label) appear in the
without-rules list (the smoke run did not list them); they look like Metal3 pin/label layers, which would not need a rule, but that was not confirmed.

## Not established here

Timing (#10), parasitics, bitstream behaviour (#11), fabric-level DRC/LVS. Per-corner slacks in the
`place-and-route` envelope are a by-product of the 10 ns placeholder clock and are not cited.
