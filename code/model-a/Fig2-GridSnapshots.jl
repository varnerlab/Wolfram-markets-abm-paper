# Fig2-GridSnapshots.jl
# Loads: data/ModelA-Homogeneous.jld2
# Produces:
#   figs/Fig2-GridSnapshots-a5-text.pdf -> tight 2×4 snapshot panel with black time labels
#
# Layout: 2×4 grid of snapshots
#         (t = 1, 32, 64, 128, 512, 1024, 4096, 16384)

include(joinpath(@__DIR__, "Include.jl"))
gr()

"""Build a tight 2×4 canvas from 8 simulation states with no inter-panel gaps."""
function _build_tight_grid_canvas(
    grids::Vector{Matrix{Int64}},
    nrows::Int = 2,
    ncols::Int = 4;
    gap::Int = 0,
)
    @assert length(grids) == nrows * ncols "Need exactly $(nrows * ncols) grids, got $(length(grids))"

    h, w = size(grids[1])
    canvas_h = nrows * h + (nrows - 1) * gap
    canvas_w = ncols * w + (ncols - 1) * gap
    canvas = fill(0, canvas_h, canvas_w)

    for (k, grid) in enumerate(grids)
        r = (k - 1) ÷ ncols
        c = (k - 1) % ncols
        y0 = r * (h + gap) + 1
        x0 = c * (w + gap) + 1
        canvas[y0:(y0 + h - 1), x0:(x0 + w - 1)] .= grid
    end

    return canvas
end

"""Add black 't = ...' labels in each panel's upper-right corner."""
function _label_snapshot_times!(
    plt,
    times::Vector{Int};
    nrows::Int = 2,
    ncols::Int = 4,
    panel_h::Int,
    panel_w::Int,
)
    ypad = 18
    xpad = 6

    for k in eachindex(times)
        r = (k - 1) ÷ ncols
        c = (k - 1) % ncols
        x = c * panel_w + panel_w - xpad
        y = panel_h * (nrows - r) - ypad
        t_idx = (nrows - 1 - r) * ncols + c + 1
        t = times[t_idx]
        annotate!(plt, x, y, text("t = $(t)", 8, :black, :right, :top))
    end

    return plt
end

"""
Save a plot to PDF by rendering to PNG first and converting with ImageMagick.
This keeps annotations as they appear in the rasterized preview.
"""
function _save_via_png_to_pdf(plt, pdf_filename::String)
    png_filename = replace(pdf_filename, r"\.pdf$" => ".png")

    local_png = joinpath(_PATH_TO_FIGS, png_filename)
    local_pdf = joinpath(_PATH_TO_FIGS, pdf_filename)
    paper_png = joinpath(_PATH_TO_PAPER_FIGS, png_filename)
    paper_pdf = joinpath(_PATH_TO_PAPER_FIGS, pdf_filename)

    isdir(_PATH_TO_FIGS) || mkpath(_PATH_TO_FIGS)
    isdir(_PATH_TO_PAPER_FIGS) || mkpath(_PATH_TO_PAPER_FIGS)

    savefig(plt, local_png)
    cp(local_png, paper_png; force = true)

    try
        run(`magick $(local_png) $(local_pdf)`)
        cp(local_pdf, paper_pdf; force = true)
        @info "Saved png:  $(local_png)"
        @info "Saved png/paper:  $(paper_png)"
        @info "Saved pdf via png route: $(local_pdf)"
        @info "Saved pdf/paper: $(paper_pdf)"
    catch
        @warn "PNG->PDF conversion failed (`magick` unavailable/errored). Falling back to Plots PDF save."
        _save_figure(plt, pdf_filename)
    end
end

d      = load(joinpath(_PATH_TO_DATA, "ModelA-Homogeneous.jld2"))
frames = d["frames"]
steps  = sort(collect(keys(frames)))

# ---------------------------------------------------------------------------
# Snapshot times: snap each target to the nearest available step
# ---------------------------------------------------------------------------
targets    = [1, 32, 64, 128, 512, 1024, 4096, 16384]
snap_times = [steps[argmin(abs.(steps .- t))] for t in targets]

# Build 2×4 simulation panel by direct image composition (no layout gaps).
snap_panels = [frames[t] for t in snap_times]
grid_canvas = _build_tight_grid_canvas(snap_panels)
panel_h, panel_w = size(snap_panels[1])

fig2_a = heatmap(grid_canvas;
    c = _grid_cgrad(),
    clims = (0, 2),
    axis = false,
    colorbar = false,
    yflip = true,
    aspect_ratio = :equal,
    framestyle = :none,
    margin = 0.0Plots.mm,
    left_margin = 0.0Plots.mm,
    right_margin = 0.0Plots.mm,
    top_margin = 0.0Plots.mm,
    bottom_margin = 0.0Plots.mm,
    xticks = false,
    yticks = false,
    size = (1024, 512))

plot!(fig2_a;
    xlim = (0.5, size(grid_canvas, 2) + 0.5),
    ylim = (0.5, size(grid_canvas, 1) + 0.5),
)
_label_snapshot_times!(fig2_a, snap_times; panel_h = panel_h, panel_w = panel_w)

_save_via_png_to_pdf(fig2_a, "Fig2-GridSnapshots-a5-text.pdf")

@info "Saved tight grid only: Fig2-GridSnapshots-a5-text.pdf"
