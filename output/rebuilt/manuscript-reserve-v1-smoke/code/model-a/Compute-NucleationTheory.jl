## Compute-NucleationTheory.jl  (v2)
#
# Nucleation theory for the 19280/19286 transition.
#
# KEY INSIGHT: Rule 19280 at c=0 → Sell. So all-buy is UNSTABLE.
# The "buy-dominated" phase is a dynamic mixed attractor:
#   ~50% Buy, ~30% Hold, ~20% Sell
# The transition is: mixed attractor → all-sell absorbing state.
#
# Approach:
#   1. Characterize the mixed steady state vs f
#   2. Measure mixed-state lifetime (how long before collapse to all-sell)
#   3. Sell cluster analysis: size distribution vs f
#   4. Perturb mixed state with sell droplets → find critical droplet size
#   5. Percolation analysis of contrarian agent influence zones

import Pkg; Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()

using Printf, Statistics, Random

# ─── Rule decoding ────────────────────────────────────────────────────────
function decode_rule(index::Int, ncolors::Int, radius::Int)
    max_sum = (ncolors - 1) * radius
    D = Dict{Int, Int}()
    val = index
    for c in 0:max_sum
        D[c] = val % ncolors
        val = val ÷ ncolors
    end
    return D
end

const D_MAJ = decode_rule(19280, 3, 4)
const D_MIN = decode_rule(19286, 3, 4)

# ─── CA step with periodic BCs ───────────────────────────────────────────
function ca_step!(grid::Matrix{Int}, nxt::Matrix{Int},
                  is_min::BitMatrix, nrows::Int, ncols::Int)
    @inbounds for r in 1:nrows, c in 1:ncols
        up    = r == 1     ? nrows : r - 1
        down  = r == nrows ? 1     : r + 1
        left  = c == 1     ? ncols : c - 1
        right = c == ncols ? 1     : c + 1
        csum = grid[up, c] + grid[down, c] + grid[r, left] + grid[r, right]
        D = is_min[r, c] ? D_MIN : D_MAJ
        nxt[r, c] = D[csum]
    end
end

function sell_fraction(grid::Matrix{Int})
    return count(==(2), grid) / length(grid)
end

function state_fractions(grid::Matrix{Int})
    N = length(grid)
    p0 = count(==(0), grid) / N
    p1 = count(==(1), grid) / N
    p2 = count(==(2), grid) / N
    return p0, p1, p2
end

function potts_energy_per_bond(grid::Matrix{Int}, nrows::Int, ncols::Int)
    E = 0
    @inbounds for r in 1:nrows, c in 1:ncols
        right = c == ncols ? 1 : c + 1
        down  = r == nrows ? 1 : r + 1
        E -= (grid[r, c] == grid[r, right]) + (grid[r, c] == grid[down, c])
    end
    return E / (2 * nrows * ncols)
end

function assign_minority!(is_min::BitMatrix, f::Float64, nrows::Int, ncols::Int, seed::Int)
    fill!(is_min, false)
    if f > 0.0
        N = nrows * ncols
        rng = Random.MersenneTwister(seed)
        for pos in randperm(rng, N)[1:round(Int, f * N)]
            r = (pos - 1) ÷ ncols + 1
            c = (pos - 1) % ncols + 1
            is_min[r, c] = true
        end
    end
end

# ─── Equilibrate to mixed steady state ────────────────────────────────────
function equilibrate!(grid::Matrix{Int}, nxt::Matrix{Int},
                      is_min::BitMatrix, nrows::Int, ncols::Int, T_burn::Int)
    for _ in 1:T_burn
        ca_step!(grid, nxt, is_min, nrows, ncols)
        grid, nxt = nxt, grid
    end
    return grid, nxt
end


# ═══════════════════════════════════════════════════════════════════════════
# 1. VERIFY: Mixed state stability and lifetime
# ═══════════════════════════════════════════════════════════════════════════

println("=" ^ 70)
println("  1. Mixed State Stability")
println("=" ^ 70)

println("\n  Verifying the mixed attractor is stable (f=0, random IC, long run)")
let
    L = 128
    grid = rand(Random.MersenneTwister(42), 0:2, L, L)
    nxt = copy(grid)
    is_min = falses(L, L)

    println("  Step    │ p₀(Buy) │ p₁(Hold) │ p₂(Sell) │ Energy")
    println("──────────┼─────────┼──────────┼──────────┼─────────")
    for t in 1:10000
        ca_step!(grid, nxt, is_min, L, L)
        grid, nxt = nxt, grid
        if t in [1, 2, 5, 10, 50, 100, 500, 1000, 2000, 5000, 10000]
            p0, p1, p2 = state_fractions(grid)
            E = potts_energy_per_bond(grid, L, L)
            @printf("  %5d   │  %.4f │  %.4f  │  %.4f  │ %.4f\n", t, p0, p1, p2, E)
        end
    end
end

# ═══════════════════════════════════════════════════════════════════════════
# 2. MIXED-STATE LIFETIME vs f
# ═══════════════════════════════════════════════════════════════════════════

println("\n" * "=" ^ 70)
println("  2. Mixed-State Lifetime vs f")
println("=" ^ 70)

println("\n  Starting from random IC, measuring when sell_frac first exceeds 0.90")
println("  (Multiple seeds for statistics)")

const L_LIFE = 64   # smaller grid for faster lifetimes
const T_MAX  = 50000
const N_SEEDS = 10

println("\n  f     │ Mean lifetime │ Std lifetime │ Min      │ Max      │ Survived")
println("────────┼───────────────┼──────────────┼──────────┼──────────┼─────────")

for f in [0.0, 0.05, 0.10, 0.12, 0.13, 0.14, 0.145, 0.15, 0.155, 0.16, 0.165, 0.17, 0.18, 0.20, 0.25]
    lifetimes = Int[]
    survived = 0

    for s in 1:N_SEEDS
        grid = rand(Random.MersenneTwister(1000 + s), 0:2, L_LIFE, L_LIFE)
        nxt = copy(grid)
        is_min = falses(L_LIFE, L_LIFE)
        assign_minority!(is_min, f, L_LIFE, L_LIFE, 5000 + s)

        # Burn-in to mixed state
        grid, nxt = equilibrate!(grid, nxt, is_min, L_LIFE, L_LIFE, 200)

        # Measure lifetime
        lifetime = T_MAX
        for t in 1:T_MAX
            ca_step!(grid, nxt, is_min, L_LIFE, L_LIFE)
            grid, nxt = nxt, grid
            if sell_fraction(grid) > 0.90
                lifetime = t
                break
            end
        end

        if lifetime == T_MAX
            survived += 1
        end
        push!(lifetimes, lifetime)
    end

    μ = mean(lifetimes)
    σ = N_SEEDS > 1 ? std(lifetimes) : 0.0
    @printf("  %.3f │    %8.0f   │   %8.0f   │  %6d  │  %6d  │  %d/%d\n",
            f, μ, σ, minimum(lifetimes), maximum(lifetimes), survived, N_SEEDS)
end


# ═══════════════════════════════════════════════════════════════════════════
# 3. SELL CLUSTER SIZE DISTRIBUTION
# ═══════════════════════════════════════════════════════════════════════════

println("\n" * "=" ^ 70)
println("  3. Sell Cluster Size Distribution")
println("=" ^ 70)

"""
    find_sell_clusters(grid, nrows, ncols) → Vector{Int}

Find connected components of sell (state=2) cells using BFS.
Returns a vector of cluster sizes.
"""
function find_sell_clusters(grid::Matrix{Int}, nrows::Int, ncols::Int)
    visited = falses(nrows, ncols)
    clusters = Int[]

    for r in 1:nrows, c in 1:ncols
        if grid[r, c] == 2 && !visited[r, c]
            # BFS
            queue = [(r, c)]
            visited[r, c] = true
            size = 0
            while !isempty(queue)
                cr, cc = popfirst!(queue)
                size += 1
                for (dr, dc) in [(-1,0),(1,0),(0,-1),(0,1)]
                    nr = cr + dr
                    nc = cc + dc
                    # Periodic BCs
                    nr = nr < 1 ? nrows : (nr > nrows ? 1 : nr)
                    nc = nc < 1 ? ncols : (nc > ncols ? 1 : nc)
                    if grid[nr, nc] == 2 && !visited[nr, nc]
                        visited[nr, nc] = true
                        push!(queue, (nr, nc))
                    end
                end
            end
            push!(clusters, size)
        end
    end
    return clusters
end

println("\n  Measuring sell cluster statistics in the mixed state")
println("  (128×128, equilibrated 500 steps, averaged over 100 snapshots)")

const L_CLUST = 128

println("\n  f     │ <n_clust> │ <max_clust> │ <mean_size> │ Max ever │ p₂")
println("────────┼───────────┼─────────────┼─────────────┼──────────┼──────")

for f in [0.0, 0.05, 0.10, 0.12, 0.13, 0.14, 0.145, 0.15, 0.155, 0.16]
    grid = rand(Random.MersenneTwister(42), 0:2, L_CLUST, L_CLUST)
    nxt = copy(grid)
    is_min = falses(L_CLUST, L_CLUST)
    assign_minority!(is_min, f, L_CLUST, L_CLUST, 1234)

    grid, nxt = equilibrate!(grid, nxt, is_min, L_CLUST, L_CLUST, 500)

    n_clust_sum = 0.0
    max_clust_sum = 0.0
    mean_size_sum = 0.0
    max_ever = 0
    p2_sum = 0.0
    n_snap = 100

    for snap in 1:n_snap
        # Run 10 steps between snapshots
        for _ in 1:10
            ca_step!(grid, nxt, is_min, L_CLUST, L_CLUST)
            grid, nxt = nxt, grid
        end

        clusters = find_sell_clusters(grid, L_CLUST, L_CLUST)
        if !isempty(clusters)
            n_clust_sum += length(clusters)
            max_clust_sum += maximum(clusters)
            mean_size_sum += mean(clusters)
            max_ever = max(max_ever, maximum(clusters))
        end
        p2_sum += sell_fraction(grid)
    end

    @printf("  %.3f │  %7.0f  │    %7.0f   │    %7.1f   │  %6d  │ %.4f\n",
            f, n_clust_sum/n_snap, max_clust_sum/n_snap, mean_size_sum/n_snap,
            max_ever, p2_sum/n_snap)
end


# ═══════════════════════════════════════════════════════════════════════════
# 4. CRITICAL DROPLET in the MIXED STATE
# ═══════════════════════════════════════════════════════════════════════════

println("\n" * "=" ^ 70)
println("  4. Critical Sell Droplet in Mixed State")
println("=" ^ 70)

println("\n  Equilibrate to mixed state, then plant sell droplet, measure outcome")
println("  128×128 grid")

println("\n  f     │ R  │ Pre-SF  │ Post-SF │ Δ(SF)   │ Collapsed?")
println("────────┼────┼─────────┼─────────┼─────────┼───────────")

for f in [0.0, 0.05, 0.10, 0.12, 0.14, 0.145, 0.15, 0.155, 0.16]
    for R in [3, 6, 10, 16, 24]
        grid = rand(Random.MersenneTwister(42), 0:2, 128, 128)
        nxt = copy(grid)
        is_min = falses(128, 128)
        assign_minority!(is_min, f, 128, 128, 1234)

        # Equilibrate
        grid, nxt = equilibrate!(grid, nxt, is_min, 128, 128, 500)
        pre_sf = sell_fraction(grid)

        # Plant sell droplet at center
        cr, cc = 64, 64
        for r in 1:128, c in 1:128
            if (r - cr)^2 + (c - cc)^2 <= R^2
                grid[r, c] = 2
            end
        end

        # Run 2000 more steps
        for _ in 1:2000
            ca_step!(grid, nxt, is_min, 128, 128)
            grid, nxt = nxt, grid
        end
        post_sf = sell_fraction(grid)
        collapsed = post_sf > 0.90

        @printf("  %.3f │ %2d │  %.4f │  %.4f │ %+.4f │ %s\n",
                f, R, pre_sf, post_sf, post_sf - pre_sf,
                collapsed ? "YES" : "no")
    end
end


# ═══════════════════════════════════════════════════════════════════════════
# 5. CONTRARIAN INFLUENCE ZONES
# ═══════════════════════════════════════════════════════════════════════════

println("\n" * "=" ^ 70)
println("  5. Contrarian Agent Influence Zones")
println("=" ^ 70)

println("\n  Single contrarian in center of 64×64 all-majority grid")
println("  Starting from random IC, measuring sell excess near contrarian")

let
    L = 65  # odd, so center is (33,33)
    cr, cc = 33, 33

    for f_local in [0.0]  # just the single contrarian
        grid = rand(Random.MersenneTwister(42), 0:2, L, L)
        nxt = copy(grid)
        is_min = falses(L, L)
        is_min[cr, cc] = true  # single contrarian at center

        # Equilibrate
        grid, nxt = equilibrate!(grid, nxt, is_min, L, L, 500)

        # Measure radial sell density profile (averaged over 200 snapshots)
        max_r = 20
        sell_by_r = zeros(max_r + 1)
        count_by_r = zeros(max_r + 1)

        for _ in 1:200
            for _ in 1:5
                ca_step!(grid, nxt, is_min, L, L)
                grid, nxt = nxt, grid
            end
            for r in 1:L, c in 1:L
                d = round(Int, sqrt((r - cr)^2 + (c - cc)^2))
                if d <= max_r
                    sell_by_r[d+1] += (grid[r, c] == 2)
                    count_by_r[d+1] += 1
                end
            end
        end

        println("\n  Distance │ Sell density │ # cells │ Excess over background")
        println("───────────┼──────────────┼─────────┼──────────────────────")
        bg = sell_by_r[end] / count_by_r[end]
        for d in 0:max_r
            if count_by_r[d+1] > 0
                sd = sell_by_r[d+1] / count_by_r[d+1]
                @printf("     %2d    │    %.4f    │  %5.0f  │   %+.4f\n",
                        d, sd, count_by_r[d+1], sd - bg)
            end
        end
    end
end

println("\nDone.")
