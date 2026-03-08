# Fig6-ReturnDistributions.jl
# Loads: data/ModelA-Homogeneous.jld2, data/ModelB-ClosedLoop.jld2,
#        data/QQQ-OHLC-1-min-aggregate-2024.csv
# Produces: figs/Fig6-ReturnDistributions.pdf  →  paper/figs/

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

# Standardise for overlay comparison
z(r) = (r .- mean(r)) ./ std(r)

zA   = z(returns_A)
zB   = z(returns_B)
zQQQ = z(returns_QQQ)

# Normal reference
x_ref = range(-5, 5; length = 300)
y_ref = pdf.(Normal(0, 1), x_ref)

# ---------------------------------------------------------------------------
# Panel A — histogram overlays (standardised log returns)
# ---------------------------------------------------------------------------
pA = histogram(zQQQ; normalize = :pdf, bins = 80, alpha = 0.4,
    label = "QQQ (real)", color = :black,
    xlabel = "Standardised log return", ylabel = "Density",
    title = "A  Return distributions", titlefont = 9, yscale = :log10)
histogram!(pA, zA;  normalize = :pdf, bins = 80, alpha = 0.4,
    label = "Model A", color = :steelblue)
histogram!(pA, zB;  normalize = :pdf, bins = 80, alpha = 0.4,
    label = "Model B", color = :firebrick)
plot!(pA, x_ref, y_ref; lw = 2, color = :black, linestyle = :dash,
    label = "Normal(0,1)")

# ---------------------------------------------------------------------------
# Panel B — QQ plot vs Normal
# ---------------------------------------------------------------------------
function qqpoints(r)
    n  = length(r)
    ps = [(i - 0.5) / n for i in 1:n]
    quantile.(Normal(0,1), ps), sort(r)
end

xA, yA   = qqpoints(zA)
xB, yB   = qqpoints(zB)
xQ, yQ   = qqpoints(zQQQ)

pB = plot(xQ, yQ; seriestype = :scatter, ms = 1.5, alpha = 0.3,
    color = :black, label = "QQQ",
    xlabel = "Normal quantile", ylabel = "Sample quantile",
    title = "B  QQ plot vs Normal", titlefont = 9)
plot!(pB, xA, yA; seriestype = :scatter, ms = 1.5, alpha = 0.3,
    color = :steelblue, label = "Model A")
plot!(pB, xB, yB; seriestype = :scatter, ms = 1.5, alpha = 0.3,
    color = :firebrick, label = "Model B")
plot!(pB, [-5,5], [-5,5]; lw = 1.5, color = :black, linestyle = :dash, label = false)

# ---------------------------------------------------------------------------
# Panel C — tail comparison (log-log survival function)
# ---------------------------------------------------------------------------
function tail_plot(r, label, color)
    neg_tail = sort(r[r .< 0])       # left tail (crashes)
    n        = length(neg_tail)
    xs       = abs.(neg_tail)         # positive magnitudes
    ys       = (1:n) ./ n             # empirical CDF
    return xs, 1 .- ys, label, color  # survival function
end

xs_Q, ys_Q, lQ, cQ = tail_plot(zQQQ, "QQQ",     :black)
xs_A, ys_A, lA, cA = tail_plot(zA,   "Model A",  :steelblue)
xs_B, ys_B, lB, cB = tail_plot(zB,   "Model B",  :firebrick)

pC = plot(xs_Q, ys_Q; xscale = :log10, yscale = :log10,
    lw = 1.5, color = cQ, label = lQ,
    xlabel = "|return|", ylabel = "P(|R| > x)",
    title = "C  Left-tail survival", titlefont = 9)
plot!(pC, xs_A, ys_A; lw = 1.5, color = cA, label = lA)
plot!(pC, xs_B, ys_B; lw = 1.5, color = cB, label = lB)

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig6 = plot(pA, pB, pC;
    layout = (1, 3), size = (1050, 340),
    plot_title = "Return distribution comparison")

_save_figure(fig6, "Fig6-ReturnDistributions.pdf")
