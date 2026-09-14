include("Revision-Lib.jl")
jobs=[(L=L,f=f,seed=s) for L in (32,64,128) for f in collect(0.14:0.005:0.25) for s in 1:50]
append!(jobs, [(L=32,f=f,seed=s) for f in collect(0.255:0.005:0.30) for s in 1:50])
function run_horizon(j)
    horizons=j.L==32 ? (750,1500,3000) : j.L==64 ? (3000,9000) : (3000,6000,12000)
    c=revision_config(;L=j.L,f=j.f,seed=j.seed,post=maximum(horizons))
    r=held_rebuild(c)
    control=held_rebuild(c;action=:none)
    @assert r.at_activation==control.at_activation
    rows=NamedTuple[]
    for post in horizons
        m=revision_metrics(r;post)
        cm=revision_metrics(control;post)
        push!(rows,merge(j,(post=post,),m,(control_transitioned=cm.transitioned,)))
    end
    rows
end
checkpoint_run("ModelB-Revision-Horizons",jobs,run_horizon)
