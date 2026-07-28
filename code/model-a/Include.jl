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
include(joinpath(_PATH_TO_SRC, "PaperStyle.jl"))

gr()   # reinitialise GR backend — prevents stale render cache on repeated runs

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

"""
    _load_phase_sweep()

Load the coarse f-sweep (`ModelA-PhaseSweep.jld2`) and, if present, the fine
f-sweep (`ModelA-PhaseSweep-Fine.jld2`), merging the fine values in where the
two overlap. Shared by every script that plots a summary vs f (mean sell
fraction, peak sell fraction, crash frequency) so the load-and-merge logic
lives in one place instead of being copied into each script.

Returns `(f_vals, all_sweep)`: `f_vals` is the sorted vector of f values,
`all_sweep` is a `Dict{Float64,Dict}` keyed by f, e.g.
`all_sweep[f]["mean_sell_fraction"]`.
"""
function _load_phase_sweep()
    d        = load(joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep.jld2"))
    f_coarse = d["f_values"]
    sweep_c  = d["sweep_results"]

    fine_path = joinpath(_PATH_TO_DATA, "ModelA-PhaseSweep-Fine.jld2")
    if isfile(fine_path)
        df      = load(fine_path)
        sweep_f = df["sweep_results"]
        # Merge: fine sweep values override coarse where they overlap
        all_sweep = merge(sweep_c, sweep_f)
        f_vals    = sort(collect(keys(all_sweep)))
    else
        all_sweep = sweep_c
        f_vals    = sort(collect(f_coarse))
    end
    return f_vals, all_sweep
end
