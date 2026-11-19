#!/usr/bin/env bash
# verification/test-fixtures-regenerate-fail.sh -- committed regression test
# for the fixture-stage FAIL path (issue #153).
#
# The guarantee under test: verification/fixtures-regenerate.sh must exit
# nonzero when the assembler's bytes differ from FABulous bit_gen's, and its
# output must not carry the byte-identical success line for the mismatching
# design. That path is exactly what the inline `( set -e ... ) &&` subshell
# broke before issue #140: set -e is suppressed on the left operand of `&&`,
# so the failed `cmp` fell through to the unconditional success echo and the
# runner recorded PASS on a byte mismatch. Nothing committed exercised the
# FAIL path (CI only ever sees the matching case), so a future edit could
# reintroduce the bug with every check still green.
#
# The harness runs the real fixtures-regenerate.sh with every pinned tool
# replaced by a stub in a temp dir -- no yosys, no nextpnr-generic, no FAB
# venv -- while `cmp` stays real: that comparison is the contract. The stub
# assembler writes `assembler-<design>`; the stub bit_gen writes the same
# bytes unless the design is named in FIXREGEN_MISMATCH_DESIGN, in which case
# it writes different bytes. So:
#
#   - match:                 both designs compare equal, script exits 0 and
#                            prints byte-identical for both (guards against
#                            the stubs being silently broken);
#   - mismatch on top_io:    the first iteration fails, script exits nonzero
#                            and never prints any byte-identical line;
#   - mismatch on top_reg:   the second iteration fails, script exits nonzero
#                            and never prints byte-identical for top_reg
#                            (top_io's own line legitimately appears first --
#                            the loop had reached the second design).
#
# Point FIXREGEN_SCRIPT at a copy of the script to test a variant without
# touching the committed file (used to sanity-check that reintroducing the
# #140 subshell pattern fails this test).
#
# Needs only bash + coreutils; run directly or from CI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${FIXREGEN_SCRIPT:-$SCRIPT_DIR/fixtures-regenerate.sh}"
[[ -f "$TARGET" ]] || { echo "test-fixtures-regenerate-fail: no script at $TARGET" >&2; exit 1; }

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/oss-bin" "$T/venv/bin" "$T/nsrc" "$T/work" "$T/out" "$T/gendir"
: > "$T/overlay.py"; : > "$T/fasm_to_bitstream.py"

fail() { echo "test-fixtures-regenerate-fail: FAIL: $*" >&2; exit 1; }

# --- the stub toolchain ----------------------------------------------------

# yosys: the mapping step itself is not under test; emit nothing, fail never.
cat > "$T/oss-bin/yosys" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

# nextpnr-generic: write the fasm file the script later cp's into $REGEN_OUT
# (-o fasm=<path>); everything else is ignored.
cat > "$T/oss-bin/nextpnr-generic" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
for a in "$@"; do
    case "$a" in
        fasm=*) f="${a#fasm=}"
                mkdir -p "$(dirname "$f")"
                printf 'stub-fasm\n' > "$f" ;;
    esac
done
exit 0
EOF

# python3 (resolved via the $REGEN_OSS_BIN PATH the script prepends): the
# script calls it in four shapes; dispatch on them, not on $REGEN_TOOL values.
#   -I <overlay> <gendir>/.FABulous <work>/io-model/.FABulous  (pad overlay)
#   -I - <raw.json> <json>                                     (clk-port heredoc)
#   -I <tool> snapshot --spec ... --out <REGEN_OUT> ...
#   -I <tool> summary <post.json> --out <mapped.json>
#   -I <tool> assemble --fasm ... --out <REGEN_OUT>/<design>
# The assembler is the left side of the `cmp` contract: it writes
# `assembler-<design>` to <REGEN_OUT>/<design>.bin.
cat > "$T/oss-bin/python3" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" = "-I" ]] || { echo "stub python3: unexpected argv: $*" >&2; exit 1; }
shift
case "$1" in
    -)  cat > /dev/null                 # swallow the heredoc
        mkdir -p "$(dirname "$3")"
        printf '{"modules": {}}\n' > "$3" ;;
    *)
        sub="${2:-}"
        case "$sub" in
            snapshot) shift 2; out=""
                      while [ $# -gt 0 ]; do
                          if [ "$1" = "--out" ]; then out="$2"; fi
                          shift
                      done
                      mkdir -p "$out"; printf '{}\n' > "$out/fabric_spec.json" ;;
            summary)  shift 2; out=""
                      while [ $# -gt 0 ]; do
                          if [ "$1" = "--out" ]; then out="$2"; fi
                          shift
                      done
                      mkdir -p "$(dirname "$out")"; printf '{}\n' > "$out" ;;
            assemble) shift 2; out=""
                      while [ $# -gt 0 ]; do
                          if [ "$1" = "--out" ]; then out="$2"; fi
                          shift
                      done
                      mkdir -p "$(dirname "$out")"
                      printf 'assembler-%s\n' "$(basename "$out")" > "$out.bin" ;;
            *)        mkdir -p "$2" "${@: -1}" ;;   # the pad overlay
        esac ;;
esac
EOF

# venv python: only used for `$(python -c 'import importlib.metadata...')`.
cat > "$T/venv/bin/python" <<'EOF'
#!/usr/bin/env bash
printf '0.0.0\n'
exit 0
EOF

# bit_gen: the right side of the `cmp` contract. Writes the same bytes the
# stub assembler wrote, unless the design is the one the harness is failing.
cat > "$T/venv/bin/bit_gen" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" = "genBitstream" ]] || { echo "stub bit_gen: unexpected argv: $*" >&2; exit 1; }
design="$(basename "$2" .logic.fasm)"
out="$4"
mkdir -p "$(dirname "$out")"
if [ "$design" = "${FIXREGEN_MISMATCH_DESIGN:-}" ]; then
    printf 'bitgen-mismatch-%s\n' "$design" > "$out"
else
    printf 'assembler-%s\n' "$design" > "$out"
fi
EOF

chmod +x "$T/oss-bin/yosys" "$T/oss-bin/nextpnr-generic" "$T/oss-bin/python3" \
         "$T/venv/bin/python" "$T/venv/bin/bit_gen"

# --- the $REGEN_* environment run.sh would set ------------------------------

export REGEN_GENDIR="$T/gendir" REGEN_WORK="$T/work" REGEN_OUT="$T/out" \
       REGEN_OSS_BIN="$T/oss-bin" REGEN_VENV="$T/venv" REGEN_NSRC="$T/nsrc" \
       REGEN_OVERLAY="$T/overlay.py" REGEN_TOOL="$T/fasm_to_bitstream.py"

run() {  # run <name> <FIXREGEN_MISMATCH_DESIGN>; sets rc and $T/<name>.out
    local name="$1" mismatch="$2"
    rc=0
    FIXREGEN_MISMATCH_DESIGN="$mismatch" "$TARGET" > "$T/$name.out" 2>&1 || rc=$?
}

# --- the cases ---------------------------------------------------------------

# Matching case: exit 0, byte-identical for both designs (proves the harness
# is not passing vacuously because a stub is broken).
run match ""
if [ "$rc" -ne 0 ]; then
    sed -n '1,20p' "$T/match.out" >&2
    fail "matching case exited $rc (want 0); output above"
fi
grep -q "byte-identical to the assembler's top_io.bin" "$T/match.out" \
    || fail "matching case never printed byte-identical for top_io"
grep -q "byte-identical to the assembler's top_reg.bin" "$T/match.out" \
    || fail "matching case never printed byte-identical for top_reg"

# Mismatch on top_io: nonzero exit, no byte-identical line at all (the first
# iteration failed, so the loop never completed a design).
run mm_top_io top_io
if [ "$rc" -eq 0 ]; then
    fail "byte mismatch on top_io exited 0 -- the exact #140 false-PASS signature"
fi
if grep -q "byte-identical" "$T/mm_top_io.out"; then
    fail "byte mismatch on top_io still printed a byte-identical line"
fi

# Mismatch on top_reg only: nonzero exit, and the mismatching design never
# gets its success line (top_io's legitimate line must be there -- the loop
# reached the second design rather than dying early).
run mm_top_reg top_reg
if [ "$rc" -eq 0 ]; then
    fail "byte mismatch on top_reg exited 0 (the #140 false-PASS signature)"
fi
if grep -q "byte-identical to the assembler's top_reg.bin" "$T/mm_top_reg.out"; then
    fail "byte mismatch on top_reg still printed its byte-identical line"
fi
grep -q "byte-identical to the assembler's top_io.bin" "$T/mm_top_reg.out" \
    || fail "top_reg-mismatch run never reached top_reg (no top_io success line)"

# Bare invocation (REGEN_* unset): the existing loud guard, exit 2.
rc=0
env -u REGEN_GENDIR "$TARGET" > "$T/unset.out" 2>&1 || rc=$?
if [ "$rc" -ne 2 ]; then
    fail "REGEN_GENDIR unset: exited $rc (want the guard's 2)"
fi

echo "test-fixtures-regenerate-fail: PASS (match, mismatch on top_io, mismatch on top_reg, unset guard)"
