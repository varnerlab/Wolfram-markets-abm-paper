# Escape-Time / Barrier-Law + Velocity-vs-Suppression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run the two confirmatory analyses from the nucleation-spine spec (Phase 1): the Model B escape-time/barrier law (A1) and front-velocity vs absolute suppression (A2), producing committed CSVs, fit results, and two standalone figures.

**Architecture:** One instrumented simulation campaign (a threaded sweep over (f, cash, seed) work items) feeds both analyses. Pure statistics live in `EscapeTime-Lib.jl` (TDD), the campaign driver in `Compute-ModelB-EscapeTime.jl` (smoke-testable, deterministic, byte-reproducible), and figures in two standalone `Figs-*.jl` scripts that read only committed CSVs — the exact structure of the boundary-vs-bulk analysis.

**Tech Stack:** Julia (packages already loaded by `code/model-b/Include.jl`: DataFrames, CSV, Statistics, StatsBase, Distributions, Random, Plots). No new dependencies. No changes to `code/src/`.

**Spec:** `docs/superpowers/specs/2026-07-20-nucleation-spine-restructure-design.md` (Part 1). Phases 2–3 of that spec (paper writing, cleanup) are a SEPARATE plan written after these results exist — the spec's surprise-handling can reframe paper sections depending on what A1/A2 find.

## Global Constraints

- Model B parameters everywhere: grid 64×64, STEPS = 2000, λ = 0.02, k = 1.0, edge_band_spread = 0.5, cost_basis_rule = false, P0 = 100.0, deterministic per-run seeds.
- Onset: t_on = first step the largest sell cluster ≥ 5% of the FULL grid; clusters = full-grid 4-neighbour BFS on Sell (state 2) — the budget-toggle definitions (`Compute-ModelB-BudgetToggle.jl`), NOT boundary-vs-bulk's interior-only labeling.
- Suppression is ABSOLUTE (orders/step, unnormalized) — never per-panel scaled.
- Censored runs (no onset by STEPS) are flagged, never dropped; medians are Kaplan–Meier (= order-statistic median with censored = ∞ under single-time censoring), NaN when >half censored.
- All Monte-Carlo p-values carry the +1 correction; all RNGs are fixed-seed `Xoshiro`; all RNG-dependent statistics run OUTSIDE the threaded loop (main thread, after the sweep).
- Threading contract (house rule): results land in preallocated vectors indexed by work-item id; all file I/O and plotting outside the threaded loop.
- Figure scripts read committed CSVs only; standalone-rerunnable from the repo root.
- Commit after every green test/verification step. Commit messages in the repo's imperative style, ending with the Claude co-author trailer.

## File Structure

- Modify: `code/model-b/Include.jl` (one line — stale `paper/figs` path → `paper-arxiv/figs`)
- Create: `code/model-b/EscapeTime-Lib.jl` (pure functions: clustering, onset, censored median, velocity, Kramers profile fit, bootstrap, Spearman permutation test)
- Create: `code/model-b/Test-EscapeTime.jl` (unit tests for the lib)
- Create: `code/model-b/Compute-ModelB-EscapeTime.jl` (campaign driver + fits + stats; smoke mode `ESCAPE_SMOKE=1`)
- Create: `code/model-b/Figs-ModelB-BarrierLaw.jl` (A1 figure, reads CSVs only)
- Create: `code/model-b/Figs-ModelB-VelocitySuppression.jl` (A2 figure, reads CSVs only)
- Data (committed after production run): `code/data/ModelB-EscapeTime.csv`, `code/data/ModelB-EscapeTime-Fits.csv`, `code/data/ModelB-EscapeTime-Trajectories.csv`
- Figures: `code/figs/ModelB-Nucleation-BarrierLaw.pdf`, `code/figs/ModelB-Nucleation-VelocitySuppression.pdf`

**One deliberate deviation from the spec:** the spec's example pilot grid was {0.12, 0.15, 0.18, 0.21, 0.25, 0.30}; this plan uses **{0.12, 0.15, 0.18, 0.20, 0.25, 0.30}** — swapping 0.21 for 0.20 so the pilot hits the canonical f = 0.20 used by every prior nucleation config (probe, seed sweep, toggle, boundary-vs-bulk) and so the A2 slice needs no extra f. Task 10 records this as a spec amendment.

---

### Task 1: Fix the stale paper-figs path in Include.jl

The repo's `paper/` directory was renamed `paper-arxiv/` (commit c34797a). `code/model-b/Include.jl` still points `_PATH_TO_PAPER_FIGS` at `paper/figs`, so `_save_figure` silently stopped copying figures into the paper (it guards on `isdir`).

**Files:**
- Modify: `code/model-b/Include.jl:15`

**Interfaces:**
- Consumes: nothing
- Produces: `_PATH_TO_PAPER_FIGS::String` pointing at the existing `paper-arxiv/figs` directory (used by `_save_figure` in the same file)

- [ ] **Step 1: Edit the constant**

In `code/model-b/Include.jl` replace:

```julia
const _PATH_TO_PAPER_FIGS = joinpath(@__DIR__, "..", "..", "paper", "figs")
```

with:

```julia
const _PATH_TO_PAPER_FIGS = joinpath(@__DIR__, "..", "..", "paper-arxiv", "figs")
```

- [ ] **Step 2: Verify the path resolves**

Run: `julia -e 'p = joinpath("code", "model-b", "..", "..", "paper-arxiv", "figs"); println(isdir(p))'`
Expected: `true`

Also check no other stale references exist:
Run: `grep -rn '"paper"' code/ --include='*.jl'`
Expected: no output (if other hits appear, fix them the same way and note it in the commit).

- [ ] **Step 3: Commit**

```bash
git add code/model-b/Include.jl
git commit -m "Point _PATH_TO_PAPER_FIGS at renamed paper-arxiv/figs

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CL5rGoKjgPYiw4BG9pdcAx"
```

---

### Task 2: EscapeTime-Lib core — clustering, onset, censored median, velocity

**Files:**
- Create: `code/model-b/EscapeTime-Lib.jl`
- Create: `code/model-b/Test-EscapeTime.jl`

**Interfaces:**
- Consumes: packages loaded by `code/model-b/Include.jl` (Statistics for `mean`)
- Produces (used by Tasks 3–9):
  - `sell_clusters(grid::Matrix{Int64})::Tuple{Int,Int}` → (n_clusters, max_size), full grid
  - `maxcl_series(frames::Dict{Int64,Matrix{Int64}}, steps::Int)::Vector{Int}` → largest-cluster CELL COUNT at t = 1..steps
  - `onset_step(maxcl::Vector{Int}, n_cells::Int, frac::Float64)::Int` → first step count ≥ frac·n_cells, 0 if never
  - `censored_median(tons::Vector{Int})::Float64` → KM median with t_on == 0 meaning censored; NaN if >half censored
  - `window_velocity(maxcl::Vector{Int}, n_cells::Int, t_on::Int; lo::Int = 50, hi::Int = 400)::Float64` → OLS slope of fraction vs step on [t_on+lo, t_on+hi]

- [ ] **Step 1: Write the failing tests**

Create `code/model-b/Test-EscapeTime.jl`:

```julia
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `julia code/model-b/Test-EscapeTime.jl`
Expected: FAIL — `SystemError: opening file .../EscapeTime-Lib.jl` (file does not exist yet).

- [ ] **Step 3: Write the implementation**

Create `code/model-b/EscapeTime-Lib.jl`:

```julia
# EscapeTime-Lib.jl — pure helpers for the escape-time / barrier-law (A1)
# and velocity-vs-suppression (A2) analyses (spec: docs/superpowers/specs/
# 2026-07-20-nucleation-spine-restructure-design.md, Part 1). Included by
# Compute-ModelB-EscapeTime.jl, both Figs-ModelB-*.jl scripts, and
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `julia code/model-b/Test-EscapeTime.jl`
Expected: all testsets PASS (`Test Summary: | Pass`).

- [ ] **Step 5: Commit**

```bash
git add code/model-b/EscapeTime-Lib.jl code/model-b/Test-EscapeTime.jl
git commit -m "Add escape-time lib core: full-grid clustering, onset, KM median, window velocity

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CL5rGoKjgPYiw4BG9pdcAx"
```

---

### Task 3: Kramers profile fit + seed bootstrap

**Files:**
- Modify: `code/model-b/EscapeTime-Lib.jl` (append two functions)
- Modify: `code/model-b/Test-EscapeTime.jl` (append two testsets)

**Interfaces:**
- Consumes: `censored_median` (Task 2); `Statistics.mean`, `Statistics.quantile`, `Random.Xoshiro`
- Produces:
  - `kramers_profile_fit(fs::Vector{Float64}, lntaus::Vector{Float64}; f0_grid)::NamedTuple{(:A, :B, :f0, :r2)}` — asserts ≥ 4 points
  - `bootstrap_kramers(fs_by_run::Vector{Float64}, tons::Vector{Int}; ndraws::Int = 2000, rng = Xoshiro(7))::NamedTuple{(:A, :B, :f0)}` of vectors (one entry per successful draw)

- [ ] **Step 1: Append the failing tests**

Append to `code/model-b/Test-EscapeTime.jl`:

```julia
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
```

- [ ] **Step 2: Run tests to verify the new ones fail**

Run: `julia code/model-b/Test-EscapeTime.jl`
Expected: FAIL with `UndefVarError: kramers_profile_fit not defined` (earlier testsets still pass).

- [ ] **Step 3: Append the implementation**

Append to `code/model-b/EscapeTime-Lib.jl`:

```julia
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `julia code/model-b/Test-EscapeTime.jl`
Expected: all testsets PASS.

- [ ] **Step 5: Commit**

```bash
git add code/model-b/EscapeTime-Lib.jl code/model-b/Test-EscapeTime.jl
git commit -m "Add Kramers profile fit and seed bootstrap to escape-time lib

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CL5rGoKjgPYiw4BG9pdcAx"
```

---

### Task 4: Spearman permutation test

**Files:**
- Modify: `code/model-b/EscapeTime-Lib.jl` (append one function)
- Modify: `code/model-b/Test-EscapeTime.jl` (append one testset)

**Interfaces:**
- Consumes: `StatsBase.corspearman`, `Random.shuffle!`, `Random.Xoshiro`
- Produces: `spearman_perm_p(x::Vector{Float64}, y::Vector{Float64}; ndraws::Int = 10_000, rng = Xoshiro(7))::NamedTuple{(:rho, :p)}`

- [ ] **Step 1: Append the failing test**

Append to `code/model-b/Test-EscapeTime.jl`:

```julia
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
```

- [ ] **Step 2: Run tests to verify the new one fails**

Run: `julia code/model-b/Test-EscapeTime.jl`
Expected: FAIL with `UndefVarError: spearman_perm_p not defined`.

- [ ] **Step 3: Append the implementation**

Append to `code/model-b/EscapeTime-Lib.jl`:

```julia
"""
    spearman_perm_p(x, y; ndraws = 10_000, rng = Xoshiro(7)) → (rho, p)

Spearman ρ of (x, y) with a two-sided permutation p-value (y shuffled),
+1 Monte-Carlo corrected: p = (1 + #{|ρ_perm| ≥ |ρ_obs|}) / (ndraws + 1).
The 1e-12 tolerance absorbs rank-tie floating-point noise.
"""
function spearman_perm_p(x::Vector{Float64}, y::Vector{Float64};
                         ndraws::Int = 10_000, rng = Xoshiro(7))
    rho  = corspearman(x, y)
    yp   = copy(y)
    hits = 0
    for _ in 1:ndraws
        shuffle!(rng, yp)
        hits += abs(corspearman(x, yp)) >= abs(rho) - 1e-12
    end
    return (rho = rho, p = (1 + hits) / (ndraws + 1))
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `julia code/model-b/Test-EscapeTime.jl`
Expected: all testsets PASS.

- [ ] **Step 5: Commit**

```bash
git add code/model-b/EscapeTime-Lib.jl code/model-b/Test-EscapeTime.jl
git commit -m "Add +1-corrected Spearman permutation test to escape-time lib

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CL5rGoKjgPYiw4BG9pdcAx"
```

---

### Task 5: Campaign driver with smoke mode

**Files:**
- Create: `code/model-b/Compute-ModelB-EscapeTime.jl`

**Interfaces:**
- Consumes: `build`, `MyModelBConfiguration`, `simulate` (from `code/src/` via Include.jl); every lib function from Tasks 2–4
- Produces (CSV contracts consumed by Tasks 8–9):
  - `code/data/ModelB-EscapeTime.csv` — columns: `stage::String` ("pilot" | "a2x" | "refine"), `f::Float64`, `cash::Float64`, `seed::Int`, `t_on::Int` (0 = never), `censored::Bool`, `v_front::Float64` (NaN if excluded from A2 window), `suppb_w::Float64` (NaN likewise), `price_end::Float64`, `maxcl_end::Float64` (fraction)
  - `code/data/ModelB-EscapeTime-Fits.csv` — one row per A1 cash level: `cash, n_points, A, B, f0, r2, A_lo, A_hi, B_lo, B_hi, f0_lo, f0_hi, n_boot` (NaN row + n_boot = 0 when < 4 defined medians)
  - `code/data/ModelB-EscapeTime-Trajectories.csv` — f = 0.20 runs only: `f, cash, seed, gridn`, then `t1..tSTEPS` largest-cluster cell counts (integers)

- [ ] **Step 1: Write the driver**

Create `code/model-b/Compute-ModelB-EscapeTime.jl`:

```julia
# Compute-ModelB-EscapeTime.jl — the shared instrumented campaign for the two
# confirmatory analyses of the nucleation-spine spec (Part 1):
#
#   A1 (escape-time / barrier law): does Model A's Kramers form
#   lnτ = A + B/(f − f0) survive under budgets, and does cash shift the
#   barrier? f-sweep × cash {500, 1000, 5000}, censoring-aware medians,
#   profile fit + seed bootstrap CIs.
#
#   A2 (velocity vs ABSOLUTE suppression): five cash doses at f = 0.20;
#   onset-aligned OLS front velocity vs mean suppressed-buy orders/step
#   (absolute, unnormalized — fixes the per-panel-scaling flaw), Spearman +
#   permutation p.
#
# Definitions COMPOSE WITH THE BUDGET TOGGLE, not boundary-vs-bulk: clusters
# are full-grid 4-neighbour BFS on Sell; onset = largest cluster ≥ 5% of the
# grid. (Boundary-vs-bulk used interior-only labeling for birth attribution;
# here fronts and onsets must line up with the toggle's intervention results.)
#
# Writes: code/data/ModelB-EscapeTime.csv                (one row per run)
#         code/data/ModelB-EscapeTime-Fits.csv           (A1 fits + boot CIs)
#         code/data/ModelB-EscapeTime-Trajectories.csv   (f = 0.20 runs, wide)
#
# Launch: julia -t 8 code/model-b/Compute-ModelB-EscapeTime.jl
# Smoke:  ESCAPE_SMOKE=1 julia code/model-b/Compute-ModelB-EscapeTime.jl
#         (tiny grid/horizon — exercises the full path, outputs are smoke)
#
# Threading contract (house rule): results land in preallocated vectors
# indexed by work-item id; file I/O, fits, and RNG-based statistics all run
# on the main thread after the sweep. Deterministic end to end: a rerun must
# reproduce the CSVs byte-identically.

include(joinpath(@__DIR__, "Include.jl"))
include(joinpath(@__DIR__, "EscapeTime-Lib.jl"))

const SMOKE = get(ENV, "ESCAPE_SMOKE", "0") == "1"
SMOKE && @warn "ESCAPE_SMOKE=1 — tiny grid and horizon; outputs are smoke artifacts only"

const P0         = 100.0
const GRIDN      = SMOKE ? 32 : 64
const STEPS      = SMOKE ? 300 : 2000
const N_CELLS    = GRIDN * GRIDN
const ONSET_FRAC = 0.05
const V_LO       = SMOKE ? 10 : 50       # velocity window start (after onset)
const V_HI       = SMOKE ? 100 : 400     # velocity window end = toggle's W

const PILOT_F       = SMOKE ? [0.20, 0.30] : [0.12, 0.15, 0.18, 0.20, 0.25, 0.30]
const CASH_A1       = SMOKE ? [500.0, 5000.0] : [500.0, 1000.0, 5000.0]
const F_A2          = 0.20
const CASH_A2_EXTRA = SMOKE ? Float64[] : [250.0, 2000.0]
const SEEDS_PILOT   = SMOKE ? (1:2) : (1:20)
const SEEDS_REFINE  = 1:40

# Refinement f-values near each cash level's divergence — EMPTY until the
# pilot review (plan Task 6) fills it by the recorded rule. Full production
# reruns pilot + refine + a2x in one deterministic pass.
const REFINE = NamedTuple{(:f, :cash),Tuple{Float64,Float64}}[]

function _escape_config(; f, cash, seed)
    return build(MyModelBConfiguration, (
        number_of_rows    = GRIDN,
        number_of_cols    = GRIDN,
        steps             = STEPS,
        seed              = seed,
        λ                 = 0.02,
        k                 = 1.0,
        minority_fraction = f,
        edge_band_spread  = 0.5,
        cost_basis_rule   = false,
        initial_cash      = cash,
        P0                = P0,
    ))
end

"""One run: simulate, reduce dense frames to the maxcl series, extract stats."""
function _run_one(f::Float64, cash::Float64, seed::Int, stage::String)
    res   = simulate(_escape_config(f = f, cash = cash, seed = seed);
                     snapshot_steps = collect(1:STEPS), verbose = false)
    maxcl = maxcl_series(res.frames, STEPS)
    t_on  = onset_step(maxcl, N_CELLS, ONSET_FRAC)
    a2ok  = t_on > 0 && t_on + V_HI <= STEPS
    v     = a2ok ? window_velocity(maxcl, N_CELLS, t_on; lo = V_LO, hi = V_HI) : NaN
    supp  = a2ok ? mean(@view res.suppressed_buys[(t_on + V_LO):(t_on + V_HI)]) : NaN
    row = (stage = stage, f = f, cash = cash, seed = seed,
           t_on = t_on, censored = t_on == 0,
           v_front = v, suppb_w = supp,
           price_end = res.prices[end], maxcl_end = maxcl[end] / N_CELLS)
    return (row = row, traj = f == F_A2 ? maxcl : Int[])
end

# ---------------------------------------------------------------------------
# Work items: pilot grid × A1 cash, the A2 dose extension, then refinement
# ---------------------------------------------------------------------------
items = NamedTuple{(:f, :cash, :seed, :stage),Tuple{Float64,Float64,Int,String}}[]
for f in PILOT_F, cash in CASH_A1, seed in SEEDS_PILOT
    push!(items, (f = f, cash = cash, seed = seed, stage = "pilot"))
end
for cash in CASH_A2_EXTRA, seed in SEEDS_PILOT
    push!(items, (f = F_A2, cash = cash, seed = seed, stage = "a2x"))
end
for r in REFINE, seed in SEEDS_REFINE
    push!(items, (f = r.f, cash = r.cash, seed = seed, stage = "refine"))
end

@info "Escape-time campaign" n_runs = length(items) grid = GRIDN steps = STEPS n_refine = length(REFINE) threads = Threads.nthreads()

results = Vector{Union{Nothing,NamedTuple}}(nothing, length(items))
Threads.@threads :dynamic for i in eachindex(items)
    it = items[i]
    results[i] = _run_one(it.f, it.cash, it.seed, it.stage)
end
@assert all(!isnothing, results)

df = DataFrame()
for r in results
    push!(df, r.row)
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-EscapeTime.csv"), df)
@info "Saved: ModelB-EscapeTime.csv" rows = nrow(df)

# Trajectories (f = 0.20 only) — Phase 2 exemplar insurance, wide integer counts
tidx = [i for i in eachindex(items) if !isempty(results[i].traj)]
meta = DataFrame(f = [items[i].f for i in tidx], cash = [items[i].cash for i in tidx],
                 seed = [items[i].seed for i in tidx], gridn = fill(GRIDN, length(tidx)))
tmat = reduce(vcat, [permutedims(results[i].traj) for i in tidx])
tdf  = hcat(meta, DataFrame(tmat, ["t$(t)" for t in 1:STEPS]))
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-EscapeTime-Trajectories.csv"), tdf)
@info "Saved: ModelB-EscapeTime-Trajectories.csv" rows = nrow(tdf)

# ---------------------------------------------------------------------------
# A1: censored medians, onset rates, Kramers fits + bootstrap CIs (main thread)
# ---------------------------------------------------------------------------
fitrows = NamedTuple[]
for cash in CASH_A1
    sub   = df[(df.cash .== cash) .& (df.stage .!= "a2x"), :]
    fvals = sort(unique(sub.f))
    meds  = [censored_median(Int.(sub.t_on[sub.f .== f])) for f in fvals]
    onr   = [mean(sub.t_on[sub.f .== f] .> 0) for f in fvals]
    ok    = .!isnan.(meds)
    @info "A1 onset summary" cash fvals = round.(fvals, digits = 3) onset_rate = round.(onr, digits = 2) median_ton = [isnan(m) ? "NaN" : string(Int(m)) for m in meds]
    if count(ok) >= 4
        fit = kramers_profile_fit(fvals[ok], log.(meds[ok]))
        bs  = bootstrap_kramers(collect(sub.f), Int.(sub.t_on); ndraws = 2000, rng = Xoshiro(7))
        ci(v) = isempty(v) ? (NaN, NaN) : (quantile(v, 0.025), quantile(v, 0.975))
        (Alo, Ahi) = ci(bs.A); (Blo, Bhi) = ci(bs.B); (f0lo, f0hi) = ci(bs.f0)
        push!(fitrows, (cash = cash, n_points = count(ok), A = fit.A, B = fit.B,
                        f0 = fit.f0, r2 = fit.r2, A_lo = Alo, A_hi = Ahi,
                        B_lo = Blo, B_hi = Bhi, f0_lo = f0lo, f0_hi = f0hi,
                        n_boot = length(bs.f0)))
        @info "A1 Kramers fit" cash A = round(fit.A, digits = 3) B = round(fit.B, digits = 4) f0 = round(fit.f0, digits = 4) r2 = round(fit.r2, digits = 4) f0_ci = (round(f0lo, digits = 4), round(f0hi, digits = 4)) B_ci = (round(Blo, digits = 4), round(Bhi, digits = 4)) n_boot = length(bs.f0)
    else
        push!(fitrows, (cash = cash, n_points = count(ok), A = NaN, B = NaN,
                        f0 = NaN, r2 = NaN, A_lo = NaN, A_hi = NaN, B_lo = NaN,
                        B_hi = NaN, f0_lo = NaN, f0_hi = NaN, n_boot = 0))
        @warn "A1 Kramers fit SKIPPED — fewer than 4 defined medians" cash n_defined = count(ok)
    end
end
fits_df = DataFrame(fitrows)
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-EscapeTime-Fits.csv"), fits_df)
@info "Saved: ModelB-EscapeTime-Fits.csv"

# Confirmation criterion 2: tight-vs-loose CI separation on f0 and B
let t = fits_df[fits_df.cash .== minimum(CASH_A1), :],
    l = fits_df[fits_df.cash .== maximum(CASH_A1), :]
    if nrow(t) == 1 && nrow(l) == 1 && t.n_boot[1] > 0 && l.n_boot[1] > 0
        sep_f0 = t.f0_lo[1] > l.f0_hi[1] || l.f0_lo[1] > t.f0_hi[1]
        sep_B  = t.B_lo[1]  > l.B_hi[1]  || l.B_lo[1]  > t.B_hi[1]
        @info "A1 criterion 2 (tight vs loose bootstrap-CI separation)" sep_f0 sep_B
    end
end

# ---------------------------------------------------------------------------
# A2: velocity vs absolute suppression at f = 0.20 (five doses)
# ---------------------------------------------------------------------------
a2  = df[(df.f .== F_A2) .& .!isnan.(df.v_front), :]
nex = count((df.f .== F_A2) .& isnan.(df.v_front))
if nrow(a2) >= 10
    sp = spearman_perm_p(collect(Float64.(a2.suppb_w)), collect(Float64.(a2.v_front)))
    @info "A2 velocity vs suppression" n = nrow(a2) excluded = nex rho = round(sp.rho, digits = 3) perm_p = round(sp.p, digits = 4) criterion_met = (sp.rho < 0 && sp.p < 0.05)
    for cash in sort(unique(a2.cash))
        s = a2[a2.cash .== cash, :]
        @info "A2 dose" cash n = nrow(s) median_v_e4 = round(median(s.v_front) * 1e4, digits = 2) median_suppb = round(median(s.suppb_w), digits = 1)
    end
else
    @warn "A2 underpowered — too few included runs at f = 0.20" n = nrow(a2) excluded = nex
end

@info "Compute-ModelB-EscapeTime.jl complete."
```

- [ ] **Step 2: Smoke-run the full path**

Run: `ESCAPE_SMOKE=1 julia code/model-b/Compute-ModelB-EscapeTime.jl`
Expected: completes without error in ~1–3 min; `@info` lines show n_runs = 8 (2 f × 2 cash × 2 seeds); all three CSVs written to `code/data/`; both fit rows warn `SKIPPED — fewer than 4 defined medians` (only 2 pilot f-values in smoke — expected); trajectories CSV has 4 rows × 304 columns; A2 line either reports or warns underpowered (n ≤ 4 in smoke — both acceptable).

- [ ] **Step 3: Revert smoke CSVs, commit the script only**

Smoke CSVs must not be committed (they overwrite the production paths):

```bash
git checkout -- code/data/ 2>/dev/null; git status --porcelain code/data/
```

Expected: untracked `ModelB-EscapeTime*.csv` files remain (they are new; delete them):

```bash
rm -f code/data/ModelB-EscapeTime.csv code/data/ModelB-EscapeTime-Fits.csv code/data/ModelB-EscapeTime-Trajectories.csv
git add code/model-b/Compute-ModelB-EscapeTime.jl
git commit -m "Add escape-time campaign driver (A1 barrier law + A2 velocity slice, smoke-tested)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CL5rGoKjgPYiw4BG9pdcAx"
```

---

### Task 6: Pilot run + refinement decision (CHECKPOINT)

This task runs the production pilot (REFINE still empty), then a human-judgment step chooses the refinement f-values. **Do not skip the review; do not auto-pick values without printing the pilot table.**

**Files:**
- Modify: `code/model-b/Compute-ModelB-EscapeTime.jl` (fill `REFINE` + add a decision-record comment)

**Interfaces:**
- Consumes: the Task 5 script
- Produces: a populated `const REFINE` (the full production design), with the pilot evidence recorded in a comment above it

- [ ] **Step 1: Run the pilot**

Run: `julia -t 8 code/model-b/Compute-ModelB-EscapeTime.jl 2>&1 | tee /tmp/escape-pilot.log`
Expected: 400 runs (6 f × 3 cash × 20 seeds pilot + 2 × 20 a2x); wall time very roughly 20–60 min at 8 threads. The `A1 onset summary` lines print onset_rate and median_ton per f per cash.

- [ ] **Step 2: Choose refinement values by the recorded rule**

For EACH cash level (500, 1000, 5000), from its `A1 onset summary` line:
- Let `f_b` = smallest pilot f with onset_rate ≥ 0.5, `f_a` = largest pilot f below `f_b`.
- Refinement values = the 4 interior points `round.(range(f_a, f_b; length = 6)[2:5], digits = 3)`, deduplicated against `PILOT_F`.
- Aim: ≥ 5 defined-median f-points per cash level after refinement (points below the cliff inform the onset-rate panel even when their median is undefined).

Escalation triggers (STOP and consult the user — spec surprise-handling):
- Some cash level has NO pilot f with onset_rate ≥ 0.5 (heavy censoring → survival-curve fallback).
- ALL pilot f have onset_rate ≥ 0.5 at every cash level (no divergence inside the sweep — the barrier sits below f = 0.12; sweep design needs rethinking, and Model A's f0 = 0.101 bounds how far down it can go).
- A cash level's fit already fails criterion 1 badly at pilot (r2 < 0.9 with ≥ 4 points): note it; refinement proceeds but flag for the "budgets break the law" framing.

- [ ] **Step 3: Record the decision in the script**

Replace the empty `const REFINE = ...` line with (VALUES ARE ILLUSTRATIVE — use the rule's output):

```julia
# Pilot review (plan Task 6, run log /tmp/escape-pilot.log): onset cliffs sat
# between f_a and f_b per cash level as follows — [record the actual
# onset_rate table rows here] — so refinement places 4 interior points per
# cash level by the plan's range rule, at 40 seeds each.
const REFINE = [
    (f = 0.157, cash = 500.0),  (f = 0.163, cash = 500.0),
    (f = 0.170, cash = 500.0),  (f = 0.177, cash = 500.0),
    (f = 0.157, cash = 1000.0), (f = 0.163, cash = 1000.0),
    (f = 0.170, cash = 1000.0), (f = 0.177, cash = 1000.0),
    (f = 0.157, cash = 5000.0), (f = 0.163, cash = 5000.0),
    (f = 0.170, cash = 5000.0), (f = 0.177, cash = 5000.0),
]
```

(Type note: with real entries the explicit `NamedTuple{...}[]` annotation is no longer needed.)

- [ ] **Step 4: Commit the decision (pilot CSVs stay uncommitted — superseded by Task 7's full run, whose pilot rows are bit-identical because the sweep is deterministic)**

```bash
git add code/model-b/Compute-ModelB-EscapeTime.jl
git commit -m "Record pilot-driven refinement grid for the escape-time campaign

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CL5rGoKjgPYiw4BG9pdcAx"
```

---

### Task 7: Production run, commit data, byte-identity check

**Files:**
- Create (data): `code/data/ModelB-EscapeTime.csv`, `code/data/ModelB-EscapeTime-Fits.csv`, `code/data/ModelB-EscapeTime-Trajectories.csv`

**Interfaces:**
- Consumes: Task 6's script with populated REFINE
- Produces: the three committed CSVs (schemas in Task 5) — the inputs for Tasks 8–9 and for the paper's Results II claims

- [ ] **Step 1: Run the full campaign**

Run: `julia -t 8 code/model-b/Compute-ModelB-EscapeTime.jl 2>&1 | tee /tmp/escape-full.log`
Expected: ~880 runs (400 pilot/a2x + 12 refine points × 40 seeds); wall time roughly 1–2× the pilot. `A1 Kramers fit` lines print per cash level with r2 and CIs; `A1 criterion 2` line prints sep_f0/sep_B; `A2 velocity vs suppression` prints rho, perm_p, criterion_met.

- [ ] **Step 2: Sanity-check the outcomes against the spec's criteria**

From `/tmp/escape-full.log`, record in the task notes: per-cash (A, B, f0, r2, CIs, n_boot), criterion-2 separations, A2 (rho, p, criterion_met, exclusion count). If criterion 1 fails (r2 far from Model A's 0.991) or criterion 2 shows no separation, that is a REPORTABLE RESULT, not a failure — the spec's surprise-handling covers it; flag it prominently for the Phase 2 plan.

- [ ] **Step 3: Commit the data**

```bash
git add code/data/ModelB-EscapeTime.csv code/data/ModelB-EscapeTime-Fits.csv code/data/ModelB-EscapeTime-Trajectories.csv
git commit -m "Run escape-time campaign: barrier-law sweep + velocity dose-response data

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CL5rGoKjgPYiw4BG9pdcAx"
```

- [ ] **Step 4: Byte-identity rerun**

Run: `julia -t 8 code/model-b/Compute-ModelB-EscapeTime.jl && git status --porcelain code/data/`
Expected: empty output from git status (all three CSVs byte-identical on rerun). If not empty, STOP — the sweep has a nondeterminism bug (threading order leaking into results, or an RNG touched inside the loop); find it before proceeding (`git diff code/data/` shows which columns move).

---

### Task 8: Barrier-law figure (A1)

**Files:**
- Create: `code/model-b/Figs-ModelB-BarrierLaw.jl`

**Interfaces:**
- Consumes: `ModelB-EscapeTime.csv`, `ModelB-EscapeTime-Fits.csv`; lib functions `censored_median` (recomputing medians from raw rows keeps one source of truth)
- Produces: `code/figs/ModelB-Nucleation-BarrierLaw.pdf`

- [ ] **Step 1: Write the figure script**

Create `code/model-b/Figs-ModelB-BarrierLaw.jl`:

```julia
# Figs-ModelB-BarrierLaw.jl — the A1 headline figure, drawn ENTIRELY from the
# committed CSVs (no simulation):
#   code/data/ModelB-EscapeTime.csv
#   code/data/ModelB-EscapeTime-Fits.csv
# Standalone-rerunnable from the repo root:
#   julia code/model-b/Figs-ModelB-BarrierLaw.jl
#
# Writes: code/figs/ModelB-Nucleation-BarrierLaw.pdf
#
# Body is a `let` block (locals only) so it can be included after a sweep
# without global-constant collisions.

isdefined(Main, :_PATH_TO_DATA)   || include(joinpath(@__DIR__, "Include.jl"))
isdefined(Main, :censored_median) || include(joinpath(@__DIR__, "EscapeTime-Lib.jl"))

let
    df   = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-EscapeTime.csv"), DataFrame)
    fits = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-EscapeTime-Fits.csv"), DataFrame)

    a1     = df[df.stage .!= "a2x", :]
    cashes = sort(unique(a1.cash))
    # tight → freeze blue, mid → orange, loose → collapse red (house palette)
    base_colors = [_BUY_COLOR, "#E69F00", _SELL_COLOR, "#009E73", "#CC79A7"]
    cash_color  = Dict(c => base_colors[i] for (i, c) in enumerate(cashes))

    # Model A reference: ln τ = 2.78 + 0.389/(f − 0.101), R² = 0.991 (Sec 5.6)
    A_REF, B_REF, F0_REF = 2.78, 0.389, 0.101

    p_tau = plot(title = "median onset time", titlefont = 10, xlabel = "f",
                 ylabel = "median t_on (steps)", yscale = :log10,
                 guidefont = 8, tickfont = 7, legend = :topright, legendfontsize = 6)
    fref = range(F0_REF + 0.012, maximum(a1.f); length = 400)
    plot!(p_tau, fref, exp.(A_REF .+ B_REF ./ (fref .- F0_REF)),
          color = :black, ls = :dash, lw = 1.5, label = "Model A fit")

    p_rate = plot(title = "onset rate by horizon t = max step", titlefont = 10,
                  xlabel = "f", ylabel = "fraction of seeds with onset",
                  ylims = (0, 1.05), guidefont = 8, tickfont = 7,
                  legend = :bottomright, legendfontsize = 6)

    for cash in cashes
        sub   = a1[a1.cash .== cash, :]
        fvals = sort(unique(sub.f))
        meds  = [censored_median(Int.(sub.t_on[sub.f .== f])) for f in fvals]
        onr   = [mean(sub.t_on[sub.f .== f] .> 0) for f in fvals]
        ok    = .!isnan.(meds)
        lbl   = "cash $(Int(cash))"
        scatter!(p_tau, fvals[ok], meds[ok], color = cash_color[cash],
                 markersize = 5, markerstrokewidth = 0.5, label = lbl)
        plot!(p_rate, fvals, onr, color = cash_color[cash], lw = 1.6,
              marker = :circle, markersize = 3, markerstrokewidth = 0, label = lbl)
        fr = fits[fits.cash .== cash, :]
        if nrow(fr) == 1 && !isnan(fr.f0[1])
            fc = range(fr.f0[1] + 0.008, maximum(fvals[ok]); length = 400)
            plot!(p_tau, fc, exp.(fr.A[1] .+ fr.B[1] ./ (fc .- fr.f0[1])),
                  color = cash_color[cash], lw = 1.6, label = "")
        end
    end

    # Fitted parameters with bootstrap CIs (skip NaN rows; if EVERY fit was
    # skipped — criterion-1 failure / heavy censoring — the panels stay empty
    # and panel b carries the story, per the spec's surprise handling)
    fok = fits[.!isnan.(fits.f0), :]
    xs  = collect(1:max(nrow(fok), 1))
    p_f0 = plot(title = "fitted f0 (divergence)", titlefont = 10,
                xlabel = "initial cash", ylabel = "f0",
                guidefont = 8, tickfont = 7, legend = false,
                xlims = (0.5, max(nrow(fok), 1) + 0.5))
    p_B = plot(title = "fitted barrier coefficient B", titlefont = 10,
               xlabel = "initial cash", ylabel = "B",
               guidefont = 8, tickfont = 7, legend = false,
               xlims = (0.5, max(nrow(fok), 1) + 0.5))
    if nrow(fok) > 0
        plot!(p_f0, xticks = (xs, string.(Int.(fok.cash))))
        scatter!(p_f0, xs, fok.f0,
                 yerror = (fok.f0 .- fok.f0_lo, fok.f0_hi .- fok.f0),
                 color = [cash_color[c] for c in fok.cash], markersize = 6,
                 markerstrokewidth = 0.5)
        hline!(p_f0, [F0_REF], color = :black, ls = :dash, lw = 1.0)
        plot!(p_B, xticks = (xs, string.(Int.(fok.cash))))
        scatter!(p_B, xs, fok.B, yerror = (fok.B .- fok.B_lo, fok.B_hi .- fok.B),
                 color = [cash_color[c] for c in fok.cash], markersize = 6,
                 markerstrokewidth = 0.5)
        hline!(p_B, [B_REF], color = :black, ls = :dash, lw = 1.0)
    end

    fig = plot(p_tau, p_rate, p_f0, p_B; layout = (2, 2), size = (1150, 950),
               left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
               plot_title = "Escape-time barrier law under budgets (dashed: Model A reference)",
               plot_titlefontsize = 11)
    savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-BarrierLaw.pdf"))
    @info "Saved: ModelB-Nucleation-BarrierLaw.pdf"
end
```

- [ ] **Step 2: Run it standalone and inspect**

Run: `julia code/model-b/Figs-ModelB-BarrierLaw.jl`
Expected: `Saved: ModelB-Nucleation-BarrierLaw.pdf`; open the PDF and check: log-scale medians rise toward each cash level's divergence, fit curves overlay the points, Model A dashed curve visible, CI whiskers present on f0/B panels. If all three fit rows were NaN (criterion-1 failure), panels c/d are empty and panel b carries the story — still a valid figure; note it.

- [ ] **Step 3: Commit**

```bash
git add code/model-b/Figs-ModelB-BarrierLaw.jl code/figs/ModelB-Nucleation-BarrierLaw.pdf
git commit -m "Add barrier-law figure: Model B escape-time divergence vs Model A reference

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CL5rGoKjgPYiw4BG9pdcAx"
```

---

### Task 9: Velocity-vs-suppression figure (A2)

**Files:**
- Create: `code/model-b/Figs-ModelB-VelocitySuppression.jl`

**Interfaces:**
- Consumes: `ModelB-EscapeTime.csv`; lib function `spearman_perm_p` (recomputed from CSV rows — deterministic, same rng)
- Produces: `code/figs/ModelB-Nucleation-VelocitySuppression.pdf`

- [ ] **Step 1: Write the figure script**

Create `code/model-b/Figs-ModelB-VelocitySuppression.jl`:

```julia
# Figs-ModelB-VelocitySuppression.jl — the A2 dose-response figure, drawn
# ENTIRELY from code/data/ModelB-EscapeTime.csv (no simulation).
# Standalone-rerunnable from the repo root:
#   julia code/model-b/Figs-ModelB-VelocitySuppression.jl
#
# Writes: code/figs/ModelB-Nucleation-VelocitySuppression.pdf
#
# Suppression is ABSOLUTE (suppressed buy orders/step, unnormalized) — the
# per-panel-scaling flaw this analysis exists to fix. Spearman ρ and the
# +1-corrected permutation p are recomputed here from the CSV via the lib
# (fixed rng ⇒ same numbers as the compute log).

isdefined(Main, :_PATH_TO_DATA)    || include(joinpath(@__DIR__, "Include.jl"))
isdefined(Main, :spearman_perm_p)  || include(joinpath(@__DIR__, "EscapeTime-Lib.jl"))

let
    df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-EscapeTime.csv"), DataFrame)
    a2 = df[(df.f .== 0.20) .& .!isnan.(df.v_front), :]
    n_excluded = count((df.f .== 0.20) .& isnan.(df.v_front))

    cashes = sort(unique(a2.cash))
    base_colors = ["#009E73", _BUY_COLOR, "#E69F00", "#CC79A7", _SELL_COLOR]
    cash_color  = Dict(c => base_colors[i] for (i, c) in enumerate(cashes))

    sp = spearman_perm_p(collect(Float64.(a2.suppb_w)), collect(Float64.(a2.v_front)))

    p1 = plot(title = "Spearman ρ = $(round(sp.rho, digits = 3)), permutation p = $(round(sp.p, digits = 4)) (n = $(nrow(a2)), excl. $(n_excluded))",
              titlefont = 9, xlabel = "suppressed buy orders / step (absolute)",
              ylabel = "front velocity × 1e4 (fraction/step)",
              guidefont = 8, tickfont = 7, legend = :topright, legendfontsize = 6)
    for cash in cashes
        s = a2[a2.cash .== cash, :]
        scatter!(p1, s.suppb_w, s.v_front .* 1e4, color = cash_color[cash],
                 markersize = 4, markerstrokewidth = 0.3, alpha = 0.75,
                 label = "cash $(Int(cash)) (n=$(nrow(s)))")
        scatter!(p1, [median(s.suppb_w)], [median(s.v_front) * 1e4],
                 color = cash_color[cash], marker = :diamond, markersize = 9,
                 markerstrokewidth = 1.2, markerstrokecolor = :black, label = "")
    end

    p2 = plot(title = "velocity by budget dose", titlefont = 10,
              xlabel = "initial cash", ylabel = "front velocity × 1e4",
              xscale = :log10, guidefont = 8, tickfont = 7, legend = false)
    for cash in cashes
        s = a2[a2.cash .== cash, :]
        scatter!(p2, fill(cash, nrow(s)), s.v_front .* 1e4,
                 color = cash_color[cash], markersize = 4, markerstrokewidth = 0.3,
                 alpha = 0.75)
        plot!(p2, [cash / 1.25, cash * 1.25], fill(median(s.v_front) * 1e4, 2),
              color = :black, lw = 2.0)
    end

    fig = plot(p1, p2; layout = (1, 2), size = (1150, 520),
               left_margin = 6Plots.mm, bottom_margin = 5Plots.mm,
               plot_title = "Front velocity vs absolute budget suppression (f = 0.20, window [t_on+50, t_on+400])",
               plot_titlefontsize = 11)
    savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-VelocitySuppression.pdf"))
    @info "Saved: ModelB-Nucleation-VelocitySuppression.pdf"
end
```

- [ ] **Step 2: Run it standalone and inspect**

Run: `julia code/model-b/Figs-ModelB-VelocitySuppression.jl`
Expected: `Saved: ModelB-Nucleation-VelocitySuppression.pdf`; check: five dose colors present, per-dose median diamonds visible, title annotation matches the compute log's rho/p exactly (same rng — a mismatch means the CSV changed since the log).

- [ ] **Step 3: Commit**

```bash
git add code/model-b/Figs-ModelB-VelocitySuppression.jl code/figs/ModelB-Nucleation-VelocitySuppression.pdf
git commit -m "Add velocity-vs-suppression figure: absolute dose-response at f=0.20

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CL5rGoKjgPYiw4BG9pdcAx"
```

---

### Task 10: Closeout — verification sweep, spec amendments, memory update

**Files:**
- Modify: `docs/superpowers/specs/2026-07-20-nucleation-spine-restructure-design.md` (append Amendments section)
- Modify: memory files (outside the repo)

**Interfaces:**
- Consumes: everything above
- Produces: a verified, recorded Phase 1 — the input state for the Phase 2 (paper-writing) planning session

- [ ] **Step 1: Full verification sweep**

Run each; all must pass:
- `julia code/model-b/Test-EscapeTime.jl` → all PASS
- `git status --porcelain code/data/ code/figs/` → empty (everything committed)
- `julia code/model-b/Figs-ModelB-BarrierLaw.jl && julia code/model-b/Figs-ModelB-VelocitySuppression.jl && git status --porcelain code/figs/` → empty (figures reproduce byte-stable from CSVs alone; if PDFs embed timestamps and diff, note it and verify visually instead — do not chase PDF-metadata noise)

- [ ] **Step 2: Append an Amendments section to the spec**

Append to `docs/superpowers/specs/2026-07-20-nucleation-spine-restructure-design.md`:

```markdown
---

# Amendments (Phase 1 execution, YYYY-MM-DD)

1. Pilot f-grid swapped 0.21 → 0.20 so the pilot hits the canonical f = 0.20
   config line (probe/seed-sweep/toggle/boundary-vs-bulk) and doubles as the
   A2 slice. (Plan decision, recorded before the pilot ran.)
2. Refinement grid chosen from the pilot (Task 6): [record the actual
   (f, cash) list and the onset-rate table that drove it].
3. [Record A1/A2 outcomes vs the confirmation criteria — met / not met /
   fallback engaged — with the headline numbers.]
```

Commit:

```bash
git add docs/superpowers/specs/2026-07-20-nucleation-spine-restructure-design.md
git commit -m "Record Phase 1 amendments and outcomes in the nucleation-spine spec

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CL5rGoKjgPYiw4BG9pdcAx"
```

- [ ] **Step 3: Update project memory**

In `/Users/jdv27/.claude/projects/-Users-jdv27-Desktop-julia-work-Wolfram-markets-abm-paper/memory/`:
- `model-b-nucleation-pivot.md`: append a dated block with the A1 fit table (A, B, f0, r2, CIs per cash), criterion outcomes, A2 (rho, p), data/figure paths, and commit hashes.
- `MEMORY.md`: replace the RESUME HERE line with: Phase 1 DONE (commits …); **RESUME HERE: plan Phase 2 (paper restructure writing) via superpowers:writing-plans against the spec + Phase 1 numbers.**

- [ ] **Step 4: Report completion**

Summarize for the user: headline numbers, criteria met/not met, any surprise-handling engaged, and that the next session should plan Phase 2 (the paper rewrite) with these results in hand.
