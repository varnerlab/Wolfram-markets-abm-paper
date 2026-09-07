# Extend the five Fig. 4 starting markets and all 50 f=0.150 markets.
# Prices remain active; each changed-rule market has a no-switch comparison.
# Run: julia --project=code --threads=4 code/revision/Compute-MarketPanel-Horizons.jl
include("Revision-Lib.jl")

const PANEL_PRE = 1000
const PANEL_POST = 10000
const PANEL_CASES = [(f=0.150, seed=8), (f=0.175, seed=5),
                     (f=0.175, seed=22), (f=0.185, seed=46), (f=0.200, seed=21)]
const PANEL_STEM = "ModelB-Revision-MarketPanel-Horizons"
const PANEL_CACHE = joinpath(REV_DATA, PANEL_STEM * "-v1-Checkpoints")
mkpath(PANEL_CACHE)
const PANEL_ARCHIVE = CSV.read(joinpath(REV_DATA, "ModelB-ReservoirQuench-Full-Summary.csv"), DataFrame)

function market_path(j; post=PANEL_POST, changed=true)
    c = revision_config(; L=64, f=j.f, seed=j.seed, post=post, pre=PANEL_PRE, h=Inf)
    simulate(c; minority_population=:interior, boundary_mode=:endogenous,
             rule_activation_step=changed ? PANEL_PRE+1 : c.steps+1,
             snapshot_steps=Int64[PANEL_PRE, PANEL_PRE+3000, c.steps], verbose=false)
end

function horizon_summary(r, post)
    p = @view r.prices[PANEL_PRE+1:PANEL_PRE+post+1]
    m = revision_metrics(r; pre=PANEL_PRE, post=post)
    endpoint = PANEL_PRE+post+1
    returns = @view r.log_returns[endpoint-1000:endpoint-1]
    merge(m, (
        price_at_rule_change=first(p), price_at_end=last(p),
        price_change=last(p)/first(p)-1,
        maximum_drawdown=compute_max_drawdown(collect(p)),
        price_change_after_3000=last(p)/r.prices[PANEL_PRE+3000+1]-1,
        final_sell=r.sell_fraction[endpoint],
        last_1000_price_change=r.prices[endpoint]/r.prices[endpoint-1000]-1,
        last_1000_return_std=std(returns),
        last_1000_executed_buys=mean(@view r.executed_buys[endpoint-1000:endpoint-1]),
        last_1000_executed_sells=mean(@view r.executed_sells[endpoint-1000:endpoint-1]),
    ))
end

function extend_market(j)
    original = PANEL_ARCHIVE[(PANEL_ARCHIVE.boundary_mode .== "endogenous") .&
        isinf.(PANEL_ARCHIVE.market_maker_capacity) .&
        (PANEL_ARCHIVE.target_f .== j.f) .& (PANEL_ARCHIVE.seed .== j.seed), :]
    @assert nrow(original) == 1
    changed = market_path(j)
    control = market_path(j; changed=false)
    @assert changed.prices[1:PANEL_PRE+2] == control.prices[1:PANEL_PRE+2]
    @assert changed.sell_fraction[1:PANEL_PRE+1] == control.sell_fraction[1:PANEL_PRE+1]
    @assert changed.frames[PANEL_PRE] == control.frames[PANEL_PRE]
    for (r, prefix) in ((changed, "treated"), (control, "control"))
        financial_metrics(r; pre=PANEL_PRE) # also checks conservation
        m = horizon_summary(r, 3000)
        @assert m.onset == original[1, Symbol(prefix * "_onset")]
        @assert isapprox(m.final_sell_mean, original[1, Symbol(prefix * "_final_sell_mean")]; atol=1e-14)
        @assert isapprox(m.maximum_drawdown, original[1, Symbol(prefix * "_maximum_drawdown")]; atol=1e-14)
        @assert isapprox(log1p(m.price_change), original[1, Symbol(prefix * "_price_log_change")]; atol=1e-14)
    end
    if j in PANEL_CASES
        short = market_path(j; post=3000)
        @assert short.prices == changed.prices[1:PANEL_PRE+3000+1]
        @assert short.sell_fraction == changed.sell_fraction[1:PANEL_PRE+3000+1]
        @assert short.frames[PANEL_PRE+3000] == changed.frames[PANEL_PRE+3000]
    end
    traces = NamedTuple[]
    for (condition,r) in (("changed",changed), ("control",control))
        for t in 0:10:PANEL_POST
            idx = PANEL_PRE+t+1
            push!(traces, merge(j, (condition=condition, post_step=t,
                price_relative=r.prices[idx]/r.prices[PANEL_PRE+1],
                sell_fraction=r.sell_fraction[idx])))
        end
    end
    CSV.write(joinpath(PANEL_CACHE, "trace-$(j.f)-$(j.seed).csv"), DataFrame(traces))
    rows = [merge(j, (condition=condition, post=post), horizon_summary(r,post))
        for (condition,r) in (("changed",changed),("control",control)) for post in (3000,5000,10000)]
    @info "Extended market" f=j.f seed=j.seed onset=rows[3].onset price_3000=rows[1].price_change price_10000=rows[3].price_change
    rows
end

# Run the actual illustrations first, then the remaining original f=0.150 seeds.
# An interrupted run can resume without recomputing completed paired paths.
jobs = vcat(PANEL_CASES, [(f=0.150,seed=s) for s in 1:50 if s != 8])
summary = checkpoint_run(PANEL_STEM, jobs, extend_market)
trace_tables = [CSV.read(joinpath(PANEL_CACHE,"trace-$(j.f)-$(j.seed).csv"),DataFrame) for j in jobs]
CSV.write(joinpath(REV_DATA, PANEL_STEM * "-Trajectories.csv"), reduce(vcat,trace_tables))
@info "Market horizon extension complete" paired_markets=length(jobs) post_steps=PANEL_POST
