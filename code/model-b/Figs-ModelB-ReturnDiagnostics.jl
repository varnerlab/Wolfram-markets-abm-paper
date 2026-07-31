# Figs-ModelB-ReturnDiagnostics.jl -- ensemble price and return diagnostics.
#
# Reads:
#   code/data/ModelB-Nucleation-SeedSweep-Trajectories.csv
#   code/data/QQQ-OHLC-1-min-aggregate-2024.csv
# Writes:
#   code/data/ModelB-ReturnDiagnostics-Summary.csv
#   code/figs/FigS8-ReturnDiagnostics.pdf (+ paper-arxiv/figs copy)
#
# The three Model B ensembles are the canonical stable/freeze/collapse cells
# already used by the nucleation seed sweep (20 disorder seeds, 1,000 steps).
# Model returns are standardized within seed before their shapes are pooled.
# QQQ is a descriptive intraday benchmark only: the 60 cross-session joins are
# excluded, and returns are standardized within each of the 61 trading days.
# Model A is deliberately absent because its price is this same external QQQ
# series and therefore is not an independently generated return process.

include(joinpath(@__DIR__, "Include.jl"))
using Printf

const RD_P0       = 100.0
const RD_STEPS    = 1000
const RD_SEEDS    = collect(1:20)
const RD_LAGS     = collect(1:50)
const RD_CONFIGS  = ["stable", "freeze", "collapse"]
const RD_LABELS   = Dict("stable" => "stable", "freeze" => "freeze",
                         "collapse" => "collapse", "QQQ_intraday" => "QQQ intraday")
const RD_COLORS   = Dict("stable" => _SERIES_COLORS[1],
                         "freeze" => _SERIES_COLORS[2],
                         "collapse" => _SERIES_COLORS[3],
                         "QQQ_intraday" => _SERIES_COLORS[5])

traj_path = joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep-Trajectories.csv")
traj = CSV.read(traj_path, DataFrame)
required = [:config, :seed, :step, :maxcluster_frac, :price, :log_return]
@assert all(c -> c in propertynames(traj), required) "seed-sweep trajectory table lacks price/return columns; rerun Compute-ModelB-NucleationSeeds.jl"
@assert nrow(traj) == length(RD_CONFIGS) * length(RD_SEEDS) * RD_STEPS
@assert sort(unique(traj.config)) == sort(RD_CONFIGS)

# The committed trajectory table is also an audit of the simulator identity
# r_t = log(P_t/P_{t-1}) = lambda*phi_t. Reconstruct every return from price,
# including t=1 from the known P0, before calculating any distributional
# statistic.
for g in groupby(traj, [:config, :seed])
    d = sort(DataFrame(g), :step)
    @assert d.step == collect(1:RD_STEPS)
    reconstructed = diff(log.(vcat(RD_P0, d.price)))
    @assert all(isapprox.(reconstructed, d.log_return; atol = 1e-12, rtol = 0.0))
end

qqq = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))
qqq_price = compute_typical_price(qqq)
qqq_session = [String(s)[1:10] for s in qqq.date]
qqq_returns = compute_session_log_returns(qqq_price, qqq_session)
@assert length(unique(qqq_session)) == 61
@assert length(qqq_returns) == 23_729  # 61 sessions x 389 within-session changes
@assert length(compute_log_returns(qqq_price)) - length(qqq_returns) == 60

function _return_stats(source::String, replicate::String, phase::String,
                       r::Vector{Float64})
    length(r) >= 3 || return nothing
    sigma = std(r)
    sigma > 0 || return nothing
    return (source = source, replicate = replicate, phase = phase,
            n_returns = length(r), mean_return = mean(r), return_std = sigma,
            return_skewness = skewness(r), return_kurtosis = kurtosis(r),
            return_ac1 = autocor(r, [1])[1],
            absolute_return_ac1 = autocor(abs.(r), [1])[1],
            zero_fraction = mean(r .== 0.0),
            max_abs_standardized_return = maximum(abs.((r .- mean(r)) ./ sigma)))
end

# Per-replicate summaries for the full trajectory and, when onset occurs,
# either side of the first 5%-of-grid sell cluster. These phase rows keep the
# full-run tail result from silently conflating a transition with a stationary
# return law. A censored run contributes only its full row.
summary_rows = NamedTuple[]
model_returns = Dict{String,Vector{Vector{Float64}}}()
for config in RD_CONFIGS
    per_seed = Vector{Vector{Float64}}()
    for seed in RD_SEEDS
        d = sort(traj[(traj.config .== config) .& (traj.seed .== seed), :], :step)
        r = Float64.(d.log_return)
        push!(per_seed, r)
        full = _return_stats(config, string(seed), "full", r)
        !isnothing(full) && push!(summary_rows, full)
        onset = something(findfirst(>=(0.05), d.maxcluster_frac), 0)
        if onset > 3
            pre = _return_stats(config, string(seed), "pre_onset", r[1:(onset - 1)])
            !isnothing(pre) && push!(summary_rows, pre)
        end
        if onset > 0 && onset <= length(r) - 3
            post = _return_stats(config, string(seed), "onset_and_after", r[onset:end])
            !isnothing(post) && push!(summary_rows, post)
        end
    end
    model_returns[config] = per_seed
end

qqq_returns_by_day = Vector{Vector{Float64}}()
for day in unique(qqq_session)
    p = qqq_price[qqq_session .== day]
    r = compute_log_returns(p)
    @assert length(r) == 389
    push!(qqq_returns_by_day, r)
    row = _return_stats("QQQ_intraday", day, "intraday", r)
    !isnothing(row) && push!(summary_rows, row)
end

summary = DataFrame(summary_rows)
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-ReturnDiagnostics-Summary.csv"), summary)
@info "Saved: ModelB-ReturnDiagnostics-Summary.csv" rows = nrow(summary)

function _standardized_pool(series::Vector{Vector{Float64}})
    pooled = Float64[]
    for r in series
        sigma = std(r)
        sigma > 0 || continue
        append!(pooled, (r .- mean(r)) ./ sigma)
    end
    return pooled
end

function _ccdf_on_grid(z::Vector{Float64}, xgrid)
    a = abs.(z)
    return [mean(a .> x) for x in xgrid]
end

function _acf_matrix(series::Vector{Vector{Float64}}; absolute::Bool = false)
    out = Matrix{Float64}(undef, length(series), length(RD_LAGS))
    for (i, r) in enumerate(series)
        x = absolute ? abs.(r) : r
        out[i, :] .= autocor(x, RD_LAGS)
    end
    return out
end

_colquantile(M::Matrix{Float64}, p::Float64) =
    [quantile(view(M, :, j), p) for j in axes(M, 2)]

function _plot_acf_band!(p, series::Vector{Vector{Float64}}, source::String;
                         absolute::Bool = false, legend::Bool = true)
    M = _acf_matrix(series; absolute = absolute)
    lo = _colquantile(M, 0.25)
    md = _colquantile(M, 0.50)
    hi = _colquantile(M, 0.75)
    plot!(p, RD_LAGS, md; ribbon = (md .- lo, hi .- md), fillalpha = 0.12,
          color = RD_COLORS[source], lw = 2.0,
          label = legend ? RD_LABELS[source] : "")
    return p
end

# A -- ensemble price paths. The logarithm puts upward and downward moves on
# the same additive scale and avoids allowing one tail path to flatten the two
# lower-amplitude ensembles.
pA = plot(; xlabel = "Simulation step", ylabel = "Log price ratio, ln(P/P0)",
          legend = :topleft,
          _panel_kw...)
for config in RD_CONFIGS
    d = traj[traj.config .== config, :]
    agg = combine(groupby(d, :step),
                  :price => (x -> quantile(log.(x ./ RD_P0), 0.25)) => :q25,
                  :price => (x -> median(log.(x ./ RD_P0))) => :q50,
                  :price => (x -> quantile(log.(x ./ RD_P0), 0.75)) => :q75)
    plot!(pA, agg.step, agg.q50;
          ribbon = (agg.q50 .- agg.q25, agg.q75 .- agg.q50), fillalpha = 0.14,
          color = RD_COLORS[config], lw = 2.2, label = RD_LABELS[config])
end
hline!(pA, [0.0], color = :gray, ls = :dot, lw = 0.8, label = "")
_panel_letter!(pA, "A")

# B -- standardized absolute-return survival. Every replicate is standardized
# before pooling, so the panel compares shape rather than lambda or daily scale.
xgrid = collect(range(0.0, 10.0; length = 251))
pB = plot(; xlabel = "Standardized absolute log return, |Z|",
          ylabel = "Survival probability",
          yscale = :log10, ylims = (3e-5, 1.05), xlims = (0, 10),
          legend = :topright, _panel_kw...)
for config in RD_CONFIGS
    z = _standardized_pool(model_returns[config])
    y = _ccdf_on_grid(z, xgrid)
    keep = y .> 0
    plot!(pB, xgrid[keep], y[keep], color = RD_COLORS[config], lw = 2.2,
          label = RD_LABELS[config])
end
zqqq = _standardized_pool(qqq_returns_by_day)
yqqq = _ccdf_on_grid(zqqq, xgrid)
plot!(pB, xgrid[yqqq .> 0], yqqq[yqqq .> 0], color = RD_COLORS["QQQ_intraday"],
      lw = 2.2, label = RD_LABELS["QQQ_intraday"])
normal_tail = 2 .* ccdf.(Normal(), xgrid)
plot!(pB, xgrid, normal_tail, color = :gray, ls = :dash, lw = 1.4,
      label = "normal")
_panel_letter!(pB, "B")

# C-D -- linear-return and absolute-return autocorrelation. Model bands are
# across 20 seeds; the QQQ band is across 61 regular trading sessions.
pC = plot(; xlabel = "Lag (steps or 1-min bars)",
          ylabel = "Return autocorrelation", legend = :topright,
          _panel_kw...)
hline!(pC, [0.0], color = :gray, ls = :dot, lw = 0.8, label = "")
for config in RD_CONFIGS
    _plot_acf_band!(pC, model_returns[config], config)
end
_plot_acf_band!(pC, qqq_returns_by_day, "QQQ_intraday")
_panel_letter!(pC, "C")

pD = plot(; xlabel = "Lag (steps or 1-min bars)",
          ylabel = "Absolute-return autocorrelation", legend = :topright,
          _panel_kw...)
hline!(pD, [0.0], color = :gray, ls = :dot, lw = 0.8, label = "")
for config in RD_CONFIGS
    _plot_acf_band!(pD, model_returns[config], config; absolute = true)
end
_plot_acf_band!(pD, qqq_returns_by_day, "QQQ_intraday"; absolute = true)
_panel_letter!(pD, "D")

fig = plot(pA, pB, pC, pD; layout = (2, 2), size = (900, 675),
           left_margin = 7Plots.mm, bottom_margin = 5Plots.mm,
           right_margin = 4Plots.mm)
_save_figure(fig, "FigS8-ReturnDiagnostics.pdf")

for source in vcat(RD_CONFIGS, ["QQQ_intraday"])
    phase = source == "QQQ_intraday" ? "intraday" : "full"
    d = summary[(summary.source .== source) .& (summary.phase .== phase), :]
    @info "Return diagnostics" source n = nrow(d) kurtosis_median = round(median(d.return_kurtosis), digits = 3) ac1_median = round(median(d.return_ac1), digits = 3) abs_ac1_median = round(median(d.absolute_return_ac1), digits = 3)
end

@info "Figs-ModelB-ReturnDiagnostics.jl complete."
