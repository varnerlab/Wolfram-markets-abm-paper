# Shared setup for the following experiments; paths do not depend on the cwd.
using Random, Statistics, SHA, Serialization, CSV, DataFrames, JLD2, Printf, Dates, TOML
for file in ("Types.jl", "Factory.jl", "Wolfram.jl", "Compute.jl", "Simulate.jl",
             "Following.jl", "FollowingMetrics.jl")
    include(joinpath(@__DIR__, "..", "src", file))
end

function following_job(; stage, seed, replicate=1, mode="advice", a=0.1, K=1,
                       independent=false, L=64, pre=1000, post=3000, h=1.,
                       boundary="hold", eta=0.8, lag=1, stop_after=post,
                       staggered=false, reverse=false, selection="random", diagnostic="core")
    parameters=(;stage,seed,replicate,mode,a,K,independent,L,pre,post,h,boundary,
                 eta,lag,stop_after,staggered,reverse,selection,diagnostic)
    id=bytes2hex(sha256(join(string.(values(parameters)),"|")))[1:20]
    merge((job_id=id,),parameters)
end

function following_jobs(stage::String)
    stage in ("smoke","pilot","confirmation") || throw(ArgumentError("unknown campaign"))
    seeds=stage=="smoke" ? (600001:600002) : stage=="pilot" ? (610001:610010) : (620001:620050)
    reps=stage=="smoke" ? (1:1) : stage=="pilot" ? (1:2) : (1:4)
    fractions=stage=="smoke" ? (0.10,0.40) : (0.05,0.10,0.20,0.40)
    ks=stage=="smoke" ? (1,4) : (1,4,16)
    capacities=stage=="smoke" ? (0.1,Inf) : (0.1,1.,Inf)
    L,pre,post=stage=="smoke" ? (12,10,40) : (64,1000,3000)
    jobs=NamedTuple[]
    for seed in seeds, h in capacities, boundary in ("hold","endogenous")
        base=(;stage,seed,h,boundary,L,pre,post)
        push!(jobs,following_job(;base...,replicate=0,mode="none",a=0.,K=1))
        for replicate in reps, a in fractions
            for K in ks, mode in ("advice","copy_filled")
                push!(jobs,following_job(;base...,replicate,a,K,mode))
            end
            push!(jobs,following_job(;base...,replicate,a,K=0,independent=true))
        end
    end
    jobs
end

function protocol_from_job(j)
    FollowingProtocol(mode=Symbol(j.mode),adoption=j.a,sources=max(1,j.K),
        independent=j.independent,replicate=j.replicate,pre=j.pre,
        stop_after=j.stop_after,persistence=j.eta,lag=j.lag,staggered=j.staggered,
        reverse_advice=j.reverse,leader_selection=Symbol(j.selection))
end

function following_source_digest()
    files=[joinpath("code","src",f) for f in
           ("Types.jl","Factory.jl","Wolfram.jl","Compute.jl","Simulate.jl",
            "Following.jl","FollowingMetrics.jl","ReserveClearing.jl")]
    push!(files,"code/following/Following-Lib.jl")
    io=IOBuffer()
    for file in files
        write(io,file); write(io,read(joinpath(FOLLOWING_ROOT,file)))
    end
    bytes2hex(sha256(take!(io)))
end

function write_following_manifest(stage,jobs)
    prefix=joinpath(FOLLOWING_DATA,"Following-"*uppercasefirst(stage))
    directory=prefix*"-Checkpoints"
    mkpath(directory)
    io=IOBuffer(); CSV.write(io,DataFrame(jobs)); manifest=take!(io)
    meta=Dict("protocol_version"=>FOLLOWING_VERSION,
              "source_digest"=>following_source_digest(),
              "manifest_digest"=>bytes2hex(sha256(manifest)),
              "julia_version"=>string(VERSION))
    lockfile=joinpath(FOLLOWING_ROOT,"code","Manifest.toml")
    meta["environment_digest"]=isfile(lockfile) ? bytes2hex(sha256(read(lockfile))) : "absent"
    path=prefix*"-Protocol.toml"
    if isfile(path)
        saved=TOML.parsefile(path)
        for (key,value) in meta
            get(saved,key,nothing)==value || error("checkpoint protocol mismatch for $key; use a newly versioned campaign")
        end
    else
        meta["created_utc"]=string(now(UTC))
        meta["git_revision"]=readchomp(Cmd(Cmd(["git","rev-parse","HEAD"]);dir=FOLLOWING_ROOT))
        open(path,"w") do io
            TOML.print(io,meta)
        end
    end
    manifest_path=prefix*"-Manifest.csv"
    if isfile(manifest_path)
        read(manifest_path)==manifest || error("manifest changed")
    else
        write(manifest_path,manifest)
    end
    (;prefix,directory,metadata=meta)
end

prefixed(nt,prefix)=NamedTuple{Tuple(Symbol(prefix,k) for k in keys(nt))}(values(nt))

function following_row(j,run,control,control_job)
    o,r=run.observer,run.result
    b=control.observer
    o.start_fingerprint==b.start_fingerprint || error("paired starting states differ")
    r.prices[1:j.pre+1]==control.result.prices[1:j.pre+1] || error("paired price prehistory differs")
    cohorts=(followers=o.population.followers,leaders=o.population.leaders,others=o.population.others)
    m=following_market(o,r); cm=following_market(b,control.result)
    row=merge(j,(control_id=control_job.job_id,protocol_version=FOLLOWING_VERSION,
        start_fingerprint=o.start_fingerprint,n_followers=length(o.population.followers),
        actual_sources=isempty(o.population.followers) ? 0 : length(o.population.weights),
        concentration=isempty(o.population.weights) ? NaN : sum(abs2,o.population.weights)),m,
        (drawdown_difference=m.maximum_drawdown-cm.maximum_drawdown,
         rejection_difference=m.sell_rejection-cm.sell_rejection,
         transition_difference=Int(m.transitioned)-Int(cm.transitioned)))
    for (name,ids) in pairs(cohorts)
        measured=following_cohort(o,ids); baseline=following_cohort(b,ids)
        differences=(return_difference=measured.mean_return-baseline.mean_return,
                     drawdown_difference=measured.mean_drawdown-baseline.mean_drawdown,
                     sell_difference=measured.mean_sell-baseline.mean_sell,
                     q10_difference=measured.return_q10-baseline.return_q10)
        row=merge(row,prefixed(measured,string(name)*"_"),prefixed(differences,string(name)*"_"))
    end
    subscribed=o.population.leaders[o.selected_leaders]
    leader=following_cohort(o,subscribed)
    row=merge(row,(subscribed_leader_return=leader.mean_return,
                   leader_follower_gap=leader.mean_return-row.followers_mean_return))
    row
end

function run_following_block(group,storage)
    base=only(filter(j->j.mode=="none",group))
    checkpoint=joinpath(storage.directory,base.job_id*".jls")
    if isfile(checkpoint)
        payload=deserialize(checkpoint)
        payload.ids==[j.job_id for j in group] || error("checkpoint job IDs differ")
        payload.digest==storage.metadata["source_digest"] || error("checkpoint source differs")
        return payload.rows
    end
    c=following_config(L=base.L,seed=base.seed,pre=base.pre,post=base.post,h=base.h)
    baseline=run_following(c,protocol_from_job(base);boundary=Symbol(base.boundary))
    rows=NamedTuple[]
    for j in group
        run=j.mode=="none" ? baseline :
            run_following(c,protocol_from_job(j);boundary=Symbol(j.boundary))
        push!(rows,following_row(j,run,baseline,base))
    end
    payload=(ids=[j.job_id for j in group],digest=storage.metadata["source_digest"],rows=rows)
    temporary=checkpoint*".tmp"
    serialize(temporary,payload); mv(temporary,checkpoint;force=true)
    rows
end

function run_following_campaign(stage; jobs=following_jobs(stage))
    storage=write_following_manifest(stage,jobs)
    block_keys=unique([(j.seed,j.h,j.boundary) for j in jobs])
    groups=[filter(j->(j.seed,j.h,j.boundary)==key,jobs) for key in block_keys]
    results=Vector{Any}(undef,length(groups))
    progress=Threads.Atomic{Int}(0)
    @info "Following campaign" stage jobs=length(jobs) blocks=length(groups)
    # A function boundary keeps checkpoint paths and row buffers task-local.
    Threads.@threads :dynamic for index in eachindex(groups)
        results[index]=run_following_block(groups[index],storage)
        completed=Threads.atomic_add!(progress,1)+1
        @info "Following blocks completed" completed total=length(groups)
    end
    rows=reduce(vcat,results)
    length(rows)==length(jobs) || error("incomplete campaign")
    length(unique([r.job_id for r in rows]))==length(jobs) || error("duplicate jobs")
    df=DataFrame(rows)
    temporary=storage.prefix*"-Summary.csv.tmp"
    CSV.write(temporary,df); mv(temporary,storage.prefix*"-Summary.csv";force=true)
    @info "Following campaign complete" stage rows=nrow(df)
    df
end

const FOLLOWING_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const FOLLOWING_DATA = joinpath(FOLLOWING_ROOT,"code","data")
const FOLLOWING_VERSION = "following-v1"

function following_config(; L=64, seed=1, pre=1000, post=3000, h=Inf,
                          impact=0.02, cash=1000.0, shares=10, kwargs...)
    build(MyModelBConfiguration, merge((number_of_rows=L,number_of_cols=L,
        steps=pre+post,seed=seed,minority_fraction=0.0,λ=impact,
        market_maker_capacity=h,cost_basis_rule=false,initial_cash=cash,
        initial_shares=shares), (;kwargs...)))
end

function run_following(config,p::FollowingProtocol; boundary=:hold, clearing=:legacy, kwargs...)
    o = FollowingObserver(config,p;kwargs...)
    r = simulate(config;minority_population=:interior,boundary_mode=boundary,
                 observer=o,snapshot_steps=[p.pre],clearing,verbose=false)
    check_following_accounting(o,r)
    (;observer=o,result=r)
end

function paired_following(config,p;boundary=:hold,clearing=:legacy,kwargs...)
    control_p = FollowingProtocol(mode=:none,pre=p.pre,replicate=p.replicate,
                                  pool_size=p.pool_size,lag=p.lag)
    control = run_following(config,control_p;boundary,clearing)
    treated = run_following(config,p;boundary,clearing,kwargs...)
    @assert control.observer.start_fingerprint == treated.observer.start_fingerprint
    @assert control.result.prices[1:p.pre+1] == treated.result.prices[1:p.pre+1]
    (;control,treated)
end
