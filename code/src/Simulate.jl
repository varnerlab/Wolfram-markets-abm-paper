# Simulate.jl — Model A and Model B simulation loops

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

"""
    _build_ca_components(sim_model) → (world, agents, rule_major)

Build the CA machinery needed for a simulation run.

- Homogeneous case (minority_fraction ≈ 0): returns (nothing, nothing, rule_major).
  The fast path `solve(rule_major, grid, steps=1)` is used.

- Heterogeneous case: builds MyTwoDimensionalFixedBoundaryGridWorld, assigns
  rule_major to (1 - f) of agents and rule_minor to the remaining f, placed
  uniformly at random.
"""
function _build_ca_components(sim_model::AbstractSimulationModel)
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
        j = rand(1:N)
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
    verbose::Bool = true,
)::MySimulationResult

    nrows       = model.number_of_rows
    ncols       = model.number_of_cols
    edge_model  = model.edge_agent_model
    α           = edge_model.α
    k           = edge_model.k
    edge_coords = edge_model.coordinates
    T           = length(price_data)

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
        grid      = _ca_step(grid, world, agents, rule_major)
        frames[t] = copy(grid)

        verbose && next!(prog)
    end

    return MySimulationResult(frames, price_data, net_imbal, edge_states)
end

# ---------------------------------------------------------------------------
# Model B — closed simulation (endogenous price → edge agents → price)
# ---------------------------------------------------------------------------

"""
    simulate(model::MyModelBSimulation; initial_grid, steps, verbose)
        → MySimulationResult

Run the closed-loop (Model B) simulation.

The price Pₜ is generated endogenously:

    φₜ   = (N_buy,t - N_sell,t) / N          net order imbalance (interior only)
    Pₜ₊₁ = Pₜ · exp(λ · φₜ)                  exponential price impact
    eₜ₊₁ = BollingerBand(Pₜ₊₁, μₜ₊₁, σₜ₊₁, k)  edge state for next step

Arguments
- model        : configured MyModelBSimulation
- initial_grid : optional starting grid (default: all-Hold)
- steps        : number of time steps (default 1000)
- verbose      : show a ProgressMeter bar (default true)

Returns MySimulationResult. prices has length steps+1 (includes P0).
"""
function simulate(
    model::MyModelBSimulation;
    initial_grid::Union{Nothing, Array{Int64,2}} = nothing,
    steps::Int64 = 1000,
    verbose::Bool = true,
)::MySimulationResult

    nrows       = model.number_of_rows
    ncols       = model.number_of_cols
    edge_model  = model.edge_agent_model
    price_model = model.price_model
    α           = edge_model.α
    k           = edge_model.k
    edge_coords = edge_model.coordinates
    λ           = price_model.λ
    P0          = price_model.P0

    # Initialize grid and CA machinery
    grid                        = isnothing(initial_grid) ? fill(1, nrows, ncols) : copy(initial_grid)
    world, agents, rule_major   = _build_ca_components(model)

    # Output containers
    frames      = Dict{Int64, Array{Int64,2}}()
    prices      = Vector{Float64}(undef, steps + 1)
    edge_states = Vector{Int64}(undef, steps)
    net_imbal   = Vector{Float64}(undef, steps)

    prices[1] = P0

    # Online EMA state (updated each step from endogenous price)
    μ_t = P0
    σ_t = 0.0

    prog = verbose ? Progress(steps; desc = "Model B: ") : nothing

    for t in 1:steps
        P_t = prices[t]

        # --- update EMA and volatility from current price ---
        μ_t = μ_t + α * (P_t - μ_t)
        σ_t = σ_t + α * (abs(P_t - μ_t) - σ_t)

        # --- edge agent decision ---
        estate         = compute_band_state(P_t, μ_t, σ_t, k)
        edge_states[t] = estate
        _set_edge_states!(grid, edge_coords, estate)

        # --- net order imbalance (interior agents only) ---
        φ             = compute_net_imbalance(grid, edge_coords)
        net_imbal[t]  = φ

        # --- price update ---
        prices[t + 1] = compute_price_update(P_t, φ, λ)

        # --- CA update ---
        grid      = _ca_step(grid, world, agents, rule_major)
        frames[t] = copy(grid)

        verbose && next!(prog)
    end

    return MySimulationResult(frames, prices, net_imbal, edge_states)
end
