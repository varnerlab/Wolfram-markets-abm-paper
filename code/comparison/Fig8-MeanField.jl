# Fig8-MeanField.jl
# Compares spatial CA (Model B) to a mean-field version where each agent
# sees the global population mean state instead of its 4 local neighbours.
#
# Produces: figs/Fig8-MeanField.pdf  →  paper/figs/Fig8-MeanField.pdf
#
#
# STALE (2026-07-16): reads pre-rebuild Model B data (deleted producer).
# Regenerate at Stage 2 from the rebuilt closed-loop model; see
# docs/superpowers/specs/2026-07-15-model-b-rebuild-design.md §6.
#
# Layout (2×2):
#   Panel A  CA price series
#   Panel B  Mean-field price series
#   Panel C  Return distribution overlay (CA vs MF)
#   Panel D  Crash size distribution overlay (CA vs MF)

include(joinpath(@__DIR__, "Include.jl"))

# ---------------------------------------------------------------------------
# Mean-field simulation
# The mean-field (MF) approximation replaces the spatial CA update with a
# well-mixed model: every agent's neighbourhood mean equals the population
# mean state  μ_MF = h + 2s  (where b, h, s are global fractions).
# All agents sharing a rule transition together, so the dynamics collapse
# to a 2-component ODE driven by edge-state injection.
# ---------------------------------------------------------------------------

function simulate_meanfield(;
    rule_major_index::Int64  = 19280,
    rule_minor_index::Int64  = 19286,
    minority_fraction::Float64 = 0.20,
    number_of_colors::Int64  = 3,
    radius::Int64            = 4,
    α::Float64               = 1/60,
    k::Float64               = 1.0,
    λ::Float64               = 0.01,
    P0::Float64              = 100.0,
    N::Int64                 = 256 * 256,
    steps::Int64             = 1000,
)
    rule_major = build(MyTwoDimensionalTotalisticWolframRuleModel,
        (index = rule_major_index, colors = number_of_colors, radius = radius))
    rule_minor = build(MyTwoDimensionalTotalisticWolframRuleModel,
        (index = rule_minor_index, colors = number_of_colors, radius = radius))

    Q_major = rule_major.neighborhoodstatesmap
    Q_minor = rule_minor.neighborhoodstatesmap

    # Initial fractions: all Hold
    b = 0.0; h = 1.0; s = 0.0

    prices      = Vector{Float64}(undef, steps + 1)
    net_imbal   = Vector{Float64}(undef, steps)
    sell_fracs  = Vector{Float64}(undef, steps)
    prices[1]   = P0
    μ_t = P0; σ_t = 0.0

    for t in 1:steps
        P_t = prices[t]
        μ_t = μ_t + α*(P_t - μ_t)
        σ_t = σ_t + α*(abs(P_t - μ_t) - σ_t)
        estate = compute_band_state(P_t, μ_t, σ_t, k)   # 0/1/2

        # Population mean neighbourhood state (well-mixed)
        μ_MF  = h + 2.0*s
        cfg_major = Q_major[round(μ_MF, digits = 2)]
        cfg_minor = Q_minor[round(μ_MF, digits = 2)]
        new_state_major = rule_major.rule[cfg_major]
        new_state_minor = rule_minor.rule[cfg_minor]

        # Update fractions (edge agents inject estate into ~3/N of population)
        edge_weight = 3.0 / N
        interior    = 1.0 - edge_weight

        b_new  = interior * ((1-minority_fraction)*(new_state_major == 0) +
                              minority_fraction   *(new_state_minor == 0)) +
                 edge_weight * (estate == 0 ? 1.0 : 0.0)
        h_new  = interior * ((1-minority_fraction)*(new_state_major == 1) +
                              minority_fraction   *(new_state_minor == 1)) +
                 edge_weight * (estate == 1 ? 1.0 : 0.0)
        s_new  = interior * ((1-minority_fraction)*(new_state_major == 2) +
                              minority_fraction   *(new_state_minor == 2)) +
                 edge_weight * (estate == 2 ? 1.0 : 0.0)
        b, h, s = b_new, h_new, s_new

        φ = b - s
        net_imbal[t]  = φ
        sell_fracs[t] = s
        prices[t+1]   = compute_price_update(P_t, φ, λ)
    end

    return (prices = prices, net_imbalance = net_imbal, sell_fracs = sell_fracs)
end

# ---------------------------------------------------------------------------
# Load spatial CA result and run mean-field
# ---------------------------------------------------------------------------
dB     = load(joinpath(_PATH_TO_DATA, "ModelB-ClosedLoop.jld2"))
params = dB["parameters"]

@info "Running mean-field simulation ..."
mf = simulate_meanfield(;
    λ = params["λ"], k = params["k"],
    minority_fraction = params["f"], P0 = params["P0"],
    steps = length(dB["net_imbalance"]),
)

ret_CA = compute_log_returns(dB["prices"])
ret_MF = compute_log_returns(mf.prices)

frames_CA = dB["frames"]
sizes_CA  = compute_crash_sizes(frames_CA; threshold = 0.40)

steps_mf  = 1:length(mf.sell_fracs)
sizes_MF = let sizes = Int64[], in_crash = false, dur = 0
    for sf in mf.sell_fracs
        if sf >= 0.40
            in_crash = true; dur += 1
        else
            in_crash && push!(sizes, dur)
            in_crash = false; dur = 0
        end
    end
    in_crash && push!(sizes, dur)
    sizes
end

# ---------------------------------------------------------------------------
# Panel A — CA price series
# ---------------------------------------------------------------------------
pA = plot(dB["prices"][1:end-1]; lw = 1.0, color = :firebrick, legend = false,
    xlabel = "Step", ylabel = "Price", title = "A  CA (spatial)", titlefont = 9)

# ---------------------------------------------------------------------------
# Panel B — Mean-field price series
# ---------------------------------------------------------------------------
pB = plot(mf.prices[1:end-1]; lw = 1.0, color = :steelblue, legend = false,
    xlabel = "Step", ylabel = "Price", title = "B  Mean-field", titlefont = 9)

# ---------------------------------------------------------------------------
# Panel C — Return distribution overlay
# ---------------------------------------------------------------------------
pC = histogram(ret_CA; normalize = :pdf, bins = 60, alpha = 0.5,
    color = :firebrick, label = "CA (spatial)",
    xlabel = "Log return", ylabel = "Density",
    title = "C  Return distributions", titlefont = 9)
histogram!(pC, ret_MF; normalize = :pdf, bins = 60, alpha = 0.5,
    color = :steelblue, label = "Mean-field")

# ---------------------------------------------------------------------------
# Panel D — Crash size distribution overlay
# ---------------------------------------------------------------------------
pD = plot(; xscale = :log10, yscale = :log10,
    xlabel = "Crash size", ylabel = "Count",
    title = "D  Crash sizes", titlefont = 9)

if !isempty(sizes_CA)
    h_CA = fit(Histogram, sizes_CA, nbins = 15)
    plot!(pD, collect(h_CA.edges[1])[1:end-1], h_CA.weights .+ 1;
        lw = 2, color = :firebrick, label = "CA (spatial)")
end
if !isempty(sizes_MF)
    h_MF = fit(Histogram, sizes_MF, nbins = 15)
    plot!(pD, collect(h_MF.edges[1])[1:end-1], h_MF.weights .+ 1;
        lw = 2, color = :steelblue, linestyle = :dash, label = "Mean-field")
end

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig8 = plot(pA, pB, pC, pD;
    layout = (2, 2), size = (850, 600),
    plot_title = "Spatial CA vs mean-field: does topology matter?")

_save_figure(fig8, "Fig8-MeanField.pdf")
