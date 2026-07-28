# Figs-ModelB-BarrierLaw.jl — Fig6-GrowthGating.pdf, the figure carrying the
# paper's central mechanism claim: budgets do not change WHETHER a nucleus is
# born, only HOW FAST it grows. Drawn ENTIRELY from committed CSVs (no
# simulation):
#   code/data/ModelB-Nucleation-EscapeTime.csv             (panels A, C, D)
#   code/data/ModelB-Nucleation-EscapeTime-Fits.csv        (panel A fits)
#   code/data/ModelB-Nucleation-SeedingIntervention.csv    (panel B)
# Standalone-rerunnable from the repo root:
#   julia code/model-b/Figs-ModelB-BarrierLaw.jl
#
# Writes: code/figs/ + paper-arxiv/figs/
#
# SCRIPT OWNERSHIP (task dispatch ruling): this script builds ALL FOUR panels
# of Fig6-GrowthGating.pdf itself, reading the three CSVs it needs directly —
# it supersedes this script's own former output (`ModelB-Nucleation-
# BarrierLaw.pdf`, panels: median onset time, onset rate by horizon, fitted
# f0, fitted B), which is no longer emitted by this file.
# `Figs-ModelB-VelocitySuppression.jl` and `Figs-ModelB-BoundaryVsBulk.jl`
# keep emitting their CURRENT figures unchanged for now (Task 10 turns those
# into supplementary figures); VelocitySuppression.jl is touched here only to
# share the A2 subset rule and the cash ramp (see EscapeTime-Lib.jl), not to
# change what it emits.
#
# CASH RAMP (design-conflict resolution): the brief asked for panels A and D
# to track cash via `_SERIES_COLORS[1..3]`, but panel A has THREE cash levels
# (500, 1000, 5000) and panel D/C have FIVE (250, 500, 1000, 2000, 5000) — 3
# reserved colours cannot cover 5 doses. Resolved by building ONE five-step
# sequential ramp (`CASH_RAMP` in EscapeTime-Lib.jl) over the full dose set
# and having panel A's three levels take the SAME colours those levels get in
# the five-step ramp (positions 2, 3, 5) — see `cash_color_map`. A reader
# therefore tracks one budget level across every panel in this figure.
#
# Body is a `let` block (locals only) so it can be included after a sweep
# without global-constant collisions.

isdefined(Main, :_PATH_TO_DATA)   || include(joinpath(@__DIR__, "Include.jl"))
isdefined(Main, :censored_median) || include(joinpath(@__DIR__, "EscapeTime-Lib.jl"))
using Printf

let
    df      = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime.csv"), DataFrame)
    fits    = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime-Fits.csv"), DataFrame)
    seed_df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedingIntervention.csv"), DataFrame)

    fits_sorted = sort(fits, :cash)                 # do not trust CSV row order
    a1          = df[df.stage .!= "a2x", :]
    cashes_a1   = sort(unique(a1.cash))              # [500, 1000, 5000]
    a2, n_excluded = a2_subset(df)                   # pooled f=0.20 window, shared with VelocitySuppression
    cashes_a2   = sort(unique(a2.cash))              # [250, 500, 1000, 2000, 5000] — the full ramp domain

    @assert Set(cashes_a1) ⊆ Set(cashes_a2) "panel A's cash levels must be a subset of the full dose ramp"
    cash_color  = cash_color_map(cashes_a2, cashes_a2)   # covers all 5 doses; panel A indexes the same dict

    # ── Panel B source: dominance rate over the six (config × placement) cells ──
    # Control excluded: there is no patch to found a domain from.
    dom_configs = ["freeze", "collapse"]
    dom_arms    = ["edge", "mid", "center"]
    dom_rate    = Dict{Tuple{String,String},Float64}()
    dom_n       = Dict{Tuple{String,String},Int}()
    for cfg in dom_configs, arm in dom_arms
        s = seed_df[(seed_df.config .== cfg) .& (seed_df.arm .== arm), :dominant_from_patch]
        dom_n[(cfg, arm)]    = length(s)
        dom_rate[(cfg, arm)] = count(s) / length(s)
    end
    dominance_rate = [dom_rate[(cfg, arm)] for cfg in dom_configs for arm in dom_arms]

    # ── Panel C/D source: velocity vs. absolute suppression, Spearman + permutation p ──
    sp = spearman_perm_p(collect(Float64.(a2.suppb_w)), collect(Float64.(a2.v_front)))

    # ── Assert the cited values before plotting anything ───────────────────
    r2_by_cash   = fits_sorted.r2
    n_fit_points = fits_sorted.n_points
    spearman_rho = sp.rho
    perm_p       = sp.p
    n_included   = nrow(a2)

    @assert all(isapprox.(r2_by_cash, [0.978, 0.990, 0.980]; atol = 0.002)) "barrier-law R^2 does not reproduce"
    @assert n_fit_points == [5, 6, 6] "fit point counts do not reproduce"
    @assert all(==(20), values(dom_n)) "expected 20 seeds per configuration-by-placement cell"
    @assert all(dominance_rate .== 0.0) "the stamped patch must never found the winning domain"
    @assert isapprox(spearman_rho, -0.372; atol = 0.005) "velocity-suppression rho does not reproduce"
    @assert perm_p <= 0.0005 "permutation p does not reproduce"
    @assert n_included == 97 "97 runs must be included, 3 excluded by the window rule"

    # ── A: Kaplan-Meier median onset time vs f, three cash levels, fitted curves ──
    # Model A reference: ln τ = 2.78 + 0.389/(f − 0.101), R² = 0.991 (Results).
    A_REF, B_REF, F0_REF = 2.78, 0.389, 0.101
    # Display ceiling for curve drawing only (~15x the 2000-step horizon) — not
    # an analysis quantity; keeps the empirical curves from stretching the log
    # axis across 15 decades and crushing the data medians.
    TAU_MAX = 3.0e4

    pA = plot(; xlabel = "f", ylabel = "median onset time (steps)", yscale = :log10,
              ylims = (50, TAU_MAX), legend = :topright, _panel_kw...)
    fref = range(F0_REF + B_REF / (log(TAU_MAX) - A_REF), maximum(a1.f); length = 400)
    plot!(pA, fref, exp.(A_REF .+ B_REF ./ (fref .- F0_REF)),
          color = :black, ls = :dash, lw = 1.5, label = "Model A fit")
    for cash in cashes_a1
        sub   = a1[a1.cash .== cash, :]
        fvals = sort(unique(sub.f))
        meds  = [censored_median(Int.(sub.t_on[sub.f .== f])) for f in fvals]
        ok    = .!isnan.(meds)
        scatter!(pA, fvals[ok], meds[ok], color = cash_color[cash],
                 markersize = 5, markerstrokewidth = 0.5, label = "cash $(Int(cash))")
        fr = fits_sorted[fits_sorted.cash .== cash, :]
        if nrow(fr) == 1 && !isnan(fr.f0[1])
            fstart = fr.f0[1] + fr.B[1] / (log(TAU_MAX) - fr.A[1])
            fc = range(min(fstart, maximum(fvals[ok]) - 1e-4), maximum(fvals[ok]); length = 400)
            plot!(pA, fc, exp.(fr.A[1] .+ fr.B[1] ./ (fc .- fr.f0[1])),
                  color = cash_color[cash], lw = 1.6, label = "")
        end
    end
    _panel_letter!(pA, "A")

    # ── B: dominance rate, six (config × placement) cells, all zero ────────
    # A flat line at zero would understate what 20 trials per cell actually
    # rules out. Each bar carries a one-sided Wilson 95% upper bound (k=0,
    # n=20 in every cell) as its error whisker: the true rate could be as
    # high as ~16% and still look like this by chance; anything above that is
    # excluded at 95% confidence. Dominance rates use the SAME config colours
    # as Fig5-Nucleus.pdf (freeze pink, collapse Sell-orange — collapse is
    # genuinely the config that converts the lattice to Sell) for cross-figure
    # consistency; this is not the cash ramp, since config is not an ordinal
    # budget quantity.
    function _wilson_upper(k::Int, n::Int; z::Float64 = 1.96)
        n == 0 && return 1.0
        phat = k / n
        d = 1 + z^2 / n
        c = (phat + z^2 / (2n)) / d
        h = z * sqrt(phat * (1 - phat) / n + z^2 / (4n^2)) / d
        return min(1.0, c + h)
    end
    wilson_hi   = _wilson_upper(0, 20)
    cfg_color   = Dict("freeze" => _SERIES_COLORS[3], "collapse" => _SELL_COLOR)
    x_offset    = Dict("freeze" => -0.18, "collapse" => 0.18)
    pB = plot(; xlabel = "patch placement", ylabel = "dominance rate (patch founds the winning domain)",
              xticks = (1:3, dom_arms), xlims = (0.5, 3.5), ylims = (0, 1.15 * wilson_hi),
              legend = :outertopright, _panel_kw...)
    for cfg in dom_configs
        xs  = (1:3) .+ x_offset[cfg]
        ys  = [dom_rate[(cfg, arm)] for arm in dom_arms]
        his = fill(wilson_hi, 3)
        # markerstrokecolor colours the error-bar whiskers themselves — Plots
        # draws yerror whiskers in plain black by default regardless of the
        # bar's own `color`, which is invisible ANYWAY at zero height; without
        # this the six cells would render as six identical black ticks and
        # the freeze/collapse legend swatches would match nothing on-panel.
        bar!(pB, xs, ys, yerror = (zeros(3), his), bar_width = 0.32,
             color = cfg_color[cfg], fillalpha = 0.75, lw = 1.2,
             markerstrokecolor = cfg_color[cfg], label = "$(cfg) (0/20 each)")
    end
    annotate!(pB, (0.5, 0.93),
              text("0/20 in every one of the six cells\n(whiskers: 95% Wilson upper bound)",
                   7, :black, :center))
    _panel_letter!(pB, "B")

    # ── C: front velocity vs. absolute suppression, coloured by dose ───────
    # ρ, p, n, and the exclusion count previously lived in this panel's title;
    # with titles gone, they move to an in-panel text annotation instead.
    pC = plot(; xlabel = "suppressed buy orders / step (absolute)",
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
        scatter!(pC, s.suppb_w, s.v_front .* 1e4, color = cash_color[cash],
                 markersize = 4, markerstrokewidth = 0.3, alpha = 0.8,
                 label = "cash $(Int(cash)) (n=$(nrow(s)))")
    end
    for cash in cashes_a2
        s = a2[a2.cash .== cash, :]
        scatter!(pC, [median(s.suppb_w)], [median(s.v_front) * 1e4],
                 color = cash_color[cash], marker = :diamond, markersize = 9,
                 markerstrokewidth = 1.2, markerstrokecolor = :black, label = "")
    end
    annotate!(pC, (0.97, 0.95),
              text(@sprintf("Spearman ρ = %.3f\npermutation p = %.4f\n(n = %d, excl. %d)",
                            spearman_rho, perm_p, n_included, n_excluded),
                   8, :black, :right))
    _panel_letter!(pC, "C")

    # ── D: velocity by initial cash, coloured by the same dose ramp ────────
    # x already carries cash unambiguously (log-scaled, one tick per dose), so
    # no legend is needed to track colour — the same dose is already
    # identified twice over (position and colour).
    pD = plot(; xlabel = "initial cash", ylabel = "front velocity × 1e4",
              xscale = :log10, xticks = (cashes_a2, string.(Int.(cashes_a2))),
              legend = false, _panel_kw...)
    for cash in cashes_a2
        s = a2[a2.cash .== cash, :]
        scatter!(pD, fill(cash, nrow(s)), s.v_front .* 1e4,
                 color = cash_color[cash], markersize = 4, markerstrokewidth = 0.3, alpha = 0.8)
        plot!(pD, [cash / 1.25, cash * 1.25], fill(median(s.v_front) * 1e4, 2),
              color = :black, lw = 2.0)
    end
    _panel_letter!(pD, "D")

    fig = plot(pA, pB, pC, pD; layout = (2, 2), size = (1150, 950),
               left_margin = 6Plots.mm, bottom_margin = 4Plots.mm)
    _save_figure(fig, "Fig6-GrowthGating.pdf")
    @info "Saved: Fig6-GrowthGating.pdf"

    # =========================================================================
    # FigS4-BarrierParameters.pdf (Task 10) — the three panels dropped from the
    # main figure when it was reduced to A-D: onset rate vs f (all three cash
    # levels), and the fitted Kramers parameters (f0, B) per cash level with
    # bootstrap CIs. Reuses `a1`, `cashes_a1`, `cash_color`, `fits_sorted`,
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

    figS4 = plot(pS1, pS2, pS3; layout = (1, 3), size = (1500, 430),
                 left_margin = 6Plots.mm, bottom_margin = 4Plots.mm)
    _save_figure(figS4, "FigS4-BarrierParameters.pdf")
end
