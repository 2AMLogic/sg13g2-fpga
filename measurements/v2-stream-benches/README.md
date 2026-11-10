# V2: stream-driven benches (issue #68, ADR-0004)

Append-only record. Produced by `verification/run.sh --out measurements/v2-stream-benches`
at the commit in `env.txt` (`48fb53c`), single local process, tools as pinned in
`flow/toolchain.json`. Verdicts: `results.tsv`; logs: `logs/`; summary: `summary.txt`.

## Result

24 PASS, 0 FAIL, 0 NOT-RUN. The five rows the V1 record listed NOT-RUN now run
on the vendored generators:

| bench | result |
|---|---|
| `tb_lut_basis` | 28032 checks, 73/73 cases |
| `tb_route_diag` | 24576 checks, 64/64 cases |
| `tb_ctrl_route` | 1296 checks, 20/20 cases |
| `tb_output_route` | 1376256 checks, 112/112 cases |
| `tb_configmem_equiv` | 7693 checks, 2 baseline streams |

All other rows are unchanged from V1. Generated stimulus streams and `.vvp`
binaries are not kept (regenerate with the command above); the simulation logs are.

## Claim boundary

Unchanged from V1. The four stream benches run the repository composition
(`logic_tile_routed`, flat cfg port); the sibling's `-DGEN_TILE` configuration
is not exercised. The switch matrix is the same-index stand-in, there is no
inter-tile routing, no timing, no area, and G5/G6 stay open. These benches are
not in `manifests/inventories/item-9.json` (inventory unchanged).
