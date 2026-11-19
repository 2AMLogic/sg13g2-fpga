#!/usr/bin/env bash
# verification/blinky.sh -- the README's one-command blinky (issue #138): take
# verification/blinky/blinky.v (a one-bit clock divider) from RTL to a mapped,
# assembled FABulous frame stream and simulate it on the single-LOGIC4
# harness, printing the sampled output-pad sequence and a verdict.
#
# What it runs, in order, all under the ignored flow/build/ tree:
#   1. the pinned toolchain, if missing -- delegated to run.sh --setup
#      (OSS CAD Suite + FABulous venv; iverilog/vvp stay host prerequisites);
#      the FABulous / nextpnr-generic pins are then enforced against the
#      installed versions even when --setup skips a reinstall (its installs
#      are existence-guarded, so a warm flow/build/ across a pin bump would
#      otherwise run the stale tool and only report the mismatch)
#   2. fabric generation with the pinned FABulous (FAB_YOSYS_PATH, the
#      run.sh mechanism: a FABulous that ignores the override is a failure)
#   3. yosys synth_fabulous + nextpnr-generic mapping of blinky.v with its
#      pcf (clk is stripped: it is the BEL's implicit UserCLK)
#   4. frame-stream assembly through the vendored fasm_to_bitstream.py,
#      cross-checked byte-for-byte against FABulous bit_gen
#   5. tb_blinky.v: load the stream through the frame-interface model,
#      assert reset, then sample the routed q pad -- expected 0, 1, 0, 1, 0.
#      A stuck, unknown or mistimed sample, a corrupt stream, or any failed
#      stage exits nonzero.
#
# Usage: verification/blinky.sh
# Everything it produces lands under the ignored flow/build/ tree
# (flow/build/blinky-run/, plus flow/build/blinky-run.env with the run line,
# elapsed seconds and tool versions); the directory is rebuilt fresh per run,
# the per-stage logs are overwritten.
#
# Exit status: 0 only if every stage succeeded AND the simulation printed
# its PASS line. The elapsed wall-clock seconds and the tool versions are
# printed at the end, so the README number is one command away.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
BUILD="$REPO/flow/build"
OSS="$BUILD/oss-cad-suite"
VENV="$BUILD/fab-venv"
W="$BUILD/blinky-run"
NSRC="$REPO/rtl/common/fabulous/nextpnr"
OVERLAY="$REPO/verification/common/flow/nextpnr_io_overlay.py"
TOOL="$REPO/verification/common/flow/fasm_to_bitstream.py"
RTL="$REPO/rtl/common/rtl"

# The toolchain pins are read from flow/toolchain.json -- that manifest is the
# only copy (issue #88). Same helper as verification/run.sh.
pin() { python3 -I -c 'import json,sys
d = json.load(open(sys.argv[1]))
for k in sys.argv[2:]:
    if not isinstance(d, dict) or k not in d:
        sys.exit("flow/toolchain.json: no pin " + ".".join(sys.argv[2:]))
    d = d[k]
print(d)' "$REPO/flow/toolchain.json" "$@"; }
ICARUS_PIN="$(pin icarus-verilog version)"
FAB_PIN="$(pin fabulous version)"
NEXTPNR_PIN="$(pin nextpnr-generic version)"

# Host prerequisites, named exactly as run.sh names them before any version
# comparison (a missing binary must not produce a nonsense version report).
if ! command -v iverilog > /dev/null 2>&1 || ! command -v vvp > /dev/null 2>&1; then
    echo "error: iverilog/vvp at $ICARUS_PIN are host prerequisites: --setup fetches the OSS CAD Suite and the FABulous venv but not Icarus (the suite bundles 14.0 (devel), not the pin); see verification/README.md § Cold start" >&2
    exit 1
fi
ICV="$(iverilog -V 2>&1 | sed -n 1p | sed -E 's/.*version ([0-9.]+).*/\1/')"
if [[ "$ICV" != "$ICARUS_PIN" ]]; then
    echo "error: iverilog $ICV, flow/toolchain.json pins $ICARUS_PIN" >&2; exit 1; fi

SECONDS=0
FETCHED=0
[[ -x "$OSS/bin/nextpnr-generic" && -x "$VENV/bin/FABulous" ]] || FETCHED=1
mkdir -p "$W/logs"

echo "== 1/5 toolchain (delegates to verification/run.sh --setup)"
if ! "$REPO/verification/run.sh" --setup > "$W/logs/setup.log" 2>&1; then
    echo "error: run.sh --setup failed (logs: flow/build/blinky-run/logs/setup.log)" >&2
    tail -5 "$W/logs/setup.log" >&2 || true
    exit 1
fi

# Enforce the FABulous / nextpnr-generic pins on the installed tools -- the
# same two comparisons run.sh makes before its benches (run.sh:171-172, which
# sit behind run.sh's --setup early exit and so never run on this path).
# Captured once here and reused verbatim in the blinky-run.env report below,
# so the recorded banner is exactly the one that was checked.
PNRV="$("$OSS/bin/nextpnr-generic" --version 2>&1 | sed -n 1p)"
FABV="$("$VENV/bin/FABulous" --version 2>&1 | sed -n "\$p")"
[[ "$PNRV" == *"$NEXTPNR_PIN"* ]] \
    || { echo "error: nextpnr-generic $PNRV is not the pinned $NEXTPNR_PIN (flow/build/oss-cad-suite holds a stale install: remove it and rerun to refetch)" >&2; exit 1; }
grep -q "FABulous CLI $FAB_PIN" <<<"$FABV" \
    || { echo "error: FABulous $FABV is not the pinned $FAB_PIN (flow/build/fab-venv holds a stale install: remove it and rerun to refetch)" >&2; exit 1; }

echo "== 2/5 generating the fabric with the pinned FABulous"
GENDIR="$W/fab"; rm -rf "$GENDIR"; cp -r "$REPO/rtl/common/fabulous" "$GENDIR"
GEN_RC=0
( cd "$GENDIR" && FAB_YOSYS_PATH="$OSS/bin/yosys" \
    timeout --kill-after=10 600 "$VENV/bin/FABulous" -p . script FABulous.tcl ) \
    > "$W/logs/fabulous-generate.log" 2>&1 || GEN_RC=$?
if [[ "$GEN_RC" -ne 0 ]]; then
    echo "error: FABulous exited $GEN_RC (logs: flow/build/blinky-run/logs/fabulous-generate.log)" >&2; exit 1; fi
if grep -q 'Resolved yosys path:' "$W/logs/fabulous-generate.log"; then
    echo "error: FABulous ignored FAB_YOSYS_PATH and resolved yosys from PATH ($(sed -n 's/.*Resolved yosys path: //p' "$W/logs/fabulous-generate.log" | head -1)); see logs/fabulous-generate.log" >&2
    exit 1
fi

echo "== 3/5 mapping blinky.v (yosys synth_fabulous + nextpnr-generic)"
PNR="$W/nextpnr"; rm -rf "$PNR"; mkdir -p "$PNR"
MAP_LOG="$W/logs/map.log"; : > "$MAP_LOG"
(
    set -euo pipefail
    export PATH="$OSS/bin:$PATH"
    python3 -I "$OVERLAY" "$GENDIR/.FABulous" "$PNR/io-model/.FABulous"
    yosys -q -p "synth_fabulous -top top -ff \$_SDFFE_PP0P_ x -extra-plib $NSRC/prims.v -extra-plib $NSRC/io_prims.v -extra-map $NSRC/io_map.v -extra-map $NSRC/ff_map.v -cells-map $NSRC/cells_map.v -json $PNR/blinky.raw.json" "$REPO/verification/blinky/blinky.v"
    # clk is the BEL's implicit UserCLK (no fabric pin): drop the unconnected
    # top port (the same guard as run.sh: only an unconnected clk may be dropped)
    python3 -I - "$PNR/blinky.raw.json" "$PNR/blinky.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); m = d["modules"]["top"]
bits = set(m["ports"]["clk"]["bits"])
assert not any(bits & set(b) for c in m["cells"].values() for b in c["connections"].values()), "clk is connected to a cell"
del m["ports"]["clk"]
json.dump(d, open(sys.argv[2], "w"))
PY
    FAB_ROOT="$PNR/io-model" nextpnr-generic --uarch fabulous --json "$PNR/blinky.json" \
        -o pcf="$REPO/verification/blinky/blinky.pcf" -o fasm="$PNR/blinky.fasm" \
        --write "$PNR/blinky.post.json"
) >> "$MAP_LOG" 2>&1 || { echo "error: mapping failed (logs: flow/build/blinky-run/logs/map.log, tail: $(tail -1 "$MAP_LOG"))" >&2; exit 1; }

echo "== 4/5 assembling the frame stream (fasm_to_bitstream.py, bit_gen cross-check)"
PY="$VENV/bin/python"
"$PY" -I "$TOOL" snapshot --spec "$GENDIR/.FABulous/bitStreamSpec.bin" \
    --configmem "$GENDIR/Tile/LOGIC4/LOGIC4_ConfigMem.v" --pips "$PNR/io-model/.FABulous/pips.txt" \
    --out "$W" --fabulous-version "$("$PY" -c 'import importlib.metadata as m; print(m.version("fabulous-fpga"))')" \
    > "$W/logs/assemble.log" 2>&1
python3 -I "$TOOL" summary "$PNR/blinky.post.json" --out "$W/blinky.mapped.json" >> "$W/logs/assemble.log" 2>&1
python3 -I "$TOOL" assemble --fasm "$PNR/blinky.fasm" --snapshot "$W/fabric_spec.json" \
    --mapped "$W/blinky.mapped.json" --out "$W/blinky" --filtered-fasm "$W/blinky.logic.fasm" \
    >> "$W/logs/assemble.log" 2>&1
"$VENV/bin/bit_gen" genBitstream "$W/blinky.logic.fasm" "$GENDIR/.FABulous/bitStreamSpec.bin" \
    "$W/blinky.fabulous.bin" > "$W/logs/bit_gen.log" 2>&1
cmp "$W/blinky.bin" "$W/blinky.fabulous.bin" >> "$W/logs/assemble.log" 2>&1 \
    || { echo "error: assembled blinky.bin differs from FABulous bit_gen output (logs: flow/build/blinky-run/logs/assemble.log)" >&2; exit 1; }
echo "   assembled stream is byte-identical to FABulous bit_gen genBitstream"

echo "== 5/5 simulating on the fabric (tb_blinky.v)"
iverilog -g2012 -Wall -o "$W/logs/tb_blinky.vvp" "$RTL/lut4_slice.v" \
    "$RTL/logic_tile_switch_matrix.v" "$RTL/logic_tile_routed.v" \
    "$REPO/verification/blinky/tb_blinky.v" > "$W/logs/tb_blinky.compile.log" 2>&1 \
    || { echo "error: iverilog compile failed (logs: flow/build/blinky-run/logs/tb_blinky.compile.log)" >&2; exit 1; }
SIM_RC=0
timeout --kill-after=10 300 vvp "$W/logs/tb_blinky.vvp" \
    +bin="$W/blinky.bin" +map="$W/logic4_configmem.map" +wiring="$W/blinky.wiring" \
    > "$W/logs/tb_blinky.log" 2>&1 || SIM_RC=$?
cat "$W/logs/tb_blinky.log"
if [[ "$SIM_RC" -eq 124 || "$SIM_RC" -eq 137 ]]; then
    echo "error: simulation timed out (infrastructure), rc=$SIM_RC" >&2; exit 1; fi
if [[ "$SIM_RC" -ne 0 ]] || grep -q '^FAIL' "$W/logs/tb_blinky.log" \
    || ! grep -q '^PASS: tb_blinky' "$W/logs/tb_blinky.log"; then
    echo "error: simulation did not pass (logs: flow/build/blinky-run/logs/tb_blinky.log)" >&2; exit 1; fi

echo
echo "blinky: PASS in ${SECONDS}s"
{
    echo "run: $(date -u +%Y-%m-%dT%H:%M:%SZ) at $(git rev-parse HEAD)"
    echo "elapsed: ${SECONDS}s (whole command, including $([[ "$FETCHED" -eq 1 ]] && echo 'the one-time toolchain fetch and ' || echo '')fabric generation, mapping, assembly and simulation)"
    echo "iverilog: $(iverilog -V 2>&1 | sed -n 1p)"
    echo "yosys: $("$OSS/bin/yosys" -V)"
    echo "nextpnr-generic: $PNRV"
    echo "FABulous: $FABV"
    echo "Pins: flow/toolchain.json (iverilog $ICARUS_PIN, FABulous $FAB_PIN, nextpnr-generic $NEXTPNR_PIN)"
} > "$BUILD/blinky-run.env"
grep -E '^(run|elapsed|iverilog|yosys|nextpnr-generic|FABulous|Pins):' "$BUILD/blinky-run.env"
