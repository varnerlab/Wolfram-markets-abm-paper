# Compute-ModelB.jl
# Runs Model B (closed-loop, endogenous price) simulations and saves results.
#
# Produces:
#   data/ModelB-ClosedLoop.jld2   — single run at default parameters
#   data/ModelB-PhaseSweep.jld2   — crash statistics on (k, f) grid

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Shared setup
# ---------------------------------------------------------------------------
nrows  = 256
ncols  = 256
STEPS  = 1000        # steps per simulation run
P0     = 100.0       # initial price (arbitrary; only ratios matter)
λ      = 0.01        # price impact parameter

# Default edge agent (Bollinger Band)
edge_model = build(MyBandEdgeAgentModel, (
    α               = 1/60,
    k               = 1.0,
    number_of_rows  = nrows,
    number_of_cols  = ncols,
))

price_model = build(MyEndogenousPriceModel, (λ = λ, P0 = P0))

# ---------------------------------------------------------------------------
# 1. Single closed-loop run — Rule 19280/19286, f = 0.20, k = 1.0
# ---------------------------------------------------------------------------
@info "Running Model B — closed loop (default parameters) ..."

modelB = build(MyModelBSimulation, (
    number_of_rows    = nrows,
    number_of_cols    = ncols,
    rule_major_index  = 19280,
    rule_minor_index  = 19286,
    minority_fraction = 0.20,
    edge_agent_model  = edge_model,
    price_model       = price_model,
))

result_B = simulate(modelB; steps = STEPS)

save(joinpath(_PATH_TO_DATA, "ModelB-ClosedLoop.jld2"), Dict(
    "frames"        => result_B.frames,
    "prices"        => result_B.prices,
    "net_imbalance" => result_B.net_imbalance,
    "edge_states"   => result_B.edge_states,
    "parameters"    => Dict("k" => 1.0, "λ" => λ, "f" => 0.20, "P0" => P0),
))
@info "Saved: ModelB-ClosedLoop.jld2"

# ---------------------------------------------------------------------------
# 2. Phase sweep — crash statistics on a (k, f) grid
#    k controls band width; f controls minority fraction
#    Records mean_sell_fraction, max_sell_fraction, crash_frequency per cell
# ---------------------------------------------------------------------------
@info "Running Model B — phase sweep over (k, f) ..."

k_values = [0.5, 1.0, 1.5, 2.0, 2.5]
f_values = [0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30]

sweep = Dict{Tuple{Float64,Float64}, Dict{String,Float64}}()

for k in k_values, f in f_values
    @info "  k = $(k), f = $(f)"

    edge_k = build(MyBandEdgeAgentModel, (
        α               = 1/60,
        k               = k,
        number_of_rows  = nrows,
        number_of_cols  = ncols,
    ))

    model_kf = build(MyModelBSimulation, (
        number_of_rows    = nrows,
        number_of_cols    = ncols,
        rule_major_index  = 19280,
        rule_minor_index  = 19286,
        minority_fraction = f,
        edge_agent_model  = edge_k,
        price_model       = price_model,
    ))

    result_kf  = simulate(model_kf; steps = STEPS, verbose = false)
    N          = nrows * ncols

    sell_fracs = [count(==(2), result_kf.frames[t]) / N
                  for t in sort(collect(keys(result_kf.frames)))]
    log_returns = compute_log_returns(result_kf.prices)

    sweep[(k, f)] = Dict(
        "mean_sell_fraction" => mean(sell_fracs),
        "max_sell_fraction"  => maximum(sell_fracs),
        "crash_frequency"    => mean(sell_fracs .> 0.5),
        "return_std"         => std(log_returns),
        "return_kurtosis"    => kurtosis(log_returns),
    )
end

save(joinpath(_PATH_TO_DATA, "ModelB-PhaseSweep.jld2"), Dict(
    "k_values" => k_values,
    "f_values" => f_values,
    "sweep"    => sweep,
))
@info "Saved: ModelB-PhaseSweep.jld2"
@info "Compute-ModelB.jl complete."
