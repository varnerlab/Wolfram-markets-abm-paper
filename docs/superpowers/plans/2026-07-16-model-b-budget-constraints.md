# Model B Budget Constraints Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-agent budget/inventory constraints and heterogeneous edge decision bands to Model B, per `docs/superpowers/specs/2026-07-16-model-b-budget-constraints-design.md`, then rerun the Stage 1 diagnostic.

**Architecture:** Two layers — the CA sentiment layer is untouched; a new execution layer (per-cell `cash`/`shares`/`avg_cost` books) filters desired trades into executed orders at the standing quote, and only executed orders move the price. Edge agents become full market participants with per-agent band half-widths `k_i ~ U(k(1−δ), k(1+δ))`.

**Tech Stack:** Julia (project env at `code/`), `Test` stdlib, JLD2, Plots. No new dependencies.

## Global Constraints

- Run tests with: `julia code/model-b/Test-ModelB.jl` from the repo root (any cwd works; paths are `@__DIR__`-relative). First run takes ~1–2 min (compile); a run ends with `Test Summary:` lines per testset. A failing script exits nonzero with `Some tests did not pass`.
- Cell states everywhere: 0 = Buy, 1 = Hold, 2 = Sell.
- Series conventions (existing, keep): state-like vectors have length `steps+1` (index 1 = t=0); transition-like vectors have length `steps` (index t = step t).
- RNG contract: all Model B randomness comes from `Xoshiro(config.seed)`, consumed in this exact order: (1) edge-cell sampling, (2) edge band half-widths, (3) initial-grid perturbation, (4) minority rule assignment. The band draw (2) is NEW — inserting it intentionally changes seeded trajectories vs. the previous commit; that is expected and fine.
- Execution price: all affordability checks AND fills at step t use `prices[t]` (the standing quote P_{t-1}); the executed imbalance then sets `prices[t+1]`.
- The identity `log_returns[t] == λ * net_imbalance[t]` must keep holding exactly, with `net_imbalance` now the EXECUTED imbalance.
- Model A (`code/model-a/`, `simulate(::MyModelASimulation, ...)`) must be untouched. The scalar-state `_set_edge_states!(grid, ::Set, state::Int64)` method stays (Model A uses it).
- Code style: 4-space indent, `My*` type names, docstrings on every public function, section-divider comments matching the existing files.
- Every commit message ends with:

```
Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019ckqHGsozaf7NKx4DVYpU2
```

**Useful constants for the 16×16 test config** (`_test_config()` in Test-ModelB.jl: 16×16, steps=50, seed=7, defaults otherwise): boundary cells = 60, active edges `n_edge` = 15, interior cells `N_int` = 196, `N_traders` = 211.

---

### Task 1: Configuration fields (`initial_cash`, `initial_shares`, `cost_basis_rule`, `edge_band_spread`)

**Files:**
- Modify: `code/src/Types.jl` (MyModelBConfiguration struct, ~line 186–205)
- Modify: `code/src/Factory.jl` (build(MyModelBConfiguration,…), ~line 229–270)
- Test: `code/model-b/Test-ModelB.jl` (testset "configuration builder: defaults and validation", ~line 80–111)

**Interfaces:**
- Consumes: existing `build(MyModelBConfiguration, data::NamedTuple)`.
- Produces: 4 new config fields with defaults — `initial_cash::Float64 = 1000.0`, `initial_shares::Int64 = 10`, `cost_basis_rule::Bool = true`, `edge_band_spread::Float64 = 0.5`. Validation: `initial_cash ≥ 0`, `initial_shares ≥ 0`, `0 ≤ edge_band_spread < 1`, each throwing `ArgumentError`.

- [ ] **Step 1: Write the failing tests.** In `code/model-b/Test-ModelB.jl`, inside the `@testset "configuration builder: defaults and validation"` block, append after the existing `@test config.rule_minor_index == 19286` line:

```julia
    # budget-constraint fields (spec 2026-07-16 §3)
    @test config.initial_cash == 1000.0
    @test config.initial_shares == 10
    @test config.cost_basis_rule == true
    @test config.edge_band_spread == 0.5
```

and append after the existing `@test_throws ArgumentError build(... P0 = -1.0))` lines:

```julia
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, initial_cash = -1.0))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, initial_shares = -1))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, edge_band_spread = 1.0))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, edge_band_spread = -0.1))
```

- [ ] **Step 2: Run tests, verify they fail.**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: the configuration testset errors (`type MyModelBConfiguration has no field initial_cash` or similar); all other testsets still pass.

- [ ] **Step 3: Add the struct fields.** In `code/src/Types.jl`, inside `mutable struct MyModelBConfiguration`, after the line `rule_minor_index::Int64`, insert:

```julia
    initial_cash::Float64            # starting cash per trading cell (spec 2026-07-16)
    initial_shares::Int64            # starting share inventory per trading cell
    cost_basis_rule::Bool            # sell only above average acquisition cost (disposition effect)
    edge_band_spread::Float64        # δ: k_i ~ U(k(1−δ), k(1+δ)); 0 ⇒ homogeneous bands
```

- [ ] **Step 4: Add defaults and validation.** In `code/src/Factory.jl`, in `build(::Type{MyModelBConfiguration}, …)`, after the line `model.rule_minor_index = get(data, :rule_minor_index, 19286)`, insert:

```julia
    model.initial_cash          = get(data, :initial_cash, 1000.0)
    model.initial_shares        = get(data, :initial_shares, 10)
    model.cost_basis_rule       = get(data, :cost_basis_rule, true)
    model.edge_band_spread      = get(data, :edge_band_spread, 0.5)
```

and after the `model.P0 > 0.0 || throw(...)` block, before `return model`, insert:

```julia
    model.initial_cash ≥ 0.0 ||
        throw(ArgumentError("initial_cash must be ≥ 0 (got $(model.initial_cash))"))
    model.initial_shares ≥ 0 ||
        throw(ArgumentError("initial_shares must be ≥ 0 (got $(model.initial_shares))"))
    (0.0 ≤ model.edge_band_spread < 1.0) ||
        throw(ArgumentError("edge_band_spread must be in [0, 1) (got $(model.edge_band_spread))"))
```

Also update the build docstring's "Optional keys (defaults)" sentence to include: `initial_cash (1000.0), initial_shares (10), cost_basis_rule (true), edge_band_spread (0.5)`.

- [ ] **Step 5: Run tests, verify they pass.**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: all testsets pass.

- [ ] **Step 6: Commit.**

```bash
git add code/src/Types.jl code/src/Factory.jl code/model-b/Test-ModelB.jl
git commit -m "Add budget-constraint and band-spread fields to MyModelBConfiguration"
```

---

### Task 2: Agent books and per-agent band draws

**Files:**
- Modify: `code/src/Types.jl` (new struct after MyModelBConfiguration)
- Modify: `code/src/Factory.jl` (two new builders after `build_initial_grid`)
- Test: `code/model-b/Test-ModelB.jl` (new testsets after "initial grid modes")

**Interfaces:**
- Consumes: `MyModelBConfiguration` fields from Task 1.
- Produces:
  - `struct MyAgentBooks` with fields `cash::Matrix{Float64}`, `shares::Matrix{Int64}`, `avg_cost::Matrix{Float64}` (grid-shaped).
  - `build_agent_books(config::MyModelBConfiguration)::MyAgentBooks` — every cell gets `(initial_cash, initial_shares, P0)`.
  - `build_edge_bands(k::Float64, spread::Float64, n_edge::Int64, rng::AbstractRNG)::Vector{Float64}` — `k_i = k·(1 − spread + 2·spread·uᵢ)`, `uᵢ ~ U(0,1)` from `rng`; consumes exactly `n_edge` draws even when `spread == 0`.

- [ ] **Step 1: Write the failing tests.** In `code/model-b/Test-ModelB.jl`, after the `@testset "initial grid modes"` block, insert:

```julia
@testset "agent books: initial endowments" begin
    config = _test_config()
    books  = build_agent_books(config)
    @test size(books.cash) == (16, 16)
    @test size(books.shares) == (16, 16)
    @test size(books.avg_cost) == (16, 16)
    @test all(books.cash .== config.initial_cash)
    @test all(books.shares .== config.initial_shares)
    @test all(books.avg_cost .== config.P0)
end

@testset "edge bands: seeded per-agent half-widths" begin
    k1 = build_edge_bands(1.0, 0.5, 15, Xoshiro(11))
    @test length(k1) == 15
    @test all(0.5 .≤ k1 .≤ 1.5)
    @test k1 == build_edge_bands(1.0, 0.5, 15, Xoshiro(11))   # seeded → identical
    @test k1 != build_edge_bands(1.0, 0.5, 15, Xoshiro(12))

    # δ = 0 recovers the homogeneous model exactly
    @test build_edge_bands(1.0, 0.0, 15, Xoshiro(11)) == fill(1.0, 15)

    # δ = 0 must still consume the same number of rng draws (order contract)
    rng_a = Xoshiro(11); build_edge_bands(1.0, 0.0, 15, rng_a)
    rng_b = Xoshiro(11); build_edge_bands(1.0, 0.9, 15, rng_b)
    @test rand(rng_a) == rand(rng_b)
end
```

- [ ] **Step 2: Run tests, verify they fail.**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: the two new testsets error with `UndefVarError: build_agent_books not defined` / `build_edge_bands not defined`; everything else passes.

- [ ] **Step 3: Add the struct.** In `code/src/Types.jl`, after the closing `end` of `MyModelBConfiguration` (before `MyModelBSimulationResult`), insert:

```julia
"""
    MyAgentBooks

Per-cell balance sheets for Model B trading cells (interior + active edge).
Matrices are grid-shaped; passive boundary cells keep their initial entries
and never trade. avg_cost is average-cost accounting: updated on buys,
unchanged by sells, and consulted only when shares ≥ 1.
"""
struct MyAgentBooks
    cash::Matrix{Float64}
    shares::Matrix{Int64}
    avg_cost::Matrix{Float64}
end
```

- [ ] **Step 4: Add the builders.** In `code/src/Factory.jl`, after `build_initial_grid`, insert:

```julia
"""
    build_agent_books(config) → MyAgentBooks

Grid-shaped balance sheets: every cell starts with config.initial_cash,
config.initial_shares, and an average cost basis of config.P0 (the endowed
shares are treated as acquired at the initial price).
"""
function build_agent_books(config::MyModelBConfiguration)::MyAgentBooks
    nrows, ncols = config.number_of_rows, config.number_of_cols
    return MyAgentBooks(
        fill(config.initial_cash, nrows, ncols),
        fill(config.initial_shares, nrows, ncols),
        fill(config.P0, nrows, ncols),
    )
end

"""
    build_edge_bands(k, spread, n_edge, rng) → Vector{Float64}

Per-agent band half-widths k_i ~ Uniform(k·(1−spread), k·(1+spread)), drawn
once at build time (spec 2026-07-16 decision 8). spread = 0 returns exactly
fill(k, n_edge) but still consumes n_edge draws, so the seeded draw ORDER is
identical for every spread value.
"""
function build_edge_bands(
    k::Float64, spread::Float64, n_edge::Int64, rng::AbstractRNG,
)::Vector{Float64}
    u = rand(rng, n_edge)
    return k .* (1.0 .- spread .+ 2.0 .* spread .* u)
end
```

- [ ] **Step 5: Run tests, verify they pass.**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: all testsets pass.

- [ ] **Step 6: Commit.**

```bash
git add code/src/Types.jl code/src/Factory.jl code/model-b/Test-ModelB.jl
git commit -m "Add MyAgentBooks and seeded per-agent edge band construction"
```

---

### Task 3: Pure compute helpers (`compute_desired_order`, `compute_book_totals`)

**Files:**
- Modify: `code/src/Compute.jl` (Model B trajectory helpers section, after `compute_interior_fractions`)
- Test: `code/model-b/Test-ModelB.jl` (new testset after "crash statistics from the full trajectory")

**Interfaces:**
- Consumes: `MyAgentBooks` from Task 2.
- Produces:
  - `compute_desired_order(state::Int64)::Int64` — Buy(0) → +1, Sell(2) → −1, Hold(1) → 0.
  - `compute_book_totals(books::MyAgentBooks, edge_coordinates::Vector{Tuple{Int64,Int64}})::Tuple{Float64,Int64}` — (total cash, total shares) summed over strictly interior cells plus the given active edge cells; passive boundary cells excluded.

- [ ] **Step 1: Write the failing tests.** In `code/model-b/Test-ModelB.jl`, after the `@testset "configuration builder: defaults and validation"` block (NOT earlier in the file — this testset calls `_test_config`, which is defined at ~line 72, and testsets execute at include time in file order), insert:

```julia
@testset "desired orders and book totals" begin
    @test compute_desired_order(0) == 1     # Buy
    @test compute_desired_order(1) == 0     # Hold
    @test compute_desired_order(2) == -1    # Sell

    config = _test_config()                  # 16×16: N_int = 196
    books  = build_agent_books(config)
    edges  = [(1, 2), (16, 5)]
    cash, shares = compute_book_totals(books, edges)
    @test cash   ≈ (196 + 2) * config.initial_cash
    @test shares == (196 + 2) * config.initial_shares

    # passive boundary entries do not contribute
    books.cash[1, 1] = 1.0e9
    cash2, _ = compute_book_totals(books, edges)
    @test cash2 ≈ cash
end
```

(Note: `_test_config` is defined further down in the file than this testset's insertion point in reading order, but the whole file is included before any testset runs only if definitions precede use — `_test_config` is defined at ~line 72, BEFORE this insertion point at ~line 66. To be safe, insert this testset AFTER the `_test_config` definition, i.e., after the "configuration builder" testset, and before "edge coordinates: seeded boundary sample".)

- [ ] **Step 2: Run tests, verify they fail.**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: new testset errors with `UndefVarError: compute_desired_order not defined`; everything else passes.

- [ ] **Step 3: Implement.** In `code/src/Compute.jl`, at the end of the "Model B trajectory helpers" section (after `compute_interior_fractions`, before `compute_crash_statistics`), insert:

```julia
"""
    compute_desired_order(state) → Int64

Map a cell state to its desired unit order: Buy(0) → +1, Sell(2) → −1,
Hold(1) → 0. Flow semantics (spec 2026-07-16 decision 2): a cell submits
this order EVERY step it remains in the state.
"""
function compute_desired_order(state::Int64)::Int64
    return state == 0 ? 1 : (state == 2 ? -1 : 0)
end

"""
    compute_book_totals(books, edge_coordinates) → (cash, shares)

Aggregate cash and share holdings over the trading population: strictly
interior cells plus the active edge cells. Passive boundary cells are
excluded (they never trade). Used for the per-step accounting identity.
"""
function compute_book_totals(
    books::MyAgentBooks,
    edge_coordinates::Vector{Tuple{Int64,Int64}},
)::Tuple{Float64,Int64}
    nrows, ncols = size(books.cash)
    cash = 0.0; shares = 0
    for r in 2:nrows-1, c in 2:ncols-1
        cash   += books.cash[r, c]
        shares += books.shares[r, c]
    end
    for (r, c) in edge_coordinates
        cash   += books.cash[r, c]
        shares += books.shares[r, c]
    end
    return (cash, shares)
end
```

- [ ] **Step 4: Run tests, verify they pass.**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: all testsets pass.

- [ ] **Step 5: Commit.**

```bash
git add code/src/Compute.jl code/model-b/Test-ModelB.jl
git commit -m "Add desired-order mapping and trading-population book totals"
```

---

### Task 4: Execution engine (`_try_execute!`, `execute_orders!`, per-agent edge writes)

**Files:**
- Modify: `code/src/Simulate.jl` (Internal helpers section, after `_set_edge_states!`)
- Test: `code/model-b/Test-ModelB.jl` (new testset after "desired orders and book totals")

**Interfaces:**
- Consumes: `MyAgentBooks`, `compute_desired_order`, Task 1 config fields.
- Produces:
  - `_try_execute!(books::MyAgentBooks, r::Int64, c::Int64, order::Int64, P::Float64, cost_basis_rule::Bool)::Bool` — attempts a ±1 order at price P; settles the books and returns true iff filled. Buy fills iff `cash ≥ P`; sell fills iff `shares ≥ 1` and (`!cost_basis_rule` or `P > avg_cost`, strict).
  - `execute_orders!(books, grid::Array{Int64,2}, edge_coordinates::Vector{Tuple{Int64,Int64}}, edge_states::Vector{Int64}, P::Float64; cost_basis_rule::Bool = true)::NamedTuple{(:executed_buys, :executed_sells, :suppressed_buys, :suppressed_sells), NTuple{4,Int64}}` — interior orders read from grid states; edge i's order read from `edge_states[i]` (NOT from the grid); Hold cells are neither executed nor suppressed. Never touches the grid.
  - `_set_edge_states!(grid, edge_coordinates::Vector{Tuple{Int64,Int64}}, states::Vector{Int64})` — per-agent overload; the existing scalar `Set` method stays for Model A.

- [ ] **Step 1: Write the failing tests.** In `code/model-b/Test-ModelB.jl`, after the "desired orders and book totals" testset, insert:

```julia
@testset "execution engine: filter and settlement" begin
    config = _test_config()
    P0     = config.P0                                     # 100.0
    no_edges = Tuple{Int64,Int64}[]
    no_states = Int64[]

    # --- broke buyer: order suppressed, state and books untouched ---
    books = build_agent_books(config)
    books.cash .= 50.0                                     # below P0
    grid = _uniform_interior_grid(16, 16, 0)               # all-Buy interior
    snapshot = copy(grid)
    counts = execute_orders!(books, grid, no_edges, no_states, P0)
    @test counts.suppressed_buys == 196
    @test counts.executed_buys == 0
    @test grid == snapshot                                 # sentiment never overwritten
    @test all(books.shares .== config.initial_shares)

    # --- shareless seller: order suppressed ---
    books = build_agent_books(config)
    books.shares .= 0
    grid = _uniform_interior_grid(16, 16, 2)               # all-Sell interior
    counts = execute_orders!(books, grid, no_edges, no_states, P0)
    @test counts.suppressed_sells == 196
    @test counts.executed_sells == 0

    # --- disposition rule: strict P > avg_cost ---
    books = build_agent_books(config)                      # avg_cost = 100 everywhere
    grid  = _uniform_interior_grid(16, 16, 2)
    counts = execute_orders!(books, grid, no_edges, no_states, 100.0;
                             cost_basis_rule = true)
    @test counts.suppressed_sells == 196                   # P == basis blocks
    counts = execute_orders!(books, grid, no_edges, no_states, 100.0;
                             cost_basis_rule = false)
    @test counts.executed_sells == 196                     # toggle off permits
    books = build_agent_books(config)
    counts = execute_orders!(books, grid, no_edges, no_states, 100.01;
                             cost_basis_rule = true)
    @test counts.executed_sells == 196                     # P > basis permits

    # --- settlement math and running average cost ---
    books = build_agent_books(config)
    books.shares[2, 2] = 0; books.avg_cost[2, 2] = 0.0; books.cash[2, 2] = 1000.0
    onebuy = fill(1, 16, 16); onebuy[2, 2] = 0             # single Buy cell
    execute_orders!(books, onebuy, no_edges, no_states, 120.0)
    @test books.cash[2, 2] ≈ 880.0
    @test books.shares[2, 2] == 1
    @test books.avg_cost[2, 2] ≈ 120.0
    execute_orders!(books, onebuy, no_edges, no_states, 60.0)
    @test books.shares[2, 2] == 2
    @test books.avg_cost[2, 2] ≈ 90.0                      # (120 + 60) / 2
    onesell = fill(1, 16, 16); onesell[2, 2] = 2
    execute_orders!(books, onesell, no_edges, no_states, 100.0)
    @test books.shares[2, 2] == 1
    @test books.cash[2, 2] ≈ 880.0 - 60.0 + 100.0
    @test books.avg_cost[2, 2] ≈ 90.0                      # sells never change basis

    # --- edge orders come from edge_states and count in the totals ---
    books = build_agent_books(config)                      # shares = 10, basis = 100
    grid  = fill(1, 16, 16)                                # nobody in the interior trades
    edges = build_edge_coordinates(16, 16, 0.25, Xoshiro(11))
    counts = execute_orders!(books, grid, edges, fill(2, length(edges)), 150.0)
    @test counts.executed_sells == length(edges)           # 15 edge sells filled
    @test all(books.shares[r, c] == config.initial_shares - 1 for (r, c) in edges)

    # --- per-agent edge state writes ---
    grid = fill(1, 16, 16)
    states = [i % 3 for i in 1:length(edges)]              # mixed 0/1/2 pattern
    _set_edge_states!(grid, edges, states)
    @test all(grid[edges[i]...] == states[i] for i in eachindex(edges))
end
```

- [ ] **Step 2: Run tests, verify they fail.**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: new testset errors with `UndefVarError: execute_orders! not defined`; everything else passes.

- [ ] **Step 3: Implement.** In `code/src/Simulate.jl`, in the "Internal helpers" section after the existing `_set_edge_states!`, insert:

```julia
"""
    _set_edge_states!(grid, edge_coordinates, states)

Per-agent variant: write states[i] into edge_coordinates[i] in-place.
(The scalar Set method above is Model A's homogeneous edge write.)
"""
function _set_edge_states!(
    grid::Array{Int64,2},
    edge_coordinates::Vector{Tuple{Int64,Int64}},
    states::Vector{Int64},
)
    for (i, (r, c)) in enumerate(edge_coordinates)
        grid[r, c] = states[i]
    end
end

"""
    _try_execute!(books, r, c, order, P, cost_basis_rule) → Bool

Attempt a ±1 order for the cell at (r, c) at price P; settle the books and
return true iff filled (spec 2026-07-16 §1–2). A buy fills iff cash ≥ P; a
sell fills iff shares ≥ 1 and, when cost_basis_rule is set, P > avg_cost
(strict — the disposition effect). Buys update the running average cost;
sells leave it unchanged.
"""
function _try_execute!(
    books::MyAgentBooks, r::Int64, c::Int64,
    order::Int64, P::Float64, cost_basis_rule::Bool,
)::Bool
    if order == 1
        books.cash[r, c] ≥ P || return false
        s_old = books.shares[r, c]
        books.avg_cost[r, c] = (books.avg_cost[r, c] * s_old + P) / (s_old + 1)
        books.shares[r, c]   = s_old + 1
        books.cash[r, c]    -= P
        return true
    elseif order == -1
        books.shares[r, c] ≥ 1 || return false
        (!cost_basis_rule || P > books.avg_cost[r, c]) || return false
        books.shares[r, c] -= 1
        books.cash[r, c]   += P
        return true
    end
    return false
end

"""
    execute_orders!(books, grid, edge_coordinates, edge_states, P;
                    cost_basis_rule) → NamedTuple

Execution layer (spec 2026-07-16 decision 3): filter every trading cell's
desired order through its books at the standing quote P, settling fills
immediately. Interior orders come from grid states; edge agent i's order
comes from edge_states[i] (its band decision e_{i,t-1}), never from the
grid. Hold cells submit nothing and are not counted as suppressed. The grid
is never modified — the constraint binds orders, not sentiment. Fill order
is irrelevant: each cell trades at most one share against its own books at
one fixed price.
"""
function execute_orders!(
    books::MyAgentBooks,
    grid::Array{Int64,2},
    edge_coordinates::Vector{Tuple{Int64,Int64}},
    edge_states::Vector{Int64},
    P::Float64;
    cost_basis_rule::Bool = true,
)::NamedTuple{(:executed_buys, :executed_sells, :suppressed_buys, :suppressed_sells), NTuple{4,Int64}}
    nrows, ncols = size(grid)
    exec_b = 0; exec_s = 0; supp_b = 0; supp_s = 0
    for r in 2:nrows-1, c in 2:ncols-1
        order = compute_desired_order(grid[r, c])
        order == 0 && continue
        if _try_execute!(books, r, c, order, P, cost_basis_rule)
            order == 1 ? (exec_b += 1) : (exec_s += 1)
        else
            order == 1 ? (supp_b += 1) : (supp_s += 1)
        end
    end
    for (i, (r, c)) in enumerate(edge_coordinates)
        order = compute_desired_order(edge_states[i])
        order == 0 && continue
        if _try_execute!(books, r, c, order, P, cost_basis_rule)
            order == 1 ? (exec_b += 1) : (exec_s += 1)
        else
            order == 1 ? (supp_b += 1) : (supp_s += 1)
        end
    end
    return (executed_buys = exec_b, executed_sells = exec_s,
            suppressed_buys = supp_b, suppressed_sells = supp_s)
end
```

- [ ] **Step 4: Run tests, verify they pass.**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: all testsets pass.

- [ ] **Step 5: Commit.**

```bash
git add code/src/Simulate.jl code/model-b/Test-ModelB.jl
git commit -m "Add order execution engine with budget, inventory, and disposition filters"
```

---

### Task 5: Result struct and closed-loop rewrite

This is the integration task: the result struct changes shape, the simulate loop routes desired orders through the execution engine, and both the stale existing tests and the new spec tests are updated in the same commit (the struct change breaks them together).

**Files:**
- Modify: `code/src/Types.jl` (MyModelBSimulationResult, ~line 207–237)
- Modify: `code/src/Simulate.jl` (simulate(::MyModelBConfiguration), ~line 194–319)
- Test: `code/model-b/Test-ModelB.jl` (testsets 1–4, 6, 8, 9 updated; new testsets 10–15)

**Interfaces:**
- Consumes: everything from Tasks 1–4 (exact signatures listed in those tasks).
- Produces: the new `MyModelBSimulationResult` (field list in Step 1 below — later tasks and Stage 2 code rely on these exact names) and the rewritten `simulate(config::MyModelBConfiguration; initial_grid, snapshot_steps, verbose)`. Removed field: `edge_states`. New scalar: `edge_switches::Int64` = Σᵢ Σₜ [e_{i,t} ≠ e_{i,t−1}] with baseline e_{i,0} = Hold.

- [ ] **Step 1: Replace the result struct.** In `code/src/Types.jl`, replace the entire `MyModelBSimulationResult` docstring and struct with:

```julia
"""
    MyModelBSimulationResult

Immutable container for a Model B run: sparse grid snapshots plus the COMPLETE
aggregate trajectory, so all statistics are computed from every step.

State-like series (length steps+1, index 1 = t=0): prices, ema_price,
ema_volatility, band_lower, band_upper (nominal-k band, for plotting),
buy_fraction, hold_fraction, sell_fraction, total_cash, total_shares.
Transition-like series (length steps, index t = step t): log_returns
(= λ·φ_{t-1}), net_imbalance (EXECUTED imbalance φ_{t-1}, the value that
generated P_t), edge_buy_count/edge_hold_count/edge_sell_count (counts of
e_{i,t} over active edge agents), executed_buys, executed_sells,
suppressed_buys, suppressed_sells.

edge_switches = Σ_i Σ_t [e_{i,t} ≠ e_{i,t-1}], baseline e_{i,0} = Hold.
final_books holds the trading-cell balance sheets at t = steps. edge_k[i]
is the band half-width of the agent at edge_coordinates[i] (same order).
frames always contains t=0 and t=steps.
"""
struct MyModelBSimulationResult
    frames::Dict{Int64, Array{Int64,2}}
    prices::Vector{Float64}
    log_returns::Vector{Float64}
    net_imbalance::Vector{Float64}
    buy_fraction::Vector{Float64}
    hold_fraction::Vector{Float64}
    sell_fraction::Vector{Float64}
    edge_buy_count::Vector{Int64}
    edge_hold_count::Vector{Int64}
    edge_sell_count::Vector{Int64}
    edge_switches::Int64
    ema_price::Vector{Float64}
    ema_volatility::Vector{Float64}
    band_lower::Vector{Float64}
    band_upper::Vector{Float64}
    executed_buys::Vector{Int64}
    executed_sells::Vector{Int64}
    suppressed_buys::Vector{Int64}
    suppressed_sells::Vector{Int64}
    total_cash::Vector{Float64}
    total_shares::Vector{Int64}
    final_books::MyAgentBooks
    edge_coordinates::Vector{Tuple{Int64,Int64}}
    edge_k::Vector{Float64}
    config::MyModelBConfiguration
end
```

- [ ] **Step 2: Rewrite the loop.** In `code/src/Simulate.jl`, replace the docstring and body of `simulate(config::MyModelBConfiguration; …)` with:

```julia
"""
    simulate(config::MyModelBConfiguration; initial_grid, snapshot_steps, verbose)
        → MyModelBSimulationResult

Run the closed-loop (Model B) simulation with per-agent budget constraints
(spec 2026-07-16).

Step t (t = 1..steps) transforms X_{t-1} → X_t in this exact order:

    o_i     = desired orders (interior grid states; e_{i,t-1} for edges)
    x_i     = execution filter + settlement at the standing quote P_{t-1}:
              buy iff cash ≥ P; sell iff shares ≥ 1 and
              (¬cost_basis_rule or P > avg_cost)
    φ_{t-1} = (executed buys − executed sells) / N_traders
    P_t     = P_{t-1} · exp(λ · φ_{t-1})          (log return = λ·φ_{t-1})
    μ_t     = μ_{t-1} + α·(P_t − μ_{t-1})         (EMA sees the NEW price)
    σ_t     = σ_{t-1} + α·(|P_t − μ_t| − σ_{t-1})
    e_{i,t} = BandState(P_t, μ_t, σ_t, k_i)       → active edge cell i
    X_t     = CA step on interior of X_{t-1}      (edge neighbors see e_{i,t})

N_traders = N_interior + N_active_edge, fixed for the run. All randomness
comes from Xoshiro(config.seed), consumed in fixed order: (1) edge-cell
sampling, (2) edge band half-widths, (3) initial-grid perturbation,
(4) minority rule assignment. Same config ⇒ identical output.

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

    # (1) edge sampling, (2) band half-widths, (3) initial grid, (4) minority rules
    edge_coordinates = build_edge_coordinates(nrows, ncols, config.edge_fraction, rng)
    edge_k           = build_edge_bands(k, config.edge_band_spread,
                                        length(edge_coordinates), rng)
    grid             = build_initial_grid(config, rng; custom_grid = initial_grid)
    world, agents, rule_major = _build_ca_components(config; rng = rng)

    books     = build_agent_books(config)
    n_edge    = length(edge_coordinates)
    N_traders = (nrows - 2) * (ncols - 2) + n_edge

    # Output containers
    prices           = Vector{Float64}(undef, steps + 1)
    log_returns      = Vector{Float64}(undef, steps)
    net_imbalance    = Vector{Float64}(undef, steps)
    buy_fraction     = Vector{Float64}(undef, steps + 1)
    hold_fraction    = Vector{Float64}(undef, steps + 1)
    sell_fraction    = Vector{Float64}(undef, steps + 1)
    edge_buy_count   = Vector{Int64}(undef, steps)
    edge_hold_count  = Vector{Int64}(undef, steps)
    edge_sell_count  = Vector{Int64}(undef, steps)
    ema_price        = Vector{Float64}(undef, steps + 1)
    ema_volatility   = Vector{Float64}(undef, steps + 1)
    band_lower       = Vector{Float64}(undef, steps + 1)
    band_upper       = Vector{Float64}(undef, steps + 1)
    executed_buys    = Vector{Int64}(undef, steps)
    executed_sells   = Vector{Int64}(undef, steps)
    suppressed_buys  = Vector{Int64}(undef, steps)
    suppressed_sells = Vector{Int64}(undef, steps)
    total_cash       = Vector{Float64}(undef, steps + 1)
    total_shares     = Vector{Int64}(undef, steps + 1)

    # t = 0 state
    prices[1]         = P0
    ema_price[1]      = P0
    ema_volatility[1] = 0.0
    band_lower[1]     = P0
    band_upper[1]     = P0
    buy_fraction[1], hold_fraction[1], sell_fraction[1] = compute_interior_fractions(grid)
    total_cash[1], total_shares[1] = compute_book_totals(books, edge_coordinates)

    # Per-agent edge states e_{i,t}; baseline e_{i,0} = Hold
    edge_now      = fill(1, n_edge)
    edge_switches = 0

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
        # --- desired orders are filtered through the books and settled
        #     at the standing quote P_{t-1} ---
        counts = execute_orders!(books, grid, edge_coordinates, edge_now, prices[t];
                                 cost_basis_rule = config.cost_basis_rule)
        executed_buys[t]    = counts.executed_buys
        executed_sells[t]   = counts.executed_sells
        suppressed_buys[t]  = counts.suppressed_buys
        suppressed_sells[t] = counts.suppressed_sells
        total_cash[t + 1], total_shares[t + 1] =
            compute_book_totals(books, edge_coordinates)

        # --- the EXECUTED imbalance generates the next price ---
        φ                = (counts.executed_buys - counts.executed_sells) / N_traders
        net_imbalance[t] = φ
        P                = prices[t] * exp(λ * φ)
        prices[t + 1]    = P
        log_returns[t]   = λ * φ

        # --- online EMA / volatility observe the NEW price ---
        μ = μ + α * (P - μ)
        σ = σ + α * (abs(P - μ) - σ)
        ema_price[t + 1]      = μ
        ema_volatility[t + 1] = σ
        band_lower[t + 1]     = μ - k * σ      # nominal-k band, for plotting
        band_upper[t + 1]     = μ + k * σ

        # --- per-agent edge band decisions observe the newly generated price ---
        for i in 1:n_edge
            e = compute_band_state(P, μ, σ, edge_k[i])
            edge_switches += (e != edge_now[i])
            edge_now[i]    = e
        end
        edge_buy_count[t]  = count(==(0), edge_now)
        edge_hold_count[t] = count(==(1), edge_now)
        edge_sell_count[t] = count(==(2), edge_now)
        _set_edge_states!(grid, edge_coordinates, edge_now)

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
        edge_buy_count, edge_hold_count, edge_sell_count, edge_switches,
        ema_price, ema_volatility, band_lower, band_upper,
        executed_buys, executed_sells, suppressed_buys, suppressed_sells,
        total_cash, total_shares, books,
        edge_coordinates, edge_k, config,
    )
end
```

- [ ] **Step 3: Update the stale closed-loop testsets.** In `code/model-b/Test-ModelB.jl`, apply these exact replacements.

Testset 1 — φ now has edges in the denominator (196 interior traders out of 211; edges are Hold at t=1 and submit nothing):

```julia
@testset "1. positive interior imbalance raises the price" begin
    config = _test_config(initial_condition = :custom, steps = 1)
    grid   = _uniform_interior_grid(16, 16, 0)            # all-Buy interior
    result = simulate(config; initial_grid = grid, verbose = false)
    n_edge = length(result.edge_coordinates)
    @test result.net_imbalance[1] ≈ 196 / (196 + n_edge)
    @test result.executed_buys[1] == 196                  # cash 1000 ≥ P0 = 100
    @test result.prices[2] > result.prices[1]
    @test result.log_returns[1] ≈ config.λ * result.net_imbalance[1]
end
```

Testset 2 — under the default disposition rule an all-Sell interior at P = basis is fully suppressed; the price only falls with the toggle off:

```julia
@testset "2. negative interior imbalance lowers the price" begin
    config = _test_config(initial_condition = :custom, steps = 1,
                          cost_basis_rule = false)
    grid   = _uniform_interior_grid(16, 16, 2)            # all-Sell interior
    result = simulate(config; initial_grid = grid, verbose = false)
    n_edge = length(result.edge_coordinates)
    @test result.net_imbalance[1] ≈ -196 / (196 + n_edge)
    @test result.prices[2] < result.prices[1]
end
```

Testset 3 — per-agent edge states (all still flip: with λ = 1 the first price move dwarfs every band):

```julia
@testset "3. edge cells respond to the newly generated price" begin
    # All-Buy interior with λ = 1: P₁ ≈ 253 blows through every agent's band
    # (upper ≤ μ₁ + 1.5·σ₁ ≈ 106) → every edge agent decides Sell at t = 1.
    # Under the OLD (wrong) ordering the edges would see P₀ = μ₀ = 100 → Hold.
    config = _test_config(initial_condition = :custom, steps = 1, λ = 1.0)
    grid   = _uniform_interior_grid(16, 16, 0)
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.edge_sell_count[1] == length(result.edge_coordinates)
    @test result.prices[2] > result.band_upper[2]
end
```

Testset 4 — same scenario and assertions, updated title and comment (boundary grid *states* never trade; active edge orders come from band decisions, which are Hold at t = 1):

```julia
@testset "4. boundary grid states never enter price formation" begin
    # Boundary painted all-Sell, interior all-Hold: passive boundary cells
    # never trade, and active edge ORDERS come from the band state e_{i,0} =
    # Hold, not from the grid → φ_exec = 0 and the price cannot move.
    config = _test_config(initial_condition = :custom, steps = 1)
    grid = fill(1, 16, 16)
    grid[1, :] .= 2; grid[16, :] .= 2; grid[:, 1] .= 2; grid[:, 16] .= 2
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.net_imbalance[1] == 0.0
    @test result.executed_sells[1] == 0
    @test result.prices[2] == result.prices[1]
end
```

Testset 6 — extend the all-Hold null control (append inside the existing testset, replacing the `edge_states` line):

```julia
@testset "6. all-Hold null control is stationary" begin
    config = _test_config(initial_condition = :all_hold)
    result = simulate(config; verbose = false)
    n_edge = length(result.edge_coordinates)
    @test all(result.prices .== config.P0)
    @test all(result.net_imbalance .== 0.0)
    @test all(result.log_returns .== 0.0)
    @test all(result.edge_hold_count .== n_edge)
    @test result.edge_switches == 0
    @test all(result.hold_fraction .== 1.0)
    @test all(result.executed_buys .== 0) && all(result.executed_sells .== 0)
    @test all(result.suppressed_buys .== 0) && all(result.suppressed_sells .== 0)
    @test all(result.total_cash .== result.total_cash[1])   # nobody ever trades
    @test all(result.total_shares .== result.total_shares[1])
    @test result.frames[config.steps] == fill(1, 16, 16)
end
```

Testset 8 — replace the `edge_states` comparison and extend with the new fields:

```julia
@testset "8. same seed gives identical output" begin
    r1 = simulate(_test_config(); verbose = false)
    r2 = simulate(_test_config(); verbose = false)
    @test r1.prices == r2.prices
    @test r1.log_returns == r2.log_returns
    @test r1.net_imbalance == r2.net_imbalance
    @test r1.buy_fraction == r2.buy_fraction
    @test r1.hold_fraction == r2.hold_fraction
    @test r1.sell_fraction == r2.sell_fraction
    @test r1.edge_buy_count == r2.edge_buy_count
    @test r1.edge_hold_count == r2.edge_hold_count
    @test r1.edge_sell_count == r2.edge_sell_count
    @test r1.edge_switches == r2.edge_switches
    @test r1.ema_price == r2.ema_price
    @test r1.ema_volatility == r2.ema_volatility
    @test r1.executed_buys == r2.executed_buys
    @test r1.executed_sells == r2.executed_sells
    @test r1.suppressed_buys == r2.suppressed_buys
    @test r1.suppressed_sells == r2.suppressed_sells
    @test r1.total_cash == r2.total_cash
    @test r1.total_shares == r2.total_shares
    @test r1.edge_coordinates == r2.edge_coordinates
    @test r1.edge_k == r2.edge_k
    @test r1.final_books.cash == r2.final_books.cash
    @test r1.final_books.shares == r2.final_books.shares
    @test r1.final_books.avg_cost == r2.final_books.avg_cost
    @test sort(collect(keys(r1.frames))) == sort(collect(keys(r2.frames)))
    @test all(r1.frames[t] == r2.frames[t] for t in keys(r1.frames))

    r3 = simulate(_test_config(seed = 8); verbose = false)
    @test r3.edge_coordinates != r1.edge_coordinates || r3.prices != r1.prices
end
```

Testset 9 — replace the `edge_states` length line and extend:

```julia
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
    @test length(result.total_cash)     == T + 1
    @test length(result.total_shares)   == T + 1
    @test length(result.log_returns)    == T
    @test length(result.net_imbalance)  == T
    @test length(result.edge_buy_count)  == T
    @test length(result.edge_hold_count) == T
    @test length(result.edge_sell_count) == T
    @test length(result.executed_buys)    == T
    @test length(result.executed_sells)   == T
    @test length(result.suppressed_buys)  == T
    @test length(result.suppressed_sells) == T
    @test length(result.edge_k) == length(result.edge_coordinates)
    @test haskey(result.frames, 0) && haskey(result.frames, T)
    # the price series reconstructs exactly from the recorded log returns
    @test all(isapprox.(diff(log.(result.prices)), result.log_returns; atol = 1e-12))
    # every step's edge counts partition the edge population
    n_edge = length(result.edge_coordinates)
    @test all(result.edge_buy_count .+ result.edge_hold_count .+
              result.edge_sell_count .== n_edge)
    # crash statistics run on the full trajectory
    stats = compute_crash_statistics(result.sell_fraction)
    @test 0.0 ≤ stats.frequency ≤ 1.0
    @test stats.n_crashes == length(stats.durations)
end
```

- [ ] **Step 4: Add the new spec testsets** (spec §5, tests 3–4 and 6–11). Append at the end of `code/model-b/Test-ModelB.jl`:

```julia
# ---------------------------------------------------------------------------
# Budget constraints and heterogeneous bands (spec 2026-07-16 §5)
# ---------------------------------------------------------------------------

@testset "10. per-step accounting identity" begin
    result = simulate(_test_config(); verbose = false)
    net = result.executed_buys .- result.executed_sells
    # cash change = −(net executed volume)·fill price; fill price is the
    # standing quote prices[t], i.e. the price BEFORE the step-t update
    @test all(isapprox.(diff(result.total_cash),
                        -net .* result.prices[1:end-1]; atol = 1e-6))
    @test diff(result.total_shares) == net
end

@testset "11. infinite endowments recover unconstrained flow" begin
    config = _test_config(initial_cash = 1.0e12, initial_shares = 10^9,
                          cost_basis_rule = false)
    result = simulate(config; verbose = false)
    @test all(result.suppressed_buys .== 0)     # φ_exec ≡ φ_desired
    @test all(result.suppressed_sells .== 0)
    @test any(result.net_imbalance .!= 0.0)     # and the market is active
end

@testset "12. disposition rule suppresses at-cost sells" begin
    # All-Sell interior at P = P0 = avg_cost: with the rule on, every sell is
    # blocked (strict P > basis) → φ_exec = 0 and the price cannot fall.
    config = _test_config(initial_condition = :custom, steps = 1)  # rule on by default
    grid   = _uniform_interior_grid(16, 16, 2)
    result = simulate(config; initial_grid = grid, verbose = false)
    @test result.suppressed_sells[1] == 196
    @test result.executed_sells[1] == 0
    @test result.net_imbalance[1] == 0.0
    @test result.prices[2] == result.prices[1]
end

@testset "13. homogeneous-band limit (spread = 0)" begin
    config = _test_config(edge_band_spread = 0.0)
    result = simulate(config; verbose = false)
    n_edge = length(result.edge_coordinates)
    @test result.edge_k == fill(config.k, n_edge)
    # unanimity at every step: exactly one state holds the whole population
    @test all(max.(result.edge_buy_count, result.edge_hold_count,
                   result.edge_sell_count) .== n_edge)
end

@testset "14. band heterogeneity breaks the edge lockstep" begin
    # δ = 0.9 → k_i ∈ [0.1, 1.9]: as σ equilibrates, the price sits between
    # the tightest and widest bands at some step, splitting the population.
    # Seeded and deterministic once green; if a future parameter change
    # breaks the mixed-state assertion, retune steps/λ/seed — the property
    # under test is the plumbing (per-agent k_i in the loop), not this seed.
    config = _test_config(edge_band_spread = 0.9, steps = 100, λ = 0.05)
    result = simulate(config; verbose = false)
    n_edge = length(result.edge_coordinates)
    @test minimum(result.edge_k) < config.k < maximum(result.edge_k)
    @test any(max.(result.edge_buy_count, result.edge_hold_count,
                   result.edge_sell_count) .< n_edge)
end

@testset "15. edge agents are full market participants" begin
    # t = 1: edges are Hold, so φ = 196/(196 + n_edge) — the denominator
    # proves edges are counted in N_traders. t = 2: every edge decided Sell
    # at t = 1 (λ = 1 blows the bands) and holds shares with basis 100 far
    # below the fill price ≈ 253 → all n_edge edge sells reach the market.
    config = _test_config(initial_condition = :custom, steps = 2, λ = 1.0)
    grid   = _uniform_interior_grid(16, 16, 0)
    result = simulate(config; initial_grid = grid, verbose = false)
    n_edge = length(result.edge_coordinates)
    @test result.net_imbalance[1] ≈ 196 / (196 + n_edge)
    @test result.edge_sell_count[1] == n_edge
    @test result.executed_sells[2] ≥ n_edge
end
```

- [ ] **Step 5: Run the full test file.**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: all testsets pass, including 10–15. If testset 14's mixed-state assertion fails on this seed, adjust `steps`/`λ` per its comment until a mixed step occurs, and note the final values in the test comment.

- [ ] **Step 6: Commit.**

```bash
git add code/src/Types.jl code/src/Simulate.jl code/model-b/Test-ModelB.jl
git commit -m "Rewrite Model B closed loop with executed-order imbalance and per-agent bands"
```

---

### Task 6: Stage 1 diagnostic rerun

**Files:**
- Modify: `code/model-b/Compute-ModelB.jl` (full rewrite below)
- Output: `code/data/ModelB-Diagnostic.jld2` (gitignored), `code/figs/ModelB-Diagnostic.pdf` (committed)

**Interfaces:**
- Consumes: `simulate(::MyModelBConfiguration)` and the Task 5 result fields; plotting constants `_BUY_COLOR`, `_SELL_COLOR`, paths `_PATH_TO_DATA`, `_PATH_TO_FIGS` from `code/model-b/Include.jl`.
- Produces: the diagnostic artifacts; no code interfaces.

- [ ] **Step 1: Rewrite the driver.** Replace the entire contents of `code/model-b/Compute-ModelB.jl` with:

```julia
# Compute-ModelB.jl — Stage 1 diagnostic driver (spec 2026-07-16 §6)
#
# Runs the 32×32, 200-step closed-loop diagnostic with per-agent budget
# constraints and heterogeneous edge bands, twice: cost_basis_rule on
# (default, artifacts saved) and off (summary logged only). Saves:
#   code/data/ModelB-Diagnostic.jld2   — full trajectory + books + config
#   code/figs/ModelB-Diagnostic.pdf    — 3×2 diagnostic figure
#
# This is a diagnostic, not a paper figure — nothing is copied to paper/figs.
# Stage 2 (64×64 ensemble) comes in a later session, only after the
# constrained feedback loop is demonstrably working.

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Configuration — single source of truth (all assumptions stated explicitly)
# ---------------------------------------------------------------------------
base = (
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
    initial_cash          = 1000.0,   # 10·P0 — ~10 steps of one-sided buying
    initial_shares        = 10,
    cost_basis_rule       = true,     # disposition effect ON (default run)
    edge_band_spread      = 0.5,      # k_i ~ U(0.5, 1.5)
)
config = build(MyModelBConfiguration, base)

@info "Model B Stage 1 diagnostic: $(config.number_of_rows)×$(config.number_of_cols), " *
      "$(config.steps) steps, seed $(config.seed), cost_basis_rule = $(config.cost_basis_rule)"
result = simulate(config)

# ---------------------------------------------------------------------------
# Save the full trajectory and final books
# ---------------------------------------------------------------------------
save(joinpath(_PATH_TO_DATA, "ModelB-Diagnostic.jld2"), Dict(
    "frames"           => result.frames,
    "prices"           => result.prices,
    "log_returns"      => result.log_returns,
    "net_imbalance"    => result.net_imbalance,
    "buy_fraction"     => result.buy_fraction,
    "hold_fraction"    => result.hold_fraction,
    "sell_fraction"    => result.sell_fraction,
    "edge_buy_count"   => result.edge_buy_count,
    "edge_hold_count"  => result.edge_hold_count,
    "edge_sell_count"  => result.edge_sell_count,
    "edge_switches"    => result.edge_switches,
    "ema_price"        => result.ema_price,
    "ema_volatility"   => result.ema_volatility,
    "band_lower"       => result.band_lower,
    "band_upper"       => result.band_upper,
    "executed_buys"    => result.executed_buys,
    "executed_sells"   => result.executed_sells,
    "suppressed_buys"  => result.suppressed_buys,
    "suppressed_sells" => result.suppressed_sells,
    "total_cash"       => result.total_cash,
    "total_shares"     => result.total_shares,
    "books_cash"       => result.final_books.cash,
    "books_shares"     => result.final_books.shares,
    "books_avg_cost"   => result.final_books.avg_cost,
    "edge_coordinates" => result.edge_coordinates,
    "edge_k"           => result.edge_k,
    "config"           => Dict(String(f) => getfield(config, f)
                               for f in fieldnames(typeof(config))),
))
@info "Saved: ModelB-Diagnostic.jld2"

# ---------------------------------------------------------------------------
# 3×2 diagnostic figure (spec 2026-07-16 §6)
# ---------------------------------------------------------------------------
T      = config.steps
n_edge = length(result.edge_coordinates)

p1 = plot(0:T, result.band_lower, fillrange = result.band_upper,
          fillalpha = 0.15, lw = 0, color = :gray, label = "EMA ± kσ (nominal)")
plot!(p1, 0:T, result.ema_price, color = :gray, ls = :dash, label = "EMA")
plot!(p1, 0:T, result.prices, color = :black, lw = 1.5, label = "price")
plot!(p1, xlabel = "step", ylabel = "price", title = "Endogenous price")

p2 = plot(1:T, result.net_imbalance, color = _BUY_COLOR, legend = false,
          xlabel = "step", ylabel = "φ (executed)", title = "Executed order imbalance")
hline!(p2, [0.0], color = :gray, ls = :dot)

p3 = plot(1:T, result.edge_buy_count ./ n_edge, color = _BUY_COLOR, label = "Buy",
          xlabel = "step", ylabel = "fraction", title = "Edge-agent populations")
plot!(p3, 1:T, result.edge_hold_count ./ n_edge, color = "#888888", label = "Hold")
plot!(p3, 1:T, result.edge_sell_count ./ n_edge, color = _SELL_COLOR, label = "Sell")

p4 = plot(0:T, result.buy_fraction, color = _BUY_COLOR, label = "Buy",
          xlabel = "step", ylabel = "fraction", title = "Interior populations")
plot!(p4, 0:T, result.hold_fraction, color = "#888888", label = "Hold")
plot!(p4, 0:T, result.sell_fraction, color = _SELL_COLOR, label = "Sell")

desired  = result.executed_buys .+ result.executed_sells .+
           result.suppressed_buys .+ result.suppressed_sells
executed = result.executed_buys .+ result.executed_sells
p5 = plot(1:T, desired, color = :gray, label = "desired",
          xlabel = "step", ylabel = "orders", title = "Order volume")
plot!(p5, 1:T, executed, color = :black, label = "executed")

p6 = plot(1:T, result.suppressed_buys, color = _BUY_COLOR, label = "suppressed buys",
          xlabel = "step", ylabel = "count", title = "Suppressed orders")
plot!(p6, 1:T, result.suppressed_sells, color = _SELL_COLOR, label = "suppressed sells")

fig = plot(p1, p2, p3, p4, p5, p6, layout = (3, 2), size = (1000, 1050),
           left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Diagnostic.pdf"))
@info "Saved: ModelB-Diagnostic.pdf"

# ---------------------------------------------------------------------------
# Numerical summary — success criteria (spec 2026-07-16 §6)
# ---------------------------------------------------------------------------
function _summarize(tag::String, result)
    crash = compute_crash_statistics(result.sell_fraction)
    @info("Diagnostic summary ($(tag))",
        price_min          = minimum(result.prices),
        price_max          = maximum(result.prices),
        return_std         = std(result.log_returns),
        edge_switches      = result.edge_switches,
        final_buy          = result.buy_fraction[end],
        final_hold         = result.hold_fraction[end],
        final_sell         = result.sell_fraction[end],
        n_suppressed_buys  = sum(result.suppressed_buys),
        n_suppressed_sells = sum(result.suppressed_sells),
        total_cash_final   = result.total_cash[end],
        total_shares_final = result.total_shares[end],
        crash_frequency    = crash.frequency,
        n_crashes          = crash.n_crashes,
    )
    return nothing
end

_summarize("cost_basis_rule = true", result)

std(result.log_returns) == 0.0 &&
    @warn "Run appears INERT: every log return is zero."
result.edge_switches == 0 &&
    @warn "No edge agent ever changed state: the feedback loop may not be closing."
(sum(result.suppressed_buys) + sum(result.suppressed_sells)) == 0 &&
    @warn "Constraints never bind: endowment defaults may be too large to matter."

# ---------------------------------------------------------------------------
# Comparison run — disposition toggle OFF (summary only, no artifacts)
# ---------------------------------------------------------------------------
config_off = build(MyModelBConfiguration, merge(base, (cost_basis_rule = false,)))
@info "Comparison run: cost_basis_rule = false"
result_off = simulate(config_off; verbose = false)
_summarize("cost_basis_rule = false", result_off)

@info "Compute-ModelB.jl complete."
```

- [ ] **Step 2: Run the diagnostic.**

Run: `julia code/model-b/Compute-ModelB.jl` (from the repo root)
Expected: both `Saved:` lines, two `Diagnostic summary` blocks (true and false), and NO warnings. Success criteria (spec §6): `return_std > 0`; `price_min ≠ price_max`; `edge_switches ≥ 1`; `n_suppressed_buys + n_suppressed_sells > 0` (constraints bind); population fractions moved from their initial values. Record whether the monotone price climb from the unconstrained Stage 1 run is broken (price reverses, plateaus, or oscillates once cash exhausts, expected around steps 10–20). A still-monotone unbounded climb FAILS the run — stop and report; the endowment defaults need revisiting (spec §6).

- [ ] **Step 3: Inspect the figure.** Open `code/figs/ModelB-Diagnostic.pdf` and verify all six panels render with sensible axes: price + band, executed φ (watch for sign changes now), edge populations (fractions in [0,1] summing to 1), interior populations, desired vs. executed volume (executed ≤ desired everywhere), suppressed counts (nonzero somewhere). Report what the constrained dynamics look like vs. the unconstrained Stage 1 baseline (monotone +50% climb, φ never crossing zero, single edge switch).

- [ ] **Step 4: Verify the full test suite still passes.**

Run: `julia code/model-b/Test-ModelB.jl`
Expected: all testsets pass.

- [ ] **Step 5: Commit.**

```bash
git add code/model-b/Compute-ModelB.jl code/figs/ModelB-Diagnostic.pdf
git commit -m "Rerun Model B Stage 1 diagnostic with budget constraints and band spread"
```

---

## Spec coverage map (self-review)

| Spec section | Task |
|---|---|
| §Decisions 1–8 | encoded across Tasks 1–5 (flow semantics: Task 3/4; suppression-only: Task 4; cost-basis toggle: Tasks 1/4; edges in φ: Tasks 4/5; market maker + execute-at-quote: Task 5 loop; heterogeneous bands: Tasks 2/5) |
| §1 step order | Task 5 Step 2 |
| §2 balance sheets | Tasks 2 (struct/init) and 4 (settlement) |
| §3 configuration | Task 1 (fields), Task 2 (k_i draws stored via result.edge_k in Task 5) |
| §4 result fields | Task 5 Step 1 |
| §5 tests 1–11 | spec 1→task4+testset "execution engine"; 2→same; 3→testset 12; 4→testset 10; 5→task 4 settlement tests; 6→testset 11; 7→testset 15 (+ task 4 edge unit test); 8→testset 8; 9→testset 6; 10→testset 13; 11→testset 14 |
| §6 diagnostic | Task 6 |
| Paper implications | out of scope (spec says follow-up) |
