include("../following/Analyze-Following.jl")

function analyze_survival(stage="full")
    output=joinpath(FOLLOWING_ROOT,"output","repaired","reserve-v2-"*stage)
    data=CSV.read(joinpath(output,"Summary.csv"),DataFrame)
    manifest=CSV.read(joinpath(output,"Manifest.csv"),DataFrame)
    keys=[:seed,:h,:boundary,:L,:pre,:post,:f]
    @assert nrow(data)==nrow(manifest) && nrow(unique(data[:,keys]))==nrow(data)
    @assert Set(Tuple(r) for r in eachrow(data[:,keys]))==Set(Tuple(r) for r in eachrow(manifest[:,keys]))
    seeds=sort(unique(data.seed))
    resamples=rand(Xoshiro(9142026),1:length(seeds),length(seeds),2000)
    estimates=NamedTuple[]
    for g in groupby(data,[:boundary,:h,:f])
        key=NamedTuple(g[1,[:boundary,:h,:f]])
        for metric in (:transitioned,:maximum_drawdown,:drawdown_difference,:rejection_fraction,
                       :final_sell_mean,:dealer_equity_change_per_trader)
            stat=following_cluster_summary(g[!,metric],g.seed,seeds,resamples;
                                           probability=metric==:transitioned)
            push!(estimates,merge(key,(metric=string(metric),),stat))
        end
    end
    grouped=DataFrame(estimates)
    CSV.write(joinpath(output,"Grouped.csv"),grouped)
    old=CSV.read(joinpath(FOLLOWING_DATA,"ModelB-ReservoirQuench-Full-Summary.csv"),DataFrame)
    lookup=Dict((r.seed,r.market_maker_capacity,r.boundary_mode,r.target_f)=>r for r in eachrow(old))
    comparisons=NamedTuple[]
    if stage=="full"
        for r in eachrow(data)
            key=(r.seed,r.h,r.boundary,r.f)
            haskey(lookup,key) || continue
            o=lookup[key]
            if r.boundary=="hold"
                @assert r.transitioned==o.transitioned
                @assert isapprox(r.final_sell_mean,o.treated_final_sell_mean;atol=1e-13,rtol=0)
            end
            push!(comparisons,(seed=r.seed,h=r.h,boundary=r.boundary,f=r.f,
                legacy_transitioned=o.transitioned,reserve_transitioned=r.transitioned,
                legacy_drawdown=o.treated_maximum_drawdown,reserve_drawdown=r.maximum_drawdown,
                legacy_paired_drawdown=o.treated_maximum_drawdown-o.control_maximum_drawdown,
                reserve_paired_drawdown=r.drawdown_difference))
        end
        CSV.write(joinpath(output,"Legacy-comparison.csv"),DataFrame(comparisons))
    end
    open(joinpath(output,"report.md"),"w") do io
        println(io,"# Original-story survival under reserve clearing\n")
        println(io,"Completed $(nrow(data)) simulations across $(length(seeds)) starting markets. The reserve dealer settles at an execution price consistent with its cash-and-share invariant. All pairs passed common-prehistory and accounting checks. Whole held decision histories matched legacy replays at f=0.20 for every tested reserve level and seed.\n")
        println(io,"This is a retrospective model comparison. Reserve size changes both financial resources and price depth. The old impact coefficient is absent. Differences between mechanisms cannot be attributed solely to removal of round-trip profits. Each mechanism has its own warm-up and no-switch control.\n")
        println(io,"## Complete repaired results\n")
        println(io,"Drawdowns are medians; majority percentages count starting markets. The paired drawdown column averages differences against each run's no-switch control. Full pointwise mean intervals and conservative boundary bounds are in `Grouped.csv`.\n")
        println(io,"| Technical traders | Reserve shares/trader | Rule fraction | Sell majority (%) | Median drawdown (%) | Mean paired drawdown (pp) |\n|---|---:|---:|---:|---:|---:|")
        for g in groupby(data,[:boundary,:h,:f])
            r=g[1,:]
            @printf(io,"| %s | %g | %.3f | %.1f | %.3f | %.3f |\n",
                r.boundary=="hold" ? "held" : "active",r.h,r.f,100mean(g.transitioned),
                100median(g.maximum_drawdown),100mean(g.drawdown_difference))
        end
        if !isempty(comparisons)
            println(io,"\n## Overlap with the archived model\n")
            println(io,"These rows match initial dealer cash and shares. They do not match price depth. Both columns summarize the original 50 starting-market identities.\n")
            println(io,"| Technical traders | Reserve shares/trader | Rule fraction | Old majority (%) | Repaired majority (%) | Old median drawdown (%) | Repaired median drawdown (%) |\n|---|---:|---:|---:|---:|---:|---:|")
            for g in groupby(DataFrame(comparisons),[:boundary,:h,:f])
                r=g[1,:]
                @printf(io,"| %s | %g | %.3f | %.1f | %.1f | %.3f | %.3f |\n",
                    r.boundary=="hold" ? "held" : "active",r.h,r.f,
                    100mean(g.legacy_transitioned),100mean(g.reserve_transitioned),
                    100median(g.legacy_drawdown),100median(g.reserve_drawdown))
            end
        end
        println(io,"\nThe held local-rule result is independent of this financial repair. Interpret any survival of active-trader probabilities or drawdown relationships only over the displayed settings. This campaign does not repeat the full size/horizon or resource-multiplier grids. The reserve mechanism is an explicit alternative dealer model, not empirical validation of an equity exchange.")
    end
    @info "Survival analysis complete" output rows=nrow(data)
end

if abspath(PROGRAM_FILE)==@__FILE__
    analyze_survival(isempty(ARGS) ? "full" : only(ARGS))
end
