# Compute-ModelA.jl
# Runs Model A (open, QQQ-driven) simulations and saves results to data/.
#
# Produces:
#   data/ModelA-Homogeneous.jld2   — Rule 6158, f = 0
#   data/ModelA-Crash.jld2         — Rule 19280 + 19286, f = 0.20
#   data/ModelA-PhaseSweep.jld2    — crash statistics vs minority fraction f

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Shared setup
# ---------------------------------------------------------------------------
df     = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))
prices = compute_typical_price(df)

nrows  = 256
ncols  = 256

edge_model = build(MyBandEdgeAgentModel, (
    α               = 1/60,
    k               = 1.0,
    number_of_rows  = nrows,
    number_of_cols  = ncols,
))

# ---------------------------------------------------------------------------
# 1. Homogeneous — Rule 6158, f = 0
# ---------------------------------------------------------------------------
@info "Running Model A — homogeneous (Rule 6158) ..."

modelA_hom = build(MyModelASimulation, (
    number_of_rows    = nrows,
    number_of_cols    = ncols,
    rule_major_index  = 6158,
    minority_fraction = 0.0,
    edge_agent_model  = edge_model,
))

result_hom = simulate(modelA_hom, prices)

save(joinpath(_PATH_TO_DATA, "ModelA-Homogeneous.jld2"), Dict(
    "frames"        => result_hom.frames,
    "prices"        => result_hom.prices,
    "net_imbalance" => result_hom.net_imbalance,
    "edge_states"   => result_hom.edge_states,
))
@info "Saved: ModelA-Homogeneous.jld2"

# ---------------------------------------------------------------------------
# 2. Crash model — Rule 19280 (major) + 19286 (minor), f = 0.20
# ---------------------------------------------------------------------------
@info "Running Model A — crash (Rule 19280/19286, f = 0.20) ..."

modelA_crash = build(MyModelASimulation, (
    number_of_rows    = nrows,
    number_of_cols    = ncols,
    rule_major_index  = 19280,
    rule_minor_index  = 19286,
    minority_fraction = 0.20,
    edge_agent_model  = edge_model,
))

result_crash = simulate(modelA_crash, prices)

save(joinpath(_PATH_TO_DATA, "ModelA-Crash.jld2"), Dict(
    "frames"        => result_crash.frames,
    "prices"        => result_crash.prices,
    "net_imbalance" => result_crash.net_imbalance,
    "edge_states"   => result_crash.edge_states,
))
@info "Saved: ModelA-Crash.jld2"

# ---------------------------------------------------------------------------
# 3. Phase sweep — crash statistics vs minority fraction f
#    For each f, run Rule 19280/19286 and record:
#      mean_sell_fraction   — average fraction of Sell agents
#      max_sell_fraction    — peak Sell fraction (crash severity proxy)
#      crash_frequency      — fraction of steps where Sell fraction > 0.5
# ---------------------------------------------------------------------------
@info "Running Model A — phase sweep over minority fraction f ..."

f_values = 0.0:0.05:0.50

sweep_results = Dict{Float64, Dict{String, Float64}}()

for f in f_values
    @info "  f = $(f)"
    model_f = build(MyModelASimulation, (
        number_of_rows    = nrows,
        number_of_cols    = ncols,
        rule_major_index  = 19280,
        rule_minor_index  = 19286,
        minority_fraction = f,
        edge_agent_model  = edge_model,
    ))

    result_f = simulate(model_f, prices; verbose = false)
    N        = nrows * ncols

    sell_fracs = [count(==(2), result_f.frames[t]) / N
                  for t in sort(collect(keys(result_f.frames)))]

    sweep_results[f] = Dict(
        "mean_sell_fraction"  => mean(sell_fracs),
        "max_sell_fraction"   => maximum(sell_fracs),
        "crash_frequency"     => mean(sell_fracs .> 0.5),
    )
end

save(joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep.jld2"), Dict(
    "f_values"      => collect(f_values),
    "sweep_results" => sweep_results,
))
@info "Saved: ModelA-PhaseSweep.jld2"
@info "Compute-ModelA.jl complete."
