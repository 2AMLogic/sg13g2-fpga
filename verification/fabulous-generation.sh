#!/usr/bin/env bash
# verification/fabulous-generation.sh -- re-record G1 (issue #105): generate the
# stamped single-LOGIC4 description in rtl/common/fabulous/ with the pinned
# FABulous and write the normalized record under
# measurements/g1-fabulous-generation/.
#
# Before this script the G1 record was reproduced by hand-run commands
# (prose in the record's README). The manifest it committed hashed two
# generated files that embed checkout-absolute paths, so
# generated-files.sha256 reproduced only from the checkout that made it -- the
# same defect #94 fixed for the G2 record. This driver mirrors the mechanism
# that landed there (verification/fabric-2x2.sh): pin the generation-stage
# yosys via FAB_YOSYS_PATH, and hash the path-embedding files from path-masked
# copies, so the manifest reproduces from any checkout.
#
# This is a thin driver over the same toolchain verification/run.sh --setup
# fetches into the ignored flow/build/ tree. It installs nothing host-wide and
# it does not touch verification/common/ (vendored) or any stamped file: the
# generated copy starts from `cp -r rtl/common/fabulous` with NO overlay.
#
# It is the generation stage only, matching the record's manifest selection:
# no nextpnr/mapping outputs are hashed (G1's manifest has no nextpnr-* entries
# -- that stage stays with the record's original hand-run nextpnr.log). It
# shares $GENDIR with verification/run.sh; do not run them concurrently.
#
# Usage:
#   verification/run.sh --setup                  # once, fetches the pinned toolchain
#   verification/fabulous-generation.sh          # regenerate into flow/build/, print the record to stdout
#   verification/fabulous-generation.sh --record # additionally rewrite the two generated files
#                                                # in measurements/g1-fabulous-generation/
#
# Exit status: 0 only if generation succeeded AND the FAB_YOSYS_PATH guard
# passed AND the manifest was emitted over the full selection. Any failure is
# reported with its log; nothing is worked around.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
BUILD="$REPO/flow/build"
OSS="$BUILD/oss-cad-suite"
VENV="$BUILD/fab-venv"
GENDIR="$BUILD/fabulous-run"
REC="$REPO/measurements/g1-fabulous-generation"

RECORD=0
[[ "${1:-}" == "--record" ]] && RECORD=1

for f in "$OSS/bin/yosys" "$VENV/bin/FABulous"; do
    [[ -x "$f" ]] || { echo "error: pinned toolchain not present under flow/build/ (run verification/run.sh --setup)" >&2; exit 1; }
done

# Host-absolute paths make a log byte-reproducible only from the directory that
# produced it, and make a manifest reproduce only from one checkout. Rewrite
# every prefix that varies by checkout or host to a placeholder, most specific
# first: $GENDIR lives under $REPO, and $REPO itself normally lives under $HOME
# (the same PATHMASK verification/fabric-2x2.sh uses, issue #94).
HOSTPATHS=(-e "s#$OSS#<oss-cad-suite>#g" -e "s#$VENV#<fab-venv>#g" -e "s#$REPO#<repo>#g")
[[ -n "${HOME:-}" ]] && HOSTPATHS+=(-e "s#$HOME#<home>#g")

# The path rewrites proper, shared by the log normalizer and by the masked
# hashing below. Content rewrites only; never applied to a binary -- the
# hashed masked set is the explicit two-file allowlist at the hashing site.
PATHMASK=(-e "s#$GENDIR#<project>#g" "${HOSTPATHS[@]}")
mask_paths() { sed "${PATHMASK[@]}"; }

# Normalize the generator log exactly as the record documents (ANSI stripped,
# scratch path rewritten to <project>, tool-probe lines dropped, sorted unique
# lines, tile-name list sorted, because FABulous 2.2.0 emits tiles in hash
# order). Dropping the tool-probe lines is the record's documented
# normalization, kept verbatim: restoring them is deliberately out of scope for
# issue #105. The dropped classes, as the committed record shows them: the
# INFO `Resolved <tool> path:` probes, the `<tool> not found in PATH`
# warnings, and the PDK_root environment warning. Consequence: the
# Resolved-yosys guard below must read the raw log, since normalization removes
# exactly those lines.
normalize_generator_log() {
    sed -e 's/\x1b\[[0-9;]*m//g' "${PATHMASK[@]}" \
        -e '/^INFO | Resolved /d' -e '/ not found in PATH/d' \
        -e '/^WARNING | PDK_root or PDK is not set/d' \
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

echo "== generating the stamped single-LOGIC4 fabric with the pinned FABulous"
rm -rf "$GENDIR"
cp -r "$REPO/rtl/common/fabulous" "$GENDIR"   # no overlay: the stamped fabric.csv is the point of G1
GEN_RC=0
# FABulous shells out to a bare `yosys` while reading the fabric; pin it to the
# suite's binary so the generated tree's creator string is not a function of
# the host's ~/.local/bin/yosys (the mechanism verification/run.sh:198 already
# uses for this same scratch path, landed for G2 by PR #100/#94).
( cd "$GENDIR" && FAB_YOSYS_PATH="$OSS/bin/yosys" \
    timeout --kill-after=10 600 "$VENV/bin/FABulous" -p . script FABulous.tcl ) \
    > "$BUILD/g1-generator.raw.log" 2>&1 || GEN_RC=$?
if [[ "$GEN_RC" -ne 0 ]]; then
    echo "error: FABulous could not generate the stamped description (exit $GEN_RC)." >&2
    echo "       full log: flow/build/g1-generator.raw.log -- commit it and report it," >&2
    echo "       do not substitute another flow." >&2
    sed -e 's/\x1b\[[0-9;]*m//g' "$BUILD/g1-generator.raw.log" | tail -20 >&2
    exit "$GEN_RC"
fi
normalize_generator_log < "$BUILD/g1-generator.raw.log" > "$BUILD/g1-generator.log"
# FAB_YOSYS_PATH fails open: FABulousSettings falls back to a PATH lookup when
# the override is not an existing file, and then logs "Resolved yosys path:".
# That silently swaps the host yosys back in -- a FAIL, not a fall-back. The
# suite's binary was already checked executable above, so a hit here means the
# override was ignored or the validator changed (issue #94). This record's
# documented normalization drops the Resolved-* lines, so the normalized log
# cannot carry the evidence: strip ANSI codes once into a scratch file and grep
# THAT FILE. Grepping the raw log through a pipe is fail-open here -- `grep -q`
# exits at the first match and sed's SIGPIPE (141) then becomes the pipeline's
# status under pipefail, so the guard would take its else branch on a match.
ANSI_LOG="$BUILD/g1-generator.ansi.log"
sed -e 's/\x1b\[[0-9;]*m//g' "$BUILD/g1-generator.raw.log" > "$ANSI_LOG"
if grep -q 'Resolved yosys path:' "$ANSI_LOG"; then
    echo "error: FABulous ignored FAB_YOSYS_PATH and resolved yosys from PATH ($(sed -n 's/.*Resolved yosys path: //p' "$ANSI_LOG" | head -1))." >&2
    echo "       the generated tree's creator string would depend on the host again" >&2
    echo "       (issue #94); refusing to record it. Check that $OSS/bin/yosys" >&2
    echo "       exists and rerun." >&2
    exit 1
fi
echo "   generation exit 0; normalized log $(wc -l < "$BUILD/g1-generator.log") lines"
echo "   generation yosys: $("$OSS/bin/yosys" -V)"

# sha256 of the generated project tree, the record's 37-file selection exactly:
# every file in the project copy except the fabric description, the TCL script
# and the nextpnr/ source overlay (and FABulous's own shell history), paths
# project-relative, sorted by name. No mapping outputs are appended -- G1's
# manifest has none.
#
# Two of the selection embed checkout-absolute paths, so they are hashed from a
# path-masked copy via mask_paths and excluded from the raw find/sha256sum pass:
# - `Tile/LOGIC4/lut4_ff_bel.json` -- yosys records an absolute `src` for every
#   cell and wire, and (since FAB_YOSYS_PATH above) its `creator` is the pinned
#   suite yosys rather than the host's;
# - `eFPGA_geometry.csv` -- its `Src,…`/`Csv,…` rows name each switch-matrix
#   file absolutely.
# An explicit allowlist, not a blanket mask: the tree also contains the binary
# `.FABulous/bitStreamSpec.bin`, which sed must never touch and which keeps its
# raw hash. Consequence, stated in the record's ## Files: a masked entry cannot
# be checked with `sha256sum -c` against a raw generated tree; re-run this
# script and diff the manifest instead.
#
# The masked set is declared ONCE, here, and the find exclusion for it is
# derived from this array -- fabric-2x2.sh names its set three times in three
# syntaxes with nothing tying them together, and a forgotten exclusion there
# hashes a file twice under one name (issue #107); G1's driver must not inherit
# that. The duplicate check below turns any residual drift into a loud failure
# rather than a doubled manifest entry.
MASKED_FILES=(Tile/LOGIC4/lut4_ff_bel.json eFPGA_geometry.csv)
MASKED_EXCLUDES=()
for f in "${MASKED_FILES[@]}"; do MASKED_EXCLUDES+=(! -path "./$f"); done
{
    ( cd "$GENDIR" && find . -type f \
        ! -path './fabric.csv' ! -path './FABulous.tcl' ! -path './nextpnr/*' \
        ! -path './.FABulous/.fabulous_history' \
        "${MASKED_EXCLUDES[@]}" \
        -printf '%P\0' | xargs -0 sha256sum )
    for f in "${MASKED_FILES[@]}"; do
        [[ -f "$GENDIR/$f" ]] || { echo "error: masked-file allowlist entry missing: $f" >&2; exit 1; }
        printf '%s  %s\n' "$(mask_paths < "$GENDIR/$f" | sha256sum | cut -d' ' -f1)" "$f"
    done
} | LC_ALL=C sort -k2 > "$BUILD/g1-generated-files.sha256"
DUPS="$(awk '{print $2}' "$BUILD/g1-generated-files.sha256" | LC_ALL=C sort | uniq -d)"
if [[ -n "$DUPS" ]]; then
    echo "error: manifest lists a file more than once (raw and masked?): $DUPS" >&2
    exit 1
fi
echo "== hashed $(wc -l < "$BUILD/g1-generated-files.sha256") generated files (${#MASKED_FILES[@]} path-masked: ${MASKED_FILES[*]})"

if [[ "$RECORD" -eq 1 ]]; then
    mkdir -p "$REC"
    cp "$BUILD/g1-generator.log" "$REC/generator.log"
    cp "$BUILD/g1-generated-files.sha256" "$REC/generated-files.sha256"
    echo "== record written to measurements/g1-fabulous-generation/ (README.md and nextpnr.log are hand-maintained)"
fi
