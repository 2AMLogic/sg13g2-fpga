# layout

Place-and-route of the stamped tile `logic_tile_routed` (issue #9).

| Path | What |
|---|---|
| `requests/` | `klt` request documents: `synthesize`, `place-and-route`, `lvs`, `erc-spec` (`__PLACEHOLDERS__` are filled in by the runner) |
| `run.sh` | wrapper over the shared `flow/klt-flow.sh`: synthesize → place-and-route → DRC → extract/LVS → ERC for the tile; single local flow, no STA (timing is #10) |
| `check-pin-abutment.py` | checks facing track pins from a `place-and-route.json` `pins[]` (`--self-test` for the negative cases); see `measurements/20261024-tile-pin-placement.md` |
| `records/<UTC date>-<short HEAD>/` | One envelope per step plus `<step>.rc`; append-only, never overwritten |

Re-run against the pinned `klt` without touching the host install:

```bash
KLT="uvx --from git+https://github.com/2AMLogic/klayout-tools.git@bf24d463fb3fc0f32b6f90d884086fc8946d74a8 klt" layout/run.sh
```

Requirements and traps are those of [`flow/README.md`](../flow/README.md) (docker `openroad`
wrapper mounts only `$PWD`; run from the repo, `PDK_ROOT` is exported by the script). Scratch
output goes to the gitignored `flow/build/tile/`. Interpretation of each record lives in
[`measurements/`](../measurements/); envelopes embed absolute worktree paths and `--check` only
passes in the tree that produced them.

## Power delivery (T1 item 11)

`requests/erc-spec.json` declares `VDD` and `VSS` as `kind: supply` nets (labels are on
TopMetal2 `134/25`, set as that layer's `label_layer`) and one substrate tie (`psub`: Activ ∩ pSD
outside NWell, to Metal1, net `VSS`). Record `20261027-79803ab` (host `klt 0.8.1.dev55`, not the
`bf24d463` pin above): `erc_status: clean`, `VDD` and `VSS` one island each, no
`erc.unconnected_net`, `erc.supply_short` or `erc.missing_tie`.

- **n-well tap is disclosed, not declared.** SG13G2 draws no nSD (`7/0`) shape; the n-well tap is
  Activ inside NWell with no pSD over it, which `ties[].tap_requires` (intersect only) cannot
  express. It is listed in `ties_disclosure.undeclared_classes` (`ties_disclosed_unexpressible`).
  Tracked at `2AMLogic/klayout-tools#4194`.
- **`tapcell_master: null` is by klt's own design.** klt documents `sg13g2_stdcell` as tapless and
  rejects a `power.tapcell` override (`docs/cli/place-and-route.md`, "Power delivery"), so the
  request cannot name one. The pinned grader (`7755612`) still requires it and grades item 11
  `unmet` / `no_pdn` for a built PDN (`pdn: true`). Filed as `2AMLogic/klayout-tools#4199`.
  Item 11 stays `unmet` until those are resolved upstream; it is not waived here.
