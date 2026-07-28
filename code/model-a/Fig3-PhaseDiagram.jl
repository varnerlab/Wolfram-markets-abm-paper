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

# Load coarse + fine sweep (merged) — shared with Fig2-Combined.jl via
# `_load_phase_sweep()` in Include.jl so the merge logic lives in one place.
f_vals, all_sweep = _load_phase_sweep()

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
