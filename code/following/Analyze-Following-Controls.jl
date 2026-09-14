include("Analyze-Following.jl")

function analyze_following_controls(stage;bootstraps=2000)
    prefix=joinpath(FOLLOWING_DATA,"Following-"*uppercasefirst(stage))
    data=CSV.read(prefix*"-Summary.csv",DataFrame)
    manifest=CSV.read(prefix*"-Manifest.csv",DataFrame)
    nrow(data)==nrow(manifest) && Set(data.job_id)==Set(manifest.job_id) || error("incomplete diagnostics")
    length(unique(data.job_id))==nrow(data) || error("duplicate diagnostics")
    treatment=data[data.mode.!="none",:]
    seeds=sort(unique(treatment.seed))
    resamples=rand(Xoshiro(20260913),1:length(seeds),length(seeds),bootstraps)
    outcomes=(FOLLOWING_OUTCOMES...,:wind_followers_cash_proceeds,
              :wind_followers_final_cash,:wind_followers_unsold_shares,:wind_followers_unsold_fraction)
    grouping=[:diagnostic,:mechanism,:a,:K,:h,:boundary,:L,:pre,:post,:impact]
    estimates=NamedTuple[];contrasts=NamedTuple[]
    reference=Dict((r.seed,r.replicate,r.mechanism,r.a,r.K,r.h,r.boundary,r.diagnostic)=>r
                   for r in eachrow(treatment) if r.diagnostic in ("live","replay"))
    for group in groupby(treatment,grouping)
        key=NamedTuple(group[1,grouping])
        ref=key.diagnostic=="mask" && key.mechanism=="copy_filled" ? "replay" : "live"
        for metric in outcomes
            stat=following_cluster_summary(group[!,metric],group.seed,seeds,resamples;
                                           probability=metric==:transitioned)
            push!(estimates,merge(key,(metric=string(metric),),stat))
            key.diagnostic=="live" && continue
            startswith(string(metric),"wind_") && continue
            values=[Float64(r[metric])-Float64(reference[(r.seed,r.replicate,r.mechanism,
                    r.a,r.K,r.h,r.boundary,ref)][metric]) for r in eachrow(group)]
            delta=following_cluster_summary(values,group.seed,seeds,resamples;
                                            binary_contrast=metric==:transitioned)
            push!(contrasts,merge(key,(reference=ref,metric=string(metric)),delta))
        end
    end
    grouped=DataFrame(estimates);contrast=DataFrame(contrasts)
    CSV.write(prefix*"-Grouped.csv",grouped)
    CSV.write(prefix*"-Contrasts.csv",contrast)
    masked=treatment[(treatment.diagnostic.=="mask").&(treatment.boundary.=="hold"),:]
    all(masked.masked_identity) || error("masked decision identity failed")
    # Re-running the live diagnostic must reproduce the corresponding core rows.
    core_stage=replace(stage,"diagnostic-"=>"")
    core_path=joinpath(FOLLOWING_DATA,"Following-"*uppercasefirst(core_stage)*"-Summary.csv")
    matched=0
    if isfile(core_path)
        core=CSV.read(core_path,DataFrame)
        lookup=Dict((r.seed,r.replicate,r.mode,r.a,r.K,r.h,r.boundary)=>r
                    for r in eachrow(core) if r.mode!="none" && !r.independent)
        for r in eachrow(treatment[treatment.diagnostic.=="live",:])
            key=(r.seed,r.replicate,r.mode,r.a,r.K,r.h,r.boundary)
            haskey(lookup,key) || continue
            for metric in FOLLOWING_OUTCOMES
                isequal(r[metric],lookup[key][metric]) || error("live diagnostic differs from core: $(r.job_id), $metric")
            end
            matched+=1
        end
    end
    output=joinpath(FOLLOWING_ROOT,"output","following");mkpath(output)
    open(joinpath(output,stage*"-report.md"),"w") do io
        println(io,"# Following mechanisms and sensitivities\n")
        println(io,"Campaign: `",stage,"`. Completed ",nrow(data)," manifest jobs across ",length(seeds)," independent starting markets.\n")
        println(io,"All ",nrow(masked)," held, fixed-source masking runs reproduced their non-followers' no-following decision histories exactly. ",matched," live diagnostic runs matched the corresponding core outcome rows exactly.\n")
        println(io,"Control contrasts are paired within starting market and design replicate. Copy-trading masking is compared with fixed replay, so the source tapes stay unchanged. Other controls are compared with live following at the original settings. Size and horizon comparisons are sensitivity analyses; they do not hold the physical population or observation period constant.\n")
        println(io,"| Control | Mechanism | Followers | Sources | Capacity | Technical traders | Non-follower Sell change relative to reference (pp) | Follower return change relative to reference (pp) |\n|---|---|---:|---:|---:|---|---:|---:|")
        for group in groupby(contrast,grouping)
            r=first(eachrow(group))
            s=only(group[group.metric.=="others_sell_difference",:estimate])
            v=only(group[group.metric.=="followers_return_difference",:estimate])
            @printf(io,"| %s | %s | %.0f%% | %d | %s | %s | %.3f | %.3f |\n",
                    r.diagnostic,r.mechanism,100r.a,r.K,string(r.h),
                    r.boundary=="hold" ? "held" : "active",100s,100v)
        end
        println(io,"\nThe accompanying grouped and contrast CSVs report pointwise 95% intervals. Exit-test cash proceeds and unsold shares are separate outcomes; unsold shares are not assigned a value of zero. No claim of permanent instability or real investment profitability follows from these simulations.")
    end
    @info "Following diagnostic analysis complete" stage matched masked=nrow(masked)
    (;data,grouped,contrast)
end

if abspath(PROGRAM_FILE)==@__FILE__
    analyze_following_controls(isempty(ARGS) ? "diagnostic-smoke" : only(ARGS))
end
