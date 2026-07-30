# Figs-ModelA-FiniteSize.jl — system-size scaling of the sell-state escape,
# drawn ENTIRELY from committed data (no simulation, except the tiny strip
# capture already baked into the committed JLD2 below):
#   code/data/ModelA-FiniteSizeScaling.csv     (survey pass, per-seed)
#   code/data/ModelA-FiniteSizeSummary.csv     (survey pass, cv_t_conv — cited assertions)
#   code/data/ModelA-AvramiFits.csv            (Avrami pass)
#   code/data/ModelA-AvramiTrajectories.csv    (Avrami pass, per-run curves)
#   code/data/ModelA-FiniteSizeStrips.jld2     (one grid per L at common t*)
# Standalone-rerunnable from the repo root:
#   julia code/model-a/Figs-ModelA-FiniteSize.jl
#
# Writes: code/figs/ + paper-arxiv/figs/
#
# Two `let` blocks (locals only, no consts colliding on re-include), so this
# file can be standalone-rerun repeatedly:
#   1) Fig-ModelA-FiniteSize.pdf — (A) size-contrast market strip: one grid per
#      L in {64, 128, 512} at f = 0.15 and a common absolute time t*, showing
#      the escape at different stages for the same clock reading (former
#      panels B/C/D's whole point, made visible rather than only measured).
#      (B) conversion-fraction-vs-f curves thinned to those same three sizes,
#      direct end-labels instead of a legend box (former panel A). (C)
#      rescaled-collapse panel (former panel D, verbatim).
#   2) FigS7-FiniteSizeDetail.pdf — the two panels the strip panel above
#      displaced: former panel B (dispersion collapse / coefficient of
#      variation) and former panel C (conversion-time saturation), verbatim,
#      letters A/B.
#
# Run: julia --project=code code/model-a/Figs-ModelA-FiniteSize.jl

isdefined(Main, :_PATH_TO_DATA) || include(joinpath(@__DIR__, "Include.jl"))
using Printf

# ── Shared survey data (used by both the strip-adjacent panel B below and by
# FigS7's panels A/B) ────────────────────────────────────────────────────────
survey = CSV.read(joinpath(_PATH_TO_DATA, "ModelA-FiniteSizeScaling.csv"), DataFrame)
LS     = sort(unique(survey.L))
FS     = sort(unique(survey.f))

# Wilson score interval — behaves at p = 0 and p = 1, unlike the normal
# approximation, and several cells sit at exactly 0/20 or 20/20.
function wilson(k, n; z = 1.96)
    n == 0 && return (0.0, 1.0)
    p̂ = k / n
    d = 1 + z^2 / n
    c = (p̂ + z^2 / (2n)) / d
    h = z * sqrt(p̂ * (1 - p̂) / n + z^2 / (4n^2)) / d
    return (max(0.0, c - h), min(1.0, c + h))
end

# ─────────────────────────────────────────────────────────────────────────
# 1) Fig-ModelA-FiniteSize.pdf
# ─────────────────────────────────────────────────────────────────────────
let
    avrami = CSV.read(joinpath(_PATH_TO_DATA, "ModelA-AvramiFits.csv"), DataFrame)
    av_ls  = sort(unique(avrami.L))   # Avrami fits exist only for L = 64-512; no L = 32 row.
    strips = load(joinpath(_PATH_TO_DATA, "ModelA-FiniteSizeStrips.jld2"))

    # ── Assert the cited values before plotting anything ───────────────────
    # Paper_v1.tex:1119-1120 quotes n "on the largest lattice," not pooled over
    # all four — filter to L = maximum(av_ls) first, the same lattice panel C's
    # n_big uses below, so the assertion checks the fit the paper actually cites.
    n_f016 = mean(avrami[(avrami.L .== maximum(av_ls)) .& (avrami.f .== 0.16), :avrami_n])
    n_f020 = mean(avrami[(avrami.L .== maximum(av_ls)) .& (avrami.f .== 0.20), :avrami_n])
    inv_K_f018 = [1 / mean(avrami[(avrami.L .== L) .& (avrami.f .== 0.18), :avrami_K]) for L in av_ls]

    @assert isapprox(n_f016, 2.54; atol = 0.05) "Avrami n at f=0.16 (largest lattice) does not reproduce"
    @assert isapprox(n_f020, 1.91; atol = 0.05) "Avrami n at f=0.20 (largest lattice) does not reproduce"
    @assert all(isapprox.(inv_K_f018, [1445, 1363, 1367, 1358]; rtol = 0.02)) "1/K spread does not reproduce"

    # Size ramp: single-hue sequential purple (ColorBrewer "Purples", 9-class,
    # keeping only classes 5-9). The first attempt used the standard 5-class
    # Purples ramp starting at #f2f0f7, which sits 7 RGB units from
    # _panel_kw's background_color_inside (#F0F0F0) — invisible against the
    # house gray. Classes 5-9 of the 9-class ramp keep the same hue family but
    # start at #9e9ac8 (contrast 125 vs. the background, on par with
    # _HOLD_COLOR's own 121) and end one class darker than before, so every
    # step — including L = 32, the smallest lattice — carries visible ink.
    # The old ramp's endpoints (#0072B2, #D55E00) also duplicated the reserved
    # Buy/Sell hues, which here would read as "state," not "size."
    size_colors = ["#9e9ac8", "#807dba", "#6a51a3", "#54278f", "#3f007d"]
    Lcolor = Dict(L => size_colors[min(i, length(size_colors))] for (i, L) in enumerate(LS))

    # ── A: size-contrast market strip ───────────────────────────────────────
    # One tile per L, each its own heatmap (the strip tiles are NOT equal
    # shape — 64x64 vs 128x128 vs 512x512 — so _strip_canvas/_strip_panel,
    # which assume equal-shaped frames sharing one canvas, do not apply here).
    # Equal on-page tile size comes from the shared grid() cell, not from
    # equal pixel counts: aspect_ratio = :equal locks each tile's own 1:1
    # data scale, and identical zero margins keep every tile's cell the same
    # physical size, so the granularity difference (64x64 blocky vs 512x512
    # fine) is the only thing that visibly differs between tiles.
    #
    # Labels use the Fig2-Combined.jl blank-row/label-panel technique (a
    # dedicated blank subplot per column, not `annotate!` on the yflip heatmap
    # tile itself — see PaperStyle.jl's `_panel_letter!` docstring for why a
    # relative-position annotation on a yflip tile lands on the wrong side).
    _blank_panel() = plot(; framestyle = :none, grid = false, legend = false,
                          ticks = false, xlims = (0, 1), ylims = (0, 1))
    function _col_label(label::String)
        p = _blank_panel()
        annotate!(p, (0.5, 0.5), text(label, :black, :center, 9))
        return p
    end
    _size_tile(frame) = heatmap(frame;
        c = _grid_cgrad(), clims = (0, 2), yflip = true, aspect_ratio = :equal,
        axis = false, colorbar = false, framestyle = :none, margin = 0Plots.mm)

    tstar      = strips["tstar"]
    size_order = [64, 128, 512]
    size_frames = [strips["L$(L)"] for L in size_order]

    corner = _blank_panel()
    _panel_letter!(corner, "A")

    panelsA = Plots.Plot[corner]
    for L in size_order
        push!(panelsA, _col_label("L = $L"))
    end
    push!(panelsA, _blank_panel())
    for frame in size_frames
        push!(panelsA, _size_tile(frame))
    end
    tile_w = (1.0 - 0.06) / 3
    pA = plot(panelsA...;
        layout = grid(2, 4; widths = [0.06, tile_w, tile_w, tile_w], heights = [0.14, 0.86]))

    # ── B: conversion probability vs f, thinned to the strip's three sizes ──
    # The stage that moves with system size is sweeping, not nucleating.
    # Direct end-labels (in each curve's own color) replace the legend box
    # that panel A used to carry when it plotted all five sizes; with only
    # three curves left, and all three saturating to a conversion fraction of
    # 1 by f ≈ 0.155-0.16 (so their right ends coincide), the labels are
    # staggered vertically in a fixed L-ascending order rather than placed
    # exactly on the (overlapping) data points.
    pB = plot(; xlabel = "Minority fraction f", ylabel = "Fraction of seeds converting",
              legend = false, xlims = (minimum(FS) - 0.012, maximum(FS) + 0.05),
              ylims = (-0.05, 1.12), _panel_kw...)
    end_dodge = Dict(64 => 0.0, 128 => -0.10, 512 => -0.20)
    for L in size_order
        ps, los, his = Float64[], Float64[], Float64[]
        for f in FS
            s = survey[(survey.L .== L) .& (survey.f .== f), :]
            k, n = sum(s.conv_observed), nrow(s)
            lo, hi = wilson(k, n)
            push!(ps, k / n); push!(los, k / n - lo); push!(his, hi - k / n)
        end
        plot!(pB, FS, ps, yerror = (los, his), color = Lcolor[L], lw = 1.6,
              marker = :circle, ms = 3, msc = Lcolor[L], label = "")
        annotate!(pB, maximum(FS) + 0.008, ps[end] + end_dodge[L],
                  text("L = $L", 8, Lcolor[L], :left))
    end
    # Large sell clusters appear at every f and every size, including where
    # nothing converts, so what moves with L is sweeping rather than clustering.
    # This is a descriptive 100-cell threshold, NOT a certified critical
    # nucleus: the mixed state throws up 30-60 cell fluctuations on its own and
    # the largest chance cluster grows with the number of sites.
    nuc_all = [mean(survey[survey.f .== f, :nuc_observed]) for f in FS]
    plot!(pB, FS, nuc_all, color = :black, ls = :dot, lw = 1.5, label = "")
    _panel_letter!(pB, "B")

    # ── C: every market size and every f fall on one curve (former panel D,
    # verbatim) ──────────────────────────────────────────────────────────────
    # Rescaling time by each run's own fitted K collapses all 320 runs onto
    # 1 − exp(−u^n). The collapse across colors is the size-independence claim,
    # shown as a curve rather than as a column of indistinguishable constants.
    trajs = CSV.read(joinpath(_PATH_TO_DATA, "ModelA-AvramiTrajectories.csv"), DataFrame)
    # Quote the exponent at the largest lattice, where the per-run fits have
    # converged (R² ≈ 0.999 and the seed spread has collapsed); at L = 64 a
    # single sweeping domain is not a KJMA process and the fit is poor.
    n_big = mean(avrami[avrami.L .== maximum(av_ls), :avrami_n])
    pC = plot(; xlabel = "Rescaled time Kt", ylabel = "Converted fraction",
              legend = :bottomright, xlims = (0, 2.2), ylims = (-0.02, 1.02),
              _panel_kw...)
    fitkey = Dict((r.L, r.f, r.seed) => (r.avrami_K, r.baseline) for r in eachrow(avrami))
    drawn = Set{Int}()
    for g in groupby(trajs, [:L, :f, :seed])
        key = (g.L[1], g.f[1], g.seed[1])
        haskey(fitkey, key) || continue
        K, base = fitkey[key]
        u = K .* g.t
        X = (g.sell_fraction .- base) ./ (1 - base)
        c = Lcolor[g.L[1]]
        lbl = g.L[1] in drawn ? "" : "L = $(g.L[1])"
        push!(drawn, g.L[1])
        plot!(pC, u, X, color = c, lw = 0.5, alpha = 0.25, label = lbl)
    end
    uu = range(0.01, 2.2; length = 300)
    plot!(pC, uu, 1 .- exp.(-uu .^ n_big), color = :black, ls = :dash, lw = 2,
          label = @sprintf("1 − exp(−u^%.2f)", n_big))
    _panel_letter!(pC, "C")

    @info "Fig-ModelA-FiniteSize strip panel" tstar = tstar seeds = strips["seeds"]

    fig = plot(pA, pB, pC; layout = @layout([a{0.34h}; b c]), size = (1000, 900))
    _save_figure(fig, "Fig-ModelA-FiniteSize.pdf")
end

# ─────────────────────────────────────────────────────────────────────────
# 2) FigS7-FiniteSizeDetail.pdf — former panels B (dispersion collapse) and
#    C (conversion-time saturation), verbatim, letters A/B.
# ─────────────────────────────────────────────────────────────────────────
let
    fs_summ = CSV.read(joinpath(_PATH_TO_DATA, "ModelA-FiniteSizeSummary.csv"), DataFrame)

    # ── Assert the cited values before plotting anything ───────────────────
    s20 = fs_summ[fs_summ.f .== 0.20, :]
    for L in unique(s20.L)
        @assert count(==(L), s20.L) == 1 "expected exactly one (L, f=0.20) row in the finite-size summary"
    end
    cov_by_L = Dict(row.L => row.cv_t_conv for row in eachrow(s20))
    cov_32, cov_512 = cov_by_L[32], cov_by_L[512]

    @assert isapprox(cov_32,  0.66;  atol = 0.02) "CoV at 32x32 does not reproduce"
    @assert isapprox(cov_512, 0.035; atol = 0.005) "CoV at 512x512 does not reproduce"

    f_disp = [f for f in FS if f >= 0.155]
    # Minority-fraction ramp for the dispersion/timing panels (also an ordered
    # variable): single-hue sequential magenta (ColorBrewer "PuRd", 9-class,
    # keeping only classes 5-9 for the same background-contrast reason as the
    # L-ramp in the main figure — the 5-class version's #f1eef6 sits 6 RGB
    # units from the house background). A different hue family from the
    # L-ramp, and, like it, clear of the reserved Buy/Hold/Sell/Edge hues.
    disp_colors = ["#df65b0", "#e7298a", "#ce1256", "#980043", "#67001f"]

    # ── A (former B): dispersion collapse ───────────────────────────────────
    # Uncensored cells only, so no horizon-pinned value enters a variance.
    pA = plot(; xlabel = "Lattice size L", ylabel = "Coefficient of variation",
              xscale = :log10, yscale = :log10, legend = :bottomleft,
              xticks = (LS, string.(LS)), _panel_kw...)
    for (i, f) in enumerate(f_disp)
        xs, ys = Float64[], Float64[]
        for L in LS
            s = survey[(survey.L .== L) .& (survey.f .== f), :]
            all(s.conv_observed) || continue
            push!(xs, L); push!(ys, std(s.t_conv) / mean(s.t_conv))
        end
        length(xs) >= 2 || continue
        c = disp_colors[mod1(i, length(disp_colors))]
        plot!(pA, xs, ys, color = c, lw = 1.6,
              marker = :circle, ms = 3, msc = c, label = "f = $f")
    end
    # Self-averaging reference: CV ∝ N^(-1/2) = L^(-1), anchored at L = 32.
    Lref = range(minimum(LS), maximum(LS); length = 50)
    plot!(pA, Lref, 0.70 .* (Lref ./ 32) .^ (-1.0), color = :black, ls = :dash,
          lw = 1.5, label = "CV ∝ N^(-1/2)")
    _panel_letter!(pA, "A")

    # ── B (former C): conversion-time saturation ────────────────────────────
    pB = plot(; xlabel = "Lattice size L", ylabel = "Median conversion time (steps)",
              xscale = :log10, yscale = :log10, legend = :topright,
              xticks = (LS, string.(LS)), _panel_kw...)
    for (i, f) in enumerate(f_disp)
        xs, ys = Float64[], Float64[]
        for L in LS
            s = survey[(survey.L .== L) .& (survey.f .== f), :]
            all(s.conv_observed) || continue
            push!(xs, L); push!(ys, median(s.t_conv))
        end
        length(xs) >= 2 || continue
        c = disp_colors[mod1(i, length(disp_colors))]
        plot!(pB, xs, ys, color = c, lw = 1.6,
              marker = :circle, ms = 3, msc = c, label = "f = $f")
    end
    _panel_letter!(pB, "B")

    figS7 = plot(pA, pB; layout = (1, 2), size = (1000, 420))
    _save_figure(figS7, "FigS7-FiniteSizeDetail.pdf")
end
