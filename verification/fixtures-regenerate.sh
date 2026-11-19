#!/usr/bin/env bash
# verification/fixtures-regenerate.sh -- regenerate the bitstream fixtures
# (issue #140): map top_io/top_reg with the pinned yosys + nextpnr-generic
# onto the FABulous-generated fabric, assemble both designs with the vendored
# assembler (fasm_to_bitstream.py), and require the assembler's bytes to
# equal FABulous bit_gen's output.
#
# Executed directly by verification/run.sh -- never sourced and never a
# subshell of the runner. The script carries its own strict mode, so a
# failing step -- in particular a failed `cmp` byte comparison -- aborts it
# with a nonzero exit status the runner branches on. (A subshell on the left
# of an `&&` has `set -e` suppressed inside, so the inline block this
# replaces recorded fixtures_regenerate PASS on a byte mismatch: after the
# failed `cmp` the unconditional success echo returned zero and the block's
# exit status stayed 0.)
#
# Locations come from the environment, set by verification/run.sh; a bare
# invocation fails loudly instead of half-running:
#   REGEN_GENDIR   FABulous-generated fabric dir (run.sh's $GENDIR)
#   REGEN_WORK     scratch dir for mapping intermediates (run.sh's $W)
#   REGEN_OUT      output dir for fixtures + step logs (run.sh's $BR)
#   REGEN_OSS_BIN  pinned OSS CAD Suite bin/ (yosys, nextpnr-generic)
#   REGEN_VENV     FABulous venv (python, bit_gen)
#   REGEN_NSRC     rtl/common/fabulous/nextpnr/ overlay sources
#   REGEN_OVERLAY  verification/common/flow/nextpnr_io_overlay.py
#   REGEN_TOOL     verification/common/flow/fasm_to_bitstream.py
# Log text goes to stdout/stderr; the runner redirects it into fixtures.log.
set -euo pipefail

for v in REGEN_GENDIR REGEN_WORK REGEN_OUT REGEN_OSS_BIN REGEN_VENV \
         REGEN_NSRC REGEN_OVERLAY REGEN_TOOL; do
    [[ -n "${!v:-}" ]] || { echo "fixtures-regenerate: $v is not set (invoke via verification/run.sh)" >&2; exit 2; }
done

W="$REGEN_WORK"; BR="$REGEN_OUT"
export PATH="$REGEN_OSS_BIN:$PATH"
PY="$REGEN_VENV/bin/python"

python3 -I "$REGEN_OVERLAY" "$REGEN_GENDIR/.FABulous" "$W/io-model/.FABulous"
yosys -q -p "synth_fabulous -top top -extra-plib $REGEN_NSRC/prims.v -extra-plib $REGEN_NSRC/io_prims.v -extra-map $REGEN_NSRC/io_map.v -cells-map $REGEN_NSRC/cells_map.v -json $W/top_io.json" "$REGEN_NSRC/top_io.v"
FAB_ROOT="$W/io-model" nextpnr-generic --uarch fabulous --json "$W/top_io.json" -o pcf="$REGEN_NSRC/top_io.pcf" -o fasm="$W/top_io.fasm" --write "$W/top_io.post.json"
yosys -q -p "synth_fabulous -top top -ff \$_SDFFE_PP0P_ x -extra-plib $REGEN_NSRC/prims.v -extra-plib $REGEN_NSRC/io_prims.v -extra-map $REGEN_NSRC/io_map.v -extra-map $REGEN_NSRC/ff_map.v -cells-map $REGEN_NSRC/cells_map.v -json $W/top_reg.raw.json" "$REGEN_NSRC/top_reg.v"
# clk is the BEL's implicit UserCLK (no fabric pin): drop the unconnected top port
python3 -I - "$W/top_reg.raw.json" "$W/top_reg.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); m = d["modules"]["top"]
bits = set(m["ports"]["clk"]["bits"])
assert not any(bits & set(b) for c in m["cells"].values() for b in c["connections"].values()), "clk is connected to a cell"
del m["ports"]["clk"]
json.dump(d, open(sys.argv[2], "w"))
PY
FAB_ROOT="$W/io-model" nextpnr-generic --uarch fabulous --json "$W/top_reg.json" -o pcf="$REGEN_NSRC/top_reg.pcf" -o fasm="$W/top_reg.fasm" --write "$W/top_reg.post.json"
"$PY" -I "$REGEN_TOOL" snapshot --spec "$REGEN_GENDIR/.FABulous/bitStreamSpec.bin" \
    --configmem "$REGEN_GENDIR/Tile/LOGIC4/LOGIC4_ConfigMem.v" --pips "$W/io-model/.FABulous/pips.txt" \
    --out "$BR" --fabulous-version "$("$PY" -c 'import importlib.metadata as m; print(m.version("fabulous-fpga"))')"
for d in top_io top_reg; do
    cp "$W/$d.fasm" "$BR/$d.fasm"
    python3 -I "$REGEN_TOOL" summary "$W/$d.post.json" --out "$BR/$d.mapped.json"
    python3 -I "$REGEN_TOOL" assemble --fasm "$BR/$d.fasm" --snapshot "$BR/fabric_spec.json" \
        --mapped "$BR/$d.mapped.json" --out "$BR/$d" --filtered-fasm "$BR/$d.logic.fasm"
    "$REGEN_VENV/bin/bit_gen" genBitstream "$BR/$d.logic.fasm" "$REGEN_GENDIR/.FABulous/bitStreamSpec.bin" "$BR/$d.fabulous.bin" > "$BR/$d.bit_gen.out" 2>&1
    cmp "$BR/$d.bin" "$BR/$d.fabulous.bin"
    echo "bit_gen genBitstream output is byte-identical to the assembler's $d.bin"
done
