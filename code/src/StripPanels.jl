# StripPanels.jl -- seamless "market strip" montage: one heatmap, NaN gutters.
# Requires PaperStyle.jl (for _grid_cgrad) to be included first.
function _strip_canvas(frames::Vector{<:AbstractMatrix}; gap::Int64 = 4)
    n = length(frames); H, W = size(frames[1])
    canvas = fill(NaN, H, n*W + (n-1)*gap)
    for (i, F) in enumerate(frames)
        c0 = (i-1)*(W + gap)
        canvas[:, (c0+1):(c0+W)] .= Float64.(F)
    end
    return canvas
end

# Boundary segments (as one NaN-separated x/y series) tracing the outline of
# `mask`, offset into tile `i`'s slot of the strip canvas (tile x-origin
# `x0`). Cell (r, c) occupies canvas coordinates x in [x0+c-0.5, x0+c+0.5],
# y in [r-0.5, r+0.5] (matching the existing `marks` scatter convention,
# where a cell (row, col) is plotted at x = x0 + col, y = row). For every
# masked cell and each of its 4-neighbours that is OUTSIDE the mask
# (off-grid counts as outside), the shared edge between them is emitted.
function _mask_outline_xy(mask::AbstractMatrix{Bool}, x0::Real)
    nr, nc = size(mask)
    xs = Float64[]
    ys = Float64[]
    for r in 1:nr, c in 1:nc
        mask[r, c] || continue
        if r == 1 || !mask[r-1, c]           # north edge
            append!(xs, (x0 + c - 0.5, x0 + c + 0.5, NaN))
            append!(ys, (r - 0.5, r - 0.5, NaN))
        end
        if r == nr || !mask[r+1, c]          # south edge
            append!(xs, (x0 + c - 0.5, x0 + c + 0.5, NaN))
            append!(ys, (r + 0.5, r + 0.5, NaN))
        end
        if c == 1 || !mask[r, c-1]           # west edge
            append!(xs, (x0 + c - 0.5, x0 + c - 0.5, NaN))
            append!(ys, (r - 0.5, r + 0.5, NaN))
        end
        if c == nc || !mask[r, c+1]          # east edge
            append!(xs, (x0 + c + 0.5, x0 + c + 0.5, NaN))
            append!(ys, (r - 0.5, r + 0.5, NaN))
        end
    end
    return xs, ys
end

function _strip_panel(frames::Vector{<:AbstractMatrix}, labels::Vector{String};
                      gap::Int64 = 4, marks = nothing, rowlabel::String = "",
                      outlines = nothing)
    canvas = _strip_canvas(frames; gap = gap)
    H, W = size(frames[1]); n = length(frames)
    plt = heatmap(canvas; c = _grid_cgrad(), clims = (0, 2), yflip = true,
                  aspect_ratio = :equal, axis = false, colorbar = false,
                  framestyle = :none, background_color_inside = :white,
                  ylims = (-0.18*H, H + 0.5), margin = 0Plots.mm)
    for (i, lab) in enumerate(labels)
        cx = (i - 1)*(W + gap) + W/2
        annotate!(plt, cx, -0.10*H, text(lab, :black, :center, 8, "helvetica"))
    end
    if marks !== nothing
        for (i, rc) in pairs(marks)
            rc === nothing && continue
            cx = (i - 1)*(W + gap) + rc[2]
            scatter!(plt, [cx], [rc[1]]; marker = :xcross, markersize = 6,
                     markercolor = :white, markerstrokecolor = :black,
                     markerstrokewidth = 1.4, label = "")
        end
    end
    if outlines !== nothing
        for (i, m) in pairs(outlines)
            m === nothing && continue
            x0      = (i - 1)*(W + gap)
            xs, ys  = _mask_outline_xy(m, x0)
            isempty(xs) && continue
            plot!(plt, xs, ys; seriescolor = :black, linewidth = 1.2, label = "")
        end
    end
    isempty(rowlabel) || annotate!(plt, -0.05*(n*W + (n-1)*gap), H/2,
        text(rowlabel, :black, :center, 8, "helvetica"; rotation = 90))
    return plt
end
