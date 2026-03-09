# Compute-ModelA.jl
# Runs Model A (open, QQQ-driven) simulations and saves results to data/.
#
# Rules (original course rules — purpose-built for crash dynamics):
#   Homogeneous : Rule 19280 — stable majority/herding rule
#   Crash pair  : Rule 19280 (major, 80%) + Rule 19286 (minor, 20%)
#   Rule 19286 is a contrarian/destabilizer: interprets all-buy as sell signal,
#   triggering local sell cascades that can propagate into flash crashes.
#
# Produces:
#   data/ModelA-Homogeneous.jld2   — Rule 19280, f = 0
#   data/ModelA-Crash.jld2         — Rule 19280 + 19286, f = 0.20
#   data/ModelA-PhaseSweep.jld2    — crash statistics vs minority fraction f

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Shared setup
# ---------------------------------------------------------------------------
df     = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))
prices = compute_typical_price(df)

const NROWS   = 256
const NCOLS   = 256
const F_EDGE  = 0.25   # fraction of boundary cells used as edge agents

# Build boundary edge agent coordinates (25% of boundary, fixed seed)
let
    boundary = Tuple{Int64,Int64}[]
    for c in 1:NCOLS
        push!(boundary, (1, c))
        push!(boundary, (NROWS, c))
    end
    for r in 2:NROWS-1
        push!(boundary, (r, 1))
        push!(boundary, (r, NCOLS))
    end
    rng    = Random.MersenneTwister(1234)
    n_edge = round(Int, F_EDGE * length(boundary))
    global edge_coords = Set{Tuple{Int64,Int64}}(boundary[randperm(rng, length(boundary))[1:n_edge]])
end

@info "Edge agents: $(length(edge_coords)) of $(4*(NROWS+NCOLS-2)) boundary cells ($(round(Int,100*F_EDGE))%)"

edge_model = build(MyBandEdgeAgentModel, (
    α           = 1/60,
    k           = 1.0,
    coordinates = edge_coords,
))

# ---------------------------------------------------------------------------
# 1. Homogeneous — Rule 19280, f = 0
# ---------------------------------------------------------------------------
@info "Running Model A — homogeneous (Rule 19280) ..."

modelA_hom = build(MyModelASimulation, (
    number_of_rows    = NROWS,
    number_of_cols    = NCOLS,
    rule_major_index  = 19280,
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
    number_of_rows    = NROWS,
    number_of_cols    = NCOLS,
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
#    Uses a lean inline loop at 128×128 to track sell_frac at EVERY step.
#    (The simulate() function only stores 8 snapshots, which gives crash_freq=0
#     always — here we compute statistics from the full time series instead.)
# ---------------------------------------------------------------------------
@info "Running Model A — phase sweep over minority fraction f ..."

const NROWS_SWEEP = 128
const NCOLS_SWEEP = 128

# Build edge coords for sweep grid
let
    boundary = Tuple{Int64,Int64}[]
    for c in 1:NCOLS_SWEEP
        push!(boundary, (1, c))
        push!(boundary, (NROWS_SWEEP, c))
    end
    for r in 2:NROWS_SWEEP-1
        push!(boundary, (r, 1))
        push!(boundary, (r, NCOLS_SWEEP))
    end
    rng    = Random.MersenneTwister(1234)
    n_edge = round(Int, F_EDGE * length(boundary))
    global edge_coords_sweep = Set{Tuple{Int64,Int64}}(boundary[randperm(rng, length(boundary))[1:n_edge]])
end

# Pre-compute EMA band signal for the full price series
α_sweep = 1/60
k_sweep = 1.0
μ_sw  = compute_ema(prices; α=α_sweep)
σv_sw = compute_ema_volatility(prices, μ_sw; α=α_sweep)
T_sw  = length(prices)

function _run_sweep(major_idx::Int, minor_idx::Int, f::Float64,
                    edge_coords::Set{Tuple{Int64,Int64}},
                    nrows::Int, ncols::Int,
                    prices::Vector{Float64},
                    mu::Vector{Float64}, sigma::Vector{Float64},
                    k::Float64)
    rm_maj = build(MyTwoDimensionalTotalisticWolframRuleModel,
                   (index=major_idx, colors=3, radius=4))
    Q_maj = rm_maj.neighborhoodstatesmap
    D_maj = rm_maj.rule

    Q_min = Q_maj
    D_min = D_maj
    if f > 0.0
        rm_min = build(MyTwoDimensionalTotalisticWolframRuleModel,
                       (index=minor_idx, colors=3, radius=4))
        Q_min = rm_min.neighborhoodstatesmap
        D_min = rm_min.rule
    end

    N = nrows * ncols
    is_min = falses(nrows, ncols)
    if f > 0.0
        rng = Random.MersenneTwister(5678)
        for pos in randperm(rng, N)[1:round(Int, f * N)]
            is_min[(pos-1)÷ncols+1, (pos-1)%ncols+1] = true
        end
    end

    Random.seed!(1234)
    grid = fill(1, nrows, ncols)   # start all-Hold
    nxt  = copy(grid)

    T = length(prices)
    sell_fracs = Vector{Float64}(undef, T)

    for t in 1:T
        # edge agent state
        es = compute_band_state(prices[t], mu[t], sigma[t], k)
        for (r, c) in edge_coords
            grid[r, c] = es
        end

        # CA update
        copyto!(nxt, grid)
        @inbounds for r in 2:nrows-1, c in 2:ncols-1
            Q = is_min[r,c] ? Q_min : Q_maj
            D = is_min[r,c] ? D_min : D_maj
            μv = 0.25 * (grid[r,c-1] + grid[r,c+1] + grid[r-1,c] + grid[r+1,c])
            nxt[r,c] = D[Q[round(μv; digits=2)]]
        end
        grid, nxt = nxt, grid

        sell_fracs[t] = count(==(2), grid) / N
    end

    return (
        mean_sell_fraction = mean(sell_fracs),
        max_sell_fraction  = maximum(sell_fracs),
        crash_frequency    = mean(sell_fracs .> 0.5),
    )
end

f_values = 0.0:0.05:0.50
sweep_results = Dict{Float64, Dict{String, Float64}}()

for f in f_values
    @info "  f = $(f)"
    r = _run_sweep(19280, 19286, f, edge_coords_sweep,
                   NROWS_SWEEP, NCOLS_SWEEP, prices, μ_sw, σv_sw, k_sweep)
    sweep_results[f] = Dict(
        "mean_sell_fraction" => r.mean_sell_fraction,
        "max_sell_fraction"  => r.max_sell_fraction,
        "crash_frequency"    => r.crash_frequency,
    )
    @info "    mean_sell=$(round(r.mean_sell_fraction,digits=3))  max_sell=$(round(r.max_sell_fraction,digits=3))  crash_freq=$(round(r.crash_frequency,digits=4))"
end

save(joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep.jld2"), Dict(
    "f_values"      => collect(f_values),
    "sweep_results" => sweep_results,
))
@info "Saved: ModelA-PhaseSweep.jld2"
@info "Compute-ModelA.jl complete."
