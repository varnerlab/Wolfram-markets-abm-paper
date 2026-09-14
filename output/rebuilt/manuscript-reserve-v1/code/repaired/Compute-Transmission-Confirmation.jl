# A new manifest and analysis plan around the frozen pilot simulator.
include("Transmission-Lib.jl")

const CONFIRMATION_SPEC = "docs/superpowers/specs/2026-09-14-reserve-transmission-confirmation.md"
const CONFIRMATION_FILES = [
    ["code/src/"*f for f in ("Types.jl","Factory.jl","Wolfram.jl","Compute.jl",
        "Simulate.jl","Following.jl","FollowingMetrics.jl","ReserveClearing.jl")]...,
    "code/following/Following-Lib.jl", "code/following/Following-Controls-Lib.jl",
    "code/repaired/Compute-Following-Pilot.jl", "code/repaired/Transmission-Lib.jl",
    "code/repaired/Compute-Transmission.jl", "code/repaired/Compute-Transmission-Confirmation.jl",
    "code/repaired/Transmission-Confirmation.py", "code/repaired/Test-Transmission-Confirmation.jl",
    "code/repaired/Test-Transmission-Confirmation.py", "code/repaired/Run-Transmission-Confirmation.sh",
    "code/Project.toml", "code/Manifest.toml",
    CONFIRMATION_SPEC,
]

confirmation_output(smoke=false) = joinpath(FOLLOWING_ROOT,"output/repaired",
    "transmission-confirmation-v1-"*(smoke ? "smoke" : "full"))

function confirmation_jobs(smoke=false)
    L,pre,post,seeds,reps=smoke ? (12,20,80,640001:640001,1:1) :
                                (64,1000,3000,641001:641050,1:2)
    stage="reserve-transmission-confirmation-v1-"*(smoke ? "smoke" : "full")
    jobs=NamedTuple[]
    for seed in seeds,replicate in reps,h in (1.,100.),boundary in ("hold","endogenous")
        base=(;stage,seed,replicate,h,boundary,L,pre,post)
        push!(jobs,following_job(;base...,mode="none",a=0.,K=1,diagnostic="control"))
        for a in (0.1,0.4),independent in (false,true),diagnostic in ("live","mask","withdrawal")
            push!(jobs,following_job(;base...,mode="advice",a,independent,
                K=independent ? 0 : 1,diagnostic,
                stop_after=diagnostic=="withdrawal" ? pre : post))
        end
    end
    jobs
end

function prepare_confirmation(smoke=false; output=confirmation_output(smoke))
    # This digest is the already verified pilot engine, including its runner.
    transmission_digest()=="b10677ec94a807918f4975812fcb550c3858e26f8aea6db252979f26bbddc7a5" ||
        error("pilot engine changed; a new design review and campaign version are required")
    jobs=confirmation_jobs(smoke); manifest=DataFrame(jobs)
    buffer=IOBuffer();CSV.write(buffer,manifest);bytes=take!(buffer)
    files=Dict(p=>bytes2hex(sha256(read(joinpath(FOLLOWING_ROOT,p)))) for p in CONFIRMATION_FILES)
    source=join((p*files[p] for p in sort(collect(keys(files)))),"\n")
    audit=joinpath(output,"Freshness.json"); environment=joinpath(output,"Environment.json")
    isfile(audit) && isfile(environment) || error("run Transmission-Confirmation.py prepare first")
    metadata=Dict("version"=>"transmission-confirmation-v1","stage"=>smoke ? "smoke" : "full",
        "source_digest"=>bytes2hex(sha256(source)),"manifest_digest"=>bytes2hex(sha256(bytes)),
        "freshness_digest"=>bytes2hex(sha256(read(audit))),
        "python_environment_digest"=>bytes2hex(sha256(read(environment))),
        "environment_digest"=>files["code/Manifest.toml"],"specification_digest"=>files[CONFIRMATION_SPEC],
        "pilot_engine_digest"=>transmission_digest(),"julia_version"=>string(VERSION),
        "runs"=>length(jobs),"blocks"=>count(j->j.mode=="none",jobs),
        "markets"=>length(unique(j.seed for j in jobs)),"bootstrap_resamples"=>10000,
        "bootstrap_seed"=>2026091401,"primary_interval_level"=>0.975)
    path=joinpath(output,"Protocol.toml")
    if isfile(path)
        saved=TOML.parsefile(path)
        all(get(saved,k,nothing)==v for (k,v) in metadata) || error("confirmation protocol changed; use a new version")
        read(joinpath(output,"Manifest.csv"))==bytes || error("confirmation manifest changed")
        TOML.parsefile(joinpath(output,"Frozen-files.toml"))["files"]==files || error("frozen files changed")
    else
        mkpath(joinpath(output,"checkpoints"))
        metadata["created_utc"]=string(now(UTC))
        write(joinpath(output,"Manifest.csv"),bytes)
        open(joinpath(output,"Frozen-files.toml"),"w") do io;TOML.print(io,Dict("files"=>files));end
        open(path,"w") do io;TOML.print(io,metadata);end
    end
    manifest
end

function compute_confirmation(smoke=false)
    output=confirmation_output(smoke);mkpath(output)
    lock=joinpath(output,".writer-lock")
    mkdir(lock) # An existing directory rejects concurrent writers, including on resume.
    try
        write(joinpath(lock,"owner.txt"),"pid=$(getpid()) started=$(now(UTC))\n")
        manifest=prepare_confirmation(smoke)
        directory=joinpath(output,"checkpoints")
        groups=[collect(eachrow(g)) for g in groupby(manifest,[:seed,:replicate,:h,:boundary])]
        results=Vector{DataFrame}(undef,length(groups));done=Threads.Atomic{Int}(0)
        @info "Fresh-market transmission confirmation" runs=nrow(manifest) blocks=length(groups) smoke
        Threads.@threads :dynamic for index in eachindex(groups)
            results[index]=transmission_block(groups[index],directory)
            completed=Threads.atomic_add!(done,1)+1
            completed%10==0 && @info "Confirmation blocks saved" completed total=length(groups)
        end
        data=reduce(vcat,results)
        @assert nrow(data)==nrow(manifest) && Set(data.job_id)==Set(manifest.job_id)
        CSV.write(joinpath(output,"Summary.csv.tmp"),data)
        mv(joinpath(output,"Summary.csv.tmp"),joinpath(output,"Summary.csv");force=true)
        @info "Confirmation simulations complete" runs=nrow(data) output
    finally
        rm(lock;recursive=true)
    end
end

if abspath(PROGRAM_FILE)==@__FILE__
    stage=isempty(ARGS) ? "full" : only(ARGS)
    stage in ("full","smoke","prepare","prepare-smoke") || error("use full, smoke, prepare, or prepare-smoke")
    startswith(stage,"prepare") ? prepare_confirmation(stage=="prepare-smoke") : compute_confirmation(stage=="smoke")
end
