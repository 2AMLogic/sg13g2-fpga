#!/usr/bin/env bash
# verification/cold-start.sh -- the one cold-start command for a third party:
# fetch the pinned EDA toolchain (OSS CAD Suite, FABulous venv) into
# flow/build/ -- no host-wide EDA install -- then run every bench. Host
# prerequisites (not fetched): iverilog/vvp at the version pinned in
# flow/toolchain.json (the suite bundles 14.0 (devel), not the pin), python3,
# uv, curl; see verification/README.md § Cold start. Exit status is
# verification/run.sh's: nonzero only if a bench FAILs. Named by
# manifests/inventories/item-9.json (`cold_start`).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
verification/run.sh --setup
verification/run.sh
