include("Following-Lib.jl")
using Test

@testset "population and protocol" begin
    c=following_config(L=12,pre=10,post=20)
    p=FollowingProtocol(mode=:advice,adoption=0.4,sources=4,pre=10)
    pop=following_population(c,p)
    @test length(pop.followers)==40
    @test isempty(intersect(pop.followers,pop.leaders))
    @test sum(pop.weights)==1
    @test length(unique(pop.source_of))==4
    small=following_population(c,FollowingProtocol(mode=:advice,adoption=0.1,pre=10))
    @test pop.followers[1:10]==small.followers
    @test pop.leaders==small.leaders
    @test following_population(c,p).followers==pop.followers
    @test_throws ArgumentError following_population(c,FollowingProtocol(adoption=1.0,pre=10))
    @test_throws ArgumentError following_population(c,FollowingProtocol(lag=0,pre=10))
    @test_throws ArgumentError FollowingObserver(c,FollowingProtocol(mode=:replay_filled,pre=10))
end

@testset "order trace preserves clearing and distinguishes suppression and rejection" begin
    c=following_config(L=8,pre=1,post=2,h=0.0)
    books=build_agent_books(c); grid=fill(1,8,8)
    grid[2,2]=0; grid[2,3]=2; grid[2,4]=2; grid[2,5]=2
    books.shares[2,5]=0
    original=deepcopy(books); dealer=build_market_maker(c,36)
    trace=MyOrderTrace(8,8)
    a=execute_orders!(books,grid,Tuple{Int64,Int64}[],Int64[],100.;
                      cost_basis_rule=false,market_maker=dealer,seed=1,trace)
    b=execute_orders!(original,grid,Tuple{Int64,Int64}[],Int64[],100.;
                      cost_basis_rule=false,market_maker=build_market_maker(c,36),seed=1)
    @test a==b
    @test books.cash==original.cash && books.shares==original.shares
    @test trace.desired[2,5]==-1 && trace.eligible[2,5]==0 && trace.filled[2,5]==0
    @test count(==(-1),trace.eligible)==2 && count(==(-1),trace.filled)==1
    @test a.market_maker_rejected_sells==1
    fill!(grid,1)
    execute_orders!(books,grid,Tuple{Int64,Int64}[],Int64[],100.;trace)
    @test all(iszero,trace.desired) && all(iszero,trace.eligible) && all(iszero,trace.filled)
end

@testset "inactive observer and common warm-up" begin
    for boundary in (:hold,:endogenous), h in (0.0,0.1,Inf)
        c=following_config(L=12,pre=10,post=30,h=h)
        plain=simulate(c;boundary_mode=boundary,minority_population=:interior,
                       snapshot_steps=[10],verbose=false)
        observed=run_following(c,FollowingProtocol(pre=10);boundary)
        for field in fieldnames(MyModelBSimulationResult)
            field in (:config,:final_books,:final_market_maker) && continue
            @test isequal(getfield(plain,field),getfield(observed.result,field))
        end
        @test plain.final_books.cash==observed.result.final_books.cash
        @test plain.final_books.shares==observed.result.final_books.shares
        p=FollowingProtocol(mode=:advice,adoption=0.2,pre=10)
        pair=paired_following(c,p;boundary)
        @test pair.control.observer.start_fingerprint==pair.treated.observer.start_fingerprint
    end
end

@testset "copy timing, failed executions, and withdrawal" begin
    c=following_config(L=8,pre=2,post=5,seed=10)
    tape=zeros(Int8,4,7); tape[:,2].=1; tape[:,3].=-1; tape[:,5].=1
    p=FollowingProtocol(mode=:replay_filled,adoption=0.25,pre=2,pool_size=4)
    out=run_following(c,p;replay=tape,record_states=true)
    id=first(out.observer.population.followers)
    @test out.observer.state_tape[id,3]==0
    @test out.observer.state_tape[id,4]==2
    @test out.observer.state_tape[id,5]==1 # no stale repetition
    @test out.observer.state_tape[id,6]==0
    @test out.observer.trajectory[3,3]==1 && out.observer.trajectory[4,4]==1
    stop=FollowingProtocol(mode=:replay_filled,adoption=0.25,pre=2,pool_size=4,stop_after=2)
    stopped=run_following(c,stop;replay=tape,record_states=true)
    @test stopped.result.prices[1:5]==out.result.prices[1:5]
    @test !following_active(stop,5)
    previous=reshape(Int.(stopped.observer.state_tape[:,4]),8,8)
    major=build(MyTwoDimensionalTotalisticWolframRuleModel,(index=19280,colors=3,radius=4))
    restored=_ca_step(previous,nothing,nothing,major)
    @test stopped.observer.state_tape[:,5]==vec(restored)
    # A nonexecuting all-Sell leader emits no trade, but its intention can be copied.
    c2=following_config(L=8,pre=1,post=3,shares=0,initial_condition=:custom)
    grid=fill(2,8,8); grid[1,:].=1; grid[end,:].=1;grid[:,1].=1;grid[:,end].=1
    observations=Dict()
    for mode in (:copy_filled,:copy_desired)
        proto=FollowingProtocol(mode=mode,adoption=0.25,pre=1,pool_size=4)
        o=FollowingObserver(c2,proto;record_states=true)
        simulate(c2;initial_grid=copy(grid),observer=o,boundary_mode=:hold,verbose=false)
        observations[mode]=o
    end
    f=observations[:copy_filled]; d=observations[:copy_desired]
    @test all(f.state_tape[f.population.followers,2].==1)
    @test all(d.state_tape[d.population.followers,2].==2)
end

@testset "external held decisions ignore finance; transmission masking" begin
    outputs=[]
    for h in (0.0,0.1,Inf)
        c=following_config(L=12,pre=10,post=100,h=h)
        p=FollowingProtocol(mode=:advice,adoption=0.4,pre=10,sources=4)
        push!(outputs,run_following(c,p;record_states=true))
    end
    @test outputs[1].observer.state_tape==outputs[2].observer.state_tape==outputs[3].observer.state_tape
    c=following_config(L=12,pre=10,post=100,h=1.)
    p=FollowingProtocol(mode=:advice,adoption=0.4,pre=10)
    base=run_following(c,FollowingProtocol(pre=10);record_states=true)
    masked=run_following(c,p;masked_states=base.observer.state_tape,record_states=true)
    nonfollowers=setdiff(masked.observer.population.interior,masked.observer.population.followers)
    @test base.observer.state_tape[nonfollowers,:]==masked.observer.state_tape[nonfollowers,:]
end

@testset "wealth and cohort timing" begin
    c=following_config(L=8,pre=1,post=3,h=0.)
    o=FollowingObserver(c,FollowingProtocol(pre=1,pool_size=4))
    r=simulate(c;observer=o,boundary_mode=:hold,verbose=false)
    @test all(o.start_value[o.trader_ids].==2000.)
    @test all(o.final_value[o.trader_ids].==2000.)
    @test following_cohort(o,o.trader_ids).mean_return==0
    @test following_cohort(o,o.trader_ids).mean_drawdown==0
    @test check_following_accounting(o,r)
    id=first(o.population.interior)
    o.start_value[id]=100.; o.final_value[id]=80.; o.max_drawdown[id]=0.25
    @test following_cohort(o,[id]).mean_return≈-0.2
    @test following_cohort(o,[id]).mean_drawdown==0.25
    @test isnan(following_cohort(o,Int[]).mean_return)
    @test_throws ArgumentError simulate(c;observer=o,verbose=false)
end

@testset "independent advice retains trader-keyed streams" begin
    c=following_config(L=12,pre=5,post=30)
    a=run_following(c,FollowingProtocol(mode=:advice,independent=true,adoption=0.1,pre=5);record_states=true)
    b=run_following(c,FollowingProtocol(mode=:advice,independent=true,adoption=0.4,pre=5);record_states=true)
    ids=a.observer.population.followers
    @test a.observer.state_tape[ids,6:end]==b.observer.state_tape[ids,6:end]
    constant=run_following(c,FollowingProtocol(mode=:advice,adoption=0.4,pre=5,persistence=1.);record_states=true)
    states=constant.observer.state_tape[constant.observer.population.followers,6:end]
    @test all(==(states[1,1]),states)
end

@testset "manifest counts, threaded blocks, and checkpoint identity" begin
    @test length(following_jobs("pilot"))==3420
    @test length(following_jobs("confirmation"))==33900
    jobs=following_jobs("smoke")
    groups=[filter(j->j.seed==600001 && j.h==h && j.boundary==b,jobs)
            for h in (0.1,Inf) for b in ("hold","endogenous")]
    mktempdir() do directory
        serial=(directory=joinpath(directory,"serial"),metadata=Dict("source_digest"=>"test"))
        parallel=(directory=joinpath(directory,"parallel"),metadata=Dict("source_digest"=>"test"))
        mkpath(serial.directory);mkpath(parallel.directory)
        expected=[run_following_block(g,serial) for g in groups]
        actual=Vector{Any}(undef,length(groups))
        Threads.@threads for i in eachindex(groups)
            actual[i]=run_following_block(groups[i],parallel)
        end
        @test isequal(expected,actual)
        @test isequal(run_following_block(groups[1],parallel),expected[1])
        bad=(directory=parallel.directory,metadata=Dict("source_digest"=>"different"))
        @test_throws ErrorException run_following_block(groups[1],bad)
    end
end

println("Following tests passed")
