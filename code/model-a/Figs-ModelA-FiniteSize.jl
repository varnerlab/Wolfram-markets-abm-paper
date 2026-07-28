# Figs-ModelA-FiniteSize.jl — system-size scaling of the sell-state escape,
# drawn ENTIRELY from the committed CSVs (no simulation):
#   code/data/ModelA-FiniteSizeScaling.csv   (survey pass, per-seed)
#   code/data/ModelA-FiniteSizeSummary.csv   (survey pass, cv_t_conv — cited assertions)
#   code/data/ModelA-AvramiFits.csv          (Avrami pass)
# Standalone-rerunnable from the repo root:
#   julia code/model-a/Figs-ModelA-FiniteSize.jl
#
# Writes: code/figs/ + paper-arxiv/figs/
#
# Body is a `let` block (locals only) so it can be included after a sweep
# without global-constant collisions.

isdefined(Main, :_PATH_TO_DATA) || include(joinpath(@__DIR__, "Include.jl"))
using Printf

let
    survey  = CSV.read(joinpath(_PATH_TO_DATA, "ModelA-FiniteSizeScaling.csv"), DataFrame)
    fs_summ = CSV.read(joinpath(_PATH_TO_DATA, "ModelA-FiniteSizeSummary.csv"), DataFrame)
    avrami  = CSV.read(joinpath(_PATH_TO_DATA, "ModelA-AvramiFits.csv"), DataFrame)

    LS    = sort(unique(survey.L))
    FS    = sort(unique(survey.f))
    av_ls = sort(unique(avrami.L))   # Avrami fits exist only for L = 64-512; no L = 32 row.

    # ── Assert the cited values before plotting anything ───────────────────
    s20 = fs_summ[fs_summ.f .== 0.20, :]
    for L in unique(s20.L)
        @assert count(==(L), s20.L) == 1 "expected exactly one (L, f=0.20) row in the finite-size summary"
    end
    cov_by_L = Dict(row.L => row.cv_t_conv for row in eachrow(s20))
    cov_32, cov_512 = cov_by_L[32], cov_by_L[512]

    # Paper_v1.tex:1119-1120 quotes n "on the largest lattice," not pooled over
    # all four — filter to L = maximum(av_ls) first, the same lattice panel D's
    # n_big uses below, so the assertion checks the fit the paper actually cites.
    n_f016 = mean(avrami[(avrami.L .== maximum(av_ls)) .& (avrami.f .== 0.16), :avrami_n])
    n_f020 = mean(avrami[(avrami.L .== maximum(av_ls)) .& (avrami.f .== 0.20), :avrami_n])

    inv_K_f018 = [1 / mean(avrami[(avrami.L .== L) .& (avrami.f .== 0.18), :avrami_K]) for L in av_ls]

    @assert isapprox(cov_32,  0.66;  atol = 0.02) "CoV at 32x32 does not reproduce"
    @assert isapprox(cov_512, 0.035; atol = 0.005) "CoV at 512x512 does not reproduce"
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

    # ── A: conversion probability vs f, one curve per L ────────────────────
    # The stage that moves with system size is sweeping, not nucleating.
    pA = plot(; xlabel = "Minority fraction f", ylabel = "Fraction of seeds converting",
              legend = :bottomright, ylims = (-0.05, 1.08), _panel_kw...)
    for L in LS
        ps, los, his = Float64[], Float64[], Float64[]
        for f in FS
            s = survey[(survey.L .== L) .& (survey.f .== f), :]
            k, n = sum(s.conv_observed), nrow(s)
            lo, hi = wilson(k, n)
            push!(ps, k / n); push!(los, k / n - lo); push!(his, hi - k / n)
        end
        plot!(pA, FS, ps, yerror = (los, his), color = Lcolor[L], lw = 1.6,
              marker = :circle, ms = 3, msc = Lcolor[L], label = "L = $L")
    end
    # Large sell clusters appear at every f and every size, including where
    # nothing converts, so what moves with L is sweeping rather than clustering.
    # This is a descriptive 100-cell threshold, NOT a certified critical
    # nucleus: the mixed state throws up 30-60 cell fluctuations on its own and
    # the largest chance cluster grows with the number of sites.
    nuc_all = [mean(survey[survey.f .== f, :nuc_observed]) for f in FS]
    plot!(pA, FS, nuc_all, color = :black, ls = :dot, lw = 1.5,
          label = "≥100-cell cluster seen")
    _panel_letter!(pA, "A")

    # ── B: dispersion collapse ─────────────────────────────────────────────
    # Uncensored cells only, so no horizon-pinned value enters a variance.
    pB = plot(; xlabel = "Lattice size L", ylabel = "Coefficient of variation",
              xscale = :log10, yscale = :log10, legend = :bottomleft,
              xticks = (LS, string.(LS)), _panel_kw...)
    f_disp = [f for f in FS if f >= 0.155]
    # Minority-fraction ramp for the dispersion/timing panels (also an ordered
    # variable): single-hue sequential magenta (ColorBrewer "PuRd", 9-class,
    # keeping only classes 5-9 for the same background-contrast reason as the
    # L-ramp above — the 5-class version's #f1eef6 sits 6 RGB units from the
    # house background). A different hue family from the L-ramp, and, like
    # it, clear of the reserved Buy/Hold/Sell/Edge hues.
    disp_colors = ["#df65b0", "#e7298a", "#ce1256", "#980043", "#67001f"]
    for (i, f) in enumerate(f_disp)
        xs, ys = Float64[], Float64[]
        for L in LS
            s = survey[(survey.L .== L) .& (survey.f .== f), :]
            all(s.conv_observed) || continue
            push!(xs, L); push!(ys, std(s.t_conv) / mean(s.t_conv))
        end
        length(xs) >= 2 || continue
        c = disp_colors[mod1(i, length(disp_colors))]
        plot!(pB, xs, ys, color = c, lw = 1.6,
              marker = :circle, ms = 3, msc = c, label = "f = $f")
    end
    # Self-averaging reference: CV ∝ N^(-1/2) = L^(-1), anchored at L = 32.
    Lref = range(minimum(LS), maximum(LS); length = 50)
    plot!(pB, Lref, 0.70 .* (Lref ./ 32) .^ (-1.0), color = :black, ls = :dash,
          lw = 1.5, label = "CV ∝ N^(-1/2)")
    _panel_letter!(pB, "B")

    # ── C: conversion-time saturation ──────────────────────────────────────
    pC = plot(; xlabel = "Lattice size L", ylabel = "Median conversion time (steps)",
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
        plot!(pC, xs, ys, color = c, lw = 1.6,
              marker = :circle, ms = 3, msc = c, label = "f = $f")
    end
    _panel_letter!(pC, "C")

    # ── D: every market size and every f fall on one curve ─────────────────
    # Rescaling time by each run's own fitted K collapses all 320 runs onto
    # 1 − exp(−u^n). The collapse across colors is the size-independence claim,
    # shown as a curve rather than as a column of indistinguishable constants.
    trajs  = CSV.read(joinpath(_PATH_TO_DATA, "ModelA-AvramiTrajectories.csv"), DataFrame)
    # Quote the exponent at the largest lattice, where the per-run fits have
    # converged (R² ≈ 0.999 and the seed spread has collapsed); at L = 64 a
    # single sweeping domain is not a KJMA process and the fit is poor.
    n_big  = mean(avrami[avrami.L .== maximum(av_ls), :avrami_n])
    pD = plot(; xlabel = "Rescaled time Kt", ylabel = "Converted fraction",
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
        plot!(pD, u, X, color = c, lw = 0.5, alpha = 0.25, label = lbl)
    end
    uu = range(0.01, 2.2; length = 300)
    plot!(pD, uu, 1 .- exp.(-uu .^ n_big), color = :black, ls = :dash, lw = 2,
          label = @sprintf("1 − exp(−u^%.2f)", n_big))
    _panel_letter!(pD, "D")

    fig = plot(pA, pB, pC, pD; layout = (2, 2), size = (1000, 800))
    _save_figure(fig, "Fig-ModelA-FiniteSize.pdf")
end
