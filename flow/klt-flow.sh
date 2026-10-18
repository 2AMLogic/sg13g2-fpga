#!/usr/bin/env bash
# Shared klt digital-flow runner for IHP SG13G2: synthesize -> place-and-route
# -> DRC -> extract/LVS -> ERC [-> STA], plus the `--check` pass. Not run
# directly; the per-design wrappers (flow/smoke/run.sh, layout/run.sh) set the
# variables below and exec this script with their own arguments.
#
# Required env (set by the wrapper):
#   FLOW_TOP      top module name
#   FLOW_BUILD    build dir name under flow/build/
#   FLOW_REQ_DIR  directory holding synthesize/place-and-route/lvs/erc-spec[/sta].json
#   FLOW_REC_DIR  directory whose records/<id>/ receives the envelopes
#   FLOW_SRC_DIR  directory holding the HDL sources
#   FLOW_SOURCES  space-separated source file names (as listed in synthesize.json)
# Optional env: FLOW_STA=1 to run the STA step (default: off),
#   FLOW_SPEF=1 to extract a parasitics SPEF from the routed GDS first (needs
#   the DEF) and pass it to every STA request as .spef (default: off),
#   FLOW_STA_REQS="sta sta-info" the STA request names under FLOW_REQ_DIR to run
#   (default: sta),
#   KLT=<klt command> (default: klt), RECORD_ID=<id> to override the record id.
#
# Usage (via a wrapper): <wrapper> [--pdk-root DIR]
#   --pdk-root  IHP-Open-PDK install root (default: klt's own resolution).
#
# Writes one envelope per step to <FLOW_REC_DIR>/records/<id>/<step>.json plus
# <step>.rc (the exit code). A step that cannot run is recorded as
# <step>.not-run with the reason; nothing is omitted. Never overwrites an
# existing record directory (records are append-only). Single local klt runs
# only; no corner/MC grids.
set -u

: "${FLOW_TOP:?}" "${FLOW_BUILD:?}" "${FLOW_REQ_DIR:?}" "${FLOW_REC_DIR:?}" "${FLOW_SRC_DIR:?}" "${FLOW_SOURCES:?}"
FLOW_STA=${FLOW_STA:-0}
FLOW_SPEF=${FLOW_SPEF:-0}
FLOW_STA_REQS=${FLOW_STA_REQS:-sta}
TOP=$FLOW_TOP
REQ="$FLOW_REQ_DIR"
REPO="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
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
REC="$FLOW_REC_DIR/records/$ID"
B="$REPO/flow/build/$FLOW_BUILD"
[[ -e "$REC" ]] && { echo "record $REC exists; records are append-only" >&2; exit 2; }
mkdir -p "$REC"
rm -rf "$B"; mkdir -p "$B"
for s in $FLOW_SOURCES; do cp "$FLOW_SRC_DIR/$s" "$B"/; done
cp "$REQ"/synthesize.json "$REQ"/erc-spec.json "$B"/

# openroad here is a docker wrapper that mounts only $PWD (and the PDK root),
# so run every klt step from the repo root, which contains flow/build/.
cd "$REPO" || exit 2

# Envelope paths are a repo-relative string/object or an absolute string.
rel() { case "$1" in /*) echo "$1";; *) echo "$REPO/$1";; esac; }
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
  jq --arg n "$(rel "$NETLIST")" '.netlist=$n' "$REQ/place-and-route.json" >"$B/place-and-route.json"
  step place-and-route $KLT place-and-route "$B/place-and-route.json" "${PDK_ARGS[@]}" --format json
else notrun place-and-route "synthesize produced no netlist_path"; fi
GDS=$(field place-and-route '.gds_path'); DEF=$(field place-and-route '.def_path')
VLOG=$(field place-and-route '.verilog_path')

# 3. DRC
if [[ -n "$GDS" ]]; then
  step drc $KLT drc "$(rel "$GDS")" --deck sg13g2 --top "$TOP" "${PDK_ARGS[@]}" --format json
else notrun drc "place-and-route produced no gds_path"; fi

# 4. LVS: extract the layout with every std cell abstracted, then compare it
#    against the as-built (post-CTS) gate-level netlist from place-and-route.
if [[ -n "$GDS" && -n "$VLOG" ]]; then
  step extract $KLT extract "$(rel "$GDS")" --deck sg13g2 --top "$TOP" \
      --abstract-cells 'sg13g2_*' --def-net-names -o "$B/$TOP.gate.spice" --format json
  jq --arg l "$B/$TOP.gate.spice" --arg v "$(rel "$VLOG")" \
     '.layout.netlist=$l | .reference.netlist=$v' "$REQ/lvs.json" >"$B/lvs.json"
  step lvs $KLT lvs "$B/lvs.json" --format json
else notrun lvs "place-and-route produced no gds_path/verilog_path"; fi

# 5. ERC
if [[ -n "$GDS" ]]; then
  step erc $KLT erc "$(rel "$GDS")" "$B/erc-spec.json" --top "$TOP" --deck sg13g2 --format json
else notrun erc "place-and-route produced no gds_path"; fi

# 6. parasitics (FLOW_SPEF=1 only): SPEF from the routed GDS, net names and pins
#    from the routed DEF so that OpenSTA can correlate the *D_NET blocks with
#    the linked design.
if [[ "$FLOW_SPEF" == 1 ]]; then
  if [[ -n "$GDS" && -n "$DEF" ]]; then
    step extract-parasitics $KLT extract "$(rel "$GDS")" --deck sg13g2 --top "$TOP" \
        --abstract-cells 'sg13g2_*' --def-net-names --parasitics --spef "$B/$TOP.spef" \
        --def-net-connections "$(rel "$DEF")" --def-pins "$(rel "$DEF")" \
        --no-netlist --format json
  else notrun extract-parasitics "place-and-route produced no gds_path/def_path"; fi
fi

# 7. STA (FLOW_STA=1 only): one request per name in FLOW_STA_REQS, each over the
#    routed DEF (and the SPEF when FLOW_SPEF=1). The envelope names the corner
#    deck, not the Liberty path (klayout-tools#3785), so keep the generated
#    script(s), whose read_liberty lines name the file: <req>.tcl/ (all scripts)
#    when FLOW_SPEF=1, else <req>.tcl (the single typical-corner script).
if [[ "$FLOW_STA" == 1 ]]; then
  for req in $FLOW_STA_REQS; do
    if [[ -z "$DEF" ]]; then notrun "$req" "place-and-route produced no def_path"; continue; fi
    if [[ "$FLOW_SPEF" == 1 && ! -s "$B/$TOP.spef" ]]; then
      notrun "$req" "no SPEF from extract-parasitics"; continue
    fi
    jq --arg d "$(rel "$DEF")" --arg s "$B/$TOP.spef" --arg on "$FLOW_SPEF" \
       '.def=$d | if $on=="1" then .spef=$s else . end' \
       "$REQ/$req.json" >"$B/$req.json"
    step "$req" $KLT sta "$B/$req.json" "${PDK_ARGS[@]}" --format json
    if [[ "$FLOW_SPEF" == 1 ]]; then
      mkdir -p "$REC/$req.tcl"; cp "$B"/.klt/sta/*.tcl "$REC/$req.tcl/" 2>/dev/null
    else
      [[ -f "$B/.klt/sta/sta_$TOP.tcl" ]] && cp "$B/.klt/sta/sta_$TOP.tcl" "$REC/$req.tcl"
    fi
    rm -rf "$B/.klt/sta"
  done
fi

# Consistency checks on the envelopes just written (cheap mode: re-hash inputs).
for c in drc lvs erc; do
  [[ -s "$REC/$c.json" ]] || continue
  $KLT $c --check "$REC/$c.json" >"$REC/$c.check.txt" 2>&1; echo "$?" >"$REC/$c.check.rc"
  echo "== $c --check: exit $(cat "$REC/$c.check.rc")"
done

echo "records: $REC"
