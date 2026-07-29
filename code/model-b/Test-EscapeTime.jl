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

@testset "kramers_profile_fit" begin
    fs  = [0.12, 0.15, 0.18, 0.20, 0.25, 0.30]
    lnt = 2.0 .+ 0.4 ./ (fs .- 0.10)
    fit = kramers_profile_fit(fs, lnt)
    @test isapprox(fit.f0, 0.10; atol = 2e-4)
    @test isapprox(fit.B, 0.4; rtol = 0.02)
    @test isapprox(fit.A, 2.0; atol = 0.05)
    @test fit.r2 > 0.9999
    @test_throws AssertionError kramers_profile_fit([0.2, 0.3, 0.4], [1.0, 2.0, 3.0])
end

@testset "bootstrap_kramers" begin
    rng0 = Xoshiro(11)
    fs_run = Float64[]; tons = Int[]
    for f in [0.12, 0.15, 0.18, 0.20, 0.25, 0.30], _ in 1:20
        push!(fs_run, f)
        push!(tons, round(Int, exp(2.0 + 0.4 / (f - 0.10)) * (0.9 + 0.2 * rand(rng0))))
    end
    bs = bootstrap_kramers(fs_run, tons; ndraws = 200, rng = Xoshiro(7))
    @test length(bs.f0) == 200                    # no censoring → every draw fits
    @test 0.05 < median(bs.f0) < 0.13             # recovers the divergence region
    bs2 = bootstrap_kramers(fs_run, tons; ndraws = 200, rng = Xoshiro(7))
    @test bs2.f0 == bs.f0                         # deterministic given the rng

    # knife-edge censoring: f = 0.12 has 3/6 censored, so resampled draws can
    # lose that point (< 4 remain) and must be skipped, not crash
    fs4 = repeat([0.12, 0.15, 0.20, 0.30], inner = 6)
    t4  = Int[]
    for f in [0.12, 0.15, 0.20, 0.30], i in 1:6
        push!(t4, (f == 0.12 && i <= 3) ? 0 : 100 + i)
    end
    bs4 = bootstrap_kramers(fs4, t4; ndraws = 100, rng = Xoshiro(7))
    @test 0 < length(bs4.f0) <= 100
end

@testset "a2_subset" begin
    # Synthetic check of the window rule itself: f == 0.20 pooled across every
    # `stage` value, with a defined v_front, independent of the committed CSV.
    syn = DataFrame(stage = ["pilot", "pilot", "a2x", "pilot", "a2x"],
                     f     = [0.20, 0.20, 0.20, 0.15, 0.20],
                     v_front = [0.10, NaN, 0.30, 0.20, 0.05])
    s_a2, s_excl = a2_subset(syn)
    @test nrow(s_a2) == 3               # 4 rows at f=0.20, 1 of them NaN
    @test s_excl == 1
    @test all(s_a2.f .== 0.20)
    @test all(.!isnan.(s_a2.v_front))
    @test Set(s_a2.stage) == Set(["pilot", "a2x"])   # pooled, not filtered to one stage

    # The committed CSV: this n is what the paper cites (97 included, 3
    # excluded). a2_subset feeds panels C and D of Fig6-GrowthGating, so a
    # silent change to it would silently move that number.
    df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime.csv"), DataFrame)
    a2, n_excluded = a2_subset(df)
    @test nrow(a2) == 97
    @test n_excluded == 3
    @test all(a2.f .== 0.20)
    @test all(.!isnan.(a2.v_front))
    @test nrow(a2) + n_excluded == count(==(0.20), df.f)
end

@testset "CASH_RAMP / cash_color_map" begin
    @test length(CASH_RAMP) == 5
    @test allunique(CASH_RAMP)

    full5 = [250.0, 500.0, 1000.0, 2000.0, 5000.0]
    cmap5 = cash_color_map(full5, full5)
    @test cmap5[250.0]  == CASH_RAMP[1]
    @test cmap5[500.0]  == CASH_RAMP[2]
    @test cmap5[1000.0] == CASH_RAMP[3]
    @test cmap5[2000.0] == CASH_RAMP[4]
    @test cmap5[5000.0] == CASH_RAMP[5]

    # The property the paper's cross-panel readability depends on: a cash
    # level shared between a 3-level subset (barrier law's panel A) and the
    # full 5-level set (panels C/D) must land on the SAME colour in both, so
    # a reader tracks one budget across panels showing different dose subsets.
    subset3 = [500.0, 1000.0, 5000.0]
    cmap3   = cash_color_map(subset3, full5)
    @test cmap3[500.0]  == cmap5[500.0]
    @test cmap3[1000.0] == cmap5[1000.0]
    @test cmap3[5000.0] == cmap5[5000.0]

    @test_throws AssertionError cash_color_map([500.0], [500.0, 1000.0])  # full domain != 5 levels
    @test_throws AssertionError cash_color_map([999.0], full5)            # cash outside full domain
end

@testset "spearman_perm_p" begin
    x  = collect(1.0:40.0)
    sp = spearman_perm_p(x, -2.0 .* x .+ 100.0)
    @test sp.rho ≈ -1.0
    @test sp.p == 1 / 10_001                     # +1 MC correction, zero hits

    sp2 = spearman_perm_p(x, 1.0 .* x)
    @test sp2.rho ≈ 1.0 && sp2.p == 1 / 10_001

    yr  = shuffle(Xoshiro(3), x)                 # independent → large p
    sp3 = spearman_perm_p(x, yr; ndraws = 2000, rng = Xoshiro(7))
    @test sp3.p > 0.05

    @test spearman_perm_p(x, yr; ndraws = 500, rng = Xoshiro(7)) ==
          spearman_perm_p(x, yr; ndraws = 500, rng = Xoshiro(7))
end
