# Types.jl — Abstract and concrete types for the Wolfram Market ABM
# All agent states: 0 = Buy (green), 1 = Hold (gray), 2 = Sell (red)

# ---------------------------------------------------------------------------
# Abstract type hierarchy
# ---------------------------------------------------------------------------
abstract type AbstractSimulationModel end
abstract type AbstractPriceModel end
abstract type AbstractEdgeAgentModel end
abstract type AbstractWorldModel end
abstract type AbstractPolicyModel end
abstract type AbstractAgentModel end

# ---------------------------------------------------------------------------
# Wolfram CA types (self-contained, no external package dependency)
# ---------------------------------------------------------------------------

"""
    MyTwoDimensionalTotalisticWolframRuleModel <: AbstractPolicyModel

2D totalistic Wolfram CA rule for a 3-state (buy/hold/sell) grid.

The neighborhood sum c = mean(4 cardinal neighbors) is looked up in
`neighborhoodstatesmap` to get a config index, which maps via `rule`
to the agent's next state.
"""
mutable struct MyTwoDimensionalTotalisticWolframRuleModel <: AbstractPolicyModel
    index::Int64
    radius::Int64
    number_of_colors::Int64
    neighborhoodstatesmap::Dict{Float64, Int64}   # rounded mean → config index
    rule::Dict{Int64, Int64}                       # config index → next state
    weights::Vector{Float64}                       # uniform: 1/radius each
    MyTwoDimensionalTotalisticWolframRuleModel() = new()
end

"""
    MyTwoDimensionalFixedBoundaryGridWorld <: AbstractWorldModel

Fixed-boundary rectangular grid. Stores bidirectional maps between
linear indices and (row, col) coordinates.
"""
mutable struct MyTwoDimensionalFixedBoundaryGridWorld <: AbstractWorldModel
    states::Dict{Int64, Tuple{Int64,Int64}}        # linear index → (row, col)
    coordinates::Dict{Tuple{Int64,Int64}, Int64}   # (row, col) → linear index
    width::Int64
    height::Int64
    MyTwoDimensionalFixedBoundaryGridWorld() = new()
end

"""
    MySimpleTwoDimensionalAgentModel <: AbstractAgentModel

Single CA agent. Holds its grid index, assigned rule, and the linear
indices of its 4 cardinal neighbors (-1 for out-of-bounds).
"""
mutable struct MySimpleTwoDimensionalAgentModel <: AbstractAgentModel
    index::Int64
    rule::MyTwoDimensionalTotalisticWolframRuleModel
    connections::Vector{Int64}   # [left, right, up, down]; -1 = boundary
    MySimpleTwoDimensionalAgentModel() = new()
end

# ---------------------------------------------------------------------------
# Edge agent model
# ---------------------------------------------------------------------------

"""
    MyBandEdgeAgentModel <: AbstractEdgeAgentModel

Edge agent that classifies price relative to an EMA ± k·σ band.

    state = 0 (Buy)  if  P < μ - k·σ
    state = 1 (Hold) if  μ - k·σ ≤ P ≤ μ + k·σ
    state = 2 (Sell) if  P > μ + k·σ

Used by both Model A (real price input) and Model B (endogenous price input);
the only difference is which price series is passed in.
"""
mutable struct MyBandEdgeAgentModel <: AbstractEdgeAgentModel
    α::Float64                              # EMA learning rate (e.g., 1/60)
    k::Float64                              # band half-width in units of σ
    coordinates::Set{Tuple{Int64,Int64}}    # (row, col) positions on grid
    MyBandEdgeAgentModel() = new()
end

# ---------------------------------------------------------------------------
# Price model (Model B only)
# ---------------------------------------------------------------------------

"""
    MyEndogenousPriceModel <: AbstractPriceModel

Exponential price impact model driven by net order imbalance:

    Pₜ = Pₜ₋₁ · exp(λ · φₜ)

where φₜ = (N_buy - N_sell) / N is the net order imbalance fraction.
"""
mutable struct MyEndogenousPriceModel <: AbstractPriceModel
    λ::Float64      # price impact parameter
    P0::Float64     # initial price
    MyEndogenousPriceModel() = new()
end

# ---------------------------------------------------------------------------
# Simulation models
# ---------------------------------------------------------------------------

"""
    MyModelASimulation <: AbstractSimulationModel

Open model: edge agents observe an external (real) price series.
Interior agents follow Wolfram totalistic CA rules.
Supports both homogeneous (minority_fraction = 0) and heterogeneous grids.
"""
mutable struct MyModelASimulation <: AbstractSimulationModel
    number_of_rows::Int64
    number_of_cols::Int64
    number_of_colors::Int64         # = 3 (buy / hold / sell)
    radius::Int64                   # = 4 (Von Neumann neighbors)
    rule_major_index::Int64         # e.g., 6158 (homogeneous) or 19280 (crash)
    rule_minor_index::Int64         # e.g., 19286 (contrarian minority, crash model)
    minority_fraction::Float64      # fraction of agents using rule_minor (0 = homogeneous)
    edge_agent_model::MyBandEdgeAgentModel
    MyModelASimulation() = new()
end

"""
    MyModelBSimulation <: AbstractSimulationModel

Closed model: price is generated endogenously from net order imbalance.
Edge agents apply a Bollinger Band rule to the endogenous price.
Everything else is identical to MyModelASimulation.
"""
mutable struct MyModelBSimulation <: AbstractSimulationModel
    number_of_rows::Int64
    number_of_cols::Int64
    number_of_colors::Int64
    radius::Int64
    rule_major_index::Int64
    rule_minor_index::Int64
    minority_fraction::Float64
    edge_agent_model::MyBandEdgeAgentModel
    price_model::MyEndogenousPriceModel
    MyModelBSimulation() = new()
end

# ---------------------------------------------------------------------------
# Simulation result
# ---------------------------------------------------------------------------

"""
    MySimulationResult

Immutable container for all outputs of a model run.

Fields
- frames        : Dict mapping time step → grid state array
- prices        : price series (real QQQ for Model A; endogenous for Model B)
- net_imbalance : φₜ = (N_buy - N_sell) / N at each step (interior agents only)
- edge_states   : edge agent classification at each step (0/1/2)
"""
struct MySimulationResult
    frames::Dict{Int64, Array{Int64,2}}
    prices::Vector{Float64}
    net_imbalance::Vector{Float64}
    edge_states::Vector{Int64}
end

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
