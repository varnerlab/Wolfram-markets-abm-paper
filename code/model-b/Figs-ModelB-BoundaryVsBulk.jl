# Figs-ModelB-BoundaryVsBulk.jl — figures for the boundary-vs-bulk seeding
# analysis, drawn ENTIRELY from committed CSVs (no simulation):
#   code/data/ModelB-Nucleation-BirthSites.csv
#   code/data/ModelB-Nucleation-SeedSweep.csv          (Task 7: panel A medians)
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
#   1) Fig5-Nucleus.pdf     — Task 7: the crash nucleus is a single spatial
#      domain, born in the interior. Reads BirthSites.csv + SeedSweep.csv.
#   2) ModelB-Nucleation-Seeding.pdf — the seeding-intervention figure, left
#      in its pre-restyle form; Task 10 turns it into FigS5-SeedingDetail.pdf.

isdefined(Main, :_PATH_TO_DATA)  || include(joinpath(@__DIR__, "Include.jl"))
isdefined(Main, :null_shell_pmf) || include(joinpath(@__DIR__, "BoundaryVsBulk-Lib.jl"))
using Printf

# =============================================================================
# Fig5-Nucleus.pdf (Task 7)
# =============================================================================
let
    birth_df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BirthSites.csv"), DataFrame)
    sweep_df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep.csv"), DataFrame)

    inc     = birth_df[birth_df.included, :]
    configs = ["freeze", "collapse"]   # the census carries no `stable` births:
                                        # a stable run never nucleates a
                                        # dominant sell cluster to trace.

    # _SERIES_COLORS[1] ("#E69F00") sits one step from _SELL_COLOR ("#D55E00")
    # in the same orange family; freeze-vs-collapse is this figure's central
    # contrast, so freeze takes the pink (_SERIES_COLORS[3]) instead. Collapse
    # keeps _SELL_COLOR deliberately: the collapse config is the one that
    # converts the lattice to Sell, so Sell-orange is semantically load-bearing
    # here, not merely decorative. Same mapping in every panel below, so a
    # reader tracks a configuration by colour across the whole figure.
    cfg_color = Dict("stable" => "#666666", "freeze" => _SERIES_COLORS[3], "collapse" => _SELL_COLOR)

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

    # ── A: per-seed ratio-at-peak by configuration, medians marked ─────────
    _jitter_rng = MersenneTwister(20260728)   # fixed local RNG: deterministic
                                               # reruns without touching global state.
    CONFIGS_A = ["stable", "freeze", "collapse"]
    pA = plot(; xticks = (1:3, CONFIGS_A), ylabel = "largest cluster / total sell at peak",
              ylims = (0, 1.0), legend = false, _panel_kw...)
    for (j, cfg) in enumerate(CONFIGS_A)
        vals = sweep_df[sweep_df.config .== cfg, :ratio_at_peak]
        boxplot!(pA, fill(j, length(vals)), vals, color = cfg_color[cfg], fillalpha = 0.35,
                 lw = 1.2, outliers = false, bar_width = 0.5)
        scatter!(pA, j .+ 0.28 .* (rand(_jitter_rng, length(vals)) .- 0.5), vals,
                 color = cfg_color[cfg], markersize = 3, markerstrokewidth = 0)
        annotate!(pA, j, maximum(vals) + 0.07,
                  text(@sprintf("median %.3f", med(cfg)), 8, :black, :center))
    end
    _panel_letter!(pA, "A")

    # ── B: birth-site map (interior-only clusters; freeze + collapse) ──────
    pB = plot(; xlims = (1, gridn), ylims = (1, gridn), yflip = true,
              aspect_ratio = :equal, xlabel = "col", ylabel = "row",
              legend = :topright, _panel_kw...)
    plot!(pB, [1, gridn, gridn, 1, 1], [1, 1, gridn, gridn, 1],
          color = :black, lw = 0.8, label = "")
    for cname in configs
        sub = inc[inc.config .== cname, :]
        isempty(sub) && continue
        scatter!(pB, sub.birth_col, sub.birth_row, color = cfg_color[cname],
                 markersize = 5, markerstrokewidth = 0.5, label = "$(cname) (n=$(nrow(sub)))")
    end
    # Zero-size proxy series: adds the pooled total as a third legend row
    # (matching panel D's proxy-entry technique) instead of a floating
    # annotation, which collided with the legend box at every position tried
    # against this scatter's edge-to-edge coverage.
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
              ylims = (0, ytop), legend = :topright, _panel_kw...)
    vspan!(pC, [0.5, 2.5], color = _HOLD_COLOR, alpha = 0.25, label = "boundary shell (d ≤ 2)")
    bar!(pC, dists, pooled_pmf, color = _SERIES_COLORS[2], fillalpha = 0.7, lw = 0.3,
         bar_width = 0.85, label = "births (n=$(n_nucleated))")
    plot!(pC, dists, null_pmf, color = :black, ls = :dash, lw = 1.6, label = "uniform null")
    annotate!(pC, 0.55 * maximum(dists), 0.55 * ytop,
              text(@sprintf("observed %.3f vs. null %.3f\np = %.2f (two-sided)",
                            pooled_boundary_frac, p_null_boundary, binom_p),
                   8, :black, :left))
    _panel_letter!(pC, "C")

    # ── D: ring-attachment timing ───────────────────────────────────────────
    # Collapse alone carries points; freeze carries an explicit zero-count
    # legend entry (a proxy series with empty data) so the "0 of 20" is
    # asserted ON the figure rather than merely implied by absent markers.
    pD = plot(; xlabel = "attach step − birth step", ylabel = "onset − birth (steps)",
              legend = :bottomright, _panel_kw...)
    for cname in configs
        sub   = inc[(inc.config .== cname) .& inc.attached, :]
        total = count(==(cname), inc.config)
        if isempty(sub)
            plot!(pD, Float64[], Float64[], seriestype = :scatter, color = cfg_color[cname],
                  markersize = 5, markerstrokewidth = 0.5, label = "$(cname) (0/$(total) attached)")
        else
            scatter!(pD, sub.attach_step .- sub.birth_step, sub.t_on .- sub.birth_step,
                     color = cfg_color[cname], markersize = 5, markerstrokewidth = 0.5,
                     label = "$(cname) ($(nrow(sub))/$(total) attached, $(count(sub.attached_before_onset)) pre-onset)")
        end
    end
    _panel_letter!(pD, "D")

    fig = plot(pA, pB, pC, pD; layout = (2, 2), size = (1100, 850))
    _save_figure(fig, "Fig5-Nucleus.pdf")
    @info "Saved: Fig5-Nucleus.pdf"
end

# =============================================================================
# ModelB-Nucleation-Seeding.pdf — seeding intervention (unchanged; Task 10
# restyles this into FigS5-SeedingDetail.pdf)
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

    cfg_color = Dict("freeze" => _BUY_COLOR, "collapse" => _SELL_COLOR)
    arm_color = Dict("control" => "#888888", "edge" => _SELL_COLOR,
                     "mid" => "#E69F00", "center" => _BUY_COLOR)

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
    # Figure 2 — seeding intervention: (a) paired t_on by arm; (b) dominance
    # rates; (c) exemplar largest-cluster growth (first seed with full pairs)
    # -----------------------------------------------------------------------
    fig2_panels = Plots.Plot[]
    for cname in configs
        p = plot(title = "$(cname): onset by arm", titlefont = 10,
                 xticks = (1:length(arms), arms), ylabel = "onset step",
                 guidefont = 8, tickfont = 7, legend = false)
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
        push!(fig2_panels, p)
    end
    for cname in configs
        p = plot(title = "$(cname): patch dominance", titlefont = 10,
                 xticks = (1:3, arms[2:end]), ylabel = "dominant-from-patch rate",
                 ylims = (0, 1.05), guidefont = 8, tickfont = 7, legend = false)
        for (j, arm) in enumerate(arms[2:end])
            dom = seed_df[(seed_df.config .== cname) .& (seed_df.arm .== arm), :dominant_from_patch]
            bar!(p, [j], [count(dom) / max(length(dom), 1)],
                 color = arm_color[arm], fillalpha = 0.7, bar_width = 0.55)
        end
        push!(fig2_panels, p)
    end
    for cname in configs
        # Exemplar: the first seed whose four arms all reached onset (else first seed)
        ex = findfirst(seed -> all(arm -> !ismissing(ton(cname, seed, arm)), arms), seeds)
        ex_seed = isnothing(ex) ? seeds[1] : seeds[ex]
        p = plot(title = "$(cname): exemplar growth (seed $(ex_seed))", titlefont = 10,
                 xlabel = "step", ylabel = "largest cluster / grid",
                 guidefont = 8, tickfont = 7, legend = :topleft, legendfontsize = 6)
        for arm in arms
            plot!(p, 1:steps, trajs[(cname, ex_seed)][arm],
                  color = arm_color[arm], lw = 1.6, label = arm)
        end
        push!(fig2_panels, p)
    end

    fig2 = plot(fig2_panels...; layout = (3, 2), size = (1150, 1250),
                left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
                plot_title = "Patch seeding at a distance gradient (paired; s=$(s_patch))",
                plot_titlefontsize = 11)
    _save_figure(fig2, "ModelB-Nucleation-Seeding.pdf")
    @info "Saved: ModelB-Nucleation-Seeding.pdf"
end
