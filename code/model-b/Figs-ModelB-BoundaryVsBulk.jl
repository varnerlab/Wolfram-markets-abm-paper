# Figs-ModelB-BoundaryVsBulk.jl — figures for the boundary-vs-bulk seeding
# analysis, drawn ENTIRELY from the three committed CSVs (no simulation):
#   code/data/ModelB-Nucleation-BirthSites.csv
#   code/data/ModelB-Nucleation-SeedingIntervention.csv
#   code/data/ModelB-Nucleation-SeedingTrajectories.csv
# Included by Compute-ModelB-BoundaryVsBulk.jl at the end of a sweep, and
# standalone-rerunnable from the repo root:
#   julia code/model-b/Figs-ModelB-BoundaryVsBulk.jl
# (regenerates both PDFs from whatever CSVs are on disk — production or smoke).
#
# Writes: code/figs/ + paper-arxiv/figs/
#
# The body is a `let` block (locals only, no consts) so including it after
# the compute sweep cannot collide with the sweep's global constants.

isdefined(Main, :_PATH_TO_DATA)  || include(joinpath(@__DIR__, "Include.jl"))
isdefined(Main, :null_shell_pmf) || include(joinpath(@__DIR__, "BoundaryVsBulk-Lib.jl"))

let
    birth_df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BirthSites.csv"), DataFrame)
    seed_df  = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedingIntervention.csv"), DataFrame)
    traj_df  = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedingTrajectories.csv"), DataFrame)

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
    null_pmf = null_shell_pmf(gridn)

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
    # Figure 1 — birth sites: (a) scatter on the grid outline; (b, c) birth
    # distance vs the analytic null PMF per config; (d) attachment timing
    # -----------------------------------------------------------------------
    inc = birth_df[birth_df.included, :]

    p_map = plot(title = "birth sites (n=$(nrow(inc)))", titlefont = 10,
                 xlims = (1, gridn), ylims = (1, gridn), yflip = true,
                 aspect_ratio = :equal, guidefont = 8, tickfont = 7,
                 legend = :topright, legendfontsize = 6,
                 xlabel = "col", ylabel = "row")
    plot!(p_map, [1, gridn, gridn, 1, 1], [1, 1, gridn, gridn, 1],
          color = :black, lw = 0.8, label = "")
    for cname in configs
        sub = inc[inc.config .== cname, :]
        isempty(sub) && continue
        scatter!(p_map, sub.birth_col, sub.birth_row, color = cfg_color[cname],
                 markersize = 5, markerstrokewidth = 0.5, label = cname)
    end

    dist_panels = Plots.Plot[]
    for cname in configs
        sub = inc[inc.config .== cname, :]
        p = plot(title = "$(cname): birth distance", titlefont = 10,
                 xlabel = "Chebyshev distance to frame", ylabel = "probability",
                 guidefont = 8, tickfont = 7, legend = :topright, legendfontsize = 6)
        plot!(p, 1:length(null_pmf), null_pmf, color = "#888888", lw = 1.8,
              label = "uniform null")
        if !isempty(sub)
            w = fill(1 / nrow(sub), nrow(sub))
            histogram!(p, sub.birth_dist, weights = w, bins = 0.5:1:(gridn ÷ 2),
                       color = cfg_color[cname], fillalpha = 0.5, lw = 0.5,
                       label = "births (n=$(nrow(sub)))")
        end
        push!(dist_panels, p)
    end

    p_att = plot(title = "ring attachment", titlefont = 10,
                 xlabel = "attach step − birth step", ylabel = "onset − birth (steps)",
                 guidefont = 8, tickfont = 7, legend = :topright, legendfontsize = 6)
    for cname in configs
        sub = inc[(inc.config .== cname) .& inc.attached, :]
        isempty(sub) && continue
        scatter!(p_att, sub.attach_step .- sub.birth_step, sub.t_on .- sub.birth_step,
                 color = cfg_color[cname], markersize = 5, markerstrokewidth = 0.5,
                 label = "$(cname) ($(count(sub.attached_before_onset))/$(nrow(sub)) pre-onset)")
    end

    fig1 = plot(p_map, dist_panels..., p_att; layout = (2, 2), size = (1150, 950),
                left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
                plot_title = "Where the dominant sell nucleus is born (interior-only clusters)",
                plot_titlefontsize = 11)
    _save_figure(fig1, "ModelB-Nucleation-BirthSites.pdf")
    @info "Saved: ModelB-Nucleation-BirthSites.pdf"

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
