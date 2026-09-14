include("Following-Lib.jl")

"""Separate simultaneous-exit stress: no new money, trader buys, or advice."""
function following_wind_down(run;clearing=:legacy)
    clearing in (:legacy,:reserve) || throw(ArgumentError("unknown clearing mechanism"))
    o,r=run.observer,run.result
    books=deepcopy(r.final_books);dealer=deepcopy(r.final_market_maker)
    initial_cash=copy(books.cash)
    grid=fill(1,o.config.number_of_rows,o.config.number_of_cols)
    edge_states=fill(1,length(r.edge_coordinates))
    price=r.prices[end];N=length(o.trader_ids)
    limit=maximum(books.shares[o.trader_ids];init=0)
    total_cash0=sum(books.cash[o.trader_ids])+dealer.cash
    total_shares0=sum(books.shares[o.trader_ids])+dealer.inventory
    rounds=0
    for step in 1:limit
        @inbounds for id in o.population.interior
            grid[id]=books.shares[id]>0 ? 2 : 1
        end
        for (j,(row,col)) in enumerate(r.edge_coordinates)
            edge_states[j]=books.shares[row,col]>0 ? 2 : 1
        end
        execute=clearing==:reserve ? execute_reserve_orders! : execute_orders!
        counts=execute(books,grid,r.edge_coordinates,edge_states,price;
            cost_basis_rule=false,market_maker=dealer,seed=o.config.seed,
            step=o.config.steps+step)
        counts.executed_buys==0 || error("wind-down created a trader buy")
        rounds=step
        counts.executed_sells==0 && break
        price = clearing==:reserve ? counts.next_price :
                price*exp(-o.config.λ*counts.executed_sells/N)
    end
    abs(sum(books.cash[o.trader_ids])+dealer.cash-total_cash0) <= max(1e-5,abs(total_cash0)*1e-11) ||
        error("wind-down lost cash")
    sum(books.shares[o.trader_ids])+dealer.inventory==total_shares0 || error("wind-down lost shares")
    row=(wind_rounds=rounds,wind_price=price,)
    for (name,ids) in pairs((followers=o.population.followers,leaders=o.population.leaders,others=o.population.others))
        valid=[id for id in ids if o.start_value[id]>0]
        stats=(cash_proceeds=isempty(valid) ? NaN : mean((books.cash[valid].-initial_cash[valid])./o.start_value[valid]),
               final_cash=isempty(valid) ? NaN : mean(books.cash[valid]./o.start_value[valid]),
               unsold_shares=isempty(ids) ? NaN : mean(books.shares[ids]),
               unsold_fraction=following_ratio(sum(books.shares[ids]),sum(r.final_books.shares[ids])))
        row=merge(row,prefixed(stats,"wind_"*string(name)*"_"))
    end
    row
end

function blank_wind_down()
    row=(wind_rounds=0,wind_price=NaN)
    for name in ("followers","leaders","others")
        row=merge(row,prefixed((cash_proceeds=NaN,final_cash=NaN,unsold_shares=NaN,unsold_fraction=NaN),"wind_"*name*"_"))
    end
    row
end

function diagnostic_job(;mechanism,impact=0.02,kwargs...)
    j=following_job(;kwargs...)
    id=bytes2hex(sha256(j.job_id*"|"*mechanism*"|"*string(impact)))[1:20]
    merge(j,(job_id=id,mechanism,impact))
end

function following_diagnostic_jobs(stage; sensitivities=false)
    stage in ("diagnostic-smoke","diagnostic-pilot","diagnostic-confirmation") ||
        throw(ArgumentError("unknown diagnostic stage"))
    smoke=stage=="diagnostic-smoke"
    seeds=smoke ? (600001:600001) : stage=="diagnostic-pilot" ? (610001:610010) : (620001:620050)
    reps=smoke ? (1:1) : stage=="diagnostic-pilot" ? (1:2) : (1:4)
    L,pre,post=smoke ? (12,10,40) : (64,1000,3000)
    ks=smoke ? (1,4) : (1,16)
    jobs=NamedTuple[]
    for seed in seeds, replicate in reps, boundary in ("hold","endogenous"),
        h in (1.,Inf), a in (0.1,0.4), K in ks, mechanism in ("advice","copy_filled")
        names=mechanism=="advice" ? ("live","withdrawal","mask","eta0","reverse") :
              ("live","withdrawal","mask","desired_copy","replay","replay_desired")
        for diagnostic in names
            mode=diagnostic in ("mask","replay") && mechanism=="copy_filled" ? "replay_filled" :
                 diagnostic=="replay_desired" ? "replay_desired" :
                 diagnostic=="desired_copy" ? "copy_desired" : mechanism
            push!(jobs,diagnostic_job(;stage,seed,replicate,boundary,h,a,K,L,pre,post,
                mechanism,mode,diagnostic,eta=diagnostic=="eta0" ? 0. : 0.8,
                reverse=diagnostic=="reverse",stop_after=diagnostic=="withdrawal" ? pre : post))
        end
        if sensitivities && !smoke
            for diagnostic in ("size32","size128","horizon10000","impact_low","impact_high")
                targetL=diagnostic=="size32" ? 32 : diagnostic=="size128" ? 128 : L
                targetPost=diagnostic=="horizon10000" ? 10000 : post
                impact=diagnostic=="impact_low" ? 0.005 : diagnostic=="impact_high" ? 0.05 : 0.02
                push!(jobs,diagnostic_job(;stage,seed,replicate,boundary,h,a,K,L=targetL,pre,
                    post=targetPost,mode=mechanism,mechanism,diagnostic,impact))
            end
        end
    end
    # All required paired controls are explicit manifest jobs. A common h=1 source
    # run is already present for every geometry, horizon, and impact coefficient.
    configs=unique([(j.seed,j.replicate,j.boundary,j.h,j.L,j.pre,j.post,j.impact) for j in jobs])
    for (seed,replicate,boundary,h,L,pre,post,impact) in configs
        push!(jobs,diagnostic_job(;stage,seed,replicate,boundary,h,L,pre,post,impact,
            mechanism="none",mode="none",a=0.,K=1,diagnostic="control"))
    end
    jobs
end

function run_following_diagnostic_block(group,storage,digest)
    label=bytes2hex(sha256(join([j.job_id for j in group],"|")))[1:20]
    checkpoint=joinpath(storage.directory,label*".jls")
    if isfile(checkpoint)
        saved=deserialize(checkpoint)
        saved.digest==digest || error("diagnostic checkpoint changed")
        saved.ids==[j.job_id for j in group] || error("diagnostic jobs changed")
        return saved.rows
    end
    controls=Dict{Tuple,Any}()
    rows=NamedTuple[]
    key(j)=(j.L,j.pre,j.post,j.h,j.impact)
    for j in filter(j->j.mode=="none",group)
        c=following_config(L=j.L,pre=j.pre,post=j.post,h=j.h,seed=j.seed,impact=j.impact)
        run=run_following(c,protocol_from_job(j);boundary=Symbol(j.boundary),
                          record_tapes=true,record_states=true)
        controls[key(j)]=(job=j,run=run)
        push!(rows,merge(following_row(j,run,run,j),blank_wind_down(),
                         (masked_identity=true,source_capacity=NaN)))
    end
    for j in filter(j->j.mode!="none",group)
        baseline=controls[key(j)]
        c=baseline.run.observer.config
        p=protocol_from_job(j)
        replay=nothing
        if j.mode in ("replay_filled","replay_desired")
            source=controls[(j.L,j.pre,j.post,1.,j.impact)].run.observer
            replay=j.mode=="replay_filled" ? source.filled_tape : source.desired_tape
        end
        mask=j.diagnostic=="mask" ? baseline.run.observer.state_tape : nothing
        run=run_following(c,p;boundary=Symbol(j.boundary),replay,
                          masked_states=mask,record_states=j.diagnostic=="mask")
        identity=true
        if j.diagnostic=="mask" && j.boundary=="hold"
            ids=setdiff(run.observer.population.interior,run.observer.population.followers)
            identity=run.observer.state_tape[ids,:]==baseline.run.observer.state_tape[ids,:]
            identity || error("masked non-followers failed to reproduce the baseline")
        end
        wind=j.diagnostic=="live" ? following_wind_down(run) : blank_wind_down()
        push!(rows,merge(following_row(j,run,baseline.run,baseline.job),wind,
                         (masked_identity=identity,source_capacity=isnothing(replay) ? NaN : 1.)))
    end
    # Serialize in manifest order, including controls that were computed first.
    lookup=Dict(r.job_id=>r for r in rows)
    rows=[lookup[j.job_id] for j in group]
    serialize(checkpoint*".tmp",(ids=[j.job_id for j in group],digest,rows))
    mv(checkpoint*".tmp",checkpoint;force=true)
    rows
end

function run_following_diagnostics(stage; sensitivities=false)
    jobs=following_diagnostic_jobs(stage;sensitivities)
    storage=write_following_manifest(stage,jobs)
    digest=bytes2hex(sha256(following_source_digest()*read(@__FILE__,String)))
    digest_path=storage.prefix*"-DiagnosticDigest.txt"
    isfile(digest_path) && readchomp(digest_path)!=digest && error("diagnostic implementation changed")
    isfile(digest_path) || write(digest_path,digest*"\n")
    keys=unique([(j.seed,j.replicate,j.boundary) for j in jobs])
    groups=[filter(j->(j.seed,j.replicate,j.boundary)==key,jobs) for key in keys]
    output=Vector{Any}(undef,length(groups))
    progress=Threads.Atomic{Int}(0)
    @info "Following diagnostics" stage jobs=length(jobs) blocks=length(groups)
    Threads.@threads :dynamic for i in eachindex(groups)
        output[i]=run_following_diagnostic_block(groups[i],storage,digest)
        completed=Threads.atomic_add!(progress,1)+1
        @info "Diagnostic blocks completed" completed total=length(groups)
    end
    data=DataFrame(reduce(vcat,output))
    nrow(data)==length(jobs) || error("incomplete diagnostics")
    Set(data.job_id)==Set(j.job_id for j in jobs) || error("diagnostic job mismatch")
    CSV.write(storage.prefix*"-Summary.csv.tmp",data)
    mv(storage.prefix*"-Summary.csv.tmp",storage.prefix*"-Summary.csv";force=true)
    data
end
