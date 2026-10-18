# V1: bitstream-level verification of the stamped tile (issue #11)

Append-only record. Produced by `verification/run.sh --out measurements/v1-bitstream-verification`
at the commit in `env.txt` (`dcca7fa`), on a single local process. Per-bench
verdicts: `results.tsv`; logs: `logs/`; summary: `summary.txt`.

## Result

19 PASS, 0 FAIL, 5 NOT-RUN. Tool versions as pinned in `flow/toolchain.json`
(Icarus 13.0, FABulous 2.2.0, yosys 0.69+260, nextpnr-generic 0.11.1-54-g861c57be).

- Stamped benches `tb_lut4_slice`, `tb_logic_tile`, `tb_switch_matrix`,
  `tb_logic_tile_routed`, `tb_logic_tile_gapfill` pass against the stamped RTL.
- `fabulous_generate` exits 0; `tb_lut4_ff_bel_equiv`, `tb_switch_matrix_equiv`
  and `tb_boundary_fwd` pass against the generated modules.
- `top_io.v` (combinational) and `top_reg.v` (registered) map with the pinned
  yosys/nextpnr, are assembled by the vendored `fasm_to_bitstream.py` (ADR-0002),
  and each stream is byte-identical to FABulous `bit_gen genBitstream`.
  Regeneration is byte-identical to the committed `verification/bitstream/`.
- `tb_logic_tile_bitstream` passes for `comb` (5409 checks, 26/26 perturbations
  detected) and `reg` (139651 checks, 27/27 detected) with `+mutate`; the
  simulation loader, the Python decoder and the recorded vector agree on the
  tile vector for both; the loader rejects 11/11 malformed streams per fixture
  (`+expect_reject`, variants from `verification/bitstream_corrupt.py`).

## NOT-RUN (listed, not omitted)

`tb_lut_basis`, `tb_route_diag`, `tb_ctrl_route`, `tb_output_route`: need
stimulus generators from the sibling's unstamped `flow/`.
`tb_configmem_equiv`: needs `+vec=` vectors from the sibling's unstamped
`flow/configmem_frames.py`. Reasons are in `results.tsv`. No decision yet to
vendor these; see ADR-0002.

## How far the claim reaches

Single-LOGIC4 harness (one logic tile on a 3x3 grid with CAP_* boundary cells
and a scratch pad overlay), driven through a sim-only model of the frame
interface. The switch matrix is the sibling's same-index stand-in, **not** a
verified Wilton-class matrix. No inter-tile routing, no timing (FABulous's
BEL delays are placeholders), no area. Two mapped designs only.

Inherited open from `sky130-fpga` at `42a8db0`: **G5** (no bitstream-level
verification of the ratified fabric; only this experimental single-tile
harness) and **G6** (bitstream format not documented/ratified); sibling
ADR-0004/0005/0006 are *Proposed*. Both remain open here. Nothing in this
record says the fabric is verified, and the 2x2 to 4x4 demonstration fabric
is untested. No sibling result file is cited.

## Defects found

None on the testbenches or the description, FABulous, nextpnr or `klt`; no
issue filed on `sky130-fpga` or `klayout-tools`. Not exercised: the sibling's
`-DGEN_TILE` configuration of `tb_logic_tile_bitstream`.
