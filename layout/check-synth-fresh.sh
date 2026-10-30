#!/usr/bin/env bash
# Freshness check for the committed synthesized gate-level netlist (T1 item 1,
# issue #37): re-hash the stamped RTL under rtl/common/rtl/ and the committed
# netlist against a record's synthesize.json, with no Yosys run. Exit 0 when the
# netlist still derives from the RTL, 3 when it drifted (RTL edited without
# re-synthesis), anything else is a tool error.
#
# Usage: layout/check-synth-fresh.sh [--skip-deck]
#   --skip-deck  do not resolve the standard-cell liberty (a host with no PDK,
#                e.g. CI); the match then proves RTL, parameters and netlist
#                bytes, not the deck.
# Env: REC=<record dir> (default: the record the manifest cites for item 1).
# KLT=<klt command> (default: klt). The request's sources resolve relative
# to the request, so they are staged next to a copy of it in a scratch dir.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
KLT=${KLT:-klt}
REC=${REC:-$REPO/layout/records/20261027-5171c5d}
TOP=logic_tile_routed
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
for s in $(jq -r '.sources[]' "$HERE/requests/synthesize.json"); do
  cp "$REPO/rtl/common/rtl/$s" "$TMP"/ || exit 2
done
cp "$HERE/requests/synthesize.json" "$TMP"/
$KLT synthesize "$TMP/synthesize.json" --pdk ihp-sg13g2 \
  --check "$REC/synthesize.json" --netlist "$REC/${TOP}_synth.v" "$@" --format json
