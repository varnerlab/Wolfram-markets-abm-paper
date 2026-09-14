# Compute-ModelA-Critical.jl
# Runs crash model at the critical fraction f = 0.15 with dense snapshots
# to capture the transition dynamics for Fig2.

include(joinpath(@__DIR__, "Include.jl"))

df     = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))
prices = compute_typical_price(df)

const NROWS  = 256
const NCOLS  = 256
const F_EDGE = 0.25

# Build boundary edge agent coordinates (25% of boundary, fixed seed)
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
edge_coords = Set{Tuple{Int64,Int64}}(boundary[randperm(rng, length(boundary))[1:n_edge]])

edge_model = build(MyBandEdgeAgentModel, (
    α           = 1/60,
    k           = 1.0,
    coordinates = edge_coords,
))

# Dense snapshots: log-spaced but more of them
T = length(prices)
snap_steps = sort(unique(round.(Int, exp.(range(log(1), log(T), length=20)))))

@info "Running Model A — critical (Rule 19280/19286, f = 0.15, $(length(snap_steps)) snapshots) ..."

modelA_crit = build(MyModelASimulation, (
    number_of_rows    = NROWS,
    number_of_cols    = NCOLS,
    rule_major_index  = 19280,
    rule_minor_index  = 19286,
    minority_fraction = 0.15,
    edge_agent_model  = edge_model,
))

result_crit = simulate(modelA_crit, prices; snapshot_steps = snap_steps)

save(joinpath(_PATH_TO_DATA, "ModelA-Critical.jld2"), Dict(
    "frames"        => result_crit.frames,
    "prices"        => result_crit.prices,
    "net_imbalance" => result_crit.net_imbalance,
    "edge_states"   => result_crit.edge_states,
))
@info "Saved: ModelA-Critical.jld2"
@info "Snapshot steps: $(sort(collect(keys(result_crit.frames))))"
