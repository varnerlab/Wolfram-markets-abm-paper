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
# The historical drivers copy plots and tables into the root manuscript.
# Once a corrected study is installed, reproduction must use its snapshot.
if [[ "$MODE" == "all" || "$MODE" == "figures" || "$MODE" == "revision" ]]; then
    BUILD_RECORD="$SCRIPT_DIR/../output/rebuilt/manuscript-reserve-v1/Build.json"
    COMPLETION_RECORD="$SCRIPT_DIR/../output/rebuilt/manuscript-reserve-v1/Completion.json"
    if python3 -c 'import json,pathlib,sys; sys.exit(not any(json.loads(p.read_text()).get("installed", False) for name in sys.argv[1:] if (p := pathlib.Path(name)).is_file()))' "$BUILD_RECORD" "$COMPLETION_RECORD"; then
        echo "This historical mode would replace corrected manuscript outputs." >&2
        echo "Use code/rebuild/README.md to reproduce the corrected study from its source snapshot." >&2
        exit 2
    fi
fi
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
    run_julia following/Test-Following.jl
    run_julia following/Test-Following-Analysis.jl
    run_julia following/Test-Following-Controls.jl
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
    repaired-transmission)
        run_julia repaired/Test-Transmission.jl
        run_julia repaired/Compute-Transmission.jl
        run_julia repaired/Analyze-Transmission.jl
        python3 repaired/Verify-Transmission.py
        MPLCONFIGDIR="${TMPDIR:-/tmp}/wolfram-abm-transmission-mpl" \
            XDG_CACHE_HOME="${TMPDIR:-/tmp}/wolfram-abm-font-cache" \
            python3 repaired/Figs-Transmission.py
        ;;
    repaired-tests)
        run_julia repaired/Test-ReserveClearing.jl
        run_julia repaired/Test-Repaired-Following.jl
        ;;
    repaired)
        run_julia repaired/Test-ReserveClearing.jl
        run_julia repaired/Test-Repaired-Following.jl
        run_julia repaired/Compare-RoundTrips.jl
        run_julia repaired/Compute-Survival.jl full
        run_julia repaired/Analyze-Survival.jl full
        run_julia repaired/Compute-Following-Pilot.jl
        run_julia repaired/Analyze-Following-Pilot.jl
        python3 repaired/Verify-Outputs.py
        ;;
    tests)
        run_tests
        ;;
    revision)
        run_revision
        ;;
    figures)
        run_figures
        ;;
    following-tests)
        run_julia following/Test-Following.jl
        run_julia following/Test-Following-Analysis.jl
        run_julia following/Test-Following-Controls.jl
        ;;
    following-smoke|following-pilot|following-confirmation)
        FOLLOWING_STAGE="${MODE#following-}"
        run_julia following/Compute-Following.jl "$FOLLOWING_STAGE"
        run_julia following/Analyze-Following.jl "$FOLLOWING_STAGE"
        run_julia following/Figs-Following.jl "$FOLLOWING_STAGE"
        ;;
    following-figures)
        run_julia following/Figs-Following.jl "${2:-pilot}"
        ;;
    all)
        run_tests
        run_compute
        run_revision
        run_figures
        ;;
    *)
        echo "Usage: bash code/run_all.sh {repaired-transmission|repaired-tests|repaired|tests|revision|figures|all|following-tests|following-smoke|following-pilot|following-confirmation|following-figures}" >&2
        exit 2
        ;;
esac

printf '\nCompleted mode: %s\n' "$MODE" | tee -a "$LOG"
