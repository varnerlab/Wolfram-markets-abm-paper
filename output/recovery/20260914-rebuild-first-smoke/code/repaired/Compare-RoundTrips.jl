# Replay the diagnosed exploit through both complete simulation paths.
include("../following/Diagnose-Following-Execution.jl")

function compare_round_trips()
    rows=NamedTuple[]
    for clearing in (:legacy,:reserve),h in (1.,100.),participants in (1,1538),
        direction in (1,-1),cycles in (1,100),wait_steps in (0,5)
        orders=Int[0]
        for _ in 1:cycles
            push!(orders,direction)
            append!(orders,zeros(Int,wait_steps))
            push!(orders,-direction)
        end
        push!(orders,0)
        c=following_config(;L=64,seed=630001,pre=0,post=length(orders),h,
            initial_condition=:all_hold,edge_fraction=0.25)
        linear=LinearIndices((64,64))
        interior=[linear[r,col] for col in 2:63 for r in 2:63]
        cohort=interior[1:participants]
        observer=ExecutionProbe(cohort,orders)
        r=simulate(c;observer,clearing,boundary_mode=:hold,minority_population=:interior,
                     snapshot_steps=Int[],verbose=false)
        ids=vcat(interior,[linear[row,col] for (row,col) in r.edge_coordinates])
        @assert r.executed_buys==[q==1 ? participants : 0 for q in orders]
        @assert r.executed_sells==[q==-1 ? participants : 0 for q in orders]
        @assert all(==(c.initial_shares),r.final_books.shares[ids])
        @assert all(==(c.initial_cash),r.final_books.cash[setdiff(ids,cohort)])
        @assert isapprox(r.prices[end],c.P0;atol=1e-9,rtol=0)
        @assert r.market_maker_inventory[end]==r.market_maker_inventory[1]
        gain=sum(r.final_books.cash[cohort].-c.initial_cash)
        dealer_gain=r.market_maker_cash[end]-r.market_maker_cash[1]
        @assert isapprox(gain+dealer_gain,0.;atol=1e-6,rtol=0)
        expected=if clearing==:reserve
            0.
        else
            x=c.λ*participants/length(ids)
            cycles*participants*c.P0*(direction==1 ? expm1(x) : -expm1(-x))
        end
        @assert isapprox(gain,expected;atol=1e-6,rtol=1e-9)
        push!(rows,(;clearing=string(clearing),h,participants,direction,cycles,wait_steps,
            cash_gain_per_participant=gain/participants,cohort_cash_gain=gain,
            dealer_cash_gain=dealer_gain,expected_cohort_gain=expected,final_price=r.prices[end]))
    end
    output=joinpath(FOLLOWING_ROOT,"output","repaired","round-trips-v2")
    mkpath(output)
    CSV.write(joinpath(output,"Summary.csv"),DataFrame(rows))
    metadata=Dict("source_digest"=>following_source_digest(),"julia_version"=>string(VERSION),
        "script_digest"=>bytes2hex(sha256(read(@__FILE__))),"cases"=>length(rows))
    open(joinpath(output,"Protocol.toml"),"w") do io;TOML.print(io,metadata);end
    @info "Round-trip comparison complete" cases=length(rows) output
end

if abspath(PROGRAM_FILE)==@__FILE__
    compare_round_trips()
end
