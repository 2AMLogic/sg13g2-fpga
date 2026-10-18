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

## Commands

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
- `nextpnr.log`: yosys/nextpnr output, FASM and the two probes. Checksum and
  wall-clock lines were removed.
- `generated-files.sha256`: sha256 of every generated file (37 files), the
  nextpnr model among them. Includes `.FABulous/{bel,bel.v2,bel.v3,pips}.txt`,
  `template.pcf`, `placement_estimate.txt` and `bitStreamSpec.{csv,bin}`.

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
