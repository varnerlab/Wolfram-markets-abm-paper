# BoundaryVsBulk-Lib.jl — pure helpers for the boundary-vs-bulk seeding
# analysis (spec: docs/superpowers/specs/2026-07-17-boundary-vs-bulk-seeding-design.md).
# Included by Compute-ModelB-BoundaryVsBulk.jl and Test-BoundaryVsBulk.jl;
# depends only on packages already loaded by model-b/Include.jl.

"""Chebyshev distance from (r, c) to the grid frame; boundary cells → 0."""
function chebyshev_boundary_distance(r::Int, c::Int, nr::Int, nc::Int)::Int
    return min(r - 1, nr - r, c - 1, nc - c)
end

"""
    null_shell_pmf(gridn) → Vector{Float64}

P(d = j) for a uniform draw on the (gridn−2)×(gridn−2) interior; cells with
d ≥ j form a square of side gridn − 2j, so
count(d = j) = (gridn − 2j)² − (gridn − 2 − 2j)², j = 1..gridn÷2−1.
"""
function null_shell_pmf(gridn::Int)::Vector{Float64}
    n_int = (gridn - 2)^2
    jmax  = gridn ÷ 2 - 1
    return [((gridn - 2j)^2 - (gridn - 2 - 2j)^2) / n_int for j in 1:jmax]
end

"""Exact two-sided binomial test: sum of pmf(j) ≤ pmf(k) under Binomial(n, p)."""
function binom_two_sided_p(n::Int, k::Int, p::Float64)::Float64
    d  = Binomial(n, p)
    pk = pdf(d, k)
    return sum(pdf(d, j) for j in 0:n if pdf(d, j) <= pk * (1 + 1e-12))
end

"""Patch side from the pooled median birth size: the odd s ∈ {3, 5} whose
square is closest to m; tie → 3 (spec §2)."""
function patch_side(m::Real)::Int
    return abs(m - 9) <= abs(m - 25) ? 3 : 5
end
