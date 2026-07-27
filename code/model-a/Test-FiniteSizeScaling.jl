## Test-FiniteSizeScaling.jl
#
# Unit tests for the finite-size scaling primitives. Run from code/:
#   julia --project=. model-a/Test-FiniteSizeScaling.jl

import Pkg; Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()

using Test
include(joinpath(@__DIR__, "FiniteSize-Lib.jl"))

@testset "rule tables" begin
    # Verified base-3 decodings of the two totalistic rules; the pair differs
    # only at c = 1, and c = 0 → Sell is what makes all-Buy unstable.
    @test D_MAJ == [2, 0, 0, 0, 1, 1, 2, 2, 2]
    @test D_MIN == [2, 2, 0, 0, 1, 1, 2, 2, 2]
    @test [c for c in 0:8 if D_MAJ[c+1] != D_MIN[c+1]] == [1]
    @test D_MAJ[8+1] == 2      # all-Sell neighborhood stays Sell (absorbing)
end

@testset "ca_step! — absorbing and unstable homogeneous states" begin
    L = 8
    is_min = falses(L, L)

    # All-Sell is absorbing: every cell sees c = 8 → Sell.
    g = fill(2, L, L); n = copy(g)
    ca_step!(g, n, is_min, L, L)
    @test all(n .== 2)

    # All-Buy is NOT stable: every cell sees c = 0, and both rules send 0 → Sell.
    g = fill(0, L, L); n = copy(g)
    ca_step!(g, n, is_min, L, L)
    @test all(n .== 2)

    # All-Hold: c = 4 → Hold for both rules.
    g = fill(1, L, L); n = copy(g)
    ca_step!(g, n, is_min, L, L)
    @test all(n .== 1)
end

@testset "ca_step! — minority mask selects the contrarian table" begin
    # Build a neighborhood sum of exactly 1 at the center: three Buy, one Hold.
    L = 5
    g = fill(0, L, L); n = copy(g)
    g[2, 3] = 1                              # one Hold neighbor of (3,3)
    is_min = falses(L, L)
    ca_step!(g, n, is_min, L, L)
    @test n[3, 3] == 0                       # majority rule: c = 1 → Buy

    is_min[3, 3] = true
    ca_step!(g, n, is_min, L, L)
    @test n[3, 3] == 2                       # contrarian rule: c = 1 → Sell
end

@testset "sell_fraction" begin
    g = fill(1, 4, 4)
    @test sell_fraction(g) == 0.0
    g[1, 1] = 2; g[2, 2] = 2; g[3, 3] = 2; g[4, 4] = 2
    @test sell_fraction(g) == 0.25
    @test sell_fraction(fill(2, 3, 3)) == 1.0
end

@testset "sell_clusters — sizes, counts, periodic wrap" begin
    g = fill(1, 6, 6)
    @test sell_clusters(g, 1) == (0, 0)

    # Two separated clusters: an L-tromino and a single cell.
    g[2, 2] = 2; g[2, 3] = 2; g[3, 2] = 2
    g[5, 5] = 2
    largest, n_super = sell_clusters(g, 1)
    @test largest == 3
    @test n_super == 2                       # both clear a 1-cell criterion
    @test sell_clusters(g, 3)[2] == 1        # only the tromino clears 3 cells
    @test sell_clusters(g, 4)[2] == 0

    # Diagonal neighbors are NOT connected under 4-connectivity.
    g2 = fill(1, 4, 4)
    g2[1, 1] = 2; g2[2, 2] = 2
    @test sell_clusters(g2, 1) == (1, 2)

    # Cells on opposite edges join through the periodic wrap.
    g3 = fill(1, 4, 4)
    g3[2, 1] = 2; g3[2, 4] = 2
    @test sell_clusters(g3, 1) == (2, 1)

    # A full row wraps into a single ring of length 4.
    g4 = fill(1, 4, 4)
    g4[3, :] .= 2
    @test sell_clusters(g4, 1) == (4, 1)
end

@testset "run_cell — staging, censoring, determinism" begin
    # All three stages are reached well inside the horizon at large f.
    r = run_cell(32, 0.20, 1; n_crit=50, check=5, t_max=20_000, burn_in=200)
    @test r.nuc_observed && r.half_observed && r.conv_observed
    @test r.t_nuc <= r.t_half <= r.t_conv
    @test r.largest_at_nuc >= 50
    @test r.t_nuc % 5 == 0                   # nucleation is only sampled on the cadence

    # Same seed, same answer.
    r2 = run_cell(32, 0.20, 1; n_crit=50, check=5, t_max=20_000, burn_in=200)
    @test r2 == r

    # Different seeds give different quenched disorder, hence different waits.
    r3 = run_cell(32, 0.20, 2; n_crit=50, check=5, t_max=20_000, burn_in=200)
    @test r3.t_conv != r.t_conv

    # A horizon far too short to escape censors rather than reporting a time.
    rc = run_cell(64, 0.13, 1; n_crit=50, check=5, t_max=50, burn_in=200)
    @test !rc.conv_observed
    @test rc.t_conv == 50                    # censored value pinned at the horizon
end

println("\nAll finite-size scaling tests passed.")
