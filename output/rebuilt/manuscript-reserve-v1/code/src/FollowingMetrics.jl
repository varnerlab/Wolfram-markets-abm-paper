# FollowingMetrics.jl — online measurements of actual orders and marked wealth.

following_ratio(n,d) = d == 0 ? NaN : n/d

function market_after_execution!(o::FollowingObserver, t, grid, books, price, counts, dealer)
    p, pop, trace = o.protocol, o.population, o.trace
    @inbounds for (k,id) in enumerate(pop.leaders)
        desired, filled = trace.desired[id], trace.filled[id]
        o.desired_history[k,mod1(t,p.lag)] = desired
        o.filled_history[k,mod1(t,p.lag)] = filled
        isnothing(o.desired_tape) || (o.desired_tape[k,t] = desired)
        isnothing(o.filled_tape) || (o.filled_tape[k,t] = filled)
    end
    nb=0; ns=0; fb=0; fs=0; other_sell=0
    @inbounds for id in pop.interior
        order = trace.desired[id]
        nb += order == 1; ns += order == -1
    end
    @inbounds for id in pop.followers
        fb += trace.desired[id] == 1; fs += trace.desired[id] == -1
    end
    @inbounds for id in pop.others
        other_sell += trace.desired[id] == -1
    end
    N = length(pop.interior); M = length(pop.followers)
    o.trajectory[t,1] = nb/N; o.trajectory[t,2] = ns/N
    o.trajectory[t,3] = following_ratio(fb,M); o.trajectory[t,4] = following_ratio(fs,M)
    o.trajectory[t,5] = following_ratio(other_sell,length(pop.others))
    o.trajectory[t,9] = price
    if following_active(p,t) && M > 0
        source_events = if p.mode == :advice
            o.source_states
        else
            # With staggered delays this measures realized follower input diversity;
            # otherwise one event per source suffices.
            indices = p.staggered ? eachindex(pop.followers) : 1:length(pop.weights)
            Int8[trace.desired[pop.followers[j]] for j in indices]
        end
        b = count(==(1),source_events); s = count(==(-1),source_events)
        z = length(source_events)-b-s; k = length(source_events)
        o.trajectory[t,6] = following_ratio(b+s,k)
        o.trajectory[t,7] = following_ratio(b*(b-1)+s*(s-1)+z*(z-1), k*(k-1))
        o.trajectory[t,8] = following_ratio(b*(b-1)+s*(s-1), (b+s)*(b+s-1))
    end
    if t > p.pre
        @inbounds for id in o.trader_ids
            d,e,f = trace.desired[id],trace.eligible[id],trace.filled[id]
            o.order_counts[id,1] += d == 1; o.order_counts[id,2] += d == -1
            o.order_counts[id,3] += e == 1; o.order_counts[id,4] += e == -1
            o.order_counts[id,5] += f == 1; o.order_counts[id,6] += f == -1
            o.buy_steps[id] += d == 1; o.sell_steps[id] += d == -1
            value = books.cash[id]+books.shares[id]*price
            o.peak_value[id] = max(o.peak_value[id],value)
            o.max_drawdown[id] = o.peak_value[id] > 0 ?
                max(o.max_drawdown[id],1-value/o.peak_value[id]) : NaN
            o.final_value[id] = value
        end
    end
    o.last_step = t
end

"""Cohort statistics work for arbitrary prospective masks in a shared control."""
function following_cohort(o::FollowingObserver, ids::AbstractVector{<:Integer})
    n = length(ids)
    post = o.config.steps-o.protocol.pre
    returns = [o.start_value[id] > 0 ? o.final_value[id]/o.start_value[id]-1 : NaN for id in ids]
    desired_b = sum(o.order_counts[id,1] for id in ids; init=0)
    desired_s = sum(o.order_counts[id,2] for id in ids; init=0)
    eligible_b = sum(o.order_counts[id,3] for id in ids; init=0)
    eligible_s = sum(o.order_counts[id,4] for id in ids; init=0)
    filled_b = sum(o.order_counts[id,5] for id in ids; init=0)
    filled_s = sum(o.order_counts[id,6] for id in ids; init=0)
    (; n, mean_return=n==0 ? NaN : mean(returns),
       return_q10=n==0 ? NaN : quantile(returns,0.1),
       return_median=n==0 ? NaN : median(returns),
       return_q90=n==0 ? NaN : quantile(returns,0.9),
       mean_drawdown=n==0 ? NaN : mean(o.max_drawdown[ids]),
       mean_sell=following_ratio(sum(o.sell_steps[ids]),n*post),
       mean_buy=following_ratio(sum(o.buy_steps[ids]),n*post),
       desired_buys=desired_b, desired_sells=desired_s,
       eligible_buys=eligible_b, eligible_sells=eligible_s,
       executed_buys=filled_b, executed_sells=filled_s,
       suppressed_buys=desired_b-eligible_b, suppressed_sells=desired_s-eligible_s,
       rejected_buys=eligible_b-filled_b, rejected_sells=eligible_s-filled_s,
       sell_rejection=following_ratio(eligible_s-filled_s,eligible_s),
       fill_rate=following_ratio(filled_b+filled_s,desired_b+desired_s))
end

function following_market(o::FollowingObserver, result)
    pre = o.protocol.pre
    post = pre+1:o.config.steps
    sell = @view o.trajectory[post,2]
    buy = @view o.trajectory[post,1]
    onset = findfirst(>=(0.5),sell)
    totals = following_cohort(o,o.trader_ids)
    finite_mean(v) = (x=filter(isfinite,v); isempty(x) ? NaN : mean(x))
    (; transitioned=!isnothing(onset), onset=isnothing(onset) ? missing : onset,
       buy_majority=any(>=(0.5),buy), mean_sell=mean(sell), peak_sell=maximum(sell),
       maximum_drawdown=compute_max_drawdown(result.prices[pre+1:end]),
       mean_buy=mean(buy), desired_imbalance_std=std(buy.-sell),
       sell_rejection=totals.sell_rejection, fill_rate=totals.fill_rate,
       desired_buys=totals.desired_buys, desired_sells=totals.desired_sells,
       suppressed_buys=totals.suppressed_buys, suppressed_sells=totals.suppressed_sells,
       rejected_buys=totals.rejected_buys, rejected_sells=totals.rejected_sells,
       executed_buys=totals.executed_buys, executed_sells=totals.executed_sells,
       source_active=finite_mean(o.trajectory[post,6]),
       source_agreement=finite_mean(o.trajectory[post,7]),
       source_active_agreement=finite_mean(o.trajectory[post,8]),
       final_dealer_cash=result.final_market_maker.cash,
       final_dealer_inventory=result.final_market_maker.inventory)
end

function check_following_accounting(o::FollowingObserver, r)
    post = o.protocol.pre+1:o.config.steps
    m = following_cohort(o,o.trader_ids)
    for name in (:executed_buys,:executed_sells,:suppressed_buys,:suppressed_sells)
        getproperty(m,name) == sum(getproperty(r,name)[post]) || error("order reconciliation: $name")
    end
    m.rejected_buys == sum(r.market_maker_rejected_buys[post]) || error("buy rejection mismatch")
    m.rejected_sells == sum(r.market_maker_rejected_sells[post]) || error("sell rejection mismatch")
    cash = r.total_cash .+ r.market_maker_cash
    shares = r.total_shares .+ r.market_maker_inventory
    maximum(abs.(cash .- cash[1])) <= max(1e-5,abs(cash[1])*1e-11) || error("cash not conserved")
    all(==(shares[1]),shares) || error("shares not conserved")
    all(>=(0),r.final_books.shares[o.trader_ids]) || error("negative trader shares")
    all(>=(-1e-8),r.final_books.cash[o.trader_ids]) || error("negative trader cash")
    true
end
