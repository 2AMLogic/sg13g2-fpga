# verification

Bitstream-level and BEL-level verification of the stamped tile, run with
Icarus Verilog (version pinned in `flow/toolchain.json`) against the stamped
RTL in `rtl/common/rtl/`. The benches are self-checking Verilog stamped under
`verification/common/` and are run as stamped (not cocotb; see issue #11).

## Cold start

```bash
verification/cold-start.sh         # the next two lines in one command (the T1 item-9 cold start)
verification/run.sh --setup        # once: fetch the pinned OSS CAD Suite + FABulous venv into flow/build/ (no host-wide EDA install; host prerequisites listed below)
verification/run.sh                # run everything; logs in flow/build/verification/
verification/run.sh --out measurements/<new-id>   # keep a record (refuses a non-empty dir)
verification/run.sh --update-fixtures             # rewrite verification/bitstream/ after an intended change
verification/blinky.sh             # the one-command blinky (README § Reproduce): map verification/blinky/blinky.v, assemble its stream, simulate it; logs in flow/build/blinky-run/
verification/fabric-2x2.sh         # G2 (issue #80): generate the 2×2 fabric, map cross_tile.v, `bit_gen` assemble, check the LOGIC4→LOGIC4 crossing; logs in flow/build/
verification/fabric-2x2-bitstream.sh  # G3 (issue #65): the bitstream-level 2×2 test — multi-tile assembly (== `bit_gen`), fabric replay, one-bit perturbation detected; logs in flow/build/fabric-bitstream-2x2/
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
| `verification/fabric-2x2-bitstream.sh` (G3) | All three mapped streams (`cross_tile`, `top_io`, `top_reg`) match FABulous `bit_gen`. The cross-tile stream passes 96 simulation checks through the configuration port. Flipping one `INIT` bit produces the expected 32 failures. Five hashes tie the generated fabric, cross-tile route and stream to G2. | routing quality, timing, area; the FF path and the wider routing space stay covered by the single-tile mutate sweep |

`verification/test-fixtures-regenerate-fail.sh` is the committed regression
test for the fixture-stage FAIL path (issue #153): driving
`fixtures-regenerate.sh` with stubbed tools and the real `cmp`, a byte
mismatch on either design must exit nonzero without that design's
`byte-identical` line, and the matching case must still print it for both.

**Claim boundary.** Single-LOGIC4 harness; the switch matrix is the sibling's
same-index stand-in, not a verified Wilton-class matrix; no inter-tile routing;
no timing; no area. Sibling gaps G5 and G6 are inherited open. Nothing here
says the fabric is verified. The 2×2 demonstration fabric's bitstream-level
test is `verification/fabric-2x2-bitstream.sh` (G3,
`measurements/g3-fabric-2x2-bitstream/`); its layout is not assembled.

Benches `tb_lut_basis`, `tb_route_diag`, `tb_ctrl_route` and `tb_output_route`
run on streams from the vendored generators in `common/flow/`, and
`tb_configmem_equiv` on vectors from `common/flow/configmem_frames.py`
(ADR-0004, which supersedes the ADR-0002 deferral). The four stream benches use
the repository composition (flat cfg port); the sibling's `-DGEN_TILE`
configuration is not exercised. They are in the item-9 evidence inventory.

Sibling `*results*.txt` files are not evidence here; only runs made in this
repo count. Records are in `measurements/`.
