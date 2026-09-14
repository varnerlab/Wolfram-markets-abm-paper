using Test
length(ARGS)==1 || error("provide the isolated study directory")
include(joinpath(abspath(ARGS[1]),"code/revision/Revision-Lib.jl"))

@testset "full reserve simulation agrees with the held decision kernel" begin
    for h in (0.,0.1,1.,100.),action in (:rule,:sell_pulse,:none)
        c=revision_config(L=12,seed=7,pre=20,post=80,h=h)
        actual=held_rebuild(c;pre=20,action)
        expected=held_lattice(c;pre=20,action)
        @test actual.sell_fraction==expected.sell_fraction
        @test actual.initial==expected.initial
        @test actual.at_activation==expected.at_activation
        @test actual.final==expected.final
        @test actual.financial_result.final_market_maker.max_inventory==typemax(Int64) || h==0
    end
end

@testset "fresh pairs and resource interventions" begin
    for boundary in (:hold,:endogenous),h in (0.1,100.)
        c=revision_config(L=12,seed=9,pre=20,post=80,h=h)
        control=simulate_repaired(c;minority_population=:interior,boundary_mode=boundary,
            rule_activation_step=101,snapshot_steps=[20],verbose=false)
        live=simulate_repaired(c;minority_population=:interior,boundary_mode=boundary,
            rule_activation_step=21,snapshot_steps=[20],verbose=false)
        @test live.prices[1:22]==control.prices[1:22]
        @test live.frames[20]==control.frames[20]
        intervention(t,books)=t==21 ? (books.cash .*=0.1;books.shares .*=10;nothing) : nothing
        resource=simulate_repaired(c;minority_population=:interior,boundary_mode=boundary,
            rule_activation_step=21,intervention,snapshot_steps=[20],verbose=false)
        @test resource.prices[1:21]==live.prices[1:21]
        @test resource.frames[20]==live.frames[20]
        boundary==:hold && @test resource.sell_fraction==live.sell_fraction
    end
    @test_throws ErrorException simulate_repaired(revision_config(L=12,pre=20,post=80,h=Inf);verbose=false)
end
