include("Following-Controls-Lib.jl")
using Test

@testset "simultaneous exit conserves holdings and reports trapped shares" begin
    p=FollowingProtocol(pre=1,adoption=0.2,pool_size=4)
    finite=following_config(L=8,pre=1,post=3,h=0.,initial_condition=:all_hold)
    a=following_wind_down(run_following(finite,p))
    @test a.wind_followers_unsold_shares==10
    @test a.wind_followers_unsold_fraction==1
    @test a.wind_followers_cash_proceeds==0
    @test a.wind_price==100
    unlimited=following_config(L=8,pre=1,post=3,h=Inf,initial_condition=:all_hold)
    b=following_wind_down(run_following(unlimited,p))
    @test b.wind_followers_unsold_shares==0
    @test b.wind_followers_unsold_fraction==0
    @test b.wind_price≈100exp(-0.2)
    @test b.wind_followers_cash_proceeds≈sum(100exp(-0.02k) for k in 0:9)/2000
end

@testset "diagnostic manifest covers common source controls" begin
    jobs=following_diagnostic_jobs("diagnostic-smoke")
    @test length(jobs)==180
    @test length(unique(j.job_id for j in jobs))==180
    for j in jobs
        j.mode in ("replay_filled","replay_desired") || continue
        @test any(k->k.mode=="none" && k.seed==j.seed && k.replicate==j.replicate &&
                     k.boundary==j.boundary && k.h==1.,jobs)
    end
end
