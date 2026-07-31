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

@testset "session-aware log returns exclude overnight joins" begin
    prices   = [100.0, 101.0, 200.0, 202.0]
    sessions = ["day1", "day1", "day2", "day2"]
    returns  = compute_session_log_returns(prices, sessions)
    @test returns ≈ [log(101 / 100), log(202 / 200)]
    @test length(returns) == 2
    @test compute_session_log_returns([100.0], ["day1"]) == Float64[]
    @test_throws DimensionMismatch compute_session_log_returns(prices, sessions[1:3])
end

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
    # budget-constraint fields (spec 2026-07-16 §3)
    @test config.initial_cash == 1000.0
    @test config.initial_shares == 10
    @test config.cost_basis_rule == true
    @test config.edge_band_spread == 0.5

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
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, initial_cash = -1.0))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, initial_shares = -1))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, edge_band_spread = 1.0))
    @test_throws ArgumentError build(MyModelBConfiguration,
        (number_of_rows = 32, number_of_cols = 32, edge_band_spread = -0.1))
end

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

    # rounding overflow guard: valid config whose rounded counts exceed N_interior
    tiny = build(MyModelBConfiguration, (number_of_rows = 5, number_of_cols = 3,
        initial_buy_fraction = 0.5, initial_sell_fraction = 0.5))
    @test_throws ArgumentError build_initial_grid(tiny, Xoshiro(1))
end

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

# ---------------------------------------------------------------------------
# Closed-loop simulate (Simulate.jl) — model-B-plan.md §6 properties
# ---------------------------------------------------------------------------

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

@testset "2. negative interior imbalance lowers the price" begin
    config = _test_config(initial_condition = :custom, steps = 1,
                          cost_basis_rule = false)
    grid   = _uniform_interior_grid(16, 16, 2)            # all-Sell interior
    result = simulate(config; initial_grid = grid, verbose = false)
    n_edge = length(result.edge_coordinates)
    @test result.net_imbalance[1] ≈ -196 / (196 + n_edge)
    @test result.prices[2] < result.prices[1]
end

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

# ---------------------------------------------------------------------------
# Stage 2 run metrics and regime classification (spec 2026-07-16 stage2)
# ---------------------------------------------------------------------------

@testset "16. drawdown and sign-crossing arithmetic" begin
    @test compute_max_drawdown([100.0, 110.0, 99.0, 121.0, 110.0]) ≈ 0.1
    @test compute_max_drawdown([100.0, 101.0, 102.0]) == 0.0
    @test compute_max_drawdown([100.0]) == 0.0
    # zeros never count; sign must actually flip between nonzero values
    @test compute_sign_crossings([0.1, -0.2, 0.0, -0.1, 0.3]) == 2
    @test compute_sign_crossings([0.0, 0.0]) == 0
    @test compute_sign_crossings([1.0, 1.0, -1.0, 1.0]) == 2
    @test compute_sign_crossings(Float64[]) == 0
end

@testset "17. run metrics on simulated runs" begin
    # degenerate conventions on the all-Hold null control
    null = simulate(_test_config(initial_condition = :all_hold); verbose = false)
    m0 = compute_run_metrics(null)
    @test m0.return_std == 0.0
    @test isnan(m0.return_kurtosis) && isnan(m0.volclust_ac1)
    @test m0.n_crashes == 0 && m0.crash_frequency == 0.0
    @test m0.crash_mean_duration == 0.0 && m0.crash_max_duration == 0
    @test m0.max_drawdown == 0.0
    @test m0.phi_zero_crossings == 0
    @test m0.edge_switches == 0
    @test m0.suppressed_buy_fraction == 0.0 && m0.suppressed_sell_fraction == 0.0
    @test m0.final_total_cash == null.total_cash[1]
    @test m0.final_total_shares == null.total_shares[1]

    # finite fields on a live run
    live = simulate(_test_config(); verbose = false)
    m1 = compute_run_metrics(live)
    @test m1.return_std > 0.0
    @test !isnan(m1.return_kurtosis) && !isnan(m1.volclust_ac1)
    @test m1.price_min ≤ m1.price_max
    @test 0.0 ≤ m1.suppressed_buy_fraction ≤ 1.0
    @test 0.0 ≤ m1.suppressed_sell_fraction ≤ 1.0
    @test m1.edge_switches == live.edge_switches
end

@testset "18. regime classifier decision order" begin
    base = (return_std = 1.0e-3, crash_frequency = 0.0, phi_zero_crossings = 0,
            price_min = 100.0, price_max = 101.0)
    @test classify_regime(merge(base, (return_std = 0.0,)), 100.0) == :inert
    # crash-prone outranks oscillatory even when both criteria hold
    @test classify_regime(merge(base, (crash_frequency = 0.05,
        phi_zero_crossings = 100)), 100.0) == :crash_prone
    @test classify_regime(merge(base, (phi_zero_crossings = 25,)), 100.0) == :oscillatory
    @test classify_regime(base, 100.0) == :plateau            # 1% range < 10%
    @test classify_regime(merge(base, (price_max = 150.0,)), 100.0) == :drift
    # thresholds are inclusive (≥) for crash frequency and crossings
    @test classify_regime(merge(base, (crash_frequency = 0.01,)), 100.0) == :crash_prone
    @test classify_regime(merge(base, (phi_zero_crossings = 20,)), 100.0) == :oscillatory
end
