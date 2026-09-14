## Pair Approximation for the 19280/19286 rule mixture on 2D lattice
#
# Extends the single-site mean-field (MeanField.jl) by tracking
# nearest-neighbor pair densities ρ[a,b] rather than just marginals ρ_a.
#
# Key idea: the conditional distribution of a site's neighbors given its
# own state captures spatial correlations that mean-field misses.
# In the pair approximation closure, the 3 "other" neighbors of a focal
# site (excluding the paired neighbor) are drawn independently from
# q(s|a) = ρ[a,s] / ρ_a.
#
# This should recover the phase transition at f_c that mean-field cannot see.
#
# Verified rule tables:
#   c:     0  1  2  3  4  5  6  7  8
#   19280: 2  0  0  0  1  1  2  2  2
#   19286: 2  2  0  0  1  1  2  2  2
#
# Effective rule (annealed disorder at fraction f):
#   c = 1 → Buy(0) w.p. (1-f),  Sell(2) w.p. f
#   all other c: deterministic (same for both rules)

using Printf

# ─── Include guard ────────────────────────────────────────────────────────
# When this file is included from another script that has already defined
# `_PAIRAPPROX_SKIP_ANALYSES` (e.g. Figs-ModelA-Theory.jl, which reuses the
# function definitions below), the console analyses are skipped. Standalone
# execution (`julia code/model-a/PairApproximation.jl`) is unchanged.
_run_pair_analyses = !@isdefined(_PAIRAPPROX_SKIP_ANALYSES)

# ─── Rule tables ──────────────────────────────────────────────────────────
const RULE_19280 = [2, 0, 0, 0, 1, 1, 2, 2, 2]   # RULE_19280[c+1] = output
const RULE_19286 = [2, 2, 0, 0, 1, 1, 2, 2, 2]

"""
    effective_rule(f) → R[c+1, s+1]

Effective rule output probability matrix. R[c+1, s+1] = Pr(output = s | sum = c).
For c ≠ 1 this is deterministic; for c = 1 it's a (1-f, 0, f) mixture.
"""
function effective_rule(f::Float64)
    R = zeros(9, 3)
    for c in 0:8
        out_maj = RULE_19280[c+1]
        out_min = RULE_19286[c+1]
        if out_maj == out_min
            R[c+1, out_maj+1] = 1.0
        else  # c = 1 only: maj→Buy(0), min→Sell(2)
            R[c+1, 1] = 1.0 - f   # → Buy
            R[c+1, 3] = f          # → Sell
        end
    end
    return R
end

# ─── Trinomial sum distribution ───────────────────────────────────────────
"""
    trinomial_sum_dist(n, q0, q1, q2) → Vector{Float64}

Distribution of X = σ₁ + σ₂ + ... + σₙ where each σᵢ ∈ {0,1,2}
with Pr(σ=0)=q0, Pr(σ=1)=q1, Pr(σ=2)=q2.
Returns dist[k+1] = Pr(X = k) for k = 0, ..., 2n.
"""
function trinomial_sum_dist(n::Int, q0::Float64, q1::Float64, q2::Float64)
    dist = zeros(2n + 1)
    for n0 in 0:n, n1 in 0:(n - n0)
        n2 = n - n0 - n1
        k = n1 + 2 * n2
        coeff = factorial(n) / (factorial(n0) * factorial(n1) * factorial(n2))
        dist[k+1] += coeff * q0^n0 * q1^n1 * q2^n2
    end
    return dist
end

# ─── Pair approximation step ─────────────────────────────────────────────
"""
    pair_step(ρ, f) → ρ_new

One synchronous update of the pair density matrix under the pair approximation.

ρ[a+1, b+1] = density of nearest-neighbor pairs with states (a, b).

Update rule:
    ρ'[b, b'] = Σ_{a,a'} ρ[a,a'] · T_b(a,a') · T_{b'}(a',a)

where T_b(a, a') = Pr(site → b | center=a, paired neighbor=a')
and the 3 non-paired neighbors are drawn from q(s|a) = ρ[a,s]/ρ_a.
"""
function pair_step(ρ::Matrix{Float64}, f::Float64)
    # Marginals: ρ_a = Σ_b ρ[a,b]
    ρ_marg = zeros(3)
    for a in 0:2
        ρ_marg[a+1] = sum(ρ[a+1, :])
    end

    # Conditional neighbor distribution: q[s+1, a+1] = P(neighbor=s | center=a)
    q = zeros(3, 3)
    for a in 0:2
        if ρ_marg[a+1] > 1e-15
            for s in 0:2
                q[s+1, a+1] = ρ[a+1, s+1] / ρ_marg[a+1]
            end
        else
            q[:, a+1] .= 1.0 / 3.0
        end
    end

    R = effective_rule(f)

    # Precompute trinomial sum distributions for each center state a
    # X ~ trinomial(3, q[·|a]): sum of 3 i.i.d. draws, range 0..6
    Xdist = Matrix{Float64}(undef, 7, 3)   # Xdist[x+1, a+1]
    for a in 0:2
        d = trinomial_sum_dist(3, q[1, a+1], q[2, a+1], q[3, a+1])
        Xdist[:, a+1] = d
    end

    # Transition probability: T[b+1, a+1, ap+1] = P(site→b | center=a, pair neighbor=a')
    # c_i = a' + X where X ~ trinomial(3, q[·|a])
    T = zeros(3, 3, 3)
    for a in 0:2, ap in 0:2
        for b in 0:2
            prob = 0.0
            for x in 0:6
                c = ap + x
                if c <= 8
                    prob += Xdist[x+1, a+1] * R[c+1, b+1]
                end
            end
            T[b+1, a+1, ap+1] = prob
        end
    end

    # New pair density: ρ'[b, b'] = Σ_{a,a'} ρ[a,a'] T_b(a,a') T_{b'}(a',a)
    ρ_new = zeros(3, 3)
    for b in 0:2, bp in 0:2
        val = 0.0
        for a in 0:2, ap in 0:2
            val += ρ[a+1, ap+1] * T[b+1, a+1, ap+1] * T[bp+1, ap+1, a+1]
        end
        ρ_new[b+1, bp+1] = val
    end

    # Symmetrize (numerical safety) and normalize
    ρ_new = 0.5 * (ρ_new + ρ_new')
    ρ_new ./= sum(ρ_new)

    return ρ_new
end

# ─── Iterate to steady state ─────────────────────────────────────────────
function pair_steady(f::Float64;
                     ρ_init::Union{Nothing, Matrix{Float64}} = nothing,
                     maxiter::Int = 200_000,
                     tol::Float64 = 1e-12)
    if isnothing(ρ_init)
        # Initialize: buy-biased uncorrelated state
        p = [0.50, 0.30, 0.20]
        ρ = zeros(3, 3)
        for a in 0:2, b in 0:2
            ρ[a+1, b+1] = p[a+1] * p[b+1]
        end
    else
        ρ = copy(ρ_init)
    end

    for iter in 1:maxiter
        ρ_new = pair_step(ρ, f)
        if maximum(abs.(ρ_new .- ρ)) < tol
            return ρ_new, iter, true
        end
        ρ = ρ_new
    end
    @warn "Pair approximation did not converge at f=$f after $maxiter iterations"
    return ρ, maxiter, false
end

# ─── Potts energy from pair densities ─────────────────────────────────────
"""
    potts_energy(ρ) → Float64

Potts alignment energy per bond: e = -Σ_a ρ[a,a] = -Tr(ρ).
Ranges from -1 (fully aligned) to ~-1/3 (random).
"""
potts_energy(ρ::Matrix{Float64}) = -sum(ρ[a+1, a+1] for a in 0:2)

# ─── Entropy measures from pair densities ─────────────────────────────────
"""
    site_entropy(ρ) → Float64

Single-site Shannon entropy S₁ = -Σ_a ρ_a ln ρ_a.
"""
function site_entropy(ρ::Matrix{Float64})
    ρ_marg = [sum(ρ[a+1, :]) for a in 0:2]
    S = 0.0
    for a in 0:2
        p = ρ_marg[a+1]
        if p > 1e-15
            S -= p * log(p)
        end
    end
    return S
end

"""
    pair_entropy(ρ) → Float64

Pair Shannon entropy S₂ = -Σ_{a,b} ρ[a,b] ln ρ[a,b].
"""
function pair_entropy(ρ::Matrix{Float64})
    S = 0.0
    for a in 0:2, b in 0:2
        p = ρ[a+1, b+1]
        if p > 1e-15
            S -= p * log(p)
        end
    end
    return S
end

"""
    mutual_information(ρ) → Float64

Spatial mutual information I = 2S₁ - S₂.
Measures excess correlation between nearest neighbors.
I = 0 for uncorrelated states; I > 0 indicates spatial structure.
"""
mutual_information(ρ::Matrix{Float64}) = 2 * site_entropy(ρ) - pair_entropy(ρ)


# ═══════════════════════════════════════════════════════════════════════════
# Main: Pair approximation with stability analysis
# ═══════════════════════════════════════════════════════════════════════════

if _run_pair_analyses  # (include guard: see top of file)
println("=" ^ 70)
println("  Pair Approximation — Stability & Correlated IC Analysis")
println("=" ^ 70)
end

# ─── Mean-field (for comparison) ──────────────────────────────────────────
function pi_distribution(p0, p1, p2)
    π = zeros(9)
    for n0 in 0:4, n1 in 0:(4 - n0)
        n2 = 4 - n0 - n1
        c = n1 + 2 * n2
        coeff = factorial(4) / (factorial(n0) * factorial(n1) * factorial(n2))
        π[c+1] += coeff * p0^n0 * p1^n1 * p2^n2
    end
    return π
end

function mf_step(p0, p2, f)
    p1 = 1.0 - p0 - p2
    π = pi_distribution(p0, p1, p2)
    new_p0 = (1 - f) * π[2] + π[3] + π[4]
    new_p2 = π[1] + f * π[2] + π[7] + π[8] + π[9]
    return new_p0, new_p2
end

function mf_steady(f; p0_init = 0.50, p2_init = 0.20, maxiter = 200_000, tol = 1e-14)
    p0, p2 = p0_init, p2_init
    for _ in 1:maxiter
        np0, np2 = mf_step(p0, p2, f)
        if abs(np0 - p0) + abs(np2 - p2) < tol
            return np0, np2
        end
        p0, p2 = np0, np2
    end
    return p0, p2
end

# ─── Build correlated initial conditions ──────────────────────────────────
"""
    correlated_init(p, ε) → Matrix{Float64}

Build a pair density matrix from marginals p = [p0, p1, p2] with
excess same-state correlation ε:
    ρ[a,b] = p_a p_b + ε · (δ_{ab} · p_a - p_a p_b)

At ε=0: uncorrelated (mean-field).
At ε=1: maximum correlation (ρ[a,b] = p_a δ_{ab}).
"""
function correlated_init(p::Vector{Float64}, ε::Float64)
    ρ = zeros(3, 3)
    for a in 0:2, b in 0:2
        ρ[a+1, b+1] = p[a+1] * p[b+1] + ε * ((a == b ? p[a+1] : 0.0) - p[a+1] * p[b+1])
    end
    # Ensure valid probabilities
    ρ = max.(ρ, 0.0)
    ρ ./= sum(ρ)
    return ρ
end

# ═══════════════════════════════════════════════════════════════════════════
# Analysis 1: Stability of the uncorrelated fixed point
# ═══════════════════════════════════════════════════════════════════════════

if _run_pair_analyses  # (include guard: see top of file)
println("\n─── Analysis 1: Stability of uncorrelated FP ───")
println("  Perturbing MF fixed point with ε = 0.01 same-state correlation")
println("  Tracking whether MI grows (unstable) or decays (stable)\n")

println("  f     │ MF p₂    │ MI(t=0)  │ MI(t=1)  │ MI(t=10) │ MI(t=100)│ MI(∞)    │ Status")
println("────────┼──────────┼──────────┼──────────┼──────────┼──────────┼──────────┼────────")

fs_test = 0.0:0.01:0.50
ε_pert = 0.01

for f in fs_test
    # Get MF fixed point
    p0_mf, p2_mf = mf_steady(f)
    p_mf = [p0_mf, 1.0 - p0_mf - p2_mf, p2_mf]

    # Perturbed initial condition
    ρ = correlated_init(p_mf, ε_pert)
    MI_0 = mutual_information(ρ)

    # Track MI over iterations
    MI_1 = MI_10 = MI_100 = MI_final = 0.0

    for t in 1:500
        ρ = pair_step(ρ, f)
        if t == 1;   MI_1   = mutual_information(ρ); end
        if t == 10;  MI_10  = mutual_information(ρ); end
        if t == 100; MI_100 = mutual_information(ρ); end
    end
    MI_final = mutual_information(ρ)

    # Classify: growing MI = unstable
    status = MI_final > MI_0 ? "UNSTABLE" :
             MI_final > 0.1 * MI_0 ? "marginal" : "stable"

    @printf("  %.2f  │  %.4f  │ %.6f │ %.6f │ %.6f │ %.6f │ %.6f │ %s\n",
            f, p2_mf, MI_0, MI_1, MI_10, MI_100, MI_final, status)
end
end  # if _run_pair_analyses

# ═══════════════════════════════════════════════════════════════════════════
# Analysis 2: Search for correlated fixed points
# ═══════════════════════════════════════════════════════════════════════════

if _run_pair_analyses  # (include guard: see top of file)
println("\n─── Analysis 2: Search for correlated fixed points ───")
println("  Trying multiple ICs with strong correlations (ε = 0.1, 0.3, 0.5)")
println("  and sell-biased ICs\n")

println("  f     │ ε    │ IC p₂   │ Final p₂ │ Final MI  │ Final E   │ Iters  │ Type")
println("────────┼──────┼─────────┼──────────┼───────────┼───────────┼────────┼──────────")

fs_search = [0.0, 0.05, 0.10, 0.12, 0.14, 0.145, 0.15, 0.16, 0.18, 0.20, 0.25, 0.30, 0.50]

for f in fs_search
    for (ε, p_init, label) in [
        (0.1,  [0.50, 0.30, 0.20], "buy-bias"),
        (0.3,  [0.50, 0.30, 0.20], "buy-corr"),
        (0.5,  [0.50, 0.30, 0.20], "buy-str"),
        (0.1,  [0.20, 0.10, 0.70], "sell-bias"),
        (0.3,  [0.20, 0.10, 0.70], "sell-corr"),
        (0.5,  [0.10, 0.05, 0.85], "sell-str"),
        (0.0,  [0.33, 0.34, 0.33], "uniform"),
    ]
        ρ = correlated_init(p_init, ε)
        ρ_final, iters, converged = pair_steady(f; ρ_init = ρ, maxiter = 50_000)
        ρ_marg = [sum(ρ_final[a+1, :]) for a in 0:2]
        MI = mutual_information(ρ_final)
        E  = potts_energy(ρ_final)

        @printf("  %.3f │ %.1f  │  %.2f   │  %.4f  │ %+.6f  │ %+.4f   │ %5d  │ %s\n",
                f, ε, p_init[3], ρ_marg[3], MI, E, iters, label)
    end
end
end  # if _run_pair_analyses

# ═══════════════════════════════════════════════════════════════════════════
# Analysis 3: Eigenvalue of the linearized pair map at the uncorrelated FP
# ═══════════════════════════════════════════════════════════════════════════

if _run_pair_analyses  # (include guard: see top of file)
println("\n─── Analysis 3: Spectral radius of pair map Jacobian ───")
println("  Numerical Jacobian of pair_step at the MF fixed point")
println("  (restricted to the 6-dimensional pair density space)\n")
end

using LinearAlgebra

"""
    ρ_to_vec(ρ) → Vector{Float64}

Flatten upper triangle of 3×3 symmetric pair density to 6-vector:
[ρ₀₀, ρ₀₁, ρ₀₂, ρ₁₁, ρ₁₂, ρ₂₂]
"""
function ρ_to_vec(ρ::Matrix{Float64})
    return [ρ[1,1], ρ[1,2], ρ[1,3], ρ[2,2], ρ[2,3], ρ[3,3]]
end

"""
    vec_to_ρ(v) → Matrix{Float64}

Reconstruct 3×3 symmetric pair density from 6-vector.
"""
function vec_to_ρ(v::Vector{Float64})
    ρ = zeros(3, 3)
    ρ[1,1] = v[1]; ρ[1,2] = v[2]; ρ[1,3] = v[3]
    ρ[2,1] = v[2]; ρ[2,2] = v[4]; ρ[2,3] = v[5]
    ρ[3,1] = v[3]; ρ[3,2] = v[5]; ρ[3,3] = v[6]
    return ρ
end

"""
    numerical_jacobian(f, ρ_fp; δ) → Matrix{Float64}

6×6 Jacobian of the pair map at fixed point ρ_fp, computed by finite differences.
"""
function numerical_jacobian(f_val::Float64, ρ_fp::Matrix{Float64}; δ = 1e-7)
    v_fp = ρ_to_vec(ρ_fp)
    f_fp = ρ_to_vec(pair_step(ρ_fp, f_val))
    J = zeros(6, 6)
    for j in 1:6
        v_pert = copy(v_fp)
        v_pert[j] += δ
        # Renormalize to stay on the simplex
        ρ_pert = vec_to_ρ(v_pert)
        ρ_pert = max.(ρ_pert, 0.0)
        ρ_pert ./= sum(ρ_pert)
        f_pert = ρ_to_vec(pair_step(ρ_pert, f_val))
        J[:, j] = (f_pert .- f_fp) ./ δ
    end
    return J
end

if _run_pair_analyses  # (include guard: see top of file)
println("  f     │ Spectral radius │ Max |λ| (non-trivial) │ Dominant mode")
println("────────┼─────────────────┼───────────────────────┼──────────────")

for f in [0.0, 0.05, 0.10, 0.12, 0.14, 0.145, 0.15, 0.16, 0.18, 0.20, 0.30, 0.50]
    p0_mf, p2_mf = mf_steady(f)
    p_mf = [p0_mf, 1.0 - p0_mf - p2_mf, p2_mf]

    # Uncorrelated fixed point
    ρ_fp = zeros(3, 3)
    for a in 0:2, b in 0:2
        ρ_fp[a+1, b+1] = p_mf[a+1] * p_mf[b+1]
    end

    J = numerical_jacobian(f, ρ_fp)
    λs = eigvals(J)
    mags = abs.(λs)
    sr = maximum(mags)

    # Sort by magnitude
    sorted_idx = sortperm(mags, rev = true)
    λ_dom = λs[sorted_idx[1]]

    @printf("  %.3f │      %.6f   │        %.6f       │ %+.4f %+.4fi\n",
            f, sr, mags[sorted_idx[2]], real(λ_dom), imag(λ_dom))
end

println("\nIf spectral radius > 1 at some f, the uncorrelated FP is unstable")
println("and correlations grow → pair approximation predicts a transition.")
println("\nDone.")
end  # if _run_pair_analyses
