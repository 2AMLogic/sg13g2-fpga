# Tile timing: clock period and constraints (issue #10, spec row 5)

Fixed in the commit that introduces this file, **before any `klt sta` number
exists for the routed tile**. The earlier `10.0` in `sta.json` was a smoke-run
placeholder for a different design (`flow/smoke/`), not a choice; no tile STA
had been run when this period was written.

| Item | Value | Rationale |
|---|---|---|
| Clock port | `clk` | The only clock port of `logic_tile_routed` (the four LUT slice flops). |
| Period | **20.0 ns** (50 MHz) | A round demonstration target set a priori. It is a stated period to be met at every claim corner (spec row 5 fallback), not an Fmax and not derived from any measurement, sky130 figure or FABulous BEL timing. It is not tuned afterwards: if a corner fails at 20 ns the failure is the result. |
| Input delay | 0.0 ns on every non-clock input | Tile boundary is unconstrained by any fabric-level budget (the fabric is out of scope), so the full period is the budget. Applies to `cfg`, which is quasi-static; it is **not** false-pathed, so `cfg` to output paths are timed conservatively. |
| Output delay | 0.0 ns on all outputs | Same reason. Makes the 16 edge outputs constrained rather than silently unconstrained. |
| Clock mode | propagated | The routed DEF is post-CTS (it contains the clock buffer), so hold must include real insertion delay and skew. |
| Parasitics | SPEF from `klt extract --parasitics` on the routed GDS | Spec row 5: parasitics come from the routed tile. |
| Claim corners | `slow_1p08V_125C`, `typ_1p20V_25C`, `fast_1p32V_m40C` | `spec/target-spec.md` row 1. `sta.json`. |
| Information corners | `slow_1p35V_125C`, `typ_1p50V_25C`, `fast_1p65V_m40C` | Outside the setup/hold claim. `sta-info.json`, same period. |

Fmax is not reported as a figure.
