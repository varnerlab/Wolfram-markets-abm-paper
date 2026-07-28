# Figs-ModelB-SeedSweep.jl — rebuilds the seed-sweep figure from committed
# CSVs. No simulation.
#
# Reads: code/data/ModelB-Nucleation-SeedSweep.csv
#        code/data/ModelB-Nucleation-SeedSweep-Trajectories.csv
# Writes: code/figs/ModelB-Nucleation-SeedSweep.pdf (+ paper-arxiv/figs copy)
#
# Five panels: row 1 = largest-cluster trajectories (20 seeds per config,
# one panel per config); row 2 = per-run distributions of the two headline
# metrics (ratio_at_peak, front_final). Restyling (Task 7) will change the
# look; this script currently reproduces the same image the compute script
# used to render as a side effect, with one deliberate fix: the distribution
# scatter's jitter is now drawn from a fixed local RNG instead of bare
# `rand`, so the figure is deterministic across reruns.
#
# Run: julia --project=code code/model-b/Figs-ModelB-SeedSweep.jl

include(joinpath(@__DIR__, "Include.jl"))
using CSV, DataFrames, Statistics, Random

const CONFIGS = ["stable", "freeze", "collapse"]
const STEPS   = 1000

summ = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep.csv"), DataFrame)
traj = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep-Trajectories.csv"), DataFrame)

# Verify the values the paper cites before plotting anything.
med(c) = median(summ[summ.config .== c, :ratio_at_peak])
@assert isapprox(med("stable"),   0.022; atol = 0.001) "stable median ratio does not reproduce"
@assert isapprox(med("freeze"),   0.26;  atol = 0.01)  "freeze median ratio does not reproduce"
@assert isapprox(med("collapse"), 0.44;  atol = 0.01)  "collapse median ratio does not reproduce"
@assert maximum(summ[summ.config .== "stable", :ratio_at_peak]) <
        minimum(summ[summ.config .!= "stable", :ratio_at_peak]) "stable band must not overlap"

# (config, seed) -> maxcluster_frac trace, ordered by step
traj_map = Dict{Tuple{String,Int},Vector{Float64}}()
for sub in groupby(traj, [:config, :seed])
    ordered = sort(sub, :step)
    traj_map[(sub.config[1], sub.seed[1])] = ordered.maxcluster_frac
end
seeds = sort(unique(traj.seed))

# ---------------------------------------------------------------------------
# Figure: row 1 = largest-cluster trajectories (20 seeds per config);
#         row 2 = per-run distributions of the two headline metrics
# ---------------------------------------------------------------------------
const _CFG_COLOR = Dict("stable" => "#666666", "freeze" => _BUY_COLOR, "collapse" => _SELL_COLOR)

traj_panels = Plots.Plot[]
for cfg in CONFIGS
    p = plot(title = cfg, titlefont = 10, xlabel = "step",
             ylabel = "largest cluster / grid", ylims = (0, 0.8),
             guidefont = 8, tickfont = 7, legend = false)
    for seed in seeds
        plot!(p, 1:STEPS, traj_map[(cfg, seed)], color = _CFG_COLOR[cfg], alpha = 0.35, lw = 1.0)
    end
    push!(traj_panels, p)
end

# Deterministic jitter: a fixed local RNG (not global seeding) so the
# distribution scatter is reproducible across reruns without perturbing any
# other script's RNG state.
_jitter_rng = MersenneTwister(20260728)

names_by_run = summ.config
dist_panels  = Plots.Plot[]
for (metric, lbl) in ((summ.ratio_at_peak, "largest cluster / total sell at peak"),
                      (summ.front_final, "largest cluster / grid at t=$(STEPS)"))
    p = plot(ylabel = lbl, guidefont = 8, tickfont = 7, legend = false,
             xticks = (1:length(CONFIGS), CONFIGS))
    for (j, cfg) in enumerate(CONFIGS)
        vals = metric[names_by_run .== cfg]
        boxplot!(p, fill(j, length(vals)), vals,
                 color = _CFG_COLOR[cfg], fillalpha = 0.4, lw = 1.2,
                 outliers = false, bar_width = 0.5)
        scatter!(p, j .+ 0.28 .* (rand(_jitter_rng, length(vals)) .- 0.5), vals,
                 color = _CFG_COLOR[cfg], markersize = 3, markerstrokewidth = 0)
    end
    push!(dist_panels, p)
end

fig = plot(traj_panels..., dist_panels...;
           layout = @layout([a b c; d e]), size = (1400, 760),
           left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
           plot_title = "Nucleation probe across $(length(seeds)) seeds",
           plot_titlefontsize = 11)
_save_figure(fig, "ModelB-Nucleation-SeedSweep.pdf")
@info "Saved: ModelB-Nucleation-SeedSweep.pdf"

@info "Figs-ModelB-SeedSweep.jl complete."
