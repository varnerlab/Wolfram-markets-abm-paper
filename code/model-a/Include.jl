# model-a/Include.jl

import Pkg; Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()

using DataFrames, CSV, LinearAlgebra, Statistics
using JLD2, FileIO, Random, ProgressMeter
using Plots, StatsPlots, Colors, Images
using Distributions, StatsBase

Random.seed!(1234)

const _PATH_TO_SRC        = joinpath(@__DIR__, "..", "src")
const _PATH_TO_DATA       = joinpath(@__DIR__, "..", "data")
const _PATH_TO_FIGS       = joinpath(@__DIR__, "..", "figs")
const _PATH_TO_PAPER_FIGS = joinpath(@__DIR__, "..", "..", "paper", "figs")

include(joinpath(_PATH_TO_SRC, "Types.jl"))
include(joinpath(_PATH_TO_SRC, "Factory.jl"))
include(joinpath(_PATH_TO_SRC, "Wolfram.jl"))
include(joinpath(_PATH_TO_SRC, "Compute.jl"))
include(joinpath(_PATH_TO_SRC, "Files.jl"))
include(joinpath(_PATH_TO_SRC, "Simulate.jl"))

function _save_figure(fig, filename::String)
    local_path = joinpath(_PATH_TO_FIGS, filename)
    paper_path = joinpath(_PATH_TO_PAPER_FIGS, filename)
    savefig(fig, local_path)
    isdir(_PATH_TO_PAPER_FIGS) && cp(local_path, paper_path; force = true)
    @info "Saved: $(filename)"
end

function _grid_to_image(grid::Array{Int64,2})::Array{RGB{Float64},2}
    color_map = Dict(0 => colorant"lightgreen", 1 => colorant"gray95", 2 => colorant"red")
    img = Array{RGB{Float64},2}(undef, size(grid)...)
    for r in axes(grid,1), c in axes(grid,2)
        img[r,c] = color_map[grid[r,c]]
    end
    return img
end
