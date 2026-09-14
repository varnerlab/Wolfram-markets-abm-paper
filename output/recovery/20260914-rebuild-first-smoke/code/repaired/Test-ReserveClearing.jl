include("../following/Following-Lib.jl")
using Test

function fixture(;h=10.,cash=10000.,shares=100)
    c=following_config(;L=8,pre=1,post=2,h,cash,shares,initial_condition=:all_hold)
    grid=fill(1,8,8); books=build_agent_books(c); dealer=build_reserve_dealer(c,36)
    ids=[LinearIndices(grid)[r,col] for col in 2:7 for r in 2:7]
    (;c,grid,books,dealer,ids,trace=MyOrderTrace(8,8))
end
function trade!(f,q;step=1,cost_basis_rule=false)
    fill!(f.grid,1)
    f.grid[f.ids[1:abs(q)]] .= q>0 ? 0 : 2
    execute_reserve_orders!(f.books,f.grid,Tuple{Int64,Int64}[],Int64[],100.;
        market_maker=f.dealer,trace=f.trace,seed=Int64(4),step=Int64(step),cost_basis_rule)
end

@testset "closed paths, holds, and order splitting" begin
    rng=Xoshiro(714)
    paths=[[1,-1],[-1,1],[10,-10],[0,5,0,-5,0],[8,4,-3,-9]]
    for _ in 1:100
        legs=rand(rng,1:8,10)
        push!(paths,shuffle(rng,vcat(legs,-legs)))
    end
    for path in paths
        f=fixture()
        cash0=sum(f.books.cash[f.ids]); dealer0=f.dealer.cash
        for (t,q) in enumerate(path)
            result=trade!(f,q;step=t)
            @test result.executed_buys-result.executed_sells==q
            @test f.dealer.cash*f.dealer.inventory≈dealer0*f.dealer.initial_inventory
        end
        @test f.dealer.inventory==f.dealer.initial_inventory
        @test f.dealer.cash≈dealer0 atol=1e-7
        @test sum(f.books.cash[f.ids])≈cash0 atol=1e-7
        @test sum(f.books.shares[f.ids])==length(f.ids)*f.c.initial_shares
    end
    for direction in (1,-1)
        block=fixture(); split=fixture()
        trade!(block,direction*20)
        for t in 1:20; trade!(split,direction;step=t); end
        @test block.dealer.inventory==split.dealer.inventory
        @test block.dealer.cash≈split.dealer.cash
        @test sum(block.books.cash[block.ids])≈sum(split.books.cash[split.ids])
    end
end

@testset "execution-price affordability and mixed orders" begin
    f=fixture(h=1.,cash=100.1)
    r=trade!(f,1)
    @test r.executed_buys==0 # Old quote is affordable; the actual unit price is not.
    f=fixture(h=1.,cash=99.)
    fill!(f.grid,1);f.grid[f.ids[1:10]].=2;f.grid[f.ids[11:15]].=0
    r=execute_reserve_orders!(f.books,f.grid,Tuple{Int64,Int64}[],Int64[],100.;
        market_maker=f.dealer,trace=f.trace)
    @test r.executed_buys==5 && r.executed_sells==10
    @test r.execution_price<99 # A buyer can afford the clearing price despite failing at 100.
    @test all(f.books.cash[f.ids].>=0)
    @test count(==(1),f.trace.filled)==5 && count(==(-1),f.trace.filled)==10
    f=fixture(h=1.)
    f.grid[f.ids[1:10]].=0;f.grid[f.ids[11:21]].=2
    f.books.avg_cost[f.ids[11:21]].=99.
    r=execute_reserve_orders!(f.books,f.grid,Tuple{Int64,Int64}[],Int64[],100.;
        market_maker=f.dealer,cost_basis_rule=true,trace=f.trace)
    @test r.execution_price==100 && r.executed_buys==r.executed_sells==10
    @test r.market_maker_rejected_sells==1
end

@testset "integer auction matches exhaustive feasible-quantity search" begin
    rng=Xoshiro(942)
    for _ in 1:300
        f=fixture(h=rand(rng,(0.1,1.,10.)))
        for id in f.ids
            f.grid[id]=rand(rng,0:2)
            f.books.cash[id]=rand(rng)*200
            f.books.shares[id]=rand(rng,0:2)
            f.books.avg_cost[id]=rand(rng)*150
        end
        restricted=rand(rng,Bool)
        C,Q=f.dealer.cash,f.dealer.inventory
        cash0=sum(f.books.cash[f.ids])+C
        shares0=sum(f.books.shares[f.ids])+Q
        function surplus(x)
            p=C/(Q-x)
            b=count(i->f.grid[i]==0 && f.books.cash[i]>=p,f.ids)
            s=count(i->f.grid[i]==2 && f.books.shares[i]>0 &&
                       (!restricted || p>f.books.avg_cost[i]),f.ids)
            b-s
        end
        d=sign(surplus(0))
        rangeq=d>0 ? (0:min(Q-1,36)) : (0:36)
        feasible=[m for m in rangeq if d*surplus(d*m)>=m]
        expected=d*maximum(feasible)
        r=execute_reserve_orders!(f.books,f.grid,Tuple{Int64,Int64}[],Int64[],100.;
            market_maker=f.dealer,cost_basis_rule=restricted,trace=f.trace)
        @test r.executed_buys-r.executed_sells==expected
        @test sum(f.books.cash[f.ids])+f.dealer.cash≈cash0
        @test sum(f.books.shares[f.ids])+f.dealer.inventory==shares0
        @test all(f.books.cash[f.ids].>=0) && all(f.books.shares[f.ids].>=0)
        @test f.dealer.cash*f.dealer.inventory≈C*Q
    end
end

@testset "scarcity, empty reserves, and no old drawdown ceiling" begin
    f=fixture(h=0.)
    @test trade!(f,5).executed_buys==0
    @test trade!(f,-5).executed_sells==0
    f.grid[f.ids[1]]=0;f.grid[f.ids[2]]=2
    r=execute_reserve_orders!(f.books,f.grid,Tuple{Int64,Int64}[],Int64[],100.;market_maker=f.dealer)
    @test r.executed_buys==r.executed_sells==1 && r.next_price==100
    f=fixture(h=1/36)
    @test trade!(f,1).executed_buys==0 # Last reserve share cannot be sold.
    f=fixture(h=1.)
    for t in 1:10
        r=trade!(f,-20;step=t)
        @test r.executed_sells==20 && f.dealer.cash>0
        @test r.next_price≈100*(36/f.dealer.inventory)^2
    end
    @test 1-f.dealer.cash/f.dealer.inventory/100>0.9
    @test_throws ArgumentError fixture(h=Inf)
    @test_throws ArgumentError fixture(h=0.00001)
end

@testset "full simulation, common prehistory, and held decision independence" begin
    for boundary in (:hold,:endogenous), h in (0.1,1.,100.)
        c=following_config(;L=12,pre=20,post=80,h,seed=2,minority_fraction=0.2)
        args=(;minority_population=:interior,rule_activation_step=21,
                boundary_mode=boundary,snapshot_steps=[20],verbose=false)
        repaired=simulate(c;args...,clearing=:reserve)
        baseline=simulate(c;args...,clearing=:reserve,activation_action=:sell_pulse)
        @test repaired.prices[1:21]==baseline.prices[1:21]
        @test repaired.frames[20]==baseline.frames[20]
        @test repaired.log_returns≈diff(log.(repaired.prices))
        @test all(repaired.prices.>0)
        @test maximum(abs.(repaired.total_cash.+repaired.market_maker_cash.-
                           (repaired.total_cash[1]+repaired.market_maker_cash[1])))<1e-6
        if boundary==:hold
            legacy=simulate(c;args...,clearing=:legacy)
            @test legacy.sell_fraction==repaired.sell_fraction
            @test legacy.frames[100]==repaired.frames[100]
        end
    end
    for mode in (:advice,:copy_filled)
        c=following_config(L=12,pre=20,post=80,h=1.)
        p=FollowingProtocol(;mode,adoption=0.4,pre=20)
        r=run_following(c,p;clearing=:reserve)
        @test check_following_accounting(r.observer,r.result)
    end
end
