using Test
using Plots

include(joinpath(@__DIR__, "..", "src", "PaperStyle.jl"))
include(joinpath(@__DIR__, "..", "src", "StripPanels.jl"))

frames = [fill(2, 8, 8), fill(0, 8, 8), fill(1, 8, 8)]
canvas = _strip_canvas(frames; gap = 4)
@test size(canvas) == (8, 3*8 + 2*4)
@test all(isnan, canvas[:, 9:12])          # first gutter
@test canvas[1, 1] == 2.0 && canvas[1, 13] == 0.0
plt = _strip_panel(frames, ["t = 1", "t = 2", "t = 3"]; marks = Dict(1 => (3, 3)))
@test plt isa Plots.Plot

println("StripPanels OK")
