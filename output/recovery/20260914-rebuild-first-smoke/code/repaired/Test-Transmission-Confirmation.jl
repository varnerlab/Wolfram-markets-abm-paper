include("Compute-Transmission-Confirmation.jl")
using Test

@testset "fresh confirmation preserves the pilot design" begin
    jobs=confirmation_jobs();pilot=transmission_jobs()
    @test length(jobs)==5200==length(unique(j.job_id for j in jobs))
    @test Set(j.seed for j in jobs)==Set(641001:641050)
    @test isempty(intersect(Set(j.seed for j in jobs),Set(j.seed for j in pilot)))
    @test Set(j.replicate for j in jobs)==Set(1:2)
    @test count(j->j.mode=="none",jobs)==400
    design(j)=Base.structdiff(j,(;job_id="",stage="",seed=0))
    @test Set(design(j) for j in jobs)==Set(design(j) for j in pilot)
    @test length(confirmation_jobs(true))==52
    @test Set(j.seed for j in confirmation_jobs(true))==Set([640001])
end

@testset "confirmation threading and checkpoint resume" begin
    jobs=DataFrame(confirmation_jobs(true))
    blocks=[collect(eachrow(g)) for g in groupby(jobs,[:seed,:replicate,:h,:boundary])]
    mktempdir() do directory
        serial_dir=joinpath(directory,"serial");mkpath(serial_dir)
        parallel_dir=joinpath(directory,"parallel");mkpath(parallel_dir)
        serial=[transmission_block(g,serial_dir) for g in blocks]
        threaded=Vector{DataFrame}(undef,length(blocks))
        Threads.@threads for i in eachindex(blocks)
            threaded[i]=transmission_block(blocks[i],parallel_dir)
        end
        for i in eachindex(blocks)
            @test isequal(serial[i],threaded[i])
            @test isequal(threaded[i],transmission_block(blocks[i],parallel_dir))
        end
    end
end

@testset "frozen campaign rejects altered metadata and manifests" begin
    mktempdir() do output
        write(joinpath(output,"Freshness.json"),"{}\n")
        write(joinpath(output,"Environment.json"),"{}\n")
        first=prepare_confirmation(true;output)
        @test isequal(first,prepare_confirmation(true;output))
        path=joinpath(output,"Protocol.toml");original=read(path,String)
        write(path,replace(original,"bootstrap_resamples = 10000"=>"bootstrap_resamples = 9999"))
        @test_throws ErrorException prepare_confirmation(true;output)
        write(path,original)
        open(joinpath(output,"Manifest.csv"),"a") do io;println(io);end
        @test_throws ErrorException prepare_confirmation(true;output)
    end
end
