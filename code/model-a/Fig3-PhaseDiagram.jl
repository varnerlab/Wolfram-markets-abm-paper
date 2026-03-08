# Fig3-PhaseDiagram.jl
# Loads: data/ModelA-PhaseSweep.jld2
# Produces: figs/Fig3-PhaseDiagram.pdf  →  paper/figs/Fig3-PhaseDiagram.pdf
#
# Layout (1×3):
#   Panel A  mean sell fraction vs f
#   Panel B  max (peak) sell fraction vs f
#   Panel C  crash frequency vs f   (fraction of steps with sell > 0.5)

include(joinpath(@__DIR__, "Include.jl"))

d      = load(joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep.jld2"))
f_vals = d["f_values"]
sweep  = d["sweep_results"]

mean_sell  = [sweep[f]["mean_sell_fraction"] for f in f_vals]
max_sell   = [sweep[f]["max_sell_fraction"]  for f in f_vals]
crash_freq = [sweep[f]["crash_frequency"]    for f in f_vals]

# ---------------------------------------------------------------------------
# Panel A — mean sell fraction
# ---------------------------------------------------------------------------
pA = plot(f_vals, mean_sell;
    marker = :circle, lw = 1.5, color = :red,
    xlabel = "Minority fraction  f", ylabel = "Mean sell fraction",
    title = "A", titlefont = 9, legend = false)

# ---------------------------------------------------------------------------
# Panel B — peak sell fraction
# ---------------------------------------------------------------------------
pB = plot(f_vals, max_sell;
    marker = :circle, lw = 1.5, color = :darkred,
    xlabel = "Minority fraction  f", ylabel = "Peak sell fraction",
    title = "B", titlefont = 9, legend = false)

# ---------------------------------------------------------------------------
# Panel C — crash frequency
# ---------------------------------------------------------------------------
pC = plot(f_vals, crash_freq;
    marker = :circle, lw = 1.5, color = :black,
    xlabel = "Minority fraction  f", ylabel = "Crash frequency",
    title = "C", titlefont = 9, legend = false)
hline!(pC, [0.0]; linestyle = :dash, color = :gray, label = false)

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig3 = plot(pA, pB, pC;
    layout = (1, 3), size = (900, 300),
    plot_title = "Model A — Phase diagram vs minority fraction f")

_save_figure(fig3, "Fig3-PhaseDiagram.pdf")
