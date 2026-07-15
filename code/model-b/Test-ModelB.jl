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
