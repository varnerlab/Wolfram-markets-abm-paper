# Compute-ModelB-NucleationSeeds.jl — seed-robustness sweep for the nucleation
# probe (arrested-nucleation confirmatory analysis #1).
#
# Probe-ModelB-Nucleation.jl established, on a SINGLE seed, that (Q1) crashes
# nucleate spatially (largest-cluster/total-sell ratio 0.02 stable vs 0.66
# freeze / 0.72 collapse) and (Q2) budget gates front extent (~0.38 stalled vs
# ~0.47 still climbing). This script reruns the same three configs across 20
# seeds and reduces each run to per-run spatial metrics so those numbers become
# distributions:
#   ratio_at_peak — largest-cluster / total-sell fraction at the sell peak
#                   (Q1: one dominant domain vs dispersed/global)
#   front_final   — largest-cluster fraction of the grid at t=STEPS
#   late_slope    — mean per-step growth of the largest cluster over the last
#                   LATE_WINDOW steps (Q2: stalled ≈ 0 vs still climbing > 0)
#
# Writes: code/data/ModelB-Nucleation-SeedSweep.csv              (one row per run)
#         code/data/ModelB-Nucleation-SeedSweep-Trajectories.csv  (per-step maxcl
#                                                                   trace, long format)
#
# Figures are drawn by Figs-ModelB-SeedSweep.jl (a separate, standalone script),
# which reads ONLY the two CSVs above — so the committed figure remains
# reproducible without re-running the 60-sim sweep.
#
# Launch: julia -t 8 code/model-b/Compute-ModelB-NucleationSeeds.jl
#
# Threading contract (as Stage 2): results land in preallocated vectors indexed
# by run id; all file I/O and plotting happen OUTSIDE the threaded loop.

include(joinpath(@__DIR__, "Include.jl"))

const P0          = 100.0
const GRIDN       = 64
const STEPS       = 1000
const SEEDS       = collect(1:20)
const LATE_WINDOW = 100
const N_CELLS     = GRIDN * GRIDN

const CONFIGS = [
    (name = "stable",   f = 0.10, cash = 1000.0),
    (name = "freeze",   f = 0.20, cash =  500.0),
    (name = "collapse", f = 0.20, cash = 5000.0),
]

function _probe_config(; f, cash, seed)
    return build(MyModelBConfiguration, (
        number_of_rows    = GRIDN,
        number_of_cols    = GRIDN,
        steps             = STEPS,
        seed              = seed,
        λ                 = 0.02,
        k                 = 1.0,
        minority_fraction = f,
        edge_band_spread  = 0.5,
        cost_basis_rule   = false,
        initial_cash      = cash,
        P0                = P0,
    ))
end

# Connected components of sell (state 2) cells, 4-neighbour, OPEN boundaries
# (same reduction as Probe-ModelB-Nucleation.jl). Returns (n, max).
function _sell_clusters(grid::Matrix{Int64})
    nr, nc  = size(grid)
    visited = falses(nr, nc)
    n_clust = 0
    max_sz  = 0
    for r in 1:nr, c in 1:nc
        (grid[r, c] == 2 && !visited[r, c]) || continue
        n_clust += 1
        sz    = 0
        queue = [(r, c)]
        visited[r, c] = true
        while !isempty(queue)
            cr, cc = popfirst!(queue)
            sz += 1
            for (dr, dc) in ((-1, 0), (1, 0), (0, -1), (0, 1))
                nr2, nc2 = cr + dr, cc + dc
                (1 <= nr2 <= nr && 1 <= nc2 <= nc) || continue
                if grid[nr2, nc2] == 2 && !visited[nr2, nc2]
                    visited[nr2, nc2] = true
                    push!(queue, (nr2, nc2))
                end
            end
        end
        max_sz = max(max_sz, sz)
    end
    return n_clust, max_sz
end

"""Run one (config, seed) and reduce to a summary row + the maxcl trajectory."""
function _run_one(cfg::NamedTuple, seed::Int)
    res    = simulate(_probe_config(f = cfg.f, cash = cfg.cash, seed = seed);
                      snapshot_steps = collect(1:STEPS), verbose = false)
    sellfr = zeros(STEPS)
    maxcl  = zeros(STEPS)
    nclust = zeros(Int, STEPS)
    for t in 1:STEPS
        n, m      = _sell_clusters(res.frames[t])
        sellfr[t] = count(==(2), res.frames[t]) / N_CELLS
        maxcl[t]  = m / N_CELLS
        nclust[t] = n
    end
    peak = argmax(sellfr)
    supp = res.suppressed_sells
    row  = (config          = cfg.name,
            f               = cfg.f,
            cash            = cfg.cash,
            seed            = seed,
            peak_step       = peak,
            peak_sell       = sellfr[peak],
            ratio_at_peak   = maxcl[peak] / max(sellfr[peak], 1e-9),
            final_sell      = sellfr[STEPS],
            front_final     = maxcl[STEPS],
            front_max       = maximum(maxcl),
            nclust_final    = nclust[STEPS],
            late_slope      = (maxcl[STEPS] - maxcl[STEPS - LATE_WINDOW]) / LATE_WINDOW,
            suppressed_total = sum(supp),
            suppressed_late  = sum(@view supp[(end - LATE_WINDOW + 1):end]))
    return row, maxcl
end

# ---------------------------------------------------------------------------
# Sweep: 3 configs x 20 seeds
# ---------------------------------------------------------------------------
runs = [(cfg = cfg, seed = seed) for cfg in CONFIGS for seed in SEEDS]
@info "Nucleation seed sweep" n_runs = length(runs) grid = GRIDN steps = STEPS threads = Threads.nthreads()

rows  = Vector{Union{Nothing,NamedTuple}}(nothing, length(runs))
trajs = Vector{Vector{Float64}}(undef, length(runs))
Threads.@threads :dynamic for i in eachindex(runs)
    row, maxcl = _run_one(runs[i].cfg, runs[i].seed)
    rows[i]  = row
    trajs[i] = maxcl
end
@assert all(!isnothing, rows)

df = DataFrame()
for r in rows
    push!(df, r)
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep.csv"), df)
@info "Saved: ModelB-Nucleation-SeedSweep.csv"

# Per-config summaries (median [IQR]) for the two headline metrics
for cfg in CONFIGS
    sub = df[df.config .== cfg.name, :]
    _mi(x) = "$(round(median(x), digits = 3)) [$(round(quantile(x, 0.25), digits = 3)), $(round(quantile(x, 0.75), digits = 3))]"
    @info "Summary: $(cfg.name)" ratio_at_peak = _mi(sub.ratio_at_peak) front_final = _mi(sub.front_final) late_slope_e4 = _mi(sub.late_slope .* 1e4) peak_sell = _mi(sub.peak_sell)
end

# Persist the per-step traces so the figure can be rebuilt without re-running
# the campaign. Columns: config, seed, step, maxcluster_frac. Built by
# indexing `runs`/`trajs` in deterministic `eachindex` order (both were
# filled by the threaded loop above using index assignment, not push!, so
# this iteration order is reproducible regardless of thread scheduling).
traj_rows = NamedTuple[]
for i in eachindex(runs)
    cfg_name, seed, maxcl = runs[i].cfg.name, runs[i].seed, trajs[i]
    for (step, v) in enumerate(maxcl)
        push!(traj_rows, (config = cfg_name, seed = seed, step = step, maxcluster_frac = v))
    end
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep-Trajectories.csv"),
          DataFrame(traj_rows))
@info "Saved: ModelB-Nucleation-SeedSweep-Trajectories.csv" rows = length(traj_rows)

@info "Compute-ModelB-NucleationSeeds.jl complete."
