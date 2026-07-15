# Model B Rebuild — Design Spec

**Date:** 2026-07-15
**Source plan:** `model-B-plan.md` (repo root)
**Scope:** First implementation pass + Stage 1 diagnostic (32×32, 200 steps).
Stages 2 (64×64 ensemble) and 3 (256×256 production sweep) are explicitly
deferred to follow-up sessions.

## Goal

Rebuild the Model B (closed-loop, endogenous price) simulation from a clean,
tested baseline. The current implementation is an inert prototype: all-Hold
initialization produces zero imbalance, a constant price, and permanently-Hold
edge agents; the closed-loop timing is ambiguous; and crash statistics are
computed from ~8 grid snapshots instead of the full trajectory. Model A, the
CA machinery, and the paper structure are preserved untouched.

## Approach (chosen)

Add new Model B-specific types and helpers into the existing src file
organization (`Types.jl`, `Factory.jl`, `Compute.jl`, `Simulate.jl`), and
rewrite the existing `simulate(::MyModelBSimulation)`-era loop in place as a
new `simulate(::MyModelBConfiguration)` entry point. Alternatives considered
and rejected: a minimal in-place patch (cannot hold full trajectories without
breaking Model A's `MySimulationResult`; leaves configuration scattered) and a
self-contained `src/ModelB.jl` (maximum isolation but breaks the repo's
file-per-function organization).

## 1. Update order (core fix, `code/src/Simulate.jl`)

Step `t` (for `t = 1..steps`) transforms `X_{t-1} → X_t` in exactly this
order:

```
φ_{t-1} = interior imbalance of X_{t-1}      # strictly interior cells
P_t     = P_{t-1} · exp(λ · φ_{t-1})         # log_return[t] = λ·φ_{t-1} exactly
μ_t     = μ_{t-1} + α·(P_t − μ_{t-1})        # EMA sees the NEW price
σ_t     = σ_{t-1} + α·(|P_t − μ_t| − σ_{t-1})
e_t     = BandState(P_t, μ_t, σ_t, k)        # written into active edge cells
X_t     = CA step on interior of X_{t-1}     # interior neighbors of edges see e_t
```

**Indexing convention.** State-like series have length `steps+1` with index 1
holding the initial condition (time t=0): `prices`, `ema_price`,
`ema_volatility`, `band_lower`, `band_upper`, `buy_fraction`, `hold_fraction`,
`sell_fraction`. Transition-like series have length `steps` with index t
holding the step t value: `log_returns`, `net_imbalance` (φ_{t-1}, the value
that generated P_t), `edge_states` (e_t). Initial EMA state: `μ₀ = P₀`,
`σ₀ = 0` (so the t=0 band has zero width and the first out-of-band price
triggers an edge response).

**Deliberate change from current code:** the imbalance denominator is
`N_interior = (nrows−2)·(ncols−2)` — strictly interior cells, whole boundary
excluded (both active edge cells and passive boundary cells). The current
`compute_net_imbalance` excludes only active edge cells, letting the ~75%
passive boundary cells dilute φ; at 32×32 the boundary is 12% of the grid, so
this matters for the Stage 1 diagnostic. This matches the plan's definition
`φ = (N_buy − N_sell) / N_interior`.

## 2. New types

### `MyModelBConfiguration` (in `Types.jl`, built in `Factory.jl`)

Single source of truth for a run, per plan §5:

| Field | Meaning | Diagnostic default |
|---|---|---|
| `number_of_rows`, `number_of_cols` | grid size | 32, 32 |
| `steps` | simulation length | 200 |
| `seed` | RNG seed for the whole run | 42 |
| `initial_condition` | `:all_hold` \| `:balanced_perturbation` \| `:custom` | `:balanced_perturbation` |
| `initial_buy_fraction` | Buy seed fraction (interior) | 0.05 |
| `initial_sell_fraction` | Sell seed fraction (interior) | 0.05 |
| `edge_fraction` | fraction of boundary cells that are active | 0.25 |
| `α` | EMA learning rate | 1/60 |
| `k` | band half-width (units of σ) | 1.0 |
| `λ` | price impact | 0.01 |
| `P0` | initial price | 100.0 |
| `minority_fraction` | fraction of agents on `rule_minor` | 0.20 |
| `rule_major_index` | majority rule | 19280 |
| `rule_minor_index` | contrarian rule | 19286 |

Builder validation: all fractions in [0,1]; `initial_buy_fraction +
initial_sell_fraction ≤ 1`; `steps > 0`; `:custom` requires a caller-supplied
`initial_grid` whose size matches and whose entries are in {0,1,2}. Unicode
field names (`α`, `k`, `λ`) are retained per repo convention.

Entry point: `simulate(config::MyModelBConfiguration; initial_grid = nothing,
snapshot_steps = nothing, verbose = true) → MyModelBSimulationResult`.

### `MyModelBSimulationResult` (in `Types.jl`)

Immutable container, per plan §4:

- `frames::Dict{Int64, Array{Int64,2}}` — sparse snapshots; always includes
  t=0 and t=steps in addition to the (default ~8, log-spaced) snapshot steps
- the eleven trajectory series from §1 above
- `edge_coordinates::Vector{Tuple{Int64,Int64}}` — sorted active edge cells,
  stored so every run is reproducible from the result alone
- `config::MyModelBConfiguration` — echoed back

`MySimulationResult` (Model A) is untouched.

## 3. Seeding and helpers

One `Xoshiro(config.seed)` RNG drives every random choice, consumed in a
fixed, documented order:

1. edge-cell sampling (`build_edge_coordinates`)
2. initial-grid perturbation (`build_initial_grid`)
3. minority rule assignment (`_build_ca_components`)

New helpers:

- `build_edge_coordinates(nrows, ncols, edge_fraction, rng)` — enumerates the
  actual boundary cells in deterministic order, samples
  `round(Int, edge_fraction · n_boundary)` of them without replacement.
  Non-sampled boundary cells are passive and remain Hold (the CA solvers
  already never write boundary cells).
- `build_initial_grid(config, rng; custom_grid = nothing)` — `:all_hold` →
  `fill(1, …)`;
  `:balanced_perturbation` → all-Hold, then place exactly
  `round(Int, initial_buy_fraction · N_interior)` Buy cells and exactly the
  same-formula Sell count on distinct interior positions sampled without
  replacement (equal counts when the two fractions are equal, so the initial
  global imbalance is zero); `:custom` → validated pass-through of
  `custom_grid`, which `simulate` forwards from its `initial_grid` keyword.
- `compute_interior_imbalance(grid)` — φ over strictly interior cells.
- `compute_interior_fractions(grid)` — (buy, hold, sell) fractions over
  strictly interior cells.
- `compute_crash_statistics(sell_fraction; threshold = 0.5)` — crash
  frequency (fraction of steps above threshold), number of crash episodes,
  and episode durations, computed from the full per-step trajectory. Replaces
  snapshot-based crash statistics for all future Model B analysis.

`_build_ca_components` gains an optional `rng` keyword defaulting to the
global RNG, so Model A call sites are bit-for-bit unchanged while Model B
threads its seeded RNG through minority placement.

## 4. Tests (`code/model-b/Test-ModelB.jl`)

Script-style using the `Test` stdlib (`@testset` per property), matching the
repo's script convention (`code/` is not a package, so `Pkg.test()` does not
apply). Run via `julia code/model-b/Test-ModelB.jl`. One testset per plan §6
property, on small deterministic grids:

1. **Positive imbalance raises price** — buy-dominated interior, one step,
   `prices[2] > prices[1]`.
2. **Negative imbalance lowers price** — sell-dominated interior, mirrored.
3. **Edge cells respond to the new price** — all-Buy interior with large λ:
   `P₁` jumps above the band while `P₀` sits inside it, so
   `edge_states[1] == 2` (Sell) only under the correct ordering.
4. **Edge cells excluded from price formation** — active edges forced
   non-Hold, interior all-Hold → `net_imbalance[1] == 0`.
5. **Passive boundary stays Hold** — after a full run, every non-active
   boundary cell of the final frame equals 1.
6. **All-Hold null control is stationary** — `:all_hold` run: price constant,
   φ ≡ 0, fractions constant, final frame equals initial frame.
7. **Balanced perturbation activates dynamics** — `:balanced_perturbation`
   run: grid evolves and some `net_imbalance[t] ≠ 0` within the run.
8. **Seed reproducibility** — two runs with the same config give identical
   trajectories, frames, and edge coordinates.
9. **Full-trajectory statistics** — trajectory series have the specified
   lengths, and `compute_crash_statistics` on a hand-built synthetic
   sell-fraction series returns the known frequency/episode counts.

## 5. Stage 1 driver (`code/model-b/Compute-ModelB.jl`, replaced)

The inert default experiment and the snapshot-based 256×256 phase sweep are
deleted. The new driver runs the Stage 1 diagnostic with the config defaults
from §2, then:

- saves `code/data/ModelB-Diagnostic.jld2` (all result fields + config as a
  Dict)
- writes a 4-panel diagnostic figure to `code/figs/` **only** (not
  `paper/figs/` — this is a diagnostic, not a paper figure): price with EMA
  and band envelope; net imbalance; edge state; population fractions
- prints summary numbers: return std, min/max price, edge-state counts, crash
  statistics from the full sell-fraction trajectory

Success criteria for the diagnostic (plan §7 Stage 1: "verify the feedback
loop visually and numerically"): non-constant price, nonzero returns, edge
state changes at least once, and population fractions that evolve — i.e., the
run is demonstrably not inert.

## 6. Out of scope / untouched

- Model A code paths and `MySimulationResult`
- The paper (`paper/`)
- `Fig4-ClosedLoop.jl`, `Fig5-PhaseDiagram.jl` — they read old data files and
  will be revisited at Stage 2/3 when there is real data worth plotting
- Stages 2 and 3 experiments (follow-up sessions)

## Error handling

Configuration validation happens in the builder (fail fast with a clear
message). The simulation loop itself is deterministic given the config and
performs no I/O; the driver owns file paths and saving.
