#!/usr/bin/env bash
# verification/cold-start.sh -- the one cold-start command for a third party:
# fetch the pinned toolchain into flow/build/ (nothing host-wide), then run
# every bench. Exit status is verification/run.sh's: nonzero only if a bench
# FAILs. Named by manifests/inventories/item-9.json (`cold_start`).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
verification/run.sh --setup
verification/run.sh
