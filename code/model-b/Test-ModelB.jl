# Test-ModelB.jl — focused Model B tests (model-B-plan.md §6, spec §4)
# Run from repo root: julia code/model-b/Test-ModelB.jl
# (paths are @__DIR__-relative, so any cwd works)

include(joinpath(@__DIR__, "Include.jl"))
using Test

# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

"""All-`state` interior on an all-Hold boundary — for hand-built scenarios."""
function _uniform_interior_grid(nrows::Int64, ncols::Int64, state::Int64)::Array{Int64,2}
    grid = fill(1, nrows, ncols)
    grid[2:nrows-1, 2:ncols-1] .= state
    return grid
end

# ---------------------------------------------------------------------------
# Trajectory helpers (Compute.jl)
# ---------------------------------------------------------------------------

@testset "interior imbalance excludes the whole boundary" begin
    # boundary all Sell, interior all Hold → φ = 0 exactly
    grid = fill(1, 8, 8)
    grid[1, :] .= 2; grid[8, :] .= 2; grid[:, 1] .= 2; grid[:, 8] .= 2
    @test compute_interior_imbalance(grid) == 0.0

    # known interior counts: 3 Buy, 1 Sell in the 6×6 interior
    grid2 = fill(1, 8, 8)
    grid2[2, 2] = 0; grid2[3, 3] = 0; grid2[4, 4] = 0; grid2[5, 5] = 2
    @test compute_interior_imbalance(grid2) ≈ 2 / 36

    # all-Buy interior → φ = +1; all-Sell interior → φ = −1
    @test compute_interior_imbalance(_uniform_interior_grid(8, 8, 0)) == 1.0
    @test compute_interior_imbalance(_uniform_interior_grid(8, 8, 2)) == -1.0
end

@testset "interior fractions" begin
    grid = fill(1, 8, 8)
    grid[2, 2] = 0; grid[2, 3] = 0; grid[3, 2] = 2
    buy, hold, sell = compute_interior_fractions(grid)
    @test buy  ≈ 2 / 36
    @test sell ≈ 1 / 36
    @test hold ≈ 33 / 36
    @test buy + hold + sell ≈ 1.0
end

@testset "crash statistics from the full trajectory" begin
    s = [0.1, 0.6, 0.7, 0.2, 0.8, 0.1]
    stats = compute_crash_statistics(s; threshold = 0.5)
    @test stats.frequency ≈ 3 / 6
    @test stats.n_crashes == 2
    @test stats.durations == [2, 1]

    quiet = compute_crash_statistics([0.1, 0.2, 0.3])
    @test quiet.frequency == 0.0
    @test quiet.n_crashes == 0
    @test isempty(quiet.durations)

    # an episode still open at the end of the series is closed and counted
    tail = compute_crash_statistics([0.6, 0.7])
    @test tail.n_crashes == 1
    @test tail.durations == [2]
end

# ---------------------------------------------------------------------------
# Configuration (Types.jl / Factory.jl)
# ---------------------------------------------------------------------------

"""Small, fast config for integration tests; override any field via kwargs."""
function _test_config(; kwargs...)
    defaults = (
        number_of_rows = 16, number_of_cols = 16,
        steps = 50, seed = 7,
    )
    return build(MyModelBConfiguration, merge(defaults, (; kwargs...)))
end

@testset "configuration builder: defaults and validation" begin
    config = build(MyModelBConfiguration, (number_of_rows = 32, number_of_cols = 32))
    @test config.number_of_colors == 3
    @test config.radius == 4
    @test config.steps == 200
    @test config.seed == 42
    @test config.initial_condition == :balanced_perturbation
    @test config.initial_buy_fraction  == 0.05
    @test config.initial_sell_fraction == 0.05
    @test config.edge_fraction == 0.25
    @test config.α ≈ 1 / 60
    @test config.k == 1.0
    @test config.λ == 0.01
    @test config.P0 == 100.0
    @test config.minority_fraction == 0.20
    @test config.rule_major_index == 19280
    @test config.rule_minor_index == 19286
    # budget-constraint fields (spec 2026-07-16 §3)
    @test config.initial_cash == 1000.0
    @test config.initial_shares == 10
    @test config.cost_basis_rule == true
    @test config.edge_band_spread == 0.5

    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, steps = 0))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 2, number_of_cols = 32))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, edge_fraction = 1.5))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32,
         initial_buy_fraction = 0.6, initial_sell_fraction = 0.6))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, initial_condition = :bogus))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, P0 = -1.0))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, initial_cash = -1.0))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, initial_shares = -1))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, edge_band_spread = 1.0))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, edge_band_spread = -0.1))
end

# ---------------------------------------------------------------------------
# Initialization and boundary helpers (Factory.jl)
# ---------------------------------------------------------------------------

@testset "edge coordinates: seeded boundary sample" begin
    nrows, ncols = 16, 16
    n_boundary = 2 * ncols + 2 * (nrows - 2)              # 60 for 16×16
    coords = build_edge_coordinates(nrows, ncols, 0.25, Xoshiro(11))
    @test length(coords) == round(Int, 0.25 * n_boundary) # 15
    @test length(unique(coords)) == length(coords)         # no repeats
    @test all(r == 1 || r == nrows || c == 1 || c == ncols for (r, c) in coords)
    @test issorted(coords)

    # same seed → same sample; different seed → different sample
    @test coords == build_edge_coordinates(nrows, ncols, 0.25, Xoshiro(11))
    @test coords != build_edge_coordinates(nrows, ncols, 0.25, Xoshiro(12))

    # edge_fraction = 0 → no active edges; = 1 → every boundary cell
    @test isempty(build_edge_coordinates(nrows, ncols, 0.0, Xoshiro(11)))
    @test length(build_edge_coordinates(nrows, ncols, 1.0, Xoshiro(11))) == n_boundary
end

@testset "initial grid modes" begin
    config = _test_config()
    nrows, ncols = config.number_of_rows, config.number_of_cols
    N_int = (nrows - 2) * (ncols - 2)                     # 196 for 16×16

    # :all_hold — every cell Hold
    all_hold = build_initial_grid(_test_config(initial_condition = :all_hold), Xoshiro(1))
    @test all(all_hold .== 1)

    # :balanced_perturbation — exact equal counts, interior only, boundary Hold
    grid = build_initial_grid(config, Xoshiro(1))
    @test count(==(0), grid) == round(Int, 0.05 * N_int)
    @test count(==(2), grid) == round(Int, 0.05 * N_int)
    @test count(==(0), grid) == count(==(2), grid)
    @test compute_interior_imbalance(grid) == 0.0
    @test all(grid[1, :] .== 1) && all(grid[end, :] .== 1)
    @test all(grid[:, 1] .== 1) && all(grid[:, end] .== 1)
    @test grid == build_initial_grid(config, Xoshiro(1))   # reproducible

    # :custom — validated pass-through
    cfg_custom = _test_config(initial_condition = :custom)
    @test_throws ArgumentError build_initial_grid(cfg_custom, Xoshiro(1))
    @test_throws ArgumentError build_initial_grid(cfg_custom, Xoshiro(1);
        custom_grid = fill(1, 4, 4))
    bad = fill(1, 16, 16); bad[3, 3] = 7
    @test_throws ArgumentError build_initial_grid(cfg_custom, Xoshiro(1); custom_grid = bad)
    ok = _uniform_interior_grid(16, 16, 0)
    @test build_initial_grid(cfg_custom, Xoshiro(1); custom_grid = ok) == ok

    # rounding overflow guard: valid config whose rounded counts exceed N_interior
    tiny = build(MyModelBConfiguration, (number_of_rows = 5, number_of_cols = 3,
        initial_buy_fraction = 0.5, initial_sell_fraction = 0.5))
    @test_throws ArgumentError build_initial_grid(tiny, Xoshiro(1))
end

@testset "agent books: initial endowments" begin
    config = _test_config()
    books  = build_agent_books(config)
    @test size(books.cash) == (16, 16)
    @test size(books.shares) == (16, 16)
    @test size(books.avg_cost) == (16, 16)
    @test all(books.cash .== config.initial_cash)
    @test all(books.shares .== config.initial_shares)
    @test all(books.avg_cost .== config.P0)
end

@testset "edge bands: seeded per-agent half-widths" begin
    k1 = build_edge_bands(1.0, 0.5, 15, Xoshiro(11))
    @test length(k1) == 15
    @test all(0.5 .≤ k1 .≤ 1.5)
    @test k1 == build_edge_bands(1.0, 0.5, 15, Xoshiro(11))   # seeded → identical
    @test k1 != build_edge_bands(1.0, 0.5, 15, Xoshiro(12))

    # δ = 0 recovers the homogeneous model exactly
    @test build_edge_bands(1.0, 0.0, 15, Xoshiro(11)) == fill(1.0, 15)

    # δ = 0 must still consume the same number of rng draws (order contract)
    rng_a = Xoshiro(11); build_edge_bands(1.0, 0.0, 15, rng_a)
    rng_b = Xoshiro(11); build_edge_bands(1.0, 0.9, 15, rng_b)
    @test rand(rng_a) == rand(rng_b)
end

# ---------------------------------------------------------------------------
# CA machinery: seeded minority assignment (Simulate.jl)
# ---------------------------------------------------------------------------

@testset "CA components: seeded minority assignment" begin
    config = _test_config(minority_fraction = 0.20)
    _, agents1, _ = _build_ca_components(config; rng = Xoshiro(3))
    _, agents2, _ = _build_ca_components(config; rng = Xoshiro(3))
    minors(agents) = Set(i for (i, a) in enumerate(agents)
                         if a.rule.index == config.rule_minor_index)
    @test minors(agents1) == minors(agents2)                       # seeded → identical
    @test length(minors(agents1)) == round(Int, 0.20 * 16 * 16)    # 51 of 256

    # default-rng path (Model A) still works and is homogeneous when f = 0
    world0, agents0, rule0 = _build_ca_components(_test_config(minority_fraction = 0.0))
    @test isnothing(world0) && isnothing(agents0)
    @test rule0.index == config.rule_major_index
end

# ---------------------------------------------------------------------------
# Closed-loop simulate (Simulate.jl) — model-B-plan.md §6 properties
# ---------------------------------------------------------------------------

@testset "1. positive interior imbalance raises the price" begin
    config = _test_config(initial_condition = :custom, steps = 1)
    grid   = _uniform_interior_grid(16, 16, 0)            # all-Buy interior
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.net_imbalance[1] == 1.0
    @test result.prices[2] > result.prices[1]
    @test result.log_returns[1] ≈ config.λ * 1.0
end

@testset "2. negative interior imbalance lowers the price" begin
    config = _test_config(initial_condition = :custom, steps = 1)
    grid   = _uniform_interior_grid(16, 16, 2)            # all-Sell interior
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.net_imbalance[1] == -1.0
    @test result.prices[2] < result.prices[1]
end

@testset "3. edge cells respond to the newly generated price" begin
    # All-Buy interior with λ = 1: P₁ = 100·e ≈ 271.8 blows through the band
    # (μ₁ ≈ 102.9, σ₁ ≈ 2.8, upper ≈ 105.7) → edge state Sell at t = 1.
    # Under the OLD (wrong) ordering the edge would see P₀ = μ₀ = 100 → Hold.
    config = _test_config(initial_condition = :custom, steps = 1, λ = 1.0)
    grid   = _uniform_interior_grid(16, 16, 0)
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.edge_states[1] == 2
    @test result.prices[2] > result.band_upper[2]
end

@testset "4. edge/boundary cells are excluded from price formation" begin
    # Boundary all Sell, interior all Hold → φ = 0 and the price cannot move.
    config = _test_config(initial_condition = :custom, steps = 1)
    grid = fill(1, 16, 16)
    grid[1, :] .= 2; grid[16, :] .= 2; grid[:, 1] .= 2; grid[:, 16] .= 2
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.net_imbalance[1] == 0.0
    @test result.prices[2] == result.prices[1]
end

@testset "5. passive boundary cells remain Hold" begin
    config = _test_config()                               # balanced perturbation
    result = simulate(config; verbose = false)
    active = Set(result.edge_coordinates)
    final  = result.frames[config.steps]
    nrows, ncols = size(final)
    passive_ok = true
    for r in 1:nrows, c in 1:ncols
        (r == 1 || r == nrows || c == 1 || c == ncols) || continue
        (r, c) in active && continue
        passive_ok &= (final[r, c] == 1)
    end
    @test passive_ok
end

@testset "6. all-Hold null control is stationary" begin
    config = _test_config(initial_condition = :all_hold)
    result = simulate(config; verbose = false)
    @test all(result.prices .== config.P0)
    @test all(result.net_imbalance .== 0.0)
    @test all(result.log_returns .== 0.0)
    @test all(result.edge_states .== 1)
    @test all(result.hold_fraction .== 1.0)
    @test result.frames[config.steps] == fill(1, 16, 16)
end

@testset "7. balanced perturbation activates spatial dynamics" begin
    config = _test_config()
    result = simulate(config; verbose = false)
    @test result.frames[config.steps] != result.frames[0]
    @test any(result.net_imbalance .!= 0.0)
    @test any(result.log_returns .!= 0.0)
end

@testset "8. same seed gives identical output" begin
    r1 = simulate(_test_config(); verbose = false)
    r2 = simulate(_test_config(); verbose = false)
    @test r1.prices == r2.prices
    @test r1.log_returns == r2.log_returns
    @test r1.net_imbalance == r2.net_imbalance
    @test r1.buy_fraction == r2.buy_fraction
    @test r1.hold_fraction == r2.hold_fraction
    @test r1.sell_fraction == r2.sell_fraction
    @test r1.edge_states == r2.edge_states
    @test r1.ema_price == r2.ema_price
    @test r1.ema_volatility == r2.ema_volatility
    @test r1.edge_coordinates == r2.edge_coordinates
    @test sort(collect(keys(r1.frames))) == sort(collect(keys(r2.frames)))
    @test all(r1.frames[t] == r2.frames[t] for t in keys(r1.frames))

    r3 = simulate(_test_config(seed = 8); verbose = false)
    @test r3.edge_coordinates != r1.edge_coordinates || r3.prices != r1.prices
end

@testset "9. trajectory series cover every simulation step" begin
    config = _test_config()
    T      = config.steps
    result = simulate(config; verbose = false)
    @test length(result.prices)         == T + 1
    @test length(result.ema_price)      == T + 1
    @test length(result.ema_volatility) == T + 1
    @test length(result.band_lower)     == T + 1
    @test length(result.band_upper)     == T + 1
    @test length(result.buy_fraction)   == T + 1
    @test length(result.hold_fraction)  == T + 1
    @test length(result.sell_fraction)  == T + 1
    @test length(result.log_returns)    == T
    @test length(result.net_imbalance)  == T
    @test length(result.edge_states)    == T
    @test haskey(result.frames, 0) && haskey(result.frames, T)
    # the price series reconstructs exactly from the recorded log returns
    @test all(isapprox.(diff(log.(result.prices)), result.log_returns; atol = 1e-12))
    # crash statistics run on the full trajectory
    stats = compute_crash_statistics(result.sell_fraction)
    @test 0.0 ≤ stats.frequency ≤ 1.0
    @test stats.n_crashes == length(stats.durations)
end
