# Table2-StylizedFacts.jl
# Computes stylized-fact statistics for QQQ, Model A, and Model B.
# Prints LaTeX tabular rows — paste into paper/sections/tables.tex.

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Load
# ---------------------------------------------------------------------------
dA    = load(joinpath(_PATH_TO_DATA, "ModelA-Homogeneous.jld2"))
dB    = load(joinpath(_PATH_TO_DATA, "ModelB-ClosedLoop.jld2"))
df    = load_price_data(joinpath(_PATH_TO_DATA, "QQQ-OHLC-1-min-aggregate-2024.csv"))

ret_A   = compute_log_returns(dA["prices"])
ret_B   = compute_log_returns(dB["prices"])
ret_QQQ = compute_log_returns(compute_typical_price(df))

# ---------------------------------------------------------------------------
# Stylized-fact metrics
# ---------------------------------------------------------------------------
function stylized_facts(r::Vector{Float64})
    n   = length(r)
    μ   = mean(r)
    σ   = std(r)
    sk  = skewness(r)
    ku  = kurtosis(r)     # excess kurtosis

    # Ljung-Box test statistic for return autocorrelation at lag 1
    r_demean = r .- μ
    γ0 = mean(r_demean.^2)
    γ1 = mean(r_demean[1:end-1] .* r_demean[2:end])
    ac1_ret = γ1 / γ0

    # Autocorrelation of |returns| at lag 1 (volatility clustering)
    ar = abs.(r)
    ar_demean = ar .- mean(ar)
    γ0a = mean(ar_demean.^2)
    γ1a = mean(ar_demean[1:end-1] .* ar_demean[2:end])
    ac1_abs = γ1a / γ0a

    # Hill tail index (upper 10% of |returns|)
    sorted_r = sort(abs.(r); rev = true)
    k_hill   = max(2, n ÷ 10)
    x_min_h  = sorted_r[k_hill]
    α_hill   = k_hill / sum(log.(sorted_r[1:k_hill] ./ x_min_h))

    return (μ = μ, σ = σ, skewness = sk, kurtosis = ku,
            ac1_ret = ac1_ret, ac1_abs = ac1_abs, tail_index = α_hill)
end

sf_QQQ = stylized_facts(ret_QQQ)
sf_A   = stylized_facts(ret_A)
sf_B   = stylized_facts(ret_B)

# ---------------------------------------------------------------------------
# Print LaTeX table
# ---------------------------------------------------------------------------
println("""
% ---- Table 2: Stylized Facts  (paste into paper) ----
\\begin{table}[h]
\\centering
\\caption{Stylized facts: QQQ (real data), Model A (open), and Model B (closed loop).
AC(1) ret = lag-1 autocorrelation of log returns; AC(1) |ret| = lag-1 autocorrelation
of absolute returns (volatility clustering); Tail \$\\alpha\$ = Hill tail index.}
\\label{tab:stylized-facts}
\\begin{tabular}{lrrrrrr}
\\toprule
Statistic & Mean & Std dev & Skewness & Ex. kurtosis & AC(1) ret & AC(1) |ret| & Tail \$\\alpha\$ \\\\
\\midrule""")

rows = [("QQQ (real)", sf_QQQ), ("Model A", sf_A), ("Model B", sf_B)]
for (name, sf) in rows
    @printf "%-14s & %7.4f & %7.4f & %7.3f & %8.2f & %8.4f & %8.4f & %6.2f \\\\\n" \
        name sf.μ sf.σ sf.skewness sf.kurtosis sf.ac1_ret sf.ac1_abs sf.tail_index
end

println("""\\bottomrule
\\end{tabular}
\\end{table}
% ---- end Table 2 ----""")
