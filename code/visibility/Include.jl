# Use the corrected manuscript's unchanged simulation source. Prepared studies
# carry their own copy under code/src and need no files from the parent project.
using Random, Statistics, DataFrames, CSV, ProgressMeter, SHA, Dates
const VISIBILITY_BASE = let
    archive = joinpath(@__DIR__, "..", "..", "output", "rebuilt",
                       "manuscript-reserve-v1", "code", "src")
    isdir(archive) ? archive : joinpath(@__DIR__, "..", "src")
end
for name in ("Types.jl", "Factory.jl", "Wolfram.jl", "Compute.jl", "Simulate.jl")
    include(joinpath(VISIBILITY_BASE, name))
end
include("Visibility.jl")
