# flow/ — digital toolchain bring-up

Pins and a smoke run of the `klt` digital flow on IHP SG13G2 / `sg13g2_stdcell`,
made before any tile work (issue #5). The smoke design (`smoke/counter.v`, an
8-bit counter with a synchronous reset) is a throwaway fixture. It is not the
tile, does not use FABulous, and decides nothing about routing layers, the
corner set or the clock (those are #2). **Nothing from this run may be cited
in a block manifest or the spec.**

| File | Pins |
|---|---|
| `pdk.json` | IHP-Open-PDK `v0.3.0`, full commit `5cccb161…bdca9e`, `sg13g2_stdcell` |
| `toolchain.json` | klayout-tools commit `7ee09483…2ef3`, Yosys, OpenROAD, KLayout, Icarus |

**How the pins were established.** `klt pdk find` reports only a stamp
(`fetched:0.3.0`), not a commit, and the local bundle has no git metadata, so
the PDK commit is the one the upstream tag `v0.3.0` points at
(`git ls-remote`). The local bundle's sha256 is recorded beside it, but the
bundle cannot be proven to equal that commit (klayout-tools#3786). The `klt`
commit comes from the host install's `uv-receipt.toml`; `klt --version` alone
(`0.7.1.dev1743+g7ee09483b748`) is only an abbreviated hash of a dev build.

## Cold start

From a clean clone, with the SG13G2 PDK installed (`klt pdk find --pdk
ihp-sg13g2` resolves it) and `yosys`, `openroad`, `jq` on `PATH`:

```bash
flow/smoke/run.sh [--pdk-root <dir containing ihp-sg13g2/>]
# or, against the pinned klt without touching the host install:
KLT="uvx --from git+https://github.com/2AMLogic/klayout-tools.git@7ee09483b74867a47a05eb353015c2cf5ca33ef3 klt" flow/smoke/run.sh
```

The script writes a new `flow/smoke/records/<UTC date>-<short HEAD>/` (it
refuses to overwrite one; records are append-only evidence) containing one
envelope per step, `<step>.rc` with its exit code, and `<step>.not-run` with a
reason for any step that could not run. Scratch output goes to the gitignored
`flow/build/`. Single local `klt` runs only; no corner or Monte Carlo grids.

Two environment traps found while bringing this up, both handled in `run.sh`:

- `~/.local/bin/openroad` is a docker wrapper that mounts only `$PWD` and the
  PDK root. Run from the repo root, and export `PDK_ROOT` explicitly: with it
  unset the wrapper calls a bare `klt pdk find`, which resolved `gf180mcuA`
  on this host, so the container could not read the SG13G2 Liberty files.
- Envelope paths are absolute strings for `place-and-route` and repo-relative
  objects for `synthesize`/`sta`; `run.sh` accepts both. Records therefore
  embed the absolute path of the worktree they were produced in.

## What each step proves

| Step | Request / command | What it proves | Result in `records/20261017-813553e/` |
|---|---|---|---|
| `synthesize` | `synthesize.json` | Yosys + ABC map RTL onto `sg13g2_stdcell` at the typ 1.20 V 25 °C Liberty | ok, 36 cells, 642.3 µm² |
| `place-and-route` | `place-and-route.json` | OpenROAD floorplan → place → CTS → route with a PDN (`power.preset: "sg13g2"`) reaches `route`, and the DEF is merged to GDS | ok, `stage_reached: route`, route DRC 0, antenna 0, 2411.8 µm² die |
| `drc` | `klt drc --deck sg13g2` | The routed GDS passes the curated SG13G2 deck (deck coverage below) | clean, 0 violations |
| `extract` + `lvs` | `lvs.json` | Layout (std cells abstracted as black boxes, `--def-net-names`) matches the as-built gate-level netlist | `status: match`, `power_connectivity.status: match` |
| `erc` | `erc-spec.json` | Connectivity ERC on the routed GDS | `erc_status: clean`; antenna `status: not_checked`, exit 4 (below) |
| `sta` | `sta.json` | OpenSTA times the routed DEF, ideal clock, at one typical corner | ok, WNS +9.115 ns, hold +0.266 ns at a placeholder 10 ns clock |

Notes per step:

- **LVS reference.** The reference is `place-and-route`'s `verilog_path` (the
  as-built netlist, CTS buffers and antenna diodes included), not the
  pre-CTS `synthesize` netlist, because the layout contains the CTS buffer.
  `mismatch_count: 2` is two `severity: warning` disclosures (power-only
  fill cells pruned; 10 top-level pins anchored by name), not mismatches.
- **DRC coverage block** (verbatim from `drc.json`; the other 43 rules are in
  `rules_checked`):

  ```json
  "layers_in_stream_without_rules": ["8/2","8/25","10/2","10/25","14/0","31/0","134/2","134/25","189/4"],
  "rules_skipped": ["metal5.enclosing.mim.1","mim.enclosing.topvia1.1"],
  "deck_scope": ["Act","Cnt","Gat","M1","M2","M3","M4","M5","MIM","TM1","TM2","TV1","TV2","V1","V2","V3","V4"]
  ```

  The `x/2`, `x/25` and `189/4` entries are pin/label/boundary layers.
  `31/0` (NWell) is tracked as klayout-tools#3571 and `14/0` (pSD) is
  filed as #3787, which also asks the envelope to say why a rule was
  skipped (the two MIM rules are presumably skipped because the layout has
  no MIM). A clean DRC here is not a claim about NWell or pSD.
- **ERC.** `klt erc --pdk` has no SG13G2 antenna table, so antenna is
  `not_checked` and the exit code is 4 (klayout-tools#3784). The OpenROAD
  `antenna_violation_count: 0` in the `place-and-route` envelope is the only
  antenna evidence in this run.
- **STA.** `klt sta` ran to completion on the routed DEF (`geometry_source:
  routed`, `clock_mode: ideal`, no SPEF) and used
  `<PDK_ROOT>/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib`.
  The envelope names only the deck (`sg13g2_stdcell__typ_1p20V_25C`), not the
  file (klayout-tools#3785), so `run.sh` keeps the generated script as
  `sta.tcl`, whose `read_liberty` line is the evidence. The 8 `q[*]` outputs
  are unconstrained (no output delay) and `constraint_completeness` is
  `incomplete`. Which corners `klt sta` should run is #2's question.
- **`--check`.** `drc.check.rc`, `lvs.check.rc` and `erc.check.rc` are cheap-mode
  `klt <cmd> --check` runs on the envelopes just written (all 0). They re-hash
  the layout under `flow/build/`, so they only pass in the tree that produced
  the record.

## Friction filed at 2AMLogic/klayout-tools

- #3784 `klt erc` has no SG13G2 antenna table (exit 4).
- #3785 `klt sta` envelope does not name the Liberty file.
- #3786 a fetched PDK bundle records no upstream commit.
- #3787 pSD has no DRC rules; `rules_skipped` gives no reason.
