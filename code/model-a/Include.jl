# model-a/Include.jl

import Pkg; Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()

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

# ---------------------------------------------------------------------------
# Color palette — change _PALETTE to switch all figures at once
#   :wong        colorblind-safe blue / gray / vermillion  (PNAS recommended)
#   :finance     conventional green / gray / red
# ---------------------------------------------------------------------------
const _PALETTE = :wong

const _BUY_COLOR, _HOLD_COLOR, _SELL_COLOR = if _PALETTE == :wong
    ("#0072B2", "#AAAAAA", "#D55E00")   # deep blue / medium gray / vermillion
elseif _PALETTE == :finance
    ("#27AE60", "#BDC3C7", "#C0392B")   # green / cool gray / dark red
else
    ("#0072B2", "#DDDDDD", "#D55E00")
end

gr()   # reinitialise GR backend — prevents stale render cache on repeated runs

function _grid_cgrad()
    cgrad([_BUY_COLOR, _HOLD_COLOR, _SELL_COLOR], [0.0, 0.5, 1.0])
end

function _save_figure(fig, filename::String)
    local_path = joinpath(_PATH_TO_FIGS, filename)
    paper_path = joinpath(_PATH_TO_PAPER_FIGS, filename)
    savefig(fig, local_path)
    isdir(_PATH_TO_PAPER_FIGS) || mkpath(_PATH_TO_PAPER_FIGS)
    cp(local_path, paper_path; force = true)
    @info "Saved (local): $(local_path)"
    @info "Saved (paper): $(paper_path)"
end

function _grid_panel(grid::Array{Int64,2}, title::String = "")
    heatmap(grid;
        c = _grid_cgrad(), clims = (0, 2),
        axis = false, colorbar = false,
        yflip = true, title = title, titlefont = 8)
end
