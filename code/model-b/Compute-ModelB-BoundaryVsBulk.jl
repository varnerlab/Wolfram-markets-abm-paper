# Compute-ModelB-BoundaryVsBulk.jl — where does the dominant sell nucleus come
# from: the price-driven edge ring (boundary-seeded) or the interior minority
# mixture (bulk-seeded)?
# Spec: docs/superpowers/specs/2026-07-17-boundary-vs-bulk-seeding-design.md
# Helpers live in BoundaryVsBulk-Lib.jl (unit-tested by Test-BoundaryVsBulk.jl)
# so the algorithms are testable without running sweeps — a deliberate
# refinement of the spec's one-script layout; this remains the sole entry point.
#
# Arm 1 (observational, 40 runs): backward max-overlap lineage from the onset
#   cluster to its birth site; birth distance-to-boundary vs the analytic
#   uniform null (P(d ≤ 2) ≈ 0.125 at 64²); ring-attachment timing.
# Arm 2 (interventional, 160 runs): paired 4-arm patch seeding — control /
#   edge (adjacent to the nearest active ring cell) / mid / center — on a
#   SHARED :custom background per (config, seed), so RNG consumption inside
#   simulate is identical across arms. Patch size is calibrated from arm 1's
#   pooled median birth size.
#
# Definitional notes (deliberate deviations from siblings):
# - STEPS = 1500 (seed sweep used 1000): the budget toggle saw onsets past
#   t = 1000; a 1000-step horizon censors late nucleators.
# - Cluster labeling is INTERIOR-ONLY (the probe/seed sweep labeled the full
#   grid): ring cells are exogenously band-driven. Onset threshold is still
#   5% of the FULL grid, as in the budget toggle.
#
# Writes: code/data/ModelB-Nucleation-BirthSites.csv
#         code/data/ModelB-Nucleation-SeedingIntervention.csv
#         code/figs/ModelB-Nucleation-BirthSites.pdf
#         code/figs/ModelB-Nucleation-Seeding.pdf
#
# Launch: julia -t 8 code/model-b/Compute-ModelB-BoundaryVsBulk.jl
# Smoke:  BVB_SMOKE=1 julia code/model-b/Compute-ModelB-BoundaryVsBulk.jl
#         (tiny grid, low onset threshold — exercises the paths, not the science)
#
# Threading contract (as Stage 2): results land in preallocated vectors
# indexed by work-item id; all file I/O and plotting happen OUTSIDE the
# threaded loop; no un-seeded RNG inside the loop.

include(joinpath(@__DIR__, "Include.jl"))
include(joinpath(@__DIR__, "BoundaryVsBulk-Lib.jl"))

const SMOKE = get(ENV, "BVB_SMOKE", "0") == "1"
SMOKE && @warn "BVB_SMOKE=1 — tiny grid, low onset threshold; outputs are smoke artifacts only"

const P0         = 100.0
const GRIDN      = SMOKE ? 32 : 64
const STEPS      = SMOKE ? 300 : 1500
const SEEDS      = SMOKE ? collect(1:2) : collect(1:20)
const ONSET_FRAC = SMOKE ? 0.01 : 0.05
const N_CELLS    = GRIDN * GRIDN

const CONFIGS = [
    (name = "freeze",   f = 0.20, cash =  500.0),
    (name = "collapse", f = 0.20, cash = 5000.0),
]

function _bvb_config(; f, cash, seed, initial_condition = :balanced_perturbation)
    return build(MyModelBConfiguration, (
        number_of_rows    = GRIDN,
        number_of_cols    = GRIDN,
        steps             = STEPS,
        seed              = seed,
        λ                 = 0.02,
        k                 = 1.0,
        minority_fraction = f,
        edge_band_spread  = 0.5,
        cost_basis_rule   = false,
        initial_cash      = cash,
        P0                = P0,
        initial_condition = initial_condition,
    ))
end

"""Largest interior cluster per step; onset = first step ≥ ONSET_FRAC of grid."""
function _onset(sizes::Vector{Vector{Int}})
    maxcl = [isempty(s) ? 0 : maximum(s) for s in sizes]
    t_on  = findfirst(m -> m >= ONSET_FRAC * N_CELLS, maxcl)
    return t_on, maxcl
end

const _EXCLUDED_BIRTH = (t_on = 0, birth_step = 0, birth_size = 0, birth_row = 0,
                         birth_col = 0, birth_dist = 0, attached = false,
                         attach_step = 0, attached_before_onset = false)

"""Arm 1: run one (config, seed), reduce to a birth-site row."""
function _run_birth(cfg::NamedTuple, seed::Int)
    res = simulate(_bvb_config(f = cfg.f, cash = cfg.cash, seed = seed);
                   snapshot_steps = collect(1:STEPS), verbose = false)
    labels, sizes = label_sequence(res.frames, STEPS)
    t_on, _ = _onset(sizes)
    base = (config = cfg.name, f = cfg.f, cash = cfg.cash, seed = seed)
    isnothing(t_on) && return merge(base, (included = false,), _EXCLUDED_BIRTH)

    chain     = trace_backward(labels, sizes, t_on, argmax(sizes[t_on]))  # argmax → first (lowest-label) maximizer on ties; deterministic
    bt, blab  = chain[1]
    bcells    = cluster_cells(labels[bt], blab)
    bdist     = minimum(chebyshev_boundary_distance(Tuple(cell)..., GRIDN, GRIDN)
                        for cell in bcells)
    at        = attach_step(res.frames, labels, chain, Set(res.edge_coordinates))
    @assert bt <= t_on "birth after onset (cfg=$(cfg.name) seed=$seed)"
    @assert sizes[bt][blab] >= 1 "empty birth cluster (cfg=$(cfg.name) seed=$seed)"
    return merge(base, (included = true, t_on = t_on, birth_step = bt,
                        birth_size = sizes[bt][blab],
                        birth_row  = round(Int, mean(getindex.(bcells, 1))),
                        birth_col  = round(Int, mean(getindex.(bcells, 2))),
                        birth_dist = bdist,
                        attached   = !ismissing(at),
                        attach_step = ismissing(at) ? 0 : at,
                        attached_before_onset = !ismissing(at) && at < t_on))
end

# ---------------------------------------------------------------------------
# Arm 1 sweep: 2 configs x seeds
# ---------------------------------------------------------------------------
birth_items = [(cfg = cfg, seed = seed) for cfg in CONFIGS for seed in SEEDS]
@info "Arm 1: birth-site tracking" n_runs = length(birth_items) grid = GRIDN steps = STEPS threads = Threads.nthreads()

birth_rows = Vector{Union{Nothing,NamedTuple}}(nothing, length(birth_items))
Threads.@threads :dynamic for i in eachindex(birth_items)
    birth_rows[i] = _run_birth(birth_items[i].cfg, birth_items[i].seed)
end
@assert all(!isnothing, birth_rows)

birth_df = DataFrame()
for r in birth_rows
    push!(birth_df, r)
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BirthSites.csv"), birth_df)
@info "Saved: ModelB-Nucleation-BirthSites.csv"

# Headline statistic: births with d ≤ 2 vs the analytic uniform null
const _NULL_PMF    = null_shell_pmf(GRIDN)
const _P_NEAR_NULL = sum(_NULL_PMF[1:2])

for name in [c.name for c in CONFIGS] ∪ ["pooled"]
    sub = name == "pooled" ? birth_df[birth_df.included, :] :
                             birth_df[(birth_df.config .== name) .& birth_df.included, :]
    n = nrow(sub)
    if n == 0
        @info "Arm 1 summary: $(name)" n = 0
        continue
    end
    k = count(sub.birth_dist .<= 2)
    @info "Arm 1 summary: $(name)" n = n frac_d_le_2 = round(k / n, digits = 3) null_frac = round(_P_NEAR_NULL, digits = 3) binom_p = round(binom_two_sided_p(n, k, _P_NEAR_NULL), sigdigits = 3) median_birth_dist = median(sub.birth_dist) median_birth_size = median(sub.birth_size) median_birth_step = median(sub.birth_step) attached_before_onset = count(sub.attached_before_onset)
end

# Patch size for arm 2, calibrated from the pooled median birth size (spec §2)
const _INCLUDED = birth_df[birth_df.included, :]
const S_PATCH   = nrow(_INCLUDED) == 0 ? 3 : patch_side(median(_INCLUDED.birth_size))
@info "Arm 2 patch calibration" s_patch = S_PATCH n_included = nrow(_INCLUDED)

# ---------------------------------------------------------------------------
# Arm 2: paired patch seeding — control / edge / mid / center on a shared
# :custom background. All four arms pass :custom, so RNG consumption inside
# simulate is identical across arms (same ring, same bands, same minority
# placement); arms differ ONLY in the stamped cells. The stamped patch
# overwrites the few background cells under it — identical background
# otherwise, negligible and location-dependent by construction.
# ---------------------------------------------------------------------------
const ARMS = ["control", "edge", "mid", "center"]

"""Arm 2: run the four paired arms for one (config, seed)."""
function _run_seeding(cfg::NamedTuple, seed::Int)
    base_cfg = _bvb_config(f = cfg.f, cash = cfg.cash, seed = seed)
    # Replicates simulate's draw (1) exactly: fresh Xoshiro(seed), edge sampling first
    ring = build_edge_coordinates(GRIDN, GRIDN, base_cfg.edge_fraction, Xoshiro(seed))
    # Shared background from a dedicated stream (spec §2)
    bg = build_initial_grid(base_cfg, Xoshiro(10_000 + seed))
    centers = Dict(
        "edge"   => edge_patch_center(ring, S_PATCH, GRIDN, GRIDN),
        "mid"    => clamp_patch_center(GRIDN ÷ 4 + 1, GRIDN ÷ 2, S_PATCH, GRIDN, GRIDN),
        "center" => clamp_patch_center(GRIDN ÷ 2, GRIDN ÷ 2, S_PATCH, GRIDN, GRIDN))

    rows      = NamedTuple[]
    trajs     = Dict{String,Vector{Float64}}()   # per-arm largest-cluster fraction
    ref_edges = nothing
    ref_k     = nothing
    n_warn    = 0
    for arm in ARMS
        grid = copy(bg)
        arm != "control" && stamp_patch!(grid, centers[arm], S_PATCH)
        res = simulate(_bvb_config(f = cfg.f, cash = cfg.cash, seed = seed,
                                   initial_condition = :custom);
                       initial_grid = grid, snapshot_steps = collect(1:STEPS),
                       verbose = false)
        if isnothing(ref_edges)
            ref_edges = res.edge_coordinates
            ref_k     = res.edge_k
            @assert ref_edges == ring "pre-computed ring mismatch (cfg=$(cfg.name) seed=$seed)"
        else
            @assert res.edge_coordinates == ref_edges "arm ring divergence (cfg=$(cfg.name) seed=$seed arm=$arm)"
            @assert res.edge_k == ref_k "arm band divergence (cfg=$(cfg.name) seed=$seed arm=$arm)"
        end

        labels, sizes = label_sequence(res.frames, STEPS)
        t_on, maxcl   = _onset(sizes)
        trajs[arm]    = maxcl ./ N_CELLS
        pc = arm == "control" ? CartesianIndex{2}[] :
                                patch_cells_square(centers[arm], S_PATCH)

        # Dominance requires the backward chain to reach exactly t = 1; gap-1
        # tolerance cannot bridge a blink AT t = 1 (t-2 = 0), so this is a
        # conservative (under-)count. The forward trace below corroborates it.
        dominant = false
        if !isnothing(t_on) && arm != "control"
            chain    = trace_backward(labels, sizes, t_on, argmax(sizes[t_on]))  # argmax → first (lowest-label) maximizer on ties; deterministic
            bt, blab = chain[1]
            if bt == 1
                bset     = Set(cluster_cells(labels[bt], blab))
                dominant = any(in(bset), pc)
            end
        end
        fwd = arm == "control" ? (max_size = 0, last_alive = 0, chain = Tuple{Int,Int16}[]) :
                                 trace_forward(labels, sizes, pc, STEPS)
        alive_at_onset = !isnothing(t_on) && fwd.last_alive >= t_on
        # Forward/backward disagreement is REPORTED, not asserted (spec §3):
        # the tracers follow max-overlap in opposite directions and can
        # legitimately route through different branches.
        (arm != "control" && dominant && !alive_at_onset) && (n_warn += 1)

        push!(rows, (config = cfg.name, f = cfg.f, cash = cfg.cash, seed = seed,
                     arm = arm, patch_size = arm == "control" ? 0 : S_PATCH,
                     patch_row = arm == "control" ? 0 : centers[arm][1],
                     patch_col = arm == "control" ? 0 : centers[arm][2],
                     included = !isnothing(t_on),
                     t_on = isnothing(t_on) ? 0 : t_on,
                     front_final = maxcl[STEPS] / N_CELLS,
                     dominant_from_patch = dominant,
                     patch_lineage_max = fwd.max_size,
                     patch_alive_at_onset = alive_at_onset))
    end
    return (rows = rows, n_warn = n_warn, trajs = trajs)
end

# ---------------------------------------------------------------------------
# Arm 2 sweep: one work item per (config, seed); each runs its 4 arms serially
# so the pairing assertions live inside the item
# ---------------------------------------------------------------------------
seed_items = [(cfg = cfg, seed = seed) for cfg in CONFIGS for seed in SEEDS]
@info "Arm 2: paired patch seeding" n_items = length(seed_items) arms = length(ARMS) s_patch = S_PATCH

seed_results = Vector{Union{Nothing,NamedTuple}}(nothing, length(seed_items))
Threads.@threads :dynamic for i in eachindex(seed_items)
    seed_results[i] = _run_seeding(seed_items[i].cfg, seed_items[i].seed)
end
@assert all(!isnothing, seed_results)

total_warn = sum(r.n_warn for r in seed_results)
total_warn > 0 && @warn "forward/backward lineage disagreement" n = total_warn

trajs_map = Dict{Tuple{String,Int},Dict{String,Vector{Float64}}}()
for (item, r) in zip(seed_items, seed_results)
    trajs_map[(item.cfg.name, item.seed)] = r.trajs
end

seed_df = DataFrame()
for r in seed_results, row in r.rows
    push!(seed_df, row)
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedingIntervention.csv"), seed_df)
@info "Saved: ModelB-Nucleation-SeedingIntervention.csv"

# ---------------------------------------------------------------------------
# Arm 2 statistics: paired onset advance (sign-flip permutation, as the
# budget toggle) and dominance rates; McNemar-style edge-vs-center contrast
# ---------------------------------------------------------------------------
# NOTE: the per-(config, arm) sign-flip tests form a 6-test family with NO
# multiplicity correction (matches the budget-toggle sibling). A nominal
# p = 0.02 does not survive Bonferroni (0.05/6 ≈ 0.0083); treat these as
# exploratory and correct (or flag as uncorrected) in any paper claim.
function _signflip_p(dv::Vector{Float64}; n_draws::Int = 20_000)
    isempty(dv) && return NaN
    rng  = Xoshiro(7)
    dobs = abs(mean(dv))
    hits = 0
    for _ in 1:n_draws
        hits += abs(mean(dv .* rand(rng, (-1.0, 1.0), length(dv)))) >= dobs
    end
    return hits / n_draws
end

"""t_on lookup: config × seed × arm → t_on (missing if that run had no onset)."""
function _ton(df, name, seed, arm)
    sub = df[(df.config .== name) .& (df.seed .== seed) .& (df.arm .== arm), :]
    return sub.included[1] ? sub.t_on[1] : missing
end

for cfg in CONFIGS
    for arm in ARMS[2:end]
        dts   = Float64[]
        for seed in SEEDS
            tc = _ton(seed_df, cfg.name, seed, "control")
            ta = _ton(seed_df, cfg.name, seed, arm)
            (ismissing(tc) || ismissing(ta)) && continue
            push!(dts, float(tc - ta))          # >0 ⇒ patch advanced onset
        end
        dom = seed_df[(seed_df.config .== cfg.name) .& (seed_df.arm .== arm), :dominant_from_patch]
        @info "Arm 2 summary: $(cfg.name)/$(arm)" n_pairs = length(dts) median_onset_advance = isempty(dts) ? NaN : median(dts) sign_pos = count(>(0), dts) signflip_p = _signflip_p(dts) dominance = "$(count(dom))/$(length(dom))"
    end
    # McNemar-style paired edge-vs-center dominance contrast
    b = 0; c = 0
    for seed in SEEDS
        de = seed_df[(seed_df.config .== cfg.name) .& (seed_df.seed .== seed) .& (seed_df.arm .== "edge"),   :dominant_from_patch][1]
        dc = seed_df[(seed_df.config .== cfg.name) .& (seed_df.seed .== seed) .& (seed_df.arm .== "center"), :dominant_from_patch][1]
        de && !dc && (b += 1)
        !de && dc && (c += 1)
    end
    p_mcn = b + c == 0 ? NaN : binom_two_sided_p(b + c, b, 0.5)
    @info "Arm 2 edge-vs-center dominance: $(cfg.name)" edge_only = b center_only = c mcnemar_p = p_mcn
end

# ---------------------------------------------------------------------------
# Figure 1 — birth sites: (a) scatter on the grid outline; (b, c) birth
# distance vs the analytic null PMF per config; (d) attachment timing
# ---------------------------------------------------------------------------
const _CFG_COLOR = Dict("freeze" => _BUY_COLOR, "collapse" => _SELL_COLOR)

inc = birth_df[birth_df.included, :]

p_map = plot(title = "birth sites (n=$(nrow(inc)))", titlefont = 10,
             xlims = (1, GRIDN), ylims = (1, GRIDN), yflip = true,
             aspect_ratio = :equal, guidefont = 8, tickfont = 7,
             legend = :topright, legendfontsize = 6,
             xlabel = "col", ylabel = "row")
plot!(p_map, [1, GRIDN, GRIDN, 1, 1], [1, 1, GRIDN, GRIDN, 1],
      color = :black, lw = 0.8, label = "")
for cfg in CONFIGS
    sub = inc[inc.config .== cfg.name, :]
    isempty(sub) && continue
    scatter!(p_map, sub.birth_col, sub.birth_row, color = _CFG_COLOR[cfg.name],
             markersize = 5, markerstrokewidth = 0.5, label = cfg.name)
end

dist_panels = Plots.Plot[]
for cfg in CONFIGS
    sub = inc[inc.config .== cfg.name, :]
    p = plot(title = "$(cfg.name): birth distance", titlefont = 10,
             xlabel = "Chebyshev distance to frame", ylabel = "probability",
             guidefont = 8, tickfont = 7, legend = :topright, legendfontsize = 6)
    plot!(p, 1:length(_NULL_PMF), _NULL_PMF, color = "#888888", lw = 1.8,
          label = "uniform null")
    if !isempty(sub)
        w = fill(1 / nrow(sub), nrow(sub))
        histogram!(p, sub.birth_dist, weights = w, bins = 0.5:1:(GRIDN ÷ 2),
                   color = _CFG_COLOR[cfg.name], fillalpha = 0.5, lw = 0.5,
                   label = "births (n=$(nrow(sub)))")
    end
    push!(dist_panels, p)
end

p_att = plot(title = "ring attachment", titlefont = 10,
             xlabel = "attach step − birth step", ylabel = "onset − birth (steps)",
             guidefont = 8, tickfont = 7, legend = :topright, legendfontsize = 6)
for cfg in CONFIGS
    sub = inc[(inc.config .== cfg.name) .& inc.attached, :]
    isempty(sub) && continue
    scatter!(p_att, sub.attach_step .- sub.birth_step, sub.t_on .- sub.birth_step,
             color = _CFG_COLOR[cfg.name], markersize = 5, markerstrokewidth = 0.5,
             label = "$(cfg.name) ($(count(sub.attached_before_onset))/$(nrow(sub)) pre-onset)")
end

fig1 = plot(p_map, dist_panels..., p_att; layout = (2, 2), size = (1150, 950),
            left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
            plot_title = "Where the dominant sell nucleus is born (interior-only clusters)",
            plot_titlefontsize = 11)
savefig(fig1, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-BirthSites.pdf"))
@info "Saved: ModelB-Nucleation-BirthSites.pdf"

# ---------------------------------------------------------------------------
# Figure 2 — seeding intervention: (a) paired t_on by arm; (b) dominance
# rates; (c) exemplar largest-cluster growth (first seed with full pairs)
# ---------------------------------------------------------------------------
const _ARM_COLOR = Dict("control" => "#888888", "edge" => _SELL_COLOR,
                        "mid" => "#E69F00", "center" => _BUY_COLOR)

fig2_panels = Plots.Plot[]
for cfg in CONFIGS
    p = plot(title = "$(cfg.name): onset by arm", titlefont = 10,
             xticks = (1:length(ARMS), ARMS), ylabel = "onset step",
             guidefont = 8, tickfont = 7, legend = false)
    for seed in SEEDS
        ts = [_ton(seed_df, cfg.name, seed, arm) for arm in ARMS]
        any(ismissing, ts) && continue
        plot!(p, 1:length(ARMS), collect(skipmissing(ts)),
              color = "#BBBBBB", lw = 0.6)
    end
    for (j, arm) in enumerate(ARMS)
        sub = seed_df[(seed_df.config .== cfg.name) .& (seed_df.arm .== arm) .&
                      seed_df.included, :]
        isempty(sub) && continue
        scatter!(p, fill(j, nrow(sub)), sub.t_on, color = _ARM_COLOR[arm],
                 markersize = 4, markerstrokewidth = 0)
    end
    push!(fig2_panels, p)
end
for cfg in CONFIGS
    p = plot(title = "$(cfg.name): patch dominance", titlefont = 10,
             xticks = (1:3, ARMS[2:end]), ylabel = "dominant-from-patch rate",
             ylims = (0, 1.05), guidefont = 8, tickfont = 7, legend = false)
    for (j, arm) in enumerate(ARMS[2:end])
        dom = seed_df[(seed_df.config .== cfg.name) .& (seed_df.arm .== arm), :dominant_from_patch]
        bar!(p, [j], [count(dom) / max(length(dom), 1)],
             color = _ARM_COLOR[arm], fillalpha = 0.7, bar_width = 0.55)
    end
    push!(fig2_panels, p)
end
for cfg in CONFIGS
    # Exemplar: the first seed whose four arms all reached onset (else first seed)
    ex = findfirst(seed -> all(arm -> !ismissing(_ton(seed_df, cfg.name, seed, arm)), ARMS), SEEDS)
    ex_seed = isnothing(ex) ? SEEDS[1] : SEEDS[ex]
    p = plot(title = "$(cfg.name): exemplar growth (seed $(ex_seed))", titlefont = 10,
             xlabel = "step", ylabel = "largest cluster / grid",
             guidefont = 8, tickfont = 7, legend = :topleft, legendfontsize = 6)
    for arm in ARMS
        plot!(p, 1:STEPS, trajs_map[(cfg.name, ex_seed)][arm],
              color = _ARM_COLOR[arm], lw = 1.6, label = arm)
    end
    push!(fig2_panels, p)
end

fig2 = plot(fig2_panels...; layout = (3, 2), size = (1150, 1250),
            left_margin = 6Plots.mm, bottom_margin = 4Plots.mm,
            plot_title = "Patch seeding at a distance gradient (paired; s=$(S_PATCH))",
            plot_titlefontsize = 11)
savefig(fig2, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-Seeding.pdf"))
@info "Saved: ModelB-Nucleation-Seeding.pdf"

@info "Arm 2 multiplicity note" n_paired_tests = 6 bonferroni_alpha = round(0.05 / 6, sigdigits = 2)

@info "Compute-ModelB-BoundaryVsBulk.jl complete."
