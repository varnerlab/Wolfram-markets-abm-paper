# Check that distributing independent markets by either scheduler is exact.
using Test
const STUDY=abspath(ARGS[1])
include(joinpath(STUDY,"code","revision","Revision-Lib.jl"))
jobs=[(L=L,h=h,boundary=boundary,seed=seed) for L in (16,32)
      for h in (.1,100.) for boundary in (:hold,:endogenous) for seed in (701,702)]
function run_job(j)
    c=revision_config(;L=j.L,h=j.h,seed=j.seed,post=120,f=.18)
    simulate(c;clearing=:reserve,boundary_mode=j.boundary,
        minority_population=:interior,rule_activation_step=1001,
        snapshot_steps=[1000],verbose=false)
end
reference=[run_job(j) for j in jobs]
dynamic=Vector{MyModelBSimulationResult}(undef,length(jobs))
greedy=similar(dynamic)
Threads.@threads :dynamic for i in eachindex(jobs)
    dynamic[i]=run_job(jobs[i])
end
Threads.@threads :greedy for i in eachindex(jobs)
    greedy[i]=run_job(jobs[i])
end
@testset "serial, dynamic, and greedy schedules give identical full markets" begin
    for i in eachindex(jobs), observed in (dynamic[i],greedy[i])
        expected=reference[i]
        for field in (:prices,:sell_fraction,:executed_buys,:executed_sells,
                      :suppressed_buys,:suppressed_sells,:market_maker_rejected_buys,
                      :market_maker_rejected_sells,:market_maker_cash,:market_maker_inventory,
                      :total_cash,:total_shares)
            @test getproperty(observed,field)==getproperty(expected,field)
        end
        @test observed.frames[1120]==expected.frames[1120]
        @test observed.final_books.cash==expected.final_books.cash
        @test observed.final_books.shares==expected.final_books.shares
    end
end
