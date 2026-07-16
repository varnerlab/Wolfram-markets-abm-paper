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
        "params"           => Dict(String(n) => row[n] for n in
                                   (:run_id, :lambda, :k, :f, :spread,
                                    :disposition, :cash, :seed)),
        "steps"            => STEPS,
    ))
    @info "Exemplar saved" regime run_id = row.run_id
end

@info "Compute-ModelB-Stage2.jl complete."
