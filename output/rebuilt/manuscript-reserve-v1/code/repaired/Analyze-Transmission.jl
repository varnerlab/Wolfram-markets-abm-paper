include("../following/Analyze-Following.jl")

const TRANSMISSION_METRICS=(
    :exit_cash_difference,:followers_return_difference,:others_sell_difference,
    :after_withdrawal_others_sell_difference,:late_others_sell_difference,
    :drawdown_difference,:remaining_exit_cash_difference,:follower_cash_difference,
    :remaining_cash_difference,:dealer_cash_difference,:total_trader_cash_difference,
)

function analyze_transmission(stage="pilot")
    output=joinpath(FOLLOWING_ROOT,"output","repaired","transmission-v1-"*stage)
    data=CSV.read(joinpath(output,"Summary.csv"),DataFrame)
    manifest=CSV.read(joinpath(output,"Manifest.csv"),DataFrame)
    @assert nrow(data)==nrow(manifest) && length(unique(data.job_id))==nrow(data)
    @assert Set(data.job_id)==Set(manifest.job_id)
    treatment=data[data.mode.!="none",:]
    @assert all(treatment.same_advice_orders) && all(treatment.held_mask_identity)
    @assert all(treatment.withdrawal_prefix_identity)
    @assert all(iszero,data.exit_unsold_shares) && all(iszero,data.control_exit_unsold_shares)
    seeds=sort(unique(data.seed))
    resamples=rand(Xoshiro(91420261),1:length(seeds),length(seeds),2000)
    grouped_rows=NamedTuple[]
    group_keys=[:a,:independent,:h,:boundary,:diagnostic]
    for g in groupby(treatment,group_keys),metric in TRANSMISSION_METRICS
        stat=following_cluster_summary(g[!,metric],g.seed,seeds,resamples)
        push!(grouped_rows,merge(NamedTuple(g[1,group_keys]),(metric=string(metric),),stat))
    end
    grouped=DataFrame(grouped_rows)
    contrasts=NamedTuple[]
    for g in groupby(treatment,[:a,:independent,:h,:boundary])
        arms=Dict(d=>g[g.diagnostic.==d,:] for d in ("live","mask","withdrawal"))
        for (name,left_name,right_name) in (("continuous_minus_mask","live","mask"),
                                          ("withdrawal_minus_continuous","withdrawal","live"))
            left=arms[left_name];right=Dict((r.seed,r.replicate)=>r for r in eachrow(arms[right_name]))
            @assert length(right)==nrow(left)
            for metric in TRANSMISSION_METRICS
                delta=[r[metric]-right[(r.seed,r.replicate)][metric] for r in eachrow(left)]
                stat=following_cluster_summary(delta,left.seed,seeds,resamples)
                push!(contrasts,merge(NamedTuple(g[1,[:a,:independent,:h,:boundary]]),
                    (comparison=name,metric=string(metric)),stat))
            end
        end
    end
    source_rows=NamedTuple[]
    for g in groupby(treatment,[:a,:h,:boundary,:diagnostic])
        left=g[.!g.independent,:];right=Dict((r.seed,r.replicate)=>r for r in eachrow(g[g.independent,:]))
        @assert length(right)==nrow(left)
        for metric in TRANSMISSION_METRICS
            delta=[r[metric]-right[(r.seed,r.replicate)][metric] for r in eachrow(left)]
            stat=following_cluster_summary(delta,left.seed,seeds,resamples)
            push!(source_rows,merge(NamedTuple(g[1,[:a,:h,:boundary,:diagnostic]]),
                (comparison="shared_minus_independent",metric=string(metric)),stat))
        end
    end
    # Every continuous-advice treatment is also an exact replay of the pilot.
    replay_rows=NamedTuple[]
    if stage=="pilot"
        old=CSV.read(joinpath(FOLLOWING_ROOT,"output/repaired/following-reserve-v2-pilot/Summary.csv"),DataFrame)
        key(r)=(r.seed,r.replicate,r.h,r.boundary,r.a,r.independent)
        lookup=Dict(key(r)=>r for r in eachrow(old[old.mode.=="advice",:]) if r.K==1 || r.independent)
        shared=setdiff(intersect(names(data),names(old)),["job_id","stage","diagnostic","control_id"])
        for row in eachrow(treatment[treatment.diagnostic.=="live",:])
            previous=lookup[key(row)]
            for col in shared
                isequal(row[col],previous[col]) || error("pilot replay mismatch $(row.job_id) $col")
            end
            push!(replay_rows,(job_id=row.job_id,pilot_job_id=previous.job_id,matching_columns=length(shared)))
        end
        @assert length(replay_rows)==320
        CSV.write(joinpath(output,"Pilot-replay.csv"),DataFrame(replay_rows))
    end
    CSV.write(joinpath(output,"Grouped.csv"),grouped)
    contrast=DataFrame(contrasts)
    CSV.write(joinpath(output,"Contrasts.csv"),contrast)
    CSV.write(joinpath(output,"Source-contrasts.csv"),DataFrame(source_rows))
    report_transmission(output,data,treatment,grouped,contrast,length(seeds),length(replay_rows))
    metadata=Dict("created_utc"=>string(now(UTC)),
        "analysis_digest"=>bytes2hex(sha256(read(@__FILE__,String)*read(joinpath(@__DIR__,"../following/Analyze-Following.jl"),String))),
        "summary_digest"=>bytes2hex(sha256(read(joinpath(output,"Summary.csv")))))
    open(joinpath(output,"Analysis.toml"),"w") do io;TOML.print(io,metadata);end
    @info "Transmission analysis complete" stage runs=nrow(data) pilot_replays=length(replay_rows) output
end

function report_transmission(output,data,treatment,grouped,contrasts,nseeds,replays)
    open(joinpath(output,"report.md"),"w") do io
        println(io,"# Does local transmission raise follower cash gains?\n")
        println(io,"Completed $(nrow(data)) runs across $nseeds starting markets. The full campaign follows up the same ten-market repaired pilot; it is exploratory. Every arm has a matched no-following prehistory and identical liquidation rules. $replays continuous-advice rows reproduce the earlier pilot exactly.\n")
        masks=treatment[(treatment.diagnostic.=="mask").&(treatment.boundary.=="hold"),:]
        println(io,"All $(nrow(masks)) held masking runs restored every non-follower's decision history exactly, while keeping follower submitted orders identical to continuous advice. Active technical traders retain the route through prices, so masking removes only the direct local influence in that condition. Withdrawal agrees with continuous advice through the last advised step, then stops advice without resetting the market.\n")
        println(io,"## Primary setting and reserve comparison\n")
        println(io,"The primary setting is 40% adoption of one shared source, h=100, technical traders held. The following table also displays h=1 and active technical traders. Values are mean differences in normalized follower cash against the same cohort's no-following control, after all traders liquidate. Intervals are pointwise 95% intervals from 2,000 whole-market bootstrap resamples.\n")
        println(io,"| Technical traders | Reserve shares/trader | Intervention | Follower exit-cash difference (pp; 95% interval) | Non-follower Sell difference (pp) | Final-window Sell difference (pp) |\n|---|---:|---|---:|---:|---:|")
        for g in groupby(treatment[(treatment.a.==0.4).&.!treatment.independent,:],[:h,:boundary,:diagnostic])
            r=g[1,:]
            s=only(eachrow(grouped[(grouped.a.==0.4).&.!grouped.independent.&(grouped.h.==r.h).&
                (grouped.boundary.==r.boundary).&(grouped.diagnostic.==r.diagnostic).&
                (grouped.metric.=="exit_cash_difference"),:]))
            @printf(io,"| %s | %g | %s | %.3f [%.3f, %.3f] | %.3f | %.3f |\n",
                r.boundary=="hold" ? "held" : "active",r.h,r.diagnostic,100s.estimate,
                100s.lower,100s.upper,100mean(g.others_sell_difference),100mean(g.late_others_sell_difference))
        end
        println(io,"\n## Mechanism contrasts\n")
        println(io,"Continuous minus masked advice measures how allowing the direct local route changed follower cash. Withdrawal minus continuous advice combines stopping follower orders with their subsequent local responses. Neither contrast is a general mediation fraction.\n")
        println(io,"| Technical traders | Reserves/trader | Adoption | Sources | Contrast | Follower exit-cash change (pp; 95% interval) |\n|---|---:|---:|---|---|---:|")
        for r in eachrow(contrasts[contrasts.metric.=="exit_cash_difference",:])
            @printf(io,"| %s | %g | %.0f%% | %s | %s | %.3f [%.3f, %.3f] |\n",
                r.boundary=="hold" ? "held" : "active",r.h,100r.a,
                r.independent ? "independent" : "one shared",r.comparison,100r.estimate,100r.lower,100r.upper)
        end
        println(io,"\n## Who funds the cash difference?\n")
        println(io,"All trader shares were sold in both arms. Raw cash changes include the followers, every remaining trader (including technical traders and reserved leaders), and the dealer. Equal terminal share inventories and the reserve invariant fix equal terminal dealer cash, so cohort differences redistribute cash among traders.\n")
        @printf(io,"Largest absolute paired dealer cash difference: %.6g currency units. Largest absolute aggregate trader cash difference: %.6g.\n",
            maximum(abs.(data.dealer_cash_difference)),maximum(abs.(data.total_trader_cash_difference)))
        println(io,"\n| Technical traders | Reserve shares/trader | Intervention | Follower cash difference (units) | Remaining traders' difference (units) |\n|---|---:|---|---:|---:|")
        for g in groupby(treatment[(treatment.a.==0.4).&.!treatment.independent,:],[:h,:boundary,:diagnostic])
            r=g[1,:]
            @printf(io,"| %s | %g | %s | %.3f | %.3f |\n",r.boundary=="hold" ? "held" : "active",
                r.h,r.diagnostic,mean(g.follower_cash_difference),mean(g.remaining_cash_difference))
        end
        println(io,"\n`Grouped.csv`, `Contrasts.csv`, and `Source-contrasts.csv` contain every specified setting and outcome. Sell differences are percentage points of trader-time spent deciding to sell; the final window is the last 500 steps in the full campaign. Withdrawal occurs after 1,000 of the 3,000 intervention steps. These controls do not cover copying, fees, alternative reserve mechanisms, size/horizon sensitivity, or fresh-market confirmation. No real investment performance or journal-readiness claim follows.")
    end
end

if abspath(PROGRAM_FILE)==@__FILE__
    analyze_transmission(isempty(ARGS) ? "pilot" : only(ARGS))
end
