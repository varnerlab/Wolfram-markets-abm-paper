# Figs-ModelB-BoundaryVsBulk.jl — figures for the boundary-vs-bulk seeding
# analysis, drawn from committed CSVs/JLD2 (no simulation):
#   code/data/ModelB-Nucleation-BirthSites.csv
#   code/data/ModelB-Nucleation-SeedSweep.csv          (cited-value assertions)
#   code/data/ModelB-StripFrames.jld2                  (Task 4: panel A strip)
#   code/data/ModelB-Nucleation-SeedingIntervention.csv
#   code/data/ModelB-Nucleation-SeedingTrajectories.csv
# Included by Compute-ModelB-BoundaryVsBulk.jl at the end of a sweep, and
# standalone-rerunnable from the repo root:
#   julia code/model-b/Figs-ModelB-BoundaryVsBulk.jl
# (regenerates every PDF from whatever CSVs are on disk — production or smoke).
#
# Writes: code/figs/ + paper-arxiv/figs/
#
# Two independent `let` blocks (locals only, no consts), so including this file
# after a sweep cannot collide with the sweep's global constants:
#   1) Fig5-Nucleus.pdf         — Task 4: rebuilt around the birth-to-engulfment
#      market strip (panel A), which shows the crash nucleus is a single
#      spatial domain, born in the interior, growing into a dominant orange
#      (Sell) region. Panels B (birth-site map) and C (birth-distance
#      histogram vs. the uniform null) are unchanged from Task 7. Reads
#      BirthSites.csv + SeedSweep.csv (cited-value assertions) + StripFrames.jld2.
#   2) FigS5-SeedingDetail.pdf  — Task 10: the seeding-intervention figure,
#      restyled onto the shared style (formerly ModelB-Nucleation-Seeding.pdf).

isdefined(Main, :_PATH_TO_DATA)  || include(joinpath(@__DIR__, "Include.jl"))
isdefined(Main, :null_shell_pmf) || include(joinpath(@__DIR__, "BoundaryVsBulk-Lib.jl"))
using Printf

# =============================================================================
# Fig5-Nucleus.pdf (Task 7; rebuilt around the market strip in Task 4)
# =============================================================================
let
    birth_df  = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BirthSites.csv"), DataFrame)
    sweep_df  = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep.csv"), DataFrame)
    strip_dat = load(joinpath(_PATH_TO_DATA, "ModelB-StripFrames.jld2"))

    inc     = birth_df[birth_df.included, :]
    configs = ["freeze", "collapse"]   # the census carries no `stable` births:
                                        # a stable run never nucleates a
                                        # dominant sell cluster to trace.

    # _SERIES_COLORS[1] ("#E69F00") sits one step from _SELL_COLOR ("#D55E00")
    # in the same orange family; freeze-vs-collapse is this figure's central
    # contrast, so freeze takes the pink (_SERIES_COLORS[3]) instead. Collapse
    # keeps _SELL_COLOR deliberately: the collapse config is the one that
    # converts the lattice to Sell, so Sell-orange is semantically load-bearing
    # here, not merely decorative. Stable takes _SERIES_COLORS[5] ("#000000")
    # rather than an arbitrary gray: the binding constraint restricts non-state
    # series to the five _SERIES_COLORS entries, and black reads as neutral
    # gray at this fill alpha while staying unambiguous against freeze's pink
    # and collapse's vermillion. Same mapping in every panel below, so a
    # reader tracks a configuration by colour across the whole figure.
    cfg_color = Dict("stable" => _SERIES_COLORS[5], "freeze" => _SERIES_COLORS[3], "collapse" => _SELL_COLOR)

    # Grid size recovered from the census itself — neither CSV carries a
    # `gridn` column. chebyshev_boundary_distance(r, c, n, n) = min(r-1, n-r,
    # c-1, n-c) = birth_dist, so n - r >= birth_dist and n - c >= birth_dist
    # for every row, with equality for whichever births sit nearest the
    # bottom/right frame. The tightest bound over all 39 rows is exact — 64 —
    # matching GRIDN in Compute-ModelB-BoundaryVsBulk.jl, and the same
    # derivation recovers 32 unchanged from a smoke-mode census.
    gridn    = maximum(max.(inc.birth_row .+ inc.birth_dist, inc.birth_col .+ inc.birth_dist))
    null_pmf = null_shell_pmf(gridn)

    # ── Assert the cited values before plotting anything ───────────────────
    n_nucleated          = nrow(inc)
    boundary_mask        = inc.birth_dist .<= 2
    pooled_boundary_frac = count(boundary_mask) / n_nucleated
    p_null_boundary      = sum(null_pmf[1:2])
    binom_p              = binom_two_sided_p(n_nucleated, count(boundary_mask), p_null_boundary)
    median_birth_distance = median(inc.birth_dist)
    median_birth_size     = median(inc.birth_size)
    ring_attach_collapse  = count((inc.config .== "collapse") .& inc.attached)
    ring_attach_freeze    = count((inc.config .== "freeze")   .& inc.attached)

    @assert n_nucleated == 39 "39 of 40 runs must nucleate within the horizon"
    @assert isapprox(pooled_boundary_frac, 0.077; atol = 0.005) "pooled boundary fraction does not reproduce"
    @assert isapprox(p_null_boundary, 0.125; atol = 0.005) "uniform-null boundary-shell mass does not reproduce"
    @assert isapprox(binom_p, 0.47; atol = 0.02) "binomial p does not reproduce"
    @assert median_birth_distance == 12 "median founding distance must be 12 cells"
    @assert median_birth_size == 1 "median birth size must be a single cell"
    @assert ring_attach_collapse == 6 && ring_attach_freeze == 0 "ring attachment counts do not reproduce"

    med(cfg) = median(sweep_df[sweep_df.config .== cfg, :ratio_at_peak])
    @assert isapprox(med("stable"),   0.022; atol = 0.001) "stable median ratio does not reproduce"
    @assert isapprox(med("freeze"),   0.26;  atol = 0.01)  "freeze median ratio does not reproduce"
    @assert isapprox(med("collapse"), 0.44;  atol = 0.01)  "collapse median ratio does not reproduce"
    @assert maximum(sweep_df[sweep_df.config .== "stable",  :ratio_at_peak]) <
            minimum(sweep_df[sweep_df.config .!= "stable", :ratio_at_peak]) "stable band must not overlap"

    # ── A: birth-to-engulfment market strip (single exemplar run, seed 20) ──
    # Match the compact, full-width montage idiom used by the two Model A
    # crossover figures: all four snapshots occupy one row and one heatmap
    # subplot. Time labels are overlaid inside their own tiles, rather than
    # consuming a separate header band. A translucent white backing keeps
    # each label legible over the noisy three-state lattice.
    frames5   = strip_dat["fig5/frames"]
    steps5    = strip_dat["fig5/steps"]
    birth5    = strip_dat["fig5/birth"]
    outlines5 = strip_dat["fig5/outlines"]

    function _fig5_strip_panel(frames::Vector{<:AbstractMatrix}, labels::Vector{String};
                                gap::Int64 = 4, mark = nothing, outlines = nothing)
        canvas = _strip_canvas(frames; gap = gap, header = 0)
        H, W = size(frames[1])
        total_rows, total_cols = size(canvas)
        plt = heatmap(canvas; c = _grid_cgrad(), clims = (0, 2), yflip = true,
                      aspect_ratio = :equal, axis = false, colorbar = false,
                      framestyle = :none, background_color_inside = :white,
                      xlims = (0.5, total_cols + 0.5), ylims = (0.5, total_rows + 0.5),
                      margin = 0Plots.mm, top_margin = 9Plots.mm)
        for (i, lab) in enumerate(labels)
            c0 = (i - 1)*(W + gap)
            box_halfwidth = 12
            cx = c0 + W - box_halfwidth - 2
            plot!(plt, [cx - box_halfwidth, cx + box_halfwidth,
                        cx + box_halfwidth, cx - box_halfwidth],
                       [0.5, 0.5, 8.5, 8.5];
                  seriestype = :shape, fillcolor = :white, fillalpha = 0.82,
                  linealpha = 0, label = "")
            annotate!(plt, cx, 4.5,
                      text(lab, :black, :center, _STRIP_LABEL_FONTSIZE, "helvetica"))
        end
        if mark !== nothing
            tile_i, rc = mark
            c0 = (tile_i - 1)*(W + gap)
            scatter!(plt, [c0 + rc[2]], [rc[1]]; marker = :xcross,
                     markersize = 6, markercolor = :white, markerstrokecolor = :black,
                     markerstrokewidth = 1.4, label = "")
        end
        if outlines !== nothing
            for (i, m) in enumerate(outlines)
                m === nothing && continue
                c0 = (i - 1)*(W + gap)
                xs, ys = _mask_outline_xy(m, c0)
                isempty(xs) && continue
                plot!(plt, xs, ys; seriescolor = :black, linewidth = 1.2, label = "")
            end
        end
        return plt
    end

    stripA_body = _fig5_strip_panel(frames5, ["t = $(s)" for s in steps5];
                                    mark = (1, birth5), outlines = outlines5)
    _panel_letter!(stripA_body, "A")
    stripA = stripA_body

    # ── B: birth-site map (interior-only clusters; freeze + collapse) ──────
    # Legend moved INSIDE (bottom-right): row > 48 & col > 48 (the last
    # quarter of the 64x64 grid in that corner) holds zero births of either
    # config, checked directly against the census — the scatter covers the
    # grid edge-to-edge everywhere else, but this one corner is genuinely
    # clear. `background_color_legend = nothing` keeps it transparent as a
    # second line of defense. An outer legend used to dodge this by drawing
    # in a separate margin region, but that margin made panel B narrower
    # than panel C's undecorated box; an inside legend restores the same
    # plot-area size and shape as panel C.
    pB = plot(; xlims = (1, gridn), ylims = (1, gridn), yflip = true,
              aspect_ratio = :equal, xlabel = "Grid column",
              ylabel = "Grid row",
              legend = :bottomright, background_color_legend = nothing,
              foreground_color_legend = nothing, _panel_kw...)
    plot!(pB, [1, gridn, gridn, 1, 1], [1, 1, gridn, gridn, 1],
          color = :black, lw = 0.8, label = "")
    for cname in configs
        sub = inc[inc.config .== cname, :]
        isempty(sub) && continue
        scatter!(pB, sub.birth_col, sub.birth_row, color = cfg_color[cname],
                 markersize = 5, markerstrokewidth = 0.5, label = "$(cname) (n=$(nrow(sub)))")
    end
    # Zero-size proxy series: adds the pooled total as a third legend row
    # instead of a floating annotation, which collided with the legend box
    # at every position tried against this scatter's edge-to-edge coverage.
    plot!(pB, Float64[], Float64[], seriestype = :scatter, markersize = 0,
          markerstrokewidth = 0, color = :white, label = "n = $(n_nucleated) total")
    _panel_letter!(pB, "B")

    # ── C: pooled birth distance vs. the uniform-interior null ─────────────
    # Full per-shell null curve, not a single flat line at the pooled 0.125:
    # count(d = j) falls off (linearly, in fact) toward the grid centre, since
    # deeper shells enclose a smaller square — the null is genuinely NOT flat
    # across distance, so a flat dashed reference would misstate its shape.
    # The pooled boundary-shell comparison (0.077 vs. 0.125, p = 0.47) is
    # instead called out directly: a shaded region plus on-panel text, so the
    # cumulative figure the paper cites still lands unambiguously.
    dists      = collect(1:length(null_pmf))
    pooled_pmf = [count(==(d), inc.birth_dist) / n_nucleated for d in dists]
    ytop       = 1.3 * maximum(vcat(pooled_pmf, null_pmf))
    pC = plot(; xlabel = "Birth distance (cells)",
              ylabel = "Birth probability",
              ylims = (0, ytop), legend = :topright, _panel_kw...,
              top_margin = 10Plots.mm, bottom_margin = 10Plots.mm,
              left_margin = 8Plots.mm, right_margin = 8Plots.mm)
    vspan!(pC, [0.5, 2.5], color = _HOLD_COLOR, alpha = 0.25, label = "boundary shell (d ≤ 2)")
    bar!(pC, dists, pooled_pmf, color = _SERIES_COLORS[2], fillalpha = 0.7, lw = 0.3,
         bar_width = 0.85, label = "births (n=$(n_nucleated))")
    plot!(pC, dists, null_pmf, color = :black, ls = :dash, lw = 1.6, label = "uniform null")
    annotate!(pC, 0.48 * maximum(dists), 0.55 * ytop,
              text(@sprintf("boundary share\nobserved %.3f; null %.3f\np = %.2f (two-sided)",
                            pooled_boundary_frac, p_null_boundary, binom_p),
                   _ANNOTATION_FONTSIZE, :black, :left))
    _panel_letter!(pC, "C")

    # Ring-attachment timing (formerly panel D, a scatter of attach-vs-birth
    # timing) is no longer plotted in this figure — the strip panel above
    # carries the figure's spatial narrative instead. The counts it would
    # have shown (6 of 19 collapse runs attach pre-onset, never in the 20
    # freeze runs) are still cited in Results text, so `ring_attach_collapse`
    # / `ring_attach_freeze` stay asserted above rather than being dropped
    # along with the panel.

    # The short top row follows the Model A crossover figures; the lower row
    # is close to one half-canvas width tall, so B's square spatial map and
    # C's ordinary axes occupy matching cells instead of visibly different
    # shapes. C's small symmetric padding compensates for B's fixed square
    # aspect, leaving the two rendered axis boxes equal in width and height.
    fig = plot(stripA, pB, pC;
        layout = @layout([a{0.36h}; b c]), size = (900, 714))
    _save_figure(fig, "Fig5-Nucleus.pdf")
    @info "Saved: Fig5-Nucleus.pdf"
end

# =============================================================================
# FigS5-SeedingDetail.pdf (Task 10) — seeding intervention, restyled onto the
# shared style. Formerly ModelB-Nucleation-Seeding.pdf, left in its
# pre-restyle form (titles, no panel letters, ad hoc font sizes) until now.
#
# Colour fix (Task 10 cleanup item + review finding): `arm_color["control"]`
# was "#888888", an out-of-palette raw hex — replaced with `_SERIES_COLORS[5]`
# ("#000000"), the same precedent Task 7 used for the "stable" config (a
# baseline / no-intervention category takes the neutral in-palette colour
# rather than an arbitrary gray).
#
# `edge`/`mid`/`center` were ALSO wrong: "edge" was `_SELL_COLOR` and "center"
# was `_BUY_COLOR`, borrowing reserved Okabe-Ito STATE hues for what are
# purely categorical PLACEMENT arms (Task 9 precedent: categorical arms take
# `_SERIES_COLORS`, reserved hues are only for genuine Buy/Hold/Sell/edge
# quantities). "edge" in Sell-orange additionally collided with the figure's
# own edge-BAND semantics elsewhere in the paper (the boundary ring, coloured
# via `_HOLD_COLOR`/`_SELL_COLOR` in panel C and Fig6/Fig7). Remapped all four
# arms onto `_SERIES_COLORS` alone: control -> [5] (black, unchanged), edge ->
# [2] (blue), center -> [3] (pink/magenta). "mid" keeps its exact existing hue
# but now spells it as `_SERIES_COLORS[1]` instead of the literal "#E69F00" it
# happened to equal, so all four arms read from one named source. Entry [4]
# ("#F0E442", yellow) is deliberately left unused: it is the weakest colour
# against this figure's #F0F0F0 panel background, and with only three
# non-control arms the three strongest entries already give full
# distinguishability without it.
# =============================================================================
let
    seed_df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedingIntervention.csv"), DataFrame)
    traj_df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedingTrajectories.csv"), DataFrame)

    # Geometry and design recovered from the data, not hardcoded, so smoke
    # CSVs (32², 300 steps) draw just as well as production (64², 1500).
    gridn = traj_df.gridn[1]
    @assert all(==(gridn), traj_df.gridn) "mixed gridn in trajectories CSV"
    n_cells = gridn * gridn
    tcols   = sort(filter(c -> occursin(r"^t\d+$", c), names(traj_df)),
                   by = c -> parse(Int, c[2:end]))
    steps   = length(tcols)
    configs = ["freeze", "collapse"]
    arms    = ["control", "edge", "mid", "center"]
    @assert Set(configs) == Set(unique(seed_df.config)) "unexpected config set"
    @assert Set(arms) == Set(unique(seed_df.arm)) "unexpected arm set"
    seeds    = sort(unique(seed_df.seed))
    s_patch  = maximum(seed_df.patch_size)          # control rows carry 0

    arm_color = Dict("control" => _SERIES_COLORS[5], "edge" => _SERIES_COLORS[2],
                     "mid" => _SERIES_COLORS[1], "center" => _SERIES_COLORS[3])

    # (config, seed) → arm → largest-cluster-fraction trajectory
    trajs = Dict{Tuple{String,Int},Dict{String,Vector{Float64}}}()
    for r in eachrow(traj_df)
        d = get!(trajs, (r.config, r.seed), Dict{String,Vector{Float64}}())
        d[r.arm] = [r[c] for c in tcols] ./ n_cells
    end

    # t_on lookup: config × seed × arm → t_on (missing if that run had no onset)
    ton(name, seed, arm) = begin
        sub = seed_df[(seed_df.config .== name) .& (seed_df.seed .== seed) .&
                      (seed_df.arm .== arm), :]
        sub.included[1] ? sub.t_on[1] : missing
    end

    # -----------------------------------------------------------------------
    # (row 1) paired t_on by arm; (row 2) exemplar largest-cluster growth
    # (first seed with full pairs). The six identical 0/20 dominance outcomes
    # are reported in the caption instead of occupying two empty-looking
    # panels. No in-figure titles: the config name (and, for row 2, the
    # exemplar seed) moves to a
    # top-right annotation on every panel instead of depending on row/column
    # position.
    # -----------------------------------------------------------------------
    fig2_panels = Plots.Plot[]
    for cname in configs
        p = plot(; xticks = (1:length(arms), arms),
                 ylabel = "Onset time (steps)",
                 legend = false, _panel_kw...)
        for seed in seeds
            ts = [ton(cname, seed, arm) for arm in arms]
            any(ismissing, ts) && continue
            plot!(p, 1:length(arms), collect(skipmissing(ts)),
                  color = "#BBBBBB", lw = 0.6)
        end
        for (j, arm) in enumerate(arms)
            sub = seed_df[(seed_df.config .== cname) .& (seed_df.arm .== arm) .&
                          seed_df.included, :]
            isempty(sub) && continue
            scatter!(p, fill(j, nrow(sub)), sub.t_on, color = arm_color[arm],
                     markersize = 4, markerstrokewidth = 0)
        end
        annotate!(p, (0.98, 1.06),
                  text("$(cname) (patch s=$(s_patch))", _ANNOTATION_FONTSIZE, :black, :right))
        push!(fig2_panels, p)
    end
    for cname in configs
        # Exemplar: the first seed whose four arms all reached onset (else first seed)
        ex = findfirst(seed -> all(arm -> !ismissing(ton(cname, seed, arm)), arms), seeds)
        ex_seed = isnothing(ex) ? seeds[1] : seeds[ex]
        p = plot(; xlabel = "Simulation step",
                 ylabel = "Largest sell cluster (grid fraction)",
                 legend = :topleft, _panel_kw...)
        for arm in arms
            plot!(p, 1:steps, trajs[(cname, ex_seed)][arm],
                  color = arm_color[arm], lw = 1.6, label = arm)
        end
        annotate!(p, (0.98, 1.06),
                  text("$(cname), seed $(ex_seed)", _ANNOTATION_FONTSIZE, :black, :right))
        push!(fig2_panels, p)
    end

    for (p, letter) in zip(fig2_panels, ["A", "B", "C", "D"])
        _panel_letter!(p, letter)
    end

    fig2 = plot(fig2_panels...; layout = (2, 2), size = (900, 665),
                left_margin = 6Plots.mm, right_margin = 3Plots.mm,
                bottom_margin = 4Plots.mm)
    _save_figure(fig2, "FigS5-SeedingDetail.pdf")
end
