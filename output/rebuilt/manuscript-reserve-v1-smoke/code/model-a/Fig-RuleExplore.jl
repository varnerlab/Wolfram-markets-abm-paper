# Fig-RuleExplore.jl
# Visualize candidate rules coupled to QQQ edge agents (same setup as Model A).
# Produces: figs/RuleExplore-XXXXX.pdf

include(joinpath(@__DIR__, "Include.jl"))

const NROWS   = 256
const NCOLS   = 256
const TARGETS = [1, 32, 64, 128, 512, 1024, 4096, 16384]
const α_EMA   = 1/60
const k_BAND  = 1.0

# ---------------------------------------------------------------------------
# Load QQQ price data and build edge signal
# ---------------------------------------------------------------------------
df     = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))
prices = compute_typical_price(df)
ema    = compute_ema(prices; α=α_EMA)
evol   = compute_ema_volatility(prices, ema; α=α_EMA)

edge_signal = map(1:length(prices)) do t
    prices[t] > ema[t] + k_BAND * evol[t] && return 2   # overbought → Sell
    prices[t] < ema[t] - k_BAND * evol[t] && return 0   # oversold  → Buy
    return 1
end

const STEPS = min(length(edge_signal), 16384)

mid_row = div(NROWS, 2)
mid_col = div(NCOLS, 2)
const EDGE_POS = ((1, mid_col), (NROWS, mid_col), (mid_row, 1))

# ---------------------------------------------------------------------------
# Explore a single rule with edge agent forcing
# ---------------------------------------------------------------------------
function _explore_rule(rule_idx::Int)
    rm = build(MyTwoDimensionalTotalisticWolframRuleModel,
               (index=rule_idx, colors=3, radius=4))
    Q = rm.neighborhoodstatesmap
    D = rm.rule

    Random.seed!(1234)
    state   = rand(0:2, NROWS, NCOLS)
    nxt     = copy(state)
    N_cells = NROWS * NCOLS

    frames     = Dict{Int, Matrix{Int}}()
    frac_steps = Int[]
    buy_ts     = Float64[]
    hold_ts    = Float64[]
    sell_ts    = Float64[]

    for step in 1:STEPS
        # Inject edge agent states from QQQ signal
        es = edge_signal[step]
        for (r, c) in EDGE_POS
            state[r, c] = es
        end

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

    snap_times  = [t for t in TARGETS if haskey(frames, t)]
    snap_panels = [_grid_panel(frames[t], "t = $t") for t in snap_times]

    p_frac = plot(frac_steps, buy_ts;
        xscale = :log10, label = "Buy", color = _BUY_COLOR, lw = 1.5,
        xlabel = "Time step", ylabel = "Agent fraction",
        ylims  = (0, 1), legend = :topright,
        title  = "Rule $(rule_idx) — QQQ coupled", titlefont = 9,
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

    _save_figure(fig, "RuleExplore-$(rule_idx)-v6.pdf")
end

for r in [16014, 2465]
    @info "Exploring rule $r (QQQ coupled) ..."
    _explore_rule(r)
end
