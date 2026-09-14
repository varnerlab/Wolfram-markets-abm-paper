include("../following/Following-Controls-Lib.jl")

function matched_reserve_exit(treated,control)
    # Retain the same prospective cohorts in the no-following endpoint. The
    # control observer already measured every trader's starting wealth.
    observer=deepcopy(control.observer)
    observer.population=treated.observer.population
    tagged_control=(;observer,result=control.result)
    live=following_wind_down(treated;clearing=:reserve)
    base=following_wind_down(tagged_control;clearing=:reserve)
    @assert live.wind_followers_unsold_shares==0 && base.wind_followers_unsold_shares==0
    merge(live,prefixed(base,"control_"),
        (exit_cash_difference=live.wind_followers_final_cash-base.wind_followers_final_cash,))
end

function reserve_following_jobs(smoke=false)
    L,pre,post,seeds,reps=smoke ? (12,20,80,631001:631001,1:1) :
                                (64,1000,3000,631001:631010,1:2)
    jobs=NamedTuple[]
    stage=smoke ? "reserve-following-smoke" : "reserve-following-pilot"
    for seed in seeds,h in (1.,100.),boundary in ("hold","endogenous"),replicate in reps
        base=(;stage,seed,h,boundary,replicate,L,pre,post)
        push!(jobs,following_job(;base...,mode="none",a=0.,K=1))
        for a in (0.1,0.4)
            for mode in ("advice","copy_filled"),K in (1,16)
                # Smoke needs at least 16 followers for the many-source arm.
                smoke && a==0.1 && K==16 && continue
                push!(jobs,following_job(;base...,mode,a,K))
            end
            push!(jobs,following_job(;base...,mode="advice",a,K=0,independent=true))
        end
    end
    jobs
end

function reserve_following_block(group,dir)
    cj=only(filter(j->j.mode=="none",group))
    checkpoint=joinpath(dir,cj.job_id*".csv")
    if isfile(checkpoint)
        cached=CSV.read(checkpoint,DataFrame)
        @assert Set(cached.job_id)==Set(j.job_id for j in group)
        @assert nrow(cached)==length(group)
        return cached
    end
    c=following_config(L=cj.L,seed=cj.seed,pre=cj.pre,post=cj.post,h=cj.h)
    boundary=Symbol(cj.boundary)
    control=run_following(c,protocol_from_job(cj);boundary,clearing=:reserve)
    rows=NamedTuple[]
    for j in group
        run=j.mode=="none" ? control : run_following(c,protocol_from_job(j);boundary,clearing=:reserve)
        row=following_row(NamedTuple(j),run,control,NamedTuple(cj))
        exit=j.mode=="none" ? merge(blank_wind_down(),prefixed(blank_wind_down(),"control_"),
                                     (exit_cash_difference=NaN,)) : matched_reserve_exit(run,control)
        push!(rows,merge(row,exit))
    end
    data=DataFrame(rows)
    CSV.write(checkpoint*".tmp",data);mv(checkpoint*".tmp",checkpoint;force=true)
    data
end

function compute_reserve_following(smoke=false)
    jobs=reserve_following_jobs(smoke)
    stage=smoke ? "smoke" : "pilot"
    output=joinpath(FOLLOWING_ROOT,"output","repaired","following-reserve-v2-"*stage)
    dir=joinpath(output,"checkpoints");mkpath(dir)
    manifest=DataFrame(jobs);io=IOBuffer();CSV.write(io,manifest);bytes=take!(io)
    controls_source=read(joinpath(@__DIR__,"..","following","Following-Controls-Lib.jl"),String)
    metadata=Dict("version"=>"following-reserve-v2","julia_version"=>string(VERSION),
        "source_digest"=>bytes2hex(sha256(following_source_digest()*controls_source*read(@__FILE__,String))),
        "manifest_digest"=>bytes2hex(sha256(bytes)),
        "environment_digest"=>bytes2hex(sha256(read(joinpath(FOLLOWING_ROOT,"code","Manifest.toml")))))
    path=joinpath(output,"Protocol.toml")
    if isfile(path)
        saved=TOML.parsefile(path)
        all(get(saved,k,nothing)==v for (k,v) in metadata) || error("changed pilot; use a new version")
        read(joinpath(output,"Manifest.csv"))==bytes || error("changed pilot manifest")
    else
        metadata["created_utc"]=string(now(UTC))
        open(path,"w") do io;TOML.print(io,metadata);end
        write(joinpath(output,"Manifest.csv"),bytes)
    end
    groups=[collect(eachrow(g)) for g in groupby(manifest,[:seed,:h,:boundary,:replicate])]
    results=Vector{DataFrame}(undef,length(groups));done=Threads.Atomic{Int}(0)
    @info "Repaired following pilot" stage runs=length(jobs) blocks=length(groups)
    Threads.@threads :dynamic for index in eachindex(groups)
        results[index]=reserve_following_block(groups[index],dir)
        completed=Threads.atomic_add!(done,1)+1
        completed%5==0 && @info "Repaired following blocks saved" completed total=length(groups)
    end
    data=reduce(vcat,results)
    @assert nrow(data)==length(jobs) && Set(data.job_id)==Set(j.job_id for j in jobs)
    CSV.write(joinpath(output,"Summary.csv.tmp"),data)
    mv(joinpath(output,"Summary.csv.tmp"),joinpath(output,"Summary.csv");force=true)
    @info "Repaired following pilot complete" stage runs=nrow(data) output
end

if abspath(PROGRAM_FILE)==@__FILE__
    isempty(ARGS) || ARGS==["smoke"] || error("only optional argument is smoke")
    compute_reserve_following(!isempty(ARGS))
end
