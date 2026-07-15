# Factory.jl — Build functions for simulation types
# Pattern: build(ModelType, data::NamedTuple) → ModelType instance

# ---------------------------------------------------------------------------
# Wolfram CA types
# ---------------------------------------------------------------------------

"""
    build(MyTwoDimensionalTotalisticWolframRuleModel, data::NamedTuple)

Required keys: index (rule number), colors (number of states), radius (= 4).
Decodes the rule index in base `colors` and builds the neighborhood → state map.
"""
function build(
    modeltype::Type{MyTwoDimensionalTotalisticWolframRuleModel},
    data::NamedTuple,
)::MyTwoDimensionalTotalisticWolframRuleModel

    index  = data.index
    levels = data.colors
    radius = data.radius

    model = modeltype()

    # Decode rule index: digit i of the base-levels representation gives the
    # next state when the config index is i.
    n_configs   = length(range(0, stop = (levels - 1), step = (1 / radius)))
    rule_digits = digits(index, base = levels, pad = n_configs)
    rule        = Dict{Int64,Int64}(i => rule_digits[i + 1] for i in 0:n_configs - 1)

    # Map rounded neighborhood mean → config index
    Q      = Dict{Float64,Int64}()
    values = range(0.0, stop = (levels - 1), step = (1 / radius))
    for (i, v) in enumerate(values)
        Q[round(v, digits = 2)] = i - 1
    end

    model.index                = index
    model.radius               = radius
    model.number_of_colors     = levels
    model.rule                 = rule
    model.neighborhoodstatesmap = Q
    model.weights              = fill(1.0 / radius, radius)
    return model
end

"""
    build(MyTwoDimensionalFixedBoundaryGridWorld, data::NamedTuple)

Required keys: width, height.
"""
function build(
    modeltype::Type{MyTwoDimensionalFixedBoundaryGridWorld},
    data::NamedTuple,
)::MyTwoDimensionalFixedBoundaryGridWorld

    model  = modeltype()
    width  = data.width
    height = data.height

    states      = Dict{Int64, Tuple{Int64,Int64}}()
    coordinates = Dict{Tuple{Int64,Int64}, Int64}()
    idx = 1
    for r in 1:height, c in 1:width
        states[idx]      = (r, c)
        coordinates[(r,c)] = idx
        idx += 1
    end

    model.width       = width
    model.height      = height
    model.states      = states
    model.coordinates = coordinates
    return model
end

"""
    build(MySimpleTwoDimensionalAgentModel, world, data::NamedTuple)

Required keys: index (linear position), rule (MyTwoDimensionalTotalisticWolframRuleModel).
Connections are ordered [left, right, up, down]; -1 indicates a boundary neighbor.
"""
function build(
    modeltype::Type{MySimpleTwoDimensionalAgentModel},
    world::MyTwoDimensionalFixedBoundaryGridWorld,
    data::NamedTuple,
)::MySimpleTwoDimensionalAgentModel

    model  = modeltype()
    index  = data.index
    rule   = data.rule
    radius = rule.radius   # must be 4 for Von Neumann

    pos   = world.states[index]
    moves = [(0, -1), (0, 1), (-1, 0), (1, 0)]   # left, right, up, down

    connections = Vector{Int64}(undef, radius)
    for (i, Δ) in enumerate(moves[1:radius])
        newpos         = pos .+ Δ
        connections[i] = get(world.coordinates, newpos, -1)
    end

    model.index       = index
    model.rule        = rule
    model.connections = connections
    return model
end

# ---------------------------------------------------------------------------
# Edge agent model
# ---------------------------------------------------------------------------

"""
    build(MyBandEdgeAgentModel, data::NamedTuple) → MyBandEdgeAgentModel

Required keys: α, k
Optional: coordinates (Set{Tuple{Int64,Int64}}) — if absent, the default 3-point
edge configuration is generated from number_of_rows and number_of_cols.

Default edge positions (3-point):
    (1, mid)       top-middle
    (nrows, mid)   bottom-middle
    (mid, 1)       left-middle
"""
function build(modeltype::Type{MyBandEdgeAgentModel}, data::NamedTuple)::MyBandEdgeAgentModel
    model = modeltype()
    model.α = data.α
    model.k = data.k

    if haskey(data, :coordinates)
        model.coordinates = data.coordinates
    else
        nrows   = data.number_of_rows
        ncols   = data.number_of_cols
        mid_row = div(nrows, 2)
        mid_col = div(ncols, 2)
        model.coordinates = Set{Tuple{Int64,Int64}}([
            (1,       mid_col),   # top middle
            (nrows,   mid_col),   # bottom middle
            (mid_row, 1),         # left middle
        ])
    end

    return model
end

# ---------------------------------------------------------------------------
# Price model
# ---------------------------------------------------------------------------

"""
    build(MyEndogenousPriceModel, data::NamedTuple) → MyEndogenousPriceModel

Required keys: λ (price impact), P0 (initial price)
"""
function build(modeltype::Type{MyEndogenousPriceModel}, data::NamedTuple)::MyEndogenousPriceModel
    model = modeltype()
    model.λ  = data.λ
    model.P0 = data.P0
    return model
end

# ---------------------------------------------------------------------------
# Simulation models
# ---------------------------------------------------------------------------

"""
    build(MyModelASimulation, data::NamedTuple) → MyModelASimulation

Required keys: number_of_rows, number_of_cols, rule_major_index, edge_agent_model
Optional keys (with defaults):
    number_of_colors    → 3
    radius              → 4
    rule_minor_index    → 19286
    minority_fraction   → 0.0   (homogeneous)
"""
function build(modeltype::Type{MyModelASimulation}, data::NamedTuple)::MyModelASimulation
    model = modeltype()
    model.number_of_rows    = data.number_of_rows
    model.number_of_cols    = data.number_of_cols
    model.number_of_colors  = get(data, :number_of_colors, 3)
    model.radius            = get(data, :radius, 4)
    model.rule_major_index  = data.rule_major_index
    model.rule_minor_index  = get(data, :rule_minor_index, 19286)
    model.minority_fraction = get(data, :minority_fraction, 0.0)
    model.edge_agent_model  = data.edge_agent_model
    return model
end

"""
    build(MyModelBSimulation, data::NamedTuple) → MyModelBSimulation

Required keys: number_of_rows, number_of_cols, rule_major_index,
               edge_agent_model, price_model
Optional keys: same as MyModelASimulation
"""
function build(modeltype::Type{MyModelBSimulation}, data::NamedTuple)::MyModelBSimulation
    model = modeltype()
    model.number_of_rows    = data.number_of_rows
    model.number_of_cols    = data.number_of_cols
    model.number_of_colors  = get(data, :number_of_colors, 3)
    model.radius            = get(data, :radius, 4)
    model.rule_major_index  = data.rule_major_index
    model.rule_minor_index  = get(data, :rule_minor_index, 19286)
    model.minority_fraction = get(data, :minority_fraction, 0.0)
    model.edge_agent_model  = data.edge_agent_model
    model.price_model       = data.price_model
    return model
end

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
