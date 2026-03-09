# Fig2-Combined.jl
# Loads: ModelA-Homogeneous.jld2, ModelA-Critical.jld2, ModelA-Crash.jld2
# Produces: figs/Fig2-Combined.pdf → paper/figs/Fig2-Combined.pdf
#
# Layout (3 rows × 4 columns):
#   Top row:    Homogeneous (Rule 19280, f = 0)      — stable market
#   Middle row: Critical    (19280 + 19286, f = 0.15) — crash emerging
#   Bottom row: Crashed     (19280 + 19286, f = 0.20) — sell-dominated

include(joinpath(@__DIR__, "Include.jl"))
using Colors

hom  = load(joinpath(_PATH_TO_DATA, "ModelA-Homogeneous.jld2"))
crit = load(joinpath(_PATH_TO_DATA, "ModelA-Critical.jld2"))
cr   = load(joinpath(_PATH_TO_DATA, "ModelA-Crash.jld2"))

frames_hom  = hom["frames"]
frames_crit = crit["frames"]
frames_cr   = cr["frames"]

# 4 shared snapshot times — all post-wavefront, exact matches across all 3 datasets
snap_steps = [581, 2851, 8236, 23790]

# ---------------------------------------------------------------------------
# Style
# ---------------------------------------------------------------------------
function _snap_panel(grid, title)
    heatmap(grid;
        c = _grid_cgrad(), clims = (0, 2),
        yflip = true, aspect_ratio = :equal,
        axis = false, colorbar = false, framestyle = :none,
        title = title, titlefontsize = 9,
        margin = 0Plots.mm,
        top_margin = 3Plots.mm,
    )
end

# ---------------------------------------------------------------------------
# Build panels
# ---------------------------------------------------------------------------
panels = []

# Row labels
row_labels = ["f = 0", "f = 0.15", "f = 0.20"]
row_frames = [frames_hom, frames_crit, frames_cr]

for (label, fdict) in zip(row_labels, row_frames)
    for t in snap_steps
        push!(panels, _snap_panel(fdict[t], "$label,  t = $t"))
    end
end

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig2 = plot(panels...;
    layout = (3, 4),
    size = (1000, 760),
    plot_title = "",
    margin = 0Plots.mm,
)

_save_figure(fig2, "Fig2-Combined.pdf")
