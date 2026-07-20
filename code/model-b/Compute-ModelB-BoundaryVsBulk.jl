# Compute-ModelB-BoundaryVsBulk.jl — where does the dominant sell nucleus come
# from: the price-driven edge ring (boundary-seeded) or the interior minority
# mixture (bulk-seeded)?
# Spec: docs/superpowers/specs/2026-07-17-boundary-vs-bulk-seeding-design.md
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

    chain     = trace_backward(labels, sizes, t_on, argmax(sizes[t_on]))
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
