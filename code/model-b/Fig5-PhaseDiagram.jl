# Fig5-PhaseDiagram.jl
# Loads: data/ModelB-PhaseSweep.jld2
# Produces: figs/Fig5-PhaseDiagram.pdf  →  paper/figs/Fig5-PhaseDiagram.pdf
#
# Layout (1×3):
#   Panel A  crash frequency heatmap on (k, f) grid
#   Panel B  return std deviation heatmap on (k, f) grid
#   Panel C  excess kurtosis heatmap on (k, f) grid  (fat-tail signature)

include(joinpath(@__DIR__, "Include.jl"))

d        = load(joinpath(_PATH_TO_DATA, "ModelB-PhaseSweep.jld2"))
k_values = d["k_values"]
f_values = d["f_values"]
sweep    = d["sweep"]

# Build matrices indexed [ki, fi]
nk = length(k_values)
nf = length(f_values)

crash_mat = zeros(nk, nf)
std_mat   = zeros(nk, nf)
kurt_mat  = zeros(nk, nf)

for (ki, k) in enumerate(k_values), (fi, f) in enumerate(f_values)
    entry          = sweep[(k, f)]
    crash_mat[ki,fi] = entry["crash_frequency"]
    std_mat[ki,fi]   = entry["return_std"]
    kurt_mat[ki,fi]  = entry["return_kurtosis"]
end

kl = string.(k_values)
fl = string.(f_values)

pA = heatmap(fl, kl, crash_mat;
    xlabel = "Minority fraction  f", ylabel = "Band width  k",
    title = "A  Crash frequency", titlefont = 9,
    color = :RdYlBu_r, clims = (0, 1))

pB = heatmap(fl, kl, std_mat;
    xlabel = "Minority fraction  f", ylabel = "Band width  k",
    title = "B  Return volatility  σ", titlefont = 9,
    color = :viridis)

pC = heatmap(fl, kl, kurt_mat;
    xlabel = "Minority fraction  f", ylabel = "Band width  k",
    title = "C  Excess kurtosis", titlefont = 9,
    color = :plasma)

fig5 = plot(pA, pB, pC;
    layout = (1, 3), size = (1050, 320),
    plot_title = "Model B — Phase diagram in (k, f) space")

_save_figure(fig5, "Fig5-PhaseDiagram.pdf")
