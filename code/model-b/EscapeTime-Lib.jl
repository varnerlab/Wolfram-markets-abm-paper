# EscapeTime-Lib.jl — pure helpers for the escape-time / barrier-law (A1)
# and velocity-vs-suppression (A2) analyses (spec: docs/superpowers/specs/
# 2026-07-20-nucleation-spine-restructure-design.md, Part 1). Included by
# Compute-ModelB-Nucleation-EscapeTime.jl, both Figs-ModelB-*.jl scripts, and
# Test-EscapeTime.jl; depends only on packages already loaded by
# model-b/Include.jl.

"""
    sell_clusters(grid) → (n, max)

Connected components of Sell (state 2) cells, 4-neighbour, FULL GRID (open
boundaries). Definition identical to `_sell_clusters` in
Compute-ModelB-BudgetToggle.jl — copied rather than refactored so the
committed toggle analysis stays untouched. Interior-only labeling
(BoundaryVsBulk-Lib.jl) is deliberately NOT used: onsets here must compose
with the toggle's.
"""
function sell_clusters(grid::Matrix{Int64})::Tuple{Int,Int}
    nr, nc  = size(grid)
    visited = falses(nr, nc)
    n_clust = 0
    max_sz  = 0
    for r in 1:nr, c in 1:nc
        (grid[r, c] == 2 && !visited[r, c]) || continue
        n_clust += 1
        sz    = 0
        queue = [(r, c)]
        visited[r, c] = true
        while !isempty(queue)
            cr, cc = popfirst!(queue)
            sz += 1
            for (dr, dc) in ((-1, 0), (1, 0), (0, -1), (0, 1))
                nr2, nc2 = cr + dr, cc + dc
                (1 <= nr2 <= nr && 1 <= nc2 <= nc) || continue
                if grid[nr2, nc2] == 2 && !visited[nr2, nc2]
                    visited[nr2, nc2] = true
                    push!(queue, (nr2, nc2))
                end
            end
        end
        max_sz = max(max_sz, sz)
    end
    return n_clust, max_sz
end

"""Largest sell-cluster CELL COUNT at each step t = 1..steps (dense frames)."""
function maxcl_series(frames::Dict{Int64,Matrix{Int64}}, steps::Int)::Vector{Int}
    return [sell_clusters(frames[t])[2] for t in 1:steps]
end

"""
    onset_step(maxcl, n_cells, frac) → Int

First step the largest sell cluster reaches ≥ frac of the grid; 0 if never.
Same trigger as the budget toggle (ONSET_FRAC = 0.05 there).
"""
function onset_step(maxcl::Vector{Int}, n_cells::Int, frac::Float64)::Int
    return something(findfirst(≥(frac * n_cells), maxcl), 0)
end

"""
    censored_median(tons) → Float64

Median onset time under Type I right-censoring: t_on == 0 marks a censored
run and counts as +∞, so the estimate is the k = ⌈n/2⌉-th order statistic
of observed onsets — exactly the Kaplan–Meier median when all censoring
occurs at the single horizon time. NaN when more than half the runs are
censored (the median is not identified at this horizon).
"""
function censored_median(tons::Vector{Int})::Float64
    n = length(tons)
    n == 0 && return NaN
    obs = sort(filter(>(0), tons))
    k = cld(n, 2)
    return length(obs) >= k ? Float64(obs[k]) : NaN
end

"""
    window_velocity(maxcl, n_cells, t_on; lo = 50, hi = 400) → Float64

OLS slope of largest-cluster FRACTION on step over the onset-aligned window
t ∈ [t_on+lo, t_on+hi] (units: fraction of grid per step). The caller
guarantees t_on > 0 and t_on + hi ≤ length(maxcl).
"""
function window_velocity(maxcl::Vector{Int}, n_cells::Int, t_on::Int;
                         lo::Int = 50, hi::Int = 400)::Float64
    ts = (t_on + lo):(t_on + hi)
    y  = maxcl[ts] ./ n_cells
    x  = collect(ts) .- mean(ts)
    return sum(x .* (y .- mean(y))) / sum(abs2, x)
end

"""
    kramers_profile_fit(fs, lntaus; f0_grid) → (A, B, f0, r2)

Least-squares fit of lnτ = A + B/(f − f0) by profiling f0: for each
admissible f0 (< min(fs)) the remaining problem is linear in (A, B) and
solved in closed form; the f0 minimizing SSE wins. Requires ≥ 4 points
(3 parameters). Deterministic and dependency-free (no LsqFit).
"""
function kramers_profile_fit(fs::Vector{Float64}, lntaus::Vector{Float64};
        f0_grid::AbstractVector{Float64} = 0.0:1e-4:(minimum(fs) - 5e-3))
    @assert length(fs) == length(lntaus) && length(fs) >= 4 "need ≥ 4 (f, lnτ) points"
    best = (A = NaN, B = NaN, f0 = NaN, r2 = -Inf)
    best_sse = Inf
    sst = sum(abs2, lntaus .- mean(lntaus))
    for f0 in f0_grid
        f0 < minimum(fs) || continue
        x  = 1.0 ./ (fs .- f0)
        mx = mean(x); my = mean(lntaus)
        sxx = sum(abs2, x .- mx)
        sxx > 0 || continue
        B = sum((x .- mx) .* (lntaus .- my)) / sxx
        A = my - B * mx
        sse = sum(abs2, lntaus .- A .- B .* x)
        if sse < best_sse
            best_sse = sse
            best = (A = A, B = B, f0 = f0, r2 = 1 - sse / sst)
        end
    end
    return best
end

"""
    bootstrap_kramers(fs_by_run, tons; ndraws, rng) → (A, B, f0) vectors

Seed bootstrap for ONE cash level: `fs_by_run[i]` and `tons[i]` describe run
i (t_on = 0 ⇒ censored). Each draw resamples runs with replacement WITHIN
each f, recomputes censored medians, and refits; draws where < 4 f-points
retain a defined median are skipped (so the returned vectors may be shorter
than ndraws — callers report the count).
"""
function bootstrap_kramers(fs_by_run::Vector{Float64}, tons::Vector{Int};
                           ndraws::Int = 2000, rng = Xoshiro(7))
    fvals = sort(unique(fs_by_run))
    idx   = Dict(f => findall(==(f), fs_by_run) for f in fvals)
    As = Float64[]; Bs = Float64[]; F0s = Float64[]
    for _ in 1:ndraws
        pf = Float64[]; pm = Float64[]
        for f in fvals
            ids  = idx[f]
            draw = [tons[ids[rand(rng, 1:length(ids))]] for _ in ids]
            m = censored_median(draw)
            isnan(m) || (push!(pf, f); push!(pm, log(m)))
        end
        length(pf) >= 4 || continue
        fit = kramers_profile_fit(pf, pm)
        push!(As, fit.A); push!(Bs, fit.B); push!(F0s, fit.f0)
    end
    return (A = As, B = Bs, f0 = F0s)
end
