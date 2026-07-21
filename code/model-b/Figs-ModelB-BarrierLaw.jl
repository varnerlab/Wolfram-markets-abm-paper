# Figs-ModelB-BarrierLaw.jl — the A1 headline figure, drawn ENTIRELY from the
# committed CSVs (no simulation):
#   code/data/ModelB-Nucleation-EscapeTime.csv
#   code/data/ModelB-Nucleation-EscapeTime-Fits.csv
# Standalone-rerunnable from the repo root:
#   julia code/model-b/Figs-ModelB-BarrierLaw.jl
#
# Writes: code/figs/ + paper-arxiv/figs/
#
# Body is a `let` block (locals only) so it can be included after a sweep
# without global-constant collisions.

isdefined(Main, :_PATH_TO_DATA)   || include(joinpath(@__DIR__, "Include.jl"))
isdefined(Main, :censored_median) || include(joinpath(@__DIR__, "EscapeTime-Lib.jl"))

let
    df   = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime.csv"), DataFrame)
    fits = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime-Fits.csv"), DataFrame)

    a1     = df[df.stage .!= "a2x", :]
    cashes = sort(unique(a1.cash))
    # tight → freeze blue, mid → orange, loose → collapse red (house palette)
    base_colors = [_BUY_COLOR, "#E69F00", _SELL_COLOR, "#009E73", "#CC79A7"]
    cash_color  = Dict(c => base_colors[i] for (i, c) in enumerate(cashes))

    # Model A reference: ln τ = 2.78 + 0.389/(f − 0.101), R² = 0.991 (Sec 5.6)
    A_REF, B_REF, F0_REF = 2.78, 0.389, 0.101
    # Display ceiling for curve drawing only (~15x the 2000-step horizon) — not
    # an analysis quantity; keeps the diverging Kramers curves from stretching
    # the log axis across 15 decades and crushing the data medians.
    TAU_MAX = 3.0e4

    p_tau = plot(title = "median onset time", titlefont = 10, xlabel = "f",
                 ylabel = "median t_on (steps)", yscale = :log10,
                 guidefont = 8, tickfont = 7, legend = :topright, legendfontsize = 6,
                 ylims = (50, TAU_MAX))
    fref = range(F0_REF + B_REF / (log(TAU_MAX) - A_REF), maximum(a1.f); length = 400)
    plot!(p_tau, fref, exp.(A_REF .+ B_REF ./ (fref .- F0_REF)),
          color = :black, ls = :dash, lw = 1.5, label = "Model A fit")

    p_rate = plot(title = "onset rate by horizon t = max step", titlefont = 10,
                  xlabel = "f", ylabel = "fraction of seeds with onset",
                  ylims = (0, 1.05), guidefont = 8, tickfont = 7,
                  legend = :bottomright, legendfontsize = 6)

    for cash in cashes
        sub   = a1[a1.cash .== cash, :]
        fvals = sort(unique(sub.f))
        meds  = [censored_median(Int.(sub.t_on[sub.f .== f])) for f in fvals]
        onr   = [mean(sub.t_on[sub.f .== f] .> 0) for f in fvals]
        ok    = .!isnan.(meds)
        lbl   = "cash $(Int(cash))"
        scatter!(p_tau, fvals[ok], meds[ok], color = cash_color[cash],
                 markersize = 5, markerstrokewidth = 0.5, label = lbl)
        plot!(p_rate, fvals, onr, color = cash_color[cash], lw = 1.6,
              marker = :circle, markersize = 3, markerstrokewidth = 0, label = lbl)
        fr = fits[fits.cash .== cash, :]
        if nrow(fr) == 1 && !isnan(fr.f0[1])
            fstart = fr.f0[1] + fr.B[1] / (log(TAU_MAX) - fr.A[1])
            fc = range(min(fstart, maximum(fvals[ok]) - 1e-4), maximum(fvals[ok]); length = 400)
            plot!(p_tau, fc, exp.(fr.A[1] .+ fr.B[1] ./ (fc .- fr.f0[1])),
                  color = cash_color[cash], lw = 1.6, label = "")
        end
    end

    # Fitted parameters with bootstrap CIs (skip NaN rows; if EVERY fit was
    # skipped — criterion-1 failure / heavy censoring — the panels stay empty
    # and panel b carries the story, per the spec's surprise handling)
    fok = fits[.!isnan.(fits.f0), :]
    xs  = collect(1:max(nrow(fok), 1))
    p_f0 = plot(title = "fitted f0 (divergence)", titlefont = 10,
                xlabel = "initial cash", ylabel = "f0",
                guidefont = 8, tickfont = 7, legend = false,
                xlims = (0.5, max(nrow(fok), 1) + 0.5))
    p_B = plot(title = "fitted barrier coefficient B", titlefont = 10,
               xlabel = "initial cash", ylabel = "B",
               guidefont = 8, tickfont = 7, legend = false,
               xlims = (0.5, max(nrow(fok), 1) + 0.5))
    if nrow(fok) > 0
        plot!(p_f0, xticks = (xs, string.(Int.(fok.cash))))
        scatter!(p_f0, xs, fok.f0,
                 yerror = (fok.f0 .- fok.f0_lo, fok.f0_hi .- fok.f0),
                 color = [cash_color[c] for c in fok.cash], markersize = 6,
                 markerstrokewidth = 0.5)
        hline!(p_f0, [F0_REF], color = :black, ls = :dash, lw = 1.0)
        plot!(p_B, xticks = (xs, string.(Int.(fok.cash))))
        scatter!(p_B, xs, fok.B, yerror = (fok.B .- fok.B_lo, fok.B_hi .- fok.B),
                 color = [cash_color[c] for c in fok.cash], markersize = 6,
                 markerstrokewidth = 0.5)
        hline!(p_B, [B_REF], color = :black, ls = :dash, lw = 1.0)
    end

    fig = plot(p_tau, p_rate, p_f0, p_B; layout = (2, 2), size = (1150, 950),
               left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
               plot_title = "Escape-time barrier law under budgets (dashed: Model A reference)",
               plot_titlefontsize = 11)
    _save_figure(fig, "ModelB-Nucleation-BarrierLaw.pdf")
    @info "Saved: ModelB-Nucleation-BarrierLaw.pdf"
end
