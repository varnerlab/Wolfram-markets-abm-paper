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
    # Four snapshots (StripFrames.jld2, `fig5/*`) trace one collapse run from
    # a single marked founding cell (tile 1, × mark) to a dominant orange
    # (Sell) domain — the figure's title claim made visible before any
    # statistic is shown. `_strip_panel` (StripPanels.jl) builds the seamless
    # heatmap montage and its own "t = <step>" tile captions; `outlines`
    # (the birth-lineage cluster mask per tile) traces that single growing
    # domain across all four tiles.
    #
    # 2x2 arrangement, ONE merged canvas (round 2 fix): round 1 (git history,
    # commit 010dcc4) built the two tile rows as two SEPARATE `_strip_panel`
    # heatmaps stacked via `@layout([a; b])` — visually correct top-to-bottom
    # ordering (row 1: t = 203, 265; row 2: t = 328, 528) but each
    # `_strip_panel` call is its own GR subplot, and GR/Plots.jl reserves a
    # per-subplot margin floor of order 70-90px at 110dpi around every
    # individual subplot regardless of that subplot's own `margin = 0mm`
    # setting — the exact disease Fig2-Combined.jl's snapshot montage and
    # Fig-ModelA-FiniteSize.jl's panel A hit and fixed the same way (see
    # their own comments). Paid twice (once per row), that floor was the
    # large gap the author flagged between the two tile rows.
    #
    # The fix follows that same precedent: compose all four frames into ONE
    # Float64 canvas with thin NaN gutters and draw it with a SINGLE heatmap
    # call, so the per-subplot floor is paid once for the whole panel, not
    # once per row. Unlike Fig2's montage (one header shared by every row,
    # since every row there shares the same column labels), this grid's two
    # rows show DIFFERENT time steps, so each row keeps its own header band —
    # `_fig5_2x2_canvas`/`_fig5_2x2_panel` below, local to this file
    # (StripPanels.jl is untouched, exactly like Fig2/Fig3's own local
    # montage helpers): [header 1 ("t = 203"/"t = 265"); tile row 1; a thin
    # NaN row gutter; header 2 ("t = 328"/"t = 528"); tile row 2]. `header =
    # 22` and 12pt labels keep the house strip-label convention
    # (`_strip_canvas`'s own default, StripPanels.jl); `gap = 4` (between the
    # two tiles in a row) and `rowgap = 4` (between the two tile rows) are
    # both "a few cells" thin, the same idiom Fig2's snapshot montage and
    # Fig3's finite-size montage use for their own gutters.
    #
    # The birth-lineage outline masks and the birth-cross mark are re-derived
    # in this merged canvas's own coordinates: `_mask_outline_xy` (from
    # StripPanels.jl, unmodified — it only ever offsets the COLUMN axis by a
    # caller-supplied `x0`) is called once per tile with that tile's column
    # offset, and the ROW offset (which a single-row `_strip_panel` call adds
    # as one constant `header`) is generalized here to a per-tile `row_y0[i]`:
    # row-1 tiles sit under header band 1, row-2 tiles sit under header band
    # 2. Checked tile-by-tile against the round-1 render (the committed
    # Fig5-Nucleus.pdf at HEAD before this change): same outline shape and
    # position relative to its own tile's Sell(orange) cluster in all four
    # tiles, same birth-cross cell in tile 1.
    #
    # Panel letter: `_panel_letter!` cannot be used directly on the strip
    # (its yflip branch would land the letter in the tile-caption header
    # band instead of above the panel); `_strip_letter_row` (StripPanels.jl)
    # builds the blank lettered row and the two are composed into one plot
    # object that fills the outer layout's "a" slot — see its docstring for
    # the full rationale, recovered from the Fig2-Combined.jl montage
    # precedent (:59-89).
    frames5   = strip_dat["fig5/frames"]
    steps5    = strip_dat["fig5/steps"]
    birth5    = strip_dat["fig5/birth"]
    outlines5 = strip_dat["fig5/outlines"]

    # `_fig5_2x2_canvas`/`_fig5_2x2_panel`: local montage helpers, deliberately
    # NOT added to StripPanels.jl (every other call site there is a single
    # tile ROW with one shared header; this figure alone needs a two-row grid
    # with a header PER row, so it stays a one-off here rather than growing
    # the shared renderer's API for a single caller).
    function _fig5_2x2_canvas(frames::Vector{<:AbstractMatrix};
                               gap::Int64 = 4, header::Int64 = 22, rowgap::Int64 = 4)
        H, W = size(frames[1])
        row1_y0 = header                              # tile-row-1 top offset (canvas rows)
        row2_y0 = header + H + rowgap + header         # tile-row-2 top offset (canvas rows)
        total_rows = row2_y0 + H
        total_cols = 2*W + gap
        canvas = fill(NaN, total_rows, total_cols)
        for (i, F) in enumerate(frames[1:2])
            c0 = (i - 1)*(W + gap)
            canvas[(row1_y0+1):(row1_y0+H), (c0+1):(c0+W)] .= Float64.(F)
        end
        for (i, F) in enumerate(frames[3:4])
            c0 = (i - 1)*(W + gap)
            canvas[(row2_y0+1):(row2_y0+H), (c0+1):(c0+W)] .= Float64.(F)
        end
        return canvas, H, W, row1_y0, row2_y0
    end

    function _fig5_2x2_panel(frames::Vector{<:AbstractMatrix},
                              labels_row1::Vector{String}, labels_row2::Vector{String};
                              gap::Int64 = 4, header::Int64 = 22, rowgap::Int64 = 4,
                              mark = nothing, outlines = nothing)
        canvas, H, W, row1_y0, row2_y0 =
            _fig5_2x2_canvas(frames; gap = gap, header = header, rowgap = rowgap)
        total_rows, total_cols = size(canvas)
        plt = heatmap(canvas; c = _grid_cgrad(), clims = (0, 2), yflip = true,
                      aspect_ratio = :equal, axis = false, colorbar = false,
                      framestyle = :none, background_color_inside = :white,
                      xlims = (0.5, total_cols + 0.5), ylims = (0.5, total_rows + 0.5),
                      margin = 0Plots.mm)
        for (i, lab) in enumerate(labels_row1)
            cx = (i - 1)*(W + gap) + W/2
            annotate!(plt, cx, header*0.5, text(lab, :black, :center, 12, "helvetica"))
        end
        for (i, lab) in enumerate(labels_row2)
            cx = (i - 1)*(W + gap) + W/2
            annotate!(plt, cx, row2_y0 - header*0.5, text(lab, :black, :center, 12, "helvetica"))
        end
        row_y0 = (row1_y0, row1_y0, row2_y0, row2_y0)   # per-tile (1..4) row offset
        if mark !== nothing
            tile_i, rc = mark
            c0 = mod(tile_i - 1, 2)*(W + gap)
            scatter!(plt, [c0 + rc[2]], [row_y0[tile_i] + rc[1]]; marker = :xcross,
                     markersize = 6, markercolor = :white, markerstrokecolor = :black,
                     markerstrokewidth = 1.4, label = "")
        end
        if outlines !== nothing
            for (i, m) in enumerate(outlines)
                m === nothing && continue
                c0     = mod(i - 1, 2)*(W + gap)
                xs, ys = _mask_outline_xy(m, c0)
                isempty(xs) && continue
                plot!(plt, xs, ys .+ row_y0[i]; seriescolor = :black, linewidth = 1.2, label = "")
            end
        end
        return plt
    end

    # header = 13 / rowgap = 3 (defaults are 22/4): at the 2x2 scale a
    # 22-unit band renders ~170px deep and reads as the row gap the author
    # flagged; 13 units keeps the 12pt labels clear of the tiles while the
    # grid stays visually tight. Fewer canvas rows also means the
    # height-bound tiles render larger for the same panel share.
    stripA_body = _fig5_2x2_panel(frames5,
        ["t = $(s)" for s in steps5[1:2]], ["t = $(s)" for s in steps5[3:4]];
        mark = (1, birth5), outlines = outlines5, header = 13, rowgap = 3)
    _letterA = _strip_letter_row("A")
    # Letter fraction 0.08h (not 0.12h): matches the Fig6/Fig7 strip-anchor
    # convention and gives the body a little more of panel A's row.
    stripA = plot(_letterA, stripA_body; layout = @layout([a{0.08h}; b]))

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
              aspect_ratio = :equal, xlabel = "col", ylabel = "row",
              legend = :bottomright, background_color_legend = nothing,
              foreground_color_legend = nothing, _panel_kw..., left_margin = 14.8Plots.mm)
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
    pC = plot(; xlabel = "Distance from frame (cells)", ylabel = "probability",
              ylims = (0, ytop), legend = :topright, _panel_kw..., right_margin = 40.7Plots.mm)
    vspan!(pC, [0.5, 2.5], color = _HOLD_COLOR, alpha = 0.25, label = "boundary shell (d ≤ 2)")
    bar!(pC, dists, pooled_pmf, color = _SERIES_COLORS[2], fillalpha = 0.7, lw = 0.3,
         bar_width = 0.85, label = "births (n=$(n_nucleated))")
    plot!(pC, dists, null_pmf, color = :black, ls = :dash, lw = 1.6, label = "uniform null")
    annotate!(pC, 0.55 * maximum(dists), 0.55 * ytop,
              text(@sprintf("observed %.3f vs. null %.3f\np = %.2f (two-sided)",
                            pooled_boundary_frac, p_null_boundary, binom_p),
                   8, :black, :left))
    _panel_letter!(pC, "C")

    # Ring-attachment timing (formerly panel D, a scatter of attach-vs-birth
    # timing) is no longer plotted in this figure — the strip panel above
    # carries the figure's spatial narrative instead. The counts it would
    # have shown (6 of 19 collapse runs attach pre-onset, never in the 20
    # freeze runs) are still cited in Results text, so `ring_attach_collapse`
    # / `ring_attach_freeze` stay asserted above rather than being dropped
    # along with the panel.

    # 2x2 rework (author choice): the canvas width stays 1160pt (unchanged
    # from the 4-tile version) so absolute font sizes stay on the same scale
    # as every other strip figure, but the canvas is now much taller
    # (1160x1430, up from 1160x1120) and panel A takes most of that growth
    # (0.8252h vs the old 0.50h) so the two 2-tile rows render as large as
    # the float page allows. Two tiles per row, at full canvas width, are
    # inherently HEIGHT-bound rather than width-bound (a 2-tile row's data
    # aspect is ~132/86, about half a 4-tile row's ~268/86, so at any given
    # row height a 2-tile row's width-matching box is narrower than the
    # canvas) — the tiles print with blank margins left/right rather than
    # touching the canvas edges, and row height (hence tile size) is set by
    # how much of the canvas panel A is given, not by the canvas width.
    # 1430pt total is an empirical ceiling, not a round number: 1520pt
    # overflowed the float page by 15.6pt ("Float too large for page" in
    # Paper_v1.log) once placed at 0.95\linewidth; 1430pt clears it with
    # ~15pt of slack, matching the safety margin Fig6-GrowthGating.pdf's own
    # two-row strip pair runs at (that figure's page is 632/648pt full).
    # Panel A's 0.8252h share (b/c row = 250pt) is itself an empirical
    # legibility floor, not a derived number: b/c's cell stops being close
    # to square (b's aspect_ratio = :equal square vs c's edge-to-edge fill,
    # same tension as the original 4-tile design's fix below) as the row
    # shrinks, but both panels' legends and in-panel text stayed clear of
    # the data through 250pt; at 190pt the B legend started crowding its
    # own scatter points and at 130pt the C in-panel annotation collided
    # with the C legend, so 250pt is the smallest row height tried that
    # rendered cleanly at both extremes.
    #
    # Panel B's aspect_ratio = :equal (a spatial row/col map) forces a
    # SQUARE plot box inside whatever cell it is given, while panel C (an
    # ordinary bar/line panel) fills its cell edge to edge; the original
    # 4-tile design's b/c row height (half the canvas, 560pt against a
    # 580pt-wide cell) was tuned so the cell itself was close to square,
    # letting C's natural fill and B's forced square coincide. The 2x2
    # design's much smaller 250pt b/c row against the same 580pt-wide cell
    # cannot keep that exact match (250 far from 580), so B's square now
    # sits inside a visibly wider cell than it fills; both panels stayed
    # legible and close enough in apparent size through visual review, but
    # this is the one respect in which the 2x2 canvas is a looser match to
    # the original square-cell recipe.
    fig = plot(stripA, pB, pC;
        layout = @layout([a{0.8252h}; b c]), size = (1160, 1430))
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
    # (row 1) paired t_on by arm; (row 2) dominance rates; (row 3) exemplar
    # largest-cluster growth (first seed with full pairs). No in-figure
    # titles: the config name (and, for row 3, the exemplar seed) moves to a
    # top-right annotation on every panel instead of depending on row/column
    # position.
    # -----------------------------------------------------------------------
    fig2_panels = Plots.Plot[]
    for cname in configs
        p = plot(; xticks = (1:length(arms), arms), ylabel = "onset step",
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
        annotate!(p, (0.98, 1.06), text("$(cname) (patch s=$(s_patch))", 8, :black, :right))
        push!(fig2_panels, p)
    end
    for cname in configs
        p = plot(; xticks = (1:3, arms[2:end]), ylabel = "dominant-from-patch rate",
                 ylims = (0, 1.05), legend = false, _panel_kw...)
        for (j, arm) in enumerate(arms[2:end])
            dom = seed_df[(seed_df.config .== cname) .& (seed_df.arm .== arm), :dominant_from_patch]
            bar!(p, [j], [count(dom) / max(length(dom), 1)],
                 color = arm_color[arm], fillalpha = 0.7, bar_width = 0.55)
        end
        # Every one of the 20 seeds, in every arm, comes back exactly zero (the
        # bars themselves are true but invisible at zero height); this panel
        # states the raw count so an empty-looking panel does not read as a
        # rendering defect. Results prose reports this same raw 0/20 count,
        # citing Figure S5; no Wilson bound appears anywhere in the paper.
        annotate!(p, (0.5, 0.5), text("0/20 dominant from patch\nin every arm", 9, :black, :center))
        annotate!(p, (0.98, 1.06), text(cname, 8, :black, :right))
        push!(fig2_panels, p)
    end
    for cname in configs
        # Exemplar: the first seed whose four arms all reached onset (else first seed)
        ex = findfirst(seed -> all(arm -> !ismissing(ton(cname, seed, arm)), arms), seeds)
        ex_seed = isnothing(ex) ? seeds[1] : seeds[ex]
        p = plot(; xlabel = "step", ylabel = "largest cluster / grid",
                 legend = :outertopright, _panel_kw...)
        for arm in arms
            plot!(p, 1:steps, trajs[(cname, ex_seed)][arm],
                  color = arm_color[arm], lw = 1.6, label = arm)
        end
        annotate!(p, (0.98, 1.06), text("$(cname), seed $(ex_seed)", 8, :black, :right))
        push!(fig2_panels, p)
    end

    for (p, letter) in zip(fig2_panels, ["A", "B", "C", "D", "E", "F"])
        _panel_letter!(p, letter)
    end

    fig2 = plot(fig2_panels...; layout = (3, 2), size = (1150, 1250),
                left_margin = 6Plots.mm, bottom_margin = 4Plots.mm)
    _save_figure(fig2, "FigS5-SeedingDetail.pdf")
end
