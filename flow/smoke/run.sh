#!/usr/bin/env bash
# Smoke run of the klt digital flow on IHP SG13G2 (issue #5). Throwaway
# fixture, not the tile. Runs the shared runner flow/klt-flow.sh, with STA.
#
# Usage: flow/smoke/run.sh [--pdk-root DIR]
# Env: KLT=<klt command> (default: klt), RECORD_ID=<id> to override.
# Records: flow/smoke/records/<id>/ (see flow/klt-flow.sh).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FLOW_TOP=counter FLOW_BUILD=smoke FLOW_STA=1 FLOW_SOURCES=counter.v \
       FLOW_REQ_DIR="$HERE" FLOW_REC_DIR="$HERE" FLOW_SRC_DIR="$HERE"
exec "$HERE/../klt-flow.sh" "$@"
