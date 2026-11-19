# Area and cost per LUT4: `logic_tile_routed` on SG13G2 (issue #137)

Append-only. Corrections go in a new record, not an edit to this one.

## Inputs

The numeric inputs below are the first table of the command output in
[Method](#method) — not typed by hand.

| Item | Value |
|---|---|
| Layout record | `20261118-c1e517b` |
| `hdl_toplevel` (both envelopes) | logic_tile_routed |
| `place-and-route.json` `die_area_um2` | 10468.4 µm² |
| `place-and-route.json` `core_area_um2` | 8491.39 µm² |
| `place-and-route.json` `utilization_pct` | 43.8462 % |
| `synthesize.json` `area_um2` | 3557.4336 µm² |
| `synthesize.json` `instance_count` | 181 |
| LUT4 per tile | 4 (`spec/target-spec.md` row 1) |
| Price rate | 2800 EUR per mm2 (registered (drawn) die area submitted to the MPW run) |
| Ordering unit | one MPW submission (shuttle seat); the listed standard submission includes 40 bare-die samples of the submitted design, so a per-area figure here is that submission fee's share attributable to the given area, not a per-chip or per-die price |
| Price source | https://www.ihp-microelectronics.com/services/research-and-prototyping-service/mpw-prototyping-service/low-cost-open-source-mpw-access-1 (retrieved 2026-11-19) |

Context, hand-written: the `20261118-c1e517b` record is the ratified-20 ns
re-run (issue #91), byte-identical GDS/netlist and identical area figures to
the `20261030-09fa1bd` baseline. The URL, retrieval date and quoted line of
the price source live in
[`cost-per-lut/prices.json`](cost-per-lut/prices.json), which the script
validates (missing `ordering_unit`, `area_basis` or source fields are
rejected).

## Method

`measurements/cost-per-lut/estimate.py` (stdlib-only Python; `--self-test`
checks the arithmetic and the validation failures) generates exactly the two
tables in this record — the **Inputs** table above and the **Result** table
below. This command reproduces those two tables and nothing else; every
other sentence here is hand-written prose:

```sh
python3 measurements/cost-per-lut/estimate.py layout/records/20261118-c1e517b --markdown
```

The script reads the two committed record envelopes and refuses any record
whose envelopes do not both identify the design (`hdl_toplevel`) as
`logic_tile_routed` and agree — a counter smoke record or a mismatched pair
is a named-field error (exit 2). It then divides each area by
`LUT4_PER_TILE`, converts µm² → mm², multiplies by the cited rate and prints
the two tables. It fails loudly (exit 2) if a required record field or
price-source field is missing.

## Result (ESTIMATE — silicon area only)

The second table of the command output in [Method](#method) — not typed by
hand.

| Quantity | Value |
|---|---|
| Die area per LUT4 | 2617.1000 µm² = 0.0026171 mm² |
| Core area per LUT4 | 2122.8475 µm² = 0.0021228 mm² |
| Cell area per LUT4 (`synthesize.json` `area_um2` / 4) | 889.3584 µm² = 0.0008894 mm² |
| Submission fee attributable to one LUT4's die area (estimate) | 7.33 EUR |
| Submission fee attributable to one LUT4's core area (estimate) | 5.94 EUR |
| Submission fee attributable to one LUT4's cell area (estimate) | 2.49 EUR |

## What this is and is not

- **Estimate, not a ratified figure.** The spec row "Tile area / aspect"
  ratifies no area figure ("measured figure ratified by a later decision
  record"); nothing here ratifies one. Ratifying an area is a spec decision
  and out of scope for this record.
- **The area is measured, unratified and utilization-dependent.** The
  floorplan is utilization-driven (run parameter 40 %, settled at 43.85 %
  after CTS/repair) — see `measurements/20261018-tile-place-and-route.md`.
  The tile was not shrunk or re-run for this estimate.
- **Scope of the area.** The tile's committed layout excludes IO/padring,
  configuration-load logic, the clock tree outside the tile and any fabric
  periphery; the die area therefore understates what a fabric part would
  pay for. The LUT count is LUT4 only (no carry).
- **Scope of the cost.** A silicon-area-only arithmetic at MPW **shuttle**
  rates: `(price per mm²) × (area per LUT4)`. The rate buys **one MPW
  submission** — the listed standard submission includes 40 bare-die
  samples of the submitted design — so each figure above is that
  submission fee's share attributable to one LUT4's design area, **not** a
  per-chip or per-die price. It excludes packaging, test, NRE, yield,
  minimum purchase and die-count rounding. A shuttle seat is a prototyping
  purchase, not a volume production price; the run page states the
  per-customer price decreases as total registered area grows until a
  lowest price level is reached, so 2 800 EUR/mm² is the listed rate, not a
  guaranteed best rate. No minimum registered area is published for the
  SG13G2 open-source runs.
- **No comparison is made or implied.** No timing, Fmax or
  price/size comparison against other vendors' parts is inherited or stated;
  the r/nicechips post that motivated this estimate is context, not a
  source. No number here is inherited from sky130.
