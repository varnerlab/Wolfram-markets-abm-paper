# Load only the packages needed for simulation and tabular output.
using Random, Statistics, DataFrames, CSV, ProgressMeter, SHA, Dates

for name in ("Types.jl", "Factory.jl", "Wolfram.jl", "Compute.jl",
             "Simulate.jl")
    include(joinpath(@__DIR__, "..", "src", name))
end
include("FeeClearing.jl")
include("FeeSimulation.jl")
