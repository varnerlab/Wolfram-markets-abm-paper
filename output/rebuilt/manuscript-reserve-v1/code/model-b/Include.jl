# model-b/Include.jl

# Use the frozen project supplied by the clean-run command.

using DataFrames, CSV, LinearAlgebra, Statistics
using JLD2, FileIO, Random, ProgressMeter
using Plots, StatsPlots
using Distributions, StatsBase

Random.seed!(1234)

const _PATH_TO_SRC        = joinpath(@__DIR__, "..", "src")
const _PATH_TO_DATA       = joinpath(@__DIR__, "..", "data")
const _PATH_TO_FIGS       = joinpath(@__DIR__, "..", "figs")
const _PATH_TO_PAPER_FIGS = joinpath(@__DIR__, "..", "..", "paper-arxiv", "figs")

include(joinpath(_PATH_TO_SRC, "Types.jl"))
include(joinpath(_PATH_TO_SRC, "Factory.jl"))
include(joinpath(_PATH_TO_SRC, "Wolfram.jl"))
include(joinpath(_PATH_TO_SRC, "Compute.jl"))
include(joinpath(_PATH_TO_SRC, "Files.jl"))
include(joinpath(_PATH_TO_SRC, "Simulate.jl"))
include(joinpath(_PATH_TO_SRC, "PaperStyle.jl"))
include(joinpath(_PATH_TO_SRC, "StripPanels.jl"))

function _save_figure(fig, filename::String)
    local_path = joinpath(_PATH_TO_FIGS, filename)
    paper_path = joinpath(_PATH_TO_PAPER_FIGS, filename)
    savefig(fig, local_path)
    isdir(_PATH_TO_PAPER_FIGS) && cp(local_path, paper_path; force = true)
    @info "Saved: $(filename)"
end

function _grid_panel(grid::Array{Int64,2}, title::String = "")
    heatmap(grid;
        c = _grid_cgrad(), clims = (0, 2),
        axis = false, colorbar = false,
        yflip = true, title = title, titlefont = 8)
end

include(joinpath(_PATH_TO_SRC,"RebuildRuntime.jl"))
