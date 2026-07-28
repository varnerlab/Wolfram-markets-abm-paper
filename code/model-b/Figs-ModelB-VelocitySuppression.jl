# Figs-ModelB-VelocitySuppression.jl — the A2 dose-response figure, drawn
# ENTIRELY from code/data/ModelB-Nucleation-EscapeTime.csv (no simulation).
# Standalone-rerunnable from the repo root:
#   julia code/model-b/Figs-ModelB-VelocitySuppression.jl
#
# Writes: code/figs/ + paper-arxiv/figs/
#
# Suppression is ABSOLUTE (suppressed buy orders/step, unnormalized) — the
# per-panel-scaling flaw this analysis exists to fix. Spearman ρ and the
# +1-corrected permutation p are recomputed here from the CSV via the lib
# (fixed rng ⇒ same numbers as the compute log).
#
# The A2 window (`a2_subset`) and the cash ramp (`CASH_RAMP` /
# `cash_color_map`) now live in EscapeTime-Lib.jl, shared with
# Figs-ModelB-BarrierLaw.jl (Fig6-GrowthGating.pdf's panels C/D use this same
# subset and the same colours per dose) — see that file's header for the
# ownership ruling. This script still emits its own current figure
# (`ModelB-Nucleation-VelocitySuppression.pdf`) unchanged in shape; only the
# subset/colour SOURCE moved, plus the reserved-state-hue palette below,
# which had to go regardless of which figure reads it.

isdefined(Main, :_PATH_TO_DATA)    || include(joinpath(@__DIR__, "Include.jl"))
isdefined(Main, :spearman_perm_p)  || include(joinpath(@__DIR__, "EscapeTime-Lib.jl"))

let
    df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime.csv"), DataFrame)
    a2, n_excluded = a2_subset(df)

    # Cash is ORDINAL (a budget dose), not five independent categories, so it
    # takes a sequential ramp rather than the three reserved state hues this
    # palette used to encode it with (`#009E73` = _EDGE_COLOR, `_BUY_COLOR`,
    # `_SELL_COLOR` — Tasks 5-7 established that non-state quantities must not
    # wear reserved state hues). See EscapeTime-Lib.jl's `CASH_RAMP` docstring
    # for the measured background-contrast numbers.
    cashes = sort(unique(a2.cash))
    cash_color = cash_color_map(cashes, cashes)

    sp = spearman_perm_p(collect(Float64.(a2.suppb_w)), collect(Float64.(a2.v_front)))

    p1 = plot(title = "Spearman ρ = $(round(sp.rho, digits = 3)), permutation p = $(round(sp.p, digits = 4)) (n = $(nrow(a2)), excl. $(n_excluded))",
              titlefont = 9, xlabel = "suppressed buy orders / step (absolute)",
              ylabel = "front velocity × 1e4 (fraction/step)",
              guidefont = 8, tickfont = 7, legend = :topright, legendfontsize = 6)
    for cash in cashes
        s = a2[a2.cash .== cash, :]
        scatter!(p1, s.suppb_w, s.v_front .* 1e4, color = cash_color[cash],
                 markersize = 4, markerstrokewidth = 0.3, alpha = 0.75,
                 label = "cash $(Int(cash)) (n=$(nrow(s)))")
        scatter!(p1, [median(s.suppb_w)], [median(s.v_front) * 1e4],
                 color = cash_color[cash], marker = :diamond, markersize = 9,
                 markerstrokewidth = 1.2, markerstrokecolor = :black, label = "")
    end

    p2 = plot(title = "velocity by budget dose", titlefont = 10,
              xlabel = "initial cash", ylabel = "front velocity × 1e4",
              xscale = :log10, guidefont = 8, tickfont = 7, legend = false)
    for cash in cashes
        s = a2[a2.cash .== cash, :]
        scatter!(p2, fill(cash, nrow(s)), s.v_front .* 1e4,
                 color = cash_color[cash], markersize = 4, markerstrokewidth = 0.3,
                 alpha = 0.75)
        plot!(p2, [cash / 1.25, cash * 1.25], fill(median(s.v_front) * 1e4, 2),
              color = :black, lw = 2.0)
    end

    fig = plot(p1, p2; layout = (1, 2), size = (1150, 520),
               left_margin = 6Plots.mm, bottom_margin = 5Plots.mm,
               plot_title = "Front velocity vs absolute budget suppression (f = 0.20, window [t_on+50, t_on+400])",
               plot_titlefontsize = 11)
    _save_figure(fig, "ModelB-Nucleation-VelocitySuppression.pdf")
    @info "Saved: ModelB-Nucleation-VelocitySuppression.pdf"
end
