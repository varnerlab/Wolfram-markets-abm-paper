struct FeeDiagnostics <: AbstractMarketObserver
    account::DealerFeeAccount
    revenue::Vector{Float64}
    execution_price::Vector{Float64}
end

function market_after_execution!(o::FeeDiagnostics,t,grid,books,price,counts,dealer)
    o.revenue[t+1]=o.account.cash
    o.execution_price[t]=counts.execution_price
end

function fee_config(;L=64,seed=1,pre=1000,post=3000,h=100.0,f=0.2,
                    cash=1000.0,shares=10,initial_condition=:balanced_perturbation)
    build(MyModelBConfiguration,(;number_of_rows=L,number_of_cols=L,
        steps=pre+post,seed,minority_fraction=f,market_maker_capacity=h,
        initial_cash=cash,initial_shares=shares,P0=100.0,
        initial_condition,edge_band_spread=0.5,cost_basis_rule=false))
end

"""Run the full financial simulator, retaining separate cumulative fee revenue."""
function simulate_with_fees(config;fee_rate::Float64=0.0,kwargs...)
    isfinite(fee_rate) && 0<=fee_rate<1 || throw(ArgumentError("invalid fee rate"))
    for key in (:observer,:clearing,:reserve_executor,:intervention)
        haskey(kwargs,key) && throw(ArgumentError("fee wrapper does not accept $key"))
    end
    account=DealerFeeAccount()
    observer=FeeDiagnostics(account,zeros(config.steps+1),zeros(config.steps))
    executor(args...;kw...)=execute_fee_orders!(args...;kw...,fee_rate,fee_account=account)
    result=simulate(config;kwargs...,clearing=:reserve,reserve_executor=executor,observer)
    cash=result.total_cash.+result.market_maker_cash.+observer.revenue
    cash_error=maximum(abs.(cash.-cash[1]))
    cash_error < max(1e-5,abs(cash[1])*1e-11) || error("fee cash conservation failed")
    shares=result.total_shares.+result.market_maker_inventory
    all(==(shares[1]),shares) || error("share conservation failed")
    minimum(result.final_books.cash)>=-1e-9 && minimum(result.final_books.shares)>=0 ||
        error("negative trader resources")
    all(isfinite,result.prices) && all(>(0),result.prices) || error("invalid quote")
    volume=result.executed_buys.+result.executed_sells
    expected=fee_rate.*observer.execution_price.*volume
    isapprox(observer.revenue[end],sum(expected);atol=1e-7,rtol=1e-11) ||
        error("fee ledger does not match completed volume")
    all(>=(0),diff(observer.revenue)) || error("fee revenue decreased")
    if config.market_maker_capacity>0
        product=result.market_maker_cash.*result.market_maker_inventory
        maximum(abs.(product./product[1].-1))<1e-9 || error("reserve product changed")
        result.prices≈result.market_maker_cash./result.market_maker_inventory ||
            error("quote includes nontrading cash")
    else
        all(==(config.P0),result.prices) || error("zero reserve quote changed")
        all(==(0),result.market_maker_cash) && all(==(0),result.market_maker_inventory) ||
            error("fees funded the zero reserve dealer")
    end
    (;result,fee_revenue=observer.revenue,execution_price=observer.execution_price,cash_error)
end
