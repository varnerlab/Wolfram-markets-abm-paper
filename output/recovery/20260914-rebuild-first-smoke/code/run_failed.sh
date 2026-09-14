#!/usr/bin/env bash
# Compatibility wrapper retained for older notes.
# The main runner now stops on the first failure, so rerun the desired group.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/run_all.sh" "${1:-tests}"
