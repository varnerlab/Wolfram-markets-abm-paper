# Fig2-Combined.jl
# Loads: data/ModelA-Homogeneous.jld2
# Produces: figs/Fig2-Combined.pdf -> paper/figs/Fig2-Combined.pdf
#
# Layout: tight 2×4 snapshot grid (top) + styled state-fraction line plot (bottom)

include(joinpath(@__DIR__, "Include.jl"))

d      = load(joinpath(_PATH_TO_DATA, "ModelA-Homogeneous.jld2"))
frames = d["frames"]
steps  = sort(collect(keys(frames)))
N      = prod(size(first(values(frames))))

# ---------------------------------------------------------------------------
# Panel A — tight 2×4 snapshot grid (direct image composition)
# ---------------------------------------------------------------------------
targets    = [1, 32, 64, 128, 512, 1024, 4096, 16384]
snap_times = [steps[argmin(abs.(steps .- t))] for t in targets]
snap_grids = [frames[t] for t in snap_times]

panel_h, panel_w = size(snap_grids[1])
nrows_g, ncols_g = 2, 4
canvas_h = nrows_g * panel_h
canvas_w = ncols_g * panel_w
canvas   = fill(0, canvas_h, canvas_w)

for (k, g) in enumerate(snap_grids)
    r  = (k - 1) ÷ ncols_g
    c  = (k - 1) % ncols_g
    y0 = r * panel_h + 1
    x0 = c * panel_w + 1
    canvas[y0:y0+panel_h-1, x0:x0+panel_w-1] .= g
end

pA = heatmap(canvas;
    c            = _grid_cgrad(),
    clims        = (0, 2),
    axis         = false,
    colorbar     = false,
    yflip        = true,
    aspect_ratio = :equal,
    framestyle   = :none,
    xticks       = false,
    yticks       = false,
    left_margin  = 0Plots.mm,
    right_margin = 0Plots.mm,
    top_margin   = 2Plots.mm,
    bottom_margin= 0Plots.mm,
)
plot!(pA; xlim=(0.5, canvas_w+0.5), ylim=(0.5, canvas_h+0.5))

# Time labels in each panel
for k in eachindex(snap_times)
    r = (k - 1) ÷ ncols_g
    c = (k - 1) % ncols_g
    x = c * panel_w + panel_w - 6
    y = panel_h * (nrows_g - r) - 18
    annotate!(pA, x, y, text("t = $(snap_times[k])", 8, :black, :right, :top))
end

# ---------------------------------------------------------------------------
# Panel B — state fractions vs log time (styled)
# ---------------------------------------------------------------------------
buy_frac  = [count(==(0), frames[t]) / N for t in steps]
hold_frac = [count(==(1), frames[t]) / N for t in steps]
sell_frac = [count(==(2), frames[t]) / N for t in steps]

pB = plot(steps, sell_frac;
    color                   = _SELL_COLOR,
    lw                      = 2.0,
    label                   = "Sell",
    xscale                  = :log10,
    xlabel                  = "Time step",
    ylabel                  = "Agent fraction",
    ylims                   = (0, 1),
    legend                  = :topright,
    background_color_inside = "#EEF0F2",
    grid                    = true,
    gridcolor               = :black,
    gridwidth               = 0.5,
    gridalpha               = 0.2,
    minorgrid               = true,
    minorgridcolor          = :black,
    minorgridwidth          = 0.3,
    minorgridalpha          = 0.1,
    minorticks              = 5,
    left_margin             = 8Plots.mm,
    bottom_margin           = 6Plots.mm,
)
plot!(pB, steps, hold_frac; label="Hold", color=_HOLD_COLOR, lw=2.0)
plot!(pB, steps, buy_frac;  label="Buy",  color=_BUY_COLOR,  lw=2.0)
vline!(pB, snap_times; color=:black, alpha=0.2, linestyle=:dot, label=false)

# ---------------------------------------------------------------------------
# Compose and save
# ---------------------------------------------------------------------------
l = @layout [a{0.55h}; b{0.45h}]

fig2 = plot(pA, pB;
    layout        = l,
    size          = (900, 700),
    top_margin    = 2Plots.mm,
    right_margin  = 4Plots.mm,
)

_save_figure(fig2, "Fig2-Combined.pdf")
