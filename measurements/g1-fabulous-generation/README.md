# G1: pinned FABulous generation of the stamped description (issue #8)

Question deferred by `spec/decisions/0001-ratify-target-spec.md`: does the
pinned FABulous generate a fabric out of the box from the stamped
`rtl/common/fabulous/` description, with no SG13G2-specific change?

## Result

**No PDK-specific change needed.** The stamped description was used unedited:
no vendored file was modified, so no decision record and no `reuse.lock.json`
change is required. The generator exits 0 and the nextpnr stage reaches the
same placed-and-routed FASM as the sibling's.

No timing or area claim is made. `GenerateDelayInSwitchMatrix,80` is
FABulous's placeholder constant, and the nextpnr run reports no Fmax.

## Pins (also in `flow/toolchain.json`)

| Tool | Version | Obtained |
|---|---|---|
| FABulous | 2.2.0 (`FABulous CLI 2.2.0`) | `fabulous-fpga==2.2.0` in a throwaway venv (`.venv-fab`, Python 3.12.3, untracked) |
| yosys (this stage) | 0.69+260 (`dcd59343b`) | YosysHQ OSS CAD Suite 2026-10-08, sha256-verified, unpacked under untracked `flow/build/oss-cad-suite` |
| nextpnr-generic | nextpnr-0.11.1-54-g861c57be | same suite |

Neither `FABulous` nor `nextpnr-generic` is on the host PATH. The host
`yosys` (0.67) does have `synth_fabulous`, but the suite's yosys was used so
the run is like-for-like with the sibling's log; the host yosys was not
tried for this stage. Everything came from a worktree-local directory and
nothing was installed host-wide. If the fleet wants these on the workers, that is a change to the
worker spec.

Since issue #105 the generation stage pins this yosys explicitly:
`verification/fabulous-generation.sh` sets `FAB_YOSYS_PATH` on the
generation subshell — the mechanism `verification/run.sh` and
`verification/fabric-2x2.sh` already use — and aborts if FABulous ever
falls back to a PATH lookup. The original hand run relied on the suite's
`bin/` ordering on PATH instead.

## Commands

**Re-recording (since issue #105):** the generation stage behind
`generator.log` and `generated-files.sha256` is driven by
`verification/fabulous-generation.sh`, which pins the suite's yosys and
emits the path-masked manifest:

```sh
verification/run.sh --setup                    # once
verification/fabulous-generation.sh --record   # regenerate generator.log
                                               # and generated-files.sha256
```

The record's original run was produced by hand-run commands, kept here as
the record of what was measured.

Generation, from a scratch copy so nothing lands in `rtl/common/`:

```
cp -r rtl/common/fabulous flow/build/fabulous-run
cd flow/build/fabulous-run && FABulous -p . script FABulous.tcl     # exit 0
```

nextpnr, with `FAB_ROOT=flow/build/fabulous-run` and the suite's `bin/` on
PATH (`nextpnr.log` has the commands inline):

```
yosys -p 'synth_fabulous -top top -noiopad -extra-plib prims.v -json top.json' top.v
nextpnr-generic --uarch fabulous --json top.json -o fasm=top.fasm       # rc 0
```

plus the two expected-failure probes `top_ports.v` and `top_const.v`.

## Files

- `generator.log`: normalized generator log (ANSI stripped, scratch path
  rewritten to `<project>`, tool-probe lines dropped, sorted unique lines,
  tile-name list sorted, because FABulous 2.2.0 emits tiles in hash order).
  Since issue #105 this normalization is implemented verbatim by
  `verification/fabulous-generation.sh`: the dropped tool-probe lines are
  the `Resolved <tool> path:` probes, the `<tool> not found in PATH`
  warnings and the `PDK_root` environment warning. The yosys pin is
  checked on the raw log before normalization removes exactly those
  lines.
- `nextpnr.log`: yosys/nextpnr output, FASM and the two probes. Checksum and
  wall-clock lines were removed.
- `generated-files.sha256`: sha256 of every generated file (37 files), the
  nextpnr model among them. Includes `.FABulous/{bel,bel.v2,bel.v3,pips}.txt`,
  `template.pcf`, `placement_estimate.txt` and `bitStreamSpec.{csv,bin}`.

  **Masking rule (issue #105).** Two of the 37 entries are hashed from a
  path-masked copy — the file's bytes run through the same checkout-path
  `sed` pipeline the sibling records' logs use (`<project>`,
  `<oss-cad-suite>`, `<fab-venv>`, `<repo>`, `<home>`) — because the raw
  files embed checkout paths:
  - `Tile/LOGIC4/lut4_ff_bel.json` — yosys records an absolute `src` for
    every cell and wire, and its `creator` names the yosys that generated
    it;
  - `eFPGA_geometry.csv` — its `Src,…` / `Csv,…` rows name each
    switch-matrix file absolutely.
  The set is an explicit allowlist in `fabulous-generation.sh`, not a
  blanket mask: the tree also contains the binary
  `.FABulous/bitStreamSpec.bin`, which `sed` must never touch and which
  keeps its raw hash. Consequence: a masked entry cannot be checked with
  `sha256sum -c` against a raw generated tree — re-run
  `verification/fabulous-generation.sh` and diff the manifest instead.

  Demonstrated 2026-11-15: the manifest is byte-identical (empty `diff`)
  across three checkouts at different absolute paths. The 35 unmasked
  hashes are byte-identical to the original record, and the masked
  `lut4_ff_bel.json` hash agrees with the G2 record's (`238d364c…` in
  both) — the same tile description from the same pinned tools. The
  masked `eFPGA_geometry.csv` still differs from G2's, as it must: the
  fabric geometry differs (one `LOGIC4` tile vs a 2×2), which is the part
  of that file's G1/G2 difference that is *not* checkout paths.

## Comparison with the sibling (`sky130-fpga` @ `42a8db0`)

- `generator.log` is **byte-identical** to the sibling's
  `design/fabulous/generator.log` after the same normalization.
- `nextpnr.log`: the `top.fasm` section is identical to the sibling's. The
  differences are the removed checksum and timing lines, and the header
  comment (the sibling's carries its script name).
- Probe `top_const.v` fails as recorded: `Failed to find a route for arc 0 of
  net $PACKER_GND`. Probe `top_ports.v` fails as recorded with `Top-level
  port 'y' connected to illegal port ... (must be PAD)`. The offending port
  is printed as `...reintegrate$241.Y` here and `...reintegrate$241._lut.O`
  in the sibling's log. The yosys and nextpnr versions are the same; I did
  not determine why the printed name differs, and it does not change the
  error class.

## Not run

The sibling's ADR-0005 stages (`top_io.v` on the harness pad model, and the
registered `top_reg.v`) need `flow/nextpnr_io_overlay.py`, which is sibling
flow code and is not vendored here. The stage reached is therefore the plain
`top.v` placement and routing plus the two probes. The `top_io`/`top_reg`
overlay inputs under `rtl/common/fabulous/nextpnr/` are present but unused
by this record. The sibling's BEL and switch-matrix equivalence benches were
also not run (that is #11's territory).

## Defects found

None, on FABulous, nextpnr or `klt`.

Appended 2026-11-15 (issue #105): the record's own manifest was not
reproducible — `Tile/LOGIC4/lut4_ff_bel.json` (line 35) and
`eFPGA_geometry.csv` (line 37) hashed files embedding checkout-absolute
paths, so `generated-files.sha256` reproduced only from the checkout that
made it. The manifest was re-recorded by
`verification/fabulous-generation.sh` with those two entries hashed from
path-masked copies (see `## Files`); the other 35 hashes and the
normalized `generator.log` are byte-identical to the original record.
