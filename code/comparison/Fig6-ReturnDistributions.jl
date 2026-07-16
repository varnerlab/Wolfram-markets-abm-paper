# Fig6-ReturnDistributions.jl
# Loads: data/ModelA-Homogeneous.jld2, data/ModelB-ClosedLoop.jld2,
#        data/QQQ-OHLC-1-min-aggregate-2024.csv
# Produces: figs/Fig6-ReturnDistributions.pdf  →  paper/figs/
#
#
# STALE (2026-07-16): reads pre-rebuild Model B data (deleted producer).
# Regenerate at Stage 2 from the rebuilt closed-loop model; see
# docs/superpowers/specs/2026-07-15-model-b-rebuild-design.md §6.
#

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------
dA    = load(joinpath(_PATH_TO_DATA, "ModelA-Homogeneous.jld2"))
dB    = load(joinpath(_PATH_TO_DATA, "ModelB-ClosedLoop.jld2"))
df    = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))

# Log returns
returns_A   = compute_log_returns(dA["prices"])
returns_B   = compute_log_returns(dB["prices"])
returns_QQQ = compute_log_returns(compute_typical_price(df))

# Standardise for overlay comparison — skip degenerate series (zero variance)
function safe_standardise(r)
    σ = std(r)
    σ ≈ 0.0 && return nothing
    return (r .- mean(r)) ./ σ
end

zA   = safe_standardise(returns_A)
zB   = safe_standardise(returns_B)
zQQQ = safe_standardise(returns_QQQ)

# Normal reference
x_ref = range(-5, 5; length = 300)
y_ref = pdf.(Normal(0, 1), x_ref)

# ---------------------------------------------------------------------------
# Panel A — histogram overlays (standardised log returns)
# ---------------------------------------------------------------------------
pA = plot(; xlabel = "Standardised log return", ylabel = "Density",
    title = "A  Return distributions", titlefont = 9, yscale = :log10)
!isnothing(zQQQ) && histogram!(pA, zQQQ; normalize = :pdf, bins = 80, alpha = 0.4, label = "QQQ (real)", color = :black)
!isnothing(zA)   && histogram!(pA, zA;   normalize = :pdf, bins = 80, alpha = 0.4, label = "Model A",    color = :steelblue)
!isnothing(zB)   && histogram!(pA, zB;   normalize = :pdf, bins = 80, alpha = 0.4, label = "Model B",    color = :firebrick)
plot!(pA, x_ref, y_ref; lw = 2, color = :black, linestyle = :dash, label = "Normal(0,1)")

# ---------------------------------------------------------------------------
# Panel B — QQ plot vs Normal
# ---------------------------------------------------------------------------
function qqpoints(r)
    n  = length(r)
    ps = [(i - 0.5) / n for i in 1:n]
    quantile.(Normal(0,1), ps), sort(r)
end

pB = plot(; xlabel = "Normal quantile", ylabel = "Sample quantile",
    title = "B  QQ plot vs Normal", titlefont = 9)
for (z_ser, lbl, col) in [(zQQQ,"QQQ",:black),(zA,"Model A",:steelblue),(zB,"Model B",:firebrick)]
    isnothing(z_ser) && continue
    xv, yv = qqpoints(z_ser)
    plot!(pB, xv, yv; seriestype = :scatter, ms = 1.5, alpha = 0.3, color = col, label = lbl)
end
plot!(pB, [-5,5], [-5,5]; lw = 1.5, color = :black, linestyle = :dash, label = false)

# ---------------------------------------------------------------------------
# Panel C — tail comparison (log-log survival function)
# ---------------------------------------------------------------------------
function tail_plot(r, label, color)
    neg_tail = sort(filter(<(0), r))
    isempty(neg_tail) && return nothing, nothing, label, color
    n  = length(neg_tail)
    xs = abs.(neg_tail)
    ys = (1:n) ./ n
    return xs, 1 .- ys, label, color
end

_tp(z, lbl, col) = isnothing(z) ? (nothing, nothing, lbl, col) : tail_plot(z, lbl, col)
xs_Q, ys_Q, lQ, cQ = _tp(zQQQ, "QQQ",     :black)
xs_A, ys_A, lA, cA = _tp(zA,   "Model A",  :steelblue)
xs_B, ys_B, lB, cB = _tp(zB,   "Model B",  :firebrick)

# Start with the first non-empty series
pC = if !isnothing(xs_Q)
    plot(xs_Q, ys_Q; xscale = :log10, yscale = :log10,
        lw = 1.5, color = cQ, label = lQ,
        xlabel = "|return|", ylabel = "P(|R| > x)",
        title = "C  Left-tail survival", titlefont = 9)
else
    plot(; xscale = :log10, yscale = :log10,
        xlabel = "|return|", ylabel = "P(|R| > x)",
        title = "C  Left-tail survival", titlefont = 9)
end
!isnothing(xs_A) && plot!(pC, xs_A, ys_A; lw = 1.5, color = cA, label = lA)
!isnothing(xs_B) && plot!(pC, xs_B, ys_B; lw = 1.5, color = cB, label = lB)

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig6 = plot(pA, pB, pC;
    layout = (1, 3), size = (1050, 340),
    plot_title = "Return distribution comparison")

_save_figure(fig6, "Fig6-ReturnDistributions.pdf")
