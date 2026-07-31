# Figs-ModelB-BudgetToggle.jl — rebuilds the budget-toggle figures from
# committed CSVs. No simulation.
#
# Reads: code/data/ModelB-Nucleation-BudgetToggle.csv
#        code/data/ModelB-Nucleation-BudgetToggle-Trajectories.csv
# Writes: code/figs/FigS6-ToggleDetail.pdf   (+ paper-arxiv/figs copy)
#         code/figs/Fig7-Intervention.pdf    (+ paper-arxiv/figs copy)
#
# Two `let` blocks (locals only, no consts colliding on re-include), so this
# file can be standalone-rerun from the repo root:
#   julia --project=code code/model-b/Figs-ModelB-BudgetToggle.jl
#
#   1) FigS6-ToggleDetail.pdf (Task 10) — full per-arm cluster trajectories +
#      the full three-arm edge trace, on the shared style. Merges what used
#      to be two separate pre-restyle figures (ModelB-Nucleation-
#      BudgetToggle.pdf and ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf,
#      neither emitted any more) into one 3x3 grid: rows = direction,
#      columns = {cluster trajectory, edge Buy fraction, edge Sell fraction}.
#   2) Fig7-Intervention.pdf (Task 9; rebuilt around the control-vs-injection
#      strip pair in Task 6) — the paper's intervention-asymmetry figure:
#      (A) two onset-aligned market strips (`ModelB-StripFrames.jld2` keys
#      `fig7/control/*` / `fig7/injection/*`, seed 16), rows "control" and
#      "cash ×10", pre-toggle bit-identical at tile 1; (B) the ensemble
#      price response under injection; (C) the edge-ring Buy/Sell mechanism
#      under injection — the
#      panel that must show the ~0.5-Buy -> ~1.0-Sell flip unmistakably;
#      (D) paired dumbbells, one thin control->toggled segment per seed, for
#      all three arms (injection, mild withdrawal, harsh withdrawal) grouped
#      side by side. The former panels A/B (per-seed spaghetti of paired
#      front velocities) are replaced by (D); the former edge-ring
#      mechanism under harsh withdrawal) is dropped outright — that trace
#      already lives in full in FigS6-ToggleDetail.pdf, so nothing is lost by
#      not repeating it here.
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
@assert :price in propertynames(traj) "budget-toggle trajectory table lacks price; rerun Compute-ModelB-BudgetToggle.jl"

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
and Fig7's edge-ring trace."""
function _aligned_mean_from_traj(sub::DataFrame, valcol::Symbol, xs::AbstractRange)
    g = combine(groupby(sub[:, [:step_since_onset, valcol]], :step_since_onset),
                valcol => mean => :m)
    lookup = Dict(g.step_since_onset .=> g.m)
    return [get(lookup, x, NaN) for x in xs]
end

"""Median and interquartile band of `valcol` at each aligned offset."""
function _aligned_quantiles_from_traj(sub::DataFrame, valcol::Symbol,
                                      xs::AbstractRange)
    g = combine(groupby(sub[:, [:step_since_onset, valcol]], :step_since_onset),
                valcol => (x -> quantile(x, 0.25)) => :q25,
                valcol => median => :q50,
                valcol => (x -> quantile(x, 0.75)) => :q75)
    lookup = Dict(r.step_since_onset => (r.q25, r.q50, r.q75) for r in eachrow(g))
    values = [get(lookup, x, (NaN, NaN, NaN)) for x in xs]
    return (q25 = first.(values), q50 = getindex.(values, 2), q75 = last.(values))
end

# ---------------------------------------------------------------------------
# FigS6-ToggleDetail.pdf (Task 10) — full per-arm cluster trajectories + the
# full three-arm edge trace, on the shared style. Merges what used to be two
# separate pre-restyle figures (ModelB-Nucleation-BudgetToggle.pdf and
# ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf, neither emitted any more)
# into one: 3 rows (one per direction) x 3 columns (cluster trajectory, edge
# Buy fraction, edge Sell fraction). The paired-velocity slope-graphs from
# the old BudgetToggle.pdf are NOT repeated here — Fig7-Intervention.pdf
# already carries them together in its paired-velocity panel — so nothing
# here duplicates that panel's content.
#
# Edge-trace panels reuse Fig7's own scheme (Buy/Sell are genuine state
# quantities: reserved hue, solid = toggled; _HOLD_COLOR dashed = control)
# rather than the old block's ad hoc "#888888"/arm-colour pairing, which lost
# the Buy/Sell identity of the very quantity being plotted. The cluster-
# trajectory column is not a state quantity, so "control" there takes
# _SERIES_COLORS[5] ("#000000", the same fix and precedent as the "control"
# colour in Figs-ModelB-BoundaryVsBulk.jl) rather than the old raw
# "#888888"; "toggled" keeps the existing _TOG_COLOR per-arm colour.
# ---------------------------------------------------------------------------
let
    xs      = (-PRE):W
    panels  = Plots.Plot[]
    letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
    li      = 0
    for (dir_i, dir) in enumerate(DIRECTIONS)
        dose_lbl = if dir.name == "injection"
            "injection: cash x$(Int(dir.factor))"
        elseif dir.name == "withdrawal_mild"
            "mild: cash x$(dir.factor)"
        else
            "harsh: cash x$(dir.factor)"
        end

        sub_c = traj[(traj.direction .== dir.name) .& (traj.condition .== "control"), :]
        sub_t = traj[(traj.direction .== dir.name) .& (traj.condition .== "toggled"), :]
        seeds = sort(unique(sub_c.seed))

        # column 1 — full per-seed cluster trajectories, control vs toggled
        xguide = dir_i == length(DIRECTIONS) ? "Steps since onset" : ""
        p1 = plot(; xlabel = xguide, xticks = [-200, 0, 200, 400], ylabel = "",
                  title = dir_i == 1 ? "Sell-cluster fraction" : "",
                  legend = :outertopright, _panel_kw...)
        seen_lbl = false
        for seed in seeds
            cs = sort(sub_c[sub_c.seed .== seed, :], :step_since_onset)
            ts = sort(sub_t[sub_t.seed .== seed, :], :step_since_onset)
            plot!(p1, cs.step_since_onset, cs.cluster_frac, color = _SERIES_COLORS[5],
                  alpha = 0.45, lw = 1.0, label = seen_lbl ? "" : "control")
            plot!(p1, ts.step_since_onset, ts.cluster_frac, color = _TOG_COLOR[dir.name],
                  alpha = 0.45, lw = 1.0, label = seen_lbl ? "" : "toggled")
            seen_lbl = true
        end
        vline!(p1, [0], color = :black, ls = :dash, lw = 0.8, label = "")
        annotate!(p1, (0.03, 0.93), text(dose_lbl, 7, :black, :left))
        li += 1; _panel_letter!(p1, letters[li])
        push!(panels, p1)

        # columns 2-3 — edge-ring mean Buy / Sell fraction, control vs toggled
        buy_c  = _aligned_mean_from_traj(sub_c, :edge_buy_frac,  xs)
        buy_t  = _aligned_mean_from_traj(sub_t, :edge_buy_frac,  xs)
        sell_c = _aligned_mean_from_traj(sub_c, :edge_sell_frac, xs)
        sell_t = _aligned_mean_from_traj(sub_t, :edge_sell_frac, xs)

        p2 = plot(; xlabel = xguide, xticks = [-200, 0, 200, 400], ylabel = "",
                  title = dir_i == 1 ? "Edge Buy fraction" : "",
                  ylims = (-0.02, 1.02), legend = :outertopright, _panel_kw...)
        plot!(p2, xs, buy_c, color = _HOLD_COLOR, ls = :dash, lw = 1.8, label = "control")
        plot!(p2, xs, buy_t, color = _BUY_COLOR,  lw = 2.2, label = "toggled")
        vline!(p2, [0], color = :black, ls = :dash, lw = 0.8, label = "")
        li += 1; _panel_letter!(p2, letters[li])
        push!(panels, p2)

        p3 = plot(; xlabel = xguide, xticks = [-200, 0, 200, 400], ylabel = "",
                  title = dir_i == 1 ? "Edge Sell fraction" : "",
                  ylims = (-0.02, 1.02), legend = :outertopright, _panel_kw...)
        plot!(p3, xs, sell_c, color = _HOLD_COLOR, ls = :dash, lw = 1.8, label = "control")
        plot!(p3, xs, sell_t, color = _SELL_COLOR, lw = 2.2, label = "toggled")
        vline!(p3, [0], color = :black, ls = :dash, lw = 0.8, label = "")
        li += 1; _panel_letter!(p3, letters[li])
        push!(panels, p3)
    end

    figS6 = plot(panels...; layout = (length(DIRECTIONS), 3), size = (900, 540),
                 left_margin = 6Plots.mm, bottom_margin = 4Plots.mm)
    _save_figure(figS6, "FigS6-ToggleDetail.pdf")
end

# ---------------------------------------------------------------------------
# Fig7-Intervention.pdf (Task 9; rebuilt around the control-vs-injection strip
# pair in Task 6) — the paper's intervention-asymmetry figure.
#
# TASK 6 REWORK: Fig7 is now anchored on the control-vs-injection market strip
# (panel A, onset-aligned, `ModelB-StripFrames.jld2` keys `fig7/control/*` and
# `fig7/injection/*`, both seed 16) — the same freeze/collapse strip-pair
# idiom Task 5 used for Fig6, mirrored here with `t_on-1` as the first tile so
# the pre-toggle bit-identity between the two arms (control and injection have
# not diverged yet) is visible directly, not just asserted in prose. The
# former panels A and B (per-seed spaghetti of paired front velocities,
# injection alone / both withdrawal doses overlaid) are replaced by a single
# paired-dumbbell panel (C) that shows all three arms — injection, mild
# withdrawal, harsh withdrawal — side by side on one categorical axis: each
# seed's short control->toggled segment now reads directly against the other
# arms' segments instead of splitting the comparison across two panels. The
# former panel C (edge-ring Buy/Sell mechanism under injection) is kept
# verbatim as the new panel B — it is still the panel that must show the
# ~0.5-Buy -> ~1.0-Sell flip unmistakably. The former panel D (the same
# construction under the harsh withdrawal dose) is dropped outright: that
# trace already lives in full in FigS6-ToggleDetail.pdf, so nothing is lost
# by not repeating it here.
#
# No in-figure titles anywhere. Panel A uses one merged 2x4 heatmap with its
# time and treatment labels overlaid inside the tiles. Panel B's legend sits
# inside its unused upper-right region; panel C needs no legend because its
# three categorical x-axis labels already identify the three arm encodings.
# ---------------------------------------------------------------------------
let
    xs = (-PRE):W
    strip_dat = load(joinpath(_PATH_TO_DATA, "ModelB-StripFrames.jld2"))

    # ── A: control-vs-injection market strip pair, onset-aligned ────────────
    # Four onset-aligned frames per arm at offsets [t_on-1, +100, +250, +400]
    # (Compute-ModelB-StripFrames.jl picked seed 16, the median-representative
    # accelerating pair — see the JLD2's own `meta/created` note). Starting
    # the tile sequence at `t_on-1` rather than `t_on` makes the pre-toggle
    # bit-identity between the two rows a rendered fact (tile 1 of both rows
    # must be pixel-identical) rather than a claim the reader has to take on
    # faith; the arms only begin to diverge from tile 2 (`+100`) onward, and
    # by `+250` the injected row is visibly ahead. `outlines` traces the
    # largest sell cluster in every frame, same convention as Fig6's strip.
    # The two rows are merged into one heatmap so the tiles use the complete
    # panel width without separate header/row-label bands or nested subplot
    # margins. Time labels sit in the upper-right of every tile, and treatment
    # labels sit in the upper-left of each row's first tile.
    tile_labels = ["", "+100", "+250", "+400"]
    function _fig7_strip_pair_panel(frames_top::Vector{<:AbstractMatrix},
                                     frames_bottom::Vector{<:AbstractMatrix},
                                     labels::Vector{String};
                                     outlines_top = nothing, outlines_bottom = nothing,
                                     gap::Int64 = 4, rowgap::Int64 = 4)
        H, W = size(frames_top[1])
        n = length(frames_top)
        @assert length(frames_bottom) == n == length(labels)
        total_rows = 2H + rowgap
        total_cols = n*W + (n - 1)*gap
        canvas = fill(NaN, total_rows, total_cols)
        row_y0 = (0, H + rowgap)
        for (row_i, frames) in enumerate((frames_top, frames_bottom))
            y0 = row_y0[row_i]
            for (i, frame) in enumerate(frames)
                c0 = (i - 1)*(W + gap)
                canvas[(y0+1):(y0+H), (c0+1):(c0+W)] .= Float64.(frame)
            end
        end

        plt = heatmap(canvas; c = _grid_cgrad(), clims = (0, 2), yflip = true,
                      aspect_ratio = :equal, axis = false, colorbar = false,
                      framestyle = :none, background_color_inside = :white,
                      xlims = (0.5, total_cols + 0.5), ylims = (0.5, total_rows + 0.5),
                      margin = 0Plots.mm, top_margin = 9Plots.mm)

        # These are image annotations rather than axis text: keep them compact
        # and move the lower-row times away from the upper sell clusters.
        time_box_halfwidth = 11
        for (row_i, y0) in enumerate(row_y0), (i, lab) in enumerate(labels)
            isempty(lab) && continue
            c0 = (i - 1)*(W + gap)
            cx = c0 + W - time_box_halfwidth - 2
            cy = row_i == 1 ? y0 + 3.5 : y0 + H - 3.5
            plot!(plt, [cx - time_box_halfwidth, cx + time_box_halfwidth,
                        cx + time_box_halfwidth, cx - time_box_halfwidth],
                       [cy - 3, cy - 3, cy + 3, cy + 3];
                  seriestype = :shape, fillcolor = :white, fillalpha = 0.82,
                  linealpha = 0, label = "")
            annotate!(plt, cx, cy,
                      text(lab, :black, :center, 9, "helvetica"))
        end

        row_box_halfwidth = 16
        for (y0, lab) in zip(row_y0, ["control\nt_on-1", "cash x10\nt_on-1"])
            cx = 2.5 + row_box_halfwidth
            plot!(plt, [cx - row_box_halfwidth, cx + row_box_halfwidth,
                        cx + row_box_halfwidth, cx - row_box_halfwidth],
                       [y0 + 0.5, y0 + 0.5, y0 + 11.5, y0 + 11.5];
                  seriestype = :shape, fillcolor = :white, fillalpha = 0.82,
                  linealpha = 0, label = "")
            annotate!(plt, cx, y0 + 6,
                      text(lab, :black, :center, 9, "helvetica"))
        end

        for (row_i, outlines) in enumerate((outlines_top, outlines_bottom))
            outlines === nothing && continue
            y0 = row_y0[row_i]
            for (i, mask) in enumerate(outlines)
                mask === nothing && continue
                c0 = (i - 1)*(W + gap)
                outline_x, outline_y = _mask_outline_xy(mask, c0)
                isempty(outline_x) && continue
                plot!(plt, outline_x, outline_y .+ y0; seriescolor = :black,
                      linewidth = 1.2, label = "")
            end
        end
        return plt
    end

    anchor = _fig7_strip_pair_panel(
        strip_dat["fig7/control/frames"], strip_dat["fig7/injection/frames"], tile_labels;
        outlines_top = strip_dat["fig7/control/outlines"],
        outlines_bottom = strip_dat["fig7/injection/outlines"])
    _panel_letter!(anchor, "A")

    # ── B: ensemble price response under injection (new panel;
    # panel C, kept verbatim; only its letter changes) ──────────────────────
    subc = traj[(traj.direction .== "injection") .& (traj.condition .== "control"), :]
    subt = traj[(traj.direction .== "injection") .& (traj.condition .== "toggled"), :]
    joined_pre = innerjoin(subc[subc.step_since_onset .< 0,
                                [:seed, :step_since_onset, :price]],
                           subt[subt.step_since_onset .< 0,
                                [:seed, :step_since_onset, :price]],
                           on = [:seed, :step_since_onset], makeunique = true)
    @assert all(joined_pre.price .== joined_pre.price_1) "pre-toggle price paths must coincide"

    pc = _aligned_quantiles_from_traj(subc, :price, xs)
    pt = _aligned_quantiles_from_traj(subt, :price, xs)
    @assert isapprox(pc.q50[end], median(inj.price_ctrl_W); atol = 1e-10)
    @assert isapprox(pt.q50[end], median(inj.price_toggle_W); atol = 1e-10)
    pB = plot(; xlabel = "Steps since onset", ylabel = "Price (USD/share)",
              xticks = [-200, 0, 200, 400],
              legend = :topleft, _panel_kw...)
    plot!(pB, xs, pc.q50; ribbon = (pc.q50 .- pc.q25, pc.q75 .- pc.q50),
          fillalpha = 0.14, color = _SERIES_COLORS[5], lw = 2.2,
          label = "control")
    plot!(pB, xs, pt.q50; ribbon = (pt.q50 .- pt.q25, pt.q75 .- pt.q50),
          fillalpha = 0.14, color = _TOG_COLOR["injection"], lw = 2.2,
          label = "cash x10")
    vline!(pB, [0], color = :black, ls = :dash, lw = 1.0, label = "")
    price_span = maximum(pt.q75) - minimum(pc.q25)
    annotate!(pB, 35, maximum(pt.q75) - 0.03price_span,
              text("toggle", _ANNOTATION_FONTSIZE, :black, :left))
    _panel_letter!(pB, "B")

    # ── C: edge-ring mechanism, injection — the sign-reversal panel ───
    buy_c  = _aligned_mean_from_traj(subc, :edge_buy_frac,  xs)
    buy_t  = _aligned_mean_from_traj(subt, :edge_buy_frac,  xs)
    sell_c = _aligned_mean_from_traj(subc, :edge_sell_frac, xs)
    sell_t = _aligned_mean_from_traj(subt, :edge_sell_frac, xs)
    pC = plot(; xlabel = "Steps since onset", ylabel = "Edge-ring fraction",
              xticks = [-200, 0, 200, 400],
              ylims = (-0.02, 1.12), legend = false, _panel_kw...)
    plot!(pC, xs, buy_c,  color = _BUY_COLOR,  ls = :dash, lw = 1.8,
          alpha = 0.48, label = "")
    plot!(pC, xs, sell_c, color = _SELL_COLOR, ls = :dash, lw = 1.8,
          alpha = 0.48, label = "")
    plot!(pC, xs, buy_t,  color = _BUY_COLOR,  lw = 2.4, label = "")
    plot!(pC, xs, sell_t, color = _SELL_COLOR, lw = 2.4, label = "")
    vline!(pC, [0], color = :black, ls = :dash, lw = 1.0, label = "")
    # Direct keys occupy the two data-free upper corners and need no opaque
    # legend box. Hue identifies state; line style identifies arm.
    for (y, color, lab) in ((1.065, _BUY_COLOR, "Buy"),
                            (0.965, _SELL_COLOR, "Sell"))
        plot!(pC, [-185, -145], [y, y], color = color, lw = 2.4, label = "")
        annotate!(pC, -135, y,
                  text(lab, _ANNOTATION_FONTSIZE, :black, :left))
    end
    for (y, style, lab) in ((1.065, :dash, "control"),
                            (0.965, :solid, "toggled"))
        plot!(pC, [190, 230], [y, y], color = :black, ls = style,
              lw = style == :dash ? 1.8 : 2.4, label = "")
        annotate!(pC, 240, y,
                  text(lab, _ANNOTATION_FONTSIZE, :black, :left))
    end
    _panel_letter!(pC, "C")

    # ── D: paired dumbbell — control->toggled front velocity, all three arms
    # side by side ────────────────────────────────────────────────────────
    # Replaces the former panels A and B (two separate spaghetti plots, one
    # per experiment) with one categorical panel: injection at x=1, mild
    # withdrawal at x=2, harsh withdrawal at x=3, each seed drawn as a short
    # control(left)->toggled(right) segment plus endpoint markers. Injection
    # is the arm that reversed the boundary's sign, so it keeps the reserved
    # Sell hue (the front it accelerates is a sell wave); withdrawal was
    # statistically null at both doses, so both withdrawal arms share the
    # neutral _HOLD_COLOR, with harsh drawn at reduced alpha so the two
    # (otherwise identically-null) doses remain visually distinguishable
    # without introducing an out-of-palette hex. A local `Xoshiro` RNG (same
    # precedent as `_signflip_p` above) gives the per-seed jitter a fixed,
    # reproducible seed rather than drawing on shared global RNG state.
    dumbbell_arms = (
        (df = inj,   x = 1, color = _SELL_COLOR, alpha = 1.00),
        (df = mild,  x = 2, color = _HOLD_COLOR, alpha = 1.00),
        (df = harsh, x = 3, color = _HOLD_COLOR, alpha = 0.55),
    )
    half_width  = 0.16   # control/toggled separation within an arm's slot
    jitter_amp  = 0.09   # per-seed jitter around that separation
    all_v       = vcat(inj.v_ctrl, inj.v_toggle, mild.v_ctrl, mild.v_toggle,
                        harsh.v_ctrl, harsh.v_toggle) .* 1e4
    v_range     = maximum(all_v) - minimum(all_v)
    ytop        = maximum(all_v) + 0.18 * v_range   # room for the median annotation

    pD = plot(; xticks = ([1, 2, 3], ["injection", "mild", "harsh"]),
              xlims = (0.5, 3.5), ylims = (minimum(all_v) - 0.08 * v_range, ytop + 0.16 * v_range),
              ylabel = "Front velocity (10^-4 grid/step)",
              legend = false, _panel_kw...)
    jrng = Xoshiro(11)
    for arm in dumbbell_arms
        for r in eachrow(arm.df)
            jit    = (rand(jrng) - 0.5) * 2 * jitter_amp
            x_ctrl = arm.x - half_width + jit
            x_tog  = arm.x + half_width + jit
            plot!(pD, [x_ctrl, x_tog], [r.v_ctrl, r.v_toggle] .* 1e4,
                  color = arm.color, alpha = arm.alpha * 0.5, lw = 1.0, label = "")
            scatter!(pD, [x_ctrl, x_tog], [r.v_ctrl, r.v_toggle] .* 1e4,
                     color = arm.color, alpha = arm.alpha, markersize = 3,
                     markerstrokewidth = 0, label = "")
        end
        med_ctrl = median(arm.df.v_ctrl)  * 1e4
        med_tog  = median(arm.df.v_toggle) * 1e4
        # The categorical x-axis already names each arm, so an arm legend
        # would duplicate those labels and steal horizontal space. Marginal
        # medians stay as plain text rather than a bold median trend line:
        # the paired sign-flip tests use per-seed differences, and for mild
        # withdrawal the marginal medians and paired result disagree in sign.
        # Stacked two-line text (not a single "1.39→3.55" line): the arm
        # slots are ~1 data-unit wide and a one-line arrow label overruns
        # into the neighbouring arm's slot at any legible font size (tried
        # first; overlapped). A narrow vertical stack fits inside one slot.
        annotate!(pD, arm.x, ytop,
                  text(@sprintf("%.2f\n%.2f", med_ctrl, med_tog), 8, :black, :center))
    end
    _panel_letter!(pD, "D")

    # The compact merged strip uses the complete upper width, and the lower
    # panels share an equal split because no legend occupies an external
    # column. The wider canvas keeps all three diagnostics legible at the
    # manuscript's full-line figure width.
    fig7 = plot(anchor, pB, pC, pD;
                layout = @layout([a{0.58h}; b c d]), size = (900, 760))
    _save_figure(fig7, "Fig7-Intervention.pdf")
end

@info "Figs-ModelB-BudgetToggle.jl complete."
