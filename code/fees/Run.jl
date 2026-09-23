include("Include.jl")
using Printf

length(ARGS)==1 || error("provide the frozen study directory")
const STUDY=abspath(ARGS[1])
const JOBS=CSV.read(joinpath(STUDY,"Manifest.csv"),DataFrame)
const WRITE_LOCK=ReentrantLock()
const COMPLETED=Threads.Atomic{Int}(0)

array_digest(x)=bytes2hex(sha256(reinterpret(UInt8,vec(x))))

function metrics(run,job)
    r=run.result; pre=Int(job.pre); steps=r.config.steps
    order_window=(pre+1):steps
    state_window=(pre+2):(steps+1)
    desired_b=r.executed_buys.+r.suppressed_buys.+r.market_maker_rejected_buys
    desired_s=r.executed_sells.+r.suppressed_sells.+r.market_maker_rejected_sells
    first_crossing=findfirst(>=(0.5),@view r.sell_fraction[state_window])
    volume=r.executed_buys.+r.executed_sells
    (;group=String(job.group),role=String(job.role),fee_bps=Int(job.fee_bps),
      h=Float64(job.h),boundary=String(job.boundary),seed=Int(job.seed),f=Float64(job.f),
      L=Int(job.L),pre,post=Int(job.post),majority=!isnothing(first_crossing),
      onset=isnothing(first_crossing) ? -1 : first_crossing,
      max_drawdown=compute_max_drawdown(r.prices[(pre+1):end]),
      final_sell=r.sell_fraction[end],final_price=r.prices[end],
      post_completed_orders=sum(volume[order_window]),
      post_desired_orders=sum(desired_b[order_window])+sum(desired_s[order_window]),
      post_suppressed_buys=sum(r.suppressed_buys[order_window]),
      post_desired_buys=sum(desired_b[order_window]),
      post_dealer_rejections=sum(r.market_maker_rejected_buys[order_window])+sum(r.market_maker_rejected_sells[order_window]),
      initial_trader_cash=r.total_cash[1],activation_trader_cash=r.total_cash[pre+1],
      final_trader_cash=r.total_cash[end],final_trading_reserve_cash=r.market_maker_cash[end],
      initial_trading_reserve_cash=r.market_maker_cash[1],
      final_fee_revenue=run.fee_revenue[end],activation_fee_revenue=run.fee_revenue[pre+1],
      post_fee_revenue=run.fee_revenue[end]-run.fee_revenue[pre+1],
      max_cash_conservation_error=run.cash_error,
      initial_grid_sha256=array_digest(r.frames[0]),
      activation_grid_sha256=array_digest(r.frames[pre]),
      prehistory_sha256=array_digest(vcat(r.prices[1:pre+2],run.fee_revenue[1:pre+2],
          r.total_cash[1:pre+2],r.sell_fraction[1:pre+1])),
      final_grid_sha256=array_digest(r.frames[steps]),
      sell_history_sha256=array_digest(r.sell_fraction),
      price_history_sha256=array_digest(r.prices),
      completed_utc=string(now(UTC)))
end

function run_group(jobs)
    id=String(jobs[1,:group]);path=joinpath(STUDY,"results",id*".csv")
    if isfile(path)
        old=CSV.read(path,DataFrame)
        nrow(old)==nrow(jobs) || error("incomplete checkpoint $path")
        Threads.atomic_add!(COMPLETED,1)
        return
    end
    rows=NamedTuple[]
    control=nothing
    for job in eachrow(jobs)
        c=fee_config(L=Int(job.L),seed=Int(job.seed),pre=Int(job.pre),post=Int(job.post),
            h=Float64(job.h),f=Float64(job.f))
        run=simulate_with_fees(c;fee_rate=Int(job.fee_bps)/10000.0,
            minority_population=:interior,boundary_mode=Symbol(job.boundary),
            rule_activation_step=job.role=="control" ? c.steps+1 : Int(job.pre)+1,
            snapshot_steps=[Int(job.pre)],verbose=false)
        if job.role=="control"
            control=run
        else
            pre=Int(job.pre)
            @assert run.result.prices[1:pre+2]==control.result.prices[1:pre+2]
            @assert run.fee_revenue[1:pre+2]==control.fee_revenue[1:pre+2]
            @assert run.result.total_cash[1:pre+2]==control.result.total_cash[1:pre+2]
            @assert run.result.sell_fraction[1:pre+1]==control.result.sell_fraction[1:pre+1]
            @assert run.result.frames[pre]==control.result.frames[pre]
            @assert run.result.edge_coordinates==control.result.edge_coordinates
            @assert run.result.edge_k==control.result.edge_k
        end
        push!(rows,metrics(run,job))
    end
    CSV.write(path*".tmp",DataFrame(rows));mv(path*".tmp",path)
    count=Threads.atomic_add!(COMPLETED,1)+1
    lock(WRITE_LOCK) do
        println(now(UTC)," completed group ",count,"/",length(unique(JOBS.group))," ",id)
        flush(stdout)
    end
end

groups=collect(groupby(JOBS,:group;sort=false))
println(now(UTC)," starting ",length(groups)," groups, ",nrow(JOBS)," full simulations; threads=",Threads.nthreads())
flush(stdout)
Threads.@threads :dynamic for i in eachindex(groups)
    run_group(groups[i])
end
all_rows=vcat([CSV.read(joinpath(STUDY,"results",String(g[1,:group])*".csv"),DataFrame) for g in groups]...)
CSV.write(joinpath(STUDY,"Run-Summary.csv"),all_rows)
println(now(UTC)," complete: ",nrow(all_rows)," simulations")
