# Include.jl — Environment setup, package loading, and src includes

const _ROOT           = pwd()
const _PATH_TO_SRC    = joinpath(_ROOT, "src")
const _PATH_TO_DATA   = joinpath(_ROOT, "data")
const _PATH_TO_FIGS   = joinpath(_ROOT, "figs")
const _PATH_TO_FRAMES = joinpath(_ROOT, "frames")

using Pkg
if isfile(joinpath(_ROOT, "Manifest.toml")) == false
    Pkg.activate(".")
    Pkg.resolve()
    Pkg.instantiate()
end

using DataFrames, CSV, LinearAlgebra, Statistics
using JLD2, FileIO, Random, ProgressMeter

include(joinpath(_PATH_TO_SRC, "Types.jl"))
include(joinpath(_PATH_TO_SRC, "Factory.jl"))
include(joinpath(_PATH_TO_SRC, "Wolfram.jl"))
include(joinpath(_PATH_TO_SRC, "Compute.jl"))
include(joinpath(_PATH_TO_SRC, "Files.jl"))
include(joinpath(_PATH_TO_SRC, "Simulate.jl"))
include(joinpath(_PATH_TO_SRC, "Following.jl"))
include(joinpath(_PATH_TO_SRC, "FollowingMetrics.jl"))
