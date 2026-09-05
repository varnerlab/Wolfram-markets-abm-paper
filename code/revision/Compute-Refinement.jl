include("Revision-Lib.jl")
old=CSV.read(joinpath(REV_DATA,"ModelB-FiniteSizeQuench-Full-Summary.csv"),DataFrame)
raw=select(old,:boundary_mode,:market_maker_capacity,:gridn,:target_f,:seed,
           :transitioned,:final_sell_mean)
function run_refinement(j)
    c=revision_config(L=j.gridn,f=j.target_f,seed=j.seed,h=j.market_maker_capacity)
    if j.boundary_mode=="hold"
        r=held_lattice(c)
        control=held_lattice(c;action=:none)
        @assert r.at_activation==control.at_activation
        @assert !revision_metrics(control).transitioned
    else
        r=simulate(c;minority_population=:interior,rule_activation_step=1001,
                   snapshot_steps=[1000],verbose=false)
        control=simulate(c;minority_population=:interior,rule_activation_step=4001,
                         snapshot_steps=[1000],verbose=false)
        @assert r.frames[1000]==control.frames[1000]
        @assert r.prices[1:1002]==control.prices[1:1002]
        @assert !revision_metrics(control).transitioned
    end
    m=revision_metrics(r)
    merge(j,(transitioned=m.transitioned,final_sell_mean=m.final_sell_mean))
end
for iteration in 1:10
    jobs=NamedTuple[]
    for df in groupby(raw,[:boundary_mode,:market_maker_capacity,:gridn])
        g=sort(combine(groupby(df,:target_f),:transitioned=>mean=>:p),:target_f)
        count(p->0.05<p<0.95,g.p)>=5 && continue
        # Bisect all intervals that touch the 5--95% response, rather than
        # assigning a systematically finer absolute grid only to large L.
        for i in 1:nrow(g)-1
            (g.p[i]<0.95 && g.p[i+1]>0.05) || continue
            f=round((g.target_f[i]+g.target_f[i+1])/2;digits=7)
            for seed in 1:50
                push!(jobs,(boundary_mode=first(df.boundary_mode),
                    market_maker_capacity=first(df.market_maker_capacity),
                    gridn=first(df.gridn),target_f=f,seed=seed))
            end
        end
    end
    isempty(jobs) && break
    @info "Adaptive refinement" iteration runs=length(jobs)
    extra=checkpoint_run("ModelB-Revision-Refinement-Round$(iteration)",jobs,run_refinement)
    append!(raw,extra)
end
sort!(raw,[:boundary_mode,:market_maker_capacity,:gridn,:target_f,:seed])
for df in groupby(raw,[:boundary_mode,:market_maker_capacity,:gridn])
    p=combine(groupby(df,:target_f),:transitioned=>mean=>:p).p
    @assert count(x->0.05<x<0.95,p)>=5
end
CSV.write(joinpath(REV_DATA,"ModelB-Revision-FiniteSize-Summary.csv"),raw)
@info "Refinement complete" rows=nrow(raw)
