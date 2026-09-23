include("Include.jl")
using Test

function fixture(;h=10.0,cash=10000.0,shares=100)
    config=fee_config(;L=8,pre=1,post=2,h,cash,shares,initial_condition=:all_hold)
    grid=fill(1,8,8)
    ids=[LinearIndices(grid)[r,c] for c in 2:7 for r in 2:7]
    (;config,grid,ids,books=build_agent_books(config),
      dealer=build_reserve_dealer(config,Int64(36)),
      account=DealerFeeAccount(),trace=MyOrderTrace(8,8))
end
function clear!(f;rate=0.001,step=1,restricted=false)
    execute_fee_orders!(f.books,f.grid,Tuple{Int64,Int64}[],Int64[],100.0;
        market_maker=f.dealer,fee_rate=rate,fee_account=f.account,
        trace=f.trace,seed=Int64(4),step=Int64(step),cost_basis_rule=restricted)
end

@testset "fees on completed orders and separate reserves" begin
    for h in (0.0,1.0,100.0)
        f=fixture(;h)
        f.grid[f.ids[1]]=0; f.grid[f.ids[2]]=2
        initial=f.dealer.cash
        out=clear!(f)
        @test out.executed_buys==out.executed_sells==1
        @test out.next_price==100.0
        @test out.fee_income≈0.2
        @test f.account.cash≈0.2
        @test f.dealer.cash==initial
        @test f.books.cash[f.ids[1]]≈9899.9
        @test f.books.cash[f.ids[2]]≈10099.9
        @test f.books.avg_cost[f.ids[1]]≈(100*100+100.1)/101
        @test sum(f.books.cash[f.ids])+f.dealer.cash+f.account.cash≈360000+initial
    end
    f=fixture(h=0.0,cash=100.05)
    f.grid[f.ids[1]]=0; f.grid[f.ids[2]]=2
    out=clear!(f)
    @test out.executed_buys==out.executed_sells==0
    @test out.suppressed_buys==1 && out.market_maker_rejected_sells==1
    @test f.account.cash==0
    f=fixture(h=0.0,cash=100.1)
    f.grid[f.ids[1]]=0; f.grid[f.ids[2]]=2
    @test clear!(f).executed_buys==1
    @test f.books.cash[f.ids[1]]>=0
    for rate in (-0.01,1.0,Inf,NaN)
        @test_throws ArgumentError clear!(fixture();rate)
    end
end

@testset "isolated round trip pays dealer but restores trading reserves" begin
    f=fixture()
    W,Q=f.dealer.cash,f.dealer.inventory
    cash0=sum(f.books.cash[f.ids])
    f.grid[f.ids[1]]=0
    first=clear!(f)
    f.grid[f.ids[1]]=2
    second=clear!(f;step=2)
    @test first.executed_buys==second.executed_sells==1
    @test f.dealer.inventory==Q && f.dealer.cash≈W
    @test first.execution_price≈second.execution_price
    @test f.account.cash≈0.002*first.execution_price
    @test cash0-sum(f.books.cash[f.ids])≈f.account.cash atol=1e-7
end

@testset "fee auction agrees with exhaustive feasible quantities" begin
    rng=Xoshiro(9812)
    for _ in 1:300
        f=fixture(h=rand(rng,(0.0,0.1,1.0,10.0)))
        rate=rand(rng,(0.0005,0.001,0.0025,0.05))
        restricted=rand(rng,Bool)
        for id in f.ids
            f.grid[id]=rand(rng,0:2)
            f.books.cash[id]=rand(rng)*200
            f.books.shares[id]=rand(rng,0:2)
            f.books.avg_cost[id]=rand(rng)*150
        end
        W,Q=f.dealer.cash,f.dealer.inventory
        before_cash=sum(f.books.cash[f.ids])+W
        before_shares=sum(f.books.shares[f.ids])+Q
        function imbalance(x)
            p=Q==0 ? 100.0 : W/(Q-x)
            count(i->f.grid[i]==0 && f.books.cash[i]>=(1+rate)*p,f.ids)-
            count(i->f.grid[i]==2 && f.books.shares[i]>=1 &&
                (!restricted || (1-rate)*p>f.books.avg_cost[i]),f.ids)
        end
        d=sign(imbalance(0))
        sizes=Q==0 ? (0:0) : d>0 ? (0:min(Q-1,36)) : (0:36)
        expected=Q==0 ? 0 : d*maximum(k for k in sizes if d*imbalance(d*k)>=k)
        out=clear!(f;rate,restricted)
        @test out.executed_buys-out.executed_sells==expected
        @test sum(f.books.cash[f.ids])+f.dealer.cash+f.account.cash≈before_cash
        @test sum(f.books.shares[f.ids])+f.dealer.inventory==before_shares
        @test minimum(f.books.cash)>=0 && minimum(f.books.shares)>=0
        @test f.dealer.cash*f.dealer.inventory≈W*Q
        @test out.fee_income≈rate*out.execution_price*(out.executed_buys+out.executed_sells)
    end
end

@testset "zero fee equivalence, pairing, and held decisions" begin
    for h in (0.0,0.1,1.0,100.0),mode in (:endogenous,:hold)
        c=fee_config(;L=12,seed=7,pre=20,post=80,h)
        args=(;minority_population=:interior,boundary_mode=mode,
            rule_activation_step=21,snapshot_steps=[20],verbose=false)
        original=simulate(c;args...,clearing=:reserve)
        zero=simulate_with_fees(c;args...)
        for name in fieldnames(MyModelBSimulationResult)
            left=getfield(original,name);right=getfield(zero.result,name)
            if name==:final_books
                @test left.cash==right.cash && left.shares==right.shares && left.avg_cost==right.avg_cost
            elseif name==:final_market_maker
                @test all(getfield(left,n)==getfield(right,n) for n in fieldnames(MyMarketMaker))
            else
                @test left==right
            end
        end
        @test all(iszero,zero.fee_revenue)
        for fee_rate in (0.0005,0.001,0.0025)
            treated=simulate_with_fees(c;args...,fee_rate)
            control=simulate_with_fees(c;args...,rule_activation_step=101,fee_rate)
            @test treated.result.prices[1:22]==control.result.prices[1:22]
            @test treated.fee_revenue[1:22]==control.fee_revenue[1:22]
            @test treated.result.frames[20]==control.result.frames[20]
            @test treated.result.sell_fraction[1:21]==control.result.sell_fraction[1:21]
            if mode==:hold
                @test treated.result.sell_fraction==zero.result.sell_fraction
                @test treated.result.frames[100]==zero.result.frames[100]
            end
        end
    end
end

@testset "zero fee agrees with the frozen executed engine" begin
    # Separate namespace prevents the current executor hook from entering the oracle.
    reference=get(ENV,"FEE_REFERENCE_SRC",joinpath(@__DIR__,"..","..","output",
        "rebuilt","manuscript-reserve-v1","code","src"))
    oracle=Module(:FrozenFeeOracle)
    Core.eval(oracle,:(using Random, Statistics, DataFrames, ProgressMeter))
    Core.eval(oracle,:(include(path)=Base.include(@__MODULE__,path)))
    for name in ("Types.jl","Factory.jl","Wolfram.jl","Compute.jl","Simulate.jl")
        Base.include(oracle,joinpath(reference,name))
    end
    for h in (0.0,0.1,100.0),mode in (:hold,:endogenous)
        c=fee_config(;L=12,seed=3,pre=20,post=80,h)
        data=NamedTuple{fieldnames(MyModelBConfiguration)}(Tuple(getfield(c,n) for n in fieldnames(MyModelBConfiguration)))
        old_config=Base.invokelatest(oracle.build,oracle.MyModelBConfiguration,data)
        args=(;minority_population=:interior,boundary_mode=mode,
            rule_activation_step=21,snapshot_steps=[20],verbose=false)
        old=Base.invokelatest(oracle.simulate,old_config;args...,clearing=:reserve)
        current=simulate_with_fees(c;args...).result
        for name in (:prices,:sell_fraction,:frames,:total_cash,:total_shares,
                     :market_maker_cash,:market_maker_inventory,:executed_buys,:executed_sells)
            @test getproperty(old,name)==getproperty(current,name)
        end
    end
end
