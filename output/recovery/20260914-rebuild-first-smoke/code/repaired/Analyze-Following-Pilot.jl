include("../following/Analyze-Following.jl")

function analyze_reserve_following(stage="pilot")
    output=joinpath(FOLLOWING_ROOT,"output","repaired","following-reserve-v2-"*stage)
    data=CSV.read(joinpath(output,"Summary.csv"),DataFrame)
    manifest=CSV.read(joinpath(output,"Manifest.csv"),DataFrame)
    @assert nrow(data)==nrow(manifest) && length(unique(data.job_id))==nrow(data)
    @assert Set(data.job_id)==Set(manifest.job_id)
    treatment=data[data.mode.!="none",:]
    seeds=sort(unique(treatment.seed))
    resamples=rand(Xoshiro(9142026),1:length(seeds),length(seeds),2000)
    grouping=[:mode,:a,:K,:independent,:h,:boundary]
    metrics=(:followers_return_difference,:followers_drawdown_difference,:others_return_difference,
             :others_sell_difference,:drawdown_difference,:exit_cash_difference,
             :wind_followers_final_cash,:control_wind_followers_final_cash,
             :wind_followers_unsold_fraction,:source_active)
    rows=NamedTuple[]
    for g in groupby(treatment,grouping),metric in metrics
        stat=following_cluster_summary(g[!,metric],g.seed,seeds,resamples)
        push!(rows,merge(NamedTuple(g[1,grouping]),(metric=string(metric),),stat))
    end
    CSV.write(joinpath(output,"Grouped.csv"),DataFrame(rows))
    contrasts=NamedTuple[]
    for g in groupby(treatment,[:mode,:a,:h,:boundary])
        left=g[g.K.==1,:]
        right=g[g.mode[1]=="advice" ? g.independent : g.K.==16,:]
        isempty(right) && continue
        lookup=Dict((r.seed,r.replicate)=>r for r in eachrow(right))
        for metric in metrics
            delta=[r[metric]-lookup[(r.seed,r.replicate)][metric] for r in eachrow(left)]
            stat=following_cluster_summary(delta,left.seed,seeds,resamples)
            push!(contrasts,merge(NamedTuple(g[1,[:mode,:a,:h,:boundary]]),
                (metric=string(metric),comparison=g.mode[1]=="advice" ? "one_minus_independent" : "one_minus_sixteen"),stat))
        end
    end
    CSV.write(joinpath(output,"Contrasts.csv"),DataFrame(contrasts))
    open(joinpath(output,"report.md"),"w") do io
        println(io,"# Shared advice and copying under reserve clearing\n")
        println(io,"Completed $(nrow(data)) runs across $(length(seeds)) starting markets. This pilot uses new starting markets and two design replicates per market in its full form. It is exploratory. Pointwise intervals resample whole starting markets.\n")
        println(io,"Every treated run has an identical no-following prehistory. Liquidation uses the same prospective follower cohort in its own no-following endpoint. All traders request sales without new buys or outside funds, under the same reserve-clearing rule. Both arms sell every remaining share; proceeds can still differ.\n")
        println(io,"Columns report mean paired changes: marked follower returns, non-follower Sell decisions, market drawdown, and normalized follower cash after the matched liquidation. Exit is a simultaneous-exit stress scenario. No fees or external fundamental value are modeled.\n")
        println(io,"| Mechanism | Technical traders | Reserves/trader | Adoption | Sources | Follower return change (pp) | Non-follower Sell change (pp) | Price drawdown change (pp) | Exit cash change (pp) |\n|---|---|---:|---:|---|---:|---:|---:|---:|")
        for g in groupby(treatment,grouping)
            r=g[1,:]
            @printf(io,"| %s | %s | %g | %.0f%% | %s | %.3f | %.3f | %.3f | %.3f |\n",
                r.mode,r.boundary=="hold" ? "held" : "active",r.h,100r.a,
                r.independent ? "independent" : string(r.K),100mean(g.followers_return_difference),
                100mean(g.others_sell_difference),100mean(g.drawdown_difference),100mean(g.exit_cash_difference))
        end
        println(io,"\n`Grouped.csv` and `Contrasts.csv` contain pointwise intervals and all declared outcomes. The concentration comparisons are one source minus independent advice and one copied leader minus sixteen. The repaired pilot and old confirmation samples are not pooled. Differences from old results reflect the changed market mechanism as a whole, not an isolated estimate of arbitrage contamination.")
    end
    @info "Repaired following analysis complete" output rows=nrow(data)
end

if abspath(PROGRAM_FILE)==@__FILE__
    analyze_reserve_following(isempty(ARGS) ? "pilot" : only(ARGS))
end
