include("Include.jl")
length(ARGS) == 2 || error("provide study directory and manifest filename")
const STUDY=abspath(ARGS[1])
const JOBS=CSV.read(joinpath(STUDY,ARGS[2]),DataFrame)
const OUTPUT_LOCK=ReentrantLock()
const DONE=Threads.Atomic{Int}(0)

function metrics(run, job)
    r,o=run.result,run.observer
    pre,post=Int(job.pre),Int(job.post)
    times=pre+1:pre+post
    late=pre+post-min(500,post)+1:pre+post
    raw=@view o.history[times,4]
    onset=findfirst(>=(0.5),raw)
    # Input signals are measured immediately before the update, using holdings
    # after settlement. "Through onset" includes the input producing that onset.
    before=pre+1:(isnothing(onset) ? pre+post : pre+onset)
    input_sells=sum(o.history[times,1])
    before_sells=sum(o.history[before,1])
    suppressed=sum(o.history[times,7]); desired=sum(o.history[times,8])
    eligible=sum(r.executed_buys[times])+sum(r.executed_sells[times])+
        sum(r.market_maker_rejected_buys[times])+sum(r.market_maker_rejected_sells[times])
    rejects=sum(r.market_maker_rejected_buys[times])+sum(r.market_maker_rejected_sells[times])
    (;id=String(job.id), group=String(job.group), mode=String(job.mode), role=String(job.role),
      seed=Int(job.seed), L=Int(job.L), boundary=String(job.boundary), h=Float64(job.h),
      f=Float64(job.f), pre,post, majority=!isnothing(onset),
      onset=isnothing(onset) ? -1 : onset, final_sell_mean=mean(o.history[late,4]),
      max_drawdown=compute_max_drawdown(r.prices[pre+1:end]),
      interior_sales_per_trader=sum(o.history[times,5])/(Int(job.L)-2)^2,
      interior_buys_per_trader=sum(o.history[times,6])/(Int(job.L)-2)^2,
      interior_completed_sales=sum(o.history[times,5]), edge_completed_sales=sum(o.history[times,9]),
      suppressed_sale_fraction=desired==0 ? 0.0 : suppressed/desired,
      dealer_rejection_fraction=eligible==0 ? 0.0 : rejects/eligible,
      raw_input_sell_mean=mean(o.history[times,1]), visible_input_sell_mean=mean(o.history[times,3]),
      unbacked_signal_fraction=input_sells==0 ? 0.0 : sum(o.history[times,2])/input_sells,
      unbacked_through_onset=before_sells==0 ? 0.0 : sum(o.history[before,2])/before_sells,
      baseline_unbacked_fraction=sum(o.history[1:pre,2])/sum(o.history[1:pre,1]),
      max_cash_error=run.cash_error,max_product_error=run.product_error,
      minimum_cash=o.minimum_cash,minimum_shares=o.minimum_shares,
      pre_state_sha256=o.pre_state_sha256,first_execution_sha256=o.first_execution_sha256,
      pre_grid_sha256=array_digest(r.frames[pre]),final_grid_sha256=array_digest(r.frames[pre+post]),
      prehistory_sha256=array_digest(vcat(r.prices[1:pre+2],r.sell_fraction[1:pre+1],
                                        r.total_cash[1:pre+2],r.market_maker_cash[1:pre+2])),
      sell_history_sha256=array_digest(r.sell_fraction),price_history_sha256=array_digest(r.prices),
      completed_utc=string(now(UTC)))
end

function run_group(jobs)
    for job in eachrow(jobs)
        path=joinpath(STUDY,"results",String(job.id)*".csv")
        if isfile(path)
            saved=CSV.read(path,DataFrame)
            nrow(saved)==1 && saved.id[1]==job.id || error("invalid checkpoint $path")
            continue
        end
        config=visibility_config(L=Int(job.L),pre=Int(job.pre),post=Int(job.post),
            seed=Int(job.seed),f=Float64(job.f),h=Float64(job.h))
        run=checked_visibility_run(config;pre=Int(job.pre),mode=Symbol(job.mode),
            boundary=Symbol(job.boundary),switched=job.role=="switch")
        row=metrics(run,job)
        if Bool(job.save_history)
            history=DataFrame(run.observer.history,HISTORY_NAMES)
            insertcols!(history,1,:step=>collect(1:config.steps))
            CSV.write(joinpath(STUDY,"histories",String(job.id)*".csv"),history)
        end
        CSV.write(path*".tmp",DataFrame([row]))
        mv(path*".tmp",path)
    end
    n=Threads.atomic_add!(DONE,1)+1
    lock(OUTPUT_LOCK) do
        println(now(UTC)," completed group ",n,"/",length(unique(JOBS.group)))
        flush(stdout)
    end
end

groups=collect(groupby(JOBS,:group;sort=false))
println(now(UTC)," starting ",nrow(JOBS)," simulations; threads=",Threads.nthreads())
flush(stdout)
Threads.@threads :dynamic for i in eachindex(groups)
    run_group(groups[i])
end
