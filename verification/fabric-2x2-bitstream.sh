#!/usr/bin/env bash
# verification/fabric-2x2-bitstream.sh -- the bitstream-level test of the 2x2
# demonstration fabric (issue #65; the G2 record, issue #80, generated and
# mapped it but deliberately made no functional claim).
#
# What this proves, end to end and on the pinned tools only:
#   * the 2x2 fabric generated from rtl/fabric-2x2/fabric.csv is byte-the-same
#     one G2 attested: the three generated inputs (.FABulous/bitStreamSpec.bin,
#     .FABulous/pips.txt, Tile/LOGIC4/LOGIC4_ConfigMem.v) and the routed
#     cross_tile.fasm are checked against the sha256 lines committed in
#     measurements/g2-fabric-2x2-generation/generated-files.sha256;
#   * the vendored multi-tile assembler (verification/common/flow/
#     fasm_to_bitstream.py, re-stamped from sky130-fpga ad55b3b4 for this
#     issue) assembles cross_tile, top_io and top_reg into 984-byte streams.
#     Each matches FABulous bit_gen. For the I/O designs, bit_gen consumes
#     the FASM after the assembler accounts for the zero-bit harness pad pips;
#   * the stream, loaded through the fabric's parallel configuration port
#     (the FABulous ConfigFSM template RTL from the pinned venv), configures
#     all four LOGIC4 tiles so the six-LUT cross-tile chain behaves as its
#     independent parity oracle expects -- the bench
#     verification/common/sim/tb_fabric_bitstream.v checks the ConfigMem
#     readback against the assembler's decode, then 6 outputs x 16 stimulus
#     vectors;
#   * the negative control: flipping the one payload bit of u2's INIT[0]
#     (u2 is the BEL driving the X2Y1 -> X1Y1 crossing) is detected -- the
#     same bench reports exactly 32 of 96 checks failing, and nothing else
#     changes.
#
# What this does NOT claim: the switch matrix is still the same-index
# stand-in, there is no timing and no layout/DRC/LVS, and the inherited gaps
# G5/G6 remain open. See measurements/g3-fabric-2x2-bitstream/README.md.
#
# Usage:
#   verification/run.sh --setup                      # once, fetches the pinned toolchain
#   verification/fabric-2x2-bitstream.sh             # regenerate + verify; drift against the
#                                                    # committed fixtures in verification/bitstream-2x2/
#                                                    # is an error
#   verification/fabric-2x2-bitstream.sh --update-fixtures   # additionally rewrite verification/bitstream-2x2/
#   verification/fabric-2x2-bitstream.sh --record    # additionally write measurements/g3-fabric-2x2-bitstream/
#                                                    # (README.md is hand-written)
#
# Exit status: 0 only if every stage succeeded, every G2 anchor matched, the
# bench printed its exact PASS line, and the perturbed stream produced its
# exact 32-failure FAIL line. Any failure is reported with its log; nothing
# is worked around (issue #65, Out of Scope).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
BUILD="$REPO/flow/build"
OSS="$BUILD/oss-cad-suite"
VENV="$BUILD/fab-venv"
RUN="$BUILD/fabric-bitstream-2x2"
SRC="$REPO/rtl/fabric-2x2"
NSRC="$REPO/rtl/common/fabulous/nextpnr"
TOOL="$REPO/verification/common/flow/fasm_to_bitstream.py"
TB="$REPO/verification/common/sim/tb_fabric_bitstream.v"
FIXDIR="$REPO/verification/bitstream-2x2"
REC="$REPO/measurements/g3-fabric-2x2-bitstream"
G2MAN="$REPO/measurements/g2-fabric-2x2-generation/generated-files.sha256"
ICARUS_PIN="$(python3 -I -c 'import json; print(json.load(open("flow/toolchain.json"))["icarus-verilog"]["version"])')"
SIM_TIMEOUT_SECONDS="${SIM_TIMEOUT_SECONDS:-600}"
SIM_KILL_AFTER_SECONDS="${SIM_KILL_AFTER_SECONDS:-10}"

UPDATE=0; RECORD=0
for a in "$@"; do
    case "$a" in
        --update-fixtures) UPDATE=1 ;;
        --record) RECORD=1 ;;
        *) echo "unknown argument: $a" >&2; exit 2 ;;
    esac
done

for f in "$OSS/bin/nextpnr-generic" "$OSS/bin/yosys" "$VENV/bin/FABulous" "$VENV/bin/bit_gen" "$VENV/bin/python"; do
    [[ -x "$f" ]] || { echo "error: pinned toolchain not present under flow/build/ (run verification/run.sh --setup)" >&2; exit 1; }
done
# The bench compiles with the host iverilog, exactly as verification/run.sh's
# benches do; the same exact-equality pin check applies (the suite bundles
# 14.0 devel, deliberately not used -- see verification/README.md § Cold start).
# The banner is captured here, before any PATH change, and reused verbatim in
# the fixtures PROVENANCE and the record env.txt, so those can never quote a
# different iverilog than the one that actually ran.
if ! command -v iverilog > /dev/null 2>&1 || ! command -v vvp > /dev/null 2>&1; then
    echo "error: iverilog/vvp at $ICARUS_PIN are host prerequisites (see verification/README.md § Cold start)" >&2; exit 1
fi
ICARUS_BANNER="$(iverilog -V 2>&1 | sed -n 1p)"
ICV="$(printf '%s\n' "$ICARUS_BANNER" | sed -E 's/.*version ([0-9.]+).*/\1/')"
[[ "$ICV" == "$ICARUS_PIN" ]] || { echo "error: iverilog $ICV, flow/toolchain.json pins $ICARUS_PIN" >&2; exit 1; }

# anchor <file-in-run> <name-in-g2-manifest> -- the file's sha256 must equal
# the line G2 committed for it, so this run's fabric IS the fabric G2
# attested (and, through G2's own record, the one upstream PR #361 replayed).
# Every verdict is tee'd into $RUN/anchors.txt, which the record commits: the
# anchors are this record's tie to G2, standing in for a second copy of G2's
# generator/nextpnr logs (which stay where G2 normalized and committed them).
anchor() {  # anchor <actual-path> <manifest-name>
    local want got
    want="$(awk -v n="$2" '$2 == n { print $1 }' "$G2MAN")"
    [[ -n "$want" ]] || { echo "error: no $2 line in $G2MAN" >&2; exit 1; }
    got="$(sha256sum "$1" | cut -d' ' -f1)"
    [[ "$got" == "$want" ]] || { echo "error: $2 sha256 $got, G2 recorded $want" >&2; exit 1; }
    echo "   anchor ok: $2 = $got" | tee -a "$RUN/anchors.txt"
}

# The record's committed logs are path-masked with the shared rule
# (verification/manifest-mask.sh, issue #122): every checkout- and
# host-absolute prefix becomes a placeholder, most specific first, so the
# record reproduces from any checkout and names no machine.
source "$REPO/verification/manifest-mask.sh"
manifest_mask_init "$REPO" "$OSS" "$VENV" "$RUN/fab"

echo "== generating the 2x2 fabric with the pinned FABulous (as verification/fabric-2x2.sh does)"
rm -rf "$RUN"; mkdir -p "$RUN/logs"
cp -r "$REPO/rtl/common/fabulous" "$RUN/fab"
cp "$SRC/fabric.csv" "$RUN/fab/fabric.csv"      # the only overlay; no vendored file is edited
GEN_RC=0
# FAB_YOSYS_PATH pins generation to the suite's yosys (issue #94); it fails
# open to a PATH lookup, so the guard below treats a "Resolved yosys path:"
# line as the FAIL it is instead of recording a host-dependent tree.
( cd "$RUN/fab" && FAB_YOSYS_PATH="$OSS/bin/yosys" \
    timeout --kill-after=10 900 "$VENV/bin/FABulous" -p . script FABulous.tcl ) \
    > "$RUN/logs/generator.log" 2>&1 || GEN_RC=$?
if [[ "$GEN_RC" -ne 0 ]]; then
    echo "error: FABulous could not generate the 2x2 description (exit $GEN_RC)." >&2
    echo "       log: flow/build/fabric-bitstream-2x2/logs/generator.log -- commit it and report" >&2
    echo "       the gap, do not substitute another flow (issue #65, Out of Scope)." >&2
    sed -e 's/\x1b\[[0-9;]*m//g' "$RUN/logs/generator.log" | tail -20 >&2
    exit "$GEN_RC"
fi
if grep -q 'Resolved yosys path:' "$RUN/logs/generator.log"; then
    echo "error: FABulous ignored FAB_YOSYS_PATH and resolved yosys from PATH (issue #94); refusing." >&2
    exit 1
fi
anchor "$RUN/fab/.FABulous/bitStreamSpec.bin" ".FABulous/bitStreamSpec.bin"
anchor "$RUN/fab/.FABulous/pips.txt" ".FABulous/pips.txt"
anchor "$RUN/fab/Tile/LOGIC4/LOGIC4_ConfigMem.v" "Tile/LOGIC4/LOGIC4_ConfigMem.v"

echo "== mapping cross_tile.v with the pinned yosys + nextpnr-generic (post-route JSON kept)"
# The suite goes on PATH for this subshell ONLY. Leaving it exported would put
# the suite's iverilog 14.0 (devel) and its vvp in front of the pinned host
# 13.0 for the bench compile and both sim runs further down -- exactly what
# the pin check above exists to prevent. verification/run.sh keeps the same
# discipline (suite PATH covers its mapping subshell only); fabric-2x2.sh
# never invokes iverilog, so its export is harmless there.
( export PATH="$OSS/bin:$PATH"; set -eo pipefail
  yosys -p "synth_fabulous -top top -noiopad -extra-plib $NSRC/prims.v -json $RUN/cross_tile.json" "$SRC/cross_tile.v"
  FAB_ROOT="$RUN/fab" timeout --kill-after=10 600 nextpnr-generic --uarch fabulous \
      --json "$RUN/cross_tile.json" --write "$RUN/cross_tile.post.json" -o fasm="$RUN/cross_tile.fasm"
) > "$RUN/logs/nextpnr.log" 2>&1 \
  || { echo "error: yosys / nextpnr failed; log: flow/build/fabric-bitstream-2x2/logs/nextpnr.log" >&2
       tail -20 "$RUN/logs/nextpnr.log" >&2; exit 1; }
# --write adds the post-route JSON this flow needs for the assembler's
# routed-netlist cross-check; it must not change the route itself, so the
# FASM is anchored to G2's committed sha too.
anchor "$RUN/cross_tile.fasm" "nextpnr-2x2/cross_tile.fasm"

echo "== mapping and assembling top_io and top_reg on the generated 2x2 fabric"
# G1's pad model uses X1Y0 (north) and X1Y2 (south). On this grid the
# south cap is X1Y3. Move its pad constraints together with the model.
mkdir -p "$RUN/pcf" "$RUN/io-work"
for design in top_io top_reg; do
    sed 's|X1Y2/|X1Y3/|g' "$NSRC/$design.pcf" > "$RUN/pcf/$design.pcf"
done
REGEN_GENDIR="$RUN/fab" REGEN_WORK="$RUN/io-work" REGEN_OUT="$RUN" \
    REGEN_NSRC="$NSRC" REGEN_PCF_DIR="$RUN/pcf" REGEN_OSS_BIN="$OSS/bin" REGEN_VENV="$VENV" \
    REGEN_OVERLAY="$SRC/io_overlay.py" REGEN_TOOL="$TOOL" \
    timeout --kill-after=10 600 "$REPO/verification/fixtures-regenerate.sh" \
        --source "verification/fabric-2x2-bitstream.sh + rtl/fabric-2x2/io_overlay.py" \
        > "$RUN/logs/io-mapping.log" 2>&1 \
    || { tail -20 "$RUN/logs/io-mapping.log" >&2; exit 1; }
# The helper exits successfully only after both routed designs assemble and
# compare byte-for-byte. Retain its per-design results in the G3 record.
grep -E '^(assembled |bit_gen genBitstream output)' "$RUN/logs/io-mapping.log" | tee "$RUN/logs/io-assembly.log"

echo "== assembling cross_tile with the same fabric snapshot"
python3 -I "$TOOL" summary "$RUN/cross_tile.post.json" --out "$RUN/cross_tile.mapped.json" > "$RUN/logs/assemble.log" 2>&1 \
  || { echo "error: summary failed; log: flow/build/fabric-bitstream-2x2/logs/assemble.log" >&2; exit 1; }
python3 -I "$TOOL" assemble --fasm "$RUN/cross_tile.fasm" --snapshot "$RUN/fabric_spec.json" \
    --mapped "$RUN/cross_tile.mapped.json" --out "$RUN/cross_tile" >> "$RUN/logs/assemble.log" 2>&1 \
  || { echo "error: assemble failed; log: flow/build/fabric-bitstream-2x2/logs/assemble.log" >&2; exit 1; }

echo "== cross-checking the assembler against FABulous bit_gen (unfiltered FASM)"
timeout --kill-after=10 300 "$VENV/bin/bit_gen" genBitstream "$RUN/cross_tile.fasm" \
    "$RUN/fab/.FABulous/bitStreamSpec.bin" "$RUN/reference.bin" > "$RUN/logs/bit_gen.log" 2>&1 \
  || { echo "error: bit_gen failed; log: flow/build/fabric-bitstream-2x2/logs/bit_gen.log" >&2; exit 1; }
cmp "$RUN/cross_tile.bin" "$RUN/reference.bin" \
  || { echo "error: assembler output differs from FABulous bit_gen genBitstream" >&2; exit 1; }
anchor "$RUN/cross_tile.bin" "nextpnr-2x2/cross_tile.bin"
echo "   assembler == bit_gen: $(sha256sum "$RUN/cross_tile.bin" | cut -d' ' -f1)  ($(stat -c%s "$RUN/cross_tile.bin") bytes)"

echo "== checking the placement the bench pins (its U0..U5 macros are hard-wired)"
python3 - "$RUN/cross_tile.mapped.json" <<'PY'
import json, sys
cells = {c["bel"] for c in json.load(open(sys.argv[1]))["cells"] if c["type"] == "lut4_ff_bel"}
pinned = {"X1Y1/A", "X1Y1/B", "X1Y1/D", "X2Y1/A", "X2Y1/C", "X2Y1/D"}
if cells != pinned:
    sys.exit(f"placement moved: got {sorted(cells)}, bench pins {sorted(pinned)}")
print(f"   placement matches the bench's pinned six BELs: {sorted(cells)}")
PY

echo "== perturbing one payload bit: u2 INIT[0] (u2 drives the X2Y1 -> X1Y1 crossing)"
# The map row for global config bit (2,1) cb%158==3*17 is BEL D's INIT[0] on
# X2Y1 -- u2 in the pinned route. One payload byte of the stream is flipped;
# frame geometry (20-byte sync, then per frame a select word and one word per
# interior row, Y descending, all big endian) comes from pack() in the
# vendored assembler.
python3 - "$RUN" > "$RUN/logs/perturb.log" <<'PY'
from pathlib import Path
import sys
run = Path(sys.argv[1])
rows = (map(int, line.split()) for line in (run / "logic4_configmem.map").read_text().splitlines())
pos, = [pos for x, y, cb, pos in rows if (x, y) == (2, 1) and cb % 158 == 3 * 17]
frame, bit = divmod(pos, 32)
data = bytearray((run / "cross_tile.bin").read_bytes())
offset = 20 + (2 * 20 + frame) * 12 + 8 + (3 - bit // 8)
data[offset] ^= 1 << (bit % 8)
(run / "perturbed.bin").write_bytes(data)
print(f"map pos {pos} -> frame {frame} bit {bit} -> stream byte {offset} bit {bit % 8} flipped")
PY
python3 -I "$TOOL" decode "$RUN/perturbed.bin" --snapshot "$RUN/fabric_spec.json" > "$RUN/perturbed.cfg" \
  || { echo "error: the perturbed stream no longer decodes (wrong offset math?)" >&2; exit 1; }
cmp -s "$RUN/cross_tile.cfg" "$RUN/perturbed.cfg" \
  && { echo "error: perturbed decode is identical to the clean one; nothing was flipped" >&2; exit 1; }
cat "$RUN/logs/perturb.log"

echo "== compiling the bench (generated fabric RTL + FABulous config template from the pinned venv)"
CONFIG_RTL="$("$VENV/bin/python" -c 'from importlib.resources import files; print(files("fabulous") / "fabric_files/FABulous_project_template_verilog/Fabric")')"
printf '`timescale 1ps/1ps\n' > "$RUN/timescale.v"
iverilog -g2012 -s tb_fabric_bitstream -o "$RUN/bench" \
    "$CONFIG_RTL/"{eFPGA_Config,ConfigFSM,bitbang,config_UART,Frame_Data_Reg,Frame_Select}.v \
    "$RUN/fab/Fabric/models_pack.v" "$RUN/fab/Tile/LOGIC4/lut4_ff_bel.v" "$RUN/timescale.v" \
    "$RUN/fab/Tile/LOGIC4/LOGIC4"{,_ConfigMem,_switch_matrix}.v \
    "$RUN/fab/Tile/CAP_N/CAP_N"{,_switch_matrix}.v "$RUN/fab/Tile/CAP_S/CAP_S"{,_switch_matrix}.v \
    "$RUN/fab/Tile/CAP_E/CAP_E"{,_switch_matrix}.v "$RUN/fab/Tile/CAP_W/CAP_W"{,_switch_matrix}.v \
    "$RUN/fab/Fabric/eFPGA"{,_top}.v "$TB" \
    > "$RUN/logs/bench.compile.log" 2>&1 \
  || { echo "error: iverilog compile failed (logs/bench.compile.log)" >&2; tail -20 "$RUN/logs/bench.compile.log" >&2; exit 1; }
sha256sum "$CONFIG_RTL/"{eFPGA_Config,ConfigFSM,bitbang,config_UART,Frame_Data_Reg,Frame_Select}.v \
    | sed "s#$CONFIG_RTL/#config-rtl/#" > "$RUN/config-rtl.sha256"

echo "== replaying both streams through the fabric's configuration port"
( cd "$RUN"
  timeout --kill-after="$SIM_KILL_AFTER_SECONDS" "$SIM_TIMEOUT_SECONDS" vvp bench \
      +bin=cross_tile.bin +cfg=cross_tile.cfg > logs/cross_tile.sim.log 2>&1
  echo "cross_tile vvp rc=$?" > vvp.rc
  timeout --kill-after="$SIM_KILL_AFTER_SECONDS" "$SIM_TIMEOUT_SECONDS" vvp bench \
      +bin=perturbed.bin +cfg=perturbed.cfg > logs/perturbed.sim.log 2>&1
  echo "perturbed vvp rc=$?" >> vvp.rc )
cat "$RUN/vvp.rc"
grep -Fxq 'PASS: tb_fabric_bitstream (96 checks, 0 failures)' "$RUN/logs/cross_tile.sim.log" \
  || { echo "error: clean stream did not produce its exact PASS line:" >&2; cat "$RUN/logs/cross_tile.sim.log" >&2; exit 1; }
grep -Fxq 'FAIL: tb_fabric_bitstream (96 checks, 32 failures)' "$RUN/logs/perturbed.sim.log" \
  || { echo "error: perturbed stream did not produce its exact 32-failure FAIL line:" >&2; cat "$RUN/logs/perturbed.sim.log" >&2; exit 1; }
if ! grep -Fxq 'cross_tile vvp rc=0' "$RUN/vvp.rc" || ! grep -Fxq 'perturbed vvp rc=0' "$RUN/vvp.rc"; then
    echo "error: a vvp run exited nonzero" >&2; cat "$RUN/vvp.rc" >&2; exit 1
fi
echo "   PASS: tb_fabric_bitstream (96 checks, 0 failures)"
echo "   negative control detected: FAIL: tb_fabric_bitstream (96 checks, 32 failures)"

# The assembler's check discovers designs by globbing *.fasm. Stage the
# explicit fixture list so a missing design fails before check can skip it,
# and bit_gen's filtered *.logic.fasm intermediates stay outside that glob.
FILES=(fabric_spec.json logic4_configmem.map)
for design in cross_tile top_io top_reg; do
    FILES+=("$design".{fasm,mapped.json,bin,wiring,cfg})
done
FILES+=(perturbed.bin perturbed.cfg)
STAGED="$RUN/fixtures"
mkdir "$STAGED"
for f in "${FILES[@]}"; do cp "$RUN/$f" "$STAGED/$f"; done
check_dir="$STAGED"
if [[ "$UPDATE" -eq 0 ]]; then
    check_dir="$FIXDIR"
    echo "== checking regenerated artifacts against verification/bitstream-2x2/"
    for f in "${FILES[@]}"; do
        if ! cmp "$STAGED/$f" "$FIXDIR/$f"; then
            echo "error: fixture $f is missing or stale; use --update-fixtures to regenerate" >&2
            exit 1
        fi
    done
    # Verify the complete hash list, even when only provenance is missing or stale.
    (cd "$STAGED" && sha256sum "${FILES[@]}") > "$RUN/fixture-hashes.txt"
    sed '1,/^sha256:$/d' "$FIXDIR/PROVENANCE.txt" | diff -u "$RUN/fixture-hashes.txt" -
fi

python3 -I "$TOOL" check "$check_dir" > "$RUN/logs/fixtures-check.log" 2>&1 \
    || { cat "$RUN/logs/fixtures-check.log" >&2; exit 1; }
if [[ "$UPDATE" -eq 1 ]]; then
    {
        echo "Regenerated by verification/fabric-2x2-bitstream.sh --update-fixtures (issue #65)."
        echo "commit: $(git rev-parse HEAD)"
        echo "iverilog:        $ICARUS_BANNER"
        echo "yosys:           $("$OSS/bin/yosys" -V)"
        echo "nextpnr-generic: $("$OSS/bin/nextpnr-generic" --version 2>&1 | sed -n 1p)"
        echo "FABulous:        $("$VENV/bin/FABulous" --version 2>&1 | sed -n '$p')"
        echo "Pins: flow/toolchain.json. Fabric: rtl/fabric-2x2/fabric.csv overlaid on the"
        echo "stamped rtl/common/fabulous/ project (G2, issue #80); its sha256 lines in"
        echo "measurements/g2-fabric-2x2-generation/generated-files.sha256 anchor the"
        echo "generated fabric and cross_tile route. Designs: rtl/fabric-2x2/cross_tile.v"
        echo "and rtl/common/fabulous/nextpnr/{top_io,top_reg}.v. The harness I/O pads"
        echo "are on X1Y0 and X1Y3 (rtl/fabric-2x2/io_overlay.py and relocated PCFs)."
        echo "Assembler: verification/common/flow/fasm_to_bitstream.py (vendored, reuse.lock.json"
        echo "@ ad55b3b4); cross-checked byte-for-byte against FABulous bit_gen genBitstream."
        echo "Bench: verification/common/sim/tb_fabric_bitstream.v over the FABulous config"
        echo "template RTL (config-rtl.sha256) and the generated fabric RTL."
        echo "Command: verification/fabric-2x2-bitstream.sh --update-fixtures"
        echo "sha256:"; (cd "$STAGED" && sha256sum "${FILES[@]}")
    } > "$STAGED/PROVENANCE.txt"
    mkdir -p "$FIXDIR"
    cp "$STAGED/"* "$FIXDIR/"
    echo "== fixtures written to verification/bitstream-2x2/"
fi
if [[ "$RECORD" -eq 1 ]]; then
    # Rebuild the record directory except README.md (hand-written): a
    # re-record must not leave files from an older record shape behind.
    mkdir -p "$REC"
    find "$REC" -mindepth 1 -maxdepth 1 ! -name README.md -exec rm -rf {} +
    mkdir -p "$REC/logs"
    {
        echo "run: $(date -u +%Y-%m-%dT%H:%M:%SZ) at $(git rev-parse HEAD)"
        echo "iverilog: $ICARUS_BANNER"
        echo "yosys: $("$OSS/bin/yosys" -V)"
        echo "nextpnr-generic: $("$OSS/bin/nextpnr-generic" --version 2>&1 | sed -n 1p)"
        echo "FABulous: $("$VENV/bin/FABulous" --version 2>&1 | sed -n '$p')"
        echo "assembler: verification/common/flow/fasm_to_bitstream.py @ reuse.lock.json ad55b3b443fe045beb2af75161a9872bf8d079c2"
    } > "$REC/env.txt"
    # Only this flow's own logs are committed. Generation and cross_tile mapping evidence
    # is G2's (measurements/g2-fabric-2x2-generation/); this record ties itself
    # to it by the anchors, not by a second, differently-normalized copy of the
    # same generator/nextpnr logs. bit_gen's per-line wall-clock stamp is
    # rewritten to <timestamp> (G2 Finding 2: not reproducible); everything is
    # ANSI-stripped and path-masked.
    for f in assemble.log io-assembly.log bit_gen.log perturb.log bench.compile.log cross_tile.sim.log perturbed.sim.log; do
        sed -e 's/\x1b\[[0-9;]*m//g' "${PATHMASK[@]}" \
            -e 's/^[0-9]\{4\}-[0-9][0-9]-[0-9][0-9] [0-9:.]\+ +[0-9:]\+ | /<timestamp> | /' \
            "$RUN/logs/$f" > "$REC/logs/$f"
    done
    cp "$RUN/anchors.txt" "$REC/anchors.txt"
    {
        ( cd "$RUN" && sha256sum "${FILES[@]}" reference.bin \
            top_io.logic.fasm top_io.fabulous.bin top_reg.logic.fasm top_reg.fabulous.bin )
        cat "$RUN/config-rtl.sha256"
    } > "$REC/outputs.sha256"
    echo "== record written to measurements/g3-fabric-2x2-bitstream/ (README.md is hand-written)"
fi

echo "== PASS: all three 2x2 streams match bit_gen; cross_tile replay passed and its perturbation was detected"
