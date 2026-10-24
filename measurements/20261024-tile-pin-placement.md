# Tile pin placement for abutment: `logic_tile_routed` on SG13G2 (issue #14)

Append-only. Corrections go in a new record, not an edit to this one. Compares against
`measurements/20261018-tile-place-and-route.md` (unconstrained run, which left that record untouched).

## Inputs

| Item | Value |
|---|---|
| Design | `logic_tile_routed`, vendored RTL not edited |
| Tool | klt `bf24d463fb3fc0f32b6f90d884086fc8946d74a8` (`0.7.1.dev2056+gbf24d463fb3f`), contains klayout-tools#3887; run as `uvx --from git+…@bf24d463… klt`. OpenROAD `26Q3-1510-g6cb3f2b704` (docker). |
| Run | `layout/run.sh`, `RECORD_ID=20261024-bf24d46`; envelopes in `layout/records/20261024-bf24d46/`; `flow/smoke` re-run on the new pin: `flow/smoke/records/20261024-bf24d46/` (all steps exit 0, ERC exit 4 as before) |
| Request | `layout/requests/place-and-route.json`, `io.pin_constraints` only; no hand-edited DEF, no custom OpenROAD script. Floorplan, seed, utilization (40 %), aspect unchanged. |
| Live verification | klayout-tools#3930 is **still open** at 2026-10-24; this run is the first real OpenROAD evidence. Friction filed: klayout-tools#4155. |

## Pin-placement rule

- Track pins (4 + 4 per side): `n_in[0..3]` on north with `s_out[0..3]` on south share one x range
  (10–13 µm); `n_out` with `s_in` share another (22.5–25.5 µm). `e_in`/`w_out` share a y range
  (9.6–12.3 µm); `e_out`/`w_in` another (23–25.7 µm). All `ordered`. A tile abutting a copy of itself
  therefore meets `n_out[t]`↔`s_in[t]`, `s_out[t]`↔`n_in[t]`, `e_out[t]`↔`w_in[t]`, `w_out[t]`↔`e_in[t]`.
  The issue's "north and south pins of index t share x" is read as these facing pairs: an `_in` and `_out`
  pin of one index cannot share a position on one edge.
- `clk`: south edge, 30–40 µm. `cfg[*]` (158 pins, not part of the abutment interface): `cfg[0..52]`
  north, `cfg[53..105]` west, `cfg[106..157]` east, each 30–100 µm, unordered. Rule: after the track
  pins on each edge, split by index so each range has more slots than pins. A first attempt with 79
  `cfg` pins per edge failed (`PPL-0110/0111`, 47 and 54 slots available). A second, with tracks in
  wider ranges, placed every track pin on the correct edge but misaligned facing pairs by up to 2.9 µm
  (ranges wider than the pin group do not fix a position). Final ranges equal each group's slot span.
  Those two attempts are not kept as records.
- Consequence: `cfg[*]` pins on a neighbour-facing edge have nothing to abut with. Distributing
  configuration across a fabric is the fabric issue's problem, not this one's.

## Result

`place-and-route.json`: `status: ok`, `stage_reached: route`, `route_drc_violation_count: 0`,
`antenna_violation_count: 0`, global-route `total_overflow: 0`, `pins[]` has 193 entries (191 signal
ports plus `VDD`, `VSS`).

`layout/check-pin-abutment.py` on `pins[]`: **abutment satisfied** — every `n_*` pin on north, `s_*`
south, `e_*` east, `w_*` west; facing pairs coincide (e.g. `n_out[0]` x = 22.56 = `s_in[0]`;
`e_out[0]` y = 23.1 = `w_in[0]`). `--self-test` shows the check fails on an all-east envelope
(24 findings) and on one shifted pin. Pins per edge: east 60, north 62, west 61, south 10.

| Quantity | Unconstrained (`20261018-ce45577`) | Constrained (`20261024-bf24d46`) |
|---|---|---|
| Die area | 10468.4 µm² | 10468.4 µm² |
| Utilization | 43.85 % | 43.85 % |
| Wirelength | 12727 µm | 14246 µm (+11.9 %) |
| Route DRC / antenna | 0 / 0 | 0 / 0 |
| Global-route overflow | 0 | 0 |
| Routing usage, total / worst layer | 13.3 % / 31.3 % (Metal2) | 15.0 % / 35.3 % (Metal2) |

Routing got somewhat worse (wirelength and Metal2 demand up) but stayed far from congestion. The tile
was not shrunk and the matrix was not narrowed; no fallback or decision record is needed. This is a
single placement seed; it is not a statement about sensitivity to the seed.

## DRC, LVS, ERC

- **DRC**: `clean`, 0 violations, 54 rules checked, `unknown` empty. Deck scope now includes NW and pSD
  (previous record: not covered), a change from the newer klt pin, not from the layout.
  `unchecked_rules`: `NW.b1` (net-aware PWell width between NWell regions; only the geometric
  `nwell.space.1` ran). `layers_in_stream_without_rules`: `8/2, 8/25, 10/2, 10/25, 30/2, 30/25, 134/2,
  134/25, 189/4`. `inapplicable` (`no_applicable_geometry`): `metal5.enclosing.mim.1`,
  `mim.enclosing.topvia1.1` and six `nwell.*nactiv*` rules.
- **LVS** (gate level, standard cells abstracted): `match`, power connectivity `match`; two warnings
  (`topology.power_only_pruned`, `topology.top_level_pins_anchored`), as before.
- **ERC**: `erc_status: clean`, exit 4 (SG13G2 antenna table absent), same gap as klayout-tools#3784.
- `klt {drc,lvs,erc} --check`: all exit 0.
- STA/SPEF ran as part of `layout/run.sh` (envelopes in the record). No timing claim is made here;
  timing stays with #10.
