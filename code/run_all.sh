#!/usr/bin/env bash
# run_all.sh — run all simulation and figure scripts in dependency order
# Usage: bash run_all.sh  (from the code/ directory)
# Logs go to run_all.log

set -e
LOG="$(pwd)/run_all.log"
JULIA=julia

run() {
    echo "==== $(date '+%H:%M:%S')  $1 ====" | tee -a "$LOG"
    $JULIA --project=. "$1" >> "$LOG" 2>&1 \
        && echo "     OK" | tee -a "$LOG" \
        || echo "     FAILED (see $LOG)" | tee -a "$LOG"
}

echo "Starting run_all.sh at $(date)" | tee "$LOG"

# Stage 1 — compute (expensive; must finish before figures)
run model-a/Compute-ModelA.jl
run model-b/Compute-ModelB.jl

# Stage 2 — figures
run model-a/Fig2-GridSnapshots.jl
run model-a/Fig3-PhaseDiagram.jl
run model-b/Fig4-ClosedLoop.jl
run model-b/Fig5-PhaseDiagram.jl
run comparison/Fig6-ReturnDistributions.jl
run comparison/Fig7-SOC.jl
run comparison/Fig8-MeanField.jl

# Stage 3 — tables (write .tex files into paper/sections/)
run model-a/Table1-RuleTaxonomy.jl
run comparison/Table2-StylizedFacts.jl

echo "Finished at $(date)" | tee -a "$LOG"
