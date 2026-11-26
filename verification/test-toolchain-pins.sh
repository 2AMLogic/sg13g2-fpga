#!/usr/bin/env bash
# verification/test-toolchain-pins.sh -- committed regression test for the
# FABulous / nextpnr-generic pin gate that verification/run.sh and
# verification/blinky.sh share through
# verification/common/flow/toolchain-pins.sh (issue #169).
#
# The guarantee under test: each entry point accepts the pinned FABulous banner
# and the complete pinned nextpnr (Version ...) field -- also when the banner's
# leading tag is shorter than that field -- and stops at the pin check, exit 1
# and before any work with the tool, on a FABulous release candidate, a dirty
# nextpnr version, and a nextpnr banner that carries the pin but no version
# field. The banners the bench runner records in env.txt are exactly the ones
# it checked.
#
# Each driver runs in a temp tree laid out like the repo, with
# flow/toolchain.json copied and every pinned tool replaced by a stub that
# prints the banner named in its environment -- no FABulous, no nextpnr, no
# Icarus, no network. A stub invoked past the gate leaves a marker and exits
# nonzero, which stops the run at the next stage (the first bench compile for
# run.sh, fabric generation for blinky.sh):
#
#   - accept:  pinned FABulous + the pinned nextpnr field under a shorter
#              leading tag: the marker exists;
#   - reject:  release candidate / dirty field / no field: exit 1, the
#              driver's own error naming the pin, no marker;
#
# and for the bench runner alone: --setup exits 0 without the gate (its
# setup-only exit), and with no toolchain under flow/build/ the gate is
# skipped and the generated-fabric benches are listed NOT-RUN (its
# optional-tool handling). The helper itself is checked to fail closed on a
# missing pin.
#
# PINTEST_RUN, PINTEST_BLINKY and PINTEST_HELPER point the test at copies of
# the two drivers and the helper, to test a variant without touching the
# committed files (used to sanity-check that a weakened comparison -- a
# substring match, say -- fails this test).
#
# Needs only bash + coreutils + python3; run directly or from CI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
RUN_SRC="${PINTEST_RUN:-$SCRIPT_DIR/run.sh}"
BLINKY_SRC="${PINTEST_BLINKY:-$SCRIPT_DIR/blinky.sh}"
HELPER_SRC="${PINTEST_HELPER:-$REPO/verification/common/flow/toolchain-pins.sh}"
for f in "$RUN_SRC" "$BLINKY_SRC" "$HELPER_SRC"; do
    [[ -f "$f" ]] || { echo "test-toolchain-pins: no file at $f" >&2; exit 1; }
done

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
fail() { echo "test-toolchain-pins: FAIL: $*" >&2; exit 1; }
dump() { sed -n '1,20p' "$T/out" >&2; }

# --- the banners ------------------------------------------------------------
# Built from pins read straight out of the manifest, never through the helper
# under test.

pin2() {  # pin2 <tool> <key>
    python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]][sys.argv[3]])' \
        "$REPO/flow/toolchain.json" "$1" "$2"
}
PINTEST_ICARUS_PIN="$(pin2 icarus-verilog version)"; export PINTEST_ICARUS_PIN
FAB_PIN="$(pin2 fabulous version)"
NEXTPNR_PIN="$(pin2 nextpnr-generic version)"

FAB_OK="FABulous CLI $FAB_PIN"
FAB_RC="FABulous CLI ${FAB_PIN}rc1"
# nextpnr's leading tag can be shorter than the version field it prints.
TAG="$(sed -E 's/^(nextpnr-[0-9]+(\.[0-9]+)*).*/\1/' <<<"$NEXTPNR_PIN")"
NEXTPNR_OK="$TAG -- Next Generation Place and Route (Version $NEXTPNR_PIN)"
NEXTPNR_DIRTY="$TAG -- Next Generation Place and Route (Version ${NEXTPNR_PIN}-dirty)"
NEXTPNR_NOFIELD="$NEXTPNR_PIN -- Next Generation Place and Route"

# --- the stub toolchain ------------------------------------------------------

# Icarus is a host prerequisite both drivers check before the gate, so its
# banner carries the pin; any other invocation is the first bench compile.
mkdir -p "$T/bin" "$T/stubs"
cat > "$T/bin/iverilog" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" = "-V" ]]; then echo "Icarus Verilog version $PINTEST_ICARUS_PIN (stable) (stub)"; exit 0; fi
: > "$PINTEST_MARKERS/iverilog-compile"
exit 99
EOF
cat > "$T/bin/vvp" <<'EOF'
#!/usr/bin/env bash
echo "stub vvp: unexpected argv: $*" >&2; exit 99
EOF
cat > "$T/stubs/nextpnr-generic" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" = "--version" ]] || { echo "stub nextpnr-generic: unexpected argv: $*" >&2; exit 1; }
echo "$PINTEST_NEXTPNR_BANNER"
EOF
cat > "$T/stubs/FABulous" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" = "--version" ]]; then echo "$PINTEST_FAB_BANNER"; exit 0; fi
: > "$PINTEST_MARKERS/fabulous-generate"
exit 99
EOF
cat > "$T/stubs/yosys" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" = "-V" ]] || { echo "stub yosys: unexpected argv: $*" >&2; exit 1; }
echo "Yosys 0.0 (stub)"
EOF
cat > "$T/stubs/bit_gen" <<'EOF'
#!/usr/bin/env bash
echo "stub bit_gen: unexpected argv: $*" >&2; exit 1
EOF
chmod +x "$T/bin/"* "$T/stubs/"*

# --- the temp tree -----------------------------------------------------------

TREE="$T/tree"
RESULTS="$TREE/flow/build/verification/results.tsv"
ENVTXT="$TREE/flow/build/verification/env.txt"

mktree() {  # mktree: a fresh repo skeleton under $TREE, stubs installed
    rm -rf "$TREE" "$T/markers"; mkdir -p "$T/markers"
    mkdir -p "$TREE/flow/build/oss-cad-suite/bin" "$TREE/flow/build/fab-venv/bin" \
        "$TREE/verification/common/flow" "$TREE/rtl/common/fabulous"
    cp "$REPO/flow/toolchain.json" "$TREE/flow/"
    cp "$RUN_SRC" "$TREE/verification/run.sh"
    cp "$BLINKY_SRC" "$TREE/verification/blinky.sh"
    cp "$HELPER_SRC" "$TREE/verification/common/flow/toolchain-pins.sh"
    : > "$TREE/rtl/common/fabulous/FABulous.tcl"
    cp "$T/stubs/nextpnr-generic" "$T/stubs/yosys" "$TREE/flow/build/oss-cad-suite/bin/"
    cp "$T/stubs/FABulous" "$T/stubs/bit_gen" "$TREE/flow/build/fab-venv/bin/"
}

markers() { find "$T/markers" -type f -printf '%f '; }  # the stubs run past the gate, if any

run() {  # run <run|blinky> <FABulous banner> <nextpnr banner> [args...]; sets rc, writes $T/out
    rc=0
    PINTEST_FAB_BANNER="$2" PINTEST_NEXTPNR_BANNER="$3" PINTEST_MARKERS="$T/markers" \
        PATH="$T/bin:$PATH" "$TREE/verification/$1.sh" "${@:4}" > "$T/out" 2>&1 || rc=$?
}

# --- the pin gate, through both entry points ---------------------------------

for d in run blinky; do
    if [[ "$d" = run ]]; then next=iverilog-compile; else next=fabulous-generate; fi
    fab_err() {  # the driver's own diagnostic for a rejected FABulous banner $1
        if [[ "$d" = run ]]; then echo "error: FABulous version is not the pinned $FAB_PIN"
        else echo "error: FABulous $1 is not the pinned $FAB_PIN (flow/build/fab-venv holds a stale install"; fi
    }
    pnr_err() {  # ... for a rejected nextpnr banner $1
        if [[ "$d" = run ]]; then echo "error: nextpnr-generic is not the pinned $NEXTPNR_PIN"
        else echo "error: nextpnr-generic $1 is not the pinned $NEXTPNR_PIN (flow/build/oss-cad-suite holds a stale install"; fi
    }
    rejects() {  # rejects <FABulous banner> <nextpnr banner> <the driver's expected error>
        mktree
        run "$d" "$1" "$2"
        [[ "$rc" -eq 1 ]] || { dump; fail "$d.sh: exited $rc on '$1' / '$2' (want 1 at the pin check); output above"; }
        grep -Fq -- "$3" "$T/out" || { dump; fail "$d.sh: no error '$3' on '$1' / '$2'; output above"; }
        [[ -z "$(markers)" ]] || fail "$d.sh: '$1' / '$2' passed the pin gate: $(markers)"
    }

    mktree
    run "$d" "$FAB_OK" "$NEXTPNR_OK"
    [[ -f "$T/markers/$next" ]] || { dump; fail "$d.sh: rejected the pinned banners '$FAB_OK' / '$NEXTPNR_OK'; output above"; }
    rejects "$FAB_RC" "$NEXTPNR_OK" "$(fab_err "$FAB_RC")"
    rejects "$FAB_OK" "$NEXTPNR_DIRTY" "$(pnr_err "$NEXTPNR_DIRTY")"
    rejects "$FAB_OK" "$NEXTPNR_NOFIELD" "$(pnr_err "$NEXTPNR_NOFIELD")"
done

# --- what the bench runner keeps ---------------------------------------------

# env.txt is written before the gate, so it records the banners actually
# checked, a rejected one too; blinky.sh writes its report only at the end of
# a full run, so for the demo the checked banner is read back from its
# diagnostics above.
mktree; run run "$FAB_OK" "$NEXTPNR_OK"
grep -Fxq -- "nextpnr-generic: $NEXTPNR_OK" "$ENVTXT" || fail "run.sh: env.txt does not record the nextpnr banner it accepted"
grep -Fxq -- "FABulous: $FAB_OK" "$ENVTXT" || fail "run.sh: env.txt does not record the FABulous banner it accepted"
mktree; run run "$FAB_RC" "$NEXTPNR_DIRTY"
grep -Fxq -- "FABulous: $FAB_RC" "$ENVTXT" || fail "run.sh: env.txt does not record the FABulous banner it rejected"
grep -Fxq -- "nextpnr-generic: $NEXTPNR_DIRTY" "$ENVTXT" || fail "run.sh: env.txt does not record the nextpnr banner it rejected"
[[ "$(wc -l < "$RESULTS")" -eq 1 ]] || fail "run.sh: a bench was recorded after a rejected banner"

# --setup is setup only: the gate sits behind its early exit.
mktree; run run "$FAB_RC" "$NEXTPNR_DIRTY" --setup
[[ "$rc" -eq 0 ]] || { dump; fail "run.sh --setup: exited $rc on rejected banners (want 0, the gate must not run); output above"; }
grep -q 'toolchain ready under flow/build/' "$T/out" || { dump; fail "run.sh --setup: never reported the toolchain ready; output above"; }
[[ -z "$(markers)" ]] || fail "run.sh --setup: ran past setup: $(markers)"

# Without a toolchain the gate is skipped: nothing to compare, and the
# generated-fabric benches are listed NOT-RUN instead.
mktree; rm -rf "$TREE/flow/build"
run run "$FAB_RC" "$NEXTPNR_DIRTY"
[[ -f "$T/markers/iverilog-compile" ]] || { dump; fail "run.sh without a toolchain: never reached the benches; output above"; }
grep -q $'^fabulous_generate\tNOT-RUN\t' "$RESULTS" || fail "run.sh without a toolchain: fabulous_generate is not listed NOT-RUN"
if grep -q '^nextpnr-generic:\|^FABulous:' "$ENVTXT"; then fail "run.sh without a toolchain: env.txt records a tool banner"; fi

# --- the helper fails closed -------------------------------------------------
# Sourced from the tree, so it reads the tree's manifest: with a pin deleted
# the reader exits nonzero naming it, and no banner matches a missing pin.
mktree
python3 -I - "$TREE/flow/toolchain.json" <<'EOF'
import json, sys
path = sys.argv[1]; d = json.load(open(path))
del d["nextpnr-generic"]["version"], d["fabulous"]["version"]
json.dump(d, open(path, "w"))
EOF
# shellcheck source=/dev/null
source "$TREE/verification/common/flow/toolchain-pins.sh"
rc=0; pin nextpnr-generic version > "$T/pin.out" 2> "$T/pin.err" || rc=$?
[[ "$rc" -ne 0 ]] || fail "helper: the reader printed a missing pin: '$(cat "$T/pin.out")'"
grep -q 'flow/toolchain.json: no pin nextpnr-generic.version' "$T/pin.err" || fail "helper: the reader did not name the missing pin"
if nextpnr_banner_is_pinned "$NEXTPNR_NOFIELD"; then fail "helper: a banner without a version field matched a missing pin"; fi
if nextpnr_banner_is_pinned "$NEXTPNR_OK"; then fail "helper: a banner matched a missing pin"; fi
if fabulous_banner_is_pinned "FABulous CLI "; then fail "helper: an empty FABulous pin matched"; fi

echo "test-toolchain-pins: PASS (run.sh and blinky.sh: accept, release candidate, dirty nextpnr, no version field; env.txt banners; --setup; no toolchain; missing pin)"
