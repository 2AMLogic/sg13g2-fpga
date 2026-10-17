#!/usr/bin/env bash
# Smoke run of the klt digital flow on IHP SG13G2 (issue #5). Throwaway
# fixture, not the tile. Single local klt runs only; no corner/MC grids.
#
# Usage: flow/smoke/run.sh [--pdk-root DIR]
#   --pdk-root  IHP-Open-PDK install root (default: klt's own resolution).
# Env: KLT=<klt command> (default: klt), RECORD_ID=<id> to override.
#
# Writes one envelope per step to flow/smoke/records/<id>/<step>.json plus
# <step>.rc (the exit code). A step that cannot run is recorded as
# <step>.not-run with the reason; nothing is omitted. Never overwrites an
# existing record directory (records are append-only).
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
KLT=${KLT:-klt}
PDK=ihp-sg13g2
PDK_ARGS=(--pdk "$PDK")
if [[ "${1:-}" == "--pdk-root" ]]; then PDK_ARGS+=(--pdk-root "$2"); fi

# Resolve the SG13G2 root explicitly and export it: a bare `klt pdk find` (what
# the docker openroad wrapper falls back to) can pick another variant, and the
# container then cannot see the Liberty/LEF files.
PDK_ROOT="$($KLT pdk find "${PDK_ARGS[@]}" --format json | jq -r .root)" || exit 2
export PDK_ROOT PDK

ID="${RECORD_ID:-$(date -u +%Y%m%d)-$(git -C "$REPO" rev-parse --short HEAD)}"
REC="$HERE/records/$ID"
B="$REPO/flow/build/smoke"
[[ -e "$REC" ]] && { echo "record $REC exists; records are append-only" >&2; exit 2; }
mkdir -p "$REC"
rm -rf "$B"; mkdir -p "$B"
cp "$HERE"/counter.v "$HERE"/synthesize.json "$HERE"/erc-spec.json "$B"/

# openroad here is a docker wrapper that mounts only $PWD (and the PDK root),
# so run every klt step from the repo root, which contains flow/build/.
cd "$REPO" || exit 2

# Envelope paths are a repo-relative string/object or an absolute string.
rel() { case "$1" in /*) echo "$1";; *) echo "$REPO/$1";; esac; }
pass=0; fail=0
# step <name> <command...>: run, save stdout envelope + rc, never abort.
step() {
  local name=$1; shift
  echo "== $name"
  "$@" >"$REC/$name.json" 2>"$REC/$name.stderr"; local rc=$?
  echo "$rc" >"$REC/$name.rc"
  [[ -s "$REC/$name.stderr" ]] || rm -f "$REC/$name.stderr"
  echo "   exit $rc"; return $rc
}
notrun() { echo "$2" >"$REC/$1.not-run"; echo "== $1: NOT RUN ($2)"; }
field() { jq -r "$2 | if type==\"object\" then .path else . end // empty" "$REC/$1.json" 2>/dev/null; }

# 1. synthesize
step synthesize $KLT synthesize "$B/synthesize.json" "${PDK_ARGS[@]}" --format json
NETLIST=$(field synthesize '.netlist_path')

# 2. place-and-route (with a power grid)
if [[ -n "$NETLIST" ]]; then
  jq --arg n "$(rel "$NETLIST")" '.netlist=$n' "$HERE/place-and-route.json" >"$B/place-and-route.json"
  step place-and-route $KLT place-and-route "$B/place-and-route.json" "${PDK_ARGS[@]}" --format json
else notrun place-and-route "synthesize produced no netlist_path"; fi
GDS=$(field place-and-route '.gds_path'); DEF=$(field place-and-route '.def_path')
VLOG=$(field place-and-route '.verilog_path')

# 3. DRC
if [[ -n "$GDS" ]]; then
  step drc $KLT drc "$(rel "$GDS")" --deck sg13g2 --top counter "${PDK_ARGS[@]}" --format json
else notrun drc "place-and-route produced no gds_path"; fi

# 4. LVS: extract the layout with every std cell abstracted, then compare it
#    against the as-built (post-CTS) gate-level netlist from place-and-route.
if [[ -n "$GDS" && -n "$VLOG" ]]; then
  step extract $KLT extract "$(rel "$GDS")" --deck sg13g2 --top counter \
      --abstract-cells 'sg13g2_*' --def-net-names -o "$B/counter.gate.spice" --format json
  jq --arg l "$B/counter.gate.spice" --arg v "$(rel "$VLOG")" \
     '.layout.netlist=$l | .reference.netlist=$v' "$HERE/lvs.json" >"$B/lvs.json"
  step lvs $KLT lvs "$B/lvs.json" --format json
else notrun lvs "place-and-route produced no gds_path/verilog_path"; fi

# 5. ERC
if [[ -n "$GDS" ]]; then
  step erc $KLT erc "$(rel "$GDS")" "$B/erc-spec.json" --top counter --deck sg13g2 --format json
else notrun erc "place-and-route produced no gds_path"; fi

# 6. STA at one typical-corner Liberty file
if [[ -n "$DEF" ]]; then
  jq --arg d "$(rel "$DEF")" '.def=$d' "$HERE/sta.json" >"$B/sta.json"
  step sta $KLT sta "$B/sta.json" "${PDK_ARGS[@]}" --format json
else notrun sta "place-and-route produced no def_path"; fi

# The STA envelope names the corner deck, not the Liberty path (klayout-tools
# #3785); keep the generated script, whose read_liberty line names the file.
[[ -f "$B/.klt/sta/sta_counter.tcl" ]] && cp "$B/.klt/sta/sta_counter.tcl" "$REC/sta.tcl"

# Consistency checks on the envelopes just written (cheap mode: re-hash inputs).
for c in drc lvs erc; do
  [[ -s "$REC/$c.json" ]] || continue
  $KLT $c --check "$REC/$c.json" >"$REC/$c.check.txt" 2>&1; echo "$?" >"$REC/$c.check.rc"
  echo "== $c --check: exit $(cat "$REC/$c.check.rc")"
done

echo "records: $REC"
