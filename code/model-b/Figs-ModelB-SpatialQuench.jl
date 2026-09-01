# Figs-ModelB-SpatialQuench.jl -- representative spatial trajectory selected
# by a prespecified median-onset rule from the full reservoir-quench ensemble.

include(joinpath(@__DIR__, "Include.jl"))

const INPUT = joinpath(_PATH_TO_DATA, "ModelB-ReservoirQuench-Full-Summary.csv")
isfile(INPUT) || error("missing $(INPUT); run Compute-ModelB-ReservoirQuench.jl --full")
summary = CSV.read(INPUT, DataFrame)

const F_EXEMPLAR = 0.20
const H_EXEMPLAR = Inf
const T_PRE = 1000
const T_POST = 3000
const STEPS = T_PRE + T_POST

eligible = summary[(summary.boundary_mode .== "endogenous") .&
                   isinf.(summary.market_maker_capacity) .&
                   (summary.target_f .== F_EXEMPLAR) .&
                   summary.transitioned, :]
nrow(eligible) > 0 || error("no transitioned unlimited-dealer run at f=$(F_EXEMPLAR)")
median_onset = median(eligible.treated_onset)
row = eligible[argmin(abs.(eligible.treated_onset .- median_onset)), :]
seed = Int64(row.seed)
onset = Int64(row.treated_onset)

config = build(MyModelBConfiguration, (
    number_of_rows = 64,
    number_of_cols = 64,
    steps = STEPS,
    seed = seed,
    λ = 0.02,
    k = 1.0,
    minority_fraction = F_EXEMPLAR,
    edge_band_spread = 0.5,
    cost_basis_rule = false,
    initial_cash = 1000.0,
    initial_shares = 10,
    P0 = 100.0,
    market_maker_capacity = H_EXEMPLAR,
))

offsets = unique(Int64[0, round(Int64, onset / 2), onset,
                       min(T_POST, onset + 600)])
length(offsets) == 4 || error("exemplar snapshot offsets are not distinct")
snapshot_steps = T_PRE .+ offsets
treated = simulate(config; snapshot_steps = snapshot_steps,
                   minority_population = :interior,
                   rule_activation_step = T_PRE + 1,
                   boundary_mode = :endogenous, verbose = false)
control = simulate(config; snapshot_steps = [T_PRE, STEPS],
                   minority_population = :interior,
                   rule_activation_step = STEPS + 1,
                   boundary_mode = :endogenous, verbose = false)

observed_onset = findfirst(≥(0.5), @view treated.sell_fraction[(T_PRE + 1):end])
@assert !isnothing(observed_onset) && observed_onset - 1 == onset
@assert treated.frames[T_PRE] == control.frames[T_PRE]
@assert treated.prices[1:(T_PRE + 2)] == control.prices[1:(T_PRE + 2)]

# One montage axis guarantees four exactly equal spatial panels.  A small NaN
# header band carries the time labels and NaN gaps separate adjacent frames.
L = config.number_of_rows
gap = 5
header = 8
montage = fill(NaN, header + L, 4L + 3gap)
centers = Float64[]
for (i, offset) in enumerate(offsets)
    first_col = (i - 1) * (L + gap) + 1
    last_col = first_col + L - 1
    montage[(header + 1):end, first_col:last_col] .= treated.frames[T_PRE + offset]
    push!(centers, (first_col + last_col) / 2)
end
pA = heatmap(montage; c = _grid_cgrad(), clims = (0, 2), colorbar = false,
             axis = false, yflip = true, aspect_ratio = :equal,
             margin = 1Plots.mm)
for (center, offset) in zip(centers, offsets)
    label = offset == 0 ? "activation" : "+$(offset) steps"
    annotate!(pA, center, header / 2, text(label, :black, 10))
end
annotate!(pA, 1.0, header / 2, text("A", :black, :left, 14, "helvetica bold"))

display_start = T_PRE - 500
times = (display_start:STEPS) .- T_PRE
indices = (display_start:STEPS) .+ 1
p0 = treated.prices[T_PRE + 1]

pE = plot(times, control.prices[indices] ./ p0;
          color = :black, ls = :dash, lw = 1.8, label = "dormant control",
          xlabel = "Steps since activation", ylabel = "Price / activation price",
          legend = :bottomleft, _panel_kw...)
plot!(pE, times, treated.prices[indices] ./ p0;
      color = _SERIES_COLORS[3], lw = 2.2, label = "contrarians activated")
vline!(pE, [0, onset]; color = [:black :black], ls = [:dot :dash],
       lw = [1.0 1.0], label = ["" ""])
_panel_letter!(pE, "B")

pF = plot(times, control.sell_fraction[indices];
          color = :black, ls = :dash, lw = 1.8, label = "",
          xlabel = "Steps since activation", ylabel = "Sell fraction",
          ylims = (0, 1), legend = false, _panel_kw...)
plot!(pF, times, treated.sell_fraction[indices];
      color = _SELL_COLOR, lw = 2.2, label = "")
hline!(pF, [0.5]; color = :black, ls = :dot, lw = 1.0, label = "")
vline!(pF, [0, onset]; color = [:black :black], ls = [:dot :dash],
       lw = [1.0 1.0], label = ["" ""])
_panel_letter!(pF, "C")

layout = @layout [a{0.43h}; b c]
fig = plot(pA, pE, pF; layout = layout, size = (1000, 650),
           left_margin = 5Plots.mm, bottom_margin = 4Plots.mm)
output = joinpath(_PATH_TO_FIGS, "Fig3-SpatialQuench.pdf")
savefig(fig, output)
cp(output, joinpath(_PATH_TO_PAPER_FIGS, "Fig3-SpatialQuench.pdf"); force = true)
@info "Saved spatial-quench figure" output seed onset offsets
