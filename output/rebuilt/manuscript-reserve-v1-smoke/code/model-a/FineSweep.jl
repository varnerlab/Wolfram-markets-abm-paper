# FineSweep.jl — Fine-grained phase sweep around the transition (f = 0.08 to 0.22)
# Run from code/ directory: julia --project=. model-a/FineSweep.jl

include(joinpath(@__DIR__, "..", "src", "Include.jl"))

df = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))
prices = compute_typical_price(df)

const NROWS = 128
const NCOLS = 128
const F_EDGE = 0.25

# Build edge coords
boundary = Tuple{Int64,Int64}[]
for c in 1:NCOLS
    push!(boundary, (1, c))
    push!(boundary, (NROWS, c))
end
for r in 2:NROWS-1
    push!(boundary, (r, 1))
    push!(boundary, (r, NCOLS))
end
rng = Random.MersenneTwister(1234)
n_edge = round(Int, F_EDGE * length(boundary))
edge_coords = Set{Tuple{Int64,Int64}}(boundary[randperm(rng, length(boundary))[1:n_edge]])

α = 1/60
k = 1.0
μ_sw = compute_ema(prices; α=α)
σv_sw = compute_ema_volatility(prices, μ_sw; α=α)

function _run_sweep(major_idx, minor_idx, f, edge_coords, nrows, ncols, prices, mu, sigma, k)
    rm_maj = build(MyTwoDimensionalTotalisticWolframRuleModel, (index=major_idx, colors=3, radius=4))
    Q_maj = rm_maj.neighborhoodstatesmap
    D_maj = rm_maj.rule

    Q_min = Q_maj
    D_min = D_maj
    if f > 0.0
        rm_min = build(MyTwoDimensionalTotalisticWolframRuleModel, (index=minor_idx, colors=3, radius=4))
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
    grid = fill(1, nrows, ncols)
    nxt = copy(grid)
    T = length(prices)
    sell_fracs = Vector{Float64}(undef, T)

    for t in 1:T
        es = compute_band_state(prices[t], mu[t], sigma[t], k)
        for (r, c) in edge_coords
            grid[r, c] = es
        end
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

    return (mean_sell = mean(sell_fracs), max_sell = maximum(sell_fracs), crash_freq = mean(sell_fracs .> 0.5))
end

f_values = collect(0.08:0.01:0.22)
sweep_results = Dict{Float64, Dict{String, Float64}}()

println("=== FINE SWEEP f = 0.08 to 0.22 (step 0.01) ===")
println("  f     | mean_sell | max_sell | crash_freq")
println("  ------|-----------|----------|----------")
for f in f_values
    r = _run_sweep(19280, 19286, f, edge_coords, NROWS, NCOLS, prices, μ_sw, σv_sw, k)
    sweep_results[f] = Dict(
        "mean_sell_fraction" => r.mean_sell,
        "max_sell_fraction"  => r.max_sell,
        "crash_frequency"    => r.crash_freq,
    )
    @info "  $(lpad(round(f,digits=2), 4)) | $(lpad(round(r.mean_sell,digits=3), 9)) | $(lpad(round(r.max_sell,digits=3), 8)) | $(lpad(round(r.crash_freq,digits=4), 10))"
end

save(joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep-Fine.jld2"), Dict(
    "f_values"      => f_values,
    "sweep_results" => sweep_results,
))
@info "Saved: ModelA-PhaseSweep-Fine.jld2"
println("\nDone.")
