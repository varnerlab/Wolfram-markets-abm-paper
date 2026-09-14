include("Revision-Lib.jl")

function run_control_job(j)
    c=revision_config(;L=j.L,f=j.f,seed=j.seed,post=j.post,h=j.h,impact=j.impact,rule=j.rule)
    if j.boundary == "hold"
        r=held_rebuild(c;action=Symbol(j.action))
        control=held_rebuild(c;action=:none)
        @assert r.at_activation == control.at_activation
        @assert r.sell_fraction[1:1001] == control.sell_fraction[1:1001]
        finance=financial_metrics(r.financial_result)
    else
        r=simulate_repaired(c;minority_population=:interior,
                   rule_activation_step=j.action=="none" ? c.steps+1 : 1001,
                   activation_action=j.action=="sell_pulse" ? :sell_pulse : :rule,
                   fixed_band_step=j.band=="frozen" ? 1001 : nothing,
                   snapshot_steps=[1000],verbose=false)
        control=simulate_repaired(c;minority_population=:interior,rule_activation_step=c.steps+1,
                         snapshot_steps=[1000],verbose=false)
        @assert r.frames[1000] == control.frames[1000]
        @assert r.sell_fraction[1:1001] == control.sell_fraction[1:1001]
        @assert r.prices[1:1001] == control.prices[1:1001]
        j.action=="rule" && @assert r.prices[1002] == control.prices[1002]
        finance=financial_metrics(r)
    end
    merge(j,revision_metrics(r),finance,
          (control_transitioned=revision_metrics(control).transitioned,))
end

job(;campaign,L=64,f=0.20,seed=1,post=3000,h=100.0,impact=0.02,rule=19286,
     boundary="endogenous",action="rule",band="adaptive") =
    (;campaign,L,f,seed,post,h,impact,rule,boundary,action,band)

# All 18 Hamming-distance-one neighbors, including both alternatives at c=1.
# These are exploratory 20-seed screens; focused controls use 50 seeds.
base=digits(19280;base=3,pad=9)
screen=[job(campaign="rule_screen",rule=19280+(output-base[sum+1])*3^sum,
            f=f,seed=seed,boundary=b) for sum in 0:8 for output in 0:2
            if output!=base[sum+1] for f in (0.15,0.20,0.25)
            for seed in 1:20 for b in ("hold","endogenous")]
pulses=[job(campaign="matched_pulse",f=f,seed=s,boundary=b,action=a)
        for f in (0.15,0.20,0.25) for s in 1:50
        for b in ("hold","endogenous") for a in ("rule","sell_pulse")]
bands=[job(campaign="fixed_band",f=0.175,h=h,seed=s,band=band)
       for h in (0.,0.1,0.5,1.,2.,5.,10.,100.0) for s in 1:50
       for band in ("adaptive","frozen")]
impacts=[job(campaign="reserve_depth",h=h,impact=2/h,seed=s)
         for h in (40.,100.,400.) for s in 1:50]
long=[job(campaign="long_control",post=100000,seed=s,boundary=b,action="none")
      for s in 1:10 for b in ("hold","endogenous")]
sets=Dict("screen"=>screen,"pulse"=>pulses,"band"=>bands,"impact"=>impacts,"long"=>long)
for name in (isempty(ARGS) ? ["screen","pulse","band","impact","long"] : ARGS)
    jobs=sets[name]
    @info "Revision control campaign" name jobs=length(jobs) threads=Threads.nthreads()
    checkpoint_run("ModelB-Revision-$(name)",jobs,run_control_job)
end
