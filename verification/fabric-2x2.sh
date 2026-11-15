#!/usr/bin/env bash
# verification/fabric-2x2.sh -- generate the 2x2 LOGIC4 demonstration fabric
# from rtl/fabric-2x2/fabric.csv with the pinned FABulous, map
# rtl/fabric-2x2/cross_tile.v onto it with the pinned yosys + nextpnr-generic,
# assemble a bitstream with FABulous's own bit_gen, and write the normalized
# record under measurements/g2-fabric-2x2-generation/ (issue #80).
#
# The generation stage pins FABulous to the suite's yosys via FAB_YOSYS_PATH
# (the same mechanism verification/run.sh uses), so the generated tree's
# creator string is not a function of the host's ~/.local/bin/yosys, and the
# manifest hashes the three generated files that embed absolute paths from a
# path-masked copy, so it reproduces from any checkout (issue #94).
#
# This is a thin driver over the same toolchain verification/run.sh --setup
# fetches into the ignored flow/build/ tree. It installs nothing host-wide and
# it does not touch verification/common/ (vendored) or the single-tile harness.
#
# Usage:
#   verification/run.sh --setup          # once, fetches the pinned toolchain
#   verification/fabric-2x2.sh           # regenerate into flow/build/, print the record to stdout
#   verification/fabric-2x2.sh --record  # additionally rewrite measurements/g2-fabric-2x2-generation/
#
# Exit status: 0 only if generation, mapping, routing and bit_gen all succeeded
# AND the FASM shows a LOGIC4 -> LOGIC4 crossing. Any failure is reported with
# its log; nothing is worked around.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
BUILD="$REPO/flow/build"
OSS="$BUILD/oss-cad-suite"
VENV="$BUILD/fab-venv"
GENDIR="$BUILD/fabulous-2x2"
PNRDIR="$BUILD/nextpnr-2x2"
SRC="$REPO/rtl/fabric-2x2"
NSRC="$REPO/rtl/common/fabulous/nextpnr"
REC="$REPO/measurements/g2-fabric-2x2-generation"

RECORD=0
[[ "${1:-}" == "--record" ]] && RECORD=1

for f in "$OSS/bin/nextpnr-generic" "$OSS/bin/yosys" "$VENV/bin/FABulous" "$VENV/bin/bit_gen"; do
    [[ -x "$f" ]] || { echo "error: pinned toolchain not present under flow/build/ (run verification/run.sh --setup)" >&2; exit 1; }
done

# Host-absolute paths make a log byte-reproducible only from the directory that
# produced it -- for a Loom worktree, one that ceases to exist when the PR
# merges. The rule itself -- rewrite every prefix that varies by checkout or
# host to a placeholder, most specific first -- is shared with
# fabulous-generation.sh via verification/manifest-mask.sh (issue #122), so the
# two drivers cannot spell it differently again. Applied to BOTH logs, so
# neither reproduces from only one path on only one host (issue #80), and --
# since issue #94 -- to the hashed copies of the generated files that embed
# absolute paths, so generated-files.sha256 reproduces from any checkout.
source "$REPO/verification/manifest-mask.sh"
manifest_mask_init "$REPO" "$OSS" "$VENV" "$GENDIR"

# Wall-clock fields. Each of these read 0.00 on the fast host the record was
# first made on and flip on a slower one, so none of them is reproducible; the
# three deletions further down (`time spent`, `Router1/SA placement/HeAP time`)
# cover a different set of lines and miss every form below. Rewritten to <t>
# rather than deleted, so the evidence sharing the line survives in the record:
# ABC's equivalence verdict, the placer's wirelen/spread/legal counts and the
# router's iteration counts are all load-bearing and all time-stamped.
WALLCLOCK=(
    -e 's/ T = *[0-9.]\+ sec$/ T = <t> sec/'
    -e 's/^ABC: Total time = *[0-9.]\+ sec$/ABC: Total time = <t> sec/'
    -e 's/ Time = *[0-9.]\+ sec$/ Time = <t> sec/'
    -e 's/^ABC: elapse: [0-9.]\+ seconds, total: [0-9.]\+ seconds$/ABC: elapse: <t> seconds, total: <t> seconds/'
    -e 's/; time = [0-9.]\+s$/; time = <t>s/'
    -e 's/^Info: HeAP Placer Time: [0-9.]\+s$/Info: HeAP Placer Time: <t>s/'
    -e 's/| *[0-9]\+\.[0-9]\+ *[0-9]\+\.[0-9]\+|$/|       <t>       <t>|/'
)

# Normalize the generator log as the G1 record documents: strip ANSI, rewrite
# the scratch path to <project> (PATHMASK, above), sort the hash-ordered
# tile-name list, then sort unique. FABulous 2.2.0 emits tile names in hash
# order, so without this the log is not reproducible run to run. Beyond G1,
# PATHMASK also masks the host/checkout prefixes: FABulous logs the absolute
# path of every tool it resolves, which is evidence worth keeping (see the
# record's Finding 4) but must not pin the log to one machine.
normalize_generator_log() {
    sed -e 's/\x1b\[[0-9;]*m//g' "${PATHMASK[@]}" \
    | awk '
        /^INFO \| Generating tile / {
            n = split($0, f, " ")
            # fields 1..4 are "INFO | Generating tile"; 5..n are tile names
            if (n > 5) {
                for (i = 5; i <= n; i++) t[i - 4] = f[i]
                m = n - 4
                for (i = 1; i < m; i++) for (j = i + 1; j <= m; j++)
                    if (t[i] > t[j]) { s = t[i]; t[i] = t[j]; t[j] = s }
                line = "INFO | Generating tile"
                for (i = 1; i <= m; i++) line = line " " t[i]
                print line; next
            }
        }
        { print }
    ' \
    | LC_ALL=C sort -u
}

echo "== generating the 2x2 fabric with the pinned FABulous"
rm -rf "$GENDIR"
cp -r "$REPO/rtl/common/fabulous" "$GENDIR"
cp "$SRC/fabric.csv" "$GENDIR/fabric.csv"      # the only overlay; no vendored file is edited
GEN_RC=0
# FABulous shells out to a bare `yosys` while reading the fabric; pin it to
# the suite's binary so the generated tree's creator string is not a function
# of the host's ~/.local/bin/yosys (issue #94, criterion 1). The PATH export
# further down covers the mapping subshell only, and deliberately stays there:
# putting the suite on PATH for generation would also swap the suite's
# iverilog/vvp/openroad in for the host's -- a larger behaviour change than
# the defect needs, and a divergence from run.sh, which pins the same way.
( cd "$GENDIR" && FAB_YOSYS_PATH="$OSS/bin/yosys" \
    timeout --kill-after=10 900 "$VENV/bin/FABulous" -p . script FABulous.tcl ) \
    > "$BUILD/g2-generator.raw.log" 2>&1 || GEN_RC=$?
if [[ "$GEN_RC" -ne 0 ]]; then
    echo "error: FABulous could not generate the 2x2 description (exit $GEN_RC)." >&2
    echo "       full log: flow/build/g2-generator.raw.log -- commit it and report it," >&2
    echo "       do not substitute another flow (issue #80, criterion 7)." >&2
    sed -e 's/\x1b\[[0-9;]*m//g' "$BUILD/g2-generator.raw.log" | tail -20 >&2
    exit "$GEN_RC"
fi
normalize_generator_log < "$BUILD/g2-generator.raw.log" > "$BUILD/g2-generator.log"
# FAB_YOSYS_PATH fails open: FABulousSettings falls back to a PATH lookup when
# the override is not an existing file, and then logs "Resolved yosys path:".
# That silently swaps the host yosys back in -- a FAIL, not a fall-back. The
# suite's binary was already checked executable above, so a hit here means
# the override was ignored or the validator changed (issue #94, criterion 2).
if grep -q 'Resolved yosys path:' "$BUILD/g2-generator.log"; then
    echo "error: FABulous ignored FAB_YOSYS_PATH and resolved yosys from PATH ($(sed -n 's/.*Resolved yosys path: //p' "$BUILD/g2-generator.log" | head -1))." >&2
    echo "       the generated tree's creator string would depend on the host again" >&2
    echo "       (issue #94); refusing to record it. Check that $OSS/bin/yosys" >&2
    echo "       exists and rerun." >&2
    exit 1
fi
echo "   generation exit 0; normalized log $(wc -l < "$BUILD/g2-generator.log") lines"
echo "   generation yosys: $("$OSS/bin/yosys" -V)"

echo "== mapping cross_tile.v with the pinned yosys + nextpnr-generic"
rm -rf "$PNRDIR"; mkdir -p "$PNRDIR"
export PATH="$OSS/bin:$PATH"
MAP_RC=0
set +e
(
    set -eo pipefail
    echo "# yosys:           $(yosys -V)"
    echo "# nextpnr-generic: $(nextpnr-generic --version 2>&1 | sed -n 1p)"
    echo "# FABulous:        $("$VENV/bin/FABulous" --version 2>&1 | sed -n '$p')"
    echo
    echo "\$ yosys -p 'synth_fabulous -top top -noiopad -extra-plib prims.v -json cross_tile.json' cross_tile.v"
    yosys -p "synth_fabulous -top top -noiopad -extra-plib $NSRC/prims.v -json $PNRDIR/cross_tile.json" "$SRC/cross_tile.v" 2>&1
    echo
    echo "\$ FAB_ROOT=<project> nextpnr-generic --uarch fabulous --json cross_tile.json -o fasm=cross_tile.fasm"
    FAB_ROOT="$GENDIR" timeout --kill-after=10 600 nextpnr-generic --uarch fabulous \
        --json "$PNRDIR/cross_tile.json" -o fasm="$PNRDIR/cross_tile.fasm" 2>&1
    echo
    echo "\$ bit_gen genBitstream cross_tile.fasm <project>/.FABulous/bitStreamSpec.bin cross_tile.bin"
    timeout --kill-after=10 300 "$VENV/bin/bit_gen" genBitstream "$PNRDIR/cross_tile.fasm" \
        "$GENDIR/.FABulous/bitStreamSpec.bin" "$PNRDIR/cross_tile.bin" 2>&1
    echo
    echo "# ---- cross_tile.fasm ----"
    cat "$PNRDIR/cross_tile.fasm"
) > "$BUILD/g2-nextpnr.raw.log" 2>&1
MAP_RC=$?
set -e
if [[ "$MAP_RC" -ne 0 ]]; then
    echo "error: yosys / nextpnr / bit_gen failed (exit $MAP_RC)." >&2
    echo "       full log: flow/build/g2-nextpnr.raw.log -- commit it and report it," >&2
    echo "       do not hand-edit the FASM or reach into verification/common/" >&2
    echo "       (issue #80, criterion 7)." >&2
    tail -20 "$BUILD/g2-nextpnr.raw.log" >&2
    exit "$MAP_RC"
fi
# Drop the run-to-run unstable lines (checksums, wall-clock, logfile hash),
# as the G1 nextpnr.log did, and rewrite absolute paths.
sed -e 's/\x1b\[[0-9;]*m//g' -e "s#$GENDIR#<project>#g" -e "s#$PNRDIR/##g" -e "s#$NSRC/##g" -e "s#$SRC/##g" \
    "${HOSTPATHS[@]}" "${WALLCLOCK[@]}" \
    -e '/^Info: Checksum:/d' -e '/time spent/Id' -e '/^Info: *of which /d' \
    -e '/^Info: \(Router1\|SA placement\|HeAP\) time /d' -e '/Logfile hash:/d' \
    -e '/^Info: Program finished normally/d' \
    -e 's/^[0-9]\{4\}-[0-9][0-9]-[0-9][0-9] [0-9:.]* +[0-9:]* | /<timestamp> | /' \
    "$BUILD/g2-nextpnr.raw.log" > "$BUILD/g2-nextpnr.log"

FASM="$PNRDIR/cross_tile.fasm"

echo "== checking the FASM for a LOGIC4 -> LOGIC4 crossing"
# A LOGIC4 tile is one the generated fabric instantiates as <coord>_LOGIC4 in
# Fabric/eFPGA.v -- read from the generated RTL, never assumed from fabric.csv.
LOGIC_COORDS="$(grep -oE 'Tile_X[0-9]+Y[0-9]+_LOGIC4' "$GENDIR/Fabric/eFPGA.v" \
    | sed -E 's/Tile_(X[0-9]+Y[0-9]+)_LOGIC4/\1/' | LC_ALL=C sort -u)"
echo "   LOGIC4 tiles in the generated fabric: $(echo "$LOGIC_COORDS" | tr '\n' ' ')"

# For each routed net, the driver feature is "<coord>.<BEL>_O.<wire>BEG<n>" and
# the sink feature is "<coord>.<wire>END<n>.<BEL>_I<n>". A crossing is a net
# whose driver coord and sink coord differ and are both LOGIC4.
CROSS="$(python3 -I - "$FASM" <<'PY'
import re, sys
net, feats, out = None, [], []
def flush():
    if not net: return
    drv = [f for f in feats if re.match(r'^X\d+Y\d+\.L[A-D]_O\.', f)]
    snk = [f for f in feats if re.search(r'\.L[A-D]_I\d+$', f)]
    for d in drv:
        for s in snk:
            dc, sc = d.split('.')[0], s.split('.')[0]
            if dc != sc:
                out.append((net, dc, d, sc, s))
for line in open(sys.argv[1]):
    line = line.strip()
    m = re.match(r"^# routing for net '(.*)'$", line)
    if m:
        flush(); net, feats = m.group(1), []; continue
    if line.startswith('# config for cell'):
        flush(); net, feats = None, []; continue
    if line and not line.startswith('#'):
        feats.append(line)
flush()
for net, dc, d, sc, s in out:
    print(f"{net}\t{dc}\t{d}\t{sc}\t{s}")
PY
)"
echo "$CROSS" > "$BUILD/g2-crossings.tsv"

# Keep only crossings where BOTH coordinates are LOGIC4 (CAP_* cells are
# harness-only terminators, not logic tiles -- the existing single-tile G1
# record already has features at two coordinates, one of them a CAP_E).
L4CROSS=0
while IFS=$'\t' read -r net dc dfeat sc sfeat; do
    [[ -z "${net:-}" ]] && continue
    if grep -qx "$dc" <<< "$LOGIC_COORDS" && grep -qx "$sc" <<< "$LOGIC_COORDS"; then
        echo "   LOGIC4 -> LOGIC4 crossing: net '$net'  $dc ($dfeat)  ->  $sc ($sfeat)"
        L4CROSS=$((L4CROSS + 1))
    fi
done <<< "$CROSS"
if [[ "$L4CROSS" -eq 0 ]]; then
    echo "error: no LOGIC4 -> LOGIC4 crossing in the FASM; the design did not cross a tile boundary" >&2
    exit 1
fi
echo "   $L4CROSS LOGIC4 -> LOGIC4 crossing(s)"

BIN_SHA="$(sha256sum "$PNRDIR/cross_tile.bin" | cut -d' ' -f1)"
echo "== bit_gen bitstream: $BIN_SHA  ($(stat -c%s "$PNRDIR/cross_tile.bin") bytes)"

# sha256 of the generated project tree, mirroring the G1 record's shape and
# selection exactly: every file in the project copy except the fabric
# description, the TCL script and the nextpnr/ source overlay (G1 hashed 37
# files on the same rule). Paths are project-relative and sorted. The mapping
# outputs are appended under a nextpnr-2x2/ prefix so criterion 4's bitstream
# sha256 lives in the same manifest.
#
# Three generated files embed checkout-absolute paths, so they are hashed from
# a path-masked copy via mask_paths and excluded from the raw find/sha256sum
# lists below. The masked set is declared exactly once, in the MASKED_BASE /
# MASKED_PATH parallel arrays: every find exclusion, every masked hash and the
# summary line is derived from that one declaration, and two assertions over
# the written manifest enforce what the original comment could only admonish
# ("must stay in step", issue #94 -- the assertions are issue #107):
# - no filename may appear twice. A file covered by both a raw list and the
#   declaration would otherwise land in the manifest twice -- once
#   path-dependent raw, once masked -- because the sort below is deliberately
#   not `sort -u`;
# - every declared masked entry must appear in the finished manifest. An edit
#   that drops an entry from the hashing paths must fail the run, not surface
#   later as a missing line a human happens to notice in a re-recorded record.
# Each entry carries its base directory: GENDIR members are excluded from the
# raw find and hashed from a masked copy under $GENDIR; the PNRDIR member is
# hashed from a masked copy under $PNRDIR and manifest-named under its
# basename, like the raw mapping outputs. Why these three, and not the whole
# tree:
# - `Tile/LOGIC4/lut4_ff_bel.json` -- yosys records an absolute `src` for every
#   cell and wire, and (since FAB_YOSYS_PATH above) its `creator` is the pinned
#   suite yosys rather than the host's;
# - `eFPGA_geometry.csv` -- its `Src,…`/`Csv,…` rows name each switch-matrix
#   file absolutely;
# - `nextpnr-2x2/cross_tile.json` -- found by this record's own two-checkout
#   demonstration: yosys's synth output records `src` attributes into the
#   suite's `share/yosys/abc9_model.v` and the repo's `prims.v`/`cross_tile.v`,
#   exactly the same absolute-path habit as lut4_ff_bel.json.
# An explicit allowlist, not a blanket mask: the tree also contains binaries
# (.FABulous/bitStreamSpec.bin, nextpnr-2x2/cross_tile.bin) that sed must
# never touch. Consequence, stated in the record's ## Files: a masked entry
# cannot be checked with `sha256sum -c` against a raw generated tree; re-run
# this script and diff the manifest instead.
MASKED_BASE=(GENDIR GENDIR PNRDIR)
MASKED_PATH=(Tile/LOGIC4/lut4_ff_bel.json eFPGA_geometry.csv cross_tile.json)
PNRSUB="$(basename "$PNRDIR")"

# Derived from the declaration alone: the raw find's exclusion predicates
# (GENDIR members only -- that find walks $GENDIR) and each member's manifest
# name, reused by the hashing loop, the summary line and the assertions.
FIND_EXCL=()
MASKED_NAMES=()
for i in "${!MASKED_PATH[@]}"; do
    if [[ "${MASKED_BASE[i]}" == GENDIR ]]; then
        FIND_EXCL+=('!' -path "./${MASKED_PATH[i]}")
        MASKED_NAMES+=("${MASKED_PATH[i]}")
    else
        MASKED_NAMES+=("$PNRSUB/${MASKED_PATH[i]}")
    fi
done

# Assert one written manifest is drift-free: no duplicated filename (checked
# by the shared guard in verification/manifest-mask.sh, issue #122), and no
# declared masked entry missing (an exclusion or hashing edit that silently
# drops it).
assert_manifest_consistent() {
    local manifest="$1" name
    assert_no_duplicate_names "$manifest"
    for name in "${MASKED_NAMES[@]}"; do
        if ! awk -F'  ' -v n="$name" '$2 == n { f = 1 } END { if (f) exit 0; exit 1 }' "$manifest"; then
            echo "error: masked entry missing from the generated-files manifest: $name" >&2
            echo "       the raw lists and the MASKED_BASE/MASKED_PATH declaration" >&2
            echo "       disagree; the record would lose a generated artifact (issue #107)" >&2
            return 1
        fi
    done
}

{
    ( cd "$GENDIR" && find . -type f \
        ! -path './fabric.csv' ! -path './FABulous.tcl' ! -path './nextpnr/*' \
        ! -path './.FABulous/.fabulous_history' \
        "${FIND_EXCL[@]}" \
        -printf '%P\0' | xargs -0 sha256sum )
    for i in "${!MASKED_PATH[@]}"; do
        f="${MASKED_PATH[i]}"
        d="$GENDIR"; [[ "${MASKED_BASE[i]}" == PNRDIR ]] && d="$PNRDIR"
        [[ -f "$d/$f" ]] || { echo "error: masked-file allowlist entry missing: ${MASKED_NAMES[i]}" >&2; exit 1; }
        printf '%s  %s\n' "$(mask_paths < "$d/$f" | sha256sum | cut -d' ' -f1)" "${MASKED_NAMES[i]}"
    done
    ( cd "$PNRDIR" && sha256sum cross_tile.fasm cross_tile.bin \
        | sed -E 's#^([0-9a-f]+)  #\1  nextpnr-2x2/#' )
} | LC_ALL=C sort -k2 > "$BUILD/g2-generated-files.sha256"
assert_manifest_consistent "$BUILD/g2-generated-files.sha256"
echo "== hashed $(wc -l < "$BUILD/g2-generated-files.sha256") generated files (${#MASKED_NAMES[@]} path-masked: ${MASKED_NAMES[*]})"

if [[ "$RECORD" -eq 1 ]]; then
    mkdir -p "$REC"
    cp "$BUILD/g2-generator.log" "$REC/generator.log"
    cp "$BUILD/g2-nextpnr.log" "$REC/nextpnr.log"
    cp "$BUILD/g2-generated-files.sha256" "$REC/generated-files.sha256"
    echo "== record written to measurements/g2-fabric-2x2-generation/ (README.md is hand-written)"
fi
