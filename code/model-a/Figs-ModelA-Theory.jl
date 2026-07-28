# Figs-ModelA-Theory.jl
# Theory-overview figure for the Theory section (Potts mapping → pair
# approximation → nucleation). Three panels:
#   Panel A  Potts energy e and site entropy S1 vs f — loaded from
#            data/SpatialTheory-PhaseSweep.jld2 (Compute-SpatialTheory.jl:
#            128×128 lattice, periodic BCs, 2000 steps + 500 burn-in)
#   Panel B  Spectral radius of the pair-approximation Jacobian at the
#            uncorrelated fixed point vs f — recomputed here via a guarded
#            include of PairApproximation.jl (Analysis 3 machinery)
#   Panel C  Sell-cluster sizes in the mixed state vs f — recomputed with the
#            protocol of Compute-NucleationTheory.jl §3 ("Sell Cluster Size
#            Distribution"): 128×128, equilibrated 500 steps, 100 snapshots
#            10 steps apart, identical seeds (grid 42, minority 1234)
#
# Produces: figs/Fig-ModelA-Theory.pdf  →  paper-arxiv/figs/Fig-ModelA-Theory.pdf
# Run from the repo root:  julia --project=code code/model-a/Figs-ModelA-Theory.jl
#
# Each panel's data is verified against the values cited in the paper before
# plotting; the script aborts if any cited value fails to reproduce.

include(joinpath(@__DIR__, "Include.jl"))

# Reuse the pair-approximation machinery (mf_steady, numerical_jacobian, …)
# without triggering its console analyses — see the include guard at the top
# of PairApproximation.jl.
const _PAIRAPPROX_SKIP_ANALYSES = true
include(joinpath(@__DIR__, "PairApproximation.jl"))

# ---------------------------------------------------------------------------
# Panel A data — Potts energy and site entropy vs f (from disk)
# ---------------------------------------------------------------------------
dA = load(joinpath(_PATH_TO_DATA, "SpatialTheory-PhaseSweep.jld2"))
fA = sort(collect(dA["fs"]))
resA = dA["results"]
energy = [resA[f].energy for f in fA]
S1     = [resA[f].S1     for f in fA]

# Verify the values cited in the paper (Potts Energy Mapping + Summary):
# mixed attractor e ≈ −0.37, S1 ≈ 1.06 below the transition; all-Sell
# e ≈ −0.93, S1 ≈ 0.18 above; discontinuities Δe ≈ 0.56, ΔS1 ≈ 0.88.
below = fA .<= 0.155
above = fA .>= 0.20
e_lo, e_hi   = mean(energy[below]), mean(energy[above])
S1_lo, S1_hi = mean(S1[below]),     mean(S1[above])
println("Panel A verification (cited vs computed):")
println("  e  below: -0.37 vs $(round(e_lo, digits = 3));  above: -0.93 vs $(round(e_hi, digits = 3))")
println("  S1 below:  1.06 vs $(round(S1_lo, digits = 3));  above:  0.18 vs $(round(S1_hi, digits = 3))")
println("  Δe:  0.56 vs $(round(abs(e_hi - e_lo), digits = 3));  ΔS1: 0.88 vs $(round(S1_lo - S1_hi, digits = 3))")
@assert isapprox(e_lo, -0.37; atol = 0.02) "Panel A: mixed-state energy does not reproduce"
@assert isapprox(e_hi, -0.93; atol = 0.02) "Panel A: all-Sell energy does not reproduce"
@assert isapprox(S1_lo, 1.06; atol = 0.02) "Panel A: mixed-state entropy does not reproduce"
@assert isapprox(S1_hi, 0.18; atol = 0.02) "Panel A: all-Sell entropy does not reproduce"
@assert isapprox(abs(e_hi - e_lo), 0.56; atol = 0.02) "Panel A: Δe does not reproduce"
@assert isapprox(S1_lo - S1_hi, 0.88; atol = 0.02) "Panel A: ΔS1 does not reproduce"

# ---------------------------------------------------------------------------
# Panel B data — pair-approximation spectral radius vs f (recomputed)
# ---------------------------------------------------------------------------
# Replicates PairApproximation.jl Analysis 3: 6×6 finite-difference Jacobian
# of the pair map at the uncorrelated (mean-field) fixed point.
function _pair_spectral_radius(f::Float64)
    p0_mf, p2_mf = mf_steady(f)
    p_mf = [p0_mf, 1.0 - p0_mf - p2_mf, p2_mf]
    ρ_fp = zeros(3, 3)
    for a in 0:2, b in 0:2
        ρ_fp[a+1, b+1] = p_mf[a+1] * p_mf[b+1]
    end
    J = numerical_jacobian(f, ρ_fp)
    return maximum(abs.(eigvals(J)))
end

fB = collect(0.0:0.02:0.5)
ρJ = [_pair_spectral_radius(f) for f in fB]

# Verify against the Analysis 3 endpoints cited in the paper and Appendix A:
# ρ declines monotonically from 0.9477 at f = 0 to 0.7136 at f = 0.5.
println("Panel B verification (cited vs computed):")
println("  ρ(0.0): 0.9477 vs $(round(ρJ[1], digits = 4));  ρ(0.5): 0.7136 vs $(round(ρJ[end], digits = 4))")
@assert round(ρJ[1],   digits = 4) == 0.9477 "Panel B: spectral radius at f=0 does not reproduce"
@assert round(ρJ[end], digits = 4) == 0.7136 "Panel B: spectral radius at f=0.5 does not reproduce"
@assert all(ρJ .< 1.0)                       "Panel B: spectral radius should be < 1 everywhere"
@assert all(diff(ρJ) .< 0)                   "Panel B: spectral radius should decline monotonically"

# ---------------------------------------------------------------------------
# Panel C data — sell-cluster sizes in the mixed state (recomputed)
# ---------------------------------------------------------------------------
# Protocol and kernels replicated from Compute-NucleationTheory.jl §3.
_decode_rule(index::Int, ncolors::Int, radius::Int) = begin
    D = Dict{Int, Int}()
    val = index
    for c in 0:(ncolors - 1) * radius
        D[c] = val % ncolors
        val = val ÷ ncolors
    end
    D
end

const _D_MAJ = _decode_rule(19280, 3, 4)
const _D_MIN = _decode_rule(19286, 3, 4)

function _ca_step_theory!(grid::Matrix{Int}, nxt::Matrix{Int},
                          is_min::BitMatrix, nrows::Int, ncols::Int)
    @inbounds for r in 1:nrows, c in 1:ncols
        up    = r == 1     ? nrows : r - 1
        down  = r == nrows ? 1     : r + 1
        left  = c == 1     ? ncols : c - 1
        right = c == ncols ? 1     : c + 1
        csum = grid[up, c] + grid[down, c] + grid[r, left] + grid[r, right]
        D = is_min[r, c] ? _D_MIN : _D_MAJ
        nxt[r, c] = D[csum]
    end
end

function _assign_minority!(is_min::BitMatrix, f::Float64, nrows::Int, ncols::Int, seed::Int)
    fill!(is_min, false)
    if f > 0.0
        N = nrows * ncols
        rng = Random.MersenneTwister(seed)
        for pos in randperm(rng, N)[1:round(Int, f * N)]
            r = (pos - 1) ÷ ncols + 1
            c = (pos - 1) % ncols + 1
            is_min[r, c] = true
        end
    end
end

function _find_sell_clusters(grid::Matrix{Int}, nrows::Int, ncols::Int)
    visited = falses(nrows, ncols)
    clusters = Int[]
    for r in 1:nrows, c in 1:ncols
        if grid[r, c] == 2 && !visited[r, c]
            queue = [(r, c)]
            visited[r, c] = true
            sz = 0
            while !isempty(queue)
                cr, cc = popfirst!(queue)
                sz += 1
                for (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]
                    nr = cr + dr
                    nc = cc + dc
                    nr = nr < 1 ? nrows : (nr > nrows ? 1 : nr)
                    nc = nc < 1 ? ncols : (nc > ncols ? 1 : nc)
                    if grid[nr, nc] == 2 && !visited[nr, nc]
                        visited[nr, nc] = true
                        push!(queue, (nr, nc))
                    end
                end
            end
            push!(clusters, sz)
        end
    end
    return clusters
end

const _L_CLUST = 128
fC = [0.05, 0.10, 0.13, 0.145, 0.155, 0.16]
mean_max_clust = Float64[]
max_ever_clust = Int[]

for f in fC
    grid = rand(Random.MersenneTwister(42), 0:2, _L_CLUST, _L_CLUST)
    nxt = copy(grid)
    is_min = falses(_L_CLUST, _L_CLUST)
    _assign_minority!(is_min, f, _L_CLUST, _L_CLUST, 1234)

    for _ in 1:500   # equilibrate to the mixed attractor
        _ca_step_theory!(grid, nxt, is_min, _L_CLUST, _L_CLUST)
        grid, nxt = nxt, grid
    end

    max_sum = 0.0
    max_ever = 0
    n_snap = 100
    for _ in 1:n_snap
        for _ in 1:10
            _ca_step_theory!(grid, nxt, is_min, _L_CLUST, _L_CLUST)
            grid, nxt = nxt, grid
        end
        clusters = _find_sell_clusters(grid, _L_CLUST, _L_CLUST)
        if !isempty(clusters)
            max_sum += maximum(clusters)
            max_ever = max(max_ever, maximum(clusters))
        end
    end
    push!(mean_max_clust, max_sum / n_snap)
    push!(max_ever_clust, max_ever)
end

# Verify against the values cited in the paper (Nucleation Theory):
# largest clusters ~30–60 cells subcritical, ~400 near f = 0.145,
# exceeding 1,800 by f = 0.16.
println("Panel C verification (cited vs computed):")
println("  subcritical (f ≤ 0.13) largest: ~30–60 vs mean-max $(round.(mean_max_clust[fC .<= 0.13], digits = 0)), max-ever $(max_ever_clust[fC .<= 0.13])")
println("  f = 0.145: ~400 vs max-ever $(max_ever_clust[fC .== 0.145][1])")
println("  f = 0.16:  >1,800 vs max-ever $(max_ever_clust[fC .== 0.16][1])")
@assert all(30 .<= mean_max_clust[fC .<= 0.13] .<= 60) "Panel C: subcritical cluster sizes do not reproduce"
@assert isapprox(max_ever_clust[fC .== 0.145][1], 400; atol = 100) "Panel C: f=0.145 cluster size does not reproduce"
@assert max_ever_clust[fC .== 0.16][1] > 1800 "Panel C: f=0.16 cluster size does not reproduce"

# ---------------------------------------------------------------------------
# Shared style — slick gray background (matches Fig3-PhaseDiagram.jl)
# ---------------------------------------------------------------------------
using Colors
fc = 0.145

# ---------------------------------------------------------------------------
# Panel A — Potts energy and site entropy vs f
# ---------------------------------------------------------------------------
pA = plot(fA, energy;
    marker = :circle, ms = 3, lw = 1.5, color = _BUY_COLOR,
    label = "energy e",
    xlabel = "Minority fraction f", ylabel = "Energy e / entropy S1",
    title = "A", legend = :right, _panel_kw...)
plot!(pA, fA, S1;
    marker = :circle, ms = 3, lw = 1.5, color = "#E69F00",
    label = "entropy S1")
vline!(pA, [fc]; linestyle = :dash, color = :gray50, label = false)

# ---------------------------------------------------------------------------
# Panel B — pair-approximation spectral radius vs f
# ---------------------------------------------------------------------------
pB = plot(fB, ρJ;
    marker = :circle, ms = 3, lw = 1.5, color = :black,
    label = false,
    xlabel = "Minority fraction f", ylabel = "Spectral radius of pair map",
    title = "B", ylims = (0.60, 1.08), legend = false, _panel_kw...)
hline!(pB, [1.0]; linestyle = :dash, color = _SELL_COLOR, label = false)
annotate!(pB, 0.25, 1.035, text("instability threshold = 1", 7, :center, _SELL_COLOR))

# ---------------------------------------------------------------------------
# Panel C — sell-cluster sizes vs f in the mixed state (log y)
# ---------------------------------------------------------------------------
pC = plot(fC, max_ever_clust;
    marker = :circle, ms = 4, lw = 1.5, color = _SELL_COLOR,
    linestyle = :dash, label = "largest observed",
    xlabel = "Minority fraction f", ylabel = "Sell-cluster size (cells)",
    title = "C", yscale = :log10, legend = :topleft, _panel_kw...)
plot!(pC, fC, mean_max_clust;
    marker = :square, ms = 3, lw = 1.5, color = :black,
    label = "mean largest per snapshot")
vline!(pC, [fc]; linestyle = :dash, color = :gray50, label = false)

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig = plot(pA, pB, pC;
    layout = (1, 3), size = (960, 320),
    bottom_margin = 6Plots.mm, left_margin = 5Plots.mm, right_margin = 5Plots.mm,
    plot_title = "")

_save_figure(fig, "Fig-ModelA-Theory.pdf")
