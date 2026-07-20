# Test-EscapeTime.jl — unit tests for EscapeTime-Lib.jl
# Run from repo root: julia code/model-b/Test-EscapeTime.jl

include(joinpath(@__DIR__, "Include.jl"))
include(joinpath(@__DIR__, "EscapeTime-Lib.jl"))
using Test

@testset "sell_clusters (full grid, toggle definition)" begin
    g = fill(1, 6, 6)
    @test sell_clusters(g) == (0, 0)
    g[1, 1] = 2; g[1, 2] = 2; g[2, 1] = 2      # boundary L — full grid counts it
    @test sell_clusters(g) == (1, 3)
    g[4, 4] = 2; g[5, 5] = 2                   # diagonal pair: NOT adjacent
    @test sell_clusters(g) == (3, 3)
    g[4, 5] = 2                                # bridges the diagonal pair
    @test sell_clusters(g) == (2, 3)
end

@testset "maxcl_series + onset_step" begin
    mk(cells) = (g = fill(1, 4, 4); for (r, c) in cells; g[r, c] = 2; end; g)
    frames = Dict{Int64,Matrix{Int64}}(
        0 => fill(1, 4, 4),
        1 => mk([(2, 2)]),
        2 => mk([(2, 2), (2, 3)]),
        3 => mk([(2, 2), (2, 3), (3, 2), (3, 3)]))
    m = maxcl_series(frames, 3)
    @test m == [1, 2, 4]
    @test onset_step(m, 16, 0.05) == 1      # needs ≥ 0.8 cells
    @test onset_step(m, 16, 0.20) == 3      # needs ≥ 3.2 cells
    @test onset_step(m, 16, 0.50) == 0      # never reached
end

@testset "censored_median (KM under Type I censoring)" begin
    @test censored_median([10, 20, 30]) == 20.0
    @test censored_median([10, 20, 30, 0]) == 20.0   # n=4, k=2 → 2nd obs
    @test censored_median([5, 7, 0, 0]) == 7.0       # hand KM: S(7) = 0.5
    @test isnan(censored_median([10, 0, 0]))         # >half censored
    @test isnan(censored_median([0, 0]))
    @test isnan(censored_median(Int[]))
end

@testset "window_velocity" begin
    maxcl = [2t for t in 1:1000]                     # 2 cells/step on 100 cells
    @test window_velocity(maxcl, 100, 100; lo = 50, hi = 400) ≈ 0.02
    @test window_velocity(fill(50, 1000), 100, 100; lo = 50, hi = 400) ≈ 0.0 atol = 1e-12
end
