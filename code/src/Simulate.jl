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
