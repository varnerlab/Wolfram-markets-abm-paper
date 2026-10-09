isdeepreserve(x) = x == 100.0
# Explicit reserve execution and per-run checks for the complete manuscript rerun.
# The tested simulator files themselves are copied without modification.
using Dates, SHA
const REBUILD_LEDGER_LOCK=ReentrantLock()

function simulate_repaired(config; kwargs...)
    isfinite(config.market_maker_capacity) || error("the rebuilt study requires finite reserves")
    haskey(kwargs,:clearing) && error("clearing is fixed by the rebuild protocol")
    r=simulate(config;clearing=:reserve,kwargs...)
    cash=r.total_cash.+r.market_maker_cash
    shares=r.total_shares.+r.market_maker_inventory
    intervention=get(kwargs,:intervention,nothing)
    spans=if isnothing(intervention)
        (1:length(cash),)
    else
        t=get(kwargs,:rule_activation_step,nothing)
        isnothing(t) && error("resource intervention must identify its scheduled step")
        (1:t,t+1:length(cash))
    end
    for span in spans
        @assert maximum(abs.(cash[span].-cash[first(span)])) < max(1e-5,abs(cash[first(span)])*1e-11)
        @assert all(==(shares[first(span)]),shares[span])
    end
    @assert all(isfinite,r.prices) && all(>(0),r.prices)
    @assert minimum(r.final_books.cash)>=-1e-9 && minimum(r.final_books.shares)>=0
    if config.market_maker_capacity>0
        product=r.market_maker_cash.*r.market_maker_inventory
        @assert maximum(abs.(product./product[1].-1))<1e-9
        @assert r.prices≈r.market_maker_cash./r.market_maker_inventory
    else
        @assert all(==(config.P0),r.prices)
    end
    # This ledger is written only after a new full simulation has completed.
    # Cached result readers cannot create these entries.
    ledger=joinpath(@__DIR__,"..","data","Rebuild-Execution-Ledger.csv")
    lock(REBUILD_LEDGER_LOCK) do
        new=!isfile(ledger)
        open(ledger,"a") do io
            new && println(io,"completed_utc,phase,seed,L,steps,h,f,rule,activation_step,boundary,action,fixed_band,resource_intervention,final_grid_sha256")
            values=(now(UTC),get(ENV,"REBUILD_PHASE","test"),config.seed,config.number_of_rows,
                config.steps,config.market_maker_capacity,config.minority_fraction,config.rule_minor_index,
                get(kwargs,:rule_activation_step,0),get(kwargs,:boundary_mode,:endogenous),
                get(kwargs,:activation_action,:rule),get(kwargs,:fixed_band_step,nothing),
                !isnothing(intervention),bytes2hex(sha256(reinterpret(UInt8,vec(r.frames[config.steps])))))
            println(io,join(string.(values),","))
        end
    end
    r
end

function held_rebuild(config; pre=1000,action=:rule)
    r=simulate_repaired(config;minority_population=:interior,boundary_mode=:hold,
        rule_activation_step=action==:none ? config.steps+1 : pre+1,
        activation_action=action==:sell_pulse ? :sell_pulse : :rule,
        snapshot_steps=[pre],verbose=false)
    (;sell_fraction=r.sell_fraction,initial=r.frames[0],at_activation=r.frames[pre],
       final=r.frames[config.steps],financial_result=r)
end
