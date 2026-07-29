using Test
using Plots

include(joinpath(@__DIR__, "..", "src", "PaperStyle.jl"))
include(joinpath(@__DIR__, "..", "src", "StripPanels.jl"))

frames = [fill(2, 8, 8), fill(0, 8, 8), fill(1, 8, 8)]
header = 10
canvas = _strip_canvas(frames; gap = 4)
@test size(canvas) == (8 + header, 3*8 + 2*4)
@test all(isnan, canvas[:, 9:12])                        # first gutter (all rows)
@test all(isnan, canvas[1, :])                            # header row is all-NaN
@test canvas[header + 1, 1] == 2.0 && canvas[header + 1, 13] == 0.0
plt = _strip_panel(frames, ["t = 1", "t = 2", "t = 3"]; marks = Dict(1 => (3, 3)))
@test plt isa Plots.Plot

# _strip_canvas is unaffected by the outlines amendment (isequal, not ==, so
# the NaN gutter columns compare equal to themselves)
canvas2 = _strip_canvas(frames; gap = 4)
@test isequal(canvas2, canvas)

# A single-true mask (tile 1 only, all other tiles unmasked) on 8x8 frames
# renders without error via the outlines kwarg.
mask = falses(8, 8)
mask[3, 3] = true
plt_outlined = _strip_panel(frames, ["t = 1", "t = 2", "t = 3"];
                             outlines = [mask, nothing, nothing])
@test plt_outlined isa Plots.Plot

println("StripPanels OK")
