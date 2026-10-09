include("Include.jl")
using Test

@testset "Visibility leaves the raw signals intact" begin
    grid = [0 1 2; 2 2 0; 1 0 2]
    shares = [0 0 0; 1 2 0; 0 1 0]
    saved = copy(grid)
    visible = similar(grid)
    @test visible_signals!(visible, grid, shares, false) == grid
    @test visible_signals!(visible, grid, fill(1,3,3), true) == grid
    visible_signals!(visible, grid, shares, true)
    @test visible == [0 1 1; 2 2 0; 1 0 1]
    @test grid == saved
    shares[1,3] = 1
    @test visible_signals!(visible, grid, shares, true)[1,3] == 2
end

@testset "Last share settles before the subsequent observation" begin
    config = visibility_config(L=6, pre=1, post=1, initial_shares=1)
    books = build_agent_books(config)
    grid = fill(1,6,6); grid[3,3] = 2
    dealer = build_reserve_dealer(config, Int64(16))
    counts = execute_reserve_orders!(books, grid, Tuple{Int64,Int64}[], Int64[], 100.;
        market_maker=dealer)
    @test counts.executed_sells == 1
    @test books.shares[3,3] == 0
    @test grid[3,3] == 2
    @test visible_signals!(similar(grid),grid,books.shares,true)[3,3] == 1
    grid[3,3] = 0
    counts = execute_reserve_orders!(books, grid, Tuple{Int64,Int64}[], Int64[], counts.next_price;
        market_maker=dealer)
    @test counts.executed_buys == 1
    @test books.shares[3,3] == 1
    grid[3,3] = 2
    @test visible_signals!(similar(grid),grid,books.shares,true)[3,3] == 2
    @test dealer.cash ≈ dealer.initial_cash
    @test dealer.inventory == dealer.initial_inventory
end

@testset "Masked inputs use the lookup table and preserve edge intentions" begin
    config = visibility_config(L=6, pre=2, post=3)
    grid = fill(1,6,6); grid[1,3] = 2; grid[3,3] = 2
    books = build_agent_books(config); books.shares[1,3] = books.shares[3,3] = 0
    world, agents, major = _build_ca_components(config; rng=Xoshiro(1), minority_population=:interior)
    o = VisibilityObserver(6,5;mode=:inventory,start=3); o.books=books
    @test market_ca_step(o,2,grid,world,agents,major) == _ca_step(grid,world,agents,major)
    saved=copy(grid)
    masked=visible_signals!(similar(grid),grid,books.shares,true)
    expected=_ca_step(masked,world,agents,major)
    result=market_ca_step(o,3,grid,world,agents,major)
    @test result[2:5,2:5] == expected[2:5,2:5]
    @test result[1,:] == grid[1,:]
    @test grid == saved
end

@testset "Original recovery and exact four-branch histories" begin
    for boundary in (:hold,:endogenous), h in (1.0,100.0)
        config=visibility_config(L=12,pre=40,post=100,seed=45,h=h)
        baseline=simulate(config;clearing=:reserve,minority_population=:interior,
            boundary_mode=boundary,rule_activation_step=41,snapshot_steps=[40],verbose=false)
        runs=[checked_visibility_run(config;pre=40,mode,boundary,switched)
              for mode in (:original,:inventory), switched in (false,true)]
        original=runs[1,2].result
        for field in (:prices,:sell_fraction,:executed_sells,:executed_buys,
                      :total_cash,:total_shares,:market_maker_cash,:market_maker_inventory)
            @test getproperty(original,field) == getproperty(baseline,field)
        end
        @test original.frames[140] == baseline.frames[140]
        @test original.final_books.cash == baseline.final_books.cash
        @test original.final_books.shares == baseline.final_books.shares
        @test length(unique(x.observer.pre_state_sha256 for x in runs)) == 1
        @test length(unique(x.observer.first_execution_sha256 for x in runs)) == 1
        @test all(x.result.prices[1:42] == original.prices[1:42] for x in runs)
        @test all(x.result.sell_fraction[1:41] == original.sell_fraction[1:41] for x in runs)
    end
end

@testset "Recovery of an archived full manuscript run" begin
    config=visibility_config(seed=1)
    r=checked_visibility_run(config;pre=1000).result
    reference=joinpath(@__DIR__,"Reference.csv")
    if !isfile(reference)
        reference=joinpath(@__DIR__,"..","..","output","rebuilt","manuscript-reserve-v1",
                           "code","data","Rebuild-Execution-Ledger.csv")
    end
    ledger=CSV.read(reference,DataFrame)
    rows=filter(x->x.seed==1 && x.L==64 && x.steps==4000 && x.h==100 &&
        x.f==0.2 && x.rule==19286 && x.activation_step==1001 && x.boundary=="hold" &&
        x.action=="rule" && !x.resource_intervention,ledger)
    @test nrow(rows)>0
    @test all(==(array_digest(r.frames[4000])),rows.final_grid_sha256)
end
