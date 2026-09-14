# test_finitesize_frames.jl -- run_cell_frames() matches the sell fraction
# run_cell_trajectory() reports at the same absolute time, same seed.
# Run: julia --project=code code/test/runtests.jl

using Test

include(joinpath(@__DIR__, "..", "model-a", "FiniteSize-Lib.jl"))

@testset "run_cell_frames" begin
    L, f, seed, t_max = 32, 0.2, 1, 500

    frames = run_cell_frames(L, f, seed, t_max, Int64[t_max])
    @test size(frames[t_max]) == (32, 32)

    # Same init, same burn-in (default 200), same stepping as run_cell_trajectory
    # sampled once at t = t_max -- the two code paths must land on the same grid.
    ts, xs = run_cell_trajectory(L, f, seed; t_max = t_max, burn_in = 200,
                                 sample_every = t_max)
    @test ts == [t_max]
    @test sell_fraction(frames[t_max]) ≈ xs[1]
end

println("FiniteSize frames OK")
