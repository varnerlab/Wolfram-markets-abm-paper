# Following.jl — external advice and observations of another trader's orders.
using SHA

Base.@kwdef struct FollowingProtocol
    mode::Symbol = :none
    adoption::Float64 = 0.0
    sources::Int = 1
    independent::Bool = false
    replicate::Int = 1
    pre::Int = 1000
    stop_after::Int = typemax(Int)
    persistence::Float64 = 0.8
    lag::Int = 1
    staggered::Bool = false
    reverse_advice::Bool = false
    leader_selection::Symbol = :random
    pool_size::Int = 16
end

struct FollowingPopulation
    interior::Vector{Int}
    leaders::Vector{Int}
    followers::Vector{Int}
    others::Vector{Int}
    source_of::Vector{Int}
    weights::Vector{Float64}
end

"""Stable random namespaces, independent of the simulator's initialization RNG."""
function following_seed(seed::Integer, replicate::Integer, namespace::Integer, key::Integer=0)
    all(>=(0), (seed, replicate, namespace, key)) ||
        throw(ArgumentError("following random keys must be nonnegative"))
    x = _splitmix64(UInt64(seed))
    for value in (replicate, namespace, key)
        x = _splitmix64(x ⊻ UInt64(value))
    end
    x
end

function following_population(config, p::FollowingProtocol)
    p.mode in (:none, :advice, :copy_filled, :copy_desired, :replay_filled, :replay_desired) ||
        throw(ArgumentError("unknown following mode: $(p.mode)"))
    0 <= p.adoption <= 1 || throw(ArgumentError("adoption must lie in [0,1]"))
    0 <= p.persistence <= 1 || throw(ArgumentError("persistence must lie in [0,1]"))
    0 <= p.pre < config.steps || throw(ArgumentError("warm-up must precede endpoint"))
    p.stop_after >= 0 || throw(ArgumentError("stop_after must be nonnegative"))
    p.lag >= 1 || throw(ArgumentError("copying requires a positive lag"))
    p.replicate >= 0 || throw(ArgumentError("replicate must be nonnegative"))
    p.leader_selection in (:random, :winners) || throw(ArgumentError("unknown leader selection"))
    p.independent && p.mode != :advice && throw(ArgumentError("independent streams require advice"))
    linear = LinearIndices((config.number_of_rows, config.number_of_cols))
    ids = [linear[r,c] for c in 2:config.number_of_cols-1 for r in 2:config.number_of_rows-1]
    1 <= p.pool_size <= length(ids) || throw(ArgumentError("invalid leader pool size"))
    leaders = ids[randperm(Xoshiro(following_seed(config.seed, p.replicate, 1)), length(ids))[1:p.pool_size]]
    candidates = setdiff(ids, leaders)
    permutation = randperm(Xoshiro(following_seed(config.seed, p.replicate, 2)), length(candidates))
    # Julia's RoundNearest convention rounds exact half-integers to even.
    M = round(Int, p.adoption * length(ids), RoundNearest)
    M <= length(candidates) || throw(ArgumentError("adoption leaves no reserved leader pool"))
    followers = candidates[permutation[1:M]]
    K = p.independent ? M : p.sources
    K >= 1 || (M == 0 && p.independent) || throw(ArgumentError("sources must be positive"))
    !p.independent && K > p.pool_size && throw(ArgumentError("sources exceed the reserved pool"))
    M > 0 && K > M && throw(ArgumentError("more sources than followers"))
    assignment = M == 0 ? Int[] : [mod1(j, K) for j in 1:M]
    weights = M == 0 ? Float64[] : [count(==(k), assignment)/M for k in 1:K]
    FollowingPopulation(ids, leaders, followers, setdiff(candidates, followers), assignment, weights)
end

const FOLLOWING_TRAJECTORY_COLUMNS = (
    :buy_fraction, :sell_fraction, :follower_buy_fraction, :follower_sell_fraction,
    :nonfollower_sell_fraction, :source_active_fraction, :source_agreement,
    :source_active_agreement, :price,
)

mutable struct FollowingObserver <: AbstractMarketObserver
    protocol::FollowingProtocol
    population::FollowingPopulation
    trace::MyOrderTrace
    config::MyModelBConfiguration
    trader_ids::Vector{Int}
    follower_mask::BitVector
    source_rngs::Vector{Xoshiro}
    source_states::Vector{Int8}
    selected_leaders::Vector{Int}
    delays::Vector{Int}
    desired_history::Matrix{Int8}
    filled_history::Matrix{Int8}
    replay::Union{Nothing,Matrix{Int8}}
    masked_states::Union{Nothing,Matrix{UInt8}}
    desired_tape::Union{Nothing,Matrix{Int8}}
    filled_tape::Union{Nothing,Matrix{Int8}}
    state_tape::Union{Nothing,Matrix{UInt8}}
    start_value::Vector{Float64}
    rank_value::Vector{Float64}
    peak_value::Vector{Float64}
    max_drawdown::Vector{Float64}
    final_value::Vector{Float64}
    order_counts::Matrix{Int}
    buy_steps::Vector{Int}
    sell_steps::Vector{Int}
    trajectory::Matrix{Float64}
    start_fingerprint::String
    last_step::Int
    initialized::Bool
end

_draw_advice(rng) = (u = rand(rng); Int8(u < 0.25 ? 1 : u < 0.75 ? 0 : -1))

function FollowingObserver(config, p::FollowingProtocol; replay=nothing,
                           masked_states=nothing, record_tapes=false, record_states=false)
    pop = following_population(config, p)
    n = config.number_of_rows * config.number_of_cols
    K = p.independent ? length(pop.followers) : p.sources
    # Private streams stay attached to identities when the adoption fraction changes.
    keys = p.independent ? pop.followers : collect(1:K)
    rngs = [Xoshiro(following_seed(config.seed, p.replicate,
                                 p.independent ? 4 : 3, k)) for k in keys]
    states = [_draw_advice(rng) for rng in rngs]
    delays = p.staggered ? [1 + mod(j-1, p.lag) for j in eachindex(pop.followers)] :
                          fill(p.lag, length(pop.followers))
    p.mode in (:replay_filled, :replay_desired) && isnothing(replay) &&
        throw(ArgumentError("replay mode requires a tape"))
    if !isnothing(replay)
        size(replay) == (p.pool_size, config.steps) ||
            throw(DimensionMismatch("replay tape must have pool_size rows and steps columns"))
        all(x -> x in (-1,0,1), replay) || throw(ArgumentError("invalid replay event"))
    end
    !isnothing(masked_states) && size(masked_states) != (n, config.steps) &&
        throw(DimensionMismatch("masked states must cover the full grid and every step"))
    !isnothing(masked_states) && !(p.mode in (:advice, :replay_filled, :replay_desired, :none)) &&
        throw(ArgumentError("transmission masking requires fixed sources"))
    mask = falses(n); mask[pop.followers] .= true
    FollowingObserver(p, pop, MyOrderTrace(config.number_of_rows, config.number_of_cols),
        config, Int[], mask, rngs, states, collect(1:min(K,p.pool_size)), delays,
        zeros(Int8,p.pool_size,p.lag), zeros(Int8,p.pool_size,p.lag), replay, masked_states,
        record_tapes ? zeros(Int8,p.pool_size,config.steps) : nothing,
        record_tapes ? zeros(Int8,p.pool_size,config.steps) : nothing,
        record_states ? zeros(UInt8,n,config.steps) : nothing,
        zeros(n), zeros(n), zeros(n), zeros(n), zeros(n), zeros(Int,n,6),
        zeros(Int,n), zeros(Int,n), fill(NaN, config.steps, length(FOLLOWING_TRAJECTORY_COLUMNS)),
        "", 0, false)
end

market_trace(o::FollowingObserver) = o.trace

function market_initialize!(o::FollowingObserver, config, grid, books, edges, dealer)
    o.initialized && throw(ArgumentError("use a fresh observer for each simulation"))
    config === o.config || throw(ArgumentError("observer belongs to a different configuration"))
    linear = LinearIndices(grid)
    o.trader_ids = vcat(o.population.interior, [linear[r,c] for (r,c) in edges])
    o.initialized = true
end

function following_fingerprint(grid, books, price, mu, sigma, dealer)
    io = IOBuffer()
    for x in (grid, books.cash, books.shares, books.avg_cost,
              [price, mu, sigma, dealer.cash, Float64(dealer.inventory)])
        write(io, x)
    end
    bytes2hex(sha256(take!(io)))
end

@inline following_active(p, t) = p.mode != :none && t > p.pre && t-p.pre <= p.stop_after

function market_before_step!(o::FollowingObserver, t, grid, books, price, mu, sigma, dealer)
    t == o.last_step + 1 || error("observer steps must be consecutive")
    p, pop = o.protocol, o.population
    if t == max(1, p.pre-499)
        @inbounds for id in o.trader_ids
            o.rank_value[id] = books.cash[id] + books.shares[id]*price
        end
    end
    if t == p.pre + 1
        o.start_fingerprint = following_fingerprint(grid, books, price, mu, sigma, dealer)
        @inbounds for id in o.trader_ids
            value = books.cash[id] + books.shares[id]*price
            o.start_value[id] = value; o.peak_value[id] = value
        end
        if p.leader_selection == :winners
            scores = [o.rank_value[id] > 0 ? o.start_value[id]/o.rank_value[id]-1 : -Inf
                      for id in pop.leaders]
            # The pool order was randomized before outcomes existed; it breaks ties.
            o.selected_leaders = sortperm(scores; rev=true, alg=MergeSort)[1:p.sources]
        end
    end
    if following_active(p,t) && !isempty(pop.followers)
        if p.mode == :advice
            if t > p.pre+1
                @inbounds for k in eachindex(o.source_states)
                    rand(o.source_rngs[k]) >= p.persistence &&
                        (o.source_states[k] = _draw_advice(o.source_rngs[k]))
                end
            end
            @inbounds for (j,id) in enumerate(pop.followers)
                event = o.source_states[pop.source_of[j]]
                grid[id] = 1 - (p.reverse_advice ? -event : event)
            end
        else
            @inbounds for (j,id) in enumerate(pop.followers)
                source = o.selected_leaders[pop.source_of[j]]
                observed_step = t - o.delays[j]
                event = Int8(0)
                if observed_step >= 1
                    if !isnothing(o.replay)
                        event = o.replay[source, observed_step]
                    else
                        history = p.mode == :copy_filled ? o.filled_history : o.desired_history
                        event = history[source, mod1(observed_step,p.lag)]
                    end
                end
                grid[id] = 1-event
            end
        end
    end
    if !isnothing(o.state_tape)
        @inbounds for id in eachindex(grid)
            o.state_tape[id,t] = grid[id]
        end
    end
end

function market_ca_step(o::FollowingObserver, t, grid, world, agents, major)
    next = _ca_step(grid,world,agents,major)
    if !isnothing(o.masked_states) && following_active(o.protocol,t)
        isnothing(world) || throw(ArgumentError("masked following requires the homogeneous baseline"))
        nr,nc = size(grid)
        @inbounds for c in 2:nc-1, r in 2:nr-1
            id = r+(c-1)*nr
            o.follower_mask[id] && continue
            s = 0
            for neighbor in (id-1,id+1,id-nr,id+nr)
                s += o.follower_mask[neighbor] ? o.masked_states[neighbor,t] : grid[neighbor]
            end
            next[id] = major.rule[s]
        end
    end
    next
end
