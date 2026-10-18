# layout

Place-and-route of the stamped tile `logic_tile_routed` (issue #9).

| Path | What |
|---|---|
| `requests/` | `klt` request documents: `synthesize`, `place-and-route`, `lvs`, `erc-spec` (`__PLACEHOLDERS__` are filled in by the runner) |
| `run.sh` | wrapper over the shared `flow/klt-flow.sh`: synthesize → place-and-route → DRC → extract/LVS → ERC for the tile; single local flow, no STA (timing is #10) |
| `records/<UTC date>-<short HEAD>/` | One envelope per step plus `<step>.rc`; append-only, never overwritten |

Re-run against the pinned `klt` without touching the host install:

```bash
KLT="uvx --from git+https://github.com/2AMLogic/klayout-tools.git@7ee09483b74867a47a05eb353015c2cf5ca33ef3 klt" layout/run.sh
```

Requirements and traps are those of [`flow/README.md`](../flow/README.md) (docker `openroad`
wrapper mounts only `$PWD`; run from the repo, `PDK_ROOT` is exported by the script). Scratch
output goes to the gitignored `flow/build/tile/`. Interpretation of each record lives in
[`measurements/`](../measurements/); envelopes embed absolute worktree paths and `--check` only
passes in the tree that produced them.
