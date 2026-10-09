# A separate observation layer: settlement and stored intentions keep their
# original meanings. The observer reads holdings only after settlement.
const HISTORY_NAMES = [:raw_input_sell, :unbacked_input_sell, :visible_input_sell,
    :raw_output_sell, :interior_sales, :interior_buys, :interior_suppressed_sales,
    :interior_desired_sales, :edge_sales, :quoted_price]

mutable struct VisibilityObserver <: AbstractMarketObserver
    mode::Symbol
    start::Int
    trace::MyOrderTrace
    books::Union{Nothing,MyAgentBooks}
    visible::Matrix{Int64}
    history::Matrix{Float64}
    pre_state_sha256::String
    first_execution_sha256::String
    minimum_cash::Float64
    minimum_shares::Int64
end

function VisibilityObserver(L, steps; mode=:original, start=1001)
    mode in (:original, :inventory) || throw(ArgumentError("unknown observation mode"))
    start >= 1 || throw(ArgumentError("observation start must be positive"))
    VisibilityObserver(mode, start, MyOrderTrace(L, L), nothing, zeros(Int64, L, L),
        zeros(steps, length(HISTORY_NAMES)), "", "", Inf, typemax(Int64))
end

array_digest(x) = bytes2hex(sha256(reinterpret(UInt8, vec(x))))

function state_digest(grid, books, price, mu, sigma, dealer)
    io = IOBuffer()
    for x in (grid, books.cash, books.shares, books.avg_cost)
        write(io, reinterpret(UInt8, vec(x)))
    end
    for x in (price, mu, sigma, dealer.cash, dealer.inventory)
        write(io, x)
    end
    bytes2hex(sha256(take!(io)))
end

function visible_signals!(visible, grid, shares, mask)
    copyto!(visible, grid)
    if mask
        @inbounds for i in eachindex(grid)
            grid[i] == 2 && shares[i] == 0 && (visible[i] = 1)
        end
    end
    visible
end

market_trace(o::VisibilityObserver) = o.trace
function market_initialize!(o::VisibilityObserver, config, grid, books, edges, dealer)
    o.books = books
end
function market_before_step!(o::VisibilityObserver, t, grid, books, price, mu, sigma, dealer)
    if t == o.start
        o.pre_state_sha256 = state_digest(grid, books, price, mu, sigma, dealer)
    end
end
function market_after_execution!(o::VisibilityObserver, t, grid, books, price, counts, dealer)
    o.minimum_cash = min(o.minimum_cash, minimum(books.cash))
    o.minimum_shares = min(o.minimum_shares, minimum(books.shares))
    if t == o.start
        # Bands have not yet updated; constants omit them from this second check.
        o.first_execution_sha256 = state_digest(grid, books, price, 0.0, 0.0, dealer)
    end
    sales = buys = suppressed = desired = 0
    @inbounds for c in 2:size(grid, 2)-1, r in 2:size(grid, 1)-1
        sales += o.trace.filled[r,c] == -1
        buys += o.trace.filled[r,c] == 1
        desired += o.trace.desired[r,c] == -1
        suppressed += o.trace.desired[r,c] == -1 && o.trace.eligible[r,c] != -1
    end
    o.history[t, 5:10] = [sales, buys, suppressed, desired, counts.executed_sells - sales, price]
end
function market_ca_step(o::VisibilityObserver, t, grid, world, agents, major)
    mask = o.mode == :inventory && t >= o.start
    visible_signals!(o.visible, grid, o.books.shares, mask)
    raw = unbacked = observed = 0
    n = (size(grid, 1) - 2) * (size(grid, 2) - 2)
    @inbounds for c in 2:size(grid, 2)-1, r in 2:size(grid, 1)-1
        raw += grid[r,c] == 2
        unbacked += grid[r,c] == 2 && o.books.shares[r,c] == 0
        observed += o.visible[r,c] == 2
    end
    next = _ca_step(o.visible, world, agents, major)
    # _ca_step copies its input edges, so restore the actual technical intentions.
    next[1,:] = grid[1,:]; next[end,:] = grid[end,:]
    next[:,1] = grid[:,1]; next[:,end] = grid[:,end]
    output = count(==(2), @view next[2:end-1,2:end-1]) / n
    o.history[t, 1:4] = [raw / n, unbacked / n, observed / n, output]
    next
end

function visibility_config(; L=64, pre=1000, post=3000, seed=1, f=0.20, h=100.0,
                           initial_shares=10, initial_condition=:balanced_perturbation)
    build(MyModelBConfiguration, (number_of_rows=L, number_of_cols=L,
        steps=pre+post, seed=seed, λ=0.02, k=1.0, minority_fraction=f,
        edge_band_spread=0.5, cost_basis_rule=false, initial_cash=1000.0,
        initial_shares=initial_shares, P0=100.0, market_maker_capacity=h,
        initial_condition=initial_condition))
end

function checked_visibility_run(config; pre, mode=:original, boundary=:hold, switched=true)
    o = VisibilityObserver(config.number_of_rows, config.steps; mode, start=pre+1)
    r = simulate(config; clearing=:reserve, minority_population=:interior,
        boundary_mode=boundary, rule_activation_step=switched ? pre+1 : config.steps+1,
        observer=o, snapshot_steps=[pre], verbose=false)
    cash = r.total_cash .+ r.market_maker_cash
    shares = r.total_shares .+ r.market_maker_inventory
    cash_error = maximum(abs.(cash .- cash[1]))
    product = r.market_maker_cash .* r.market_maker_inventory
    product_error = maximum(abs.(product ./ product[1] .- 1))
    @assert cash_error < max(1e-5, abs(cash[1])*1e-11)
    @assert all(==(shares[1]), shares)
    @assert product_error < 1e-9
    @assert r.prices ≈ r.market_maker_cash ./ r.market_maker_inventory
    @assert all(isfinite, r.prices) && all(>(0), r.prices)
    @assert o.minimum_cash >= -1e-9 && o.minimum_shares >= 0
    @assert o.history[:,4] == r.sell_fraction[2:end]
    @assert o.history[:,5] + o.history[:,9] == r.executed_sells
    (;result=r, observer=o, cash_error, product_error)
end
