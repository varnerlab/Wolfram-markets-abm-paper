# Model B Stage 2 — Ensemble and Factorial Sweep Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run the constrained Model B Stage 2 experiments per `docs/superpowers/specs/2026-07-16-model-b-stage2-design.md`: a 20-seed robustness ensemble with a go/no-go gate, then a 10,800-run factorial sweep with per-run metrics, regime classification, and analysis figures.

**Architecture:** Purely additive — `simulate` and the result struct are untouched. Task 1 adds pure metric/classifier helpers to `Compute.jl` (unit-tested). Task 2 adds the threaded driver script (Phase A + gate + Phase B sweep + exemplar re-runs). Task 3 adds the analysis/visualization script reading only the summary table. Task 4 is the production run + committed outputs.

**Tech Stack:** Julia (project env `code/`), Threads (`julia -t 24`), DataFrames + CSV + JLD2 + StatsBase + Plots (all already in the project env via `code/model-b/Include.jl`).

## Global Constraints

- Tests: `julia code/model-b/Test-ModelB.jl` from repo root (ends with `Test Summary:` lines; nonzero exit on failure).
- Smoke mode: both new scripts must work end-to-end with `STAGE2_SMOKE=1` (tiny grid, seconds) — this is how Tasks 2–3 are verified without burning the production run.
- Production driver launch: `julia -t 24 code/model-b/Compute-ModelB-Stage2.jl` (32-core machine, leave headroom). Fallback on thread trouble: `-t 12`.
- All randomness inside `simulate` (seeded per run). Scripts add NO other randomness.
- Summary-table column names are ASCII: `run_id, lambda, k, f, spread, disposition, cash, seed, <metrics...>, regime`. `disposition` is the `cost_basis_rule` Bool. CSV is the canonical artifact; the JLD2 copy is convenience.
- Threading rules: results into a preallocated vector indexed by run id; no file I/O and no plotting inside the threaded loop; progress via `Threads.Atomic{Int}`.
- Data outputs to `code/data/` (`*.jld2` gitignored, CSVs committed); figures to `code/figs/` only — NOTHING copied to `paper/figs` (do not use `_save_figure`; call `savefig` directly).
- `simulate` is called with `snapshot_steps = Int64[]` and `verbose = false` in sweep loops; exemplar re-runs use default snapshots.
- Cell states: 0 = Buy, 1 = Hold, 2 = Sell. State-like series length steps+1; transition-like length steps.
- Code style: 4-space indent, docstrings on public functions, section-divider comments matching existing files.
- Every commit message ends with:

```
Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ckqHGsozaf7NKx4DVYpU2
```

---

### Task 1: Run metrics and regime classifier (`Compute.jl`)

**Files:**
- Modify: `code/src/Compute.jl` (append to the "Model B trajectory helpers" section, after `compute_crash_statistics`)
- Test: `code/model-b/Test-ModelB.jl` (three new testsets appended at end of file)

**Interfaces:**
- Consumes: `MyModelBSimulationResult` fields (log_returns, prices, sell_fraction, net_imbalance, edge_switches, executed_/suppressed_ buys/sells, total_cash, total_shares); `compute_crash_statistics`; StatsBase `kurtosis`/`autocor` (already loaded via Include.jl).
- Produces (Tasks 2–3 rely on these exact names):
  - `compute_max_drawdown(prices::Vector{Float64})::Float64`
  - `compute_sign_crossings(x::Vector{Float64})::Int64` — zeros never count; sign must actually flip between nonzero values
  - `compute_run_metrics(result::MyModelBSimulationResult)::NamedTuple` — fields exactly: `return_std, return_kurtosis, volclust_ac1, crash_frequency, n_crashes, crash_mean_duration, crash_max_duration, max_drawdown, price_min, price_max, phi_zero_crossings, edge_switches, suppressed_buy_fraction, suppressed_sell_fraction, final_total_cash, final_total_shares`
  - `classify_regime(m::NamedTuple, P0::Float64)::Symbol` — one of `:inert, :crash_prone, :oscillatory, :plateau, :drift`; plus constants `_REGIME_CRASH_FREQ = 0.01`, `_REGIME_OSC_XINGS = 20`, `_REGIME_RANGE_FRAC = 0.10`

- [ ] **Step 1: Write the failing tests.** Append at the end of `code/model-b/Test-ModelB.jl`:

```julia
# ---------------------------------------------------------------------------
# Stage 2 run metrics and regime classification (spec 2026-07-16 stage2)
# ---------------------------------------------------------------------------

@testset "16. drawdown and sign-crossing arithmetic" begin
    @test compute_max_drawdown([100.0, 110.0, 99.0, 121.0, 110.0]) ≈ 0.1
    @test compute_max_drawdown([100.0, 101.0, 102.0]) == 0.0
    @test compute_max_drawdown([100.0]) == 0.0
    # zeros never count; sign must actually flip between nonzero values
    @test compute_sign_crossings([0.1, -0.2, 0.0, -0.1, 0.3]) == 2
    @test compute_sign_crossings([0.0, 0.0]) == 0
    @test compute_sign_crossings([1.0, 1.0, -1.0, 1.0]) == 2
    @test compute_sign_crossings(Float64[]) == 0
end

@testset "17. run metrics on simulated runs" begin
    # degenerate conventions on the all-Hold null control
    null = simulate(_test_config(initial_condition = :all_hold); verbose = false)
    m0 = compute_run_metrics(null)
    @test m0.return_std == 0.0
    @test isnan(m0.return_kurtosis) && isnan(m0.volclust_ac1)
    @test m0.n_crashes == 0 && m0.crash_frequency == 0.0
    @test m0.crash_mean_duration == 0.0 && m0.crash_max_duration == 0
    @test m0.max_drawdown == 0.0
    @test m0.phi_zero_crossings == 0
    @test m0.edge_switches == 0
    @test m0.suppressed_buy_fraction == 0.0 && m0.suppressed_sell_fraction == 0.0
    @test m0.final_total_cash == null.total_cash[1]
    @test m0.final_total_shares == null.total_shares[1]

    # finite fields on a live run
    live = simulate(_test_config(); verbose = false)
    m1 = compute_run_metrics(live)
    @test m1.return_std > 0.0
    @test !isnan(m1.return_kurtosis) && !isnan(m1.volclust_ac1)
    @test m1.price_min ≤ m1.price_max
    @test 0.0 ≤ m1.suppressed_buy_fraction ≤ 1.0
    @test 0.0 ≤ m1.suppressed_sell_fraction ≤ 1.0
    @test m1.edge_switches == live.edge_switches
end

@testset "18. regime classifier decision order" begin
    base = (return_std = 1.0e-3, crash_frequency = 0.0, phi_zero_crossings = 0,
            price_min = 100.0, price_max = 101.0)
    @test classify_regime(merge(base, (return_std = 0.0,)), 100.0) == :inert
    # crash-prone outranks oscillatory even when both criteria hold
    @test classify_regime(merge(base, (crash_frequency = 0.05,
        phi_zero_crossings = 100)), 100.0) == :crash_prone
    @test classify_regime(merge(base, (phi_zero_crossings = 25,)), 100.0) == :oscillatory
    @test classify_regime(base, 100.0) == :plateau            # 1% range < 10%
    @test classify_regime(merge(base, (price_max = 150.0,)), 100.0) == :drift
    # thresholds are inclusive (≥) for crash frequency and crossings
    @test classify_regime(merge(base, (crash_frequency = 0.01,)), 100.0) == :crash_prone
    @test classify_regime(merge(base, (phi_zero_crossings = 20,)), 100.0) == :oscillatory
end
```

- [ ] **Step 2: Run tests, verify the three new testsets fail** with `UndefVarError: compute_max_drawdown not defined` (or similar); everything else passes.

Run: `julia code/model-b/Test-ModelB.jl`

- [ ] **Step 3: Implement.** In `code/src/Compute.jl`, append after `compute_crash_statistics`:

```julia
"""
    compute_max_drawdown(prices) → Float64

Largest peak-to-trough fractional decline: max over t of 1 − P_t / max_{s≤t} P_s.
Zero for a monotone non-decreasing series.
"""
function compute_max_drawdown(prices::Vector{Float64})::Float64
    isempty(prices) && return 0.0
    peak = prices[1]
    dd   = 0.0
    for p in prices
        peak = max(peak, p)
        dd   = max(dd, 1.0 - p / peak)
    end
    return dd
end

"""
    compute_sign_crossings(x) → Int64

Count of sign flips in a series. Zeros are skipped entirely: a crossing is
counted only when a nonzero value has the opposite sign of the previous
nonzero value (spec 2026-07-16 stage2 metrics).
"""
function compute_sign_crossings(x::Vector{Float64})::Int64
    last = 0
    n    = 0
    for v in x
        s = v > 0.0 ? 1 : (v < 0.0 ? -1 : 0)
        s == 0 && continue
        (last != 0 && s != last) && (n += 1)
        last = s
    end
    return n
end

"""
    compute_run_metrics(result) → NamedTuple

Reduce a full Model B run to the Stage 2 scalar summary row (spec 2026-07-16
stage2). Degenerate runs (return_std == 0) report NaN for kurtosis and
volatility clustering; the classifier maps them to :inert.
"""
function compute_run_metrics(result::MyModelBSimulationResult)::NamedTuple
    r  = result.log_returns
    σr = std(r)
    degenerate = (σr == 0.0)
    crash = compute_crash_statistics(result.sell_fraction)
    d     = crash.durations
    supp_b = sum(result.suppressed_buys)
    supp_s = sum(result.suppressed_sells)
    exec_b = sum(result.executed_buys)
    exec_s = sum(result.executed_sells)
    return (
        return_std               = σr,
        return_kurtosis          = degenerate ? NaN : kurtosis(r),
        volclust_ac1             = degenerate ? NaN : autocor(abs.(r), [1])[1],
        crash_frequency          = crash.frequency,
        n_crashes                = crash.n_crashes,
        crash_mean_duration      = isempty(d) ? 0.0 : mean(d),
        crash_max_duration       = isempty(d) ? 0 : maximum(d),
        max_drawdown             = compute_max_drawdown(result.prices),
        price_min                = minimum(result.prices),
        price_max                = maximum(result.prices),
        phi_zero_crossings       = compute_sign_crossings(result.net_imbalance),
        edge_switches            = result.edge_switches,
        suppressed_buy_fraction  = supp_b / max(1, exec_b + supp_b),
        suppressed_sell_fraction = supp_s / max(1, exec_s + supp_s),
        final_total_cash         = result.total_cash[end],
        final_total_shares       = result.total_shares[end],
    )
end

# Regime-classification thresholds (spec 2026-07-16 stage2): classification
# conveniences, not physics claims; revisit after the Phase A ensemble.
const _REGIME_CRASH_FREQ = 0.01   # ≥ 1% of steps in crash → :crash_prone
const _REGIME_OSC_XINGS  = 20     # ≥ this many φ sign flips → :oscillatory
const _REGIME_RANGE_FRAC = 0.10   # price range below this × P0 → :plateau

"""
    classify_regime(m, P0) → Symbol

Map a metrics NamedTuple to a discrete regime, in strict decision order:
:inert (no returns at all) → :crash_prone → :oscillatory → :plateau → :drift.
"""
function classify_regime(m::NamedTuple, P0::Float64)::Symbol
    m.return_std == 0.0                          && return :inert
    m.crash_frequency ≥ _REGIME_CRASH_FREQ       && return :crash_prone
    m.phi_zero_crossings ≥ _REGIME_OSC_XINGS     && return :oscillatory
    (m.price_max - m.price_min) / P0 < _REGIME_RANGE_FRAC && return :plateau
    return :drift
end
```

- [ ] **Step 4: Run tests, verify all pass.**

Run: `julia code/model-b/Test-ModelB.jl`

- [ ] **Step 5: Commit.**

```bash
git add code/src/Compute.jl code/model-b/Test-ModelB.jl
git commit -m "Add Stage 2 run metrics and regime classifier"
```

---

### Task 2: Stage 2 driver (`Compute-ModelB-Stage2.jl`)

**Files:**
- Create: `code/model-b/Compute-ModelB-Stage2.jl`
- Outputs (smoke verification): `code/data/ModelB-Stage2-PhaseA.csv`, `code/data/ModelB-Stage2-Summary.{csv,jld2}`, `code/data/ModelB-Stage2-Exemplar-<regime>.jld2`, `code/figs/ModelB-Stage2-PhaseA-Prices.pdf`

**Interfaces:**
- Consumes: Task 1 helpers exactly as named; `simulate(config; snapshot_steps, verbose)`; `build(MyModelBConfiguration, …)`.
- Produces: the summary CSV with columns exactly `run_id, lambda, k, f, spread, disposition, cash, seed` + the 16 metric fields + `regime` (Task 3 reads these names); exemplar JLD2s whose keys match the Stage 1 diagnostic save dict plus a `"params"` entry.

- [ ] **Step 1: Write the driver.** Create `code/model-b/Compute-ModelB-Stage2.jl`:

```julia
# Compute-ModelB-Stage2.jl — Stage 2 driver (spec 2026-07-16 stage2)
#
# Phase A: 20-seed robustness ensemble at Stage 1 defaults + go/no-go gate.
# Phase B: full factorial sweep (10,800 runs), one summary row per run.
# Exemplars: one full re-run per discovered regime, saved with frames.
#
# Launch: julia -t 24 code/model-b/Compute-ModelB-Stage2.jl
# Smoke:  STAGE2_SMOKE=1 julia code/model-b/Compute-ModelB-Stage2.jl
#
# Threading contract: results land in a preallocated vector indexed by run
# id; all file I/O and plotting happen OUTSIDE the threaded loops.

include(joinpath(@__DIR__, "Include.jl"))

const SMOKE = get(ENV, "STAGE2_SMOKE", "0") == "1"
SMOKE && @warn "STAGE2_SMOKE=1 — tiny grid; outputs are smoke-test artifacts only"

const GRIDN   = SMOKE ? 16 : 64
const STEPS   = SMOKE ? 100 : 2000
const SEEDS_A = SMOKE ? collect(1:3) : collect(1:20)
const SEEDS_B = SMOKE ? collect(1:2) : collect(1:10)
const LAMBDAS = SMOKE ? [0.01, 0.05] : [0.005, 0.01, 0.02, 0.05]
const KS      = SMOKE ? [1.0] : [0.5, 1.0, 2.0]
const FS      = SMOKE ? [0.0, 0.20] : [0.0, 0.10, 0.15, 0.20, 0.30]
const SPREADS = SMOKE ? [0.5] : [0.0, 0.5, 0.9]
const DISPOS  = [true, false]
const CASHES  = SMOKE ? [1000.0] : [500.0, 1000.0, 5000.0]
const P0      = 100.0

"""Build one Stage 2 configuration; all non-swept knobs stay at defaults."""
function _stage2_config(; lambda, k, f, spread, disposition, cash, seed)
    return build(MyModelBConfiguration, (
        number_of_rows   = GRIDN,
        number_of_cols   = GRIDN,
        steps            = STEPS,
        seed             = seed,
        λ                = lambda,
        k                = k,
        minority_fraction = f,
        edge_band_spread = spread,
        cost_basis_rule  = disposition,
        initial_cash     = cash,
        P0               = P0,
    ))
end

"""Run one config and reduce it to a summary NamedTuple (no frames kept)."""
function _run_one(params::NamedTuple)
    config = _stage2_config(; params...)
    res    = simulate(config; snapshot_steps = Int64[], verbose = false)
    m      = compute_run_metrics(res)
    return merge(m, (regime = classify_regime(m, config.P0),)), res
end

# ---------------------------------------------------------------------------
# Phase A — robustness ensemble at defaults, with go/no-go gate
# ---------------------------------------------------------------------------
@info "Phase A: $(length(SEEDS_A))-seed ensemble" grid = GRIDN steps = STEPS threads = Threads.nthreads()

const PHASE_A_DEFAULTS = (lambda = 0.01, k = 1.0, f = 0.20, spread = 0.5,
                          disposition = true, cash = 1000.0)

rows_a   = Vector{Union{Nothing,NamedTuple}}(nothing, length(SEEDS_A))
prices_a = Vector{Vector{Float64}}(undef, length(SEEDS_A))
Threads.@threads :dynamic for i in eachindex(SEEDS_A)
    params = merge(PHASE_A_DEFAULTS, (seed = SEEDS_A[i],))
    row, res = _run_one(params)
    rows_a[i]   = merge((seed = SEEDS_A[i],), row)
    prices_a[i] = res.prices
end
@assert all(!isnothing, rows_a)

dfa = DataFrame()
for r in rows_a
    push!(dfa, r)
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Stage2-PhaseA.csv"), dfa)
@info "Saved: ModelB-Stage2-PhaseA.csv"

pA = plot(legend = false, xlabel = "step", ylabel = "price",
          title = "Phase A: $(length(SEEDS_A)) seeds at defaults")
for p in prices_a
    plot!(pA, 0:STEPS, p, alpha = 0.5, color = :steelblue)
end
savefig(pA, joinpath(_PATH_TO_FIGS, "ModelB-Stage2-PhaseA-Prices.pdf"))
@info "Saved: ModelB-Stage2-PhaseA-Prices.pdf"

# Gate (spec Phase A): CV treats an all-zero column as perfectly stable.
_cv(x) = (μ = mean(x); μ == 0 ? 0.0 : std(x) / μ)
pathology = any((dfa.phi_zero_crossings .== 0) .| (dfa.price_max ./ P0 .≥ 2.0))
inert     = any(dfa.return_std .== 0.0)
unstable  = (_cv(dfa.return_std) ≥ 1.0) || (_cv(dfa.crash_frequency) ≥ 1.0)
gate_ok   = !(pathology || inert || unstable)
@info "Phase A gate" pathology inert unstable gate_ok
if !gate_ok
    if SMOKE
        @warn "Phase A gate would have FAILED — ignored in smoke mode (tiny grid/horizon)"
    else
        @error "Phase A gate FAILED — stopping before the sweep. Inspect ModelB-Stage2-PhaseA.csv."
        exit(1)
    end
end

# ---------------------------------------------------------------------------
# Phase B — factorial sweep (nested in spec table order, seed innermost)
# ---------------------------------------------------------------------------
runs = NamedTuple[]
for lambda in LAMBDAS, k in KS, f in FS, spread in SPREADS,
    disposition in DISPOS, cash in CASHES, seed in SEEDS_B
    push!(runs, (lambda = lambda, k = k, f = f, spread = spread,
                 disposition = disposition, cash = cash, seed = seed))
end
@info "Phase B: factorial sweep" n_runs = length(runs) threads = Threads.nthreads()

results  = Vector{Union{Nothing,NamedTuple}}(nothing, length(runs))
done     = Threads.Atomic{Int}(0)
t_sweep  = @elapsed Threads.@threads :dynamic for i in eachindex(runs)
    row, _ = _run_one(runs[i])
    results[i] = merge((run_id = i,), runs[i], row)
    c = Threads.atomic_add!(done, 1) + 1
    (c % 500 == 0) && @info "sweep progress" completed = c total = length(runs)
end
@assert all(!isnothing, results)
@info "Sweep complete" seconds = round(t_sweep, digits = 1)

df = DataFrame()
for r in results
    push!(df, r)
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Stage2-Summary.csv"), df)
save(joinpath(_PATH_TO_DATA, "ModelB-Stage2-Summary.jld2"), Dict("summary" => df))
@info "Saved: ModelB-Stage2-Summary.csv / .jld2" rows = nrow(df)

# ---------------------------------------------------------------------------
# Exemplars — one full re-run per discovered regime (frames on)
# ---------------------------------------------------------------------------
"""Robust z-ish scale for exemplar distance; degenerate spreads → zeros."""
function _scaled(v::AbstractVector)
    s = length(v) < 2 ? 0.0 : std(v)
    (s == 0 || isnan(s)) && return zeros(length(v))
    return (v .- median(v)) ./ s
end

for regime in sort(unique(df.regime))
    sub  = df[df.regime .== regime, :]
    dist = abs.(_scaled(sub.crash_frequency)) .+ abs.(_scaled(sub.return_std))
    row  = sub[sortperm(collect(zip(dist, sub.run_id)))[1], :]
    config = _stage2_config(lambda = row.lambda, k = row.k, f = row.f,
                            spread = row.spread, disposition = row.disposition,
                            cash = row.cash, seed = row.seed)
    res = simulate(config; verbose = false)
    save(joinpath(_PATH_TO_DATA, "ModelB-Stage2-Exemplar-$(regime).jld2"), Dict(
        "frames"           => res.frames,
        "prices"           => res.prices,
        "log_returns"      => res.log_returns,
        "net_imbalance"    => res.net_imbalance,
        "buy_fraction"     => res.buy_fraction,
        "hold_fraction"    => res.hold_fraction,
        "sell_fraction"    => res.sell_fraction,
        "edge_buy_count"   => res.edge_buy_count,
        "edge_hold_count"  => res.edge_hold_count,
        "edge_sell_count"  => res.edge_sell_count,
        "edge_switches"    => res.edge_switches,
        "ema_price"        => res.ema_price,
        "ema_volatility"   => res.ema_volatility,
        "band_lower"       => res.band_lower,
        "band_upper"       => res.band_upper,
        "executed_buys"    => res.executed_buys,
        "executed_sells"   => res.executed_sells,
        "suppressed_buys"  => res.suppressed_buys,
        "suppressed_sells" => res.suppressed_sells,
        "total_cash"       => res.total_cash,
        "total_shares"     => res.total_shares,
        "edge_coordinates" => res.edge_coordinates,
        "edge_k"           => res.edge_k,
        "books_cash"       => res.final_books.cash,
        "books_shares"     => res.final_books.shares,
        "books_avg_cost"   => res.final_books.avg_cost,
        "config"           => Dict(String(f) => getfield(config, f)
                                   for f in fieldnames(typeof(config))),
        "params"           => Dict(String(n) => row[n] for n in
                                   (:run_id, :lambda, :k, :f, :spread,
                                    :disposition, :cash, :seed)),
        "steps"            => STEPS,
    ))
    @info "Exemplar saved" regime run_id = row.run_id
end

@info "Compute-ModelB-Stage2.jl complete."
```

- [ ] **Step 2: Smoke-verify end-to-end.**

Run: `STAGE2_SMOKE=1 julia code/model-b/Compute-ModelB-Stage2.jl`
Expected: the smoke warning; Phase A saves CSV + PDF and logs its gate booleans (in smoke mode a failed gate only warns — the tiny grid/horizon can trip it spuriously; the binding gate judgment happens on the production run in Task 4); sweep completes 2·1·2·1·2·1·2 = 16 runs; `ModelB-Stage2-Summary.csv` has 16 rows with the exact column set `run_id, lambda, k, f, spread, disposition, cash, seed, <16 metrics>, regime`; at least one exemplar JLD2 exists. Note in your report whether the smoke gate booleans fired.

- [ ] **Step 3: Run the test suite** (unchanged code paths, but confirm no accidental breakage): `julia code/model-b/Test-ModelB.jl` — all pass.

- [ ] **Step 4: Commit** (driver only — smoke CSVs are disposable; delete them before committing; the smoke PDF will be overwritten in Task 4, do not commit it now):

```bash
rm -f code/data/ModelB-Stage2-PhaseA.csv code/data/ModelB-Stage2-Summary.csv
git add code/model-b/Compute-ModelB-Stage2.jl
git commit -m "Add Model B Stage 2 ensemble and factorial sweep driver"
```

---

### Task 3: Analysis and visualization (`Analyze-ModelB-Stage2.jl`)

**Files:**
- Create: `code/model-b/Analyze-ModelB-Stage2.jl`
- Outputs: `code/figs/ModelB-Stage2-Marginals.pdf`, `ModelB-Stage2-PairSheet.pdf`, `ModelB-Stage2-RegimeMap.pdf`, `ModelB-Stage2-Exemplar-<regime>.pdf`; `code/data/ModelB-Stage2-VarianceDecomposition.csv`

**Interfaces:**
- Consumes: `code/data/ModelB-Stage2-Summary.csv` (Task 2 column names; `regime` arrives as String from CSV), exemplar JLD2s (Task 2 key set).
- Produces: figures + variance table only; no code interfaces.

- [ ] **Step 1: Write the analysis script.** Create `code/model-b/Analyze-ModelB-Stage2.jl`:

```julia
# Analyze-ModelB-Stage2.jl — Stage 2 analysis (spec 2026-07-16 stage2)
#
# Reads ONLY the summary table (+ exemplar JLD2s); never re-simulates.
# The 5-D response surface is viewed through three projections:
#   1. marginal effects (metric vs one knob, averaged over everything else)
#   2. pairwise heatmap contact sheet (all 10 knob pairs)
#   3. λ×f regime map faceted by disposition, plus per-regime exemplars
# plus a variance-decomposition table ranking knobs and pairs.

include(joinpath(@__DIR__, "Include.jl"))

df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Stage2-Summary.csv"), DataFrame)
@info "Loaded summary" rows = nrow(df)

const KNOBS            = [:lambda, :k, :f, :spread, :disposition, :cash]
const METRICS_MARGINAL = [:crash_frequency, :return_kurtosis,
                          :phi_zero_crossings, :return_std]
const PAIR_METRIC      = :crash_frequency
const REGIME_ORDER     = ["inert", "plateau", "drift", "oscillatory", "crash_prone"]

_nanmean(v) = (w = filter(!isnan, v); isempty(w) ? NaN : mean(w))
_nanstd(v)  = (w = filter(!isnan, v); length(w) < 2 ? 0.0 : std(w))

# ---------------------------------------------------------------------------
# 1. Marginal effects: metrics × knobs grid, mean ± std over everything else
# ---------------------------------------------------------------------------
function _marginal_panel(df, metric, knob)
    levels = sort(unique(df[!, knob]))
    xs = 1:length(levels)
    ys = [_nanmean(df[df[!, knob] .== l, metric]) for l in levels]
    es = [_nanstd(df[df[!, knob] .== l, metric]) for l in levels]
    plot(xs, ys, yerror = es, marker = :circle, legend = false,
         xticks = (xs, string.(levels)), xlabel = String(knob),
         ylabel = String(metric), guidefont = 7, tickfont = 6)
end

panels = [_marginal_panel(df, m, k) for m in METRICS_MARGINAL for k in KNOBS]
fig1 = plot(panels...; layout = (length(METRICS_MARGINAL), length(KNOBS)),
            size = (1800, 1100), left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
savefig(fig1, joinpath(_PATH_TO_FIGS, "ModelB-Stage2-Marginals.pdf"))
@info "Saved: ModelB-Stage2-Marginals.pdf"

# ---------------------------------------------------------------------------
# 2. Pairwise contact sheet for the headline metric (all 10 knob pairs)
# ---------------------------------------------------------------------------
function _pair_heatmap(df, metric, a, b)
    la = sort(unique(df[!, a]))
    lb = sort(unique(df[!, b]))
    M  = [_nanmean(df[(df[!, a] .== x) .& (df[!, b] .== y), metric])
          for y in lb, x in la]
    heatmap(string.(la), string.(lb), M, xlabel = String(a), ylabel = String(b),
            title = String(metric), titlefont = 8, guidefont = 7, tickfont = 6,
            colorbar = true)
end

pairs = [(KNOBS[i], KNOBS[j]) for i in 1:length(KNOBS) for j in i+1:length(KNOBS)]
sheets = [_pair_heatmap(df, PAIR_METRIC, a, b) for (a, b) in pairs]
fig2 = plot(sheets...; layout = (5, 2), size = (1000, 1800),
            left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
savefig(fig2, joinpath(_PATH_TO_FIGS, "ModelB-Stage2-PairSheet.pdf"))
@info "Saved: ModelB-Stage2-PairSheet.pdf"

# ---------------------------------------------------------------------------
# 3. Regime map: modal regime per (λ, f) cell, faceted by disposition
# ---------------------------------------------------------------------------
function _mode_regime(v)::String
    counts = Dict{String,Int}()
    for r in v
        counts[r] = get(counts, r, 0) + 1
    end
    return sort(collect(counts); by = x -> (-x[2], x[1]))[1][1]
end

regime_code = Dict(r => i for (i, r) in enumerate(REGIME_ORDER))
facets = map([true, false]) do dispo
    d  = df[df.disposition .== dispo, :]
    ls = sort(unique(d.lambda))
    fs = sort(unique(d.f))
    M  = [Float64(regime_code[_mode_regime(
              d[(d.lambda .== l) .& (d.f .== f), :regime])])
          for f in fs, l in ls]
    h = heatmap(string.(ls), string.(fs), M, xlabel = "lambda", ylabel = "f",
                clims = (1, length(REGIME_ORDER)), colorbar = false,
                title = "disposition = $(dispo)", titlefont = 9)
    # categorical axes center cells on integer indices 1..n
    for (yi, f) in enumerate(fs), (xi, l) in enumerate(ls)
        annotate!(h, xi, yi,
                  text(uppercase(first(REGIME_ORDER[Int(M[yi, xi])])), 7, :white))
    end
    h
end
fig3 = plot(facets...; layout = (1, 2), size = (1100, 450),
            plot_title = "Modal regime (" * join(REGIME_ORDER, ", ") * ")")
savefig(fig3, joinpath(_PATH_TO_FIGS, "ModelB-Stage2-RegimeMap.pdf"))
@info "Saved: ModelB-Stage2-RegimeMap.pdf"

# ---------------------------------------------------------------------------
# 4. Variance decomposition: knob and pair fractions per metric
# ---------------------------------------------------------------------------
function _variance_rows(df, metric, knobs)
    v0   = df[!, metric]
    keep = .!isnan.(v0)
    d    = df[keep, :]
    v    = d[!, metric]
    μ    = mean(v)
    ss_total = sum((v .- μ) .^ 2)
    ss_total == 0 && return NamedTuple[]
    rows    = NamedTuple[]
    ss_main = Dict{Symbol,Float64}()
    for knob in knobs
        ss = 0.0
        for g in groupby(d, knob)
            ss += nrow(g) * (mean(g[!, metric]) - μ)^2
        end
        ss_main[knob] = ss
        push!(rows, (metric = String(metric), term = String(knob),
                     frac = ss / ss_total))
    end
    for i in 1:length(knobs), j in i+1:length(knobs)
        a, b = knobs[i], knobs[j]
        ss = 0.0
        for g in groupby(d, [a, b])
            ss += nrow(g) * (mean(g[!, metric]) - μ)^2
        end
        push!(rows, (metric = String(metric), term = "$(a)x$(b)",
                     frac = (ss - ss_main[a] - ss_main[b]) / ss_total))
    end
    return rows
end

var_rows = reduce(vcat, [_variance_rows(df, m, KNOBS) for m in METRICS_MARGINAL])
vt = sort(DataFrame(var_rows), [:metric, order(:frac, rev = true)])
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Stage2-VarianceDecomposition.csv"), vt)
for m in METRICS_MARGINAL
    top = first(vt[vt.metric .== String(m), :], 5)
    @info "Variance decomposition (top 5)" metric = m table = top
end
@info "Saved: ModelB-Stage2-VarianceDecomposition.csv"

# ---------------------------------------------------------------------------
# 5. Exemplar six-panel figures (Stage 1 diagnostic layout, from saved dicts)
# ---------------------------------------------------------------------------
for file in filter(f -> startswith(f, "ModelB-Stage2-Exemplar-") &&
                        endswith(f, ".jld2"), readdir(_PATH_TO_DATA))
    d      = load(joinpath(_PATH_TO_DATA, file))
    regime = replace(replace(file, "ModelB-Stage2-Exemplar-" => ""), ".jld2" => "")
    T      = d["steps"]
    n_edge = length(d["edge_coordinates"])

    p1 = plot(0:T, d["band_lower"], fillrange = d["band_upper"],
              fillalpha = 0.15, lw = 0, color = :gray, label = "EMA ± kσ (nominal)")
    plot!(p1, 0:T, d["ema_price"], color = :gray, ls = :dash, label = "EMA")
    plot!(p1, 0:T, d["prices"], color = :black, lw = 1.0, label = "price")
    plot!(p1, xlabel = "step", ylabel = "price", title = "Price — $(regime)")

    p2 = plot(1:T, d["net_imbalance"], color = _BUY_COLOR, legend = false,
              xlabel = "step", ylabel = "φ (executed)", title = "Executed imbalance")
    hline!(p2, [0.0], color = :gray, ls = :dot)

    p3 = plot(1:T, d["edge_buy_count"] ./ n_edge, color = _BUY_COLOR, label = "Buy",
              xlabel = "step", ylabel = "fraction", title = "Edge populations")
    plot!(p3, 1:T, d["edge_hold_count"] ./ n_edge, color = "#888888", label = "Hold")
    plot!(p3, 1:T, d["edge_sell_count"] ./ n_edge, color = _SELL_COLOR, label = "Sell")

    p4 = plot(0:T, d["buy_fraction"], color = _BUY_COLOR, label = "Buy",
              xlabel = "step", ylabel = "fraction", title = "Interior populations")
    plot!(p4, 0:T, d["hold_fraction"], color = "#888888", label = "Hold")
    plot!(p4, 0:T, d["sell_fraction"], color = _SELL_COLOR, label = "Sell")

    desired  = d["executed_buys"] .+ d["executed_sells"] .+
               d["suppressed_buys"] .+ d["suppressed_sells"]
    executed = d["executed_buys"] .+ d["executed_sells"]
    p5 = plot(1:T, desired, color = :gray, label = "desired",
              xlabel = "step", ylabel = "orders", title = "Order volume")
    plot!(p5, 1:T, executed, color = :black, label = "executed")

    p6 = plot(1:T, d["suppressed_buys"], color = _BUY_COLOR, label = "suppressed buys",
              xlabel = "step", ylabel = "count", title = "Suppressed orders")
    plot!(p6, 1:T, d["suppressed_sells"], color = _SELL_COLOR, label = "suppressed sells")

    fig = plot(p1, p2, p3, p4, p5, p6, layout = (3, 2), size = (1000, 1050),
               left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
    savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Stage2-Exemplar-$(regime).pdf"))
    @info "Saved: ModelB-Stage2-Exemplar-$(regime).pdf" params = d["params"]
end

@info "Analyze-ModelB-Stage2.jl complete."
```

- [ ] **Step 2: Smoke-verify.** Regenerate smoke data, then analyze it:

Run: `STAGE2_SMOKE=1 julia code/model-b/Compute-ModelB-Stage2.jl && julia code/model-b/Analyze-ModelB-Stage2.jl`
Expected: all five outputs saved without error on the 16-row table (single-level knobs produce 1-column heatmaps — degenerate but must not crash); variance CSV exists; one exemplar PDF per smoke regime.

- [ ] **Step 3: Clean smoke artifacts and commit** (script only):

```bash
rm -f code/data/ModelB-Stage2-PhaseA.csv code/data/ModelB-Stage2-Summary.csv \
      code/data/ModelB-Stage2-VarianceDecomposition.csv
git add code/model-b/Analyze-ModelB-Stage2.jl
git commit -m "Add Model B Stage 2 analysis and visualization script"
```

(Smoke PDFs in `code/figs/` will be overwritten by the production run in Task 4; leave them untracked until then.)

---

### Task 4: Production run and committed outputs

**Files:**
- Outputs committed: `code/data/ModelB-Stage2-PhaseA.csv`, `code/data/ModelB-Stage2-Summary.csv`, `code/data/ModelB-Stage2-VarianceDecomposition.csv`, and all `code/figs/ModelB-Stage2-*.pdf`
- Not committed: `code/data/*.jld2` (gitignored)

**Interfaces:**
- Consumes: Tasks 2–3 scripts.
- Produces: the Stage 2 dataset and draft figures; the run report is the deliverable for the paper's next step.

- [ ] **Step 1: Production sweep.**

Run: `julia -t 24 code/model-b/Compute-ModelB-Stage2.jl` (NO smoke variable)
Expected: Phase A logs 20 seeds, gate booleans, `gate_ok = true` (if the gate FAILS, STOP — commit nothing, report the Phase A table and the failing flag; that is a valid Stage 2 outcome per spec); sweep logs progress every 500 runs and completes 10,800 runs; wall-clock target < 30 min at `-t 24` (record the logged `seconds`); one exemplar per discovered regime. Capture the full console output for the report.

- [ ] **Step 2: Analysis.**

Run: `julia code/model-b/Analyze-ModelB-Stage2.jl`
Expected: all figures + variance CSV regenerate from the production table.

- [ ] **Step 3: Inspect and interpret (deliverable, not formality).** Read the PDFs; report: Is the Phase A ensemble tight (overlay figure)? Which regimes exist and where (regime map)? Which knobs dominate which metrics (variance table — and does seed variance dominate? If seeds ≫ knobs for every metric, say so prominently: the phase structure is noise per spec)? Do the λ×f maps connect to Model A's f_c ≈ 0.15? Summary row count == 10,800, no unexplained NaN (kurtosis/volclust NaN allowed only where `return_std == 0`).

- [ ] **Step 4: Test suite still green.**

Run: `julia code/model-b/Test-ModelB.jl`

- [ ] **Step 5: Commit data + figures.**

```bash
git add code/data/ModelB-Stage2-PhaseA.csv code/data/ModelB-Stage2-Summary.csv \
        code/data/ModelB-Stage2-VarianceDecomposition.csv code/figs/ModelB-Stage2-*.pdf
git commit -m "Run Model B Stage 2: Phase A ensemble and 10,800-run factorial sweep"
```

---

## Spec coverage map (self-review)

| Spec section | Task |
|---|---|
| Decisions 1–6 | gate: Task 2 Phase A; factorial: Task 2 Phase B; viz projections: Task 3; one-row-per-run + re-run exemplars: Tasks 2–3; threading: Task 2 (+ launch cmd in Task 4); no simulate changes: all tasks additive |
| Phase A config/gate | Task 2 (exact booleans; CV zero-mean convention documented in code) |
| Phase B grid | Task 2 constants (levels verbatim; enumeration order = spec table order, seed innermost) |
| Metrics | Task 1 `compute_run_metrics` (all 16 fields, exact names) |
| Regime classifier | Task 1 (3 constants + decision order; inclusive ≥ thresholds tested) |
| Code structure table | Tasks 1–3 files match spec table; figure filenames match spec list |
| Success criteria / failure modes | Task 4 Step 3 (row count, NaN audit, seed-variance honesty check, runtime sanity) |
| Out of scope | no simulate/result changes anywhere; STALE scripts untouched |
