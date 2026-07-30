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

# _strip_letter_row: a blank panel that carries only the panel-letter
# annotation `_panel_letter!` (PaperStyle.jl) draws. Shared by the four
# strip-anchor/corner-letter blocks (Figs-ModelB-BoundaryVsBulk.jl,
# Figs-ModelB-BarrierLaw.jl, Figs-ModelB-BudgetToggle.jl,
# Figs-ModelA-FiniteSize.jl) instead of each rebuilding the same blank
# `plot(...)` + `_panel_letter!` call inline.
row = _strip_letter_row("A")
@test row isa Plots.Plot
row_ann = only(row.subplots[1][:annotations])
@test row_ann[2].str == "A"
row_b = _strip_letter_row("B")
@test only(row_b.subplots[1][:annotations])[2].str == "B"

println("StripPanels OK")
