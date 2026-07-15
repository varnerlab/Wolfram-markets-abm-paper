# Model B Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Model B (closed-loop endogenous price) simulation with the explicit update order, controlled initialization, 25% boundary edge agents, full-trajectory recording, nine focused tests, and a 32×32 Stage-1 diagnostic run.

**Architecture:** New `MyModelBConfiguration` (single source of truth, one seed) and `MyModelBSimulationResult` (full per-step trajectories) are added to the existing src file organization (`Types.jl`/`Factory.jl`/`Compute.jl`/`Simulate.jl`). The old inert `simulate(::MyModelBSimulation)` method is replaced by `simulate(::MyModelBConfiguration)` implementing the order: interior imbalance → new price → EMA on new price → edge decision on new price → CA step. Model A code paths are bit-for-bit untouched.

**Tech Stack:** Julia 1.12 scripts (not a package). Project env at `code/` (each script's `Include.jl` activates it). Test/Random/Statistics are stdlibs available via the default load path — no Project.toml changes needed.

**Spec:** `docs/superpowers/specs/2026-07-15-model-b-rebuild-design.md`

## Global Constraints

- **Model A untouched:** only additive changes to shared src files; `_build_ca_components`'s new `rng` kwarg must default to `Random.default_rng()` so Model A behavior is bit-for-bit identical.
- **States:** 0 = Buy, 1 = Hold, 2 = Sell. Rules: 19280 (majority, default major), 19286 (contrarian, default minor). Von Neumann neighborhood (radius 4), 3 colors.
- **Imbalance is strictly interior:** `φ = (N_buy − N_sell) / ((nrows−2)·(ncols−2))` over rows/cols `2:end-1`; the whole boundary (active + passive) is excluded.
- **RNG contract:** all randomness from `Xoshiro(config.seed)`, consumed in fixed order: (1) edge-cell sampling, (2) initial-grid perturbation, (3) minority rule assignment. Same config ⇒ identical output.
- **Series lengths:** state-like series length `steps+1` (index 1 = t=0); transition-like series length `steps`. `log_returns[t] = λ·net_imbalance[t]` exactly.
- **Test command (run from repo root, must pass at the end of every task):** `julia code/model-b/Test-ModelB.jl`
- **Outputs:** `code/data/*.jld2` is gitignored (do not try to commit data); figures under `code/figs/` are committed. Nothing is copied to `paper/figs/`.
- **Julia:** 1.12.6 at `julia`. First script run may take ~1-2 min for package precompilation; later runs ~30-60 s startup (Plots).

## File Structure

- Modify `code/src/Types.jl` — append `MyModelBConfiguration`, `MyModelBSimulationResult` (Model A types untouched; old `MyModelBSimulation`/`MyEndogenousPriceModel` deliberately left in place — old JLD2 data and Fig scripts never call `simulate`)
- Modify `code/src/Factory.jl` — append `build(MyModelBConfiguration, …)`, `build_edge_coordinates`, `build_initial_grid`
- Modify `code/src/Compute.jl` — append `compute_interior_imbalance`, `compute_interior_fractions`, `compute_crash_statistics`
- Modify `code/src/Simulate.jl` — add `rng` kwarg to `_build_ca_components`; replace the old Model B section with `simulate(::MyModelBConfiguration)`
- Create `code/model-b/Test-ModelB.jl` — all nine spec §4 test properties plus builder/helper unit tests
- Rewrite `code/model-b/Compute-ModelB.jl` — Stage 1 diagnostic driver (32×32, 200 steps)

---

### Task 1: Interior/trajectory helpers in Compute.jl

**Files:**
- Modify: `code/src/Compute.jl` (append at end of file)
- Create: `code/model-b/Test-ModelB.jl`

**Interfaces:**
- Consumes: nothing new (pure functions on `Array{Int64,2}` / `Vector{Float64}`)
- Produces:
  - `compute_interior_imbalance(grid::Array{Int64,2})::Float64`
  - `compute_interior_fractions(grid::Array{Int64,2})::Tuple{Float64,Float64,Float64}` — (buy, hold, sell)
  - `compute_crash_statistics(sell_fraction::Vector{Float64}; threshold::Float64 = 0.5)` → NamedTuple `(frequency, n_crashes, durations)`
  - Test helper `_uniform_interior_grid(nrows, ncols, state)::Array{Int64,2}`

- [ ] **Step 1: Create the test file with failing helper tests**

Create `code/model-b/Test-ModelB.jl`:

```julia
# Test-ModelB.jl — focused Model B tests (model-B-plan.md §6, spec §4)
# Run from repo root: julia code/model-b/Test-ModelB.jl
# (paths are @__DIR__-relative, so any cwd works)

include(joinpath(@__DIR__, "Include.jl"))
using Test

# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

"""All-`state` interior on an all-Hold boundary — for hand-built scenarios."""
function _uniform_interior_grid(nrows::Int64, ncols::Int64, state::Int64)::Array{Int64,2}
    grid = fill(1, nrows, ncols)
    grid[2:nrows-1, 2:ncols-1] .= state
    return grid
end

# ---------------------------------------------------------------------------
# Trajectory helpers (Compute.jl)
# ---------------------------------------------------------------------------

@testset "interior imbalance excludes the whole boundary" begin
    # boundary all Sell, interior all Hold → φ = 0 exactly
    grid = fill(1, 8, 8)
    grid[1, :] .= 2; grid[8, :] .= 2; grid[:, 1] .= 2; grid[:, 8] .= 2
    @test compute_interior_imbalance(grid) == 0.0

    # known interior counts: 3 Buy, 1 Sell in the 6×6 interior
    grid2 = fill(1, 8, 8)
    grid2[2, 2] = 0; grid2[3, 3] = 0; grid2[4, 4] = 0; grid2[5, 5] = 2
    @test compute_interior_imbalance(grid2) ≈ 2 / 36

    # all-Buy interior → φ = +1; all-Sell interior → φ = −1
    @test compute_interior_imbalance(_uniform_interior_grid(8, 8, 0)) == 1.0
    @test compute_interior_imbalance(_uniform_interior_grid(8, 8, 2)) == -1.0
end

@testset "interior fractions" begin
    grid = fill(1, 8, 8)
    grid[2, 2] = 0; grid[2, 3] = 0; grid[3, 2] = 2
    buy, hold, sell = compute_interior_fractions(grid)
    @test buy  ≈ 2 / 36
    @test sell ≈ 1 / 36
    @test hold ≈ 33 / 36
    @test buy + hold + sell ≈ 1.0
end

@testset "crash statistics from the full trajectory" begin
    s = [0.1, 0.6, 0.7, 0.2, 0.8, 0.1]
    stats = compute_crash_statistics(s; threshold = 0.5)
    @test stats.frequency ≈ 3 / 6
    @test stats.n_crashes == 2
    @test stats.durations == [2, 1]

    quiet = compute_crash_statistics([0.1, 0.2, 0.3])
    @test quiet.frequency == 0.0
    @test quiet.n_crashes == 0
    @test isempty(quiet.durations)

    # an episode still open at the end of the series is closed and counted
    tail = compute_crash_statistics([0.6, 0.7])
    @test tail.n_crashes == 1
    @test tail.durations == [2]
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: FAIL/ERROR with `UndefVarError: compute_interior_imbalance not defined` (the first testset errors; later ones error similarly).

- [ ] **Step 3: Implement the three helpers**

Append to `code/src/Compute.jl` (after `compute_crash_sizes`, end of file):

```julia
# ---------------------------------------------------------------------------
# Model B trajectory helpers (strictly interior; boundary excluded)
# ---------------------------------------------------------------------------

"""
    compute_interior_imbalance(grid) → Float64

Net order imbalance over strictly interior cells (rows 2:end-1, cols 2:end-1):

    φ = (N_buy − N_sell) / N_interior

The entire boundary — active edge cells and passive Hold cells — is excluded,
matching φ = D/N_interior in the paper's supply–demand form (spec §1).
"""
function compute_interior_imbalance(grid::Array{Int64,2})::Float64
    nrows, ncols = size(grid)
    N_buy = 0; N_sell = 0
    for r in 2:nrows-1, c in 2:ncols-1
        s = grid[r, c]
        N_buy  += (s == 0)
        N_sell += (s == 2)
    end
    N_int = (nrows - 2) * (ncols - 2)
    return N_int > 0 ? (N_buy - N_sell) / N_int : 0.0
end

"""
    compute_interior_fractions(grid) → (buy, hold, sell)

Population fractions over strictly interior cells (same region as
compute_interior_imbalance).
"""
function compute_interior_fractions(grid::Array{Int64,2})::Tuple{Float64,Float64,Float64}
    nrows, ncols = size(grid)
    n = zeros(Int64, 3)
    for r in 2:nrows-1, c in 2:ncols-1
        n[grid[r, c] + 1] += 1
    end
    N_int = (nrows - 2) * (ncols - 2)
    return N_int > 0 ? (n[1] / N_int, n[2] / N_int, n[3] / N_int) : (0.0, 0.0, 0.0)
end

"""
    compute_crash_statistics(sell_fraction; threshold = 0.5)
        → (frequency, n_crashes, durations)

Crash statistics from the FULL per-step sell-fraction trajectory (never from
sparse snapshots): `frequency` is the fraction of entries ≥ threshold; a crash
episode is a maximal contiguous run of entries ≥ threshold; `durations` lists
episode lengths in steps (an episode still open at the end is counted).
"""
function compute_crash_statistics(
    sell_fraction::Vector{Float64};
    threshold::Float64 = 0.5,
)::NamedTuple{(:frequency, :n_crashes, :durations), Tuple{Float64, Int64, Vector{Int64}}}
    durations = Int64[]
    duration  = 0
    for s in sell_fraction
        if s ≥ threshold
            duration += 1
        elseif duration > 0
            push!(durations, duration)
            duration = 0
        end
    end
    duration > 0 && push!(durations, duration)
    frequency = isempty(sell_fraction) ? 0.0 :
        count(≥(threshold), sell_fraction) / length(sell_fraction)
    return (frequency = frequency, n_crashes = length(durations), durations = durations)
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: PASS — three testsets, no failures.

- [ ] **Step 5: Commit**

```bash
git add code/src/Compute.jl code/model-b/Test-ModelB.jl
git commit -m "Add interior imbalance/fractions and full-trajectory crash statistics for Model B"
```

---

### Task 2: Configuration and result types

**Files:**
- Modify: `code/src/Types.jl` (append after `MySimulationResult`, end of file)
- Modify: `code/src/Factory.jl` (append at end of file)
- Modify: `code/model-b/Test-ModelB.jl` (append testset + helper)

**Interfaces:**
- Consumes: `AbstractSimulationModel` (Types.jl), `build(::Type, ::NamedTuple)` pattern (Factory.jl)
- Produces:
  - `MyModelBConfiguration <: AbstractSimulationModel` — mutable struct with fields `number_of_rows::Int64, number_of_cols::Int64, number_of_colors::Int64, radius::Int64, steps::Int64, seed::Int64, initial_condition::Symbol, initial_buy_fraction::Float64, initial_sell_fraction::Float64, edge_fraction::Float64, α::Float64, k::Float64, λ::Float64, P0::Float64, minority_fraction::Float64, rule_major_index::Int64, rule_minor_index::Int64`
  - `MyModelBSimulationResult` — immutable struct, field order: `frames, prices, log_returns, net_imbalance, buy_fraction, hold_fraction, sell_fraction, edge_states, ema_price, ema_volatility, band_lower, band_upper, edge_coordinates, config`
  - `build(MyModelBConfiguration, data::NamedTuple)::MyModelBConfiguration` — defaults + validation, throws `ArgumentError`
  - Test helper `_test_config(; kwargs...)::MyModelBConfiguration` (16×16, 50 steps, seed 7)

- [ ] **Step 1: Write failing builder tests**

Append to `code/model-b/Test-ModelB.jl`:

```julia
# ---------------------------------------------------------------------------
# Configuration (Types.jl / Factory.jl)
# ---------------------------------------------------------------------------

"""Small, fast config for integration tests; override any field via kwargs."""
function _test_config(; kwargs...)
    defaults = (
        number_of_rows = 16, number_of_cols = 16,
        steps = 50, seed = 7,
    )
    return build(MyModelBConfiguration, merge(defaults, (; kwargs...)))
end

@testset "configuration builder: defaults and validation" begin
    config = build(MyModelBConfiguration, (number_of_rows = 32, number_of_cols = 32))
    @test config.number_of_colors == 3
    @test config.radius == 4
    @test config.steps == 200
    @test config.seed == 42
    @test config.initial_condition == :balanced_perturbation
    @test config.initial_buy_fraction  == 0.05
    @test config.initial_sell_fraction == 0.05
    @test config.edge_fraction == 0.25
    @test config.α ≈ 1 / 60
    @test config.k == 1.0
    @test config.λ == 0.01
    @test config.P0 == 100.0
    @test config.minority_fraction == 0.20
    @test config.rule_major_index == 19280
    @test config.rule_minor_index == 19286

    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, steps = 0))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 2, number_of_cols = 32))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, edge_fraction = 1.5))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32,
         initial_buy_fraction = 0.6, initial_sell_fraction = 0.6))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, initial_condition = :bogus))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, P0 = -1.0))
end
```

- [ ] **Step 2: Run tests to verify the new testset fails**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: Task 1 testsets PASS; new testset ERRORS with `UndefVarError: MyModelBConfiguration not defined`.

- [ ] **Step 3: Add the two types**

Append to `code/src/Types.jl` (after `MySimulationResult`, end of file):

```julia
# ---------------------------------------------------------------------------
# Model B configuration and result (closed-loop rebuild; spec 2026-07-15)
# ---------------------------------------------------------------------------

"""
    MyModelBConfiguration <: AbstractSimulationModel

Single source of truth for a Model B run: grid geometry, CA rules,
initialization mode, boundary population, edge-agent parameters, price
model, and the RNG seed. Build via build(MyModelBConfiguration, data),
which applies defaults and validates ranges.

Subtypes AbstractSimulationModel with the standard field names so the shared
CA machinery (_build_ca_components) works on it directly.
"""
mutable struct MyModelBConfiguration <: AbstractSimulationModel
    number_of_rows::Int64
    number_of_cols::Int64
    number_of_colors::Int64          # = 3 (buy / hold / sell)
    radius::Int64                    # = 4 (Von Neumann neighbors)
    steps::Int64
    seed::Int64                      # seeds ALL randomness for the run
    initial_condition::Symbol        # :all_hold | :balanced_perturbation | :custom
    initial_buy_fraction::Float64    # Buy seeds, fraction of interior cells
    initial_sell_fraction::Float64   # Sell seeds, fraction of interior cells
    edge_fraction::Float64           # fraction of boundary cells that are active
    α::Float64                       # EMA learning rate
    k::Float64                       # band half-width in units of σ
    λ::Float64                       # price impact (per-capita inverse depth)
    P0::Float64                      # initial price
    minority_fraction::Float64       # fraction of agents using rule_minor
    rule_major_index::Int64
    rule_minor_index::Int64
    MyModelBConfiguration() = new()
end

"""
    MyModelBSimulationResult

Immutable container for a Model B run: sparse grid snapshots plus the COMPLETE
aggregate trajectory, so all statistics are computed from every step.

State-like series (length steps+1, index 1 = t=0): prices, ema_price,
ema_volatility, band_lower, band_upper, buy_fraction, hold_fraction,
sell_fraction. Transition-like series (length steps, index t = step t):
log_returns (= λ·φ_{t-1}), net_imbalance (φ_{t-1}, the value that generated
P_t), edge_states (e_t).

frames always contains t=0 and t=steps. edge_coordinates lists the active
edge cells (sorted) so every run is reproducible from the result alone.
"""
struct MyModelBSimulationResult
    frames::Dict{Int64, Array{Int64,2}}
    prices::Vector{Float64}
    log_returns::Vector{Float64}
    net_imbalance::Vector{Float64}
    buy_fraction::Vector{Float64}
    hold_fraction::Vector{Float64}
    sell_fraction::Vector{Float64}
    edge_states::Vector{Int64}
    ema_price::Vector{Float64}
    ema_volatility::Vector{Float64}
    band_lower::Vector{Float64}
    band_upper::Vector{Float64}
    edge_coordinates::Vector{Tuple{Int64,Int64}}
    config::MyModelBConfiguration
end
```

- [ ] **Step 4: Add the builder with validation**

Append to `code/src/Factory.jl` (end of file):

```julia
# ---------------------------------------------------------------------------
# Model B configuration (closed-loop rebuild; spec 2026-07-15)
# ---------------------------------------------------------------------------

"""
    build(MyModelBConfiguration, data::NamedTuple) → MyModelBConfiguration

Required keys: number_of_rows, number_of_cols.
Optional keys (defaults): number_of_colors (3), radius (4), steps (200),
seed (42), initial_condition (:balanced_perturbation),
initial_buy_fraction (0.05), initial_sell_fraction (0.05),
edge_fraction (0.25), α (1/60), k (1.0), λ (0.01), P0 (100.0),
minority_fraction (0.20), rule_major_index (19280), rule_minor_index (19286).

Validates: steps > 0; grid at least 3×3 (interior must be non-empty); all
fractions in [0, 1]; initial_buy_fraction + initial_sell_fraction ≤ 1;
known initial_condition; P0 > 0. Throws ArgumentError on violation.
"""
function build(modeltype::Type{MyModelBConfiguration}, data::NamedTuple)::MyModelBConfiguration
    model = modeltype()
    model.number_of_rows        = data.number_of_rows
    model.number_of_cols        = data.number_of_cols
    model.number_of_colors      = get(data, :number_of_colors, 3)
    model.radius                = get(data, :radius, 4)
    model.steps                 = get(data, :steps, 200)
    model.seed                  = get(data, :seed, 42)
    model.initial_condition     = get(data, :initial_condition, :balanced_perturbation)
    model.initial_buy_fraction  = get(data, :initial_buy_fraction, 0.05)
    model.initial_sell_fraction = get(data, :initial_sell_fraction, 0.05)
    model.edge_fraction         = get(data, :edge_fraction, 0.25)
    model.α                     = get(data, :α, 1 / 60)
    model.k                     = get(data, :k, 1.0)
    model.λ                     = get(data, :λ, 0.01)
    model.P0                    = get(data, :P0, 100.0)
    model.minority_fraction     = get(data, :minority_fraction, 0.20)
    model.rule_major_index      = get(data, :rule_major_index, 19280)
    model.rule_minor_index      = get(data, :rule_minor_index, 19286)

    model.steps > 0 ||
        throw(ArgumentError("steps must be positive (got $(model.steps))"))
    (model.number_of_rows ≥ 3 && model.number_of_cols ≥ 3) ||
        throw(ArgumentError("grid must be at least 3×3 to have interior cells"))
    for (name, value) in (
        (:initial_buy_fraction,  model.initial_buy_fraction),
        (:initial_sell_fraction, model.initial_sell_fraction),
        (:edge_fraction,         model.edge_fraction),
        (:minority_fraction,     model.minority_fraction),
    )
        (0.0 ≤ value ≤ 1.0) ||
            throw(ArgumentError("$(name) must be in [0, 1] (got $(value))"))
    end
    (model.initial_buy_fraction + model.initial_sell_fraction ≤ 1.0) ||
        throw(ArgumentError("initial_buy_fraction + initial_sell_fraction must be ≤ 1"))
    model.initial_condition in (:all_hold, :balanced_perturbation, :custom) ||
        throw(ArgumentError("unknown initial_condition $(model.initial_condition); " *
                            "use :all_hold, :balanced_perturbation, or :custom"))
    model.P0 > 0.0 ||
        throw(ArgumentError("P0 must be positive (got $(model.P0))"))
    return model
end
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: PASS — four testsets, no failures.

- [ ] **Step 6: Commit**

```bash
git add code/src/Types.jl code/src/Factory.jl code/model-b/Test-ModelB.jl
git commit -m "Add MyModelBConfiguration and MyModelBSimulationResult with validated builder"
```

---

### Task 3: Initialization and boundary-construction helpers

**Files:**
- Modify: `code/src/Factory.jl` (append after the Task 2 builder)
- Modify: `code/model-b/Test-ModelB.jl` (append two testsets)

**Interfaces:**
- Consumes: `MyModelBConfiguration` (Task 2), `randperm` from `Random` (already loaded by `Include.jl`), `compute_interior_imbalance` (Task 1)
- Produces:
  - `build_edge_coordinates(nrows::Int64, ncols::Int64, edge_fraction::Float64, rng::AbstractRNG)::Vector{Tuple{Int64,Int64}}` — sorted
  - `build_initial_grid(config::MyModelBConfiguration, rng::AbstractRNG; custom_grid::Union{Nothing,Array{Int64,2}} = nothing)::Array{Int64,2}`

- [ ] **Step 1: Write failing helper tests**

Append to `code/model-b/Test-ModelB.jl`:

```julia
# ---------------------------------------------------------------------------
# Initialization and boundary helpers (Factory.jl)
# ---------------------------------------------------------------------------

@testset "edge coordinates: seeded boundary sample" begin
    nrows, ncols = 16, 16
    n_boundary = 2 * ncols + 2 * (nrows - 2)              # 60 for 16×16
    coords = build_edge_coordinates(nrows, ncols, 0.25, Xoshiro(11))
    @test length(coords) == round(Int, 0.25 * n_boundary) # 15
    @test length(unique(coords)) == length(coords)         # no repeats
    @test all(r == 1 || r == nrows || c == 1 || c == ncols for (r, c) in coords)
    @test issorted(coords)

    # same seed → same sample; different seed → different sample
    @test coords == build_edge_coordinates(nrows, ncols, 0.25, Xoshiro(11))
    @test coords != build_edge_coordinates(nrows, ncols, 0.25, Xoshiro(12))

    # edge_fraction = 0 → no active edges; = 1 → every boundary cell
    @test isempty(build_edge_coordinates(nrows, ncols, 0.0, Xoshiro(11)))
    @test length(build_edge_coordinates(nrows, ncols, 1.0, Xoshiro(11))) == n_boundary
end

@testset "initial grid modes" begin
    config = _test_config()
    nrows, ncols = config.number_of_rows, config.number_of_cols
    N_int = (nrows - 2) * (ncols - 2)                     # 196 for 16×16

    # :all_hold — every cell Hold
    all_hold = build_initial_grid(_test_config(initial_condition = :all_hold), Xoshiro(1))
    @test all(all_hold .== 1)

    # :balanced_perturbation — exact equal counts, interior only, boundary Hold
    grid = build_initial_grid(config, Xoshiro(1))
    @test count(==(0), grid) == round(Int, 0.05 * N_int)
    @test count(==(2), grid) == round(Int, 0.05 * N_int)
    @test count(==(0), grid) == count(==(2), grid)
    @test compute_interior_imbalance(grid) == 0.0
    @test all(grid[1, :] .== 1) && all(grid[end, :] .== 1)
    @test all(grid[:, 1] .== 1) && all(grid[:, end] .== 1)
    @test grid == build_initial_grid(config, Xoshiro(1))   # reproducible

    # :custom — validated pass-through
    cfg_custom = _test_config(initial_condition = :custom)
    @test_throws ArgumentError build_initial_grid(cfg_custom, Xoshiro(1))
    @test_throws ArgumentError build_initial_grid(cfg_custom, Xoshiro(1);
        custom_grid = fill(1, 4, 4))
    bad = fill(1, 16, 16); bad[3, 3] = 7
    @test_throws ArgumentError build_initial_grid(cfg_custom, Xoshiro(1); custom_grid = bad)
    ok = _uniform_interior_grid(16, 16, 0)
    @test build_initial_grid(cfg_custom, Xoshiro(1); custom_grid = ok) == ok
end
```

- [ ] **Step 2: Run tests to verify the new testsets fail**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: earlier testsets PASS; new testsets ERROR with `UndefVarError: build_edge_coordinates not defined`.

- [ ] **Step 3: Implement the two helpers**

Append to `code/src/Factory.jl` (after the Task 2 `build` method):

```julia
"""
    build_edge_coordinates(nrows, ncols, edge_fraction, rng)
        → Vector{Tuple{Int64,Int64}}

Enumerate the boundary cells of an nrows×ncols grid in deterministic order and
sample round(edge_fraction · n_boundary) of them without replacement using
rng. Returns the ACTIVE edge coordinates, sorted for reproducible storage.
Non-sampled boundary cells are passive and remain Hold (the CA solvers never
write boundary cells).
"""
function build_edge_coordinates(
    nrows::Int64, ncols::Int64, edge_fraction::Float64, rng::AbstractRNG,
)::Vector{Tuple{Int64,Int64}}
    boundary = Tuple{Int64,Int64}[]
    for c in 1:ncols
        push!(boundary, (1, c))
        push!(boundary, (nrows, c))
    end
    for r in 2:nrows-1
        push!(boundary, (r, 1))
        push!(boundary, (r, ncols))
    end
    n_edge = round(Int, edge_fraction * length(boundary))
    return sort(boundary[randperm(rng, length(boundary))[1:n_edge]])
end

"""
    build_initial_grid(config, rng; custom_grid = nothing) → Array{Int64,2}

Build the initial grid per config.initial_condition:

- :all_hold              → every cell Hold (state 1); stationary null control
- :balanced_perturbation → all-Hold, then exactly
  round(initial_buy_fraction · N_interior) Buy cells and exactly
  round(initial_sell_fraction · N_interior) Sell cells placed on distinct
  interior positions sampled without replacement (equal fractions ⇒ equal
  counts ⇒ zero initial imbalance); the boundary stays Hold
- :custom                → validated copy of custom_grid (size must match;
  entries must be 0, 1, or 2)
"""
function build_initial_grid(
    config::MyModelBConfiguration, rng::AbstractRNG;
    custom_grid::Union{Nothing, Array{Int64,2}} = nothing,
)::Array{Int64,2}
    nrows = config.number_of_rows
    ncols = config.number_of_cols

    if config.initial_condition == :custom
        isnothing(custom_grid) &&
            throw(ArgumentError(":custom initial_condition requires an initial_grid"))
        size(custom_grid) == (nrows, ncols) ||
            throw(ArgumentError("initial_grid size $(size(custom_grid)) ≠ ($(nrows), $(ncols))"))
        all(s -> s in (0, 1, 2), custom_grid) ||
            throw(ArgumentError("initial_grid entries must be 0 (Buy), 1 (Hold), or 2 (Sell)"))
        return copy(custom_grid)
    end

    grid = fill(1, nrows, ncols)
    config.initial_condition == :all_hold && return grid

    # :balanced_perturbation — interior cells only, exact counts
    interior = vec([(r, c) for r in 2:nrows-1, c in 2:ncols-1])
    N_int    = length(interior)
    n_buy    = round(Int, config.initial_buy_fraction  * N_int)
    n_sell   = round(Int, config.initial_sell_fraction * N_int)
    perm     = randperm(rng, N_int)
    for i in 1:n_buy
        r, c = interior[perm[i]]
        grid[r, c] = 0
    end
    for i in (n_buy + 1):(n_buy + n_sell)
        r, c = interior[perm[i]]
        grid[r, c] = 2
    end
    return grid
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: PASS — six testsets, no failures.

- [ ] **Step 5: Commit**

```bash
git add code/src/Factory.jl code/model-b/Test-ModelB.jl
git commit -m "Add seeded edge-coordinate sampling and initial-grid construction for Model B"
```

---

### Task 4: Seeded minority assignment in _build_ca_components

**Files:**
- Modify: `code/src/Simulate.jl:19-62` (`_build_ca_components`)
- Modify: `code/model-b/Test-ModelB.jl` (append one testset)

**Interfaces:**
- Consumes: `MyModelBConfiguration <: AbstractSimulationModel` (Task 2) — has all fields `_build_ca_components` reads (`number_of_rows`, `number_of_cols`, `number_of_colors`, `radius`, `minority_fraction`, `rule_major_index`, `rule_minor_index`)
- Produces: `_build_ca_components(sim_model::AbstractSimulationModel; rng::AbstractRNG = Random.default_rng())` — same returns as before: `(world, agents, rule_major)`; homogeneous case returns `(nothing, nothing, rule_major)`. **Model A call sites pass no rng and are bit-for-bit unchanged.**

- [ ] **Step 1: Write the failing test**

Append to `code/model-b/Test-ModelB.jl`:

```julia
# ---------------------------------------------------------------------------
# CA machinery: seeded minority assignment (Simulate.jl)
# ---------------------------------------------------------------------------

@testset "CA components: seeded minority assignment" begin
    config = _test_config(minority_fraction = 0.20)
    _, agents1, _ = _build_ca_components(config; rng = Xoshiro(3))
    _, agents2, _ = _build_ca_components(config; rng = Xoshiro(3))
    minors(agents) = Set(i for (i, a) in enumerate(agents)
                         if a.rule.index == config.rule_minor_index)
    @test minors(agents1) == minors(agents2)                       # seeded → identical
    @test length(minors(agents1)) == round(Int, 0.20 * 16 * 16)    # 51 of 256

    # default-rng path (Model A) still works and is homogeneous when f = 0
    world0, agents0, rule0 = _build_ca_components(_test_config(minority_fraction = 0.0))
    @test isnothing(world0) && isnothing(agents0)
    @test rule0.index == config.rule_major_index
end
```

- [ ] **Step 2: Run tests to verify the new testset fails**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: new testset ERRORS with `MethodError` (no method matching `_build_ca_components(::MyModelBConfiguration; rng::Xoshiro)` — the existing method accepts no keyword arguments).

- [ ] **Step 3: Add the rng keyword**

In `code/src/Simulate.jl`, change the `_build_ca_components` signature and the one `rand` call. The docstring line and signature:

```julia
"""
    _build_ca_components(sim_model; rng) → (world, agents, rule_major)

Build the CA machinery needed for a simulation run.

- Homogeneous case (minority_fraction ≈ 0): returns (nothing, nothing, rule_major).
  The fast path `solve(rule_major, grid, steps=1)` is used.

- Heterogeneous case: builds MyTwoDimensionalFixedBoundaryGridWorld, assigns
  rule_major to (1 - f) of agents and rule_minor to the remaining f, placed
  uniformly at random using `rng`.

`rng` defaults to the global RNG, so Model A call sites (which pass no rng)
are bit-for-bit unchanged. Model B passes its seeded Xoshiro so minority
placement is reproducible from config.seed alone.
"""
function _build_ca_components(
    sim_model::AbstractSimulationModel;
    rng::AbstractRNG = Random.default_rng(),
)
```

and inside the minority-placement loop replace `j = rand(1:N)` with:

```julia
        j = rand(rng, 1:N)
```

Everything else in the function stays identical.

- [ ] **Step 4: Run tests to verify they pass**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: PASS — seven testsets, no failures.

- [ ] **Step 5: Verify Model A is untouched (smoke check)**

Run: `grep -n "_build_ca_components" code/src/Simulate.jl`
Expected: definition plus the existing Model A call site `_build_ca_components(model)` (no rng argument) — unchanged.

- [ ] **Step 6: Commit**

```bash
git add code/src/Simulate.jl code/model-b/Test-ModelB.jl
git commit -m "Thread optional rng through _build_ca_components for seeded minority placement"
```

---

### Task 5: The closed-loop simulate method

**Files:**
- Modify: `code/src/Simulate.jl` — replace the entire old Model B section (the `# Model B — closed simulation` header comment, the old docstring, and the old `simulate(model::MyModelBSimulation; ...)` method — currently lines 183-276, everything after the Model A `simulate` method to end of file)
- Modify: `code/model-b/Test-ModelB.jl` (append nine testsets)

**Interfaces:**
- Consumes: `MyModelBConfiguration`, `MyModelBSimulationResult` (Task 2); `build_edge_coordinates`, `build_initial_grid` (Task 3); `compute_interior_imbalance`, `compute_interior_fractions` (Task 1); `_build_ca_components(…; rng)` (Task 4); existing `_ca_step`, `_set_edge_states!`, `compute_band_state`, `Progress`/`next!`
- Produces: `simulate(config::MyModelBConfiguration; initial_grid::Union{Nothing,Array{Int64,2}} = nothing, snapshot_steps::Union{Nothing,Vector{Int64}} = nothing, verbose::Bool = true)::MyModelBSimulationResult`
- Removes: `simulate(model::MyModelBSimulation; ...)` — verified unused elsewhere (Fig4/Fig5 only read JLD2 files; old driver is rewritten in Task 6)

- [ ] **Step 1: Write the failing integration tests (plan §6 properties 1-9)**

Append to `code/model-b/Test-ModelB.jl`:

```julia
# ---------------------------------------------------------------------------
# Closed-loop simulate (Simulate.jl) — model-B-plan.md §6 properties
# ---------------------------------------------------------------------------

@testset "1. positive interior imbalance raises the price" begin
    config = _test_config(initial_condition = :custom, steps = 1)
    grid   = _uniform_interior_grid(16, 16, 0)            # all-Buy interior
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.net_imbalance[1] == 1.0
    @test result.prices[2] > result.prices[1]
    @test result.log_returns[1] ≈ config.λ * 1.0
end

@testset "2. negative interior imbalance lowers the price" begin
    config = _test_config(initial_condition = :custom, steps = 1)
    grid   = _uniform_interior_grid(16, 16, 2)            # all-Sell interior
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.net_imbalance[1] == -1.0
    @test result.prices[2] < result.prices[1]
end

@testset "3. edge cells respond to the newly generated price" begin
    # All-Buy interior with λ = 1: P₁ = 100·e ≈ 271.8 blows through the band
    # (μ₁ ≈ 102.9, σ₁ ≈ 2.8, upper ≈ 105.7) → edge state Sell at t = 1.
    # Under the OLD (wrong) ordering the edge would see P₀ = μ₀ = 100 → Hold.
    config = _test_config(initial_condition = :custom, steps = 1, λ = 1.0)
    grid   = _uniform_interior_grid(16, 16, 0)
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.edge_states[1] == 2
    @test result.prices[2] > result.band_upper[2]
end

@testset "4. edge/boundary cells are excluded from price formation" begin
    # Boundary all Sell, interior all Hold → φ = 0 and the price cannot move.
    config = _test_config(initial_condition = :custom, steps = 1)
    grid = fill(1, 16, 16)
    grid[1, :] .= 2; grid[16, :] .= 2; grid[:, 1] .= 2; grid[:, 16] .= 2
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.net_imbalance[1] == 0.0
    @test result.prices[2] == result.prices[1]
end

@testset "5. passive boundary cells remain Hold" begin
    config = _test_config()                               # balanced perturbation
    result = simulate(config; verbose = false)
    active = Set(result.edge_coordinates)
    final  = result.frames[config.steps]
    nrows, ncols = size(final)
    passive_ok = true
    for r in 1:nrows, c in 1:ncols
        (r == 1 || r == nrows || c == 1 || c == ncols) || continue
        (r, c) in active && continue
        passive_ok &= (final[r, c] == 1)
    end
    @test passive_ok
end

@testset "6. all-Hold null control is stationary" begin
    config = _test_config(initial_condition = :all_hold)
    result = simulate(config; verbose = false)
    @test all(result.prices .== config.P0)
    @test all(result.net_imbalance .== 0.0)
    @test all(result.log_returns .== 0.0)
    @test all(result.edge_states .== 1)
    @test all(result.hold_fraction .== 1.0)
    @test result.frames[config.steps] == fill(1, 16, 16)
end

@testset "7. balanced perturbation activates spatial dynamics" begin
    config = _test_config()
    result = simulate(config; verbose = false)
    @test result.frames[config.steps] != result.frames[0]
    @test any(result.net_imbalance .!= 0.0)
    @test any(result.log_returns .!= 0.0)
end

@testset "8. same seed gives identical output" begin
    r1 = simulate(_test_config(); verbose = false)
    r2 = simulate(_test_config(); verbose = false)
    @test r1.prices == r2.prices
    @test r1.log_returns == r2.log_returns
    @test r1.net_imbalance == r2.net_imbalance
    @test r1.buy_fraction == r2.buy_fraction
    @test r1.hold_fraction == r2.hold_fraction
    @test r1.sell_fraction == r2.sell_fraction
    @test r1.edge_states == r2.edge_states
    @test r1.ema_price == r2.ema_price
    @test r1.ema_volatility == r2.ema_volatility
    @test r1.edge_coordinates == r2.edge_coordinates
    @test sort(collect(keys(r1.frames))) == sort(collect(keys(r2.frames)))
    @test all(r1.frames[t] == r2.frames[t] for t in keys(r1.frames))

    r3 = simulate(_test_config(seed = 8); verbose = false)
    @test r3.edge_coordinates != r1.edge_coordinates || r3.prices != r1.prices
end

@testset "9. trajectory series cover every simulation step" begin
    config = _test_config()
    T      = config.steps
    result = simulate(config; verbose = false)
    @test length(result.prices)         == T + 1
    @test length(result.ema_price)      == T + 1
    @test length(result.ema_volatility) == T + 1
    @test length(result.band_lower)     == T + 1
    @test length(result.band_upper)     == T + 1
    @test length(result.buy_fraction)   == T + 1
    @test length(result.hold_fraction)  == T + 1
    @test length(result.sell_fraction)  == T + 1
    @test length(result.log_returns)    == T
    @test length(result.net_imbalance)  == T
    @test length(result.edge_states)    == T
    @test haskey(result.frames, 0) && haskey(result.frames, T)
    # the price series reconstructs exactly from the recorded log returns
    @test all(isapprox.(diff(log.(result.prices)), result.log_returns; atol = 1e-12))
    # crash statistics run on the full trajectory
    stats = compute_crash_statistics(result.sell_fraction)
    @test 0.0 ≤ stats.frequency ≤ 1.0
    @test stats.n_crashes == length(stats.durations)
end
```

- [ ] **Step 2: Run tests to verify the new testsets fail**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: new testsets ERROR with `MethodError: no method matching simulate(::MyModelBConfiguration; ...)`.

- [ ] **Step 3: Replace the old Model B section in Simulate.jl**

Delete everything in `code/src/Simulate.jl` from the comment line
`# Model B — closed simulation (endogenous price → edge agents → price)`
(including its `# ---` banner lines) through the end of the file — the old
docstring and the old `simulate(model::MyModelBSimulation; ...)` method — and
replace with:

```julia
# ---------------------------------------------------------------------------
# Model B — closed simulation (endogenous price → edge agents → price)
# ---------------------------------------------------------------------------

"""
    simulate(config::MyModelBConfiguration; initial_grid, snapshot_steps, verbose)
        → MyModelBSimulationResult

Run the closed-loop (Model B) simulation.

Step t (t = 1..steps) transforms X_{t-1} → X_t in this exact order
(model-B-plan.md §1):

    φ_{t-1} = interior imbalance of X_{t-1}       (strictly interior cells)
    P_t     = P_{t-1} · exp(λ · φ_{t-1})          (log return = λ·φ_{t-1})
    μ_t     = μ_{t-1} + α·(P_t − μ_{t-1})         (EMA sees the NEW price)
    σ_t     = σ_{t-1} + α·(|P_t − μ_t| − σ_{t-1})
    e_t     = BandState(P_t, μ_t, σ_t, k)         → active edge cells
    X_t     = CA step on interior of X_{t-1}      (edge neighbors see e_t)

All randomness comes from Xoshiro(config.seed), consumed in fixed order:
(1) edge-cell sampling, (2) initial-grid perturbation, (3) minority rule
assignment. Same config ⇒ identical output.

Arguments
- config        : MyModelBConfiguration (single source of truth)
- initial_grid  : required iff config.initial_condition == :custom
- snapshot_steps: steps at which to store full grid frames (default: 8
                  log-spaced); t = 0 and t = steps are always stored
- verbose       : show a ProgressMeter bar (default true)

Returns MyModelBSimulationResult; see its docstring for the series-length
conventions (state-like: steps+1; transition-like: steps).
"""
function simulate(
    config::MyModelBConfiguration;
    initial_grid::Union{Nothing, Array{Int64,2}} = nothing,
    snapshot_steps::Union{Nothing, Vector{Int64}} = nothing,
    verbose::Bool = true,
)::MyModelBSimulationResult

    nrows = config.number_of_rows
    ncols = config.number_of_cols
    steps = config.steps
    α     = config.α
    k     = config.k
    λ     = config.λ
    P0    = config.P0

    # Seeded RNG — draw order below is part of the reproducibility contract
    rng = Xoshiro(config.seed)

    # (1) active edge cells, (2) initial grid, (3) minority rule assignment
    edge_coordinates = build_edge_coordinates(nrows, ncols, config.edge_fraction, rng)
    edge_set         = Set{Tuple{Int64,Int64}}(edge_coordinates)
    grid             = build_initial_grid(config, rng; custom_grid = initial_grid)
    world, agents, rule_major = _build_ca_components(config; rng = rng)

    # Output containers
    prices         = Vector{Float64}(undef, steps + 1)
    log_returns    = Vector{Float64}(undef, steps)
    net_imbalance  = Vector{Float64}(undef, steps)
    buy_fraction   = Vector{Float64}(undef, steps + 1)
    hold_fraction  = Vector{Float64}(undef, steps + 1)
    sell_fraction  = Vector{Float64}(undef, steps + 1)
    edge_states    = Vector{Int64}(undef, steps)
    ema_price      = Vector{Float64}(undef, steps + 1)
    ema_volatility = Vector{Float64}(undef, steps + 1)
    band_lower     = Vector{Float64}(undef, steps + 1)
    band_upper     = Vector{Float64}(undef, steps + 1)

    # t = 0 state
    prices[1]         = P0
    ema_price[1]      = P0
    ema_volatility[1] = 0.0
    band_lower[1]     = P0
    band_upper[1]     = P0
    buy_fraction[1], hold_fraction[1], sell_fraction[1] = compute_interior_fractions(grid)

    # Sparse frames: always t = 0 and t = steps, plus log-spaced (or supplied) steps
    snaps = isnothing(snapshot_steps) ?
        Set{Int64}(unique(round.(Int, exp.(range(log(1), log(steps), length = 8))))) :
        Set{Int64}(snapshot_steps)
    push!(snaps, steps)
    frames    = Dict{Int64, Array{Int64,2}}()
    frames[0] = copy(grid)

    μ = P0
    σ = 0.0
    prog = verbose ? Progress(steps; desc = "Model B: ") : nothing

    for t in 1:steps
        # --- interior grid acts first: net order imbalance ---
        φ                = compute_interior_imbalance(grid)
        net_imbalance[t] = φ

        # --- imbalance generates the next price ---
        P              = prices[t] * exp(λ * φ)
        prices[t + 1]  = P
        log_returns[t] = λ * φ

        # --- online EMA / volatility observe the NEW price ---
        μ = μ + α * (P - μ)
        σ = σ + α * (abs(P - μ) - σ)
        ema_price[t + 1]      = μ
        ema_volatility[t + 1] = σ
        band_lower[t + 1]     = μ - k * σ
        band_upper[t + 1]     = μ + k * σ

        # --- edge cells observe the newly generated price ---
        e              = compute_band_state(P, μ, σ, k)
        edge_states[t] = e
        _set_edge_states!(grid, edge_set, e)

        # --- CA updates the interior grid ---
        grid = _ca_step(grid, world, agents, rule_major)
        buy_fraction[t + 1], hold_fraction[t + 1], sell_fraction[t + 1] =
            compute_interior_fractions(grid)

        t in snaps && (frames[t] = copy(grid))
        verbose && next!(prog)
    end

    return MyModelBSimulationResult(
        frames, prices, log_returns, net_imbalance,
        buy_fraction, hold_fraction, sell_fraction,
        edge_states, ema_price, ema_volatility, band_lower, band_upper,
        edge_coordinates, config,
    )
end
```

- [ ] **Step 4: Run tests to verify all pass**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: PASS — sixteen testsets, no failures. (If testset 7 fails on `any(net_imbalance .!= 0)`: the buy-spreading dynamics of Rule 19280 make zero imbalance for all 50 steps essentially impossible; investigate the loop order rather than weakening the test.)

- [ ] **Step 5: Verify Model A still compiles (include check)**

Run: `julia -e 'cd("code"); include("Include.jl"); println("Model A include OK: ", hasmethod(simulate, (MyModelASimulation, Vector{Float64})))'`
Expected: `Model A include OK: true`

- [ ] **Step 6: Commit**

```bash
git add code/src/Simulate.jl code/model-b/Test-ModelB.jl
git commit -m "Rewrite Model B closed-loop simulate with explicit update order and full trajectories"
```

---

### Task 6: Stage 1 diagnostic driver

**Files:**
- Rewrite (full replacement): `code/model-b/Compute-ModelB.jl`

**Interfaces:**
- Consumes: `build(MyModelBConfiguration, …)` (Task 2), `simulate(config; …)` (Task 5), `compute_crash_statistics` (Task 1), `_PATH_TO_DATA`/`_PATH_TO_FIGS`/`_BUY_COLOR`/`_SELL_COLOR` (model-b/Include.jl), `save` (JLD2/FileIO), `std` (Statistics), Plots
- Produces: `code/data/ModelB-Diagnostic.jld2`, `code/figs/ModelB-Diagnostic.pdf`

- [ ] **Step 1: Replace the driver**

Replace the entire contents of `code/model-b/Compute-ModelB.jl` with:

```julia
# Compute-ModelB.jl — Stage 1 diagnostic driver (model-B-plan.md §7, spec §5)
#
# Runs the 32×32, 200-step closed-loop diagnostic and saves:
#   code/data/ModelB-Diagnostic.jld2   — full trajectory + config
#   code/figs/ModelB-Diagnostic.pdf    — 4-panel diagnostic figure
#
# This is a diagnostic, not a paper figure — nothing is copied to paper/figs.
# Stage 2 (64×64 ensemble) and Stage 3 (256×256 sweep) come in later sessions,
# only after this feedback loop is demonstrably working.

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Configuration — single source of truth (all assumptions stated explicitly)
# ---------------------------------------------------------------------------
config = build(MyModelBConfiguration, (
    number_of_rows        = 32,
    number_of_cols        = 32,
    steps                 = 200,
    seed                  = 42,
    initial_condition     = :balanced_perturbation,
    initial_buy_fraction  = 0.05,
    initial_sell_fraction = 0.05,
    edge_fraction         = 0.25,
    α                     = 1 / 60,
    k                     = 1.0,
    λ                     = 0.01,
    P0                    = 100.0,
    minority_fraction     = 0.20,
    rule_major_index      = 19280,
    rule_minor_index      = 19286,
))

@info "Model B Stage 1 diagnostic: $(config.number_of_rows)×$(config.number_of_cols), " *
      "$(config.steps) steps, seed $(config.seed)"
result = simulate(config)

# ---------------------------------------------------------------------------
# Save the full trajectory
# ---------------------------------------------------------------------------
save(joinpath(_PATH_TO_DATA, "ModelB-Diagnostic.jld2"), Dict(
    "frames"           => result.frames,
    "prices"           => result.prices,
    "log_returns"      => result.log_returns,
    "net_imbalance"    => result.net_imbalance,
    "buy_fraction"     => result.buy_fraction,
    "hold_fraction"    => result.hold_fraction,
    "sell_fraction"    => result.sell_fraction,
    "edge_states"      => result.edge_states,
    "ema_price"        => result.ema_price,
    "ema_volatility"   => result.ema_volatility,
    "band_lower"       => result.band_lower,
    "band_upper"       => result.band_upper,
    "edge_coordinates" => result.edge_coordinates,
    "config"           => Dict(String(f) => getfield(config, f)
                               for f in fieldnames(typeof(config))),
))
@info "Saved: ModelB-Diagnostic.jld2"

# ---------------------------------------------------------------------------
# 4-panel diagnostic figure: price/band, imbalance, edge state, populations
# ---------------------------------------------------------------------------
T = config.steps

p1 = plot(0:T, result.band_lower, fillrange = result.band_upper,
          fillalpha = 0.15, lw = 0, color = :gray, label = "EMA ± kσ")
plot!(p1, 0:T, result.ema_price, color = :gray, ls = :dash, label = "EMA")
plot!(p1, 0:T, result.prices, color = :black, lw = 1.5, label = "price")
plot!(p1, xlabel = "step", ylabel = "price", title = "Endogenous price")

p2 = plot(1:T, result.net_imbalance, color = _BUY_COLOR, legend = false,
          xlabel = "step", ylabel = "φ", title = "Net order imbalance")
hline!(p2, [0.0], color = :gray, ls = :dot)

p3 = plot(1:T, result.edge_states, seriestype = :steppost, color = :black,
          legend = false, xlabel = "step", ylabel = "edge state",
          yticks = ([0, 1, 2], ["Buy", "Hold", "Sell"]), ylims = (-0.2, 2.2),
          title = "Edge-agent state")

p4 = plot(0:T, result.buy_fraction, color = _BUY_COLOR, label = "Buy",
          xlabel = "step", ylabel = "fraction", title = "Interior populations")
plot!(p4, 0:T, result.hold_fraction, color = "#888888", label = "Hold")
plot!(p4, 0:T, result.sell_fraction, color = _SELL_COLOR, label = "Sell")

fig = plot(p1, p2, p3, p4, layout = (2, 2), size = (1000, 700),
           left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Diagnostic.pdf"))
@info "Saved: ModelB-Diagnostic.pdf"

# ---------------------------------------------------------------------------
# Numerical summary — success criterion (spec §5): the run must not be inert
# ---------------------------------------------------------------------------
crash           = compute_crash_statistics(result.sell_fraction)
n_edge_switches = count(diff(result.edge_states) .!= 0)

@info("Diagnostic summary",
    price_min       = minimum(result.prices),
    price_max       = maximum(result.prices),
    return_std      = std(result.log_returns),
    edge_switches   = n_edge_switches,
    final_buy       = result.buy_fraction[end],
    final_hold      = result.hold_fraction[end],
    final_sell      = result.sell_fraction[end],
    crash_frequency = crash.frequency,
    n_crashes       = crash.n_crashes,
)

std(result.log_returns) == 0.0 &&
    @warn "Run appears INERT: every log return is zero (model-B-plan.md known issue)."
n_edge_switches == 0 &&
    @warn "Edge state never changed: the feedback loop may not be closing."

@info "Compute-ModelB.jl complete."
```

- [ ] **Step 2: Run the full test suite (regression gate)**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: PASS — sixteen testsets, no failures.

- [ ] **Step 3: Commit the driver**

```bash
git add code/model-b/Compute-ModelB.jl
git commit -m "Replace inert Model B experiment with Stage 1 diagnostic driver"
```

---

### Task 7: Run and inspect the Stage 1 diagnostic

**Files:**
- Read/verify: `code/data/ModelB-Diagnostic.jld2` (gitignored — do not commit), `code/figs/ModelB-Diagnostic.pdf` (commit)

**Interfaces:**
- Consumes: Task 6 driver

- [ ] **Step 1: Run the diagnostic**

Run: `julia code/model-b/Compute-ModelB.jl`
Expected: progress bar completes 200 steps in seconds; both `Saved:` lines appear; the `Diagnostic summary` info block prints; **no** `INERT` or `Edge state never changed` warnings.

- [ ] **Step 2: Verify the outputs exist**

Run: `ls -la code/data/ModelB-Diagnostic.jld2 code/figs/ModelB-Diagnostic.pdf`
Expected: both files exist with non-trivial sizes (JLD2 tens of KB; PDF tens of KB).

- [ ] **Step 3: Check the success criteria numerically**

From the printed `Diagnostic summary`, confirm (spec §5): `return_std > 0`, `price_min ≠ price_max`, `edge_switches ≥ 1`, and the population fractions are not frozen at the t=0 values. Read the figure (`code/figs/ModelB-Diagnostic.pdf`) and describe what the four panels show — this inspection (does the feedback loop behave sensibly, does anything look pathological?) is the deliverable of Stage 1 and the input to the Stage 2 go/no-go decision.

- [ ] **Step 4: Commit the figure**

```bash
git add code/figs/ModelB-Diagnostic.pdf
git commit -m "Add Model B Stage 1 diagnostic run (32×32, 200 steps)"
```

---

## Plan Self-Review Notes

- **Spec coverage:** spec §1 (update order) → Task 5; §2 (types/builder) → Task 2; §3 (seeding + helpers) → Tasks 1, 3, 4; §4 (nine tests) → properties 1-9 in Task 5 step 1, with helper-level coverage in Tasks 1-3; §5 (driver) → Tasks 6-7; §6 (untouched surfaces) → global constraints + Task 4 step 5 + Task 5 step 5.
- **Known deliberate deviations from spec text:** `MyModelBConfiguration` carries `number_of_colors`/`radius` (defaults 3/4) beyond the spec's field list so `_build_ca_components` works on it unchanged; old `MyModelBSimulation`/`MyEndogenousPriceModel` types and builders stay in `Types.jl`/`Factory.jl` (unused but harmless; only the old `simulate` method is removed).
