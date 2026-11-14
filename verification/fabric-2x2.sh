#!/usr/bin/env bash
# verification/fabric-2x2.sh -- generate the 2x2 LOGIC4 demonstration fabric
# from rtl/fabric-2x2/fabric.csv with the pinned FABulous, map
# rtl/fabric-2x2/cross_tile.v onto it with the pinned yosys + nextpnr-generic,
# assemble a bitstream with FABulous's own bit_gen, and write the normalized
# record under measurements/g2-fabric-2x2-generation/ (issue #80).
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

# Normalize the generator log exactly as the G1 record documents: strip ANSI,
# rewrite the scratch path to <project>, sort the hash-ordered tile-name list,
# then sort unique. FABulous 2.2.0 emits tile names in hash order, so without
# this the log is not reproducible run to run.
normalize_generator_log() {
    sed -e 's/\x1b\[[0-9;]*m//g' -e "s#$GENDIR#<project>#g" \
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
( cd "$GENDIR" && timeout --kill-after=10 900 "$VENV/bin/FABulous" -p . script FABulous.tcl ) \
    > "$BUILD/g2-generator.raw.log" 2>&1 || GEN_RC=$?
if [[ "$GEN_RC" -ne 0 ]]; then
    echo "error: FABulous could not generate the 2x2 description (exit $GEN_RC)." >&2
    echo "       full log: flow/build/g2-generator.raw.log -- commit it and report it," >&2
    echo "       do not substitute another flow (issue #80, criterion 7)." >&2
    sed -e 's/\x1b\[[0-9;]*m//g' "$BUILD/g2-generator.raw.log" | tail -20 >&2
    exit "$GEN_RC"
fi
normalize_generator_log < "$BUILD/g2-generator.raw.log" > "$BUILD/g2-generator.log"
echo "   generation exit 0; normalized log $(wc -l < "$BUILD/g2-generator.log") lines"

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
{
    ( cd "$GENDIR" && find . -type f \
        ! -path './fabric.csv' ! -path './FABulous.tcl' ! -path './nextpnr/*' \
        ! -path './.FABulous/.fabulous_history' \
        -printf '%P\0' | xargs -0 sha256sum )
    ( cd "$PNRDIR" && sha256sum cross_tile.json cross_tile.fasm cross_tile.bin \
        | sed -E 's#^([0-9a-f]+)  #\1  nextpnr-2x2/#' )
} | LC_ALL=C sort -k2 > "$BUILD/g2-generated-files.sha256"
echo "== hashed $(wc -l < "$BUILD/g2-generated-files.sha256") generated files"

if [[ "$RECORD" -eq 1 ]]; then
    mkdir -p "$REC"
    cp "$BUILD/g2-generator.log" "$REC/generator.log"
    cp "$BUILD/g2-nextpnr.log" "$REC/nextpnr.log"
    cp "$BUILD/g2-generated-files.sha256" "$REC/generated-files.sha256"
    echo "== record written to measurements/g2-fabric-2x2-generation/ (README.md is hand-written)"
fi
