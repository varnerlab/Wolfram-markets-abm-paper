# Test-BoundaryVsBulk.jl — unit tests for BoundaryVsBulk-Lib.jl
# Run from repo root: julia code/model-b/Test-BoundaryVsBulk.jl

include(joinpath(@__DIR__, "Include.jl"))
include(joinpath(@__DIR__, "BoundaryVsBulk-Lib.jl"))
using Test

@testset "chebyshev_boundary_distance" begin
    @test chebyshev_boundary_distance(2, 2, 64, 64)   == 1
    @test chebyshev_boundary_distance(32, 32, 64, 64) == 31
    @test chebyshev_boundary_distance(1, 10, 64, 64)  == 0   # boundary cell
    @test chebyshev_boundary_distance(2, 63, 64, 64)  == 1
end

@testset "null_shell_pmf" begin
    pmf = null_shell_pmf(64)
    @test length(pmf) == 31
    @test pmf[1] ≈ 244 / 3844          # (62² − 60²)/62²
    @test sum(pmf) ≈ 1.0
    @test sum(pmf[1:2]) ≈ 480 / 3844   # ≈ 0.125, the d ≤ 2 null

    small = null_shell_pmf(6)          # 4×4 interior: 12 cells at d=1, 4 at d=2
    @test small ≈ [12 / 16, 4 / 16]
end

@testset "binom_two_sided_p" begin
    @test binom_two_sided_p(6, 3, 0.5) ≈ 1.0
    @test binom_two_sided_p(6, 0, 0.5) ≈ 2 * (1 / 64)
    @test binom_two_sided_p(3, 3, 0.125) ≈ 0.125^3
end

@testset "patch_side" begin
    @test patch_side(9)  == 3
    @test patch_side(25) == 5
    @test patch_side(17) == 3   # tie → 3
    @test patch_side(1)  == 3
    @test patch_side(40) == 5
end
