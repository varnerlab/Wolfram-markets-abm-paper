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

function _strip_panel(frames::Vector{<:AbstractMatrix}, labels::Vector{String};
                      gap::Int64 = 4, marks = nothing, rowlabel::String = "")
    canvas = _strip_canvas(frames; gap = gap)
    H, W = size(frames[1]); n = length(frames)
    plt = heatmap(canvas; c = _grid_cgrad(), clims = (0, 2), yflip = true,
                  aspect_ratio = :equal, axis = false, colorbar = false,
                  framestyle = :none, background_color_inside = :white,
                  ylims = (-0.14*H, H + 0.5), margin = 0Plots.mm)
    for (i, lab) in enumerate(labels)
        cx = (i - 1)*(W + gap) + W/2
        annotate!(plt, cx, -0.08*H, text(lab, :black, :center, 8, "helvetica"))
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
    isempty(rowlabel) || annotate!(plt, -0.05*(n*W + (n-1)*gap), H/2,
        text(rowlabel, :black, :center, 8, "helvetica"; rotation = 90))
    return plt
end
