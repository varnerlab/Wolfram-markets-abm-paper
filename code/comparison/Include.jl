# comparison/Include.jl

import Pkg; Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()

using DataFrames, CSV, LinearAlgebra, Statistics, Printf
using JLD2, FileIO, Random, ProgressMeter
using Plots, StatsPlots, Colors
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

const _PALETTE = :wong
const _BUY_COLOR, _HOLD_COLOR, _SELL_COLOR = if _PALETTE == :wong
    ("#0072B2", "#DDDDDD", "#D55E00")
elseif _PALETTE == :finance
    ("#27AE60", "#BDC3C7", "#C0392B")
else
    ("#0072B2", "#DDDDDD", "#D55E00")
end
_grid_cgrad() = cgrad([_BUY_COLOR, _HOLD_COLOR, _SELL_COLOR], [0.0, 0.5, 1.0])

function _save_figure(fig, filename::String)
    local_path = joinpath(_PATH_TO_FIGS, filename)
    paper_path = joinpath(_PATH_TO_PAPER_FIGS, filename)
    savefig(fig, local_path)
    isdir(_PATH_TO_PAPER_FIGS) && cp(local_path, paper_path; force = true)
    @info "Saved: $(filename)"
end
