#!/usr/bin/env bash
# Reproduce or resume the frozen fresh-market confirmation from any directory.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
export MPLCONFIGDIR="${TMPDIR:-/tmp}/wolfram-confirmation-mpl"
export XDG_CACHE_HOME="${TMPDIR:-/tmp}/wolfram-confirmation-cache"
MARKET_ABM_THREADS="${MARKET_ABM_THREADS:-12}"
MARKET_ABM_GC_THREADS="${MARKET_ABM_GC_THREADS:-1}"
mkdir -p output/repaired

run_julia() {
    julia --project=code --startup-file=no --threads="$MARKET_ABM_THREADS" \
        --gcthreads="$MARKET_ABM_GC_THREADS" "$@"
}

run_python() {
    if [[ "$2" == smoke ]]; then
        python3 code/repaired/Transmission-Confirmation.py "$1" --smoke
    else
        python3 code/repaired/Transmission-Confirmation.py "$1"
    fi
}

python3 code/repaired/Test-Transmission-Confirmation.py 2>&1 | \
    tee output/repaired/transmission-confirmation-v1-analysis-tests.log
run_julia code/repaired/Test-Transmission-Confirmation.jl 2>&1 | \
    tee output/repaired/transmission-confirmation-v1-tests.log

for stage in smoke full; do
    run_python prepare "$stage"
    run_julia code/repaired/Compute-Transmission-Confirmation.jl "$stage" 2>&1 | \
        tee "output/repaired/transmission-confirmation-v1-$stage-run.log"
    run_python analyze "$stage" | \
        tee "output/repaired/transmission-confirmation-v1-$stage-analysis.log"
    run_python verify "$stage"
    run_python figure "$stage"
done
