# Fig3-PhaseDiagram.jl
# Loads: data/ModelA-PhaseSweep.jld2 + data/ModelA-PhaseSweep-Fine.jld2
# Produces: figs/Fig3-PhaseDiagram.pdf  →  paper-arxiv/figs/Fig3-PhaseDiagram.pdf
#
# Single panel: peak (max) sell fraction vs f. The mean-sell-fraction and
# crash-frequency panels that used to live here (as panels A and C) moved to
# Fig2-Combined.jl, which now emits the merged Fig2-Crossover.pdf (snapshot
# montage + mean sell + crash frequency). This script keeps only the panel
# that figure displaced; a later task re-homes it as FigS3-PeakSell.pdf.

include(joinpath(@__DIR__, "Include.jl"))
using Colors

# Load coarse sweep
d      = load(joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep.jld2"))
f_coarse = d["f_values"]
sweep_c  = d["sweep_results"]

# Load fine sweep (if available) and merge
fine_path = joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep-Fine.jld2")
if isfile(fine_path)
    df = load(fine_path)
    sweep_f = df["sweep_results"]
    # Merge: fine sweep values override coarse where they overlap
    all_sweep = merge(sweep_c, sweep_f)
    f_vals = sort(collect(keys(all_sweep)))
else
    all_sweep = sweep_c
    f_vals = sort(collect(f_coarse))
end

max_sell = [all_sweep[f]["max_sell_fraction"] for f in f_vals]

# Vertical dashed line marks the midpoint of the crossover bracket (0.15-0.20);
# it is not an independently fitted critical point.
fc = 0.145

# ---------------------------------------------------------------------------
# Peak sell fraction vs f
# ---------------------------------------------------------------------------
pB = plot(f_vals, max_sell;
    marker = :circle, ms = 3, lw = 1.5, color = _SELL_COLOR,
    xlabel = "Minority fraction f", ylabel = "Peak sell fraction",
    legend = false, _panel_kw...)
vline!(pB, [fc]; linestyle = :dash, color = :gray50, label = false)

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig3 = plot(pB; size = (480, 380))

_save_figure(fig3, "Fig3-PhaseDiagram.pdf")
