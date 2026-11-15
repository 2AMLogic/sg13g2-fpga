# layout

Place-and-route of the stamped tile `logic_tile_routed` (issue #9).

| Path | What |
|---|---|
| `requests/` | `klt` request documents: `synthesize`, `place-and-route`, `lvs`, `erc-spec` (`__PLACEHOLDERS__` are filled in by the runner) |
| `run.sh` | wrapper over the shared `flow/klt-flow.sh`: synthesize → place-and-route → DRC → extract/LVS → ERC for the tile; single local flow, no STA (timing is #10) |
| `check-synth-fresh.sh` | cheap freshness check (no Yosys): re-hashes `rtl/common/rtl/*` and the record's committed `logic_tile_routed_synth.v` against its `synthesize.json` (T1 item 1; exit 3 = RTL edited without re-synthesis). `run.sh` copies the netlist into each record and runs the same check |
| `check-pin-abutment.py` | checks facing track pins from a `place-and-route.json` `pins[]` (`--self-test` for the negative cases); see `measurements/20261024-tile-pin-placement.md` |
| `records/<UTC date>-<short HEAD>/` | One envelope per step plus `<step>.rc`; append-only, never overwritten |

Re-run against the pinned `klt` without touching the host install:

```bash
KLT="uvx --from klayout-tools@git+https://github.com/2AMLogic/klayout-tools@v0.9.0 klt" layout/run.sh
```

SDF reports (`functional-verification-sdf-*.json`) committed in the records
above predate the `v0.9.0` bump (issue #99): the former `bf24d463` pin could
not annotate this netlist at all — its `functional-verification` rejected the
escaped-divider INTERCONNECT entries, narrowed upstream in klayout-tools#2897 —
so those runs used the host `klt`, not the declared pin, and the results stay
attributed to the klt that produced them (per-record attribution below; no
committed report is rewritten). `layout/sdf-verify.sh` runs cleanly under the
`v0.9.0` pin on a scratch copy of a record (with the
`klayout-tools[functional-verification]` extra, which the cocotb bench needs —
`uvx --from klayout-tools@git+…@v0.9.0` without the extra is enough for
`run.sh`/`smoke` verbs); the pin bump does not retroactively re-pin any
recorded result.

Requirements and traps are those of [`flow/README.md`](../flow/README.md) (docker `openroad`
wrapper mounts only `$PWD`; run from the repo, `PDK_ROOT` is exported by the script). Scratch
output goes to the gitignored `flow/build/tile/`. The routed stream is also copied into each
record as `logic_tile_routed.gds` (about 0.5 MB), committed so T1 item 2 can attest it
(`manifests/item-2.attestation.json`); the P&R flow is byte-deterministic (a re-run of
`20261030-09fa1bd` reproduced the `20261027-5171c5d` stream hash). The LVS envelope's
`environment.layout_sha256` is the hash of the extracted gate-level netlist, not of the GDS. Interpretation of each record lives in
[`measurements/`](../measurements/); envelopes embed absolute worktree paths and `--check` only
passes in the tree that produced them.

## Power delivery (T1 item 11)

`requests/erc-spec.json` declares `VDD` and `VSS` as `kind: supply` nets (labels are on
TopMetal2 `134/25`, set as that layer's `label_layer`) and one substrate tie (`psub`: Activ ∩ pSD
outside NWell, to Metal1, net `VSS`). Record `20261030-09fa1bd` (host `klt 0.8.1.dev849`, not the then-pinned `bf24d463`,
which the `v0.9.0` bump has since superseded): `erc_status: clean`, `VDD` and `VSS` one island each, no
`erc.unconnected_net`, `erc.supply_short` or `erc.missing_tie`.

The `erc` envelope records its spec path verbatim, and `klt signoff` re-reads that spec to grade
item 11, so `flow/klt-flow.sh` passes the committed `layout/requests/erc-spec.json` by
repo-relative path; an absolute `flow/build/` path (untracked) grades `supply_spec_incomplete`
in a clean checkout.

- **n-well tap is disclosed, not declared.** SG13G2 draws no nSD (`7/0`) shape; the n-well tap is
  Activ inside NWell with no pSD over it, which `ties[].tap_requires` (intersect only) cannot
  express. It is listed in `ties_disclosure.undeclared_classes` (`ties_disclosed_unexpressible`).
  Filed as `2AMLogic/klayout-tools#4194` (closed upstream); the disclosure stays regardless — it
  is in the committed record and still surfaces in the item-11 citation as
  `disclosed_undeclared_tie_classes`.
- **`tapcell_master: null` is by klt's own design, and item 11 grades `met` on it.** klt documents
  `sg13g2_stdcell` as tapless and rejects a `power.tapcell` override
  (`docs/cli/place-and-route.md`, "Power delivery"), so the request cannot name one. The grader
  changed, not the layout: the `klt` pinned in `.github/workflows/signoff.yml` (klt v0.9.0; that
  workflow is the pin's only home, per `manifests/README.md` § "Rules") reads `power.tapless` —
  `true` here — instead of grading a built PDN on a tapless library as a missing grid
  (klayout-tools#4250, closing #4199). The committed grade
  (`manifests/sg13g2-fpga.signoff.json`) is `met` on this record (`pdn: true`, `tapless: true`,
  `power_connectivity_status: "match"`); the layout and the ERC run are unchanged.
