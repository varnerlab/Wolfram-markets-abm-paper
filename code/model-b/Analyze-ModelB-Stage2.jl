# Analyze-ModelB-Stage2.jl — Stage 2 analysis (spec 2026-07-16 stage2)
#
# Reads ONLY the summary table (+ exemplar JLD2s); never re-simulates.
# The 6-knob response surface is viewed through three projections:
#   1. marginal effects (metric vs one knob, averaged over everything else)
#   2. pairwise heatmap contact sheet (all 15 knob pairs)
#   3. λ×f regime map faceted by disposition, plus per-regime exemplars
# plus a variance-decomposition table ranking knobs and pairs.

include(joinpath(@__DIR__, "Include.jl"))

df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Stage2-Summary.csv"), DataFrame)
@info "Loaded summary" rows = nrow(df)

const KNOBS            = [:lambda, :k, :f, :spread, :disposition, :cash]
const METRICS_MARGINAL = [:crash_frequency, :return_kurtosis,
                          :phi_zero_crossings, :return_std]
const PAIR_METRIC      = :crash_frequency
const REGIME_ORDER     = ["inert", "plateau", "drift", "oscillatory", "crash_prone"]

_nanmean(v) = (w = filter(!isnan, v); isempty(w) ? NaN : mean(w))
_nanstd(v)  = (w = filter(!isnan, v); length(w) < 2 ? 0.0 : std(w))

# ---------------------------------------------------------------------------
# 1. Marginal effects: metrics × knobs grid, mean ± std over everything else
# ---------------------------------------------------------------------------
function _marginal_panel(df, metric, knob)
    levels = sort(unique(df[!, knob]))
    xs = 1:length(levels)
    ys = [_nanmean(df[df[!, knob] .== l, metric]) for l in levels]
    es = [_nanstd(df[df[!, knob] .== l, metric]) for l in levels]
    plot(xs, ys, yerror = es, marker = :circle, legend = false,
         xticks = (xs, string.(levels)), xlabel = String(knob),
         ylabel = String(metric), guidefont = 7, tickfont = 6)
end

panels = [_marginal_panel(df, m, k) for m in METRICS_MARGINAL for k in KNOBS]
fig1 = plot(panels...; layout = (length(METRICS_MARGINAL), length(KNOBS)),
            size = (1800, 1100), left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
savefig(fig1, joinpath(_PATH_TO_FIGS, "ModelB-Stage2-Marginals.pdf"))
@info "Saved: ModelB-Stage2-Marginals.pdf"

# ---------------------------------------------------------------------------
# 2. Pairwise contact sheet for the headline metric (all 15 knob pairs)
# ---------------------------------------------------------------------------
function _pair_heatmap(df, metric, a, b)
    la = sort(unique(df[!, a]))
    lb = sort(unique(df[!, b]))
    M  = [_nanmean(df[(df[!, a] .== x) .& (df[!, b] .== y), metric])
          for y in lb, x in la]
    heatmap(string.(la), string.(lb), M, xlabel = String(a), ylabel = String(b),
            title = String(metric), titlefont = 8, guidefont = 7, tickfont = 6,
            colorbar = true)
end

pairs = [(KNOBS[i], KNOBS[j]) for i in 1:length(KNOBS) for j in i+1:length(KNOBS)]
sheets = [_pair_heatmap(df, PAIR_METRIC, a, b) for (a, b) in pairs]
# NOTE: length(KNOBS) == 6 → C(6,2) == 15 pairs, not the 10 the brief's
# hardcoded layout=(5,2) assumed (that count matches C(5,2), i.e. KNOBS
# minus :disposition). Grid sized dynamically from the actual pair count
# so every pair renders; no pair or knob is dropped from the sheet.
_pair_ncols = 3
_pair_nrows = cld(length(pairs), _pair_ncols)
fig2 = plot(sheets...; layout = (_pair_nrows, _pair_ncols),
            size = (500 * _pair_ncols, 360 * _pair_nrows),
            left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
savefig(fig2, joinpath(_PATH_TO_FIGS, "ModelB-Stage2-PairSheet.pdf"))
@info "Saved: ModelB-Stage2-PairSheet.pdf"

# ---------------------------------------------------------------------------
# 3. Regime map: modal regime per (λ, f) cell, faceted by disposition
# ---------------------------------------------------------------------------
function _mode_regime(v)::String
    counts = Dict{String,Int}()
    for r in v
        counts[r] = get(counts, r, 0) + 1
    end
    return sort(collect(counts); by = x -> (-x[2], x[1]))[1][1]
end

regime_code = Dict(r => i for (i, r) in enumerate(REGIME_ORDER))
facets = map([true, false]) do dispo
    d  = df[df.disposition .== dispo, :]
    ls = sort(unique(d.lambda))
    fs = sort(unique(d.f))
    M  = [Float64(regime_code[_mode_regime(
              d[(d.lambda .== l) .& (d.f .== f), :regime])])
          for f in fs, l in ls]
    h = heatmap(string.(ls), string.(fs), M, xlabel = "lambda", ylabel = "f",
                clims = (1, length(REGIME_ORDER)), colorbar = false,
                title = "disposition = $(dispo)", titlefont = 9)
    # categorical axes center cells on integer indices 1..n
    for (yi, f) in enumerate(fs), (xi, l) in enumerate(ls)
        annotate!(h, xi, yi,
                  text(uppercase(first(REGIME_ORDER[Int(M[yi, xi])])), 7, :white))
    end
    h
end
fig3 = plot(facets...; layout = (1, 2), size = (1100, 450),
            plot_title = "Modal regime (" * join(REGIME_ORDER, ", ") * ")")
savefig(fig3, joinpath(_PATH_TO_FIGS, "ModelB-Stage2-RegimeMap.pdf"))
@info "Saved: ModelB-Stage2-RegimeMap.pdf"

# ---------------------------------------------------------------------------
# 4. Variance decomposition: knob and pair fractions per metric
# ---------------------------------------------------------------------------
function _variance_rows(df, metric, knobs)
    v0   = df[!, metric]
    keep = .!isnan.(v0)
    d    = df[keep, :]
    count(keep) < nrow(df) &&
        @warn "variance decomposition: NaN filter dropped rows — grid unbalanced, pair terms approximate" metric dropped = nrow(df) - count(keep)
    v    = d[!, metric]
    μ    = mean(v)
    ss_total = sum((v .- μ) .^ 2)
    ss_total == 0 && return NamedTuple[]
    rows    = NamedTuple[]
    ss_main = Dict{Symbol,Float64}()
    for knob in knobs
        ss = 0.0
        for g in groupby(d, knob)
            ss += nrow(g) * (mean(g[!, metric]) - μ)^2
        end
        ss_main[knob] = ss
        push!(rows, (metric = String(metric), term = String(knob),
                     frac = ss / ss_total))
    end
    for i in 1:length(knobs), j in i+1:length(knobs)
        a, b = knobs[i], knobs[j]
        ss = 0.0
        for g in groupby(d, [a, b])
            ss += nrow(g) * (mean(g[!, metric]) - μ)^2
        end
        push!(rows, (metric = String(metric), term = "$(a)x$(b)",
                     frac = (ss - ss_main[a] - ss_main[b]) / ss_total))
    end
    return rows
end

var_rows = reduce(vcat, [_variance_rows(df, m, KNOBS) for m in METRICS_MARGINAL])
vt = sort(DataFrame(var_rows), [:metric, order(:frac, rev = true)])
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Stage2-VarianceDecomposition.csv"), vt)
for m in METRICS_MARGINAL
    top = first(vt[vt.metric .== String(m), :], 5)
    @info "Variance decomposition (top 5)" metric = m table = top
end
@info "Saved: ModelB-Stage2-VarianceDecomposition.csv"

# ---------------------------------------------------------------------------
# 5. Exemplar six-panel figures (Stage 1 diagnostic layout, from saved dicts)
# ---------------------------------------------------------------------------
for file in filter(f -> startswith(f, "ModelB-Stage2-Exemplar-") &&
                        endswith(f, ".jld2"), readdir(_PATH_TO_DATA))
    d      = load(joinpath(_PATH_TO_DATA, file))
    regime = replace(replace(file, "ModelB-Stage2-Exemplar-" => ""), ".jld2" => "")
    T      = d["steps"]
    n_edge = length(d["edge_coordinates"])

    p1 = plot(0:T, d["band_lower"], fillrange = d["band_upper"],
              fillalpha = 0.15, lw = 0, color = :gray, label = "EMA ± kσ (nominal)")
    plot!(p1, 0:T, d["ema_price"], color = :gray, ls = :dash, label = "EMA")
    plot!(p1, 0:T, d["prices"], color = :black, lw = 1.0, label = "price")
    plot!(p1, xlabel = "step", ylabel = "price", title = "Price — $(regime)")

    p2 = plot(1:T, d["net_imbalance"], color = _BUY_COLOR, legend = false,
              xlabel = "step", ylabel = "φ (executed)", title = "Executed imbalance")
    hline!(p2, [0.0], color = :gray, ls = :dot)

    p3 = plot(1:T, d["edge_buy_count"] ./ n_edge, color = _BUY_COLOR, label = "Buy",
              xlabel = "step", ylabel = "fraction", title = "Edge populations")
    plot!(p3, 1:T, d["edge_hold_count"] ./ n_edge, color = "#888888", label = "Hold")
    plot!(p3, 1:T, d["edge_sell_count"] ./ n_edge, color = _SELL_COLOR, label = "Sell")

    p4 = plot(0:T, d["buy_fraction"], color = _BUY_COLOR, label = "Buy",
              xlabel = "step", ylabel = "fraction", title = "Interior populations")
    plot!(p4, 0:T, d["hold_fraction"], color = "#888888", label = "Hold")
    plot!(p4, 0:T, d["sell_fraction"], color = _SELL_COLOR, label = "Sell")

    desired  = d["executed_buys"] .+ d["executed_sells"] .+
               d["suppressed_buys"] .+ d["suppressed_sells"]
    executed = d["executed_buys"] .+ d["executed_sells"]
    p5 = plot(1:T, desired, color = :gray, label = "desired",
              xlabel = "step", ylabel = "orders", title = "Order volume")
    plot!(p5, 1:T, executed, color = :black, label = "executed")

    p6 = plot(1:T, d["suppressed_buys"], color = _BUY_COLOR, label = "suppressed buys",
              xlabel = "step", ylabel = "count", title = "Suppressed orders")
    plot!(p6, 1:T, d["suppressed_sells"], color = _SELL_COLOR, label = "suppressed sells")

    fig = plot(p1, p2, p3, p4, p5, p6, layout = (3, 2), size = (1000, 1050),
               left_margin = 5Plots.mm, bottom_margin = 5Plots.mm)
    savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Stage2-Exemplar-$(regime).pdf"))
    @info "Saved: ModelB-Stage2-Exemplar-$(regime).pdf" params = d["params"]
end

@info "Analyze-ModelB-Stage2.jl complete."
