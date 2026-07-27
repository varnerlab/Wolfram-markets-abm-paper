# Figs-ModelA-FiniteSize.jl — system-size scaling of the sell-state escape,
# drawn ENTIRELY from the committed CSVs (no simulation):
#   code/data/ModelA-FiniteSizeScaling.csv   (survey pass)
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
    survey = CSV.read(joinpath(_PATH_TO_DATA, "ModelA-FiniteSizeScaling.csv"), DataFrame)
    avrami = CSV.read(joinpath(_PATH_TO_DATA, "ModelA-AvramiFits.csv"), DataFrame)

    LS = sort(unique(survey.L))
    FS = sort(unique(survey.f))

    # Size ramp: cool (small) to warm (large), colorblind-safe endpoints.
    size_colors = ["#0072B2", "#56B4E9", "#999999", "#E69F00", "#D55E00"]
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
    pA = plot(title = "A  conversion probability", titlefont = 10,
              xlabel = "minority fraction f", ylabel = "P(convert within horizon)",
              guidefont = 8, tickfont = 7, legend = :bottomright, legendfontsize = 6,
              ylims = (-0.05, 1.08))
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

    # ── B: dispersion collapse ─────────────────────────────────────────────
    # Uncensored cells only, so no horizon-pinned value enters a variance.
    pB = plot(title = "B  dispersion collapse", titlefont = 10,
              xlabel = "lattice size L", ylabel = "CV of conversion time",
              xscale = :log10, yscale = :log10, guidefont = 8, tickfont = 7,
              legend = :bottomleft, legendfontsize = 6,
              xticks = (LS, string.(LS)))
    f_disp = [f for f in FS if f >= 0.155]
    disp_colors = ["#0072B2", "#56B4E9", "#009E73", "#E69F00", "#D55E00", "#CC79A7"]
    for (i, f) in enumerate(f_disp)
        xs, ys = Float64[], Float64[]
        for L in LS
            s = survey[(survey.L .== L) .& (survey.f .== f), :]
            all(s.conv_observed) || continue
            push!(xs, L); push!(ys, std(s.t_conv) / mean(s.t_conv))
        end
        length(xs) >= 2 || continue
        plot!(pB, xs, ys, color = disp_colors[mod1(i, length(disp_colors))], lw = 1.6,
              marker = :circle, ms = 3, label = "f = $f")
    end
    # Self-averaging reference: CV ∝ N^(-1/2) = L^(-1), anchored at L = 32.
    Lref = range(minimum(LS), maximum(LS); length = 50)
    plot!(pB, Lref, 0.70 .* (Lref ./ 32) .^ (-1.0), color = :black, ls = :dash,
          lw = 1.5, label = "CV ∝ N^(-1/2)")

    # ── C: conversion-time saturation ──────────────────────────────────────
    pC = plot(title = "C  conversion time saturates", titlefont = 10,
              xlabel = "lattice size L", ylabel = "median conversion time (steps)",
              xscale = :log10, yscale = :log10, guidefont = 8, tickfont = 7,
              legend = :topright, legendfontsize = 6,
              xticks = (LS, string.(LS)))
    for (i, f) in enumerate(f_disp)
        xs, ys = Float64[], Float64[]
        for L in LS
            s = survey[(survey.L .== L) .& (survey.f .== f), :]
            all(s.conv_observed) || continue
            push!(xs, L); push!(ys, median(s.t_conv))
        end
        length(xs) >= 2 || continue
        plot!(pC, xs, ys, color = disp_colors[mod1(i, length(disp_colors))], lw = 1.6,
              marker = :circle, ms = 3, label = "f = $f")
    end

    # ── D: the Avrami rate constant is intensive ───────────────────────────
    # K ∝ (I v²)^(1/3) with I the per-site nucleation rate. A flat K against L
    # means the rate is extensive in area, measured without any cluster-size
    # criterion — the transformation curve reads only the sell fraction.
    av_ls = sort(unique(avrami.L))
    av_fs = sort(unique(avrami.f))
    # Quote the exponent at the largest lattice, where the per-run fits have
    # converged (R² ≈ 0.999 and the seed spread has collapsed); at L = 64 a
    # single sweeping domain is not a KJMA process and the fit is poor.
    n_big = mean(avrami[avrami.L .== maximum(av_ls), :avrami_n])
    pD = plot(title = @sprintf("D  Avrami rate constant (n = %.2f at L = %d)",
                               n_big, maximum(av_ls)),
              titlefont = 10, xlabel = "lattice size L", ylabel = "rate constant K",
              xscale = :log10, yscale = :log10, guidefont = 8, tickfont = 7,
              legend = :topright, legendfontsize = 6,
              xticks = (av_ls, string.(av_ls)))
    for (i, f) in enumerate(av_fs)
        xs, ys, es = Float64[], Float64[], Float64[]
        for L in av_ls
            s = avrami[(avrami.L .== L) .& (avrami.f .== f), :]
            nrow(s) >= 2 || continue
            push!(xs, L); push!(ys, mean(s.avrami_K))
            push!(es, std(s.avrami_K) / sqrt(nrow(s)))
        end
        length(xs) >= 2 || continue
        c = disp_colors[mod1(i, length(disp_colors))]
        plot!(pD, xs, ys, yerror = es, color = c, lw = 1.6, marker = :circle,
              ms = 3, msc = c, label = "f = $f")
        # Flat reference anchored at the smallest size drawn for this f.
        plot!(pD, [xs[1], xs[end]], [ys[1], ys[1]], color = c, ls = :dash,
              lw = 1.0, label = "")
    end

    fig = plot(pA, pB, pC, pD; layout = (2, 2), size = (900, 700),
               left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
    _save_figure(fig, "Fig-ModelA-FiniteSize.pdf")
end
