# verification

Bitstream-level and BEL-level verification of the stamped tile, run with
Icarus Verilog (version pinned in `flow/toolchain.json`) against the stamped
RTL in `rtl/common/rtl/`. The benches are self-checking Verilog stamped under
`verification/common/` and are run as stamped (not cocotb; see issue #11).

## Cold start

```bash
verification/run.sh --setup        # once: fetch the pinned OSS CAD Suite + FABulous venv into flow/build/ (nothing host-wide)
verification/run.sh                # run everything; logs in flow/build/verification/
verification/run.sh --out measurements/<new-id>   # keep a record (refuses a non-empty dir)
verification/run.sh --update-fixtures             # rewrite verification/bitstream/ after an intended change
```

Needs `iverilog`/`vvp` on `PATH` at the pinned version, `python3`, `uv`, `curl`.
Single process, no `-j`; each `vvp` run is bounded by `SIM_TIMEOUT_SECONDS`
(default 600). Without the toolchain the generated-fabric benches are listed
`NOT-RUN` with the reason. Exit status is nonzero only if a bench FAILs.

## What each stage does and does not prove

| Stage | Proves | Does not prove |
|---|---|---|
| `tb_lut4_slice`, `tb_logic_tile`, `tb_switch_matrix`, `tb_logic_tile_routed`, `tb_logic_tile_gapfill` | stamped RTL behaves as its benches specify | anything about the FABulous-generated modules or a bitstream |
| `gen_switch_matrix_drift` | stamped switch-matrix RTL equals its stamped generator's output | |
| `tb_lut4_ff_bel_equiv`, `tb_switch_matrix_equiv` | FABulous-generated BEL / switch matrix equal the stamped RTL (same pinned generator output) | routing quality |
| `tb_boundary_fwd` | generated tile forwards clock/frame ports | |
| `fixtures_*`, `assembler_reproduce` | `top_io.v`/`top_reg.v` map (yosys + nextpnr-generic) onto the generated fabric; the assembled stream is byte-identical to FABulous `bit_gen`; fixtures in `bitstream/` are reproducible | |
| `tb_logic_tile_bitstream` (`comb`, `reg`) | a stream loaded through the frame interface configures the single-LOGIC4 harness so the mapped design behaves as its independent oracle; every used routing/LUT/FF bit flip is detected (`+mutate`); malformed streams are rejected (`+expect_reject`) | see below |

**Claim boundary.** Single-LOGIC4 harness; the switch matrix is the sibling's
same-index stand-in, not a verified Wilton-class matrix; no inter-tile routing;
no timing; no area. Sibling gaps G5 and G6 are inherited open. Nothing here
says the fabric is verified. The 2x2 to 4x4 demonstration fabric is untested.

Benches `tb_lut_basis`, `tb_route_diag`, `tb_ctrl_route`, `tb_output_route`
and `tb_configmem_equiv` need stream/vector generators from the sibling's
unstamped `flow/` and are reported `NOT-RUN` (ADR-0002).

Sibling `*results*.txt` files are not evidence here; only runs made in this
repo count. Records are in `measurements/`.
