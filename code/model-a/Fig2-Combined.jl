# Fig2-Combined.jl
# Loads: ModelA-Homogeneous.jld2, ModelA-Critical.jld2, ModelA-Crash.jld2,
#        ModelA-PhaseSweep.jld2 (+ ModelA-PhaseSweep-Fine.jld2)
# Produces: figs/Fig2-Crossover.pdf → paper-arxiv/figs/Fig2-Crossover.pdf
#
# Three panels:
#   A  snapshot montage (3 f-regimes x 4 time steps, post-wavefront)
#   B  mean sell fraction vs f
#   C  crash frequency vs f
#
# B and C used to live in Fig3-PhaseDiagram.jl as its panels A and C. They
# moved here so the crossover story (snapshots plus the two f-sweep summaries
# that define the crossover) reads as one figure. Fig3-PhaseDiagram.jl keeps
# only the peak-sell panel that this figure displaced (a supplementary figure
# later on). Peak sell fraction is NOT reproduced here.

include(joinpath(@__DIR__, "Include.jl"))
using Colors

# ---------------------------------------------------------------------------
# Load snapshot montage data
# ---------------------------------------------------------------------------
hom  = load(joinpath(_PATH_TO_DATA, "ModelA-Homogeneous.jld2"))
crit = load(joinpath(_PATH_TO_DATA, "ModelA-Critical.jld2"))
cr   = load(joinpath(_PATH_TO_DATA, "ModelA-Crash.jld2"))

frames_hom  = hom["frames"]
frames_crit = crit["frames"]
frames_cr   = cr["frames"]

# 4 shared snapshot times — all post-wavefront, exact matches across all 3 datasets
snap_steps = [581, 2851, 8236, 23790]

# ---------------------------------------------------------------------------
# Load phase sweep data (coarse + fine merge) — same merge Fig3-PhaseDiagram.jl
# performs for its own (now sole) panel.
# ---------------------------------------------------------------------------
d        = load(joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep.jld2"))
f_coarse = d["f_values"]
sweep_c  = d["sweep_results"]

fine_path = joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep-Fine.jld2")
if isfile(fine_path)
    df      = load(fine_path)
    sweep_f = df["sweep_results"]
    # Merge: fine sweep values override coarse where they overlap
    all_sweep = merge(sweep_c, sweep_f)
    f_vals    = sort(collect(keys(all_sweep)))
else
    all_sweep = sweep_c
    f_vals    = sort(collect(f_coarse))
end

mean_sell  = [all_sweep[f]["mean_sell_fraction"] for f in f_vals]
crash_freq = [all_sweep[f]["crash_frequency"]    for f in f_vals]

# ---------------------------------------------------------------------------
# Assert the cited values before plotting anything
# ---------------------------------------------------------------------------
i14 = findfirst(≈(0.14), f_vals); i15 = findfirst(≈(0.15), f_vals); i20 = findfirst(≈(0.20), f_vals)
@assert mean_sell[i14] < 0.30 "at f=0.14 mean sell must stay near 0.26"
@assert mean_sell[i15] > 0.45 "at f=0.15 mean sell must jump to ~0.50"
@assert isapprox(mean_sell[i20], 0.91; atol = 0.03) "f=0.20 saturation does not reproduce"
@assert crash_freq[i20] > 0.95 "crash frequency above the bracket must exceed 95%"
@assert crash_freq[i14] == 0.0 "no crashes may occur at or below f=0.14"

# Vertical dashed line marks the midpoint of the crossover bracket (0.15-0.20);
# it is not an independently fitted critical point.
fc = 0.145

# ---------------------------------------------------------------------------
# Panel A — snapshot montage
#
# Row/column identification used to be carried by `title=` on each tile; the
# house style forbids in-figure titles. A plain `ylabel=`/annotate! placed on
# the heatmap tiles themselves does not work here: an opaque `heatmap` in this
# Plots/GR version draws its raster AFTER the subplot's `:annotations` layer,
# so any text placed directly on a filled heatmap tile is drawn UNDER the
# colored cells and is invisible (verified empirically — a scatter series
# added after the heatmap DOES show on top; an annotation does not). So row
# labels (f value) and column labels (time step) get their own dedicated
# blank cells in an expanded 4x5 grid instead of being drawn on the tiles.
# ---------------------------------------------------------------------------
function _snap_panel(fdict, t)
    heatmap(fdict[t];
        c = _grid_cgrad(), clims = (0, 2),
        yflip = true, aspect_ratio = :equal,
        axis = false, colorbar = false, framestyle = :none,
        margin = 0Plots.mm)
end

_blank_panel() = plot(;
    framestyle = :none, grid = false, legend = false, ticks = false,
    xlims = (0, 1), ylims = (0, 1))

function _row_label(label::String)
    p = _blank_panel()
    annotate!(p, (0.5, 0.5), text(label, :black, :center, 9, rotation = 90))
    return p
end

function _col_label(label::String)
    p = _blank_panel()
    annotate!(p, (0.5, 0.5), text(label, :black, :center, 9))
    return p
end

row_labels = ["f = 0", "f = 0.15", "f = 0.20"]
row_frames = [frames_hom, frames_crit, frames_cr]
col_labels = ["t = $t" for t in snap_steps]

# The montage's letter goes on its first sub-panel (top-left corner), which
# reads as labeling the whole group — the heatmap tiles themselves cannot
# carry it (see note above).
corner = _blank_panel()
_panel_letter!(corner, "A")

panels = Plots.Plot[corner]
for cl in col_labels
    push!(panels, _col_label(cl))
end
for (label, fdict) in zip(row_labels, row_frames)
    push!(panels, _row_label(label))
    for t in snap_steps
        push!(panels, _snap_panel(fdict, t))
    end
end

pA = plot(panels...;
    layout = grid(4, 5;
        widths  = [0.09, 0.2275, 0.2275, 0.2275, 0.2275],
        heights = [0.10, 0.30, 0.30, 0.30]))

# ---------------------------------------------------------------------------
# Panel B — mean sell fraction vs f
# ---------------------------------------------------------------------------
pB = plot(f_vals, mean_sell;
    marker = :circle, ms = 3, lw = 1.5, color = _SELL_COLOR,
    xlabel = "Minority fraction f", ylabel = "Mean sell fraction",
    legend = false, _panel_kw...)
vline!(pB, [fc]; linestyle = :dash, color = :gray50, label = false)
_panel_letter!(pB, "B")

# ---------------------------------------------------------------------------
# Panel C — crash frequency vs f
# ---------------------------------------------------------------------------
pC = plot(f_vals, crash_freq;
    marker = :circle, ms = 3, lw = 1.5, color = _SERIES_COLORS[5],
    xlabel = "Minority fraction f", ylabel = "Crash frequency",
    legend = false, _panel_kw...)
vline!(pC, [fc]; linestyle = :dash, color = :gray50, label = false)
_panel_letter!(pC, "C")

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig = plot(pA, plot(pB, pC, layout = (1, 2)),
    layout = grid(2, 1, heights = [0.6, 0.4]), size = (1000, 900))

_save_figure(fig, "Fig2-Crossover.pdf")
