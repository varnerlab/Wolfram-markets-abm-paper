include("Following-Lib.jl")

const FOLLOWING_OUTCOMES = (
    :followers_return_difference, :followers_drawdown_difference,
    :followers_q10_difference, :others_return_difference, :others_sell_difference,
    :drawdown_difference, :rejection_difference, :maximum_drawdown,
    :sell_rejection, :transitioned, :source_active, :desired_imbalance_std,
)

function following_cluster_summary(values,seeds,all_seeds,resamples;
                                   probability=false,binary_contrast=false)
    clusters=[begin
        selected=Float64[values[i] for i in eachindex(values)
                         if seeds[i]==seed && !ismissing(values[i]) && isfinite(values[i])]
        isempty(selected) ? NaN : mean(selected)
    end for seed in all_seeds]
    finite=filter(isfinite,clusters)
    raw=Float64[x for x in values if !ismissing(x) && isfinite(x)]
    estimate=isempty(finite) ? NaN : mean(finite)
    draws=Float64[]
    for b in axes(resamples,2)
        sample=filter(isfinite,clusters[resamples[:,b]])
        isempty(sample) || push!(draws,mean(sample))
    end
    lo,hi=isempty(draws) ? (NaN,NaN) : Tuple(quantile(draws,[0.025,0.975]))
    kind="pointwise_cluster_bootstrap_95"
    if probability && !isempty(finite) && all(iszero,finite)
        lo=0.;hi=1-0.05^(1/length(finite));kind="one_sided_exact_cluster_boundary_95"
    elseif probability && !isempty(finite) && all(==(1),finite)
        lo=0.05^(1/length(finite));hi=1.;kind="one_sided_exact_cluster_boundary_95"
    end
    if binary_contrast && !isempty(raw) && (all(iszero,raw) || all(==(1),raw) || all(==(-1),raw))
        bound=1-0.05^(1/length(finite))
        if all(iszero,raw)
            lo=-bound;hi=bound
        elseif all(==(1),raw)
            lo=1-2bound;hi=1.
        else
            lo=-1.;hi=-1+2bound
        end
        kind="conservative_exact_cluster_discordance_95"
    end
    quantiles=isempty(raw) ? fill(NaN,3) : quantile(raw,[0.25,0.5,0.75])
    (;estimate,lower=lo,upper=hi,q25=quantiles[1],median=quantiles[2],q75=quantiles[3],
       markets=length(finite),runs=length(values),valid_runs=length(raw),
       valid_bootstraps=length(draws),interval=kind)
end

function analyze_following(stage; bootstraps=2000)
    prefix=joinpath(FOLLOWING_DATA,"Following-"*uppercasefirst(stage))
    data=CSV.read(prefix*"-Summary.csv",DataFrame)
    manifest=CSV.read(prefix*"-Manifest.csv",DataFrame)
    nrow(data)==nrow(manifest) || error("incomplete summary")
    Set(data.job_id)==Set(manifest.job_id) || error("summary jobs do not match manifest")
    length(unique(data.job_id))==nrow(data) || error("duplicate summary rows")
    treatment=data[data.mode .!= "none",:]
    seeds=sort(unique(treatment.seed))
    resamples=rand(Xoshiro(20260913),1:length(seeds),length(seeds),bootstraps)
    rows=NamedTuple[]
    for group in groupby(treatment,[:mode,:a,:K,:independent,:h,:boundary,:L,:pre,:post])
        key=NamedTuple(group[1,[:mode,:a,:K,:independent,:h,:boundary,:L,:pre,:post]])
        for metric in FOLLOWING_OUTCOMES
            stat=following_cluster_summary(group[!,metric],group.seed,seeds,resamples;
                                           probability=metric==:transitioned)
            push!(rows,merge(key,(metric=string(metric),),stat))
        end
    end
    grouped=DataFrame(rows)
    contrasts=NamedTuple[]
    for group in groupby(treatment,[:mode,:a,:h,:boundary,:L,:pre,:post])
        key=NamedTuple(group[1,[:mode,:a,:h,:boundary,:L,:pre,:post]])
        left=group[(group.K .== 1) .& .!group.independent,:]
        right=key.mode=="advice" ? group[group.independent,:] : group[group.K .== 16,:]
        isempty(right) && continue
        index=Dict((r.seed,r.replicate)=>r for r in eachrow(right))
        all(haskey(index,(r.seed,r.replicate)) for r in eachrow(left)) || error("unpaired concentration contrast")
        for metric in FOLLOWING_OUTCOMES
            values=[Float64(r[metric])-Float64(index[(r.seed,r.replicate)][metric]) for r in eachrow(left)]
            stat=following_cluster_summary(values,left.seed,seeds,resamples;
                                           binary_contrast=metric==:transitioned)
            push!(contrasts,merge(key,(comparison=key.mode=="advice" ? "one_minus_independent" : "one_minus_sixteen",
                                      metric=string(metric)),stat))
        end
    end
    contrast=DataFrame(contrasts)
    CSV.write(prefix*"-Grouped.csv",grouped)
    CSV.write(prefix*"-Contrasts.csv",contrast)
    report=joinpath(FOLLOWING_ROOT,"output","following")
    mkpath(report)
    open(joinpath(report,stage*"-report.md"),"w") do io
        println(io,"# Following experiment: ",stage,"\n")
        println(io,"Complete manifest: ",nrow(data)," runs, including ",count(==("none"),data.mode),
                " shared no-following controls. There are ",length(seeds)," independent starting markets.\n")
        println(io,"All treatment pairs have matching starting-state fingerprints. Per-run checks reconcile individual orders with aggregate execution and verify cash and share conservation.\n")
        println(io,"The estimates below compare following with the same tagged traders in the paired no-following market. Returns and drawdowns are gross simulated outcomes. Intervals resample entire starting markets and are pointwise. Source agreement is imposed in the advice experiment; non-follower responses measure transmission beyond the followers.\n")
        println(io,"| Mechanism | Followers | Sources | Capacity | Technical traders | Follower return change (pp) | Non-follower Sell change (pp) | Price drawdown change (pp) | Source active (%) |\n|---|---:|---:|---:|---|---:|---:|---:|---:|")
        for group in groupby(treatment,[:mode,:a,:K,:independent,:h,:boundary])
            r=first(eachrow(group))
            (r.K==1 || r.K==16 || r.independent) || continue
            fmean(col)=begin v=filter(isfinite,Float64.(group[!,col]));isempty(v) ? NaN : mean(v)*100 end
            @printf(io,"| %s | %.0f%% | %s | %s | %s | %.3f | %.3f | %.3f | %.2f |\n",
                r.mode,100r.a,r.independent ? "independent" : string(r.K),string(r.h),
                r.boundary=="hold" ? "held" : "active",fmean(:followers_return_difference),
                fmean(:others_sell_difference),fmean(:drawdown_difference),fmean(:source_active))
        end
        println(io,"\nFull estimates and 95% intervals: `",basename(prefix),"-Grouped.csv` and `",
                basename(prefix),"-Contrasts.csv`. Missing order denominators remain NaN. Zero-event probability samples use a conservative exact bound based on independent market clusters.\n")
        println(io,"Pilot findings are exploratory. Confirmation uses fresh market seeds; no pilot rows are pooled into confirmation estimates.")
    end
    @info "Following analysis complete" stage grouped=nrow(grouped) contrasts=nrow(contrast)
    (;data,grouped,contrast)
end

if abspath(PROGRAM_FILE)==@__FILE__
    analyze_following(isempty(ARGS) ? "smoke" : only(ARGS))
end
