# Fig2-GridSnapshots.jl
# Loads: data/ModelA-Homogeneous.jld2
# Produces: figs/Fig2-GridSnapshots.pdf  →  paper/figs/Fig2-GridSnapshots.pdf
#
# Layout (2×2):
#   Panel A  grid at t = T/4
#   Panel B  grid at t = T/2
#   Panel C  grid at t = 3T/4
#   Panel D  buy / hold / sell fractions over time

include(joinpath(@__DIR__, "Include.jl"))

d      = load(joinpath(_PATH_TO_DATA, "ModelA-Homogeneous.jld2"))
frames = d["frames"]
steps  = sort(collect(keys(frames)))
T      = length(steps)
N      = 256 * 256

# ---------------------------------------------------------------------------
# Snapshot indices
# ---------------------------------------------------------------------------
t1 = steps[max(1, T ÷ 4)]
t2 = steps[max(1, T ÷ 2)]
t3 = steps[max(1, 3T ÷ 4)]

snap_A = plot(_grid_to_image(frames[t1]); axis = false, title = "t = $(t1)", titlefont = 8)
snap_B = plot(_grid_to_image(frames[t2]); axis = false, title = "t = $(t2)", titlefont = 8)
snap_C = plot(_grid_to_image(frames[t3]); axis = false, title = "t = $(t3)", titlefont = 8)

# ---------------------------------------------------------------------------
# Fraction time series
# ---------------------------------------------------------------------------
buy_frac  = [count(==(0), frames[t]) / N for t in steps]
hold_frac = [count(==(1), frames[t]) / N for t in steps]
sell_frac = [count(==(2), frames[t]) / N for t in steps]

panel_D = plot(steps, buy_frac;
    label = "Buy", color = :lightgreen, lw = 1.5,
    xlabel = "Time step", ylabel = "Agent fraction",
    title = "Population dynamics", titlefont = 8,
    ylims = (0, 1), legend = :topright)
plot!(panel_D, steps, hold_frac; label = "Hold", color = :gray,   lw = 1.5)
plot!(panel_D, steps, sell_frac; label = "Sell", color = :red,    lw = 1.5)

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig2 = plot(snap_A, snap_B, snap_C, panel_D;
    layout = (2, 2), size = (800, 700),
    plot_title = "Model A — Homogeneous (Rule 6158)")

_save_figure(fig2, "Fig2-GridSnapshots.pdf")
