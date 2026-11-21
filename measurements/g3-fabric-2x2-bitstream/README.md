# G3: bitstream-level test of the 2×2 fabric — a cross-tile design replayed and a perturbed stream detected (issue #65)

Question: does a bitstream assembled for the 2×2 demonstration fabric, loaded
through the fabric's own configuration port, actually make the mapped
cross-tile design behave — and is a one-bit corruption of that stream
detected? G2 (issue #80) generated and routed this fabric but made no
functional claim; this record is that missing half, and with it
`spec/target-spec.md` row 4's evidence column ("bitstream-level tests on the
simulated fabric") has its first entry for the fallback 2×2 size.

## Result

**Yes, on every stage, with the assembler byte-identical to FABulous's own
`bit_gen`.**

- **The fabric is G2's, proven by sha256, not re-asserted.** The three
  assembler snapshot inputs (`.FABulous/bitStreamSpec.bin`,
  `.FABulous/pips.txt`, `Tile/LOGIC4/LOGIC4_ConfigMem.v`) and the routed
  `cross_tile.fasm` all hash to the lines G2 committed in
  `measurements/g2-fabric-2x2-generation/generated-files.sha256`
  (`anchors.txt`). The driver fails if any anchor moves.
- **Assembly.** The vendored multi-tile assembler
  (`verification/common/flow/fasm_to_bitstream.py`, re-stamped from
  `2AMLogic/sky130-fpga` at `ad55b3b443fe` — upstream PR #361, the dependency
  this issue was parked on) accepts nextpnr's **unfiltered** FASM for the
  2×2 fabric: 29 FASM lines expanding to 113 logic-tile and 6 cap/wire spec
  features, 64 cfg bits set across the four tiles, a 984-byte stream. That
  stream is **byte-identical to `bit_gen genBitstream`** run on the same FASM
  (`cmp` clean, both `e4a0ff12…fbf2` — also the sha G2 recorded and the one
  upstream's fixture carries).
- **Replay.** The stream is loaded by the bench
  (`verification/common/sim/tb_fabric_bitstream.v`, vendored from the same
  commit) through `eFPGA_top`'s parallel configuration port, driven by the
  FABulous ConfigFSM template RTL from the pinned venv (`config-rtl.sha256`
  in `outputs.sha256` names the six template files). Verdict, verbatim:
  `PASS: tb_fabric_bitstream (96 checks, 0 failures)` — 6 stage outputs × 16
  stimulus vectors of the parity oracle. Before any stimulus, the bench also
  read back all 4×158 ConfigMem bits and found them equal to the assembler's
  independent decode (`cross_tile.cfg`); a mismatch is `$fatal`.
- **Negative control.** Flipping the single payload bit of `u2`'s `INIT[0]`
  (`u2` = `X2Y1` BEL D, the driver of the `X2Y1 → X1Y1` crossing net `n3`;
  map position 117 → stream byte 545 bit 5) is **detected**: the same bench
  reports exactly `FAIL: tb_fabric_bitstream (96 checks, 32 failures)` — the
  four downstream stages (`u2..u5`) mismatch on the 8 of 16 vectors where
  parity flips, and nothing else changes. The perturbed stream still decodes
  and still passes the loader's frame checks, so the detection is functional,
  not a load failure.
- **Reproducible.** A second clean run regenerates every artifact
  byte-identically: the driver's own fixture-drift check
  (`fasm_to_bitstream.py check` + `cmp` against `verification/bitstream-2x2/`)
  passed with zero drift. The committed logs are ANSI-stripped, wall-clock
  rewritten (`bit_gen`'s per-line timestamp → `<timestamp>`, as G2 Finding 2)
  and path-masked (`<project>`, `<repo>`, `<fab-venv>`, `<oss-cad-suite>`,
  `<home>` — `verification/manifest-mask.sh`), so the record names no machine.

The placement is asserted, not assumed: the bench's `U0..U5` macros pin the
six BELs (`X1Y1/A,B,D`, `X2Y1/A,C,D`), and the driver fails outright unless
`cross_tile.mapped.json` reports exactly that set — the pinned nextpnr
reproduces it, as G2 recorded.

## Claim boundary — what this record does NOT establish

- **Stand-in switch matrix.** Same-index stand-in, not a designed routing
  architecture; a routed design proving the *mechanism* says nothing about
  routing quality or routability at occupancy.
- **No timing.** `GenerateDelayInSwitchMatrix,80` is FABulous's placeholder;
  no Fmax, no SG13G2 characterized number, nothing inherited from sky130 or
  from FABulous's placeholder BEL timing.
- **No layout, no DRC, no LVS, no area.** Simulation only; nothing was placed
  on silicon. Assembling and physically checking a 2×2 layout is spec row 6,
  out of scope here.
- **Bench coverage is exact, not exhaustive.** 96 checks cover the six
  chain stages under all 16 LUT-input vectors; the bench drives only LUT
  inputs `cross_tile.v` left unconnected, so the FF path and the wider
  routing space stay covered by the single-tile harness's mutate sweep
  (`tb_logic_tile_bitstream`, 26/26 and 27/27 perturbations there), not here.
- **G5/G6 inherited open** (the sibling's recorded gaps: no verified switch
  matrix architecture; no characterized fabric timing).
- **One fabric, one design.** 2×2 `LOGIC4` core, one six-LUT chain. Growing
  the fabric or adding tile types is spec-gated, not taken here.

## Pins (also in `flow/toolchain.json`, `env.txt`)

| Tool | Version | Role here |
|---|---|---|
| FABulous | 2.2.0 (`FABulous CLI 2.2.0`) | fabric generation; `bit_gen genBitstream` cross-check; ConfigFSM template RTL (from the venv package) |
| yosys | 0.69+260 (`dcd59343b`) | `synth_fabulous` mapping (suite binary; also generation via `FAB_YOSYS_PATH`) |
| nextpnr-generic | nextpnr-0.11.1-54-g861c57be | place/route, FASM + post-route JSON |
| Icarus Verilog | 13.0 (stable) (host) | bench compile + both `vvp` replays — the suite's 14.0 (devel) is deliberately not used; the driver pins the PATH scope so the bench never sees it |
| assembler | `verification/common/flow/fasm_to_bitstream.py` @ `reuse.lock.json` `ad55b3b443fe` | snapshot, summary, assemble, decode |

## Commands

```sh
verification/run.sh --setup                     # once
verification/fabric-2x2-bitstream.sh            # everything below; drift vs committed fixtures is an error
verification/fabric-2x2-bitstream.sh --record   # additionally rewrite this record (README.md is hand-written)
```

Stage by stage: copy `rtl/common/fabulous/` to scratch, overlay
`rtl/fabric-2x2/fabric.csv`, generate with `FAB_YOSYS_PATH` pinned (issue #94
mechanism); map `rtl/fabric-2x2/cross_tile.v` (`--write` post-route JSON kept
— the only nextpnr difference from G2's invocation, anchored not to change
the route); `snapshot`/`summary`/`assemble` with the vendored tool;
`bit_gen genBitstream` + `cmp`; perturb; `decode`; compile the bench against
the generated fabric RTL plus the venv's config template RTL; replay both
streams.

## Files

- `anchors.txt` — the five G2-manifest sha256 equalities this run is tied by.
- `env.txt` — tool banners and the assembler's lock commit.
- `logs/assemble.log` — snapshot/summary/assemble output (the one-line
  accounting of the 29 FASM lines).
- `logs/bit_gen.log` — the cross-check tool's own log, timestamps masked.
- `logs/perturb.log` — the map-position → stream-byte arithmetic for the flip.
- `logs/bench.compile.log`, `logs/cross_tile.sim.log`, `logs/perturbed.sim.log`
  — the bench compile (clean at 13.0) and the two replay verdicts.
- `outputs.sha256` — hashes of every run artifact (snapshot, map, FASM,
  mapped summary, stream, wiring, cfg, perturbed pair, `bit_gen` reference)
  plus the six config-template RTL files under `config-rtl/`.

Committed fixtures live in `verification/bitstream-2x2/` (with
`PROVENANCE.txt`); `fasm_to_bitstream.py check verification/bitstream-2x2/`
re-derives `.bin`/`.wiring`/`.cfg` from the committed FASM + snapshot
byte-for-byte, so the fixture set is a standing regression independent of the
fabric-generation toolchain.

## The vendored-tool re-stamp (and the G1 regression)

Upstream PR #361 is what unblocked this issue: it made
`fasm_to_bitstream.py` multi-tile (per-tile 158-bit vectors, coordinate-
qualified ConfigMem map, inter-tile `LINK` wiring records) and added
`tb_fabric_bitstream.v`. Bringing it in moved `reuse.lock.json` from
`42a8db0` to `ad55b3b443fe`: 11 vendored files refreshed (the assembler, the
four stream generators and their benches — pure upstream refactors into
shared `flow/_stream_gen.py`/`flow/_modload.py` and
`sim/bitstream_load.vh`/`bitstream_parse.vh`, now vendored too — plus
`tb_logic_tile_bitstream.v`'s redundancy-proof work and a
`tb_configmem_equiv.v` register-width fix) and 5 entries added; 59
destinations, all hashing to the lock.

The single-tile harness is unchanged by the re-stamp:
`verification/run.sh` reports **24 PASS, 0 FAIL, 0 NOT-RUN**, and its
`results.tsv` is **byte-identical** to a run of the same suite on clean
`main` at `dfd659d` (measured side by side; the single line that differs
from the committed `v2-stream-benches` record, `fabulous_generate`'s detail
text, embeds the checkout-absolute `FAB_YOSYS_PATH` and differs on `main`
already — a recorded-path artifact of `run.sh`'s own message, not a bench
result). `verification/bitstream/` single-tile fixtures still reproduce
byte-for-byte (`fixtures_match_committed`, `assembler_reproduce` both PASS
with the re-stamped assembler). The `manifests/` T1 **grading** is unchanged
(10 of 11 met, item 6 `not_applicable`); the item-9 attestation envelope was
re-attested for the re-stamped bench bytes and the new bench, per
`manifests/README.md` ("Regenerate it whenever an inventoried bench or
script changes").

## Findings

- **No tool defect found.** FABulous, yosys, nextpnr, `bit_gen`, Icarus and
  the vendored assembler all behaved as pinned; nothing needed working
  around, and no klayout-tools friction surfaced (nothing here touches
  `klt`).
- **The bench's ConfigMem readback check is load-bearing.** Before any
  stimulus, `latched !== expected_cfg` is `$fatal` — the four tiles' latched
  vectors must equal the assembler's decode. That is what makes the replay a
  test of the *stream* (frame packing, select words, row order), not only of
  the design: a stream that loaded but latched wrong bits would fail here
  even if the chain happened to work.
- **The negative control's failure count is derived, not tuned.** 32 = 4
  affected stages × 8 affected vectors of the parity function; the driver
  requires the bench's exact line, so a perturbation that broke loading
  (0 checks run) or a wrong bit (different count) both fail the run.
