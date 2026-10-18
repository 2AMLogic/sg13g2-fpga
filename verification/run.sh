#!/usr/bin/env bash
# verification/run.sh -- run every stamped bench under verification/common/ with
# Icarus Verilog and record a per-bench verdict (issue #11).
#
# What this runs
#   * BEL / slice / tile / switch-matrix benches against the stamped RTL in
#     rtl/common/rtl/ and, for the *_equiv benches, the FABulous-generated
#     modules (generated here under the pinned FABulous, into flow/build/).
#   * tb_boundary_fwd against the generated LOGIC4 tile (-DGEN_TILE).
#   * The bitstream bench tb_logic_tile_bitstream on fixtures regenerated from
#     the stamped rtl/common/fabulous/nextpnr/ overlay (top_io.v, top_reg.v)
#     with the pinned yosys + nextpnr-generic, assembled by the vendored
#     verification/common/flow/fasm_to_bitstream.py and cross-checked against
#     FABulous's own `bit_gen genBitstream`. Negative paths: +mutate and
#     +expect_reject on malformed variants (verification/bitstream_corrupt.py).
#   * A bench that cannot run is listed NOT-RUN with its reason, never omitted.
#
# What this does NOT claim: see verification/README.md. Single LOGIC4 harness,
# same-index stand-in switch matrix, no inter-tile routing, no timing, no area.
#
# Usage:
#   verification/run.sh --setup          fetch the pinned toolchain into flow/build/
#                                        (OSS CAD Suite tarball, FABulous venv); no host install
#   verification/run.sh [--out DIR] [--update-fixtures]
#       --out DIR           write logs + results.tsv + summary.txt to DIR
#                           (default flow/build/verification; refuses a non-empty DIR
#                           other than the default, results are append-only evidence)
#       --update-fixtures   rewrite verification/bitstream/ from the regenerated copy
#                           (default: drift is an error)
#
# Single process throughout: no -j, no background jobs. Every vvp run is
# bounded by SIM_TIMEOUT_SECONDS (default 600, kill after SIM_KILL_AFTER_SECONDS,
# default 10); a timeout is a FAIL (infrastructure) naming the bench.
# Exit status: 0 only if no bench FAILed. NOT-RUN entries do not change it but
# are printed and recorded.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
BUILD="$REPO/flow/build"
OSS="$BUILD/oss-cad-suite"
VENV="$BUILD/fab-venv"
RTL="$REPO/rtl/common/rtl"
VCOMMON="$REPO/verification/common"
FIXDIR="$REPO/verification/bitstream"
TOOL="$VCOMMON/flow/fasm_to_bitstream.py"
OVERLAY="$VCOMMON/flow/nextpnr_io_overlay.py"
NSRC="$REPO/rtl/common/fabulous/nextpnr"
SIM_TIMEOUT_SECONDS="${SIM_TIMEOUT_SECONDS:-600}"
SIM_KILL_AFTER_SECONDS="${SIM_KILL_AFTER_SECONDS:-10}"

pin() { python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d[sys.argv[2]][sys.argv[3]])' "$REPO/flow/toolchain.json" "$1" "$2"; }
ICARUS_PIN="$(pin icarus-verilog version)"
FAB_PIN="$(pin fabulous version)"
OSS_URL="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-10-08/oss-cad-suite-linux-x64-20261008.tgz"
OSS_SHA="8fa59d93d6cadbbee352077c059f2c5b72cda301e4508d9064a23d1ec11579c7"

if [[ "${1:-}" == "--setup" ]]; then
    mkdir -p "$BUILD/dl"
    if [[ ! -x "$OSS/bin/nextpnr-generic" ]]; then
        curl -fsSL -o "$BUILD/dl/oss.tgz" "$OSS_URL"
        echo "$OSS_SHA  $BUILD/dl/oss.tgz" | sha256sum -c --quiet -
        mkdir -p "$OSS"
        tar -xzf "$BUILD/dl/oss.tgz" -C "$OSS" --strip-components=1 \
            oss-cad-suite/bin oss-cad-suite/lib oss-cad-suite/libexec \
            oss-cad-suite/share/yosys oss-cad-suite/share/nextpnr oss-cad-suite/etc
    fi
    if [[ ! -x "$VENV/bin/FABulous" ]]; then
        uv venv --python 3.12 "$VENV"
        uv pip install --python "$VENV/bin/python" "fabulous-fpga==$FAB_PIN"
    fi
    echo "toolchain ready under flow/build/"
    exit 0
fi

OUT="$BUILD/verification"; UPDATE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --out) OUT="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; shift 2 ;;
        --update-fixtures) UPDATE=1; shift ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done
if [[ "$OUT" == "$BUILD/verification" ]]; then rm -rf "$OUT"
elif [[ -e "$OUT" && -n "$(ls -A "$OUT" 2>/dev/null)" ]]; then
    echo "error: $OUT exists and is not empty; results are append-only, pick a new --out" >&2; exit 2
fi
mkdir -p "$OUT/logs"
TSV="$OUT/results.tsv"
printf 'bench\tverdict\tdetail\n' > "$TSV"
overall=0

record() {  # record <bench> <PASS|FAIL|NOT-RUN> <detail>
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$TSV"
    printf '%-9s %s -- %s\n' "$2" "$1" "$3"
    [[ "$2" == FAIL ]] && overall=1
    return 0
}

# bounded vvp: sets RC; log in $OUT/logs/<tag>.log
run_vvp() {  # run_vvp <tag> <vvp args...>
    local tag="$1"; shift
    RC=0
    timeout --kill-after="$SIM_KILL_AFTER_SECONDS" "$SIM_TIMEOUT_SECONDS" vvp "$@" > "$OUT/logs/$tag.log" 2>&1 || RC=$?
}

verdict_of() {  # verdict_of <tag> <pass-regex>; prints PASS/FAIL + detail, uses RC
    local tag="$1" rx="$2" log="$OUT/logs/$1.log"
    if [[ "$RC" -eq 124 || "$RC" -eq 137 ]]; then echo "FAIL|timeout after ${SIM_TIMEOUT_SECONDS}s (infrastructure), rc=$RC"
    elif [[ "$RC" -ne 0 ]]; then echo "FAIL|vvp rc=$RC"
    elif grep -q '^FAIL' "$log"; then echo "FAIL|$(grep -m1 '^FAIL' "$log")"
    elif grep -Eq "$rx" "$log"; then echo "PASS|$(grep -E -m1 "$rx" "$log")"
    else echo "FAIL|no PASS line matching /$rx/"; fi
}

compile() {  # compile <tag> <iverilog args...> ; returns 0/1, log in logs/<tag>.compile.log
    local tag="$1"; shift
    iverilog "$@" > "$OUT/logs/$tag.compile.log" 2>&1
}

run_bench() {  # run_bench <name> <pass-regex> <iverilog args...>
    local name="$1" rx="$2"; shift 2
    if ! compile "$name" -o "$OUT/logs/$name.vvp" "$@"; then
        record "$name" FAIL "iverilog compile failed (logs/$name.compile.log)"; return 0; fi
    run_vvp "$name" "$OUT/logs/$name.vvp"
    local v; v="$(verdict_of "$name" "$rx")"
    record "$name" "${v%%|*}" "${v#*|}"
}

# --------------------------------------------------------------- preflight
ICV="$(iverilog -V 2>&1 | sed -n 1p | sed -E 's/.*version ([0-9.]+).*/\1/')"
if [[ "$ICV" != "$ICARUS_PIN" ]]; then
    echo "error: iverilog $ICV, flow/toolchain.json pins $ICARUS_PIN" >&2; exit 1; fi
{
    echo "run: $(date -u +%Y-%m-%dT%H:%M:%SZ) at $(git rev-parse HEAD)$(git diff --quiet HEAD -- . ':!measurements' 2>/dev/null || echo ' (+uncommitted changes)')"
    echo "iverilog: $(iverilog -V 2>&1 | sed -n 1p)"
} > "$OUT/env.txt"

HAVE_TOOLS=1
for f in "$OSS/bin/nextpnr-generic" "$OSS/bin/yosys" "$VENV/bin/FABulous" "$VENV/bin/bit_gen"; do
    [[ -x "$f" ]] || HAVE_TOOLS=0; done
if [[ "$HAVE_TOOLS" -eq 1 ]]; then
    {
        echo "yosys: $("$OSS/bin/yosys" -V)"
        echo "nextpnr-generic: $("$OSS/bin/nextpnr-generic" --version 2>&1 | sed -n 1p)"
        echo "FABulous: $("$VENV/bin/FABulous" --version 2>&1 | sed -n "\$p")"
    } >> "$OUT/env.txt"
    grep -q "FABulous CLI $FAB_PIN" "$OUT/env.txt" || { echo "error: FABulous version is not the pinned $FAB_PIN" >&2; exit 1; }
fi
NOTOOLS="pinned toolchain not present under flow/build/ (run verification/run.sh --setup)"

# ------------------------------------------------- stamped RTL-only benches
S="$VCOMMON/sim"
run_bench tb_lut4_slice '^PASS: tb_lut4_slice' -g2012 -Wall -I "$S" "$RTL/lut4_slice.v" "$S/tb_lut4_slice.v"
run_bench tb_logic_tile '^PASS: tb_logic_tile ' -g2012 -Wall -I "$S" "$RTL/lut4_slice.v" "$RTL/logic_tile.v" "$S/tb_logic_tile.v"
run_bench tb_switch_matrix '^PASS: tb_switch_matrix' -g2012 -Wall -I "$S" "$RTL/logic_tile_switch_matrix.v" "$S/tb_switch_matrix.v"
run_bench tb_logic_tile_routed '^PASS: tb_logic_tile_routed' -g2012 -Wall -I "$S" "$RTL/lut4_slice.v" "$RTL/logic_tile_switch_matrix.v" "$RTL/logic_tile_routed.v" "$S/tb_logic_tile_routed.v"
run_bench tb_logic_tile_gapfill '^PASS: tb_logic_tile_gapfill' -g2012 -Wall -I "$S" "$RTL/lut4_slice.v" "$RTL/logic_tile.v" "$RTL/logic_tile_switch_matrix.v" "$RTL/logic_tile_routed.v" "$S/tb_logic_tile_gapfill.v"

# Drift guard: the stamped switch-matrix RTL / bench include must equal the
# stamped generator's output (a hand edit would otherwise go unseen).
GEN="$OUT/logs/gen_check"; mkdir -p "$GEN"
if python3 -I "$REPO/rtl/common/gen/gen_switch_matrix.py" \
        "$REPO/rtl/common/fabulous/Tile/LOGIC4/LOGIC4_switch_matrix.list" \
        "$GEN/logic_tile_switch_matrix.v" "$GEN/switch_matrix_tb_gen.vh" > "$OUT/logs/gen_check.log" 2>&1 \
   && cmp -s "$GEN/logic_tile_switch_matrix.v" "$RTL/logic_tile_switch_matrix.v" \
   && cmp -s "$GEN/switch_matrix_tb_gen.vh" "$S/switch_matrix_tb_gen.vh"; then
    record gen_switch_matrix_drift PASS "stamped RTL and bench include equal the stamped generator's output"
else
    record gen_switch_matrix_drift FAIL "generator output differs from stamped files (logs/gen_check.log)"
fi

# ------------------------------------------------- generate the FABulous fabric
GENDIR="$BUILD/fabulous-run"
if [[ "$HAVE_TOOLS" -eq 1 ]]; then
    rm -rf "$GENDIR"; cp -r "$REPO/rtl/common/fabulous" "$GENDIR"
    if ( cd "$GENDIR" && timeout --kill-after=10 600 "$VENV/bin/FABulous" -p . script FABulous.tcl ) > "$OUT/logs/fabulous-generate.log" 2>&1; then
        record fabulous_generate PASS "FABulous $FAB_PIN generated the stamped description (exit 0)"
        GEN_OK=1
    else
        record fabulous_generate FAIL "FABulous exited nonzero (logs/fabulous-generate.log)"; GEN_OK=0
    fi
else
    record fabulous_generate NOT-RUN "$NOTOOLS"; GEN_OK=0
fi

# generated-fabric benches
G="$GENDIR/Tile/LOGIC4"
if [[ "$GEN_OK" -eq 1 ]]; then
    run_bench tb_lut4_ff_bel_equiv '^PASS' -g2005 "$VCOMMON/fabulous/tb_lut4_ff_bel_equiv.v" "$G/lut4_ff_bel.v" "$RTL/lut4_slice.v"
    run_bench tb_switch_matrix_equiv '^PASS: switch_matrix_fabulous_equiv' -g2005 "$VCOMMON/fabulous/tb_switch_matrix_equiv.v" "$G/LOGIC4_switch_matrix.v" "$RTL/logic_tile_switch_matrix.v"
    run_bench tb_boundary_fwd '^PASS: tb_boundary_fwd' -g2012 -DGEN_TILE -Wall -I "$S" \
        "$G/LOGIC4.v" "$G/LOGIC4_ConfigMem.v" "$G/LOGIC4_switch_matrix.v" "$G/lut4_ff_bel.v" "$GENDIR/Fabric/models_pack.v" "$S/tb_boundary_fwd.v"
else
    for b in tb_lut4_ff_bel_equiv tb_switch_matrix_equiv tb_boundary_fwd; do
        record "$b" NOT-RUN "needs the FABulous-generated tile; fabulous_generate did not complete"; done
fi

# ------------------------------------------------- fixtures: map, assemble
BR="$BUILD/bitstream-run"
FIX_OK=0
if [[ "$GEN_OK" -eq 1 ]]; then
    W="$BUILD/nextpnr-run"; rm -rf "$W" "$BR"; mkdir -p "$W" "$BR"
    FL="$OUT/logs/fixtures.log"; : > "$FL"
    (
        set -euo pipefail
        export PATH="$OSS/bin:$PATH"
        python3 -I "$OVERLAY" "$GENDIR/.FABulous" "$W/io-model/.FABulous"
        yosys -q -p "synth_fabulous -top top -extra-plib $NSRC/prims.v -extra-plib $NSRC/io_prims.v -extra-map $NSRC/io_map.v -cells-map $NSRC/cells_map.v -json $W/top_io.json" "$NSRC/top_io.v"
        FAB_ROOT="$W/io-model" nextpnr-generic --uarch fabulous --json "$W/top_io.json" -o pcf="$NSRC/top_io.pcf" -o fasm="$W/top_io.fasm" --write "$W/top_io.post.json"
        yosys -q -p "synth_fabulous -top top -ff \$_SDFFE_PP0P_ x -extra-plib $NSRC/prims.v -extra-plib $NSRC/io_prims.v -extra-map $NSRC/io_map.v -extra-map $NSRC/ff_map.v -cells-map $NSRC/cells_map.v -json $W/top_reg.raw.json" "$NSRC/top_reg.v"
        # clk is the BEL's implicit UserCLK (no fabric pin): drop the unconnected top port
        python3 -I - "$W/top_reg.raw.json" "$W/top_reg.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); m = d["modules"]["top"]
bits = set(m["ports"]["clk"]["bits"])
assert not any(bits & set(b) for c in m["cells"].values() for b in c["connections"].values()), "clk is connected to a cell"
del m["ports"]["clk"]
json.dump(d, open(sys.argv[2], "w"))
PY
        FAB_ROOT="$W/io-model" nextpnr-generic --uarch fabulous --json "$W/top_reg.json" -o pcf="$NSRC/top_reg.pcf" -o fasm="$W/top_reg.fasm" --write "$W/top_reg.post.json"
        PY="$VENV/bin/python"
        "$PY" -I "$TOOL" snapshot --spec "$GENDIR/.FABulous/bitStreamSpec.bin" \
            --configmem "$GENDIR/Tile/LOGIC4/LOGIC4_ConfigMem.v" --pips "$W/io-model/.FABulous/pips.txt" \
            --out "$BR" --fabulous-version "$("$PY" -c 'import importlib.metadata as m; print(m.version("fabulous-fpga"))')"
        for d in top_io top_reg; do
            cp "$W/$d.fasm" "$BR/$d.fasm"
            python3 -I "$TOOL" summary "$W/$d.post.json" --out "$BR/$d.mapped.json"
            python3 -I "$TOOL" assemble --fasm "$BR/$d.fasm" --snapshot "$BR/fabric_spec.json" \
                --mapped "$BR/$d.mapped.json" --out "$BR/$d" --filtered-fasm "$BR/$d.logic.fasm"
            "$VENV/bin/bit_gen" genBitstream "$BR/$d.logic.fasm" "$GENDIR/.FABulous/bitStreamSpec.bin" "$BR/$d.fabulous.bin" > "$BR/$d.bit_gen.out" 2>&1
            cmp "$BR/$d.bin" "$BR/$d.fabulous.bin"
            echo "bit_gen genBitstream output is byte-identical to the assembler's $d.bin"
        done
    ) >> "$FL" 2>&1 && FIX_OK=1
    if [[ "$FIX_OK" -eq 1 ]]; then
        record fixtures_regenerate PASS "top_io, top_reg mapped (yosys+nextpnr), assembled; assembler output byte-identical to FABulous bit_gen"
    else
        record fixtures_regenerate FAIL "see logs/fixtures.log (tail: $(tail -1 "$FL"))"
    fi
else
    record fixtures_regenerate NOT-RUN "needs fabulous_generate"
fi

FILES="fabric_spec.json logic4_configmem.map top_io.fasm top_io.mapped.json top_io.bin top_io.wiring top_io.cfg top_reg.fasm top_reg.mapped.json top_reg.bin top_reg.wiring top_reg.cfg"
if [[ "$FIX_OK" -eq 1 ]]; then
    if [[ "$UPDATE" -eq 1 ]]; then
        mkdir -p "$FIXDIR"
        for f in $FILES; do cp "$BR/$f" "$FIXDIR/$f"; done
        {
            echo "Regenerated by verification/run.sh --update-fixtures (issue #11)."
            echo "commit: $(git rev-parse HEAD)"
            echo "FABulous:        $(grep '^FABulous' "$OUT/env.txt")"
            echo "yosys:           $(grep '^yosys' "$OUT/env.txt")"
            echo "nextpnr-generic: $(grep '^nextpnr' "$OUT/env.txt")"
            echo "Pins: flow/toolchain.json. Inputs: rtl/common/fabulous/ (generator) and"
            echo "rtl/common/fabulous/nextpnr/{top_io,top_reg}.v (+ .pcf, prims/maps)."
            echo "Pad overlay: verification/common/flow/nextpnr_io_overlay.py. Assembler:"
            echo "verification/common/flow/fasm_to_bitstream.py (vendored, reuse.lock.json);"
            echo "cross-checked byte-for-byte against FABulous bit_gen genBitstream."
            echo "Command: verification/run.sh --update-fixtures"
            echo "sha256:"; (cd "$FIXDIR" && sha256sum $FILES)
        } > "$FIXDIR/PROVENANCE.txt"
        record fixtures_commit PASS "verification/bitstream/ rewritten from the regenerated copy"
    else
        drift=0
        for f in $FILES; do
            cmp -s "$BR/$f" "$FIXDIR/$f" 2>/dev/null || { echo "DRIFT: verification/bitstream/$f" >> "$OUT/logs/fixture-drift.log"; drift=1; }
        done
        if [[ "$drift" -eq 0 ]]; then record fixtures_match_committed PASS "regenerated fixtures byte-identical to verification/bitstream/"
        else record fixtures_match_committed FAIL "drift (logs/fixture-drift.log); rerun with --update-fixtures if intended"; fi
    fi
    if python3 -I "$TOOL" check "$FIXDIR" > "$OUT/logs/assembler-check.log" 2>&1; then
        record assembler_reproduce PASS "assembler re-derives every fixture in verification/bitstream/ from its FASM byte-for-byte"
    else record assembler_reproduce FAIL "logs/assembler-check.log"; fi
fi

# ------------------------------------------------- bitstream bench
if [[ ! -f "$FIXDIR/top_io.bin" ]]; then
    record tb_logic_tile_bitstream NOT-RUN "no committed fixtures in verification/bitstream/ and none regenerated"
else
    B=tb_logic_tile_bitstream
    if ! compile "$B" -g2012 -Wall -I "$S" -o "$OUT/logs/$B.vvp" "$RTL/lut4_slice.v" "$RTL/logic_tile_switch_matrix.v" "$RTL/logic_tile_routed.v" "$S/$B.v"; then
        record "$B" FAIL "iverilog compile failed (logs/$B.compile.log)"
    else
        for entry in comb:top_io reg:top_reg; do
            dn="${entry%%:*}"; st="${entry#*:}"; tag="${B}_${dn}"
            run_vvp "$tag" "$OUT/logs/$B.vvp" +bin="$FIXDIR/$st.bin" +map="$FIXDIR/logic4_configmem.map" +wiring="$FIXDIR/$st.wiring" +design="$dn" +mutate
            v="$(verdict_of "$tag" "^PASS: ${B}\\[${dn}\\]")"
            record "$tag (+mutate)" "${v%%|*}" "${v#*|}"
            # three independent reads of the same stream must agree on the tile vector
            sim_cfg="$(grep -o '^CFG=[0-9a-f]*' "$OUT/logs/$tag.log" | cut -d= -f2 || true)"
            py_cfg="$(python3 -I "$TOOL" decode "$FIXDIR/$st.bin" --snapshot "$FIXDIR/fabric_spec.json")"
            rec_cfg="$(tr -d '\n' < "$FIXDIR/$st.cfg")"
            if [[ -n "$sim_cfg" && "$sim_cfg" == "$py_cfg" && "$sim_cfg" == "$rec_cfg" ]]; then
                record "${tag}_cfg_crosscheck" PASS "simulation loader == python decoder == recorded cfg"
            else
                record "${tag}_cfg_crosscheck" FAIL "sim=$sim_cfg python=$py_cfg recorded=$rec_cfg"
            fi
            # malformed streams must be rejected by the loader
            BAD="$OUT/logs/bad_$dn"
            python3 -I "$REPO/verification/bitstream_corrupt.py" "$FIXDIR/$st.bin" "$FIXDIR/logic4_configmem.map" "$FIXDIR/$st.wiring" "$BAD" > /dev/null
            nbad=0; nrej=0
            for bad in "$BAD"/*.bin; do
                nbad=$((nbad + 1)); btag="bad_$dn/$(basename "${bad%.bin}")"
                run_vvp "$btag" "$OUT/logs/$B.vvp" +bin="$bad" +map="$FIXDIR/logic4_configmem.map" +wiring="$FIXDIR/$st.wiring" +design="$dn" +expect_reject
                if [[ "$RC" -eq 0 ]] && grep -q "^PASS: ${B}\\[${dn}\\] loader rejected" "$OUT/logs/$btag.log"; then nrej=$((nrej + 1))
                else echo "not rejected / not completed: $btag rc=$RC" >> "$OUT/logs/bad_$dn.failures"; fi
            done
            if [[ "$nrej" -eq "$nbad" && "$nbad" -gt 0 ]]; then
                record "${tag}_expect_reject" PASS "loader rejected $nrej/$nbad malformed streams"
            else
                record "${tag}_expect_reject" FAIL "loader rejected $nrej/$nbad (logs/bad_$dn.failures)"
            fi
        done
    fi
fi

# ------------------------------------------------- stamped benches this run cannot drive
reason_gen="needs a stimulus-stream generator from the sibling's flow/ (lut_basis.py / route_diag.py / ctrl_route.py / output_route.py), which is not stamped"
for b in tb_lut_basis tb_route_diag tb_ctrl_route tb_output_route; do record "$b" NOT-RUN "$reason_gen"; done
record tb_configmem_equiv NOT-RUN "needs +vec= transaction vectors from the sibling's flow/configmem_frames.py, which is not stamped"

# ------------------------------------------------- summary
{
    echo "# verification/run.sh summary"
    cat "$OUT/env.txt"
    echo
    column -t -s$'\t' "$TSV"
    echo
    echo "PASS:    $(grep -c $'\tPASS\t' "$TSV")"
    echo "FAIL:    $(grep -c $'\tFAIL\t' "$TSV")"
    echo "NOT-RUN: $(grep -c $'\tNOT-RUN\t' "$TSV")"
} > "$OUT/summary.txt"
tail -4 "$OUT/summary.txt"
exit "$overall"
