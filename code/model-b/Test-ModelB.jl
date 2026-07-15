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
