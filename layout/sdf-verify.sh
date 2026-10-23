#!/usr/bin/env bash
# SDF-annotated gate-level re-simulation of the routed tile (issue #27): runs
# klt functional-verification (cocotb bench verification/gatelevel/test_tile_sdf.py)
# on the post-route netlist kept in a layout record, once per claim corner with
# that corner's post-route SDF, plus a negative control (the slow SDF with every
# IOPATH delay corrupted to 50 ns), which must fail. Single local klt runs only.
#
# Usage: layout/sdf-verify.sh <record-id>      (record made by layout/run.sh with
#        "sdf": true in layout/requests/sta.json)
# Env: KLT=<klt command> (default: klt; needs cocotb and iverilog on PATH).
# Writes <record>/functional-verification-sdf-{slow,fast,negative}.json (+ .rc).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
KLT=${KLT:-klt}
ID=${1:?usage: sdf-verify.sh <record-id>}
REC="$HERE/records/$ID"
B="$REPO/flow/build/sdf-verify"
[[ -s "$REC/logic_tile_routed.routed.v" ]] || { echo "no routed netlist in $REC" >&2; exit 2; }
for r in slow fast negative; do
  [[ -e "$REC/functional-verification-sdf-$r.json" ]] && { echo "report exists; records are append-only" >&2; exit 2; }
done
PDK_ROOT="$($KLT pdk find --pdk ihp-sg13g2 --format json | jq -r .root)" || exit 2
LIB="$PDK_ROOT/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog"
rm -rf "$B"; mkdir -p "$B"
SDF_SLOW="$REC/sta.sdf/logic_tile_routed.slow_1p08V_125C.sdf"
SDF_FAST="$REC/sta.sdf/logic_tile_routed.fast_1p32V_m40C.sdf"
# Negative control: every IOPATH rise/fall triple becomes 50 ns.
sed -E 's/\(IOPATH ([^ ]+) ([^ ]+) \([^)]*\) \([^)]*\)\)/(IOPATH \1 \2 (50:50:50) (50:50:50))/' "$SDF_SLOW" >"$B/corrupt.sdf"
cmp -s "$SDF_SLOW" "$B/corrupt.sdf" && { echo "negative control: sed changed nothing" >&2; exit 2; }

run() { # run <name> <request-template> <sdf>
  jq --arg n "$REC/logic_tile_routed.routed.v" --arg s "$LIB/sg13g2_stdcell.v" \
     --arg u "$LIB/sg13g2_udp.v" --arg b "$REPO/verification/gatelevel" --arg f "$3" \
     '.sources=[$n,$s,$u] | .testbench.search_path=$b | .options.sdf.file=$f' "$2" >"$B/$1.json"
  $KLT functional-verification "$B/$1.json" -o "$B/$1.out" --format json \
     >"$REC/functional-verification-sdf-$1.json" 2>"$B/$1.stderr"
  echo "$?" >"$REC/functional-verification-sdf-$1.rc"
  echo "== $1: exit $(cat "$REC/functional-verification-sdf-$1.rc")"
}
run slow "$HERE/requests/functional-verification-sdf-slow.json" "$SDF_SLOW"
run fast "$HERE/requests/functional-verification-sdf-fast.json" "$SDF_FAST"
run negative "$HERE/requests/functional-verification-sdf-slow.json" "$B/corrupt.sdf"
