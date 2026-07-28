# Figs-ModelB-SeedSweep.jl — rebuilds the seed-sweep figure from committed
# CSVs. No simulation.
#
# Reads: code/data/ModelB-Nucleation-SeedSweep.csv
#        code/data/ModelB-Nucleation-SeedSweep-Trajectories.csv
# Writes: code/figs/FigS2-SeedTrajectories.pdf (+ paper-arxiv/figs copy)
#
# Five panels: row 1 = largest-cluster trajectories (20 seeds per config,
# one panel per config); row 2 = per-run distributions of the two headline
# metrics (ratio_at_peak, front_final). Task 10 moved this onto the shared
# style (_panel_kw, _panel_letter!, no in-figure titles) and renamed the
# output from ModelB-Nucleation-SeedSweep.pdf to FigS2-SeedTrajectories.pdf.
# The distribution scatter's jitter is drawn from a fixed local RNG instead
# of bare `rand`, so the figure is deterministic across reruns.
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
#
# Shared style (Task 10): _panel_kw + _panel_letter! throughout; no in-figure
# titles (the config name moves to a top-right annotation on every trajectory
# panel — column position alone would be positional language). Config colours
# now match the mapping already established and justified in Fig5-Nucleus.pdf
# and Fig6-GrowthGating.pdf (stable -> _SERIES_COLORS[5], freeze ->
# _SERIES_COLORS[3], collapse -> _SELL_COLOR) instead of this script's
# previous ad hoc "#666666"/_BUY_COLOR pair, so a reader tracks one
# configuration by one colour across every figure in the paper, and freeze no
# longer borrows the reserved Buy hue for a non-state category.
# ---------------------------------------------------------------------------
const _CFG_COLOR = Dict("stable" => _SERIES_COLORS[5], "freeze" => _SERIES_COLORS[3], "collapse" => _SELL_COLOR)

traj_panels = Plots.Plot[]
for cfg in CONFIGS
    p = plot(; xlabel = "step", ylabel = "largest cluster / grid", ylims = (0, 0.8),
             legend = false, _panel_kw...)
    for seed in seeds
        plot!(p, 1:STEPS, traj_map[(cfg, seed)], color = _CFG_COLOR[cfg], alpha = 0.35, lw = 1.0)
    end
    annotate!(p, (0.98, 1.06), text(cfg, 8, :black, :right))
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
    p = plot(; ylabel = lbl, legend = false, xticks = (1:length(CONFIGS), CONFIGS), _panel_kw...)
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

panels = vcat(traj_panels, dist_panels)
for (p, letter) in zip(panels, ["A", "B", "C", "D", "E"])
    _panel_letter!(p, letter)
end

fig = plot(panels...;
           layout = @layout([a b c; d e]), size = (1400, 760),
           left_margin = 6Plots.mm, bottom_margin = 4Plots.mm)
_save_figure(fig, "FigS2-SeedTrajectories.pdf")

@info "Figs-ModelB-SeedSweep.jl complete."
