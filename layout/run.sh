#!/usr/bin/env bash
# Synthesize / place-and-route / DRC / LVS / ERC of the stamped tile
# (rtl/common/rtl/logic_tile_routed.v) on IHP SG13G2 (issue #9). Runs the
# shared runner flow/klt-flow.sh.
# Timing (issue #10): klt extract --parasitics -> SPEF, then one klt sta request
# over the routed DEF at the corners in layout/requests/sta*.json (period and
# constraints: layout/timing-period.md). Single local klt runs only.
#
# Usage: layout/run.sh [--pdk-root DIR]
# Env: KLT=<klt command> (default: klt), RECORD_ID=<id> to override.
# Records: layout/records/<id>/ (see flow/klt-flow.sh).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
export FLOW_TOP=logic_tile_routed FLOW_BUILD=tile \
       FLOW_STA=1 FLOW_SPEF=1 FLOW_STA_REQS="sta sta-info" \
       FLOW_SOURCES="lut4_slice.v logic_tile_switch_matrix.v logic_tile_routed.v" \
       FLOW_REQ_DIR="$HERE/requests" FLOW_REC_DIR="$HERE" FLOW_SRC_DIR="$REPO/rtl/common/rtl"
exec "$REPO/flow/klt-flow.sh" "$@"
