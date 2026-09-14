# Fig2b-MeanSell-vs-Time.jl
# Loads: data/ModelA-Homogeneous.jld2
# Produces:
#   figs/Fig2b-StateFractions-v4.pdf -> paper/figs/Fig2b-StateFractions-v4.pdf

include(joinpath(@__DIR__, "Include.jl"))

d      = load(joinpath(_PATH_TO_DATA, "ModelA-Homogeneous.jld2"))
frames = d["frames"]
steps  = sort(collect(keys(frames)))

cells = prod(size(first(values(frames))))
mean_buy_fraction  = [count(==(0), frames[t]) / cells for t in steps]
mean_hold_fraction = [count(==(1), frames[t]) / cells for t in steps]
mean_sell_fraction = [count(==(2), frames[t]) / cells for t in steps]

fig2_b = plot(steps, mean_sell_fraction;
    color = _SELL_COLOR,
    lw = 1.5,
    xlabel = "Time step",
    ylabel = "Average State fraction",
    xscale = :log10,
    legend = :topright,
    label = "Sell",
    size = (620, 420),
    background_color_inside = "#EEF0F2",
    grid        = true,
    gridcolor   = :black,
    gridwidth   = 0.5,
    gridalpha   = 0.2,
    minorgrid   = true,
    minorgridcolor = :black,
    minorgridwidth = 0.3,
    minorgridalpha = 0.1,
    minorticks  = 5,
)

plot!(fig2_b, steps, mean_hold_fraction;
    color = _HOLD_COLOR,
    lw = 2.0,
    label = "Hold",
)

plot!(fig2_b, steps, mean_buy_fraction;
    color = _BUY_COLOR,
    lw = 2.0,
    label = "Buy",
)

plot!(fig2_b;
    lw = 2.0,
    xlabel = "Time step",
    ylabel = "Average State fraction",
)

_save_figure(fig2_b, "Fig2b-StateFractions-v4.pdf")

@info "Saved: Fig2b-StateFractions-v3.pdf"
