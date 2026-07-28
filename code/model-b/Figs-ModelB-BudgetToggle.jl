# Figs-ModelB-BudgetToggle.jl — rebuilds the budget-toggle and edge-trace
# figures from committed CSVs. No simulation.
#
# Reads: code/data/ModelB-Nucleation-BudgetToggle.csv
#        code/data/ModelB-Nucleation-BudgetToggle-Trajectories.csv
# Writes: code/figs/ModelB-Nucleation-BudgetToggle.pdf          (+ paper-arxiv/figs copy)
#         code/figs/ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf (+ paper-arxiv/figs copy)
#
# Two figures, six panels each (row per direction):
#   Fig 1 — paired trajectories: largest-cluster/grid, control vs toggled, one
#           line per included seed, onset-aligned; plus a paired-velocity
#           slope-graph panel per direction.
#   Fig 2 — edge-ring trace: mean (over included seeds) edge-ring Buy/Sell
#           fraction, control vs toggled, onset-aligned. This is the conduit
#           figure — budgets can only reach interior sentiment through these
#           ring states.
# These reproduce the images the compute script used to render as a side
# effect. DIRECTIONS' names/factors and the PRE/W window below duplicate
# constants from Compute-ModelB-BudgetToggle.jl by design (same pattern as
# Figs-ModelB-SeedSweep.jl's CONFIGS/STEPS) — they must match that script.
#
# Run: julia --project=code code/model-b/Figs-ModelB-BudgetToggle.jl

include(joinpath(@__DIR__, "Include.jl"))
using CSV, DataFrames, Statistics

const DIRECTIONS = [
    (name = "injection",        factor = 10.0),
    (name = "withdrawal_mild",  factor =  0.1),
    (name = "withdrawal_harsh", factor =  0.01),
]
const W   = 400   # post-toggle comparison window (must match compute script)
const PRE = 200   # pre-onset window plotted        (must match compute script)

summ = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BudgetToggle.csv"), DataFrame)
traj = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BudgetToggle-Trajectories.csv"), DataFrame)

# Verify the values the paper cites before plotting anything.
inj = summ[(summ.direction .== "injection") .& summ.included, :]
@assert nrow(inj) == 19 "expected 19 included injection pairs"
@assert sum(inj.v_toggle .> inj.v_ctrl) == 14 "injection must accelerate in 14 of 19 pairs"
@assert isapprox(median(inj.v_ctrl),   1.39e-4; rtol = 0.02) "control median velocity does not reproduce"
@assert isapprox(median(inj.v_toggle), 3.55e-4; rtol = 0.02) "toggled median velocity does not reproduce"

# ---------------------------------------------------------------------------
# Figure 1: row per direction — onset-aligned paired trajectories + paired dv
# ---------------------------------------------------------------------------
const _TOG_COLOR = Dict("injection"        => _BUY_COLOR,
                        "withdrawal_mild"  => _SELL_COLOR,
                        "withdrawal_harsh" => "#8E1B00")

panels = Plots.Plot[]
for dir in DIRECTIONS
    p = plot(title = "$(dir.name): cash x$(dir.factor) at onset", titlefont = 10,
             xlabel = "steps since onset", ylabel = "largest cluster / grid",
             guidefont = 8, tickfont = 7, legend = :topleft, legendfontsize = 6)
    sub_c = traj[(traj.direction .== dir.name) .& (traj.condition .== "control"), :]
    sub_t = traj[(traj.direction .== dir.name) .& (traj.condition .== "toggled"), :]
    seeds = sort(unique(sub_c.seed))
    seen_lbl = false
    for seed in seeds
        cs = sort(sub_c[sub_c.seed .== seed, :], :step_since_onset)
        ts = sort(sub_t[sub_t.seed .== seed, :], :step_since_onset)
        plot!(p, cs.step_since_onset, cs.cluster_frac, color = "#888888", alpha = 0.45,
              lw = 1.0, label = seen_lbl ? "" : "control")
        plot!(p, ts.step_since_onset, ts.cluster_frac, color = _TOG_COLOR[dir.name],
              alpha = 0.45, lw = 1.0, label = seen_lbl ? "" : "toggled")
        seen_lbl = true
    end
    vline!(p, [0], color = :black, ls = :dash, lw = 0.8, label = "")
    push!(panels, p)

    sub = summ[(summ.direction .== dir.name) .& summ.included, :]
    q = plot(ylabel = "front velocity x 1e4 (per step)", guidefont = 8,
             tickfont = 7, legend = false, xticks = ([1, 2], ["control", "toggled"]),
             xlims = (0.6, 2.4), title = "paired velocities", titlefont = 10)
    for r in eachrow(sub)
        plot!(q, [1, 2], [r.v_ctrl, r.v_toggle] .* 1e4,
              color = _TOG_COLOR[dir.name], alpha = 0.5, lw = 1.0, marker = :circle,
              markersize = 3, markerstrokewidth = 0)
    end
    push!(panels, q)
end

fig = plot(panels...; layout = (length(DIRECTIONS), 2), size = (1250, 1050),
           left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
           plot_title = "Budget-toggle intervention (paired, onset-aligned; W=$(W))",
           plot_titlefontsize = 11)
_save_figure(fig, "ModelB-Nucleation-BudgetToggle.pdf")
@info "Saved: ModelB-Nucleation-BudgetToggle.pdf"

# ---------------------------------------------------------------------------
# Figure 2: edge-trace mechanism — onset-aligned MEAN edge-ring Buy and Sell
# fractions, control vs toggled, per direction. This is the conduit figure:
# budgets can only reach interior sentiment through these ring states.
# ---------------------------------------------------------------------------

"""Mean, over included seeds, of `valcol` at each offset in xs, NaN where no
seed has data at that offset (equivalent to the compute script's original
`_aligned_mean`, but reading from the persisted long-format trajectory
table instead of in-memory per-seed series)."""
function _aligned_mean_from_traj(sub::DataFrame, valcol::Symbol, xs::AbstractRange)
    g = combine(groupby(sub[:, [:step_since_onset, valcol]], :step_since_onset),
                valcol => mean => :m)
    lookup = Dict(g.step_since_onset .=> g.m)
    return [get(lookup, x, NaN) for x in xs]
end

edge_panels = Plots.Plot[]
xs = (-PRE):W
for dir in DIRECTIONS
    subc = traj[(traj.direction .== dir.name) .& (traj.condition .== "control"), :]
    subt = traj[(traj.direction .== dir.name) .& (traj.condition .== "toggled"), :]
    for (valcol, lbl) in ((:edge_buy_frac, "edge ring: Buy fraction"),
                          (:edge_sell_frac, "edge ring: Sell fraction"))
        mc = _aligned_mean_from_traj(subc, valcol, xs)
        mt = _aligned_mean_from_traj(subt, valcol, xs)
        p  = plot(title = "$(dir.name): cash x$(dir.factor)", titlefont = 10,
                  xlabel = "steps since onset", ylabel = lbl, ylims = (0, 1),
                  guidefont = 8, tickfont = 7, legend = :topleft, legendfontsize = 6)
        plot!(p, xs, mc, color = "#888888", lw = 1.8, label = "control")
        plot!(p, xs, mt, color = _TOG_COLOR[dir.name], lw = 1.8, label = "toggled")
        vline!(p, [0], color = :black, ls = :dash, lw = 0.8, label = "")
        push!(edge_panels, p)
    end
end
fig_edge = plot(edge_panels...; layout = (length(DIRECTIONS), 2), size = (1250, 1050),
                left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
                plot_title = "Edge-ring trace: the price -> boundary conduit (mean over seeds)",
                plot_titlefontsize = 11)
_save_figure(fig_edge, "ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf")
@info "Saved: ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf"

@info "Figs-ModelB-BudgetToggle.jl complete."
