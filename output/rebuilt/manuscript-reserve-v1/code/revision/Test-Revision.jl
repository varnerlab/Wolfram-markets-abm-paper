include("Revision-Lib.jl")
using Test
@testset "Revision intervention contracts" begin
    for rule in (19286,19283,19262), action in (:rule,:sell_pulse,:none), seed in 1:2
        c=revision_config(L=12,seed=seed,pre=20,post=60,rule=rule)
        fast=held_lattice(c;pre=20,action)
        full=simulate(c;minority_population=:interior,rule_activation_step=action==:none ? 81 : 21,
                      activation_action=action==:sell_pulse ? :sell_pulse : :rule,
                      boundary_mode=:hold,snapshot_steps=[20],verbose=false)
        @test fast.sell_fraction == full.sell_fraction
        @test fast.at_activation == full.frames[20]
        @test fast.final == full.frames[80]
    end
    c=revision_config(L=12,pre=20,post=60)
    base=simulate(c;minority_population=:interior,rule_activation_step=21,
                  snapshot_steps=[20],verbose=false)
    frozen=simulate(c;minority_population=:interior,rule_activation_step=21,
                    fixed_band_step=21,snapshot_steps=[20],verbose=false)
    @test base.frames[20] == frozen.frames[20]
    @test base.prices[1:22] == frozen.prices[1:22]
    @test all(isapprox.(frozen.band_upper[22:end].-frozen.ema_price[22:end],
                       c.k*base.ema_volatility[21];atol=1e-12))
    @test_throws ArgumentError simulate(c;activation_action=:sell_pulse,verbose=false)
    @test_throws ArgumentError simulate(c;fixed_band_step=0,verbose=false)
    # A pulse changes orders immediately, whereas rule activation leaves the
    # first quote unchanged. Both retain the same realized prehistory.
    pulse=simulate(c;minority_population=:interior,rule_activation_step=21,
                   activation_action=:sell_pulse,snapshot_steps=[20],verbose=false)
    @test pulse.frames[20] == base.frames[20]
    @test pulse.prices[1:21] == base.prices[1:21]
end
