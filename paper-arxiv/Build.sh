#!/usr/bin/env bash
# Build the paper and refresh bibliography and cross-references.
# Usage: ./build.sh [jobname]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

JOB="${1:-Paper_v1}"
latexmk -pdf -interaction=nonstopmode -halt-on-error "$JOB.tex"
