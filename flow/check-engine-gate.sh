#!/usr/bin/env bash
# Wrapper checks for flow/klt-flow.sh's engine gate (issue #130 review). Every
# case below must exit 2 before PDK discovery, before any record directory is
# created and before the wrapper's flow/build/<build>/ output (its sentinel
# included) is touched:
#
#   fail-after-json     the probe prints the pinned version, then exits nonzero
#   garbage-after-json  the probe prints the pinned version, then unparsable
#                       text, and exits 0 (the jq read must still fail)
#   empty               the probe prints nothing and exits 0
#   mismatch            the probe reports a different engine
#   corrupt-pin         flow/toolchain.json does not parse (scratch copy of
#                       the tree; the committed pin is never touched)
#
# plus one positive control per wrapper: a valid probe reaches PDK discovery,
# where the stub deliberately fails -- still before any record or build write.
# Both wrappers run against a stub KLT; no PDK, klt, yosys or openroad needed.
#
# Usage: flow/check-engine-gate.sh
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # flow/
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v jq >/dev/null || { echo "jq not on PATH" >&2; exit 1; }

SCRATCH_ID=engine-gate-check
SENTINEL=.engine-gate-sentinel
SENTINEL_TEXT=survive
PASS=0
FAIL=0

# Stub klt standing in for the real tool: version behavior selected by
# KLT_STUB_MODE, every invocation logged to KLT_STUB_LOG.
mkdir -p "$TMP/bin"
STUB="$TMP/bin/klt"
cat >"$STUB" <<'EOF'
#!/usr/bin/env bash
set -u
echo "stub: $*" >>"$KLT_STUB_LOG"
case "${1:-}" in
  version)
    case "${KLT_STUB_MODE:-}" in
      ok) printf '{"klayout_version":"0.30.12"}\n'; exit 0 ;;
      fail-after-json) printf '{"klayout_version":"0.30.12"}\n'; exit 17 ;;
      garbage-after-json) printf '{"klayout_version":"0.30.12"}\nnot json at all\n'; exit 0 ;;
      mismatch) printf '{"klayout_version":"0.30.13"}\n'; exit 0 ;;
      empty) exit 0 ;;
      *) echo "klt stub: unknown KLT_STUB_MODE '${KLT_STUB_MODE:-}'" >&2; exit 9 ;;
    esac ;;
  pdk) # fail hard: the wrapper must stop before any record/build write
    echo 'stub: not json' >&2
    exit 1 ;;
  *) echo "klt stub: unexpected invocation: $*" >&2; exit 9 ;;
esac
EOF
chmod +x "$STUB"
LOG="$TMP/stub.log"

check_rc()       { [[ "$1" -eq "$2" ]]; }
check_absent()   { [[ ! -e "$1" ]]; }
check_sentinel() { [[ -f "$1" && "$(cat "$1")" == "$SENTINEL_TEXT" ]]; }
check_pdk()      { grep -q '^stub: pdk ' "$LOG"; }
check_no_pdk()   { ! grep -q '^stub: pdk ' "$LOG"; }
check_grep()     { grep -qF -- "$2" "$1"; }
check_not_grep() { ! grep -qF -- "$2" "$1"; }

assert() { # <label> <check-function args...>
  local label=$1; shift
  if "$@"; then
    PASS=$((PASS + 1)); echo "ok   $label"
  else
    FAIL=$((FAIL + 1)); echo "FAIL $label"
  fi
}

# one gate case: <wrapper> <flow/build name> <records dir> <mode> <reached pdk
# find: yes|no> <fixed strings that must appear in stderr...>
case_run() {
  local wrapper=$1 build=$2 recs=$3 mode=$4 want_pdk=$5; shift 5
  local rc=0
  : >"$LOG"
  mkdir -p "$REPO/flow/build/$build"
  printf '%s' "$SENTINEL_TEXT" >"$REPO/flow/build/$build/$SENTINEL"
  rm -rf "${recs:?}/$SCRATCH_ID"
  KLT_STUB_MODE=$mode KLT_STUB_LOG="$LOG" KLT="$STUB" RECORD_ID=$SCRATCH_ID \
    "$wrapper" >"$TMP/out" 2>"$TMP/err" || rc=$?
  local label
  label="[$(basename "$wrapper")] $mode"
  assert "$label: exits 2" check_rc "$rc" 2
  if [[ "$want_pdk" == yes ]]; then
    assert "$label: gate passed, reached pdk find" check_pdk
    assert "$label: pdk failure named" check_grep "$TMP/err" "cannot resolve the SG13G2 PDK root"
  else
    assert "$label: stopped before pdk find" check_no_pdk
  fi
  assert "$label: record absent" check_absent "$recs/$SCRATCH_ID"
  assert "$label: sentinel survives" check_sentinel "$REPO/flow/build/$build/$SENTINEL"
  local pat
  for pat in "$@"; do
    assert "$label: stderr names it ($pat)" check_grep "$TMP/err" "$pat"
  done
}

SMOKE="$REPO/flow/smoke/run.sh";   SMOKE_RECS="$REPO/flow/smoke/records"
LAYOUT="$REPO/layout/run.sh";      LAYOUT_RECS="$REPO/layout/records"

case_run_wrapper() { # <wrapper> <build> <recs>
  local wrapper=$1 build=$2 recs=$3
  case_run "$wrapper" "$build" "$recs" ok yes
  case_run "$wrapper" "$build" "$recs" fail-after-json no "probe failed" "exited 17"
  case_run "$wrapper" "$build" "$recs" garbage-after-json no "probe failed" "reported no .klayout_version"
  case_run "$wrapper" "$build" "$recs" empty no "reported no .klayout_version"
  case_run "$wrapper" "$build" "$recs" mismatch no "mismatch: required 0.30.12" "observed 0.30.13" \
    'KLT="uvx' "rerun your original wrapper"
  # finding: the recovery hint must not suggest invoking the shared runner,
  # which dies on the unset wrapper variables ($0 used to expand to it)
  local label
  label="[$(basename "$wrapper")] mismatch"
  : >"$LOG"
  KLT_STUB_MODE=mismatch KLT_STUB_LOG="$LOG" KLT="$STUB" RECORD_ID=$SCRATCH_ID \
    "$wrapper" >/dev/null 2>"$TMP/err" || true
  assert "$label: hint never names the shared runner" check_not_grep "$TMP/err" "klt-flow.sh"
}
case_run_wrapper "$SMOKE" smoke "$SMOKE_RECS"
case_run_wrapper "$LAYOUT" tile "$LAYOUT_RECS"

# Corrupt-pin case: append unparsable text to a scratch copy of the tree (the
# jq read must fail; the wrapper must reject before anything is written). The
# scratch wrapper runs against the scratch REPO (REPO resolves from the script
# location), so only the copy sees the corrupted pin.
pin_case() { # <wrapper path relative to the repo root> <build> <records dir>
  local rel=$1 build=$2 recs=$3
  local tree="$TMP/repo"
  rm -rf "$tree"
  mkdir -p "$tree/flow/smoke" "$tree/layout" "$tree/flow/build/$build"
  cp "$REPO/flow/klt-flow.sh" "$REPO/flow/toolchain.json" "$tree/flow/"
  cp "$REPO/flow/smoke/run.sh" "$tree/flow/smoke/"
  cp "$REPO/layout/run.sh" "$tree/layout/"
  printf 'this line is not json\n' >>"$tree/flow/toolchain.json"
  git -C "$tree" init -q
  printf '%s' "$SENTINEL_TEXT" >"$tree/flow/build/$build/$SENTINEL"
  local rc=0 label
  : >"$LOG"
  (cd "$tree" && KLT_STUB_MODE=ok KLT_STUB_LOG="$LOG" KLT="$STUB" RECORD_ID=$SCRATCH_ID \
    "$tree/$rel") >"$TMP/out" 2>"$TMP/err" || rc=$?
  label="[$rel] corrupt-pin"
  assert "$label: exits 2" check_rc "$rc" 2
  assert "$label: pin read named" check_grep "$TMP/err" "cannot read .klayout.version"
  assert "$label: stopped before pdk find" check_no_pdk
  assert "$label: record absent" check_absent "$recs/$SCRATCH_ID"
  assert "$label: sentinel survives" check_sentinel "$tree/flow/build/$build/$SENTINEL"
}
pin_case flow/smoke/run.sh smoke "$SMOKE_RECS"
pin_case layout/run.sh tile "$LAYOUT_RECS"

# Leave the tree as found (only the check's own scratch traces).
rm -f "$REPO/flow/build/smoke/$SENTINEL" "$REPO/flow/build/tile/$SENTINEL"
rm -rf "${SMOKE_RECS:?}/$SCRATCH_ID" "${LAYOUT_RECS:?}/$SCRATCH_ID"

echo
echo "engine-gate checks: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
