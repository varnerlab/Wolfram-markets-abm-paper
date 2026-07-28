# Figs-ModelB-BudgetToggle.jl — rebuilds the budget-toggle and edge-trace
# figures from committed CSVs. No simulation.
#
# Reads: code/data/ModelB-Nucleation-BudgetToggle.csv
#        code/data/ModelB-Nucleation-BudgetToggle-Trajectories.csv
# Writes: code/figs/ModelB-Nucleation-BudgetToggle.pdf          (+ paper-arxiv/figs copy)
#         code/figs/ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf (+ paper-arxiv/figs copy)
#         code/figs/Fig7-Intervention.pdf                        (+ paper-arxiv/figs copy)
#
# Three `let` blocks (locals only, no consts colliding on re-include), so this
# file can be standalone-rerun from the repo root:
#   julia --project=code code/model-b/Figs-ModelB-BudgetToggle.jl
#
#   1) ModelB-Nucleation-BudgetToggle.pdf — paired trajectories: largest-
#      cluster/grid, control vs toggled, one line per included seed,
#      onset-aligned; plus a paired-velocity slope-graph panel per direction.
#      Left in its pre-restyle form (titles, six-panel layout unchanged);
#      Task 10 turns it into a supplementary figure.
#   2) ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf — edge-ring trace: mean
#      (over included seeds) edge-ring Buy/Sell fraction, control vs toggled,
#      onset-aligned, three arms x two states. Also left in its pre-restyle
#      form for Task 10's supplementary figure S6.
#   3) Fig7-Intervention.pdf (Task 9, THIS task's output) — the paper's
#      intervention-asymmetry figure: (A) paired front velocities under
#      injection, (B) paired velocities under both withdrawal doses, (C) the
#      edge-ring Buy/Sell mechanism under injection, (D) the same under the
#      harsh withdrawal dose (the mild dose behaves the same way per the
#      paper's own text — "either cut lifts the Buy fraction to ~0.72-0.74" —
#      so showing one exemplar does not lose information; both doses appear
#      in panel B and, in full, in Task 10's supplementary figure).
#
# DIRECTIONS' names/factors and the PRE/W window below duplicate constants
# from Compute-ModelB-BudgetToggle.jl by design (same pattern as
# Figs-ModelB-SeedSweep.jl's CONFIGS/STEPS) — they must match that script.
#
# Run: julia --project=code code/model-b/Figs-ModelB-BudgetToggle.jl

isdefined(Main, :_PATH_TO_DATA)     || include(joinpath(@__DIR__, "Include.jl"))
isdefined(Main, :binom_two_sided_p) || include(joinpath(@__DIR__, "BoundaryVsBulk-Lib.jl"))
using CSV, DataFrames, Statistics, Printf

const DIRECTIONS = [
    (name = "injection",        factor = 10.0),
    (name = "withdrawal_mild",  factor =  0.1),
    (name = "withdrawal_harsh", factor =  0.01),
]
const W   = 400   # post-toggle comparison window (must match compute script)
const PRE = 200   # pre-onset window plotted        (must match compute script)

summ = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BudgetToggle.csv"), DataFrame)
traj = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BudgetToggle-Trajectories.csv"), DataFrame)

# Arms are categorical (injection / mild withdrawal / harsh withdrawal), not an
# ordinal budget quantity, so they draw from _SERIES_COLORS rather than a
# ramp (Task 8's cash ramp is for the ordinal cash-level axis; this is not
# that). Previously this dict mapped "injection" => _BUY_COLOR, a reserved
# state hue standing in for an experimental arm — the same violation Tasks 5
# through 8 corrected elsewhere. Shared by all three figures below so one arm
# keeps one colour across every panel that shows it.
const _TOG_COLOR = Dict("injection"        => _SERIES_COLORS[1],
                        "withdrawal_mild"  => _SERIES_COLORS[2],
                        "withdrawal_harsh" => _SERIES_COLORS[3])

# ---------------------------------------------------------------------------
# Verify the values the paper cites before plotting anything. TWO DIFFERENT
# TESTS are computed here, and they are NOT interchangeable statistics:
#
#   TEST 1 — "sign test p = 0.064" (paper, injection only): the two-sided
#   EXACT BINOMIAL test on the COUNT of accelerating pairs (14 of 19) against
#   the null p = 0.5. This is `binom_two_sided_p` (Distributions.Binomial),
#   already used for the boundary-vs-bulk analysis.
#
#   TEST 2 — "sign-flip permutation p = 0.67 mild, p = 0.29 harsh" (paper,
#   both withdrawal doses): a SIGN-FLIP PERMUTATION test on the MEAN of the
#   paired difference `dv`, using a fixed `Xoshiro(7)` and 20,000 draws —
#   duplicated verbatim from Compute-ModelB-BudgetToggle.jl's `_signflip_p`
#   (same duplication rationale as DIRECTIONS/W/PRE above).
#
# Using the wrong test for either quantity gives a WRONG but plausible-
# looking number: the sign-flip permutation p for injection is 0.2418, not
# 0.064, and the exact-binomial p for both withdrawal doses is 0.6476 for
# each — close enough to 0.67 that a loose tolerance could hide the swap for
# mild while still failing for harsh (0.6476 vs the cited 0.29). Keep them
# named distinctly (`sign_test_p` vs `mild_p`/`harsh_p`) so this cannot recur.
# ---------------------------------------------------------------------------
inj   = summ[(summ.direction .== "injection")        .& summ.included, :]
mild  = summ[(summ.direction .== "withdrawal_mild")  .& summ.included, :]
harsh = summ[(summ.direction .== "withdrawal_harsh") .& summ.included, :]
@assert nrow(inj) == 19 && nrow(mild) == 19 && nrow(harsh) == 19 "expected 19 included pairs per direction"

n_accel_inj = sum(inj.v_toggle .> inj.v_ctrl)
@assert n_accel_inj == 14 "injection must accelerate in 14 of 19 pairs"

# --- TEST 1: exact two-sided binomial sign test on the accelerating count ---
sign_test_p = binom_two_sided_p(nrow(inj), n_accel_inj, 0.5)
@assert isapprox(sign_test_p, 0.064; atol = 0.002) "sign-test p (exact binomial on 14/19) does not reproduce"

# --- TEST 2: sign-flip permutation test on mean(dv), fixed Xoshiro(7) RNG ---
function _signflip_p(dv::Vector{Float64}; n_draws::Int = 20_000)
    isempty(dv) && return NaN
    rng  = Xoshiro(7)
    dobs = abs(mean(dv))
    hits = 0
    for _ in 1:n_draws
        hits += abs(mean(dv .* rand(rng, (-1.0, 1.0), length(dv)))) >= dobs
    end
    return hits / n_draws
end
mild_p  = _signflip_p(collect(Float64.(mild.dv)))
harsh_p = _signflip_p(collect(Float64.(harsh.dv)))
@assert isapprox(mild_p, 0.67; atol = 0.02) && isapprox(harsh_p, 0.29; atol = 0.02) "withdrawal nulls do not reproduce"

@assert isapprox(median(inj.v_ctrl),     1.392e-4; rtol = 0.02) "injection control median velocity does not reproduce"
@assert isapprox(median(inj.v_toggle),   3.552e-4; rtol = 0.02) "injection toggled median velocity does not reproduce"
@assert isapprox(median(mild.v_ctrl),    2.228e-4; rtol = 0.02) "withdrawal-mild control median velocity does not reproduce"
@assert isapprox(median(mild.v_toggle),  3.571e-4; rtol = 0.02) "withdrawal-mild toggled median velocity does not reproduce"
@assert isapprox(median(harsh.v_ctrl),   2.228e-4; rtol = 0.02) "withdrawal-harsh control median velocity does not reproduce"
@assert isapprox(median(harsh.v_toggle), 2.380e-4; rtol = 0.02) "withdrawal-harsh toggled median velocity does not reproduce"
@assert count(harsh.v_toggle .< harsh.v_ctrl) == 11 "harsh withdrawal: 11 of 19 must move in the predicted (decelerating) direction"

"""Mean, over included seeds, of `valcol` at each offset in xs, NaN where no
seed has data at that offset (equivalent to the compute script's original
`_aligned_mean`, but reading from the persisted long-format trajectory
table instead of in-memory per-seed series). Shared by the edge-trace figure
and Fig7's panels C/D."""
function _aligned_mean_from_traj(sub::DataFrame, valcol::Symbol, xs::AbstractRange)
    g = combine(groupby(sub[:, [:step_since_onset, valcol]], :step_since_onset),
                valcol => mean => :m)
    lookup = Dict(g.step_since_onset .=> g.m)
    return [get(lookup, x, NaN) for x in xs]
end

# ---------------------------------------------------------------------------
# Figure 1: row per direction — onset-aligned paired trajectories + paired dv
# (pre-restyle form; Task 10 turns this into a supplementary figure)
# ---------------------------------------------------------------------------
let
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
end

# ---------------------------------------------------------------------------
# Figure 2: edge-trace mechanism — onset-aligned MEAN edge-ring Buy and Sell
# fractions, control vs toggled, per direction. This is the conduit figure:
# budgets can only reach interior sentiment through these ring states.
# (pre-restyle form; Task 10 turns this into supplementary figure S6)
# ---------------------------------------------------------------------------
let
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
end

# ---------------------------------------------------------------------------
# Fig7-Intervention.pdf (Task 9) — the paper's intervention-asymmetry figure.
#
# (A) paired front velocities, injection only, coloured by arm.
# (B) paired velocities, BOTH withdrawal doses overlaid, coloured by arm.
# (C) edge-ring Buy/Sell mechanism under injection: control (gray dashed) vs
#     toggled (Buy = _BUY_COLOR, Sell = _SELL_COLOR solid). This is the panel
#     that must show the ~0.5-Buy -> ~1.0-Sell flip unmistakably.
# (D) the same construction under the harsh withdrawal dose — chosen because
#     it is the dose that genuinely binds (cash drops below the standing
#     price, buys die outright) yet still produces no sign reversal; the
#     paper's own text treats mild and harsh as behaving alike here ("either
#     cut lifts the Buy fraction to ~0.72-0.74"), and the mild dose's own
#     trace is preserved in full in Figure 2 above / Task 10's supplementary
#     figure, so no information is lost by picking one exemplar.
#
# No in-figure titles anywhere. Legends moved to :outertopright throughout
# (Tasks 7-8's remedy for `_panel_kw`'s opaque inside-legend backing), and
# every arm/factor/window value that used to live in a panel title now lives
# in an axis label, legend entry, or annotation (see Task 9 report for the
# title -> {label, legend, annotation} mapping).
# ---------------------------------------------------------------------------
let
    xs = (-PRE):W

    # ── A: paired front velocities, injection ───────────────────────────────
    pA = plot(; xticks = ([1, 2], ["control", "toggled"]), xlims = (0.6, 2.4),
              ylabel = "front velocity x 1e4 (per step)",
              legend = :outertopright, _panel_kw...)
    for r in eachrow(inj)
        plot!(pA, [1, 2], [r.v_ctrl, r.v_toggle] .* 1e4, color = _TOG_COLOR["injection"],
              alpha = 0.55, lw = 1.2, marker = :circle, markersize = 3,
              markerstrokewidth = 0, label = "")
    end
    plot!(pA, Float64[], Float64[], color = _TOG_COLOR["injection"], lw = 2.0,
          label = "injection (cash x10 at onset, n=$(nrow(inj)))")
    annotate!(pA, (1.02, 1.0),
              text(@sprintf("%d of %d pairs accelerate\nsign test p = %.3f\n(W = %d steps)",
                            n_accel_inj, nrow(inj), sign_test_p, W),
                   8, :black, :left))
    _panel_letter!(pA, "A")

    # ── B: paired front velocities, both withdrawal doses ───────────────────
    pB = plot(; xticks = ([1, 2], ["control", "toggled"]), xlims = (0.6, 2.4),
              ylabel = "front velocity x 1e4 (per step)",
              legend = :outertopright, _panel_kw...)
    for (df_, dname) in ((mild, "withdrawal_mild"), (harsh, "withdrawal_harsh"))
        for r in eachrow(df_)
            plot!(pB, [1, 2], [r.v_ctrl, r.v_toggle] .* 1e4, color = _TOG_COLOR[dname],
                  alpha = 0.5, lw = 1.0, marker = :circle, markersize = 3,
                  markerstrokewidth = 0, label = "")
        end
    end
    plot!(pB, Float64[], Float64[], color = _TOG_COLOR["withdrawal_mild"], lw = 2.0,
          label = @sprintf("mild (cash x0.1, p = %.2f)", mild_p))
    plot!(pB, Float64[], Float64[], color = _TOG_COLOR["withdrawal_harsh"], lw = 2.0,
          label = @sprintf("harsh (cash x0.01, p = %.2f)", harsh_p))
    _panel_letter!(pB, "B")

    # ── C: edge-ring mechanism, injection — the sign-reversal panel ─────────
    subc = traj[(traj.direction .== "injection") .& (traj.condition .== "control"), :]
    subt = traj[(traj.direction .== "injection") .& (traj.condition .== "toggled"), :]
    buy_c  = _aligned_mean_from_traj(subc, :edge_buy_frac,  xs)
    buy_t  = _aligned_mean_from_traj(subt, :edge_buy_frac,  xs)
    sell_c = _aligned_mean_from_traj(subc, :edge_sell_frac, xs)
    sell_t = _aligned_mean_from_traj(subt, :edge_sell_frac, xs)
    pC = plot(; xlabel = "steps since onset", ylabel = "edge-ring state fraction",
              ylims = (-0.02, 1.12), legend = :outertopright, _panel_kw...)
    plot!(pC, xs, buy_c,  color = _HOLD_COLOR, ls = :dash, lw = 1.8, label = "Buy (control)")
    plot!(pC, xs, sell_c, color = _HOLD_COLOR, ls = :dash, lw = 1.8, label = "Sell (control)")
    plot!(pC, xs, buy_t,  color = _BUY_COLOR,  lw = 2.4, label = "Buy (toggled)")
    plot!(pC, xs, sell_t, color = _SELL_COLOR, lw = 2.4, label = "Sell (toggled)")
    vline!(pC, [0], color = :black, ls = :dash, lw = 1.0, label = "toggle (t_on)")
    # Top-RIGHT corner (never top-left, where _panel_letter! always draws) and
    # right-aligned so it grows away from that corner as text is added.
    annotate!(pC, (0.98, 1.06),
              text("injection: cash x10 at t_on", 8, :black, :right))
    _panel_letter!(pC, "C")

    # ── D: edge-ring mechanism, harsh withdrawal (mild is qualitatively the
    # same per the paper's text; its own trace lives in Figure 2 above) ─────
    subc_h = traj[(traj.direction .== "withdrawal_harsh") .& (traj.condition .== "control"), :]
    subt_h = traj[(traj.direction .== "withdrawal_harsh") .& (traj.condition .== "toggled"), :]
    buy_c_h  = _aligned_mean_from_traj(subc_h, :edge_buy_frac,  xs)
    buy_t_h  = _aligned_mean_from_traj(subt_h, :edge_buy_frac,  xs)
    sell_c_h = _aligned_mean_from_traj(subc_h, :edge_sell_frac, xs)
    sell_t_h = _aligned_mean_from_traj(subt_h, :edge_sell_frac, xs)
    pD = plot(; xlabel = "steps since onset", ylabel = "edge-ring state fraction",
              ylims = (-0.02, 1.12), legend = :outertopright, _panel_kw...)
    plot!(pD, xs, buy_c_h,  color = _HOLD_COLOR, ls = :dash, lw = 1.8, label = "Buy (control)")
    plot!(pD, xs, sell_c_h, color = _HOLD_COLOR, ls = :dash, lw = 1.8, label = "Sell (control)")
    plot!(pD, xs, buy_t_h,  color = _BUY_COLOR,  lw = 2.4, label = "Buy (toggled)")
    plot!(pD, xs, sell_t_h, color = _SELL_COLOR, lw = 2.4, label = "Sell (toggled)")
    vline!(pD, [0], color = :black, ls = :dash, lw = 1.0, label = "toggle (t_on)")
    annotate!(pD, (0.98, 1.06),
              text("withdrawal, harsh: cash x0.01 at t_on\n(mild: same pattern, Fig. S6)", 8, :black, :right))
    _panel_letter!(pD, "D")

    fig7 = plot(pA, pB, pC, pD; layout = (2, 2), size = (1150, 950),
                left_margin = 6Plots.mm, bottom_margin = 4Plots.mm)
    _save_figure(fig7, "Fig7-Intervention.pdf")
    @info "Saved: Fig7-Intervention.pdf"
end

@info "Figs-ModelB-BudgetToggle.jl complete."
