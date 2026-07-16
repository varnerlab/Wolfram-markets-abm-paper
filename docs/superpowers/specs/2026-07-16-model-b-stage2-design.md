# Model B Stage 2 — Ensemble and Factorial Sweep — Design Spec

**Date:** 2026-07-16
**Predecessors:** `2026-07-15-model-b-rebuild-design.md` (Stage 1 rebuild),
`2026-07-16-model-b-budget-constraints-design.md` (budget constraints; merged
to main 2026-07-16).
**Branch:** `model-b-stage2`.
**Scope:** Stage 2 experiments on the constrained Model B — seed-robustness
ensemble plus a full factorial parameter sweep with analysis/visualization.
Stage 3 (256×256 production runs) and final paper-figure polishing are out of
scope; the analysis script produces draft figures.

## Goal

Establish (A) that the constrained Model B baseline is robust to spatial
randomness — not an artifact of one seed — and (B) where in parameter space
the interesting dynamical regimes live (boom-bust, oscillatory, crash-prone,
plateau), producing the summary data, phase diagrams, and exemplar
trajectories the paper's Model B results section needs.

Timing probe (2026-07-16, merged main): one 64×64 × 2,000-step run costs
≈ 0.55 s and already exhibits 11 crash episodes and ~79k edge switches at
default parameters — the sweep starts from a live system. Machine has 32
cores; the sweep is embarrassingly parallel.

## Decisions (agreed 2026-07-16)

1. **Two phases, one gate.** Phase A: 20-seed ensemble at Stage 1 defaults.
   Phase B: full factorial sweep. If Phase A shows the baseline is dominated
   by seed variance (gate below), stop and report before sweeping.
2. **Full factorial, not one-at-a-time.** Compute is not a constraint;
   factorial marginals average over the whole grid (better statistics than
   axis sweeps) and capture interactions. Rejected: axes+2D-grid (weaker
   statistics, misses interactions); baseline+f-only (defers the new knobs).
3. **Visualization strategy** (the 5-D surface is never viewed raw):
   marginal-effect panels (metric vs one knob, mean ± CI over everything
   else), pairwise heatmap contact sheet (all 10 pairs, averaged over the
   rest), a categorical regime map for λ×f faceted by disposition on/off,
   variance decomposition ranking knobs/pairs, and one six-panel exemplar
   trajectory per discovered regime.
4. **One row per run.** Every run reduces to config + seed + scalar metrics
   in a summary DataFrame; all analysis is group-bys over that table. Full
   trajectories are kept only for exemplars, which are RE-RUN post-hoc
   (0.55 s makes re-running cheaper than storing 10,800 trajectories).
5. **Threaded driver.** `Threads.@threads` over the run list; results into a
   preallocated vector indexed by run id (thread-safe); all file I/O and all
   plotting outside the threaded region. Launch with `julia -t 24`
   (leave headroom on the 32-core machine).
6. **No simulation-code changes.** Stage 2 is additive: new driver, new
   analysis script, new pure helpers + tests. `simulate` is consumed as-is
   with `verbose = false` and `snapshot_steps = Int64[]` (t=0 and t=steps
   are always stored regardless; that overhead is acceptable).

## Phase A — robustness ensemble

- Config: Stage 1 defaults at 64×64, `steps = 2000`, seeds 1..20
  (`edge_fraction = 0.25`, α = 1/60, k = 1.0, λ = 0.01, P0 = 100,
  f = 0.20, spread = 0.5, cash = 1000, shares = 10, disposition on).
- Deliverables: ensemble summary table (per-seed metrics + mean/std/CV row),
  and a figure overlaying all 20 price paths.
- **Gate (all must hold to proceed to Phase B):**
  - no seed reproduces the Stage 1 pathology: for every seed, φ crosses zero
    at least once AND `price_max/P0 < 2`;
  - no seed is inert: `return_std > 0` for every seed;
  - headline metrics are seed-stable: coefficient of variation across seeds
    of `return_std` and of `crash_frequency` each < 1.0 (order-of-magnitude
    stability, not tight agreement — crashes are rare events).
  If the gate fails, write the Phase A report and stop; do not sweep.

## Phase B — factorial sweep

Grid (fixed: 64×64, steps = 2000, edge_fraction = 0.25, α = 1/60, P0 = 100,
initial_shares = 10, initial buy/sell fractions 0.05, rules 19280/19286):

| Knob | Levels |
|---|---|
| λ | 0.005, 0.01, 0.02, 0.05 |
| k | 0.5, 1.0, 2.0 |
| minority_fraction f | 0.0, 0.10, 0.15, 0.20, 0.30 |
| edge_band_spread δ | 0.0, 0.5, 0.9 |
| cost_basis_rule | true, false |
| initial_cash | 500, 1000, 5000 |
| seeds | 1..10 |

4·3·5·3·2·3 = 1,080 cells × 10 seeds = **10,800 runs**; ≈ 100 min serial,
≈ 4–8 min at `-t 24`. Runs are enumerated deterministically (nested loops in
the table order above, seed innermost) so run id ↔ config is reproducible.

## Per-run metrics (`compute_run_metrics(result)::NamedTuple`, Compute.jl)

All computable from the existing `MyModelBSimulationResult`:

- `return_std` — std of `log_returns`
- `return_kurtosis` — excess kurtosis of `log_returns` (`NaN` when
  `return_std == 0`; classifier maps that to inert)
- `volclust_ac1` — lag-1 autocorrelation of `abs.(log_returns)` (`NaN` when
  degenerate)
- `crash_frequency`, `n_crashes`, `crash_mean_duration`, `crash_max_duration`
  — from `compute_crash_statistics(sell_fraction)` (threshold 0.5; a run
  with no crashes reports durations 0)
- `max_drawdown` — `maximum(1 .- prices ./ accumulate(max, prices))`
- `price_min`, `price_max`
- `phi_zero_crossings` — count of sign changes in `net_imbalance`
  (zeros do not count as crossings; sign must actually flip)
- `edge_switches` — copied from the result
- `suppressed_buy_fraction` — `sum(suppressed_buys) / max(1, sum(executed_buys)
  + sum(suppressed_buys))`; analogously `suppressed_sell_fraction`
- `final_total_cash`, `final_total_shares`

## Regime classification (`classify_regime(metrics)::Symbol`, Compute.jl)

Explicit named-constant thresholds, defined once and revisable after Phase A
(they are classification conveniences, not physics claims):

```julia
const _REGIME_CRASH_FREQ  = 0.01   # ≥ 1% of steps in crash → :crash_prone
const _REGIME_OSC_XINGS   = 20     # φ sign flips per 2000 steps → two-sided
const _REGIME_RANGE_FRAC  = 0.10   # (price_max−price_min)/P0 below → :plateau
```

Decision order: `return_std == 0 → :inert`; `crash_frequency ≥
_REGIME_CRASH_FREQ → :crash_prone`; `phi_zero_crossings ≥ _REGIME_OSC_XINGS
→ :oscillatory`; price range fraction < _REGIME_RANGE_FRAC → :plateau`;
otherwise `:drift`. (P0 is passed alongside metrics or included in them via
`price_min/max`; the classifier takes the metrics NamedTuple plus `P0`.)

## Code structure (all under `code/model-b/`, helpers in `code/src/`)

| File | Responsibility |
|---|---|
| `code/src/Compute.jl` | add `compute_run_metrics`, `classify_regime` + the three regime constants (pure, unit-tested) |
| `code/model-b/Test-ModelB.jl` | new testsets: metrics on hand-built degenerate/synthetic series (all-Hold null → inert; constructed sell_fraction → crash metrics; drawdown/zero-crossing arithmetic on known vectors); classifier decision order incl. tie precedence |
| `code/model-b/Compute-ModelB-Stage2.jl` | driver: Phase A (ensemble + gate + price-overlay figure), gate check, Phase B threaded sweep, summary table to `code/data/ModelB-Stage2-Summary.jld2` + `.csv`, exemplar selection + re-runs saved to `code/data/ModelB-Stage2-Exemplar-<regime>.jld2` |
| `code/model-b/Analyze-ModelB-Stage2.jl` | reads summary table only: marginal panels, 10-pair contact sheet, λ×f regime map faceted by disposition, variance-decomposition table (printed + CSV), six-panel exemplar figures (reusing the Stage 1 panel layout) |

Figure outputs (all `code/figs/`, none copied to `paper/figs` — drafts):
`ModelB-Stage2-PhaseA-Prices.pdf` (driver), and from the analysis script
`ModelB-Stage2-Marginals.pdf`, `ModelB-Stage2-PairSheet.pdf`,
`ModelB-Stage2-RegimeMap.pdf`, `ModelB-Stage2-Exemplar-<regime>.pdf`.

Driver details:
- run list built as a `Vector{NamedTuple}` up front; `results =
  Vector{Union{Nothing,NamedTuple}}(nothing, n)`; `Threads.@threads :dynamic
  for i in 1:n` fills `results[i]` with metrics + config echo; progress via
  `Threads.Atomic{Int}` counter logged every ~500 runs.
- Each thread's run is fully independent (per-run config, seeded Xoshiro
  inside `simulate`, per-run allocations); nothing shared is mutated.
- DataFrame assembly, JLD2/CSV writes, and exemplar re-runs (with frames)
  happen serially after the loop.
- Exemplar per regime: the run whose (crash_frequency, return_std) is closest
  to that regime's median — deterministic tie-break by lowest run id.
- Analysis is a separate script so plots can be iterated without re-sweeping.

Variance decomposition (analysis script): for each metric, fraction of
variance explained by each knob (grouped means over that knob's levels) and
each pair (grouped means over level pairs, minus main effects) — poor-man's
Sobol indices over the discrete grid; seeds contribute the residual. Report
as a table sorted by explained fraction.

## Success criteria and honest failure modes

- Phase A gate passes and the ensemble table + overlay figure exist.
- Phase B summary table has 10,800 rows, no NaN outside documented degenerate
  cases, and the regime map is non-trivial (≥ 2 regimes occupied).
- The variance decomposition is the honesty check: if seed variance dominates
  every knob for every metric, the phase structure is noise — report that
  conclusion prominently instead of contouring it.
- Runtime sanity: sweep wall-clock at `-t 24` under ~30 min; if it blows past
  (thread contention, GC), fall back to fewer threads and report.

## Out of scope

Stage 3 (256×256), paper-ready figure styling, stylized-facts deep dive
(Table 2 regeneration), and any change to `simulate` or the result struct.
The six STALE-marked pre-rebuild scripts stay untouched; regenerating their
data products is a decision for after Stage 2 results exist.
