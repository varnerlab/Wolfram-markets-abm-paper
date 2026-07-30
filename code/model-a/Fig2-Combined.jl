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
# Load phase sweep data (coarse + fine merge) — shared with Fig3-PhaseDiagram.jl
# via `_load_phase_sweep()` in Include.jl so the merge logic lives in one place.
# ---------------------------------------------------------------------------
f_vals, all_sweep = _load_phase_sweep()

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
# Panel A — snapshot montage, composed as ONE heatmap
#
# Round 1 of this montage (see git history) put each of the twelve tiles in
# its own subplot, in an expanded 4x5 grid whose extra row/column carried the
# row/column labels in dedicated blank cells. That sidestepped `_panel_letter!`'s
# yflip trap (see its docstring in PaperStyle.jl) and kept every tile's own
# margin uniform, but it could not close the gap BETWEEN tiles: even with
# every subplot's own `margin = 0mm`, GR/Plots.jl reserves a per-subplot
# floor of order 70-90px at 110dpi around every individual subplot,
# regardless of that subplot's cell size or the grid fractions feeding it
# (confirmed with isolated probe renders) — a floor paid twelve times over.
#
# This montage instead follows the `StripPanels.jl` idiom already used for
# Figs 5-7 (`_strip_canvas`/`_strip_panel`): compose every tile into ONE
# Float64 matrix with NaN gutters between tiles, a NaN header band above for
# the column (`t = ...`) labels and a NaN left band beside it for the row
# (`f = ...`) labels, then draw the whole thing with a SINGLE `heatmap` call.
# Because there is only one subplot, the GR per-subplot margin floor above is
# paid once for the whole montage, not once per tile — the gap between tiles
# is exactly `gap` canvas cells (a few px at any reasonable figure size),
# not a fixed ~80px GR floor.
#
# `_strip_canvas`/`_strip_panel` assume one label row and no left band (every
# existing call site stacks at most two strips, each carrying its OWN
# row label via the `rowlabel` kwarg, drawn outside the canvas at a
# negative x). This montage needs THREE rows sharing one header row of
# column labels, so it gets a local, Fig2-specific canvas/panel pair below
# rather than a change to the shared helper (which every other figure using
# `_strip_panel` still relies on as-is).
#
# Column and row labels are `annotate!`ed at ABSOLUTE canvas data
# coordinates (not `_panel_letter!`'s relative-fraction call shape), inside
# the canvas's own NaN header/left bands, exactly like `_strip_panel`'s
# column-label annotations — so the yflip trap documented in
# `_panel_letter!`'s docstring does not apply here either. The panel letter
# itself still cannot live on the yflip'd heatmap, so it uses the same
# `_strip_letter_row` + `@layout([a{0.08h}; b])` anchor idiom as Figs 5-7.
# ---------------------------------------------------------------------------
function _fig2_montage_canvas(row_frames, snap_steps::Vector{Int};
                               gap::Int64 = 4, header::Int64 = 30, leftband::Int64 = 30)
    n = length(snap_steps); nrows = length(row_frames)
    H, W = size(row_frames[1][snap_steps[1]])
    total_rows = header + nrows*H + (nrows - 1)*gap
    total_cols = leftband + n*W + (n - 1)*gap
    canvas = fill(NaN, total_rows, total_cols)
    for (ri, fdict) in enumerate(row_frames)
        r0 = header + (ri - 1)*(H + gap)
        for (ci, t) in enumerate(snap_steps)
            c0 = leftband + (ci - 1)*(W + gap)
            canvas[(r0+1):(r0+H), (c0+1):(c0+W)] .= Float64.(fdict[t])
        end
    end
    return canvas, H, W
end

function _fig2_montage_panel(row_frames, row_labels::Vector{String},
                              snap_steps::Vector{Int}, col_labels::Vector{String};
                              gap::Int64 = 4, header::Int64 = 30, leftband::Int64 = 30)
    canvas, H, W = _fig2_montage_canvas(row_frames, snap_steps;
                                         gap = gap, header = header, leftband = leftband)
    total_rows, total_cols = size(canvas)
    plt = heatmap(canvas; c = _grid_cgrad(), clims = (0, 2), yflip = true,
                  aspect_ratio = :equal, axis = false, colorbar = false,
                  framestyle = :none, background_color_inside = :white,
                  xlims = (0.5, total_cols + 0.5), ylims = (0.5, total_rows + 0.5),
                  margin = 0Plots.mm)
    # Label anchors sit at the midpoint of their NaN band (not `0.45`, which
    # hugged the tile edge in round 2) so the enlarged 12pt labels are
    # centered between the letter/canvas edge and the first tile row/column,
    # giving clear standoff on both sides.
    for (ci, lab) in enumerate(col_labels)
        cx = leftband + (ci - 1)*(W + gap) + W/2
        annotate!(plt, cx, header*0.5, text(lab, :black, :center, 12, "helvetica"))
    end
    for (ri, lab) in enumerate(row_labels)
        ry = header + (ri - 1)*(H + gap) + H/2
        annotate!(plt, leftband*0.5, ry, text(lab, :black, :center, 12, "helvetica"; rotation = 90))
    end
    return plt
end

row_labels = ["f = 0", "f = 0.15", "f = 0.20"]
row_frames = [frames_hom, frames_crit, frames_cr]
col_labels = ["t = $t" for t in snap_steps]

strip_body = _fig2_montage_panel(row_frames, row_labels, snap_steps, col_labels)
_letterA   = _strip_letter_row("A")
pA = plot(_letterA, strip_body; layout = @layout([a{0.08h}; b]))

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
fig = plot(pA, pB, pC;
    layout = @layout([a{0.676h}; b c]),
    size = (1160, 1440))

_save_figure(fig, "Fig2-Crossover.pdf")
