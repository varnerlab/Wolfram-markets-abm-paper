include("Transmission-Lib.jl")

function compute_transmission(smoke=false)
    jobs=transmission_jobs(smoke)
    stage=smoke ? "smoke" : "pilot"
    output=joinpath(FOLLOWING_ROOT,"output","repaired","transmission-v1-"*stage)
    directory=joinpath(output,"checkpoints");mkpath(directory)
    manifest=DataFrame(jobs);io=IOBuffer();CSV.write(io,manifest);bytes=take!(io)
    spec=joinpath(FOLLOWING_ROOT,"docs/superpowers/specs/2026-09-14-reserve-transmission-controls.md")
    metadata=Dict("version"=>"transmission-v1","source_digest"=>transmission_digest(),
        "manifest_digest"=>bytes2hex(sha256(bytes)),"specification_digest"=>bytes2hex(sha256(read(spec))),
        "julia_version"=>string(VERSION),
        "environment_digest"=>bytes2hex(sha256(read(joinpath(FOLLOWING_ROOT,"code/Manifest.toml")))))
    protocol=joinpath(output,"Protocol.toml")
    if isfile(protocol)
        saved=TOML.parsefile(protocol)
        all(get(saved,k,nothing)==v for (k,v) in metadata) || error("changed transmission campaign; use a new version")
        read(joinpath(output,"Manifest.csv"))==bytes || error("manifest changed")
    else
        metadata["created_utc"]=string(now(UTC))
        open(protocol,"w") do io;TOML.print(io,metadata);end
        write(joinpath(output,"Manifest.csv"),bytes)
    end
    groups=[collect(eachrow(g)) for g in groupby(manifest,[:seed,:replicate,:h,:boundary])]
    results=Vector{DataFrame}(undef,length(groups));done=Threads.Atomic{Int}(0)
    @info "Reserve transmission controls" stage runs=length(jobs) blocks=length(groups)
    Threads.@threads :dynamic for index in eachindex(groups)
        results[index]=transmission_block(groups[index],directory)
        completed=Threads.atomic_add!(done,1)+1
        completed%5==0 && @info "Transmission blocks saved" completed total=length(groups)
    end
    data=reduce(vcat,results)
    @assert nrow(data)==length(jobs) && Set(data.job_id)==Set(j.job_id for j in jobs)
    CSV.write(joinpath(output,"Summary.csv.tmp"),data)
    mv(joinpath(output,"Summary.csv.tmp"),joinpath(output,"Summary.csv");force=true)
    @info "Transmission campaign complete" stage runs=nrow(data) output
end

if abspath(PROGRAM_FILE)==@__FILE__
    isempty(ARGS) || ARGS==["smoke"] || error("only optional argument is smoke")
    compute_transmission(!isempty(ARGS))
end
