# Test-BoundaryVsBulk.jl — unit tests for BoundaryVsBulk-Lib.jl
# Run from repo root: julia code/model-b/Test-BoundaryVsBulk.jl

include(joinpath(@__DIR__, "Include.jl"))
include(joinpath(@__DIR__, "BoundaryVsBulk-Lib.jl"))
using Test

@testset "chebyshev_boundary_distance" begin
    @test chebyshev_boundary_distance(2, 2, 64, 64)   == 1
    @test chebyshev_boundary_distance(32, 32, 64, 64) == 31
    @test chebyshev_boundary_distance(1, 10, 64, 64)  == 0   # boundary cell
    @test chebyshev_boundary_distance(2, 63, 64, 64)  == 1
end

@testset "null_shell_pmf" begin
    pmf = null_shell_pmf(64)
    @test length(pmf) == 31
    @test pmf[1] ≈ 244 / 3844          # (62² − 60²)/62²
    @test sum(pmf) ≈ 1.0
    @test sum(pmf[1:2]) ≈ 480 / 3844   # ≈ 0.125, the d ≤ 2 null

    small = null_shell_pmf(6)          # 4×4 interior: 12 cells at d=1, 4 at d=2
    @test small ≈ [12 / 16, 4 / 16]
end

@testset "binom_two_sided_p" begin
    @test binom_two_sided_p(6, 3, 0.5) ≈ 1.0
    @test binom_two_sided_p(6, 0, 0.5) ≈ 2 * (1 / 64)
    @test binom_two_sided_p(3, 3, 0.125) ≈ 0.125^3
end

@testset "patch_side" begin
    @test patch_side(9)  == 3
    @test patch_side(25) == 5
    @test patch_side(17) == 3   # tie → 3
    @test patch_side(1)  == 3
    @test patch_side(40) == 5
end

@testset "label_interior_sell_clusters" begin
    g = fill(1, 8, 8)
    g[2, 2] = 2; g[2, 3] = 2; g[3, 2] = 2      # blob A (row-major first)
    g[6, 6] = 2; g[7, 6] = 2                   # blob B
    g[5, 2] = 2                                # singleton C
    g[1, 4] = 2; g[8, 8] = 2; g[4, 1] = 2      # boundary sells — excluded
    labels, sizes = label_interior_sell_clusters(g)
    @test sizes == [3, 1, 2]                   # row-major discovery: A, C, B
    @test labels[2, 2] == labels[2, 3] == labels[3, 2] == 1
    @test labels[5, 2] == 2
    @test labels[6, 6] == labels[7, 6] == 3
    @test labels[1, 4] == 0 && labels[8, 8] == 0 && labels[4, 1] == 0
    @test Set(cluster_cells(labels, 1)) ==
          Set([CartesianIndex(2, 2), CartesianIndex(2, 3), CartesianIndex(3, 2)])

    empty_labels, empty_sizes = label_interior_sell_clusters(fill(1, 8, 8))
    @test isempty(empty_sizes) && all(==(0), empty_labels)
end

@testset "label_sequence" begin
    g1 = fill(1, 6, 6); g1[3, 3] = 2
    g2 = fill(1, 6, 6); g2[3, 3] = 2; g2[3, 4] = 2
    frames = Dict{Int64,Matrix{Int64}}(0 => fill(1, 6, 6), 1 => g1, 2 => g2)
    labels, sizes = label_sequence(frames, 2)
    @test length(labels) == 2
    @test sizes[1] == [1] && sizes[2] == [2]
end

"""Build (labels, sizes) sequences from a vector of hand-made grids."""
function _labelseq(grids::Vector{Matrix{Int64}})
    frames = Dict{Int64,Matrix{Int64}}(t => g for (t, g) in enumerate(grids))
    return label_sequence(frames, length(grids))
end

@testset "max_overlap_label tie-breaking" begin
    g = fill(1, 8, 8)
    g[2, 2] = 2                    # label 1, size 1
    g[4, 4] = 2; g[4, 5] = 2       # label 2, size 2
    labels, sizes = label_interior_sell_clusters(g)
    # one query cell on each cluster → overlap tie 1–1 → larger size wins
    cells = [CartesianIndex(2, 2), CartesianIndex(4, 4)]
    @test max_overlap_label(labels, sizes, cells) == 2
    # no overlap anywhere → 0
    @test max_overlap_label(labels, sizes, [CartesianIndex(6, 6)]) == 0
    # equal overlap AND equal size → smaller label
    g2 = fill(1, 8, 8); g2[2, 2] = 2; g2[4, 4] = 2
    l2, s2 = label_interior_sell_clusters(g2)
    @test max_overlap_label(l2, s2, [CartesianIndex(2, 2), CartesianIndex(4, 4)]) == 1
end

@testset "trace_backward: growth, birth, gap-1 flicker" begin
    blob(cells) = (g = fill(1, 8, 8); for (r, c) in cells; g[r, c] = 2; end; g)
    # t1: 1 cell → t2: 3 cells → t3: 5 cells; birth at t=1
    labels, sizes = _labelseq([blob([(4, 4)]),
                               blob([(4, 4), (4, 5), (5, 4)]),
                               blob([(4, 4), (4, 5), (5, 4), (5, 5), (3, 4)])])
    chain = trace_backward(labels, sizes, 3, 1)
    @test chain == [(1, Int16(1)), (2, Int16(1)), (3, Int16(1))]

    # flicker: present t1, absent t2, present t3 → gap-1 bridges to t1
    labels_f, sizes_f = _labelseq([blob([(4, 4), (4, 5)]),
                                   fill(1, 8, 8),
                                   blob([(4, 4), (4, 5), (5, 4)])])
    chain_f = trace_backward(labels_f, sizes_f, 3, 1)
    @test chain_f == [(1, Int16(1)), (3, Int16(1))]

    # true birth mid-sequence: nothing at t1 or t2, blob appears at t3
    labels_b, sizes_b = _labelseq([fill(1, 8, 8), fill(1, 8, 8), blob([(4, 4)])])
    chain_b = trace_backward(labels_b, sizes_b, 3, 1)
    @test chain_b == [(3, Int16(1))]
end

@testset "trace_forward from a seed patch" begin
    blob(cells) = (g = fill(1, 8, 8); for (r, c) in cells; g[r, c] = 2; end; g)
    seed = [CartesianIndex(4, 4), CartesianIndex(4, 5)]
    # grows then dies at t3
    labels, sizes = _labelseq([blob([(4, 4), (4, 5)]),
                               blob([(4, 4), (4, 5), (5, 4)]),
                               fill(1, 8, 8),
                               fill(1, 8, 8)])
    fwd = trace_forward(labels, sizes, seed, 4)
    @test fwd.max_size == 3 && fwd.last_alive == 2
    # seed never materializes
    dead = trace_forward(_labelseq([fill(1, 8, 8), fill(1, 8, 8)])..., seed, 2)
    @test dead.max_size == 0 && dead.last_alive == 0 && isempty(dead.chain)
    # gap-1 forward: alive t1, gone t2, back t3
    labels_g, sizes_g = _labelseq([blob([(4, 4), (4, 5)]),
                                   fill(1, 8, 8),
                                   blob([(4, 4), (4, 5), (5, 4), (5, 5)])])
    fwd_g = trace_forward(labels_g, sizes_g, seed, 3)
    @test fwd_g.max_size == 4 && fwd_g.last_alive == 3
end
