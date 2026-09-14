# Shared, deterministic revision experiments. No plotting or package mutation.
using Random, Statistics, Distributions, DataFrames, CSV, Printf
for file in ("Types.jl", "Factory.jl", "Wolfram.jl", "Compute.jl", "Simulate.jl")
    include(joinpath(@__DIR__, "..", "src", file))
end
const REV_DATA = joinpath(@__DIR__, "..", "data")

function revision_config(; L=64, f=0.20, seed=1, post=3000, pre=1000,
                         h=100.0, impact=0.02, rule=19286)
    build(MyModelBConfiguration, (number_of_rows=L, number_of_cols=L,
          steps=pre+post, seed=seed, minority_fraction=f, λ=impact,
          rule_minor_index=rule, market_maker_capacity=h, cost_basis_rule=false))
end

# With a held boundary, financial variables cannot enter the lattice. This
# allocation-free kernel uses the production setup draws and rule tables; the
# tests compare every time point and the final grid against simulate().
function held_lattice(config; pre=1000, action=:rule)
    rng = Xoshiro(config.seed)
    coords = build_edge_coordinates(config.number_of_rows, config.number_of_cols,
                                    config.edge_fraction, rng)
    build_edge_bands(config.k, config.edge_band_spread, length(coords), rng)
    grid = build_initial_grid(config, rng)
    world, agents, major = _build_ca_components(config; rng, minority_population=:interior)
    mask = falses(size(grid))
    for agent in agents
        if agent.rule.index == config.rule_minor_index
            r,c = world.states[agent.index]
            mask[r,c] = true
        end
    end
    baseline = Tuple(major.rule[i] for i in 0:8)
    minor = build(MyTwoDimensionalTotalisticWolframRuleModel,
                  (index=config.rule_minor_index, colors=3, radius=4))
    activated = Tuple(minor.rule[i] for i in 0:8)
    next = copy(grid)
    sell = zeros(config.steps+1)
    sell[1] = compute_interior_fractions(grid)[3]
    initial = copy(grid)
    at_activation = copy(grid)
    L = config.number_of_rows
    for t in 1:config.steps
        if t == pre+1
            at_activation = copy(grid)
            action == :sell_pulse && (grid[mask] .= 2)
        end
        n_sell = 0
        @inbounds for c in 2:L-1, r in 2:L-1
            s = grid[r-1,c] + grid[r+1,c] + grid[r,c-1] + grid[r,c+1]
            table = t > pre && action == :rule && mask[r,c] ? activated : baseline
            state = table[s+1]
            next[r,c] = state
            n_sell += state == 2
        end
        grid, next = next, grid
        sell[t+1] = n_sell / (L-2)^2
    end
    (; sell_fraction=sell, initial, at_activation, final=grid)
end

function revision_metrics(result; pre=1000, post=length(result.sell_fraction)-pre-1)
    sell = @view result.sell_fraction[pre+2:pre+post+1]
    onset(q) = something(findfirst(>=(q), sell), 0)
    (; transitioned=maximum(sell)>=0.5, onset=onset(0.5), onset40=onset(0.4),
       onset60=onset(0.6), peak_sell=maximum(sell),
       final_sell_mean=mean(@view sell[max(1,end-499):end]),
       pre_sell_early=mean(@view result.sell_fraction[502:751]),
       pre_sell_late=mean(@view result.sell_fraction[752:1001]))
end

function financial_metrics(r; pre=1000)
    post = pre+1:length(r.log_returns)
    rejected = sum(r.market_maker_rejected_buys[post])+sum(r.market_maker_rejected_sells[post])
    eligible = rejected+sum(r.executed_buys[post])+sum(r.executed_sells[post])
    cash = r.total_cash .+ r.market_maker_cash
    shares = r.total_shares .+ r.market_maker_inventory
    @assert maximum(abs.(cash .- cash[1])) < max(1e-5,abs(cash[1])*1e-11)
    @assert all(==(shares[1]), shares)
    (; maximum_drawdown=compute_max_drawdown(r.prices[pre+1:end]),
       rejection_fraction=rejected/max(1,eligible),
       edge_sell_fraction=mean(r.edge_sell_count[post])/max(1,length(r.edge_coordinates)),
       edge_hold_fraction=mean(r.edge_hold_count[post])/max(1,length(r.edge_coordinates)),
       pre_deviation=r.ema_volatility[pre+1],
       post_deviation=mean(r.ema_volatility[pre+2:end]),
       pre_return_mean=mean(r.log_returns[751:1000]),
       pre_return_std=std(r.log_returns[751:1000]),
       pre_return_q01=quantile(r.log_returns[751:1000],0.01),
       pre_return_q99=quantile(r.log_returns[751:1000],0.99),
       pre_zero_returns=mean(iszero,r.log_returns[751:1000]))
end

function checkpoint_run(stem, jobs, run; version="v1")
    manifest=joinpath(REV_DATA,stem*"-Manifest.csv")
    buffer=IOBuffer();CSV.write(buffer,DataFrame(jobs));manifest_bytes=take!(buffer)
    isfile(manifest) ? (@assert read(manifest)==manifest_bytes) : write(manifest,manifest_bytes)
    dir = joinpath(REV_DATA, "$(stem)-$(version)-Checkpoints")
    mkpath(dir)
    paths = [joinpath(dir, "$(i).csv") for i in eachindex(jobs)]
    done = Threads.Atomic{Int}(0)
    Threads.@threads :dynamic for i in eachindex(jobs)
        path = paths[i]
        if isfile(path)
            cached = CSV.read(path, DataFrame)
            all(k -> all(==(getproperty(jobs[i], k)), cached[!, k]), keys(jobs[i])) ||
                error("checkpoint job mismatch at $(path); use a new campaign version")
        else
            rows = run(jobs[i])
            temp = tempname(dir)
            CSV.write(temp, DataFrame(rows isa NamedTuple ? [rows] : rows))
            mv(temp,path;force=true)
        end
        n = Threads.atomic_add!(done,1)+1
        n % 100 == 0 && @info stem completed=n total=length(jobs)
    end
    df = reduce(vcat, (CSV.read(p,DataFrame) for p in paths))
    CSV.write(joinpath(REV_DATA,"$(stem).csv"),df)
    df
end

include(joinpath(@__DIR__,"..","src","RebuildRuntime.jl"))
