# Fig7-SOC.jl
# Tests for self-organised criticality via crash size distribution.
# Loads: data/ModelB-ClosedLoop.jld2
# Produces: figs/Fig7-SOC.pdf  →  paper/figs/Fig7-SOC.pdf
#
#
# STALE (2026-07-16): reads pre-rebuild Model B data (deleted producer).
# Regenerate at Stage 2 from the rebuilt closed-loop model; see
# docs/superpowers/specs/2026-07-15-model-b-rebuild-design.md §6.
#
# Layout (1×2):
#   Panel A  log-log crash size histogram + power-law fit
#   Panel B  crash size vs rank (Zipf plot)

include(joinpath(@__DIR__, "Include.jl"))

d      = load(joinpath(_PATH_TO_DATA, "ModelB-ClosedLoop.jld2"))
frames = d["frames"]

# ---------------------------------------------------------------------------
# Crash size: duration (steps) of contiguous sell-dominated windows
# ---------------------------------------------------------------------------
sizes = compute_crash_sizes(frames; threshold = 0.40)

isempty(sizes) && (@warn "No crashes detected at threshold 0.40"; exit())

# ---------------------------------------------------------------------------
# Power-law fit via MLE (Clauset et al. 2009 approach)
# x_min = minimum observed crash size; α = 1 + n / Σ ln(xᵢ/x_min)
# ---------------------------------------------------------------------------
x_min = minimum(sizes)
n     = length(sizes)
α_mle = 1.0 + n / sum(log.(sizes ./ x_min))

@info "Crash size statistics"
@info "  n crashes    = $(n)"
@info "  x_min        = $(x_min)"
@info "  α (MLE)      = $(round(α_mle, digits=3))"
@info "  mean size    = $(round(mean(sizes), digits=2))"
@info "  max size     = $(maximum(sizes))"

# Theoretical power-law CDF for overlay
x_range   = range(x_min, maximum(sizes); length = 200)
pl_survival(x) = (x / x_min)^(-(α_mle - 1))

# ---------------------------------------------------------------------------
# Panel A — log-log survival plot + power-law fit
# ---------------------------------------------------------------------------
sorted_s  = sort(sizes)
ns        = length(sorted_s)
empirical_survival = [(ns - i + 1) / ns for i in 1:ns]

pA = plot(sorted_s, empirical_survival;
    xscale = :log10, yscale = :log10,
    seriestype = :scatter, ms = 3, color = :firebrick, alpha = 0.7,
    label = "Empirical",
    xlabel = "Crash duration (steps)", ylabel = "P(S > s)",
    title = "A  Crash size distribution", titlefont = 9)
plot!(pA, x_range, pl_survival.(x_range);
    lw = 2, color = :black, linestyle = :dash,
    label = "Power law  α = $(round(α_mle, digits=2))")

# ---------------------------------------------------------------------------
# Panel B — Zipf (rank vs size) plot
# ---------------------------------------------------------------------------
ranks = 1:n
zipf_s = sort(sizes; rev = true)

pB = plot(ranks, zipf_s;
    xscale = :log10, yscale = :log10,
    lw = 1.5, color = :steelblue, label = false,
    xlabel = "Rank", ylabel = "Crash size",
    title = "B  Zipf plot", titlefont = 9)

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
fig7 = plot(pA, pB;
    layout = (1, 2), size = (750, 340),
    plot_title = "Self-organised criticality — crash size distribution")

_save_figure(fig7, "Fig7-SOC.pdf")
