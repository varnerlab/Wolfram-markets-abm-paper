# Figs-ModelB-BarrierLaw.jl — Fig6-GrowthGating.pdf, the figure carrying the
# paper's central mechanism claim: budgets do not change WHETHER a nucleus is
# born, only HOW FAST it grows. Mostly drawn from committed CSVs, plus one
# JLD2 for the strip pair (Task 3/5):
#   code/data/ModelB-StripFrames.jld2                      (panel A strips)
#   code/data/ModelB-Nucleation-EscapeTime.csv             (panels B, C)
#   code/data/ModelB-Nucleation-EscapeTime-Fits.csv        (panel B fits)
# Standalone-rerunnable from the repo root:
#   julia code/model-b/Figs-ModelB-BarrierLaw.jl
#
# Writes: code/figs/ + paper-arxiv/figs/
#
# SCRIPT OWNERSHIP (task dispatch ruling): this script builds every panel of
# Fig6-GrowthGating.pdf itself, reading the CSVs/JLD2 it needs directly — it
# supersedes this script's own former output (`ModelB-Nucleation-
# BarrierLaw.pdf`, panels: median onset time, onset rate by horizon, fitted
# f0, fitted B), which is no longer emitted by this file.
# The standalone dose-response script that used to draw the velocity panels on
# its own has been retired; its window rule and cash ramp live in
# EscapeTime-Lib.jl and are read from there.
#
# TASK 5 REWORK: Fig6 is now anchored on the freeze-vs-collapse strip pair
# (panel A, onset-aligned, `ModelB-StripFrames.jld2` keys `fig6/freeze/*` and
# `fig6/collapse/*` — both seed 17). The former panel A (KM medians + fitted
# divergences) becomes panel B, verbatim. The former panel B (dominance rate
# over six config x placement cells, 0/20 everywhere) is DELETED from this
# figure: that null result is stated in prose and detailed in full in
# FigS5-SeedingDetail.pdf, so drawing it a second time here added nothing.
# The former panel C (velocity vs. suppression) stays panel C, verbatim. The
# former panel D (velocity by initial cash) moves into FigS4-BarrierParameters
# as its new panel D, verbatim, below.
#
# CASH RAMP (design-conflict resolution): the brief asked for panels tracking
# cash (now B and FigS4's D) to use `_SERIES_COLORS[1..3]`, but panel B has
# THREE cash levels (500, 1000, 5000) and panel C/FigS4-D have FIVE (250, 500,
# 1000, 2000, 5000) — 3 reserved colours cannot cover 5 doses. Resolved by
# building ONE five-step sequential ramp (`CASH_RAMP` in EscapeTime-Lib.jl)
# over the full dose set and having panel B's three levels take the SAME
# colours those levels get in the five-step ramp (positions 2, 3, 5) — see
# `cash_color_map`. A reader therefore tracks one budget level across every
# panel in this figure.
#
# Body is a `let` block (locals only) so it can be included after a sweep
# without global-constant collisions.

isdefined(Main, :_PATH_TO_DATA)   || include(joinpath(@__DIR__, "Include.jl"))
isdefined(Main, :censored_median) || include(joinpath(@__DIR__, "EscapeTime-Lib.jl"))
using Printf

let
    df   = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime.csv"), DataFrame)
    fits = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime-Fits.csv"), DataFrame)
    strip_dat = load(joinpath(_PATH_TO_DATA, "ModelB-StripFrames.jld2"))

    fits_sorted = sort(fits, :cash)                 # do not trust CSV row order
    a1          = df[df.stage .!= "a2x", :]
    cashes_a1   = sort(unique(a1.cash))              # [500, 1000, 5000]
    a2, n_excluded = a2_subset(df)                   # pooled f=0.20 window (EscapeTime-Lib.jl)
    cashes_a2   = sort(unique(a2.cash))              # [250, 500, 1000, 2000, 5000] — the full ramp domain

    @assert Set(cashes_a1) ⊆ Set(cashes_a2) "panel B's cash levels must be a subset of the full dose ramp"
    cash_color  = cash_color_map(cashes_a2, cashes_a2)   # covers all 5 doses; panel B indexes the same dict

    # ── Panel C source: velocity vs. absolute suppression, Spearman + permutation p ──
    sp = spearman_perm_p(collect(Float64.(a2.suppb_w)), collect(Float64.(a2.v_front)))

    # ── Assert the cited values before plotting anything ───────────────────
    r2_by_cash   = fits_sorted.r2
    n_fit_points = fits_sorted.n_points
    spearman_rho = sp.rho
    perm_p       = sp.p
    n_included   = nrow(a2)

    @assert all(isapprox.(r2_by_cash, [0.978, 0.990, 0.980]; atol = 0.002)) "barrier-law R^2 does not reproduce"
    @assert n_fit_points == [5, 6, 6] "fit point counts do not reproduce"
    @assert isapprox(spearman_rho, -0.372; atol = 0.005) "velocity-suppression rho does not reproduce"
    @assert perm_p <= 0.0005 "permutation p does not reproduce"
    @assert n_included == 97 "97 runs must be included, 3 excluded by the window rule"

    # ── A: freeze-vs-collapse market strip pair, onset-aligned ──────────────
    # `ModelB-StripFrames.jld2` (Task 3) carries four 64x64 frames per arm at
    # onset-aligned offsets [t_on, +100, +250, +400] — the two arms have
    # different absolute t_on (freeze/cash 500 nucleates later than
    # collapse/cash 5000), which is the point of aligning by offset rather
    # than by absolute step: a reader compares how far each arm's nucleus has
    # grown N steps after ITS OWN onset, not two unrelated clocks. `outlines`
    # traces the largest sell cluster in every frame; `rowlabel` spells out
    # the cash level driving each arm, since "freeze"/"collapse" are internal
    # config names that never appear on the page. Panel letter via the
    # Fig2/Fig5 blank-row technique: `_panel_letter!` cannot be used directly
    # on a yflip strip (see the Fig5-Nucleus.pdf block for the full rationale).
    tile_labels = ["t_on", "+100", "+250", "+400"]
    strip_freeze = _strip_panel(strip_dat["fig6/freeze/frames"], tile_labels;
                                 outlines = strip_dat["fig6/freeze/outlines"],
                                 rowlabel = "cash 500")
    strip_collapse = _strip_panel(strip_dat["fig6/collapse/frames"], tile_labels;
                                   outlines = strip_dat["fig6/collapse/outlines"],
                                   rowlabel = "cash 5,000")
    strip_pair = plot(strip_freeze, strip_collapse; layout = @layout([a; b]))
    _letterA = plot(; framestyle = :none, grid = false, legend = false,
                     ticks = false, xlims = (0, 1), ylims = (0, 1))
    _panel_letter!(_letterA, "A")
    anchor = plot(_letterA, strip_pair; layout = @layout([a{0.08h}; b]))

    # ── B: Kaplan-Meier median onset time vs f, three cash levels, fitted curves ──
    # Model A reference: ln τ = 2.78 + 0.389/(f − 0.101), R² = 0.991 (Results).
    A_REF, B_REF, F0_REF = 2.78, 0.389, 0.101
    # Display ceiling for curve drawing only (~15x the 2000-step horizon) — not
    # an analysis quantity; keeps the empirical curves from stretching the log
    # axis across 15 decades and crushing the data medians.
    TAU_MAX = 3.0e4

    panelB = plot(; xlabel = "f", ylabel = "median onset time (steps)", yscale = :log10,
              ylims = (50, TAU_MAX), legend = :topright, _panel_kw...)
    fref = range(F0_REF + B_REF / (log(TAU_MAX) - A_REF), maximum(a1.f); length = 400)
    plot!(panelB, fref, exp.(A_REF .+ B_REF ./ (fref .- F0_REF)),
          color = :black, ls = :dash, lw = 1.5, label = "Model A fit")
    for cash in cashes_a1
        sub   = a1[a1.cash .== cash, :]
        fvals = sort(unique(sub.f))
        meds  = [censored_median(Int.(sub.t_on[sub.f .== f])) for f in fvals]
        ok    = .!isnan.(meds)
        scatter!(panelB, fvals[ok], meds[ok], color = cash_color[cash],
                 markersize = 5, markerstrokewidth = 0.5, label = "cash $(Int(cash))")
        fr = fits_sorted[fits_sorted.cash .== cash, :]
        if nrow(fr) == 1 && !isnan(fr.f0[1])
            fstart = fr.f0[1] + fr.B[1] / (log(TAU_MAX) - fr.A[1])
            fc = range(min(fstart, maximum(fvals[ok]) - 1e-4), maximum(fvals[ok]); length = 400)
            plot!(panelB, fc, exp.(fr.A[1] .+ fr.B[1] ./ (fc .- fr.f0[1])),
                  color = cash_color[cash], lw = 1.6, label = "")
        end
    end
    _panel_letter!(panelB, "B")

    # Former panel B (dominance rate over six config x placement cells, 0/20
    # everywhere with a one-sided Wilson 95% upper bound) is removed from this
    # figure: that null result is stated in prose and detailed in full in
    # FigS5-SeedingDetail.pdf, so this figure no longer draws it a second time.

    # ── C: front velocity vs. absolute suppression, coloured by dose ───────
    # ρ, p, n, and the exclusion count previously lived in this panel's title;
    # with titles gone, they move to an in-panel text annotation instead.
    panelC = plot(; xlabel = "suppressed buy orders / step (absolute)",
              ylabel = "front velocity × 1e4 (fraction/step)",
              legend = :outertopright, _panel_kw...)
    # Two passes — every point, THEN every median diamond — rather than one
    # pass per cash group. The five medians cluster tightly, so interleaving
    # (points, diamond) per group let a later group's diamond partially cover
    # an earlier group's individual points (self-occlusion from loop order,
    # not a design choice). Drawing all 97 points first and all five diamonds
    # last is the same visual intent (raw data underneath, medians marked on
    # top) with no dependence on iteration order.
    for cash in cashes_a2
        s = a2[a2.cash .== cash, :]
        scatter!(panelC, s.suppb_w, s.v_front .* 1e4, color = cash_color[cash],
                 markersize = 4, markerstrokewidth = 0.3, alpha = 0.8,
                 label = "cash $(Int(cash)) (n=$(nrow(s)))")
    end
    for cash in cashes_a2
        s = a2[a2.cash .== cash, :]
        scatter!(panelC, [median(s.suppb_w)], [median(s.v_front) * 1e4],
                 color = cash_color[cash], marker = :diamond, markersize = 9,
                 markerstrokewidth = 1.2, markerstrokecolor = :black, label = "")
    end
    annotate!(panelC, (0.97, 0.95),
              text(@sprintf("Spearman ρ = %.3f\npermutation p = %.4f\n(n = %d, excl. %d)",
                            spearman_rho, perm_p, n_included, n_excluded),
                   8, :black, :right))
    _panel_letter!(panelC, "C")

    fig = plot(anchor, panelB, panelC; layout = @layout([a{0.46h}; b c]), size = (1160, 980))
    _save_figure(fig, "Fig6-GrowthGating.pdf")
    @info "Saved: Fig6-GrowthGating.pdf"

    # =========================================================================
    # FigS4-BarrierParameters.pdf (Task 10; gains panel D in Task 5) — the two
    # panels dropped from the main figure when it was reduced to A-C: onset
    # rate vs f (all three cash levels), and the fitted Kramers parameters
    # (f0, B) per cash level with bootstrap CIs, plus (Task 5) the former Fig6
    # panel D (velocity by initial cash), moved here verbatim when Fig6 was
    # reduced to the strip pair + KM panel + velocity-suppression scatter.
    # Reuses `a1`, `cashes_a1`, `cash_color`, `fits_sorted`, `a2`, `cashes_a2`,
    # and the Model A reference constants already computed above — no refit.
    # =========================================================================
    pS1 = plot(; xlabel = "f", ylabel = "fraction of seeds with onset (within horizon)",
               ylims = (0, 1.05), legend = :outertopright, _panel_kw...)
    for cash in cashes_a1
        sub   = a1[a1.cash .== cash, :]
        fvals = sort(unique(sub.f))
        onr   = [mean(sub.t_on[sub.f .== f] .> 0) for f in fvals]
        plot!(pS1, fvals, onr, color = cash_color[cash], lw = 1.6,
              marker = :circle, markersize = 4, markerstrokewidth = 0,
              label = "cash $(Int(cash))")
    end
    _panel_letter!(pS1, "A")

    fok    = fits_sorted[.!isnan.(fits_sorted.f0), :]
    xs_fit = collect(1:max(nrow(fok), 1))

    pS2 = plot(; xlabel = "initial cash", ylabel = "fitted pseudo-threshold f0",
               xticks = (xs_fit, string.(Int.(fok.cash))),
               xlims = (0.5, max(nrow(fok), 1) + 0.5), legend = false, _panel_kw...)
    if nrow(fok) > 0
        scatter!(pS2, xs_fit, fok.f0, yerror = (fok.f0 .- fok.f0_lo, fok.f0_hi .- fok.f0),
                 color = [cash_color[c] for c in fok.cash], markersize = 6, markerstrokewidth = 0.5)
        hline!(pS2, [F0_REF], color = :black, ls = :dash, lw = 1.0, label = "")
    end
    _panel_letter!(pS2, "B")

    pS3 = plot(; xlabel = "initial cash", ylabel = "fitted shape coefficient B",
               xticks = (xs_fit, string.(Int.(fok.cash))),
               xlims = (0.5, max(nrow(fok), 1) + 0.5), legend = false, _panel_kw...)
    if nrow(fok) > 0
        scatter!(pS3, xs_fit, fok.B, yerror = (fok.B .- fok.B_lo, fok.B_hi .- fok.B),
                 color = [cash_color[c] for c in fok.cash], markersize = 6, markerstrokewidth = 0.5)
        hline!(pS3, [B_REF], color = :black, ls = :dash, lw = 1.0, label = "")
    end
    _panel_letter!(pS3, "C")

    # ── D: velocity by initial cash, coloured by the same dose ramp ────────
    # Moved here verbatim from Fig6 (Task 5): x already carries cash
    # unambiguously (log-scaled, one tick per dose), so no legend is needed
    # to track colour — the same dose is already identified twice over
    # (position and colour).
    pS4 = plot(; xlabel = "initial cash", ylabel = "front velocity × 1e4",
               xscale = :log10, xticks = (cashes_a2, string.(Int.(cashes_a2))),
               legend = false, _panel_kw...)
    for cash in cashes_a2
        s = a2[a2.cash .== cash, :]
        scatter!(pS4, fill(cash, nrow(s)), s.v_front .* 1e4,
                 color = cash_color[cash], markersize = 4, markerstrokewidth = 0.3, alpha = 0.8)
        plot!(pS4, [cash / 1.25, cash * 1.25], fill(median(s.v_front) * 1e4, 2),
              color = :black, lw = 2.0)
    end
    _panel_letter!(pS4, "D")

    # Taller canvas and larger left/bottom margins than the Fig6 combine call
    # above: a single-row (1,3) layout at only 430pt of total height left the
    # x-axis titles ("f", "initial cash" x2) and panel A's y-axis title
    # clipped against the page edge (Task 13 fix review). Extended to (2,2)
    # (Task 5) to seat the new panel D; Fig6 is built entirely above this
    # point from anchor/panelB/panelC and is untouched by this change.
    figS4 = plot(pS1, pS2, pS3, pS4; layout = (2, 2), size = (1150, 950),
                 left_margin = 12Plots.mm, bottom_margin = 10Plots.mm, top_margin = 10Plots.mm)
    _save_figure(figS4, "FigS4-BarrierParameters.pdf")
end
