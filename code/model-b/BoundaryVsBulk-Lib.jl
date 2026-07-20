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

"""
    label_interior_sell_clusters(grid) → (labels, sizes)

BFS 4-neighbour connected components of Sell (state 2) cells, INTERIOR ONLY
(rows/cols 2..N−1). Ring cells are exogenously band-driven, so counting them
would conflate forcing with response (spec, shared configuration). Labels are
assigned in row-major discovery order; sizes[l] is cluster l's cell count.
"""
function label_interior_sell_clusters(grid::Matrix{Int64})::Tuple{Matrix{Int16}, Vector{Int}}
    nr, nc = size(grid)
    labels = zeros(Int16, nr, nc)
    sizes  = Int[]
    nextl  = Int16(0)
    for r in 2:nr-1, c in 2:nc-1
        (grid[r, c] == 2 && labels[r, c] == 0) || continue
        nextl += Int16(1)
        sz    = 0
        queue = [(r, c)]
        labels[r, c] = nextl
        while !isempty(queue)
            cr, cc = popfirst!(queue)
            sz += 1
            for (dr, dc) in ((-1, 0), (1, 0), (0, -1), (0, 1))
                r2, c2 = cr + dr, cc + dc
                (2 <= r2 <= nr - 1 && 2 <= c2 <= nc - 1) || continue
                if grid[r2, c2] == 2 && labels[r2, c2] == 0
                    labels[r2, c2] = nextl
                    push!(queue, (r2, c2))
                end
            end
        end
        push!(sizes, sz)
    end
    return labels, sizes
end

"""Per-step labels/sizes for t = 1..steps from a dense frames Dict."""
function label_sequence(frames::Dict{Int64,Matrix{Int64}}, steps::Int)
    labels = Vector{Matrix{Int16}}(undef, steps)
    sizes  = Vector{Vector{Int}}(undef, steps)
    for t in 1:steps
        labels[t], sizes[t] = label_interior_sell_clusters(frames[t])
    end
    return labels, sizes
end

"""All cells carrying label `lab`."""
function cluster_cells(labels::Matrix{Int16}, lab::Integer)::Vector{CartesianIndex{2}}
    return findall(==(Int16(lab)), labels)
end
