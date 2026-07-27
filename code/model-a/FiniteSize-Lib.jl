## FiniteSize-Lib.jl
#
# Primitives for the system-size scaling campaign: a self-contained periodic-
# boundary CA stepper, sell-cluster labeling, and the single-run driver.
# Kept separate from Compute-FiniteSizeScaling.jl so that Test-FiniteSizeScaling.jl
# can exercise them without launching the campaign.
#
# No price data and no boundary forcing is involved anywhere in this file.

using Statistics, Random

# ─── Rule decoding (dense tables indexed by neighborhood sum c ∈ 0:8) ──────
function decode_rule(index::Int, ncolors::Int, radius::Int)
    D = zeros(Int, (ncolors - 1) * radius + 1)
    val = index
    for c in 0:(ncolors-1)*radius
        D[c+1] = val % ncolors
        val = val ÷ ncolors
    end
    return D
end

const D_MAJ = decode_rule(19280, 3, 4)   # majority / herding
const D_MIN = decode_rule(19286, 3, 4)   # contrarian; differs only at c = 1

function ca_step!(grid::Matrix{Int}, nxt::Matrix{Int},
                  is_min::BitMatrix, nrows::Int, ncols::Int)
    @inbounds for c in 1:ncols, r in 1:nrows
        up    = r == 1     ? nrows : r - 1
        down  = r == nrows ? 1     : r + 1
        left  = c == 1     ? ncols : c - 1
        right = c == ncols ? 1     : c + 1
        csum = grid[up, c] + grid[down, c] + grid[r, left] + grid[r, right]
        nxt[r, c] = is_min[r, c] ? D_MIN[csum+1] : D_MAJ[csum+1]
    end
end

sell_fraction(grid::Matrix{Int}) = count(==(2), grid) / length(grid)

function assign_minority!(is_min::BitMatrix, f::Float64, nrows::Int, ncols::Int, seed::Int)
    fill!(is_min, false)
    f > 0 || return
    N = nrows * ncols
    rng = Random.MersenneTwister(seed)
    for pos in randperm(rng, N)[1:round(Int, f * N)]
        is_min[(pos-1)÷ncols+1, (pos-1)%ncols+1] = true
    end
end

# ─── Connected sell clusters (4-connectivity, periodic wrap) ──────────────
# Returns (largest cluster size, number of clusters of at least n_crit cells).
function sell_clusters(grid::Matrix{Int}, seen::Matrix{Bool}, stack::Vector{Int},
                       nrows::Int, ncols::Int, n_crit::Int)
    fill!(seen, false)
    largest = 0
    n_super = 0
    @inbounds for c0 in 1:ncols, r0 in 1:nrows
        (grid[r0, c0] == 2 && !seen[r0, c0]) || continue
        empty!(stack)
        push!(stack, (c0 - 1) * nrows + r0)
        seen[r0, c0] = true
        sz = 0
        while !isempty(stack)
            idx = pop!(stack)
            r = (idx - 1) % nrows + 1
            c = (idx - 1) ÷ nrows + 1
            sz += 1
            up    = r == 1     ? nrows : r - 1
            down  = r == nrows ? 1     : r + 1
            left  = c == 1     ? ncols : c - 1
            right = c == ncols ? 1     : c + 1
            for (rr, cc) in ((up, c), (down, c), (r, left), (r, right))
                if grid[rr, cc] == 2 && !seen[rr, cc]
                    seen[rr, cc] = true
                    push!(stack, (cc - 1) * nrows + rr)
                end
            end
        end
        sz > largest && (largest = sz)
        sz >= n_crit && (n_super += 1)
    end
    return largest, n_super
end

sell_clusters(grid::Matrix{Int}, n_crit::Int) =
    sell_clusters(grid, fill(false, size(grid)...), Int[], size(grid, 1), size(grid, 2), n_crit)

# ─── One run ──────────────────────────────────────────────────────────────
# Records the three stages of escape:
#   t_nuc   largest sell cluster first reaches n_crit cells
#   t_half  sell fraction first exceeds 0.50
#   t_conv  sell fraction first exceeds 0.90
# Unreached stages are recorded at t_max with the matching *_observed flag
# false, so downstream analysis can censor rather than silently truncate.
function run_cell(L::Int, f::Float64, seed::Int;
                  n_crit::Int, check::Int, t_max::Int, burn_in::Int)
    grid   = rand(Random.MersenneTwister(1000 + seed), 0:2, L, L)
    nxt    = copy(grid)
    is_min = falses(L, L)
    assign_minority!(is_min, f, L, L, 5000 + seed)

    seen  = fill(false, L, L)
    stack = Int[]

    for _ in 1:burn_in
        ca_step!(grid, nxt, is_min, L, L)
        grid, nxt = nxt, grid
    end

    t_nuc  = t_max
    t_half = t_max
    t_conv = t_max
    nuc_obs  = false
    half_obs = false
    conv_obs = false
    n_clusters_at_half = 0
    largest_at_nuc = 0

    for t in 1:t_max
        ca_step!(grid, nxt, is_min, L, L)
        grid, nxt = nxt, grid

        if !nuc_obs && t % check == 0
            largest, _ = sell_clusters(grid, seen, stack, L, L, n_crit)
            if largest >= n_crit
                t_nuc = t
                nuc_obs = true
                largest_at_nuc = largest
            end
        end

        sf = sell_fraction(grid)

        if !half_obs && sf > 0.50
            t_half = t
            half_obs = true
            _, n_clusters_at_half = sell_clusters(grid, seen, stack, L, L, n_crit)
        end

        if sf > 0.90
            t_conv = t
            conv_obs = true
            break
        end
    end

    return (L=L, f=f, seed=seed,
            t_nuc=t_nuc, nuc_observed=nuc_obs, largest_at_nuc=largest_at_nuc,
            t_half=t_half, half_observed=half_obs, n_clusters_at_half=n_clusters_at_half,
            t_conv=t_conv, conv_observed=conv_obs)
end

# ─── Transformation curve (Avrami) ────────────────────────────────────────
# Cluster-size criteria are not scale-free detectors of nucleation: the mixed
# state throws up 30-60 cell sell fluctuations, and the largest chance
# fluctuation anywhere on the lattice grows with the number of sites, so a
# fixed threshold is crossed sooner on a bigger lattice for reasons unrelated
# to nucleation. The transformation curve avoids the problem entirely — it
# reads only the sell fraction, which needs no cluster identification.
#
# Kolmogorov-Johnson-Mehl-Avrami for continuous nucleation at rate I per site
# per step with fronts advancing at constant velocity v in d = 2:
#
#   X(t) = 1 - exp(-(K t)^n),   n = d + 1 = 3,   K ∝ (I v^2)^(1/3)
#
# so n distinguishes continuous nucleation (n = 3) from site saturation
# (n = 2, all nuclei present from the outset), and K is the intensive rate
# constant that should not depend on L once many nuclei are contributing.
function run_cell_trajectory(L::Int, f::Float64, seed::Int;
                             t_max::Int, burn_in::Int, sample_every::Int)
    grid   = rand(Random.MersenneTwister(1000 + seed), 0:2, L, L)
    nxt    = copy(grid)
    is_min = falses(L, L)
    assign_minority!(is_min, f, L, L, 5000 + seed)

    for _ in 1:burn_in
        ca_step!(grid, nxt, is_min, L, L)
        grid, nxt = nxt, grid
    end

    ts = Int[]
    xs = Float64[]
    for t in 1:t_max
        ca_step!(grid, nxt, is_min, L, L)
        grid, nxt = nxt, grid
        if t % sample_every == 0
            sf = sell_fraction(grid)
            push!(ts, t); push!(xs, sf)
            sf > 0.95 && break
        end
    end
    return ts, xs
end

# Fit ln(-ln(1 - X)) = n ln t + n ln K over the transformed fraction window
# [x_lo, x_hi], after rescaling the raw sell fraction against the metastable
# baseline so that X runs from 0 in the mixed state to 1 in the absorbing one.
# The baseline is the median sell fraction over the leading `baseline_frac` of
# the record, which is inside the mixed plateau for every run that survives
# long enough to fit. Returns `nothing` when the window holds too few points.
function fit_avrami(ts::Vector{Int}, xs::Vector{Float64};
                    x_lo = 0.05, x_hi = 0.90, baseline_frac = 0.10)
    length(ts) >= 20 || return nothing
    nb = max(3, round(Int, baseline_frac * length(xs)))
    baseline = median(xs[1:nb])
    baseline < 0.5 || return nothing

    X = @. (xs - baseline) / (1 - baseline)
    idx = findall(i -> x_lo <= X[i] <= x_hi, eachindex(X))
    length(idx) >= 6 || return nothing

    # Restrict to the first monotone excursion through the window, so that
    # pre-transition wobble around the baseline cannot enter the fit.
    i1 = idx[1]
    i2 = idx[end]
    lx = [log(ts[i]) for i in i1:i2 if x_lo <= X[i] <= x_hi]
    ly = [log(-log(1 - X[i])) for i in i1:i2 if x_lo <= X[i] <= x_hi]
    length(lx) >= 6 || return nothing

    n  = cov(lx, ly) / var(lx)
    a  = mean(ly) - n * mean(lx)
    r2 = 1 - sum((ly .- (a .+ n .* lx)) .^ 2) / sum((ly .- mean(ly)) .^ 2)
    n > 0 || return nothing
    K = exp(a / n)
    return (n=n, K=K, r2=r2, npts=length(lx), baseline=baseline)
end
