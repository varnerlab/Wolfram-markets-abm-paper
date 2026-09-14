include("Compute-Transmission.jl")
using Test

@testset "mask keeps submitted advice orders and removes held local transmission" begin
    for boundary in (:hold,:endogenous),h in (1.,100.),independent in (false,true)
        c=following_config(L=12,pre=20,post=80,h=h)
        p=FollowingProtocol(mode=:advice,adoption=0.4,pre=20,independent=independent)
        control=run_following(c,FollowingProtocol(pre=20);boundary,clearing=:reserve,record_states=true)
        live=run_following(c,p;boundary,clearing=:reserve,record_states=true)
        mask=run_following(c,p;boundary,clearing=:reserve,record_states=true,
                           masked_states=control.observer.state_tape)
        followers=live.observer.population.followers
        @test live.observer.state_tape[followers,:]==mask.observer.state_tape[followers,:]
        @test live.observer.start_fingerprint==mask.observer.start_fingerprint==control.observer.start_fingerprint
        if boundary==:hold
            others=setdiff(live.observer.population.interior,followers)
            @test mask.observer.state_tape[others,:]==control.observer.state_tape[others,:]
        end
        stop=FollowingProtocol(mode=:advice,adoption=0.4,pre=20,independent=independent,stop_after=20)
        withdrawal=run_following(c,stop;boundary,clearing=:reserve,record_states=true)
        @test withdrawal.observer.state_tape[:,1:40]==live.observer.state_tape[:,1:40]
        @test withdrawal.result.prices[1:41]==live.result.prices[1:41]
        @test all(isnan,withdrawal.observer.trajectory[41:end,6])
        off=FollowingProtocol(mode=:advice,adoption=0.4,pre=20,independent=independent,stop_after=0)
        null=run_following(c,off;boundary,clearing=:reserve,record_states=true)
        @test null.observer.state_tape==control.observer.state_tape
        @test null.result.prices==control.result.prices
        @test null.result.final_books.cash==control.result.final_books.cash
    end
end

@testset "detailed exit matches prior liquidation and accounts for every trader" begin
    for boundary in (:hold,:endogenous),h in (1.,100.)
        c=following_config(L=12,pre=20,post=80,h=h)
        p=FollowingProtocol(mode=:advice,adoption=0.4,pre=20)
        pair=paired_following(c,p;boundary,clearing=:reserve)
        run=pair.treated
        before=deepcopy(run.result.final_books.cash)
        detailed=reserve_exit_ledger(run);base=reserve_exit_ledger(pair.control)
        old=following_wind_down(run;clearing=:reserve)
        @test detailed.price==old.wind_price
        @test detailed.rounds==old.wind_rounds
        for (name,ids) in pairs((followers=run.observer.population.followers,
            leaders=run.observer.population.leaders,others=run.observer.population.others))
            @test mean(detailed.books.cash[ids]./run.observer.start_value[ids])==
                  old[Symbol("wind_",name,"_final_cash")]
        end
        @test detailed.books.shares[run.observer.trader_ids]==zeros(Int,length(run.observer.trader_ids))
        @test run.result.final_books.cash==before
        m=transmission_exit_metrics(run,pair.control,detailed,base)
        old_pair=matched_reserve_exit(run,pair.control)
        @test m.exit_cash_difference==old_pair.exit_cash_difference
        @test abs(m.follower_cash_difference+m.remaining_cash_difference+m.dealer_cash_difference)<1e-6
        @test abs(m.dealer_cash_difference)<1e-6
    end
end

@testset "complete controls reproduce serial execution and checkpoint resume" begin
    @test length(transmission_jobs(false))==1040
    jobs=transmission_jobs(true)
    @test length(jobs)==52==length(unique(j.job_id for j in jobs))
    groups=[collect(eachrow(g)) for g in groupby(DataFrame(jobs),[:seed,:replicate,:h,:boundary])]
    mktempdir() do serial_dir
        serial=[transmission_block(g,serial_dir) for g in groups]
        mktempdir() do threaded_dir
            threaded=Vector{DataFrame}(undef,length(groups))
            Threads.@threads for i in eachindex(groups)
                threaded[i]=transmission_block(groups[i],threaded_dir)
            end
            for i in eachindex(groups)
                @test isequal(serial[i],threaded[i])
                @test isequal(threaded[i],transmission_block(groups[i],threaded_dir))
            end
            all_rows=reduce(vcat,threaded)
            @test nrow(all_rows)==52 && length(unique(all_rows.job_id))==52
            @test Set(all_rows.job_id)==Set(j.job_id for j in jobs)
        end
    end
end
