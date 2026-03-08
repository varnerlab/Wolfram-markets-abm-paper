#!/usr/bin/env bash
set -e
LOG="$(pwd)/run_all.log"
JULIA=julia

run() {
    echo "==== $(date '+%H:%M:%S')  $1 ====" | tee -a "$LOG"
    $JULIA --project=. "$1" >> "$LOG" 2>&1 \
        && echo "     OK" | tee -a "$LOG" \
        || echo "     FAILED (see $LOG)" | tee -a "$LOG"
}

echo "=== Re-running failed scripts at $(date) ===" | tee -a "$LOG"

run model-b/Fig5-PhaseDiagram.jl
run comparison/Fig6-ReturnDistributions.jl
run comparison/Fig7-SOC.jl
run comparison/Fig8-MeanField.jl
run comparison/Table2-StylizedFacts.jl

echo "Done at $(date)" | tee -a "$LOG"
