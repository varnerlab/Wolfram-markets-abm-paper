# Fig4-ClosedLoop.jl
# Loads: data/ModelB-ClosedLoop.jld2
# Produces: figs/Fig4-ClosedLoop.pdf  →  paper/figs/Fig4-ClosedLoop.pdf
#
#
# STALE (2026-07-16): reads pre-rebuild Model B data (deleted producer).
# Regenerate at Stage 2 from the rebuilt closed-loop model; see
# docs/superpowers/specs/2026-07-15-model-b-rebuild-design.md §6.
#
# Layout (2×3):
#   Row 1  grid snapshots at three moments: before / during / after crash
#   Row 2  endogenous price series  |  net order imbalance  |  sell fraction

include(joinpath(@__DIR__, "Include.jl"))

d           = load(joinpath(_PATH_TO_DATA, "ModelB-ClosedLoop.jld2"))
frames      = d["frames"]
prices      = d["prices"]
net_imbal   = d["net_imbalance"]
steps       = sort(collect(keys(frames)))
T           = length(steps)
N           = 256 * 256

sell_frac   = [count(==(2), frames[t]) / N for t in steps]

# ---------------------------------------------------------------------------
# Find crash peak (maximum sell fraction)
# ---------------------------------------------------------------------------
crash_idx   = argmax(sell_frac)
t_crash     = steps[crash_idx]
t_before    = steps[max(1, crash_idx - T ÷ 6)]
t_after     = steps[min(T, crash_idx + T ÷ 6)]

snap_before = _grid_panel(frames[t_before], "Before crash  (t=$(t_before))")
snap_crash  = _grid_panel(frames[t_crash],  "Crash peak  (t=$(t_crash))")
snap_after  = _grid_panel(frames[t_after],  "After crash  (t=$(t_after))")

# ---------------------------------------------------------------------------
# Time series panels
# ---------------------------------------------------------------------------
log_ret = compute_log_returns(prices)

p_price = plot(prices[1:end-1];
    lw = 1.2, color = :black, legend = false,
    xlabel = "Time step", ylabel = "Price  P_t",
    title = "D", titlefont = 9)
vline!(p_price, [t_crash]; linestyle = :dash, color = :red, label = false)

p_imbal = plot(steps, net_imbal;
    lw = 1.2, color = :steelblue, legend = false,
    xlabel = "Time step", ylabel = "Net imbalance  φ",
    title = "E", titlefont = 9)
hline!(p_imbal, [0.0]; linestyle = :dash, color = :gray, label = false)
vline!(p_imbal, [t_crash]; linestyle = :dash, color = :red, label = false)

p_sell = plot(steps, sell_frac;
    lw = 1.2, color = :red, legend = false,
    xlabel = "Time step", ylabel = "Sell fraction",
    ylims = (0, 1), title = "F", titlefont = 9)
vline!(p_sell, [t_crash]; linestyle = :dash, color = :darkred, label = false)

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig4 = plot(snap_before, snap_crash, snap_after, p_price, p_imbal, p_sell;
    layout = (2, 3), size = (1050, 600),
    plot_title = "Model B — Closed-loop endogenous price formation")

_save_figure(fig4, "Fig4-ClosedLoop.pdf")
