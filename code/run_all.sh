#!/usr/bin/env bash
# Reproduce tests, figures, or the full simulation pipeline.
# Usage (from any directory):
#   bash code/run_all.sh tests
#   bash code/run_all.sh figures
#   bash code/run_all.sh all

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-tests}"
LOG="$SCRIPT_DIR/run_all.log"
MARKET_ABM_THREADS="${MARKET_ABM_THREADS:-12}"
MARKET_ABM_GC_THREADS="${MARKET_ABM_GC_THREADS:-1}"

run_julia() {
    local script="$1"
    shift
    printf '\n[%s] %s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$script" "$*" | tee -a "$LOG"
    julia --project=. -t "$MARKET_ABM_THREADS" \
        --gcthreads="$MARKET_ABM_GC_THREADS" "$script" "$@" 2>&1 | tee -a "$LOG"
}

run_tests() {
    run_julia model-a/Test-EdgeFraction.jl
    run_julia model-a/Test-FiniteSizeScaling.jl
    run_julia model-b/Test-ModelB.jl
    run_julia revision/Test-Revision.jl
    run_julia model-b/Test-EscapeTime.jl
    run_julia model-b/Test-BoundaryVsBulk.jl
}

run_compute() {
    run_julia model-b/Compute-ModelB-RuleQuench.jl --full
    run_julia model-b/Compute-ModelB-ReservoirQuench.jl --full
    run_julia model-b/Compute-ModelB-FiniteSizeQuench.jl --full
    run_julia model-b/Compute-ModelB-BalanceSheetQuench.jl --full
}

run_revision() {
    run_julia revision/Test-Revision.jl
    run_julia revision/Compute-Controls.jl
    run_julia revision/Compute-Refinement.jl
    run_julia revision/Compute-Horizons.jl
    python3 revision/Analyze-Revision.py
    python3 revision/Write-Revision-Tables.py
    python3 revision/Check-Revision-Data.py
}

run_figures() {
    run_julia model-b/Compute-ModelB-RuleQuench.jl --full --plot-only
    python3 revision/Analyze-Revision.py
    python3 revision/Write-Revision-Tables.py
    python3 revision/Check-Revision-Data.py
    run_julia model-b/Tables-ModelB-Supplement.jl
    run_julia model-b/Figs-ModelB-ReservoirQuench.jl
    run_julia model-b/Figs-ModelB-MarketPanels.jl
    run_julia model-b/Figs-ModelB-FiniteSizeQuench.jl
    run_julia model-b/Figs-ModelB-BalanceSheetQuench.jl
}

: > "$LOG"
case "$MODE" in
    tests)
        run_tests
        ;;
    revision)
        run_revision
        ;;
    figures)
        run_figures
        ;;
    all)
        run_tests
        run_compute
        run_revision
        run_figures
        ;;
    *)
        echo "Usage: bash code/run_all.sh {tests|revision|figures|all}" >&2
        exit 2
        ;;
esac

printf '\nCompleted mode: %s\n' "$MODE" | tee -a "$LOG"
