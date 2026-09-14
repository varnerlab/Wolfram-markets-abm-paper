# Fig-EdgeAgentDiagnostic.jl
# Verify that edge agents are updating correctly with QQQ data.
# Shows: price + EMA + bands, edge signal over time, and fraction of Buy/Hold/Sell injections.
# Produces: figs/Fig-EdgeAgentDiagnostic.pdf

include(joinpath(@__DIR__, "Include.jl"))

df     = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))
prices = compute_typical_price(df)
T      = length(prices)

const α  = 1/60    # EMA smoothing — ~60-step half-life (≈1 hour of 1-min data)
const k  = 1.0     # band width in σ units

ema  = compute_ema(prices; α=α)
evol = compute_ema_volatility(prices, ema; α=α)

upper = ema .+ k .* evol
lower = ema .- k .* evol

edge_signal = map(1:T) do t
    prices[t] > upper[t] && return 2   # overbought → Sell
    prices[t] < lower[t] && return 0   # oversold  → Buy
    return 1
end

n_buy  = count(==(0), edge_signal)
n_hold = count(==(1), edge_signal)
n_sell = count(==(2), edge_signal)
@info "Edge signal over $T steps: Buy=$(n_buy) ($(round(100n_buy/T,digits=1))%)  Hold=$(n_hold) ($(round(100n_hold/T,digits=1))%)  Sell=$(n_sell) ($(round(100n_sell/T,digits=1))%)"

# ---------------------------------------------------------------------------
# Panel A — price, EMA, bands (first 2000 steps for clarity)
# ---------------------------------------------------------------------------
N_show = 2000
ts = 1:N_show

pA = plot(ts, prices[ts];
    label  = "Typical price", color = :black, lw = 0.8,
    xlabel = "Time step (1-min bars)", ylabel = "Price (USD)",
    title  = "A  QQQ price + EMA band  (α=$(α), k=$(k))", titlefont = 9,
    background_color_inside = "#EEF0F2",
    grid = true, gridcolor = :black, gridwidth = 0.5, gridalpha = 0.15,
    legend = :topright)
plot!(pA, ts, ema[ts];   label="EMA",   color=:steelblue, lw=1.5)
plot!(pA, ts, upper[ts]; label="Upper", color=:firebrick, lw=1.0, linestyle=:dash)
plot!(pA, ts, lower[ts]; label="Lower", color=:steelblue, lw=1.0, linestyle=:dash)

# ---------------------------------------------------------------------------
# Panel B — edge signal over same window
# ---------------------------------------------------------------------------
sig_colors = [e==0 ? _BUY_COLOR : e==2 ? _SELL_COLOR : _HOLD_COLOR
              for e in edge_signal[ts]]

pB = scatter(ts, edge_signal[ts];
    marker = :rect, ms = 1.5, markerstrokewidth = 0,
    color  = sig_colors,
    yticks = ([0,1,2], ["Buy","Hold","Sell"]),
    xlabel = "Time step", ylabel = "Edge state",
    title  = "B  Edge agent injection signal", titlefont = 9,
    legend = false,
    background_color_inside = "#EEF0F2",
    grid = true, gridcolor = :black, gridwidth = 0.5, gridalpha = 0.15)

# ---------------------------------------------------------------------------
# Panel C — running fraction of each state (full series)
# ---------------------------------------------------------------------------
window = 500
buy_run  = [mean(edge_signal[max(1,t-window):t] .== 0) for t in 1:T]
hold_run = [mean(edge_signal[max(1,t-window):t] .== 1) for t in 1:T]
sell_run = [mean(edge_signal[max(1,t-window):t] .== 2) for t in 1:T]

pC = plot(1:T, buy_run;
    label="Buy",  color=_BUY_COLOR,  lw=1.5,
    xlabel="Time step", ylabel="Rolling fraction ($(window)-step window)",
    title="C  Edge signal composition over time", titlefont=9,
    ylims=(0,1), legend=:topright,
    background_color_inside="#EEF0F2",
    grid=true, gridcolor=:black, gridwidth=0.5, gridalpha=0.15)
plot!(pC, 1:T, hold_run; label="Hold", color=_HOLD_COLOR, lw=1.5)
plot!(pC, 1:T, sell_run; label="Sell", color=_SELL_COLOR, lw=1.5)

# ---------------------------------------------------------------------------
# Compose
# ---------------------------------------------------------------------------
fig = plot(pA, pB, pC;
    layout = (3,1),
    size   = (900, 800),
    left_margin   = 8Plots.mm,
    right_margin  = 4Plots.mm,
    top_margin    = 2Plots.mm,
    bottom_margin = 4Plots.mm)

_save_figure(fig, "Fig-EdgeAgentDiagnostic-v4.pdf")
