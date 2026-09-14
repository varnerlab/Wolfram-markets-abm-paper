## Compute-NucleationFit.jl
#
# Fit the mixed-state lifetime data τ(f) with descriptive finite-horizon curves.
#
# Candidate form: τ(f) = A · exp(B / (f - f₀)).
# This is an empirical onset-time fit, not a derived Kramers law.
#
# Also: finer lifetime sweep near the transition for better resolution.

import Pkg; Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()

using CSV, DataFrames, Printf, Statistics, Random

# ─── Rule decoding ────────────────────────────────────────────────────────
function decode_rule(index::Int, ncolors::Int, radius::Int)
    D = Dict{Int, Int}()
    val = index
    for c in 0:(ncolors-1)*radius
        D[c] = val % ncolors
        val = val ÷ ncolors
    end
    return D
end

const D_MAJ = decode_rule(19280, 3, 4)
const D_MIN = decode_rule(19286, 3, 4)

function ca_step!(grid::Matrix{Int}, nxt::Matrix{Int},
                  is_min::BitMatrix, nrows::Int, ncols::Int)
    @inbounds for r in 1:nrows, c in 1:ncols
        up    = r == 1     ? nrows : r - 1
        down  = r == nrows ? 1     : r + 1
        left  = c == 1     ? ncols : c - 1
        right = c == ncols ? 1     : c + 1
        csum = grid[up, c] + grid[down, c] + grid[r, left] + grid[r, right]
        nxt[r, c] = (is_min[r, c] ? D_MIN : D_MAJ)[csum]
    end
end

function sell_fraction(grid::Matrix{Int})
    count(==(2), grid) / length(grid)
end

function assign_minority!(is_min::BitMatrix, f::Float64, nrows::Int, ncols::Int, seed::Int)
    fill!(is_min, false)
    f > 0 || return
    N = nrows * ncols
    rng = Random.MersenneTwister(seed)
    for pos in randperm(rng, N)[1:round(Int, f * N)]
        is_min[(pos-1)÷ncols+1, (pos-1)%ncols+1] = true
    end
end

# ═══════════════════════════════════════════════════════════════════════════
# 1. Fine lifetime sweep
# ═══════════════════════════════════════════════════════════════════════════

println("=" ^ 70)
println("  Lifetime Sweep (fine resolution near transition)")
println("=" ^ 70)

const L = 64
const T_MAX = 100_000
const N_SEEDS = 20

fs_fine = vcat(
    0.10:0.01:0.14,
    0.140:0.005:0.175,
    0.18:0.01:0.22,
    0.25, 0.30
)
sort!(unique!(fs_fine))

# Collect data
lifetime_data = Dict{Float64, Vector{Int}}()
observed_data = Dict{Float64, BitVector}()
lifetime_rows = DataFrame(
    f=Float64[],
    seed=Int[],
    onset_time=Int[],
    event_observed=Bool[],
)

println("\n  f     │ Mean τ     │ Median τ   │ Std τ      │ Survived │ ln(mean τ)")
println("────────┼────────────┼────────────┼────────────┼──────────┼───────────")

for f in fs_fine
    lifetimes = Int[]
    observed = Bool[]

    for s in 1:N_SEEDS
        grid = rand(Random.MersenneTwister(1000 + s), 0:2, L, L)
        nxt = copy(grid)
        is_min = falses(L, L)
        assign_minority!(is_min, f, L, L, 5000 + s)

        # Burn-in
        for _ in 1:200
            ca_step!(grid, nxt, is_min, L, L)
            grid, nxt = nxt, grid
        end

        # Measure lifetime
        lifetime = T_MAX
        event_observed = false
        for t in 1:T_MAX
            ca_step!(grid, nxt, is_min, L, L)
            grid, nxt = nxt, grid
            if sell_fraction(grid) > 0.90
                lifetime = t
                event_observed = true
                break
            end
        end
        push!(lifetimes, lifetime)
        push!(observed, event_observed)
        push!(lifetime_rows, (f, s, lifetime, event_observed))
    end

    lifetime_data[f] = lifetimes
    observed_data[f] = BitVector(observed)
    survived = count(!, observed)
    μ = mean(lifetimes)
    md = median(lifetimes)
    σ = std(lifetimes)

    @printf("  %.3f │ %10.0f │ %10.0f │ %10.0f │   %2d/%2d  │  %7.3f\n",
            f, μ, md, σ, survived, N_SEEDS, log(μ))
end

CSV.write(joinpath(@__DIR__, "..", "data", "ModelA-OnsetTimes.csv"), lifetime_rows)

# ═══════════════════════════════════════════════════════════════════════════
# 2. Fit ln(τ) vs f
# ═══════════════════════════════════════════════════════════════════════════

println("\n" * "=" ^ 70)
println("  Empirical Onset-Time Fitting")
println("=" ^ 70)

# Only use f values where not all seeds survived (finite lifetime)
# and not all collapsed instantly
f_fit = Float64[]
lnτ_fit = Float64[]

for f in sort(collect(keys(lifetime_data)))
    τs = lifetime_data[f]
    survived = count(!, observed_data[f])
    if survived == 0 && mean(τs) > 50  # finite lifetime, not trivial
        push!(f_fit, f)
        push!(lnτ_fit, log(mean(τs)))
    end
end

println("\n  Data points for fitting (f where all seeds collapsed):")
println("  f       │ ln(τ)")
println("──────────┼────────")
for (f, lτ) in zip(f_fit, lnτ_fit)
    @printf("  %.3f   │ %.3f\n", f, lτ)
end

# Fit 1: ln(τ) = a + b/f  (simple barrier ~ 1/f)
if length(f_fit) >= 2
    # Linear regression: ln(τ) = a + b * (1/f)
    x = 1.0 ./ f_fit
    y = lnτ_fit
    n = length(x)
    sx = sum(x); sy = sum(y); sxx = sum(x.^2); sxy = sum(x .* y)
    b1 = (n * sxy - sx * sy) / (n * sxx - sx^2)
    a1 = (sy - b1 * sx) / n
    y_pred = a1 .+ b1 .* x
    SS_res = sum((y .- y_pred).^2)
    SS_tot = sum((y .- mean(y)).^2)
    R2_1 = 1 - SS_res / SS_tot

    @printf("\n  Fit 1: ln(τ) = %.3f + %.3f / f\n", a1, b1)
    @printf("  R² = %.6f\n", R2_1)
    @printf("  Pre-exponential: τ₀ = exp(%.3f) = %.1f\n", a1, exp(a1))
end

# Fit 2: ln(τ) = a + b * (1/(f - f₀)) with f₀ as a parameter
# Grid search over f₀
let
    if length(f_fit) >= 3
        local best_R2 = -Inf
        local best_f0 = 0.0
        local best_a = 0.0
        local best_b = 0.0

        for f0_try in 0.00:0.001:0.14
            local x = 1.0 ./ (f_fit .- f0_try)
            any(isinf, x) && continue
            local y = lnτ_fit
            local n = length(x)
            local sx = sum(x); local sy = sum(y)
            local sxx = sum(x.^2); local sxy = sum(x .* y)
            local denom = n * sxx - sx^2
            abs(denom) < 1e-10 && continue
            local b = (n * sxy - sx * sy) / denom
            local a = (sy - b * sx) / n
            local y_pred = a .+ b .* x
            local SS_res = sum((y .- y_pred).^2)
            local SS_tot = sum((y .- mean(y)).^2)
            local R2 = SS_tot > 0 ? 1 - SS_res / SS_tot : 0.0
            if R2 > best_R2
                best_R2 = R2; best_f0 = f0_try; best_a = a; best_b = b
            end
        end

        @printf("\n  Fit 2: ln(τ) = %.3f + %.3f / (f - %.3f)\n", best_a, best_b, best_f0)
        @printf("  R² = %.6f\n", best_R2)
        @printf("  Fitted pseudo-threshold: f₀ = %.3f\n", best_f0)
        @printf("  This extrapolation does not establish absolute stability below f₀.\n")

        CSV.write(
            joinpath(@__DIR__, "..", "data", "ModelA-OnsetTime-Fit.csv"),
            DataFrame(
                model=["log_tau = a + b/(f-f0)"],
                a=[best_a],
                b=[best_b],
                f0=[best_f0],
                r_squared=[best_R2],
                n_f=[length(f_fit)],
            ),
        )

        for T_obs in [1000, 10000]
            local denom = log(T_obs) - best_a
            if denom > 0
                local f_cross = best_f0 + best_b / denom
                @printf("  → finite-horizon crossover estimate f(T=%d) = %.4f\n",
                        T_obs, f_cross)
            end
        end
    end
end

# Fit 3: ln(τ) = a + b * f^(-α)
let
    if length(f_fit) >= 2
        for α in [1.0, 2.0]
            local x = f_fit .^ (-α)
            local y = lnτ_fit
            local n = length(x)
            local sx = sum(x); local sy = sum(y)
            local sxx = sum(x.^2); local sxy = sum(x .* y)
            local b = (n * sxy - sx * sy) / (n * sxx - sx^2)
            local a = (sy - b * sx) / n
            local y_pred = a .+ b .* x
            local SS_res = sum((y .- y_pred).^2)
            local SS_tot = sum((y .- mean(y)).^2)
            local R2 = SS_tot > 0 ? 1 - SS_res / SS_tot : 0.0
            @printf("\n  Fit 3 (α=%.0f): ln(τ) = %.3f + %.6f · f^(-%.0f),  R² = %.6f\n",
                    α, a, b, α, R2)
        end
    end
end

# ═══════════════════════════════════════════════════════════════════════════
# 3. System-size dependence of f_c
# ═══════════════════════════════════════════════════════════════════════════

println("\n" * "=" ^ 70)
println("  System-Size Dependence of f_c")
println("=" ^ 70)

println("\n  Measuring transition threshold at different grid sizes")
println("  (f_c defined as f where ≥50% of seeds collapse within T=10000)")

const N_SEEDS_SIZE = 10
const T_SIZE = 10000

for L_test in [32, 48, 64, 96, 128]
    println("\n  L = $L_test:")
    println("    f     │ Collapsed │ Mean τ")
    println("  ────────┼───────────┼──────────")

    for f in 0.10:0.01:0.25
        collapsed = 0
        τ_sum = 0.0

        for s in 1:N_SEEDS_SIZE
            grid = rand(Random.MersenneTwister(1000 + s), 0:2, L_test, L_test)
            nxt = copy(grid)
            is_min = falses(L_test, L_test)
            assign_minority!(is_min, f, L_test, L_test, 5000 + s)

            for _ in 1:200
                ca_step!(grid, nxt, is_min, L_test, L_test)
                grid, nxt = nxt, grid
            end

            lifetime = T_SIZE
            for t in 1:T_SIZE
                ca_step!(grid, nxt, is_min, L_test, L_test)
                grid, nxt = nxt, grid
                if sell_fraction(grid) > 0.90
                    lifetime = t
                    break
                end
            end
            if lifetime < T_SIZE; collapsed += 1; end
            τ_sum += lifetime
        end

        @printf("    %.2f  │   %2d/%2d   │ %8.0f\n",
                f, collapsed, N_SEEDS_SIZE, τ_sum / N_SEEDS_SIZE)
    end
end

println("\nDone.")
