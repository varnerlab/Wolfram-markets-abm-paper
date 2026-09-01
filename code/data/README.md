# Data provenance and generated outputs

The revised manuscript uses the endogenous-price cellular-automaton market
only. Its principal production artifacts are committed as CSV files so every
reported aggregate and figure can be rebuilt without repeating the threaded
campaigns.

## Principal Model B campaigns

All commands below are run from the repository root.

### Rule quench and dealer-capacity screen

```bash
julia --project=code --gcthreads=1 -t 12 code/model-b/Compute-ModelB-ReservoirQuench.jl --full
julia --project=code code/model-b/Figs-ModelB-ReservoirQuench.jl
julia --project=code code/model-b/Figs-ModelB-MarketPanels.jl
```

- `ModelB-ReservoirQuench-Full-Summary.csv`: one treated row per dealer
  capacity, boundary mode, target fraction, and seed (8,800 rows). The paired
  dormant-control metrics are stored on the same row.
- `ModelB-ReservoirQuench-Full-Grouped.csv`: medians and transition
  probabilities written by the simulation driver.
- `ModelB-ReservoirQuench-Full-Derived.csv`: Wilson intervals, ensemble
  susceptibility, and quantiles used by the final figure.

The market-panel script reruns only nine prespecified trajectories from the
summary table. It produces 20 activation-fraction snapshots and 16 matched
dealer-capacity snapshots. Rows are selected by subgroup-median rules recorded in the
manuscript, not by visual inspection.

The driver runs 9,600 simulations: eight capacities, two boundary modes, 50
seeds, one reused no-switch control, and eleven activated fractions per cell.

### Finite-size rule switch

```bash
julia --project=code --gcthreads=1 -t 12 code/model-b/Compute-ModelB-FiniteSizeQuench.jl --full
```

- `ModelB-FiniteSizeQuench-Full-Summary.csv`: seed-level outcomes.
- `ModelB-FiniteSizeQuench-Full-Grouped.csv`: transition curves and ensemble
  susceptibility.
- `ModelB-FiniteSizeQuench-Full-Scaling.csv`: interpolated finite-horizon
  crossings and susceptibility peaks.

The campaign crosses five lattice sizes, three distinct boundary/capacity
arms, twelve target fractions, and 50 seeds, reusing one no-switch control per
cell (9,750 simulations). The duplicate held-boundary capacity arm is omitted
because the reservoir campaign verifies its exact lattice invariance to $h$.

The finite-size and balance-sheet drivers write one atomic checkpoint per
independent cell. Reissuing a command validates and resumes completed cells,
then reconstructs the same sorted summary table.

### Crossed cash and share interventions

```bash
julia --project=code --gcthreads=1 -t 12 code/model-b/Compute-ModelB-BalanceSheetQuench.jl --full
julia --project=code code/model-b/Figs-ModelB-BalanceSheetQuench.jl
```

- `ModelB-BalanceSheetQuench-Full-Summary.csv`: seed-level outcomes for the
  full cash-factor by share-factor experiment.
- `ModelB-BalanceSheetQuench-Full-Contrasts.csv`: same-seed differences from
  the neutral cash-times-one, shares-times-one arm.
- `ModelB-BalanceSheetQuench-Full-Grouped.csv` and `-Derived.csv`: grouped
  figure inputs.

The campaign crosses four contrarian fractions, three dealer capacities, two
boundary modes, nine balance-sheet interventions, and 50 seeds (10,800
simulations).

Balance-sheet checkpoint cells are keyed by capacity, boundary mode, and seed.

Smoke and pilot files have the corresponding `Smoke` or `Pilot` tag. They are
diagnostics and must not be used for manuscript numbers.

## Reproducibility contracts

- Seeds use Julia's `Xoshiro` generator. Threaded workers write independent
  atomic cells; the final sort makes row order independent of scheduling or
  resumed execution.
- Every treated quench is checked against its dormant arm for exact common
  prehistory.
- Held-boundary balance-sheet arms are checked for bit-identical lattice
  trajectories.
- Agent-plus-dealer cash and shares are checked for conservation. In
  balance-sheet campaigns, the check is applied separately before and after
  the intentional intervention jump.
- `h = Inf` reproduces the historical fill-all execution path; `h = 0`
  permits offsetting agent flow only.

## Archival external-price data

`QQQ-OHLC-1-min-aggregate-2024.csv` is retained solely to reproduce the
earlier classroom Model A implementation. No principal result or figure in the
revised manuscript uses it.

The file contains 23,790 regular-session one-minute bars from January 2 through
March 28, 2024. Its SHA-256 digest is
`0d90853ea20b1e022b1c97828ff48fa3f1e295c3937e3a80a35844f7e5a3da0f`.
The original vendor, oneminutedata.com, is offline, so the repository copy is
archival and its license metadata cannot be reconstructed.

## Legacy outputs

Files beginning `ModelA-`, `ModelB-Stage2-`, or `ModelB-Nucleation-` belong to
the superseded fixed-composition and onset-aligned analyses. They remain in
the repository for provenance but do not support the revised paper's main
claims.
