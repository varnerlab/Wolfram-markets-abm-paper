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

run_julia() {
    local script="$1"
    printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$script" | tee -a "$LOG"
    julia --project=. "$script" 2>&1 | tee -a "$LOG"
}

run_tests() {
    run_julia model-a/Test-EdgeFraction.jl
    run_julia model-b/Test-ModelB.jl
    run_julia model-b/Test-EscapeTime.jl
    run_julia model-b/Test-BoundaryVsBulk.jl
}

run_compute() {
    run_julia model-a/Compute-ModelA.jl
    run_julia model-a/FineSweep.jl
    run_julia model-a/Compute-ModelA-Critical.jl
    run_julia model-a/Compute-SpatialTheory.jl
    run_julia model-a/Compute-NucleationFit.jl

    run_julia model-b/Compute-ModelB-Stage2.jl
    run_julia model-b/Compute-ModelB-NucleationSeeds.jl
    run_julia model-b/Compute-ModelB-Nucleation-EscapeTime.jl
    run_julia model-b/Compute-ModelB-BoundaryVsBulk.jl
    run_julia model-b/Compute-ModelB-BudgetToggle.jl
}

run_figures() {
    run_julia model-a/Fig2-Combined.jl
    run_julia model-a/Fig3-PhaseDiagram.jl
    run_julia model-a/Figs-ModelA-Theory.jl
    run_julia model-b/Figs-ModelB-Exemplars.jl
    run_julia model-b/Figs-ModelB-BarrierLaw.jl
    run_julia model-b/Figs-ModelB-BoundaryVsBulk.jl
    run_julia model-b/Figs-ModelB-VelocitySuppression.jl
}

: > "$LOG"
case "$MODE" in
    tests)
        run_tests
        ;;
    figures)
        run_figures
        ;;
    all)
        run_tests
        run_compute
        run_figures
        ;;
    *)
        echo "Usage: bash code/run_all.sh {tests|figures|all}" >&2
        exit 2
        ;;
esac

printf '\nCompleted mode: %s\n' "$MODE" | tee -a "$LOG"
