# Boundary-vs-Bulk Seeding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Determine whether Model B's dominant sell nucleus is boundary-seeded (edge ring) or bulk-seeded (interior), via backward-lineage birth-site tracking (arm 1) plus a paired patch-seeding intervention (arm 2).

**Architecture:** Pure, unit-testable helpers (cluster labeling, lineage tracers, patch geometry, analytic null) live in `code/model-b/BoundaryVsBulk-Lib.jl`; the sweep script `Compute-ModelB-BoundaryVsBulk.jl` includes the lib and runs the two staged arms threaded, writing two CSVs and two figures. `Test-BoundaryVsBulk.jl` unit-tests the lib. This is a deliberate refinement of the spec's "one script": the compute entry point is still a single script, but the algorithms are testable without triggering the 200-run sweep.

**Tech Stack:** Julia (project env at `code/`), DataFrames/CSV, Plots/StatsPlots, Distributions, `Test` stdlib. Simulation via the existing `simulate(::MyModelBConfiguration)` — **no changes to `code/src/`**.

**Spec:** `docs/superpowers/specs/2026-07-17-boundary-vs-bulk-seeding-design.md`

## Global Constraints

- No changes to `code/src/` (spec scope).
- Configs: freeze (f=0.20, cash=500) and collapse (f=0.20, cash=5000); λ=0.02, k=1.0, edge_band_spread=0.5, cost_basis_rule=false, P0=100. Grid 64×64, STEPS=1500, seeds 1:20.
- Onset: largest **interior-only** sell cluster ≥ 5% of the full grid (ONSET_FRAC=0.05, N=64²).
- Cluster labeling: BFS, 4-neighbour, rows/cols 2..N−1 only, state==2 (Sell).
- Smoke mode: `BVB_SMOKE=1` → GRIDN=32, STEPS=300, seeds 1:2, ONSET_FRAC=0.01 (low threshold so lineage/figure paths execute on a tiny run; outputs are smoke artifacts, not science).
- Threading contract (as Stage 2): results land in preallocated slots indexed by work-item id; all file I/O and plotting OUTSIDE the threaded loop; no un-seeded RNG inside the loop.
- Data: `code/data/ModelB-Nucleation-BirthSites.csv`, `code/data/ModelB-Nucleation-SeedingIntervention.csv`. Figures (via `savefig` to `_PATH_TO_FIGS` only, like the other nucleation figures): `code/figs/ModelB-Nucleation-BirthSites.pdf`, `code/figs/ModelB-Nucleation-Seeding.pdf`.
- Run tests from repo root: `julia code/model-b/Test-BoundaryVsBulk.jl` (slow first load — Plots precompile — is normal).
- Commit after every task; never `--no-verify`.

---

### Task 1: Lib skeleton + scalar helpers (distance, null PMF, binomial test, patch side)

**Files:**
- Create: `code/model-b/BoundaryVsBulk-Lib.jl`
- Create: `code/model-b/Test-BoundaryVsBulk.jl`

**Interfaces:**
- Consumes: `Distributions.Binomial`, `Distributions.pdf` (loaded by `Include.jl`).
- Produces:
  - `chebyshev_boundary_distance(r::Int, c::Int, nr::Int, nc::Int)::Int`
  - `null_shell_pmf(gridn::Int)::Vector{Float64}` — index j = P(d=j), j=1..gridn÷2−1
  - `binom_two_sided_p(n::Int, k::Int, p::Float64)::Float64`
  - `patch_side(m::Real)::Int` — 3 or 5

- [ ] **Step 1: Write the failing test file**

Create `code/model-b/Test-BoundaryVsBulk.jl`:

```julia
# Test-BoundaryVsBulk.jl — unit tests for BoundaryVsBulk-Lib.jl
# Run from repo root: julia code/model-b/Test-BoundaryVsBulk.jl

include(joinpath(@__DIR__, "Include.jl"))
include(joinpath(@__DIR__, "BoundaryVsBulk-Lib.jl"))
using Test

@testset "chebyshev_boundary_distance" begin
    @test chebyshev_boundary_distance(2, 2, 64, 64)   == 1
    @test chebyshev_boundary_distance(32, 32, 64, 64) == 31
    @test chebyshev_boundary_distance(1, 10, 64, 64)  == 0   # boundary cell
    @test chebyshev_boundary_distance(2, 63, 64, 64)  == 1
end

@testset "null_shell_pmf" begin
    pmf = null_shell_pmf(64)
    @test length(pmf) == 31
    @test pmf[1] ≈ 244 / 3844          # (62² − 60²)/62²
    @test sum(pmf) ≈ 1.0
    @test sum(pmf[1:2]) ≈ 480 / 3844   # ≈ 0.125, the d ≤ 2 null

    small = null_shell_pmf(6)          # 4×4 interior: 12 cells at d=1, 4 at d=2
    @test small ≈ [12 / 16, 4 / 16]
end

@testset "binom_two_sided_p" begin
    @test binom_two_sided_p(6, 3, 0.5) ≈ 1.0
    @test binom_two_sided_p(6, 0, 0.5) ≈ 2 * (1 / 64)
    @test binom_two_sided_p(3, 3, 0.125) ≈ 0.125^3
end

@testset "patch_side" begin
    @test patch_side(9)  == 3
    @test patch_side(25) == 5
    @test patch_side(17) == 3   # tie → 3
    @test patch_side(1)  == 3
    @test patch_side(40) == 5
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `julia code/model-b/Test-BoundaryVsBulk.jl`
Expected: FAIL / error — `SystemError: opening file ... BoundaryVsBulk-Lib.jl` (file does not exist yet).

- [ ] **Step 3: Write the lib skeleton with the four helpers**

Create `code/model-b/BoundaryVsBulk-Lib.jl`:

```julia
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `julia code/model-b/Test-BoundaryVsBulk.jl`
Expected: `Test Summary: | Pass  Total` — all 4 testsets pass, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add code/model-b/BoundaryVsBulk-Lib.jl code/model-b/Test-BoundaryVsBulk.jl
git commit -m "Add boundary-vs-bulk lib: distance, analytic null, binomial test, patch sizing"
```

---

### Task 2: Interior-only cluster labeling

**Files:**
- Modify: `code/model-b/BoundaryVsBulk-Lib.jl` (append)
- Modify: `code/model-b/Test-BoundaryVsBulk.jl` (append)

**Interfaces:**
- Produces:
  - `label_interior_sell_clusters(grid::Matrix{Int64})::Tuple{Matrix{Int16}, Vector{Int}}` — labels (0 = unlabeled), `sizes[l]` = cell count of cluster l; labels assigned in row-major discovery order
  - `label_sequence(frames::Dict{Int64,Matrix{Int64}}, steps::Int)::Tuple{Vector{Matrix{Int16}}, Vector{Vector{Int}}}` — per-step labels/sizes for t = 1..steps
  - `cluster_cells(labels::Matrix{Int16}, lab::Integer)::Vector{CartesianIndex{2}}`

- [ ] **Step 1: Append failing tests**

Append to `Test-BoundaryVsBulk.jl`:

```julia
@testset "label_interior_sell_clusters" begin
    g = fill(1, 8, 8)
    g[2, 2] = 2; g[2, 3] = 2; g[3, 2] = 2      # blob A (row-major first)
    g[6, 6] = 2; g[7, 6] = 2                   # blob B
    g[5, 2] = 2                                # singleton C
    g[1, 4] = 2; g[8, 8] = 2; g[4, 1] = 2      # boundary sells — excluded
    labels, sizes = label_interior_sell_clusters(g)
    @test sizes == [3, 1, 2]                   # row-major discovery: A, C, B
    @test labels[2, 2] == labels[2, 3] == labels[3, 2] == 1
    @test labels[5, 2] == 2
    @test labels[6, 6] == labels[7, 6] == 3
    @test labels[1, 4] == 0 && labels[8, 8] == 0 && labels[4, 1] == 0
    @test Set(cluster_cells(labels, 1)) ==
          Set([CartesianIndex(2, 2), CartesianIndex(2, 3), CartesianIndex(3, 2)])

    empty_labels, empty_sizes = label_interior_sell_clusters(fill(1, 8, 8))
    @test isempty(empty_sizes) && all(==(0), empty_labels)
end

@testset "label_sequence" begin
    g1 = fill(1, 6, 6); g1[3, 3] = 2
    g2 = fill(1, 6, 6); g2[3, 3] = 2; g2[3, 4] = 2
    frames = Dict{Int64,Matrix{Int64}}(0 => fill(1, 6, 6), 1 => g1, 2 => g2)
    labels, sizes = label_sequence(frames, 2)
    @test length(labels) == 2
    @test sizes[1] == [1] && sizes[2] == [2]
end
```

- [ ] **Step 2: Run tests to verify the new testsets fail**

Run: `julia code/model-b/Test-BoundaryVsBulk.jl`
Expected: earlier testsets pass; new ones error with `UndefVarError: label_interior_sell_clusters not defined`.

- [ ] **Step 3: Append implementation to the lib**

Append to `BoundaryVsBulk-Lib.jl`:

```julia
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `julia code/model-b/Test-BoundaryVsBulk.jl`
Expected: all testsets pass.

- [ ] **Step 5: Commit**

```bash
git add code/model-b/BoundaryVsBulk-Lib.jl code/model-b/Test-BoundaryVsBulk.jl
git commit -m "Add interior-only sell-cluster labeling for lineage tracking"
```

---

### Task 3: Lineage tracers (backward to birth, forward from patch)

**Files:**
- Modify: `code/model-b/BoundaryVsBulk-Lib.jl` (append)
- Modify: `code/model-b/Test-BoundaryVsBulk.jl` (append)

**Interfaces:**
- Consumes: `label_sequence`, `cluster_cells` (Task 2).
- Produces:
  - `max_overlap_label(labelmat::Matrix{Int16}, sizes::Vector{Int}, cells::Vector{CartesianIndex{2}})::Int16` — 0 if no overlap; ties: larger overlap → larger size → smaller label
  - `trace_backward(labels, sizes, t0::Int, lab0::Integer)::Vector{Tuple{Int,Int16}}` — chain of (step, label) from birth to t0 inclusive, ascending; gap-1 tolerant; `chain[1][1]` is birth_step
  - `trace_forward(labels, sizes, seed_cells::Vector{CartesianIndex{2}}, t_end::Int)` → `(max_size::Int, last_alive::Int, chain::Vector{Tuple{Int,Int16}})` — starts at t=1; `(0, 0, [])` if the seed has no overlap at t=1

- [ ] **Step 1: Append failing tests**

Append to `Test-BoundaryVsBulk.jl`:

```julia
"""Build (labels, sizes) sequences from a vector of hand-made grids."""
function _labelseq(grids::Vector{Matrix{Int64}})
    frames = Dict{Int64,Matrix{Int64}}(t => g for (t, g) in enumerate(grids))
    return label_sequence(frames, length(grids))
end

@testset "max_overlap_label tie-breaking" begin
    g = fill(1, 8, 8)
    g[2, 2] = 2                    # label 1, size 1
    g[4, 4] = 2; g[4, 5] = 2       # label 2, size 2
    labels, sizes = label_interior_sell_clusters(g)
    # one query cell on each cluster → overlap tie 1–1 → larger size wins
    cells = [CartesianIndex(2, 2), CartesianIndex(4, 4)]
    @test max_overlap_label(labels, sizes, cells) == 2
    # no overlap anywhere → 0
    @test max_overlap_label(labels, sizes, [CartesianIndex(6, 6)]) == 0
    # equal overlap AND equal size → smaller label
    g2 = fill(1, 8, 8); g2[2, 2] = 2; g2[4, 4] = 2
    l2, s2 = label_interior_sell_clusters(g2)
    @test max_overlap_label(l2, s2, [CartesianIndex(2, 2), CartesianIndex(4, 4)]) == 1
end

@testset "trace_backward: growth, birth, gap-1 flicker" begin
    blob(cells) = (g = fill(1, 8, 8); for (r, c) in cells; g[r, c] = 2; end; g)
    # t1: 1 cell → t2: 3 cells → t3: 5 cells; birth at t=1
    labels, sizes = _labelseq([blob([(4, 4)]),
                               blob([(4, 4), (4, 5), (5, 4)]),
                               blob([(4, 4), (4, 5), (5, 4), (5, 5), (3, 4)])])
    chain = trace_backward(labels, sizes, 3, 1)
    @test chain == [(1, Int16(1)), (2, Int16(1)), (3, Int16(1))]

    # flicker: present t1, absent t2, present t3 → gap-1 bridges to t1
    labels_f, sizes_f = _labelseq([blob([(4, 4), (4, 5)]),
                                   fill(1, 8, 8),
                                   blob([(4, 4), (4, 5), (5, 4)])])
    chain_f = trace_backward(labels_f, sizes_f, 3, 1)
    @test chain_f == [(1, Int16(1)), (3, Int16(1))]

    # true birth mid-sequence: nothing at t1 or t2, blob appears at t3
    labels_b, sizes_b = _labelseq([fill(1, 8, 8), fill(1, 8, 8), blob([(4, 4)])])
    chain_b = trace_backward(labels_b, sizes_b, 3, 1)
    @test chain_b == [(3, Int16(1))]
end

@testset "trace_forward from a seed patch" begin
    blob(cells) = (g = fill(1, 8, 8); for (r, c) in cells; g[r, c] = 2; end; g)
    seed = [CartesianIndex(4, 4), CartesianIndex(4, 5)]
    # grows then dies at t3
    labels, sizes = _labelseq([blob([(4, 4), (4, 5)]),
                               blob([(4, 4), (4, 5), (5, 4)]),
                               fill(1, 8, 8),
                               fill(1, 8, 8)])
    fwd = trace_forward(labels, sizes, seed, 4)
    @test fwd.max_size == 3 && fwd.last_alive == 2
    # seed never materializes
    dead = trace_forward(_labelseq([fill(1, 8, 8), fill(1, 8, 8)])..., seed, 2)
    @test dead.max_size == 0 && dead.last_alive == 0 && isempty(dead.chain)
    # gap-1 forward: alive t1, gone t2, back t3
    labels_g, sizes_g = _labelseq([blob([(4, 4), (4, 5)]),
                                   fill(1, 8, 8),
                                   blob([(4, 4), (4, 5), (5, 4), (5, 5)])])
    fwd_g = trace_forward(labels_g, sizes_g, seed, 3)
    @test fwd_g.max_size == 4 && fwd_g.last_alive == 3
end
```

- [ ] **Step 2: Run tests to verify the new testsets fail**

Run: `julia code/model-b/Test-BoundaryVsBulk.jl`
Expected: `UndefVarError: max_overlap_label not defined` in the new testsets; earlier testsets still pass.

- [ ] **Step 3: Append implementation to the lib**

Append to `BoundaryVsBulk-Lib.jl`:

```julia
"""
    max_overlap_label(labelmat, sizes, cells) → Int16

Label at `labelmat` with maximal overlap against `cells`; 0 if none. Ties
broken by larger overlap count, then larger cluster size, then smaller label
(= earlier row-major first cell), per spec §1.
"""
function max_overlap_label(labelmat::Matrix{Int16}, sizes::Vector{Int},
                           cells::Vector{CartesianIndex{2}})::Int16
    counts = Dict{Int16,Int}()
    for cell in cells
        l = labelmat[cell]
        l == 0 && continue
        counts[l] = get(counts, l, 0) + 1
    end
    isempty(counts) && return Int16(0)
    best = Int16(0); bestcount = -1
    for l in sort!(collect(keys(counts)))          # ascending label order
        cnt = counts[l]
        if cnt > bestcount || (cnt == bestcount && sizes[l] > sizes[best])
            best = l; bestcount = cnt
        end
    end
    return best
end

"""
    trace_backward(labels, sizes, t0, lab0) → chain

Backward max-overlap lineage of cluster `lab0` at step `t0` down to birth.
Returns (step, label) pairs ascending from birth to t0; skipped flicker steps
(gap-1 tolerance, spec §1) simply do not appear in the chain.
"""
function trace_backward(labels::Vector{Matrix{Int16}}, sizes::Vector{Vector{Int}},
                        t0::Int, lab0::Integer)::Vector{Tuple{Int,Int16}}
    chain = [(t0, Int16(lab0))]
    t, lab = t0, Int16(lab0)
    while t > 1
        cells = cluster_cells(labels[t], lab)
        prev  = t - 1
        p     = max_overlap_label(labels[prev], sizes[prev], cells)
        if p == 0 && t - 2 >= 1
            prev = t - 2
            p    = max_overlap_label(labels[prev], sizes[prev], cells)
        end
        p == 0 && break
        pushfirst!(chain, (prev, p))
        t, lab = prev, p
    end
    return chain
end

"""
    trace_forward(labels, sizes, seed_cells, t_end)
        → (max_size, last_alive, chain)

Forward max-overlap lineage seeded by `seed_cells` (t = 0 patch coordinates)
starting at t = 1, gap-1 tolerant, stopping at extinction or t_end.
"""
function trace_forward(labels::Vector{Matrix{Int16}}, sizes::Vector{Vector{Int}},
                       seed_cells::Vector{CartesianIndex{2}}, t_end::Int)
    chain = Tuple{Int,Int16}[]
    lab   = max_overlap_label(labels[1], sizes[1], seed_cells)
    lab == 0 && return (max_size = 0, last_alive = 0, chain = chain)
    push!(chain, (1, lab))
    max_size = sizes[1][lab]
    t = 1
    while t < t_end
        cells = cluster_cells(labels[t], chain[end][2])
        nxt   = t + 1
        s     = max_overlap_label(labels[nxt], sizes[nxt], cells)
        if s == 0 && t + 2 <= t_end
            nxt = t + 2
            s   = max_overlap_label(labels[nxt], sizes[nxt], cells)
        end
        s == 0 && break
        push!(chain, (nxt, s))
        max_size = max(max_size, sizes[nxt][s])
        t = nxt
    end
    return (max_size = max_size, last_alive = chain[end][1], chain = chain)
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `julia code/model-b/Test-BoundaryVsBulk.jl`
Expected: all testsets pass. (Note the `trace_forward` gap-1 test: after a gap the trace continues from the PRE-gap cells, which is why `fwd_g.last_alive == 3`.)

- [ ] **Step 5: Commit**

```bash
git add code/model-b/BoundaryVsBulk-Lib.jl code/model-b/Test-BoundaryVsBulk.jl
git commit -m "Add backward/forward max-overlap lineage tracers with gap-1 tolerance"
```

---

### Task 4: Patch geometry, stamping, and ring-attachment detection

**Files:**
- Modify: `code/model-b/BoundaryVsBulk-Lib.jl` (append)
- Modify: `code/model-b/Test-BoundaryVsBulk.jl` (append)

**Interfaces:**
- Consumes: `cluster_cells` (Task 2).
- Produces:
  - `clamp_patch_center(r::Int, c::Int, s::Int, nr::Int, nc::Int)::Tuple{Int,Int}`
  - `edge_patch_center(edge_coordinates::Vector{Tuple{Int64,Int64}}, s::Int, nr::Int, nc::Int)::Tuple{Int,Int}`
  - `patch_cells_square(center::Tuple{Int,Int}, s::Int)::Vector{CartesianIndex{2}}`
  - `stamp_patch!(grid::Matrix{Int64}, center::Tuple{Int,Int}, s::Int)`
  - `attach_step(frames::Dict{Int64,Matrix{Int64}}, labels::Vector{Matrix{Int16}}, chain::Vector{Tuple{Int,Int16}}, edge_set::Set{Tuple{Int64,Int64}})::Union{Int,Missing}`

- [ ] **Step 1: Append failing tests**

Append to `Test-BoundaryVsBulk.jl`:

```julia
@testset "patch geometry" begin
    @test clamp_patch_center(2, 40, 3, 64, 64) == (3, 40)   # pushed inward
    @test clamp_patch_center(32, 32, 5, 64, 64) == (32, 32)
    @test clamp_patch_center(63, 2, 5, 64, 64) == (61, 4)   # rows 59..63 stay interior

    ring = [(1, 10), (1, 40), (30, 64)]
    @test edge_patch_center(ring, 3, 64, 64) == (3, 40)     # nearest to (1,32) → (1,40)
    @test edge_patch_center([(20, 1)], 3, 64, 64) == (20, 3)
    @test edge_patch_center([(1, 1)], 3, 64, 64) == (3, 3)  # corner ring cell

    pc = patch_cells_square((3, 40), 3)
    @test length(pc) == 9
    @test CartesianIndex(2, 39) in pc && CartesianIndex(4, 41) in pc

    g = fill(1, 64, 64)
    stamp_patch!(g, (3, 40), 3)
    @test count(==(2), g) == 9 && g[3, 40] == 2 && g[2, 39] == 2
end

@testset "attach_step" begin
    g = fill(1, 8, 8)
    g[2, 2] = 2; g[3, 2] = 2                  # cluster hugging the top-left interior
    labels, sizes = label_interior_sell_clusters(g)
    chain  = [(1, Int16(1))]
    frames = Dict{Int64,Matrix{Int64}}(1 => copy(g))

    # active ring cell (1,2) currently Sell → attach at t=1
    frames[1][1, 2] = 2
    @test attach_step(frames, [labels], chain, Set([(1, 2)])) == 1
    # same cell active but Hold → no attachment
    frames[1][1, 2] = 1
    @test ismissing(attach_step(frames, [labels], chain, Set([(1, 2)])))
    # Sell boundary neighbour that is NOT an active ring cell → no attachment
    frames[1][1, 2] = 2
    @test ismissing(attach_step(frames, [labels], chain, Set([(1, 7)])))
    # side-boundary adjacency: (2,1) active + Sell, adjacent to (2,2)
    frames[1][1, 2] = 1; frames[1][2, 1] = 2
    @test attach_step(frames, [labels], chain, Set([(2, 1)])) == 1
end
```

- [ ] **Step 2: Run tests to verify the new testsets fail**

Run: `julia code/model-b/Test-BoundaryVsBulk.jl`
Expected: `UndefVarError: clamp_patch_center not defined`; earlier testsets pass.

- [ ] **Step 3: Append implementation to the lib**

Append to `BoundaryVsBulk-Lib.jl`:

```julia
"""Clamp an s×s patch center into the interior (rows/cols 2..N−1)."""
function clamp_patch_center(r::Int, c::Int, s::Int, nr::Int, nc::Int)::Tuple{Int,Int}
    h = (s - 1) ÷ 2
    return (clamp(r, 2 + h, nr - 1 - h), clamp(c, 2 + h, nc - 1 - h))
end

"""
    edge_patch_center(edge_coordinates, s, nr, nc) → (r, c)

Patch center for the `edge` arm: the interior cell adjacent (inward) to the
active ring cell nearest to top-center (1, nc÷2), clamped so the patch fits;
its outermost cells then sit at d = 1. Placement is relative to the RING, not
the frame, because ring cells cover only ~25% of the boundary and the
hypothesis is attachment to a driven cell (spec §2). Euclidean distance;
ties → first in the (sorted) edge_coordinates order.
"""
function edge_patch_center(edge_coordinates::Vector{Tuple{Int64,Int64}},
                           s::Int, nr::Int, nc::Int)::Tuple{Int,Int}
    tr, tc = 1.0, nc / 2
    best   = edge_coordinates[1]
    bestd  = Inf
    for (r, c) in edge_coordinates
        d = (r - tr)^2 + (c - tc)^2
        d < bestd && (best = (r, c); bestd = d)
    end
    rb, cb = best
    ri = rb == 1 ? 2 : rb == nr ? nr - 1 : Int(rb)
    ci = cb == 1 ? 2 : cb == nc ? nc - 1 : Int(cb)
    return clamp_patch_center(ri, ci, s, nr, nc)
end

"""Cells of the s×s square centered at `center`."""
function patch_cells_square(center::Tuple{Int,Int}, s::Int)::Vector{CartesianIndex{2}}
    h = (s - 1) ÷ 2
    return [CartesianIndex(r, c) for r in (center[1]-h):(center[1]+h)
                                 for c in (center[2]-h):(center[2]+h)]
end

"""Stamp an all-Sell s×s patch (overwrites background, spec §2)."""
function stamp_patch!(grid::Matrix{Int64}, center::Tuple{Int,Int}, s::Int)
    for cell in patch_cells_square(center, s)
        grid[cell] = 2
    end
    return grid
end

"""
    attach_step(frames, labels, chain, edge_set) → Int | missing

First lineage step at which any lineage cell is 4-adjacent to an ACTIVE ring
cell whose current state is Sell (spec §1). Frames store edge states as
written at each step (the CA never writes boundary cells).
"""
function attach_step(frames::Dict{Int64,Matrix{Int64}}, labels::Vector{Matrix{Int16}},
                     chain::Vector{Tuple{Int,Int16}},
                     edge_set::Set{Tuple{Int64,Int64}})::Union{Int,Missing}
    for (t, lab) in chain
        frame  = frames[t]
        nr, nc = size(frame)
        for cell in cluster_cells(labels[t], lab)
            r, c = Tuple(cell)
            for (dr, dc) in ((-1, 0), (1, 0), (0, -1), (0, 1))
                rn, cn = r + dr, c + dc
                (rn == 1 || rn == nr || cn == 1 || cn == nc) || continue
                ((rn, cn) in edge_set && frame[rn, cn] == 2) && return t
            end
        end
    end
    return missing
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `julia code/model-b/Test-BoundaryVsBulk.jl`
Expected: all testsets pass.

- [ ] **Step 5: Commit**

```bash
git add code/model-b/BoundaryVsBulk-Lib.jl code/model-b/Test-BoundaryVsBulk.jl
git commit -m "Add patch geometry, stamping, and ring-attachment detection"
```

---

### Task 5: Compute script — arm 1 (observational birth sites)

**Files:**
- Create: `code/model-b/Compute-ModelB-BoundaryVsBulk.jl`

**Interfaces:**
- Consumes: everything from Tasks 1–4; `simulate(::MyModelBConfiguration)`, `build(MyModelBConfiguration, ...)` from `code/src/` via `Include.jl`.
- Produces (for Tasks 6–7, all in this same file's global scope):
  - constants `SMOKE, GRIDN, STEPS, SEEDS, ONSET_FRAC, N_CELLS, P0, CONFIGS`
  - `_bvb_config(; f, cash, seed, initial_condition = :balanced_perturbation)`
  - `birth_df::DataFrame` (arm-1 rows), `S_PATCH::Int`
  - CSV `code/data/ModelB-Nucleation-BirthSites.csv` with columns `config, f, cash, seed, included, t_on, birth_step, birth_size, birth_row, birth_col, birth_dist, attached, attach_step, attached_before_onset` (0 sentinels where `included`/`attached` is false)

- [ ] **Step 1: Write the script header, constants, config builder, and arm-1 sweep**

Create `code/model-b/Compute-ModelB-BoundaryVsBulk.jl`:

```julia
# Compute-ModelB-BoundaryVsBulk.jl — where does the dominant sell nucleus come
# from: the price-driven edge ring (boundary-seeded) or the interior minority
# mixture (bulk-seeded)?
# Spec: docs/superpowers/specs/2026-07-17-boundary-vs-bulk-seeding-design.md
#
# Arm 1 (observational, 40 runs): backward max-overlap lineage from the onset
#   cluster to its birth site; birth distance-to-boundary vs the analytic
#   uniform null (P(d ≤ 2) ≈ 0.125 at 64²); ring-attachment timing.
# Arm 2 (interventional, 160 runs): paired 4-arm patch seeding — control /
#   edge (adjacent to the nearest active ring cell) / mid / center — on a
#   SHARED :custom background per (config, seed), so RNG consumption inside
#   simulate is identical across arms. Patch size is calibrated from arm 1's
#   pooled median birth size.
#
# Definitional notes (deliberate deviations from siblings):
# - STEPS = 1500 (seed sweep used 1000): the budget toggle saw onsets past
#   t = 1000; a 1000-step horizon censors late nucleators.
# - Cluster labeling is INTERIOR-ONLY (the probe/seed sweep labeled the full
#   grid): ring cells are exogenously band-driven. Onset threshold is still
#   5% of the FULL grid, as in the budget toggle.
#
# Writes: code/data/ModelB-Nucleation-BirthSites.csv
#         code/data/ModelB-Nucleation-SeedingIntervention.csv
#         code/figs/ModelB-Nucleation-BirthSites.pdf
#         code/figs/ModelB-Nucleation-Seeding.pdf
#
# Launch: julia -t 8 code/model-b/Compute-ModelB-BoundaryVsBulk.jl
# Smoke:  BVB_SMOKE=1 julia code/model-b/Compute-ModelB-BoundaryVsBulk.jl
#         (tiny grid, low onset threshold — exercises the paths, not the science)
#
# Threading contract (as Stage 2): results land in preallocated vectors
# indexed by work-item id; all file I/O and plotting happen OUTSIDE the
# threaded loop; no un-seeded RNG inside the loop.

include(joinpath(@__DIR__, "Include.jl"))
include(joinpath(@__DIR__, "BoundaryVsBulk-Lib.jl"))

const SMOKE = get(ENV, "BVB_SMOKE", "0") == "1"
SMOKE && @warn "BVB_SMOKE=1 — tiny grid, low onset threshold; outputs are smoke artifacts only"

const P0         = 100.0
const GRIDN      = SMOKE ? 32 : 64
const STEPS      = SMOKE ? 300 : 1500
const SEEDS      = SMOKE ? collect(1:2) : collect(1:20)
const ONSET_FRAC = SMOKE ? 0.01 : 0.05
const N_CELLS    = GRIDN * GRIDN

const CONFIGS = [
    (name = "freeze",   f = 0.20, cash =  500.0),
    (name = "collapse", f = 0.20, cash = 5000.0),
]

function _bvb_config(; f, cash, seed, initial_condition = :balanced_perturbation)
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
        initial_condition = initial_condition,
    ))
end

"""Largest interior cluster per step; onset = first step ≥ ONSET_FRAC of grid."""
function _onset(sizes::Vector{Vector{Int}})
    maxcl = [isempty(s) ? 0 : maximum(s) for s in sizes]
    t_on  = findfirst(m -> m >= ONSET_FRAC * N_CELLS, maxcl)
    return t_on, maxcl
end

const _EXCLUDED_BIRTH = (t_on = 0, birth_step = 0, birth_size = 0, birth_row = 0,
                         birth_col = 0, birth_dist = 0, attached = false,
                         attach_step = 0, attached_before_onset = false)

"""Arm 1: run one (config, seed), reduce to a birth-site row."""
function _run_birth(cfg::NamedTuple, seed::Int)
    res = simulate(_bvb_config(f = cfg.f, cash = cfg.cash, seed = seed);
                   snapshot_steps = collect(1:STEPS), verbose = false)
    labels, sizes = label_sequence(res.frames, STEPS)
    t_on, _ = _onset(sizes)
    base = (config = cfg.name, f = cfg.f, cash = cfg.cash, seed = seed)
    isnothing(t_on) && return merge(base, (included = false,), _EXCLUDED_BIRTH)

    chain     = trace_backward(labels, sizes, t_on, argmax(sizes[t_on]))
    bt, blab  = chain[1]
    bcells    = cluster_cells(labels[bt], blab)
    bdist     = minimum(chebyshev_boundary_distance(Tuple(cell)..., GRIDN, GRIDN)
                        for cell in bcells)
    at        = attach_step(res.frames, labels, chain, Set(res.edge_coordinates))
    @assert bt <= t_on "birth after onset (cfg=$(cfg.name) seed=$seed)"
    @assert sizes[bt][blab] >= 1 "empty birth cluster (cfg=$(cfg.name) seed=$seed)"
    return merge(base, (included = true, t_on = t_on, birth_step = bt,
                        birth_size = sizes[bt][blab],
                        birth_row  = round(Int, mean(getindex.(bcells, 1))),
                        birth_col  = round(Int, mean(getindex.(bcells, 2))),
                        birth_dist = bdist,
                        attached   = !ismissing(at),
                        attach_step = ismissing(at) ? 0 : at,
                        attached_before_onset = !ismissing(at) && at < t_on))
end

# ---------------------------------------------------------------------------
# Arm 1 sweep: 2 configs x seeds
# ---------------------------------------------------------------------------
birth_items = [(cfg = cfg, seed = seed) for cfg in CONFIGS for seed in SEEDS]
@info "Arm 1: birth-site tracking" n_runs = length(birth_items) grid = GRIDN steps = STEPS threads = Threads.nthreads()

birth_rows = Vector{Union{Nothing,NamedTuple}}(nothing, length(birth_items))
Threads.@threads :dynamic for i in eachindex(birth_items)
    birth_rows[i] = _run_birth(birth_items[i].cfg, birth_items[i].seed)
end
@assert all(!isnothing, birth_rows)

birth_df = DataFrame()
for r in birth_rows
    push!(birth_df, r)
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BirthSites.csv"), birth_df)
@info "Saved: ModelB-Nucleation-BirthSites.csv"

# Headline statistic: births with d ≤ 2 vs the analytic uniform null
const _NULL_PMF    = null_shell_pmf(GRIDN)
const _P_NEAR_NULL = sum(_NULL_PMF[1:2])

for name in [c.name for c in CONFIGS] ∪ ["pooled"]
    sub = name == "pooled" ? birth_df[birth_df.included, :] :
                             birth_df[(birth_df.config .== name) .& birth_df.included, :]
    n = nrow(sub)
    if n == 0
        @info "Arm 1 summary: $(name)" n = 0
        continue
    end
    k = count(sub.birth_dist .<= 2)
    @info "Arm 1 summary: $(name)" n = n frac_d_le_2 = round(k / n, digits = 3) null_frac = round(_P_NEAR_NULL, digits = 3) binom_p = round(binom_two_sided_p(n, k, _P_NEAR_NULL), sigdigits = 3) median_birth_dist = median(sub.birth_dist) median_birth_size = median(sub.birth_size) median_birth_step = median(sub.birth_step) attached_before_onset = count(sub.attached_before_onset)
end

# Patch size for arm 2, calibrated from the pooled median birth size (spec §2)
const _INCLUDED = birth_df[birth_df.included, :]
const S_PATCH   = nrow(_INCLUDED) == 0 ? 3 : patch_side(median(_INCLUDED.birth_size))
@info "Arm 2 patch calibration" s_patch = S_PATCH n_included = nrow(_INCLUDED)
```

- [ ] **Step 2: Smoke-run the script**

Run: `BVB_SMOKE=1 julia code/model-b/Compute-ModelB-BoundaryVsBulk.jl`
Expected: completes without error; logs `Arm 1: birth-site tracking n_runs = 4`, per-config summaries (n may be small or 0 at smoke scale — both fine), `Arm 2 patch calibration`, and `Saved: ModelB-Nucleation-BirthSites.csv`.

- [ ] **Step 3: Verify the smoke CSV shape, then restore it**

Run: `head -3 code/data/ModelB-Nucleation-BirthSites.csv && git status --short code/data/`
Expected: header row `config,f,cash,seed,included,t_on,birth_step,...` and 4 data rows.
Then discard the smoke artifact: `git checkout -- code/data/ 2>/dev/null; rm -f code/data/ModelB-Nucleation-BirthSites.csv` (file is new, so just delete it).

- [ ] **Step 4: Run the unit tests to confirm nothing regressed**

Run: `julia code/model-b/Test-BoundaryVsBulk.jl`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add code/model-b/Compute-ModelB-BoundaryVsBulk.jl
git commit -m "Add arm 1 of boundary-vs-bulk: birth-site tracking vs analytic null"
```

---

### Task 6: Compute script — arm 2 (paired patch seeding)

**Files:**
- Modify: `code/model-b/Compute-ModelB-BoundaryVsBulk.jl` (append)

**Interfaces:**
- Consumes: `S_PATCH`, `_bvb_config`, `_onset`, constants (Task 5); `build_edge_coordinates`, `build_initial_grid` (from `code/src/Factory.jl`); lib functions (Tasks 2–4).
- Produces:
  - `seed_df::DataFrame` (arm-2 rows) for Task 7
  - `trajs_map::Dict{Tuple{String,Int},Dict{String,Vector{Float64}}}` — (config, seed) → arm → largest-cluster-fraction trajectory, for Task 7's exemplar panel
  - `ARMS = ["control", "edge", "mid", "center"]`
  - CSV `code/data/ModelB-Nucleation-SeedingIntervention.csv` with columns `config, f, cash, seed, arm, patch_size, patch_row, patch_col, included, t_on, front_final, dominant_from_patch, patch_lineage_max, patch_alive_at_onset`

- [ ] **Step 1: Append the arm-2 sweep**

Append to `Compute-ModelB-BoundaryVsBulk.jl`:

```julia
# ---------------------------------------------------------------------------
# Arm 2: paired patch seeding — control / edge / mid / center on a shared
# :custom background. All four arms pass :custom, so RNG consumption inside
# simulate is identical across arms (same ring, same bands, same minority
# placement); arms differ ONLY in the stamped cells. The stamped patch
# overwrites the few background cells under it — identical background
# otherwise, negligible and location-dependent by construction.
# ---------------------------------------------------------------------------
const ARMS = ["control", "edge", "mid", "center"]

"""Arm 2: run the four paired arms for one (config, seed)."""
function _run_seeding(cfg::NamedTuple, seed::Int)
    base_cfg = _bvb_config(f = cfg.f, cash = cfg.cash, seed = seed)
    # Replicates simulate's draw (1) exactly: fresh Xoshiro(seed), edge sampling first
    ring = build_edge_coordinates(GRIDN, GRIDN, base_cfg.edge_fraction, Xoshiro(seed))
    # Shared background from a dedicated stream (spec §2)
    bg = build_initial_grid(base_cfg, Xoshiro(10_000 + seed))
    centers = Dict(
        "edge"   => edge_patch_center(ring, S_PATCH, GRIDN, GRIDN),
        "mid"    => clamp_patch_center(GRIDN ÷ 4 + 1, GRIDN ÷ 2, S_PATCH, GRIDN, GRIDN),
        "center" => clamp_patch_center(GRIDN ÷ 2, GRIDN ÷ 2, S_PATCH, GRIDN, GRIDN))

    rows      = NamedTuple[]
    trajs     = Dict{String,Vector{Float64}}()   # per-arm largest-cluster fraction
    ref_edges = nothing
    ref_k     = nothing
    n_warn    = 0
    for arm in ARMS
        grid = copy(bg)
        arm != "control" && stamp_patch!(grid, centers[arm], S_PATCH)
        res = simulate(_bvb_config(f = cfg.f, cash = cfg.cash, seed = seed,
                                   initial_condition = :custom);
                       initial_grid = grid, snapshot_steps = collect(1:STEPS),
                       verbose = false)
        if isnothing(ref_edges)
            ref_edges = res.edge_coordinates
            ref_k     = res.edge_k
            @assert ref_edges == ring "pre-computed ring mismatch (cfg=$(cfg.name) seed=$seed)"
        else
            @assert res.edge_coordinates == ref_edges "arm ring divergence (cfg=$(cfg.name) seed=$seed arm=$arm)"
            @assert res.edge_k == ref_k "arm band divergence (cfg=$(cfg.name) seed=$seed arm=$arm)"
        end

        labels, sizes = label_sequence(res.frames, STEPS)
        t_on, maxcl   = _onset(sizes)
        trajs[arm]    = maxcl ./ N_CELLS
        pc = arm == "control" ? CartesianIndex{2}[] :
                                patch_cells_square(centers[arm], S_PATCH)

        dominant = false
        if !isnothing(t_on) && arm != "control"
            chain    = trace_backward(labels, sizes, t_on, argmax(sizes[t_on]))
            bt, blab = chain[1]
            if bt == 1
                bset     = Set(cluster_cells(labels[bt], blab))
                dominant = any(in(bset), pc)
            end
        end
        fwd = arm == "control" ? (max_size = 0, last_alive = 0, chain = Tuple{Int,Int16}[]) :
                                 trace_forward(labels, sizes, pc, STEPS)
        alive_at_onset = !isnothing(t_on) && fwd.last_alive >= t_on
        # Forward/backward disagreement is REPORTED, not asserted (spec §3):
        # the tracers follow max-overlap in opposite directions and can
        # legitimately route through different branches.
        (arm != "control" && dominant && !alive_at_onset) && (n_warn += 1)

        push!(rows, (config = cfg.name, f = cfg.f, cash = cfg.cash, seed = seed,
                     arm = arm, patch_size = arm == "control" ? 0 : S_PATCH,
                     patch_row = arm == "control" ? 0 : centers[arm][1],
                     patch_col = arm == "control" ? 0 : centers[arm][2],
                     included = !isnothing(t_on),
                     t_on = isnothing(t_on) ? 0 : t_on,
                     front_final = maxcl[STEPS] / N_CELLS,
                     dominant_from_patch = dominant,
                     patch_lineage_max = fwd.max_size,
                     patch_alive_at_onset = alive_at_onset))
    end
    return (rows = rows, n_warn = n_warn, trajs = trajs)
end

# ---------------------------------------------------------------------------
# Arm 2 sweep: one work item per (config, seed); each runs its 4 arms serially
# so the pairing assertions live inside the item
# ---------------------------------------------------------------------------
seed_items = [(cfg = cfg, seed = seed) for cfg in CONFIGS for seed in SEEDS]
@info "Arm 2: paired patch seeding" n_items = length(seed_items) arms = length(ARMS) s_patch = S_PATCH

seed_results = Vector{Union{Nothing,NamedTuple}}(nothing, length(seed_items))
Threads.@threads :dynamic for i in eachindex(seed_items)
    seed_results[i] = _run_seeding(seed_items[i].cfg, seed_items[i].seed)
end
@assert all(!isnothing, seed_results)

total_warn = sum(r.n_warn for r in seed_results)
total_warn > 0 && @warn "forward/backward lineage disagreement" n = total_warn

trajs_map = Dict{Tuple{String,Int},Dict{String,Vector{Float64}}}()
for (item, r) in zip(seed_items, seed_results)
    trajs_map[(item.cfg.name, item.seed)] = r.trajs
end

seed_df = DataFrame()
for r in seed_results, row in r.rows
    push!(seed_df, row)
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedingIntervention.csv"), seed_df)
@info "Saved: ModelB-Nucleation-SeedingIntervention.csv"

# ---------------------------------------------------------------------------
# Arm 2 statistics: paired onset advance (sign-flip permutation, as the
# budget toggle) and dominance rates; McNemar-style edge-vs-center contrast
# ---------------------------------------------------------------------------
function _signflip_p(dv::Vector{Float64}; n_draws::Int = 20_000)
    isempty(dv) && return NaN
    rng  = Xoshiro(7)
    dobs = abs(mean(dv))
    hits = 0
    for _ in 1:n_draws
        hits += abs(mean(dv .* rand(rng, (-1.0, 1.0), length(dv)))) >= dobs
    end
    return hits / n_draws
end

"""t_on lookup: config × seed × arm → t_on (missing if that run had no onset)."""
function _ton(df, name, seed, arm)
    sub = df[(df.config .== name) .& (df.seed .== seed) .& (df.arm .== arm), :]
    return sub.included[1] ? sub.t_on[1] : missing
end

for cfg in CONFIGS
    for arm in ARMS[2:end]
        dts   = Float64[]
        for seed in SEEDS
            tc = _ton(seed_df, cfg.name, seed, "control")
            ta = _ton(seed_df, cfg.name, seed, arm)
            (ismissing(tc) || ismissing(ta)) && continue
            push!(dts, float(tc - ta))          # >0 ⇒ patch advanced onset
        end
        dom = seed_df[(seed_df.config .== cfg.name) .& (seed_df.arm .== arm), :dominant_from_patch]
        @info "Arm 2 summary: $(cfg.name)/$(arm)" n_pairs = length(dts) median_onset_advance = isempty(dts) ? NaN : median(dts) sign_pos = count(>(0), dts) signflip_p = _signflip_p(dts) dominance = "$(count(dom))/$(length(dom))"
    end
    # McNemar-style paired edge-vs-center dominance contrast
    b = 0; c = 0
    for seed in SEEDS
        de = seed_df[(seed_df.config .== cfg.name) .& (seed_df.seed .== seed) .& (seed_df.arm .== "edge"),   :dominant_from_patch][1]
        dc = seed_df[(seed_df.config .== cfg.name) .& (seed_df.seed .== seed) .& (seed_df.arm .== "center"), :dominant_from_patch][1]
        de && !dc && (b += 1)
        !de && dc && (c += 1)
    end
    p_mcn = b + c == 0 ? NaN : binom_two_sided_p(b + c, b, 0.5)
    @info "Arm 2 edge-vs-center dominance: $(cfg.name)" edge_only = b center_only = c mcnemar_p = p_mcn
end
```

- [ ] **Step 2: Smoke-run the script**

Run: `BVB_SMOKE=1 julia code/model-b/Compute-ModelB-BoundaryVsBulk.jl`
Expected: arm 1 completes as before, then `Arm 2: paired patch seeding n_items = 4 arms = 4`, both CSVs saved, per-arm summaries print (NaN/0-pair values are fine at smoke scale), no assertion failures.

- [ ] **Step 3: Verify pairing invariants in the smoke CSV, then clean up**

Run: `cut -d, -f5 code/data/ModelB-Nucleation-SeedingIntervention.csv | sort | uniq -c`
Expected: 4 (header +) equal counts for arms `center, control, edge, mid` — 4 rows each (2 configs × 2 smoke seeds).
Then delete both smoke CSVs: `rm -f code/data/ModelB-Nucleation-BirthSites.csv code/data/ModelB-Nucleation-SeedingIntervention.csv`

- [ ] **Step 4: Run unit tests**

Run: `julia code/model-b/Test-BoundaryVsBulk.jl`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add code/model-b/Compute-ModelB-BoundaryVsBulk.jl
git commit -m "Add arm 2 of boundary-vs-bulk: paired patch seeding at a distance gradient"
```

---

### Task 7: Figures

**Files:**
- Modify: `code/model-b/Compute-ModelB-BoundaryVsBulk.jl` (append)

**Interfaces:**
- Consumes: `birth_df, seed_df, trajs_map, _ton, CONFIGS, ARMS, SEEDS, GRIDN, STEPS, _NULL_PMF, S_PATCH` (Tasks 5–6); `_BUY_COLOR, _SELL_COLOR, _PATH_TO_FIGS` (Include.jl).
- Produces: `code/figs/ModelB-Nucleation-BirthSites.pdf`, `code/figs/ModelB-Nucleation-Seeding.pdf`.

- [ ] **Step 1: Append the figure code**

Append to `Compute-ModelB-BoundaryVsBulk.jl`:

```julia
# ---------------------------------------------------------------------------
# Figure 1 — birth sites: (a) scatter on the grid outline; (b, c) birth
# distance vs the analytic null PMF per config; (d) attachment timing
# ---------------------------------------------------------------------------
const _CFG_COLOR = Dict("freeze" => _BUY_COLOR, "collapse" => _SELL_COLOR)

inc = birth_df[birth_df.included, :]

p_map = plot(title = "birth sites (n=$(nrow(inc)))", titlefont = 10,
             xlims = (1, GRIDN), ylims = (1, GRIDN), yflip = true,
             aspect_ratio = :equal, guidefont = 8, tickfont = 7,
             legend = :topright, legendfontsize = 6,
             xlabel = "col", ylabel = "row")
plot!(p_map, [1, GRIDN, GRIDN, 1, 1], [1, 1, GRIDN, GRIDN, 1],
      color = :black, lw = 0.8, label = "")
for cfg in CONFIGS
    sub = inc[inc.config .== cfg.name, :]
    isempty(sub) && continue
    scatter!(p_map, sub.birth_col, sub.birth_row, color = _CFG_COLOR[cfg.name],
             markersize = 5, markerstrokewidth = 0.5, label = cfg.name)
end

dist_panels = Plots.Plot[]
for cfg in CONFIGS
    sub = inc[inc.config .== cfg.name, :]
    p = plot(title = "$(cfg.name): birth distance", titlefont = 10,
             xlabel = "Chebyshev distance to frame", ylabel = "probability",
             guidefont = 8, tickfont = 7, legend = :topright, legendfontsize = 6)
    plot!(p, 1:length(_NULL_PMF), _NULL_PMF, color = "#888888", lw = 1.8,
          label = "uniform null")
    if !isempty(sub)
        w = fill(1 / nrow(sub), nrow(sub))
        histogram!(p, sub.birth_dist, weights = w, bins = 0.5:1:(GRIDN ÷ 2),
                   color = _CFG_COLOR[cfg.name], fillalpha = 0.5, lw = 0.5,
                   label = "births (n=$(nrow(sub)))")
    end
    push!(dist_panels, p)
end

p_att = plot(title = "ring attachment", titlefont = 10,
             xlabel = "attach step − birth step", ylabel = "onset − birth (steps)",
             guidefont = 8, tickfont = 7, legend = :topright, legendfontsize = 6)
for cfg in CONFIGS
    sub = inc[(inc.config .== cfg.name) .& inc.attached, :]
    isempty(sub) && continue
    scatter!(p_att, sub.attach_step .- sub.birth_step, sub.t_on .- sub.birth_step,
             color = _CFG_COLOR[cfg.name], markersize = 5, markerstrokewidth = 0.5,
             label = "$(cfg.name) ($(count(sub.attached_before_onset))/$(nrow(sub)) pre-onset)")
end

fig1 = plot(p_map, dist_panels..., p_att; layout = (2, 2), size = (1150, 950),
            left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
            plot_title = "Where the dominant sell nucleus is born (interior-only clusters)",
            plot_titlefontsize = 11)
savefig(fig1, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-BirthSites.pdf"))
@info "Saved: ModelB-Nucleation-BirthSites.pdf"

# ---------------------------------------------------------------------------
# Figure 2 — seeding intervention: (a) paired t_on by arm; (b) dominance
# rates; (c) exemplar largest-cluster growth (first seed with full pairs)
# ---------------------------------------------------------------------------
const _ARM_COLOR = Dict("control" => "#888888", "edge" => _SELL_COLOR,
                        "mid" => "#E69F00", "center" => _BUY_COLOR)

fig2_panels = Plots.Plot[]
for cfg in CONFIGS
    p = plot(title = "$(cfg.name): onset by arm", titlefont = 10,
             xticks = (1:length(ARMS), ARMS), ylabel = "onset step",
             guidefont = 8, tickfont = 7, legend = false)
    for seed in SEEDS
        ts = [_ton(seed_df, cfg.name, seed, arm) for arm in ARMS]
        any(ismissing, ts) && continue
        plot!(p, 1:length(ARMS), collect(skipmissing(ts)),
              color = "#BBBBBB", lw = 0.6)
    end
    for (j, arm) in enumerate(ARMS)
        sub = seed_df[(seed_df.config .== cfg.name) .& (seed_df.arm .== arm) .&
                      seed_df.included, :]
        isempty(sub) && continue
        scatter!(p, fill(j, nrow(sub)), sub.t_on, color = _ARM_COLOR[arm],
                 markersize = 4, markerstrokewidth = 0)
    end
    push!(fig2_panels, p)
end
for cfg in CONFIGS
    p = plot(title = "$(cfg.name): patch dominance", titlefont = 10,
             xticks = (1:3, ARMS[2:end]), ylabel = "dominant-from-patch rate",
             ylims = (0, 1.05), guidefont = 8, tickfont = 7, legend = false)
    for (j, arm) in enumerate(ARMS[2:end])
        dom = seed_df[(seed_df.config .== cfg.name) .& (seed_df.arm .== arm), :dominant_from_patch]
        bar!(p, [j], [count(dom) / max(length(dom), 1)],
             color = _ARM_COLOR[arm], fillalpha = 0.7, bar_width = 0.55)
    end
    push!(fig2_panels, p)
end
for cfg in CONFIGS
    # Exemplar: the first seed whose four arms all reached onset (else first seed)
    ex = findfirst(seed -> all(arm -> !ismissing(_ton(seed_df, cfg.name, seed, arm)), ARMS), SEEDS)
    ex_seed = isnothing(ex) ? SEEDS[1] : SEEDS[ex]
    p = plot(title = "$(cfg.name): exemplar growth (seed $(ex_seed))", titlefont = 10,
             xlabel = "step", ylabel = "largest cluster / grid",
             guidefont = 8, tickfont = 7, legend = :topleft, legendfontsize = 6)
    for arm in ARMS
        plot!(p, 1:STEPS, trajs_map[(cfg.name, ex_seed)][arm],
              color = _ARM_COLOR[arm], lw = 1.6, label = arm)
    end
    push!(fig2_panels, p)
end

fig2 = plot(fig2_panels...; layout = (3, 2), size = (1150, 1250),
            left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
            plot_title = "Patch seeding at a distance gradient (paired; s=$(S_PATCH))",
            plot_titlefontsize = 11)
savefig(fig2, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-Seeding.pdf"))
@info "Saved: ModelB-Nucleation-Seeding.pdf"

@info "Compute-ModelB-BoundaryVsBulk.jl complete."
```

- [ ] **Step 2: Smoke-run and verify both PDFs appear**

Run: `BVB_SMOKE=1 julia code/model-b/Compute-ModelB-BoundaryVsBulk.jl && ls -la code/figs/ModelB-Nucleation-BirthSites.pdf code/figs/ModelB-Nucleation-Seeding.pdf`
Expected: script completes; both PDFs exist with nonzero size (panels may be sparse at smoke scale — fine).

- [ ] **Step 3: Clean up smoke artifacts**

Run: `rm -f code/data/ModelB-Nucleation-BirthSites.csv code/data/ModelB-Nucleation-SeedingIntervention.csv code/figs/ModelB-Nucleation-BirthSites.pdf code/figs/ModelB-Nucleation-Seeding.pdf`

- [ ] **Step 4: Commit**

```bash
git add code/model-b/Compute-ModelB-BoundaryVsBulk.jl
git commit -m "Add birth-site and seeding-intervention figures"
```

---

### Task 8: Production run, sanity checks, data commit

**Files:**
- Create (by running): `code/data/ModelB-Nucleation-BirthSites.csv`, `code/data/ModelB-Nucleation-SeedingIntervention.csv`, `code/figs/ModelB-Nucleation-BirthSites.pdf`, `code/figs/ModelB-Nucleation-Seeding.pdf`

- [ ] **Step 1: Full production run**

Run: `julia -t 8 code/model-b/Compute-ModelB-BoundaryVsBulk.jl 2>&1 | tee /tmp/bvb-run.log`
Expected: arm 1 (40 sims) then arm 2 (40 items × 4 sims), ~20–60 min total. No assertion failures. Note the logged `Arm 1 summary` (frac_d_le_2, binom_p), `Arm 2 patch calibration` (s_patch), `Arm 2 summary` lines, and any forward/backward disagreement warning count.

- [ ] **Step 2: Sanity-check the outputs**

Run:
```bash
wc -l code/data/ModelB-Nucleation-BirthSites.csv code/data/ModelB-Nucleation-SeedingIntervention.csv
cut -d, -f5 code/data/ModelB-Nucleation-SeedingIntervention.csv | sort | uniq -c
```
Expected: 41 lines (header + 40) and 161 lines (header + 160); arm counts 40 each for center/control/edge/mid.

Cross-checks against prior results (investigate before committing if violated):
- Arm-1 onset times for included runs should be broadly consistent with the budget toggle's onsets (tens to ~1400) — freeze/collapse both nucleate.
- If nearly all arm-1 runs are `included = false`, the interior-only/full-grid labeling difference or the onset scan is buggy — the seed sweep showed most runs passing 5% well before t = 1500.
- `dominant_from_patch` must be identically `false` for every control row, and `patch_lineage_max = 0` for control.

- [ ] **Step 3: Commit data and figures**

```bash
git add code/data/ModelB-Nucleation-BirthSites.csv code/data/ModelB-Nucleation-SeedingIntervention.csv code/figs/ModelB-Nucleation-BirthSites.pdf code/figs/ModelB-Nucleation-Seeding.pdf
git commit -m "Run boundary-vs-bulk seeding analysis: birth sites + paired patch intervention"
```

- [ ] **Step 4: Report the headline numbers**

From the run log, report to the user: per-config and pooled `frac_d_le_2` vs the 0.125 null with binomial p; the calibrated patch size; per-arm median onset advance and sign-flip p; dominance rates and the edge-vs-center McNemar p — mapped onto the spec's interpretation table (bulk-creates-boundary-gates vs boundary-seeds vs discordant).

---

## Self-Review Notes

- **Spec coverage:** shared config/onset/labeling → Task 5 constants and `_onset`; backward lineage + gap-1 + tie-breaks → Task 3; null PMF + binomial headline → Tasks 1, 5; attachment → Tasks 4, 5; patch calibration + placements + shared background + pairing assertions → Tasks 5–6; forward trace + dominance + paired stats (sign-flip, McNemar) → Tasks 3, 6; figures → Task 7; smoke mode + threading contract → Tasks 5–7; production run + reporting → Task 8. Censored-run handling (`included = false`, dropped from Δt_on pairs, kept in dominance denominators) → Tasks 5–6.
- **Known judgment call:** the lib/test file split refines the spec's "one self-contained script" so the tracers are unit-testable without running sweeps; the compute entry point remains a single script (documented in the header of the plan and the script).
- **Type consistency check:** `label_sequence` returns `(Vector{Matrix{Int16}}, Vector{Vector{Int}})` and every tracer call site passes them positionally; `edge_coordinates` is `Vector{Tuple{Int64,Int64}}` everywhere (matches `build_edge_coordinates` and `res.edge_coordinates`); arms are `String`s in both the sweep and the figures.

---

## Post-merge amendment (2026-07-20)

The final whole-branch review flagged that Figure 2's exemplar panel was not
reproducible from committed data (`trajs_map` existed only in-process). Fix,
applied on branch `bvb-loose-ends` after the production data was merged:

- The arm-2 sweep now also writes
  `code/data/ModelB-Nucleation-SeedingTrajectories.csv` (wide; one row per
  config × seed × arm; `t1..tSTEPS` hold integer largest-cluster counts, so
  fraction = count / gridn² exactly).
- Task 7's figure code moved from the compute script into the standalone
  `code/model-b/Figs-ModelB-BoundaryVsBulk.jl`, which reads only the three
  CSVs (no simulation) and is included by the compute script at the end of a
  sweep — pipeline behavior unchanged, figures regenerable in isolation.
- `_signflip_p` adopted the +1 Monte-Carlo correction ((hits+1)/(n_draws+1)).

The production rerun reproduced both original CSVs byte-identically
(determinism audit passed); logged statistics unchanged to 3 significant
figures (freeze/mid sign-flip p: 0.02375 → 0.0238).
