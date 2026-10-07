# test_revision_interior_technical.jl -- lazy revision (revision_probability)
# and interior technical traders (interior_technical_fraction) in the
# reserve-clearing simulator. Both options are off by default, and the defaults
# must reproduce archived manuscript runs exactly.
# Run: julia --project=code code/test/runtests.jl

using Test, Random, SHA, Statistics, DataFrames, CSV, ProgressMeter

const _SRC = joinpath(@__DIR__, "..", "src")
include(joinpath(_SRC, "Types.jl"))
include(joinpath(_SRC, "Factory.jl"))
include(joinpath(_SRC, "Wolfram.jl"))
include(joinpath(_SRC, "Compute.jl"))
include(joinpath(_SRC, "Simulate.jl"))

# Configuration used by the archived rebuild drivers (model-b/Compute-*.jl).
function _rebuild_config(; L = 64, steps = 4000, seed = 1, f = 0.2, h = 100.0, kwargs...)
    build(MyModelBConfiguration, (
        number_of_rows = L, number_of_cols = L, steps = steps, seed = seed,
        λ = 0.02, k = 1.0, minority_fraction = f, edge_band_spread = 0.5,
        cost_basis_rule = false, initial_cash = 1000.0, initial_shares = 10,
        P0 = 100.0, market_maker_capacity = h, kwargs...,
    ))
end

_run(config; kwargs...) = simulate(config; clearing = :reserve,
    minority_population = :interior, verbose = false, kwargs...)

_grid_sha(grid) = bytes2hex(sha256(reinterpret(UInt8, vec(grid))))

# Final-grid hashes from output/rebuilt/manuscript-reserve-v1/code/data/
# Rebuild-Execution-Ledger.csv (L = 64, 4,000 steps, Rule 19286).
const ARCHIVED = [
    (seed = 1, f = 0.2,   h = 100.0, boundary = :endogenous, activation = 1001,
     sha = "bb1d81df0dc4869624abfdee0c2a13293e3d72e49507042477b93f69ee33a019"),
    (seed = 2, f = 0.175, h = 0.1,   boundary = :hold,       activation = 1001,
     sha = "c31d3f7866da69a0a80458a5693426c62b9d273d948b39ac721f1603b0e87489"),
    (seed = 3, f = 0.25,  h = 1.0,   boundary = :endogenous, activation = 4001,
     sha = "0f5ff25c02f2494aa0ea9291c232ce2c6e0d7c758e045519e93ab6e52321e1b3"),
    (seed = 4, f = 0.2,   h = 0.0,   boundary = :endogenous, activation = 1001,
     sha = "07a672afcf7a756ffbcd54a09b2f20a9108d2f3e40c702340e6a7b3998b93e88"),
]

@testset "explicit defaults reproduce archived manuscript runs" begin
    for a in ARCHIVED
        config = _rebuild_config(seed = a.seed, f = a.f, h = a.h)
        r = _run(config; rule_activation_step = a.activation, boundary_mode = a.boundary,
                 revision_probability = 1.0, interior_technical_fraction = 0.0)
        @test _grid_sha(r.frames[config.steps]) == a.sha
    end
    # Onset and drawdown of the first case, from ModelB-ReservoirQuench-Full-Summary.csv.
    config = _rebuild_config(seed = 1, f = 0.2, h = 100.0)
    r = _run(config; rule_activation_step = 1001, revision_probability = 1.0,
             interior_technical_fraction = 0.0)
    @test findfirst(≥(0.5), r.sell_fraction[1002:end]) == 776
    @test compute_max_drawdown(r.prices[1001:end]) == 0.2521633751117536
end

@testset "revision draws are uniform and independent of rationing" begin
    u = [_revision_uniform(7, t, id) for t in 1:200, id in 1:500]
    @test all(0 .<= u .< 1)
    @test abs(mean(u .< 0.9) - 0.9) < 0.01
    @test _revision_uniform(7, 3, 11) == _revision_uniform(7, 3, 11)
    @test _revision_uniform(7, 3, 11) != _revision_uniform(8, 3, 11)
end

# With synchronous updating and no self-input, a perturbation at one site can
# reach only sites whose checkerboard color plus time has the same parity.
function _parity_leak(α)
    config = _rebuild_config(L = 16, steps = 120, f = 0.2, h = 100.0,
                             initial_condition = :custom)
    base = fill(1, 16, 16)
    rng = Xoshiro(5)
    for r in 2:15, c in 2:15
        base[r, c] = rand(rng, (0, 1, 1, 2))
    end
    flipped = copy(base)
    flipped[8, 8] = flipped[8, 8] == 2 ? 0 : 2
    snaps = collect(1:120)
    ra = _run(config; initial_grid = base, boundary_mode = :hold, snapshot_steps = snaps,
              revision_probability = α)
    rb = _run(config; initial_grid = flipped, boundary_mode = :hold, snapshot_steps = snaps,
              revision_probability = α)
    leak = 0
    for t in snaps, r in 2:15, c in 2:15
        isodd(r + c + t) == isodd(8 + 8) && continue
        leak += ra.frames[t][r, c] != rb.frames[t][r, c]
    end
    return leak
end

@testset "lazy revision couples the two checkerboard halves" begin
    @test _parity_leak(1.0) == 0
    @test _parity_leak(0.9) > 0
end

@testset "lazy revision keeps the held and paired invariances" begin
    shallow = _run(_rebuild_config(L = 32, steps = 600, seed = 3, f = 0.2, h = 1.0);
                   rule_activation_step = 301, boundary_mode = :hold,
                   revision_probability = 0.8)
    deep = _run(_rebuild_config(L = 32, steps = 600, seed = 3, f = 0.2, h = 100.0);
                rule_activation_step = 301, boundary_mode = :hold,
                revision_probability = 0.8)
    @test shallow.sell_fraction == deep.sell_fraction
    @test shallow.frames[600] == deep.frames[600]
    @test shallow.prices != deep.prices

    config = _rebuild_config(L = 32, steps = 600, seed = 3, f = 0.2, h = 100.0)
    switched = _run(config; rule_activation_step = 301, revision_probability = 0.8)
    control = _run(config; rule_activation_step = 601, revision_probability = 0.8)
    @test switched.sell_fraction[1:301] == control.sell_fraction[1:301]
    @test switched.prices[1:302] == control.prices[1:302]
    @test switched.sell_fraction != control.sell_fraction
end

@testset "zero revision probability freezes intentions" begin
    config = _rebuild_config(L = 16, steps = 50, f = 0.2, h = 100.0)
    r = _run(config; boundary_mode = :hold, rule_activation_step = 11,
             snapshot_steps = collect(1:50), revision_probability = 0.0)
    @test all(r.frames[t] == r.frames[0] for t in 1:50)
end

@testset "interior technical layout" begin
    config = _rebuild_config(L = 32, steps = 10, seed = 6, f = 0.2, h = 100.0)
    plain = market_layout(config; minority_population = :interior)
    with = market_layout(config; minority_population = :interior,
                         interior_technical_fraction = 0.05)
    n = round(Int, 0.05 * 30^2)
    @test isempty(plain.interior_technical)
    @test length(with.interior_technical) == n == length(with.interior_technical_k)
    @test allunique(with.interior_technical)
    @test all(2 <= r <= 31 && 2 <= c <= 31 for (r, c) in with.interior_technical)
    @test isempty(intersect(Set(with.interior_technical), Set(with.minor_sites)))
    # Adding interior technical traders keeps the starting market's other draws;
    # a switch target that lands on a technical cell passes to the next cell.
    @test with.edge_coordinates == plain.edge_coordinates
    @test with.edge_k == plain.edge_k
    @test length(with.minor_sites) == length(plain.minor_sites)
    @test issubset(setdiff(Set(plain.minor_sites), Set(with.interior_technical)),
                   Set(with.minor_sites))
    for r in 2:31, c in 2:31
        (r, c) in with.interior_technical && continue
        @test with.initial_grid[r, c] == plain.initial_grid[r, c]
    end
    @test all(with.initial_grid[r, c] == 1 for (r, c) in with.interior_technical)
    @test with.initial_grid == _run(config; rule_activation_step = 6,
        interior_technical_fraction = 0.05).frames[0]
end

@testset "interior technical layout does not depend on the switched fraction" begin
    low = market_layout(_rebuild_config(L = 32, steps = 10, seed = 6, f = 0.15, h = 1.0);
                        minority_population = :interior, interior_technical_fraction = 0.05)
    high = market_layout(_rebuild_config(L = 32, steps = 10, seed = 6, f = 0.25, h = 1.0);
                         minority_population = :interior, interior_technical_fraction = 0.05)
    @test low.interior_technical == high.interior_technical
    @test low.interior_technical_k == high.interior_technical_k
    @test low.initial_grid == high.initial_grid
    @test issubset(Set(low.minor_sites), Set(high.minor_sites))
end

@testset "paired switch and control share history with interior technical traders" begin
    switched = _run(_rebuild_config(L = 32, steps = 600, seed = 6, f = 0.15, h = 1.0);
                    rule_activation_step = 301, snapshot_steps = [300],
                    interior_technical_fraction = 0.05)
    control = _run(_rebuild_config(L = 32, steps = 600, seed = 6, f = 0.25, h = 1.0);
                   rule_activation_step = 601, snapshot_steps = [300],
                   interior_technical_fraction = 0.05)
    @test switched.frames[300] == control.frames[300]
    @test switched.sell_fraction[1:301] == control.sell_fraction[1:301]
    @test switched.prices[1:302] == control.prices[1:302]
end

@testset "held interior technical traders stay in Hold and are not counted" begin
    config = _rebuild_config(L = 32, steps = 300, seed = 6, f = 0.2, h = 1.0)
    layout = market_layout(config; minority_population = :interior,
                           interior_technical_fraction = 0.05)
    tech = Set(layout.interior_technical)
    snaps = collect(1:300)
    r = _run(config; rule_activation_step = 101, boundary_mode = :hold,
             snapshot_steps = snaps, interior_technical_fraction = 0.05)
    n_counted = 30^2 - length(tech)
    for t in snaps
        g = r.frames[t]
        @test all(g[rc...] == 1 for rc in tech)
        sells = count(g[i, j] == 2 for i in 2:31, j in 2:31 if (i, j) ∉ tech)
        @test r.sell_fraction[t + 1] == sells / n_counted
    end
end

@testset "active interior technical traders follow the band rule" begin
    config = _rebuild_config(L = 32, steps = 400, seed = 6, f = 0.2, h = 1.0)
    layout = market_layout(config; minority_population = :interior,
                           interior_technical_fraction = 0.05)
    snaps = collect(1:400)
    r = _run(config; rule_activation_step = 101, snapshot_steps = snaps,
             interior_technical_fraction = 0.05)
    states = Int64[]
    for t in snaps, (j, (row, col)) in enumerate(layout.interior_technical)
        expected = compute_band_state(r.prices[t + 1], r.ema_price[t + 1],
                                      r.ema_volatility[t + 1], layout.interior_technical_k[j])
        @test r.frames[t][row, col] == expected
        push!(states, expected)
    end
    @test any(!=(1), states)
    # Conservation with interior technical traders trading.
    cash = r.total_cash .+ r.market_maker_cash
    @test maximum(abs.(cash .- cash[1])) < 1e-5
    @test all(==(r.total_shares[1] + r.market_maker_inventory[1]),
              r.total_shares .+ r.market_maker_inventory)
end

@testset "zero dealer depth leaves interior technical traders in Hold" begin
    config = _rebuild_config(L = 32, steps = 300, seed = 6, f = 0.2, h = 0.0)
    active = _run(config; rule_activation_step = 101, interior_technical_fraction = 0.05)
    held = _run(config; rule_activation_step = 101, boundary_mode = :hold,
                interior_technical_fraction = 0.05)
    @test active.sell_fraction == held.sell_fraction
end

@testset "argument validation" begin
    config = _rebuild_config(L = 16, steps = 10, f = 0.2, h = 100.0)
    @test_throws ArgumentError _run(config; revision_probability = 1.5)
    @test_throws ArgumentError _run(config; revision_probability = -0.1)
    @test_throws ArgumentError _run(config; interior_technical_fraction = -0.01)
    @test_throws ArgumentError _run(config; interior_technical_fraction = 0.9)
end

println("Lazy revision and interior technical traders OK")
