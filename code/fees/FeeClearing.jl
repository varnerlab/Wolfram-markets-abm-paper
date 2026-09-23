"""Dealer revenue excluded from the cash and shares used for reserve pricing."""
mutable struct DealerFeeAccount
    cash::Float64
end
DealerFeeAccount() = DealerFeeAccount(0.0)

"""
Settle unit orders with a cash fee on each completed buy and sale.

Buyers pay (1+rate)*price; sellers receive (1-rate)*price. The difference
is dealer revenue, held outside the trading reserves. Buy affordability
includes the fee. Acquisition cost includes the buyer fee; the optional
cost-basis restriction compares net sale proceeds with that cost.
"""
function execute_fee_orders!(books::MyAgentBooks, grid::Array{Int64,2},
    edges::Vector{Tuple{Int64,Int64}}, states::Vector{Int64}, last_price::Float64;
    market_maker::MyMarketMaker, fee_rate::Float64, fee_account::DealerFeeAccount,
    cost_basis_rule::Bool=false, seed::Int64=0, step::Int64=1,
    trace::Union{Nothing,MyOrderTrace}=nothing)
    isfinite(fee_rate) && 0 <= fee_rate < 1 ||
        throw(ArgumentError("fee_rate must lie in [0,1)"))
    # Preserve the original arithmetic, ordering, and allocation at zero fee.
    if fee_rate == 0
        counts = execute_reserve_orders!(books,grid,edges,states,last_price;
            market_maker,cost_basis_rule,seed,step,trace)
        return merge(counts,(fee_income=0.0,))
    end
    dealer = market_maker
    dealer.unlimited && throw(ArgumentError("fee dealer cannot borrow or short"))
    dealer.max_inventory == typemax(Int64) ||
        throw(ArgumentError("use build_reserve_dealer"))
    empty_reserves = dealer.initial_inventory == 0
    if empty_reserves
        dealer.cash == 0 && dealer.inventory == 0 || error("zero reserve control changed")
    else
        dealer.cash > 0 && dealer.inventory >= 1 || error("nonpositive reserve")
    end
    if !isnothing(trace)
        for buffer in (trace.desired,trace.eligible,trace.filled)
            size(buffer)==size(grid) || throw(DimensionMismatch("order trace dimensions"))
            fill!(buffer,0)
        end
    end
    buyers=NTuple{3,Int64}[]; sellers=NTuple{3,Int64}[]
    linear=LinearIndices(grid)
    function request(r,c,state)
        order=compute_desired_order(state)
        isnothing(trace) || (trace.desired[r,c]=order)
        order==0 && return
        push!(order==1 ? buyers : sellers,(Int64(r),Int64(c),Int64(linear[r,c])))
    end
    for c in 2:size(grid,2)-1, r in 2:size(grid,1)-1
        request(r,c,grid[r,c])
    end
    for (i,(r,c)) in enumerate(edges)
        request(r,c,states[i])
    end
    cash,inventory=dealer.cash,dealer.inventory
    base_price(x)=empty_reserves ? last_price : cash/(inventory-x)
    can_buy(b,p)=books.cash[b[3]] >= (1+fee_rate)*p
    can_sell(s,p)=books.shares[s[3]] >= 1 &&
        (!cost_basis_rule || (1-fee_rate)*p > books.avg_cost[s[3]])
    excess(x)=begin
        p=base_price(x)
        count(b->can_buy(b,p),buyers)-count(s->can_sell(s,p),sellers)
    end
    net=0
    if !empty_reserves
        initial_excess=excess(0)
        direction=sign(initial_excess)
        lo=0
        hi=direction>0 ? min(initial_excess,inventory-1) : -initial_excess
        while lo<hi
            mid=lo+(hi-lo+1)÷2
            direction*excess(direction*mid)>=mid ? (lo=mid) : (hi=mid-1)
        end
        net=direction*lo
    end
    price=base_price(net)
    eligible_b=filter(b->can_buy(b,price),buyers)
    eligible_s=filter(s->can_sell(s,price),sellers)
    B,S=length(eligible_b),length(eligible_s)
    fill_b=min(B,S+net); fill_s=fill_b-net
    0<=fill_b<=B && 0<=fill_s<=S || error("infeasible fee auction")
    if !isnothing(trace)
        for b in eligible_b; trace.eligible[b[3]]=1; end
        for s in eligible_s; trace.eligible[s[3]]=-1; end
    end
    0<fill_b<B && _rank_for_rationing!(eligible_b,seed,step,1)
    0<fill_s<S && _rank_for_rationing!(eligible_s,seed,step,-1)
    for i in 1:fill_b
        r,c,id=eligible_b[i]
        _settle_agent_order!(books,r,c,1,(1+fee_rate)*price)
        isnothing(trace) || (trace.filled[id]=1)
    end
    for i in 1:fill_s
        r,c,id=eligible_s[i]
        _settle_agent_order!(books,r,c,-1,(1-fee_rate)*price)
        isnothing(trace) || (trace.filled[id]=-1)
    end
    fee_income=fee_rate*price*(fill_b+fill_s)
    fee_account.cash+=fee_income
    if !empty_reserves
        dealer.inventory=inventory-net
        dealer.cash=cash*inventory/dealer.inventory
    end
    (;executed_buys=fill_b,executed_sells=fill_s,
      suppressed_buys=length(buyers)-B,suppressed_sells=length(sellers)-S,
      market_maker_rejected_buys=B-fill_b,market_maker_rejected_sells=S-fill_s,
      execution_price=price,next_price=empty_reserves ? last_price : dealer.cash/dealer.inventory,
      fee_income)
end
