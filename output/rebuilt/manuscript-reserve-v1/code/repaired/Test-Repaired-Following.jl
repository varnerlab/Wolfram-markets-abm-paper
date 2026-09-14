include("Compute-Following-Pilot.jl")
using Test

@testset "paired reserve following and identical liquidation conditions" begin
    for mode in (:advice,:copy_filled),boundary in (:hold,:endogenous),h in (1.,100.)
        c=following_config(;L=12,pre=20,post=80,h)
        p=FollowingProtocol(;mode,pre=20,adoption=0.4)
        pair=paired_following(c,p;boundary,clearing=:reserve)
        @test pair.control.result.prices[1:21]==pair.treated.result.prices[1:21]
        for r in (pair.control.result,pair.treated.result)
            @test r.prices≈r.market_maker_cash./r.market_maker_inventory
        end
        before=deepcopy(pair.control.result.final_books.cash)
        exit=matched_reserve_exit(pair.treated,pair.control)
        @test exit.wind_followers_unsold_shares==exit.control_wind_followers_unsold_shares==0
        @test isfinite(exit.exit_cash_difference)
        @test before==pair.control.result.final_books.cash
    end
    @test length(reserve_following_jobs(false))==880
end

@testset "threaded pilot blocks reproduce serial rows and checkpoint identities" begin
    jobs=reserve_following_jobs(true)
    groups=[collect(eachrow(g)) for g in groupby(DataFrame(jobs),[:seed,:h,:boundary,:replicate])]
    mktempdir() do serial_dir
        serial=[reserve_following_block(g,serial_dir) for g in groups]
        mktempdir() do parallel_dir
            parallel=Vector{DataFrame}(undef,length(groups))
            Threads.@threads for i in eachindex(groups)
                parallel[i]=reserve_following_block(groups[i],parallel_dir)
            end
            for i in eachindex(groups)
                @test isequal(serial[i],parallel[i])
                @test isequal(parallel[i],reserve_following_block(groups[i],parallel_dir))
            end
            allrows=reduce(vcat,parallel)
            @test nrow(allrows)==length(jobs)==length(unique(allrows.job_id))
            @test Set(allrows.job_id)==Set(j.job_id for j in jobs)
        end
    end
end
