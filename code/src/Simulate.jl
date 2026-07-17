# Simulate.jl — Model A and Model B simulation loops

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

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
    nrows   = sim_model.number_of_rows
    ncols   = sim_model.number_of_cols
    ncolors = sim_model.number_of_colors
    radius  = sim_model.radius
    f       = sim_model.minority_fraction

    rule_major = build(MyTwoDimensionalTotalisticWolframRuleModel, (
        index  = sim_model.rule_major_index,
        colors = ncolors,
        radius = radius,
    ))

    f ≈ 0.0 && return (nothing, nothing, rule_major)

    rule_minor = build(MyTwoDimensionalTotalisticWolframRuleModel, (
        index  = sim_model.rule_minor_index,
        colors = ncolors,
        radius = radius,
    ))

    world = build(MyTwoDimensionalFixedBoundaryGridWorld, (
        width  = ncols,
        height = nrows,
    ))

    N      = nrows * ncols
    agents = Array{MySimpleTwoDimensionalAgentModel,1}(undef, N)
    for i in 1:N
        agents[i] = build(MySimpleTwoDimensionalAgentModel, world, (rule = rule_major, index = i))
    end

    n_minor = round(Int, f * N)
    visited = Set{Int64}()
    while length(visited) < n_minor
        j = rand(rng, 1:N)
        if j ∉ visited
            agents[j].rule = rule_minor
            push!(visited, j)
        end
    end

    return (world, agents, rule_major)
end

"""
    _ca_step(grid, world, agents, rule_major) → Array{Int64,2}

Apply one Wolfram CA update step.

Edge agent coordinates are set before calling this function and may be
overwritten by the CA solver; the caller resets them at the top of each
time-step loop iteration (same pattern as the course notebooks).
"""
function _ca_step(
    grid::Array{Int64,2},
    world,
    agents,
    rule_major,
)::Array{Int64,2}
    if isnothing(world)
        frames = solve(rule_major, grid, steps = 1)
        return copy(frames[1])
    else
        frames = solve(agents, world; initial = grid, steps = 1,
                       exclude = Set{Tuple{Int64,Int64}}())
        return copy(frames[1])
    end
end

"""
    _set_edge_states!(grid, edge_coords, state)

Write `state` into every edge-agent position in-place.
"""
function _set_edge_states!(
    grid::Array{Int64,2},
    edge_coords::Set{Tuple{Int64,Int64}},
    state::Int64,
)
    for (r, c) in edge_coords
        grid[r, c] = state
    end
end

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

# ---------------------------------------------------------------------------
# Model A — open simulation (real price data → edge agents)
# ---------------------------------------------------------------------------

"""
    simulate(model::MyModelASimulation, price_data; initial_grid, verbose)
        → MySimulationResult

Run the open (Model A) simulation.

Arguments
- model       : configured MyModelASimulation
- price_data  : real price series, e.g. QQQ typical prices; length T determines
                the number of simulation steps
- initial_grid: optional starting grid (default: all-Hold, state = 1)
- verbose     : show a ProgressMeter bar (default true)

Returns MySimulationResult with frames, the original price series, φₜ, and
edge state at each step.
"""
function simulate(
    model::MyModelASimulation,
    price_data::Vector{Float64};
    initial_grid::Union{Nothing, Array{Int64,2}} = nothing,
    snapshot_steps::Union{Nothing, Vector{Int64}} = nothing,
    verbose::Bool = true,
)::MySimulationResult

    nrows       = model.number_of_rows
    ncols       = model.number_of_cols
    edge_model  = model.edge_agent_model
    α           = edge_model.α
    k           = edge_model.k
    edge_coords = edge_model.coordinates
    T           = length(price_data)

    # Default snapshots: 8 log-spaced steps up to T
    snaps = isnothing(snapshot_steps) ?
        Set{Int64}(unique(round.(Int, exp.(range(log(1), log(T), length=8))))) :
        Set{Int64}(snapshot_steps)

    # Pre-compute EMA and volatility over the full price series
    μ  = compute_ema(price_data; α = α)
    σv = compute_ema_volatility(price_data, μ; α = α)

    # Initialize grid and CA machinery
    grid                        = isnothing(initial_grid) ? fill(1, nrows, ncols) : copy(initial_grid)
    world, agents, rule_major   = _build_ca_components(model)

    # Output containers
    frames       = Dict{Int64, Array{Int64,2}}()
    edge_states  = Vector{Int64}(undef, T)
    net_imbal    = Vector{Float64}(undef, T)

    prog = verbose ? Progress(T; desc = "Model A: ") : nothing

    for t in 1:T
        # --- edge agent decision ---
        estate       = compute_band_state(price_data[t], μ[t], σv[t], k)
        edge_states[t] = estate
        _set_edge_states!(grid, edge_coords, estate)

        # --- interior statistics (before CA step) ---
        net_imbal[t] = compute_net_imbalance(grid, edge_coords)

        # --- CA update ---
        grid = _ca_step(grid, world, agents, rule_major)

        # Only store frames at requested snapshot steps
        if t in snaps
            frames[t] = copy(grid)
        end

        verbose && next!(prog)
    end

    return MySimulationResult(frames, price_data, net_imbal, edge_states)
end

# ---------------------------------------------------------------------------
# Model B — closed simulation (endogenous price → edge agents → price)
# ---------------------------------------------------------------------------

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
- intervention  : optional (t, books) -> nothing hook called at the TOP of
                  step t, before orders execute at P_{t-1}. May mutate the
                  books in place (e.g. a mid-run liquidity injection). Must
                  be deterministic in (t, books) — no RNG — or the
                  same-config ⇒ identical-output contract breaks.
- verbose       : show a ProgressMeter bar (default true)

Returns MyModelBSimulationResult; see its docstring for the series-length
conventions (state-like: steps+1; transition-like: steps).
"""
function simulate(
    config::MyModelBConfiguration;
    initial_grid::Union{Nothing, Array{Int64,2}} = nothing,
    snapshot_steps::Union{Nothing, Vector{Int64}} = nothing,
    intervention::Union{Nothing, Function} = nothing,
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
        # --- optional intervention mutates the books before this step trades ---
        isnothing(intervention) || intervention(t, books)

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
