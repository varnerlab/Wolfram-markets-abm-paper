# Fig-RuleExplore.jl
# Quick visualization of candidate rules from the screen.
# Produces: figs/RuleExplore-XXXXX.pdf

include(joinpath(@__DIR__, "Include.jl"))

const NROWS   = 256
const NCOLS   = 256
const STEPS   = 16384
const TARGETS = [1, 32, 64, 128, 512, 1024, 4096, 16384]

function _explore_rule(rule_idx::Int)
    rule_model = build(MyTwoDimensionalTotalisticWolframRuleModel,
        (index = rule_idx, colors = 3, radius = 4))
    Q = rule_model.neighborhoodstatesmap
    D = rule_model.rule

    Random.seed!(1234)
    state = rand(0:2, NROWS, NCOLS)
    nxt   = similar(state)

    frames    = Dict{Int, Matrix{Int}}()
    frac_steps = Int[]
    buy_ts    = Float64[]
    hold_ts   = Float64[]
    sell_ts   = Float64[]
    N_cells   = NROWS * NCOLS

    frames[0] = copy(state)

    for step in 1:STEPS
        copyto!(nxt, state)
        for r in 2:NROWS-1, c in 2:NCOLS-1
            μ = 0.25 * (state[r,c-1] + state[r,c+1] + state[r-1,c] + state[r+1,c])
            nxt[r,c] = D[Q[round(μ; digits=2)]]
        end
        state, nxt = nxt, state

        push!(frac_steps, step)
        push!(buy_ts,  count(==(0), state) / N_cells)
        push!(hold_ts, count(==(1), state) / N_cells)
        push!(sell_ts, count(==(2), state) / N_cells)

        if step in TARGETS
            frames[step] = copy(state)
        end
    end

    snap_times = [t for t in TARGETS if haskey(frames, t)]
    snap_panels = [_grid_panel(frames[t], "t = $t") for t in snap_times]

    p_frac = plot(frac_steps, buy_ts;
        xscale = :log10, label = "Buy", color = _BUY_COLOR, lw = 1.5,
        xlabel = "Time step", ylabel = "Agent fraction",
        ylims = (0, 1), legend = :topright,
        title = "Rule $(rule_idx)", titlefont = 9,
        background_color_inside = "#EEF0F2",
        grid = true, gridcolor = :black, gridwidth = 0.5, gridalpha = 0.2)
    plot!(p_frac, frac_steps, hold_ts; label="Hold", color=_HOLD_COLOR, lw=1.5)
    plot!(p_frac, frac_steps, sell_ts; label="Sell", color=_SELL_COLOR, lw=1.5)
    vline!(p_frac, snap_times; color=:black, alpha=0.2, linestyle=:dot, label=false)

    l   = @layout [grid(2, 4) b{0.22w}]
    fig = plot(snap_panels..., p_frac;
        layout        = l,
        size          = (1150, 460),
        left_margin   = 1Plots.mm,
        right_margin  = 1Plots.mm,
        top_margin    = 2Plots.mm,
        bottom_margin = 3Plots.mm)

    _save_figure(fig, "RuleExplore-$(rule_idx).pdf")
end

for r in [18955, 19198, 19441]
    @info "Exploring rule $r ..."
    _explore_rule(r)
end
