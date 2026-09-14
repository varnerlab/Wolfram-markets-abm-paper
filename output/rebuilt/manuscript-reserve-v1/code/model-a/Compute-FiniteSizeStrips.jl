## Compute-FiniteSizeStrips.jl
#
# Captures one deterministic full-grid frame per lattice size L ∈ {64, 128, 512}
# at a single common absolute time t*, for the Fig 3 size-contrast market
# strip (panel A). t* is derived from the ALREADY-COMMITTED survey summary
# (ModelA-FiniteSizeSummary.csv) rather than from a fresh run:
#
#   t* = 2 x median t_conv of the L = 512, f = 0.15 survey cell
#
# Twice the largest lattice's own median conversion time puts t* comfortably
# past where L = 512 (many-nucleus KJMA regime, fastest to escape) has almost
# certainly converged, while L = 64 (median t_conv = 39302 at the same f, a
# single/few-nucleus regime) is very likely still mixed at that same absolute
# time -- the size contrast the panel exists to show.
#
# Seed = 1 is used for every size, EXCEPT: if the L = 64 run at seed 1 has
# already converged by t* (sell_fraction > 0.90), seeds 2..20 are tried in
# turn and the first still-mixed one is kept, since a converged L = 64 tile
# would erase the very contrast the panel exists to show (see brief). L = 128
# and L = 512 always use seed = 1 -- both are expected, and required by the
# choice of t*, to already show the converged endpoint.
#
# Reads (read-only): code/data/ModelA-FiniteSizeSummary.csv
# Writes: code/data/ModelA-FiniteSizeStrips.jld2
#   keys: "L64" "L128" "L512" (each a Matrix{Int}), "tstar" (Int), "seeds"
#         (a NamedTuple (L64=.., L128=.., L512=..))
#
# Run from code/: julia --project=. model-a/Compute-FiniteSizeStrips.jl

import Pkg; Pkg.activate(joinpath(@__DIR__, "..")); Pkg.instantiate()

using CSV, DataFrames, Printf, JLD2
include(joinpath(@__DIR__, "FiniteSize-Lib.jl"))

const F_STAR       = 0.15
const MAX_SEED     = 20
const CONVERGED_SF = 0.90   # same convention run_cell uses for t_conv crossing

summ = CSV.read(joinpath(@__DIR__, "..", "data", "ModelA-FiniteSizeSummary.csv"), DataFrame)
row512 = summ[(summ.pass .== "survey") .& (summ.L .== 512) .& (summ.f .== F_STAR), :]
@assert nrow(row512) == 1 "expected exactly one survey row for L=512, f=$F_STAR"
median_t_conv_512 = row512.median_t_conv[1]
t_star = round(Int, 2 * median_t_conv_512)

println("t* = 2 x median t_conv(L=512, f=$F_STAR) = 2 x $median_t_conv_512 = $t_star")

"""
    capture_frame(L, t_star; retry_if_converged)

Capture the grid at absolute time `t_star` for lattice size `L` at f=F_STAR.
Seed 1 is used unless `retry_if_converged` is true AND seed 1 has already
converged (sell_fraction > CONVERGED_SF) by `t_star`, in which case seeds
2..MAX_SEED are tried in turn until a still-mixed one is found (or MAX_SEED
is exhausted, in which case the last seed tried -- still converged -- is
kept). Returns (frame, seed, sell_fraction, converged).
"""
function capture_frame(L::Int, t_star::Int; retry_if_converged::Bool)
    result = nothing
    for seed in 1:(retry_if_converged ? MAX_SEED : 1)
        frame = run_cell_frames(L, F_STAR, seed, t_star, Int64[t_star])[t_star]
        sf = sell_fraction(frame)
        converged = sf > CONVERGED_SF
        result = (frame = frame, seed = seed, sell_fraction = sf, converged = converged)
        if !retry_if_converged || !converged
            break
        end
        @info "L=$L seed=$seed already converged by t* -- trying next seed" sell_fraction = sf
    end
    return result
end

cap64  = capture_frame(64,  t_star; retry_if_converged = true)
cap128 = capture_frame(128, t_star; retry_if_converged = false)
cap512 = capture_frame(512, t_star; retry_if_converged = false)

println("Chosen seeds and grid state at t* = $t_star (f = $F_STAR):")
for (L, cap) in ((64, cap64), (128, cap128), (512, cap512))
    @printf("  L=%3d  seed=%2d  sell_fraction(t*)=%.3f  converged=%s\n",
            L, cap.seed, cap.sell_fraction, cap.converged)
end

seeds = (L64 = cap64.seed, L128 = cap128.seed, L512 = cap512.seed)

outpath = joinpath(@__DIR__, "..", "data", "ModelA-FiniteSizeStrips.jld2")
save(outpath, Dict(
    "L64"   => cap64.frame,
    "L128"  => cap128.frame,
    "L512"  => cap512.frame,
    "tstar" => t_star,
    "seeds" => seeds,
))
@info "Saved: ModelA-FiniteSizeStrips.jld2" path = outpath tstar = t_star seeds = seeds
