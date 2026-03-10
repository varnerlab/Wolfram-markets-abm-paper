## Compute-SpatialTheory.jl
#
# Runs lattice simulations across f and measures:
#   1. Potts energy:  E = -Σ_{⟨i,j⟩} δ(σ_i, σ_j) / N_bonds
#   2. Site entropy:  S₁ = -Σ_k ρ_k ln ρ_k
#   3. Pair entropy:  S₂ = -Σ_{a,b} ρ_{ab} ln ρ_{ab}
#   4. Mutual info:   I = 2S₁ - S₂
#   5. Measured pair densities ρ[a,b] (for comparison with pair approximation)
#   6. Sell fraction  (for comparison with phase diagram)
#
# Uses a standalone lean sweep (no Include.jl dependency) for speed.

import Pkg; Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()

using Printf, Statistics, Random, JLD2

# ─── Rule decoding (same as Wolfram.jl) ───────────────────────────────────

"""
    decode_rule(index, ncolors, radius) → Dict{Int,Int}

Decode a Wolfram totalistic rule index into a lookup table.
For a 2D totalistic rule with `ncolors` states and `radius` neighbors,
the neighborhood sum c ranges from 0 to (ncolors-1)*radius.
The rule index is decoded in base `ncolors`.
"""
function decode_rule(index::Int, ncolors::Int, radius::Int)
    max_sum = (ncolors - 1) * radius  # = 8 for 3 colors, 4 neighbors
    D = Dict{Int, Int}()
    val = index
    for c in 0:max_sum
        D[c] = val % ncolors
        val = val ÷ ncolors
    end
    return D
end

# ─── Spatial observables ──────────────────────────────────────────────────

"""
    compute_pair_density(grid, nrows, ncols) → Matrix{Float64}

Measure the nearest-neighbor pair density ρ[a+1, b+1] from the grid.
Counts all horizontal and vertical interior bonds.
"""
function compute_pair_density(grid::Matrix{Int}, nrows::Int, ncols::Int)
    counts = zeros(3, 3)
    nbonds = 0

    # Horizontal bonds (interior)
    @inbounds for r in 2:nrows-1, c in 2:ncols-2
        a, b = grid[r, c], grid[r, c+1]
        counts[a+1, b+1] += 1.0
        counts[b+1, a+1] += 1.0
        nbonds += 2
    end

    # Vertical bonds (interior)
    @inbounds for r in 2:nrows-2, c in 2:ncols-1
        a, b = grid[r, c], grid[r+1, c]
        counts[a+1, b+1] += 1.0
        counts[b+1, a+1] += 1.0
        nbonds += 2
    end

    return counts ./ nbonds
end

"""
    compute_potts_energy(ρ_pair) → Float64

Potts alignment energy per bond from measured pair densities.
E = -Tr(ρ) = -(ρ₀₀ + ρ₁₁ + ρ₂₂).
"""
compute_potts_energy(ρ::Matrix{Float64}) = -(ρ[1,1] + ρ[2,2] + ρ[3,3])

"""
    compute_site_entropy(grid, nrows, ncols) → Float64

Single-site Shannon entropy S₁ = -Σ_k ρ_k ln ρ_k from interior cells.
"""
function compute_site_entropy(grid::Matrix{Int}, nrows::Int, ncols::Int)
    counts = zeros(3)
    n = 0
    @inbounds for r in 2:nrows-1, c in 2:ncols-1
        counts[grid[r,c]+1] += 1.0
        n += 1
    end
    S = 0.0
    for k in 1:3
        p = counts[k] / n
        if p > 1e-15
            S -= p * log(p)
        end
    end
    return S
end

"""
    compute_pair_entropy(ρ_pair) → Float64

Pair entropy S₂ = -Σ_{a,b} ρ_{ab} ln ρ_{ab}.
"""
function compute_pair_entropy(ρ::Matrix{Float64})
    S = 0.0
    for a in 1:3, b in 1:3
        p = ρ[a, b]
        if p > 1e-15
            S -= p * log(p)
        end
    end
    return S
end

"""
    compute_sell_fraction(grid, nrows, ncols) → Float64

Fraction of interior cells in state 2 (Sell).
"""
function compute_sell_fraction(grid::Matrix{Int}, nrows::Int, ncols::Int)
    n_sell = 0
    n_total = 0
    @inbounds for r in 2:nrows-1, c in 2:ncols-1
        n_sell += (grid[r,c] == 2)
        n_total += 1
    end
    return n_sell / n_total
end

# ─── Lean simulation loop ────────────────────────────────────────────────

"""
    run_spatial_sweep(f, nrows, ncols, T_steps; seed) → NamedTuple

Run a pure CA simulation (no edge agents, no price) at minority fraction f,
starting from all-Hold, and compute time-averaged spatial observables.

Uses periodic boundary conditions for the theory analysis
(avoids edge-agent contamination of spatial statistics).
"""
function run_spatial_sweep(f::Float64, nrows::Int, ncols::Int, T_steps::Int;
                           seed::Int = 1234)
    # Decode rules
    D_maj = decode_rule(19280, 3, 4)
    D_min = decode_rule(19286, 3, 4)

    # Assign minority agents
    N = nrows * ncols
    is_min = falses(nrows, ncols)
    if f > 0.0
        rng = Random.MersenneTwister(seed)
        for pos in randperm(rng, N)[1:round(Int, f * N)]
            r = (pos - 1) ÷ ncols + 1
            c = (pos - 1) % ncols + 1
            is_min[r, c] = true
        end
    end

    # Initialize: random state (more informative than all-Hold for equilibrium)
    rng_init = Random.MersenneTwister(seed + 1)
    grid = rand(rng_init, 0:2, nrows, ncols)
    nxt = copy(grid)

    # Burn-in
    T_burn = min(500, T_steps ÷ 2)

    # Accumulators
    sum_energy = 0.0
    sum_S1     = 0.0
    sum_S2     = 0.0
    sum_MI     = 0.0
    sum_sell   = 0.0
    sum_ρ      = zeros(3, 3)
    n_samples  = 0

    for t in 1:(T_burn + T_steps)
        # CA update with periodic BCs
        @inbounds for r in 1:nrows, c in 1:ncols
            # Periodic neighbors
            up    = r == 1     ? nrows : r - 1
            down  = r == nrows ? 1     : r + 1
            left  = c == 1     ? ncols : c - 1
            right = c == ncols ? 1     : c + 1

            csum = grid[up, c] + grid[down, c] + grid[r, left] + grid[r, right]
            D = is_min[r, c] ? D_min : D_maj
            nxt[r, c] = D[csum]
        end
        grid, nxt = nxt, grid

        # Measure after burn-in
        if t > T_burn
            ρ_pair = compute_pair_density(grid, nrows, ncols)
            E  = compute_potts_energy(ρ_pair)
            S1 = compute_site_entropy(grid, nrows, ncols)
            S2 = compute_pair_entropy(ρ_pair)
            MI = 2 * S1 - S2

            sum_energy += E
            sum_S1     += S1
            sum_S2     += S2
            sum_MI     += MI
            sum_sell   += compute_sell_fraction(grid, nrows, ncols)
            sum_ρ     .+= ρ_pair
            n_samples  += 1
        end
    end

    return (
        f            = f,
        energy       = sum_energy / n_samples,
        S1           = sum_S1 / n_samples,
        S2           = sum_S2 / n_samples,
        MI           = sum_MI / n_samples,
        sell_frac    = sum_sell / n_samples,
        ρ_pair       = sum_ρ ./ n_samples,
    )
end


# ═══════════════════════════════════════════════════════════════════════════
# Main sweep
# ═══════════════════════════════════════════════════════════════════════════

const NROWS  = 128
const NCOLS  = 128
const TSTEPS = 2000

println("=" ^ 70)
println("  Lattice Spatial Theory Analysis: 19280/19286 mixture")
println("  Grid: $(NROWS)×$(NCOLS), T=$(TSTEPS) steps (+ 500 burn-in)")
println("  Periodic BCs (no edge agents)")
println("=" ^ 70)

fs = vcat(0.0:0.01:0.10, 0.11:0.005:0.20, 0.21:0.01:0.30, 0.35:0.05:0.50)
sort!(unique!(fs))

results = Dict{Float64, NamedTuple}()

println("\n  f     │ Sell frac │ Energy   │ S₁       │ MI       │ ρ₀₀     │ ρ₂₂")
println("────────┼──────────┼──────────┼──────────┼──────────┼─────────┼─────────")

for f in fs
    r = run_spatial_sweep(f, NROWS, NCOLS, TSTEPS)
    results[f] = r
    @printf("  %.3f │  %.4f  │ %+.4f  │  %.4f  │  %.4f  │ %.4f  │ %.4f\n",
            f, r.sell_frac, r.energy, r.S1, r.MI, r.ρ_pair[1,1], r.ρ_pair[3,3])
end

# ─── Save results ─────────────────────────────────────────────────────────
outpath = joinpath(@__DIR__, "..", "data", "SpatialTheory-PhaseSweep.jld2")
save(outpath, Dict(
    "fs"      => fs,
    "results" => results,
    "nrows"   => NROWS,
    "ncols"   => NCOLS,
    "tsteps"  => TSTEPS,
))
@info "Saved: $outpath"

# ─── Summary ──────────────────────────────────────────────────────────────
println("\n" * "=" ^ 70)
println("  Summary")
println("=" ^ 70)

sell_fracs = [results[f].sell_frac for f in fs]
energies   = [results[f].energy for f in fs]
MIs        = [results[f].MI for f in fs]

# Find transition
if maximum(sell_fracs) > 0.50
    idx = findfirst(x -> x > 0.50, sell_fracs)
    @printf("\nLattice transition: sell > 0.50 at f ≈ %.3f\n", fs[idx])
end

# Energy discontinuity
dE = diff(energies)
idx_E = argmax(abs.(dE))
@printf("Largest energy jump: |ΔE| = %.4f between f=%.3f and f=%.3f\n",
        abs(dE[idx_E]), fs[idx_E], fs[idx_E+1])

# MI drop
dMI = diff(MIs)
idx_MI = argmax(abs.(dMI))
@printf("Largest MI change:   |ΔI| = %.4f between f=%.3f and f=%.3f\n",
        abs(dMI[idx_MI]), fs[idx_MI], fs[idx_MI+1])

println("\nDone.")
