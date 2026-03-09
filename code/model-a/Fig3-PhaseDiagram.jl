# Fig3-PhaseDiagram.jl
# Loads: data/ModelA-PhaseSweep.jld2 + data/ModelA-PhaseSweep-Fine.jld2
# Produces: figs/Fig3-PhaseDiagram.pdf  →  paper/figs/Fig3-PhaseDiagram.pdf
#
# Layout (1×3):
#   Panel A  mean sell fraction vs f
#   Panel B  max (peak) sell fraction vs f
#   Panel C  crash frequency vs f   (fraction of steps with sell > 0.5)

include(joinpath(@__DIR__, "Include.jl"))

# Load coarse sweep
d      = load(joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep.jld2"))
f_coarse = d["f_values"]
sweep_c  = d["sweep_results"]

# Load fine sweep (if available) and merge
fine_path = joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep-Fine.jld2")
if isfile(fine_path)
    df = load(fine_path)
    f_fine  = df["f_values"]
    sweep_f = df["sweep_results"]
    # Merge: fine sweep values override coarse where they overlap
    all_sweep = merge(sweep_c, sweep_f)
    f_vals = sort(collect(keys(all_sweep)))
else
    all_sweep = sweep_c
    f_vals = sort(collect(f_coarse))
end

mean_sell  = [all_sweep[f]["mean_sell_fraction"] for f in f_vals]
max_sell   = [all_sweep[f]["max_sell_fraction"]  for f in f_vals]
crash_freq = [all_sweep[f]["crash_frequency"]    for f in f_vals]

# Vertical line at critical fraction
fc = 0.145

# Shared style — slick gray background (Cell / Science style)
using Colors
_bg = RGB(0.94, 0.94, 0.94)
_grid_col = RGB(1.0, 1.0, 1.0)
_panel_kw = (
    background_color_inside = _bg,
    foreground_color_grid = _grid_col,
    gridalpha = 0.8,
    gridlinewidth = 0.5,
    framestyle = :box,
    tickfontsize = 7,
    guidefontsize = 8,
    titlefontsize = 9,
    legend = false,
    margin = 5Plots.mm,
)

# ---------------------------------------------------------------------------
# Panel A — mean sell fraction
# ---------------------------------------------------------------------------
pA = plot(f_vals, mean_sell;
    marker = :circle, ms = 3, lw = 1.5, color = :red,
    xlabel = "Minority fraction f", ylabel = "Mean sell fraction",
    title = "A", _panel_kw...)
vline!(pA, [fc]; linestyle = :dash, color = :gray50, label = false)

# ---------------------------------------------------------------------------
# Panel B — peak sell fraction
# ---------------------------------------------------------------------------
pB = plot(f_vals, max_sell;
    marker = :circle, ms = 3, lw = 1.5, color = :darkred,
    xlabel = "Minority fraction f", ylabel = "Peak sell fraction",
    title = "B", _panel_kw...)
vline!(pB, [fc]; linestyle = :dash, color = :gray50, label = false)

# ---------------------------------------------------------------------------
# Panel C — crash frequency
# ---------------------------------------------------------------------------
pC = plot(f_vals, crash_freq;
    marker = :circle, ms = 3, lw = 1.5, color = :black,
    xlabel = "Minority fraction f", ylabel = "Crash frequency",
    title = "C", _panel_kw...)
vline!(pC, [fc]; linestyle = :dash, color = :gray50, label = false)

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig3 = plot(pA, pB, pC;
    layout = (1, 3), size = (960, 320),
    bottom_margin = 6Plots.mm, left_margin = 5Plots.mm, right_margin = 5Plots.mm,
    plot_title = "")

_save_figure(fig3, "Fig3-PhaseDiagram.pdf")
