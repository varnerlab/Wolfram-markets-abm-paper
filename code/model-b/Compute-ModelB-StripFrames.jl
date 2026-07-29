# Compute-ModelB-StripFrames.jl — captures deterministic 64x64 Model B grid
# frames for the market-strip panel figures:
#   Fig 5 — nucleation exemplar (single collapse run, birth -> onset -> after)
#   Fig 6 — freeze vs collapse, same seed, strips aligned to each arm's onset
#   Fig 7 — control vs x10 cash injection, same seed, bit-identical pre-toggle
#
# Every seed and every strip step below is DATA-DRIVEN from the committed
# campaign CSVs (median-representative selection; nothing hand-picked) — see
# .superpowers/sdd/2026-07-29-market-strip-figures/task-3-brief.md. This
# script reads those CSVs read-only; it does not regenerate or overwrite any
# existing file in code/data/. Its sole output is code/data/ModelB-StripFrames.jld2.
#
# Fix round 1 (amended plan, docs/superpowers/plans/2026-07-29-market-strip-figures.md
# Task 3): (1) Fig 5's seed pick is restricted to nucleated collapse rows
# with birth_dist >= 10 (a comfortably interior birth) before the
# argmin-|onset - median| pick, median still taken over ALL nucleated
# collapse rows; (2) every saved frame also gets an outline BitMatrix mask
# under a matching .../outlines key — Fig 5's is the birth-lineage chain,
# Figs 6/7's is that frame's own largest sell cluster.
#
# Reads (read-only):
#   code/data/ModelB-Nucleation-BirthSites.csv               (Fig 5 seed pick)
#   code/data/ModelB-Nucleation-SeedSweep-Trajectories.csv   (Fig 6 seed pick)
#   code/data/ModelB-Nucleation-BudgetToggle.csv             (Fig 7 seed pick)
#
# The onset used to CUT the strips (as opposed to the onset used only to
# PICK the seed) is always recomputed fresh from a full-grid, all-cells
# cluster-labeling scan whose BFS/scan order matches
# Compute-ModelB-NucleationSeeds.jl (:48-74) / Compute-ModelB-BudgetToggle.jl
# (:76-102) — never read off a CSV column — so the strip is exactly aligned
# to the run that produced it.
#
# Writes: code/data/ModelB-StripFrames.jld2 (nested keys; see bottom of file)
#
# Launch: julia --project=code -t auto code/model-b/Compute-ModelB-StripFrames.jl

include(joinpath(@__DIR__, "Include.jl"))
using Dates

const P0         = 100.0
const GRIDN      = 64
const STEPS      = 1500
const N_CELLS    = GRIDN * GRIDN
const ONSET_FRAC = 0.05

include(joinpath(@__DIR__, "NucleationConfigs-Lib.jl"))

# Connected components of sell (state 2) cells, 4-neighbour, full grid.
# Same BFS/scan order as Compute-ModelB-NucleationSeeds.jl:48-74 (also used
# as-is by Compute-ModelB-BudgetToggle.jl:76-102), refactored to also return
# a per-cell label matrix (0 = not sell) so outline masks can be built from
# it. `_sell_clusters` is kept as a thin wrapper so onset detection is
# unchanged (same n_clust/max_sz semantics, same scan order => same result).
function _label_sell_clusters(grid::Matrix{Int64})
    nr, nc = size(grid)
    labels = zeros(Int, nr, nc)
    sizes  = Int[]
    for r in 1:nr, c in 1:nc
        (grid[r, c] == 2 && labels[r, c] == 0) || continue
        id    = length(sizes) + 1
        sz    = 0
        queue = [(r, c)]
        labels[r, c] = id
        while !isempty(queue)
            cr, cc = popfirst!(queue)
            sz += 1
            for (dr, dc) in ((-1, 0), (1, 0), (0, -1), (0, 1))
                nr2, nc2 = cr + dr, cc + dc
                (1 <= nr2 <= nr && 1 <= nc2 <= nc) || continue
                if grid[nr2, nc2] == 2 && labels[nr2, nc2] == 0
                    labels[nr2, nc2] = id
                    push!(queue, (nr2, nc2))
                end
            end
        end
        push!(sizes, sz)
    end
    return labels, sizes
end

"""Connected components of sell cells, reduced to (n_clust, max_sz)."""
function _sell_clusters(grid::Matrix{Int64})
    _, sizes = _label_sell_clusters(grid)
    return length(sizes), isempty(sizes) ? 0 : maximum(sizes)
end

"""First step in 1:STEPS where the largest sell cluster >= ONSET_FRAC*N_CELLS,
or 0 if none. `res.frames` must hold every step 1:STEPS (i.e. simulate was
called with snapshot_steps = collect(1:STEPS))."""
function _onset_step(res)
    for t in 1:STEPS
        _, m = _sell_clusters(res.frames[t])
        m >= ONSET_FRAC * N_CELLS && return t
    end
    return 0
end

"""BitMatrix mask of the largest sell cluster in `grid` (all-false if none)."""
function _largest_cluster_mask(grid::Matrix{Int64})::BitMatrix
    labels, sizes = _label_sell_clusters(grid)
    isempty(sizes) && return falses(size(grid))
    best_id = argmax(sizes)
    return labels .== best_id
end

"""Birth-lineage chain of outline masks, one per frame in `frames` (same
order/length). Tile 1's mask is just the birth cell. Each later tile's mask
is the sell cluster (via _label_sell_clusters) with maximal cell-overlap
against the PREVIOUS tile's mask; if no sell cluster overlaps at all (the
lineage died, or the previous mask was itself already empty), the mask is
all-false and stays all-false for every subsequent tile (zero overlap with
an empty mask is unavoidable). Ties in overlap count broken by lowest
cluster id (scan order)."""
function _lineage_masks(frames::Vector{Matrix{Int64}}, birth_row::Int, birth_col::Int)
    nr, nc = size(frames[1])
    masks  = Vector{BitMatrix}(undef, length(frames))
    prev   = falses(nr, nc)
    prev[birth_row, birth_col] = true
    masks[1] = prev
    for i in 2:length(frames)
        labels, sizes = _label_sell_clusters(frames[i])
        if isempty(sizes) || !any(prev)
            masks[i] = falses(nr, nc)
        else
            best_ov, best_id = 0, 0
            for id in 1:length(sizes)
                ov = count(@. (labels == id) & prev)
                ov > best_ov && ((best_ov, best_id) = (ov, id))
            end
            masks[i] = best_ov > 0 ? (labels .== best_id) : falses(nr, nc)
        end
        prev = masks[i]
    end
    return masks
end

# =============================================================================
# Fig 5 — collapse nucleation exemplar
# =============================================================================
# Among nucleated ("included") collapse rows of BirthSites, restrict to those
# with birth_dist >= 10 (a comfortably interior birth — median birth_dist is
# 10-12; the exemplar must be typical in the dimension the panel is about),
# THEN pick the seed whose onset (t_on) is nearest the median onset — that
# median is taken over ALL nucleated collapse rows (not just the filtered
# subset), per the amended selection rule. birth_step/t_on/birth_row/
# birth_col are taken directly from the CSV (no recompute needed here — the
# frames are pure CA state, unaffected by which script's onset-detection
# convention produced the CSV row).

birth_df   = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BirthSites.csv"), DataFrame)
collapse_b = birth_df[(birth_df.config .== "collapse") .& birth_df.included, :]
collapse_b_interior = collapse_b[collapse_b.birth_dist .>= 10, :]

med_onset_fig5 = median(collapse_b.t_on)
fig5_idx       = argmin(abs.(collapse_b_interior.t_on .- med_onset_fig5))
fig5_seed      = collapse_b_interior.seed[fig5_idx]
fig5_birth     = collapse_b_interior.birth_step[fig5_idx]
fig5_onset     = collapse_b_interior.t_on[fig5_idx]
fig5_row       = collapse_b_interior.birth_row[fig5_idx]
fig5_col       = collapse_b_interior.birth_col[fig5_idx]
fig5_dist      = collapse_b_interior.birth_dist[fig5_idx]

@info "Fig5 seed selection (median-representative, nucleated collapse rows with birth_dist>=10)" n_all_nucleated = nrow(collapse_b) n_interior_candidates = nrow(collapse_b_interior) median_t_on_all = med_onset_fig5 seed = fig5_seed birth_step = fig5_birth t_on = fig5_onset birth_row = fig5_row birth_col = fig5_col birth_dist = fig5_dist

fig5_steps = Int64[fig5_birth, (fig5_birth + fig5_onset) ÷ 2, fig5_onset, min(fig5_onset + 200, STEPS)]
@info "Fig5 strip steps" steps = fig5_steps

fig5_res    = simulate(_probe_config(f = 0.20, cash = 5000.0, seed = fig5_seed);
                       snapshot_steps = fig5_steps, verbose = false)
fig5_frames  = Matrix{Int64}[fig5_res.frames[t] for t in fig5_steps]
fig5_outlines = _lineage_masks(fig5_frames, Int(fig5_row), Int(fig5_col))
@info "Fig5 lineage outline sizes (cells per tile)" sizes = [count(m) for m in fig5_outlines]

# =============================================================================
# Fig 6 — freeze vs collapse, same seed
# =============================================================================
# Seed pick uses the SeedSweep per-step trajectories (SeedSweep.csv itself
# carries no onset column) to derive, per (config, seed), the first step the
# full-grid largest sell cluster crosses ONSET_FRAC. Among seeds with a
# finite onset in BOTH freeze and collapse, pick the seed minimizing the
# summed distance of both onsets to their own per-config medians (computed
# over each config's own finite-onset population).
#
# The strip-cutting onset is then RECOMPUTED from a fresh STEPS=1500 run
# using _probe_config (not read off the sweep, which only ran to STEPS=1000
# and used a different config-builder path) — see module docstring.

traj_df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep-Trajectories.csv"), DataFrame)

"""Per-seed onset (first step maxcluster_frac >= ONSET_FRAC), Dict seed => onset or missing."""
function _seed_onsets(df::DataFrame, config_name::String)
    sub = df[df.config .== config_name, :]
    out = Dict{Int,Union{Int,Missing}}()
    for seed in sort(unique(sub.seed))
        s   = sort(sub[sub.seed .== seed, :], :step)
        idx = findfirst(>=(ONSET_FRAC), s.maxcluster_frac)
        out[seed] = isnothing(idx) ? missing : s.step[idx]
    end
    return out
end

freeze_onsets_sweep   = _seed_onsets(traj_df, "freeze")
collapse_onsets_sweep = _seed_onsets(traj_df, "collapse")

common_seeds = sort([s for s in keys(freeze_onsets_sweep)
                     if haskey(collapse_onsets_sweep, s) &&
                        !ismissing(freeze_onsets_sweep[s]) &&
                        !ismissing(collapse_onsets_sweep[s])])

med_freeze_sweep   = median([v for v in values(freeze_onsets_sweep) if !ismissing(v)])
med_collapse_sweep = median([v for v in values(collapse_onsets_sweep) if !ismissing(v)])

fig6_dists = [abs(freeze_onsets_sweep[s] - med_freeze_sweep) +
              abs(collapse_onsets_sweep[s] - med_collapse_sweep) for s in common_seeds]
fig6_seed  = common_seeds[argmin(fig6_dists)]

@info "Fig6 seed selection (median-representative, finite onset in both arms, from SeedSweep trajectories)" n_common_seeds = length(common_seeds) median_freeze_onset = med_freeze_sweep median_collapse_onset = med_collapse_sweep seed = fig6_seed freeze_onset_sweep = freeze_onsets_sweep[fig6_seed] collapse_onset_sweep = collapse_onsets_sweep[fig6_seed]

"""Run one Fig6 arm at cash `cash`, seed `seed`: fresh STEPS=1500 run, fresh
onset recompute (full-grid _sell_clusters), 4-step strip [t_on, +100, +250, +400],
outline mask per tile = that frame's own largest sell cluster."""
function _fig6_arm(cash::Float64, seed::Int, label::String)
    res  = simulate(_probe_config(f = 0.20, cash = cash, seed = seed);
                    snapshot_steps = collect(1:STEPS), verbose = false)
    t_on = _onset_step(res)
    t_on == 0 && error("Fig6/$label: no onset found within STEPS=$STEPS (seed=$seed, cash=$cash)")
    steps = Int64[t_on, t_on + 100, t_on + 250, t_on + 400]
    @assert steps[end] <= STEPS "Fig6/$label strip exceeds STEPS horizon (seed=$seed, t_on=$t_on, last=$(steps[end]))"
    frames   = Matrix{Int64}[res.frames[t] for t in steps]
    outlines = [_largest_cluster_mask(f) for f in frames]
    @info "Fig6/$label recomputed onset" seed = seed cash = cash t_on = t_on steps = steps outline_sizes = [count(m) for m in outlines]
    return (frames = frames, steps = steps, t_on = t_on, outlines = outlines)
end

fig6_freeze   = _fig6_arm(500.0, fig6_seed, "freeze")
fig6_collapse = _fig6_arm(5000.0, fig6_seed, "collapse")

# =============================================================================
# Fig 7 — control vs x10 cash injection, same seed
# =============================================================================
# Seed pick uses BudgetToggle.csv directly (it already carries onset/dv).
# Among included injection pairs, restrict to the ACCELERATING subset
# (dv = v_toggle - v_ctrl > 0 — the hypothesis-confirming direction) and pick
# the seed whose dv is nearest the median dv of that same accelerating
# subset. Ties (structurally possible whenever the accelerating subset has
# even size, since the two middle values are always equidistant from their
# mean) are broken by lowest seed number via argmin's first-occurrence rule,
# since the DataFrame preserves ascending-seed row order.

toggle_df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BudgetToggle.csv"), DataFrame)
injection = toggle_df[(toggle_df.direction .== "injection") .& toggle_df.included, :]
accel     = injection[injection.dv .> 0, :]

med_dv    = median(accel.dv)
fig7_idx  = argmin(abs.(accel.dv .- med_dv))
fig7_seed = accel.seed[fig7_idx]

@info "Fig7 seed selection (median-representative, accelerating injection pairs)" n_included = nrow(injection) n_accelerating = nrow(accel) median_dv = med_dv seed = fig7_seed dv = accel.dv[fig7_idx] onset_csv = accel.onset[fig7_idx]

"""Rebuild the injection pair exactly as Compute-ModelB-BudgetToggle.jl's
_run_pair (:121-151): control finds t_on, toggled run scales cash x10 at
t_on via the intervention hook, bit-identity asserted at frame t_on-1."""
function _fig7_pair(seed::Int)
    ctrl = simulate(_toggle_config(cash = 500.0, seed = seed);
                    snapshot_steps = collect(1:STEPS), verbose = false)
    t_on = _onset_step(ctrl)
    t_on == 0 && error("Fig7: no onset found within STEPS=$STEPS for control (seed=$seed)")

    hook = (t, books) -> (t == t_on && (books.cash .*= 10.0); nothing)
    tog  = simulate(_toggle_config(cash = 500.0, seed = seed);
                    snapshot_steps = collect(1:STEPS), verbose = false,
                    intervention = hook)

    @assert ctrl.frames[t_on - 1] == tog.frames[t_on - 1] "pre-toggle frame divergence (seed=$seed, t_on=$t_on)"

    steps = Int64[t_on - 1, t_on + 100, t_on + 250, t_on + 400]
    @assert steps[end] <= STEPS "Fig7 strip exceeds STEPS horizon (seed=$seed, t_on=$t_on, last=$(steps[end]))"

    control_frames   = Matrix{Int64}[ctrl.frames[t] for t in steps]
    injection_frames = Matrix{Int64}[tog.frames[t]  for t in steps]
    control_outlines   = [_largest_cluster_mask(f) for f in control_frames]
    injection_outlines = [_largest_cluster_mask(f) for f in injection_frames]
    @info "Fig7 recomputed onset + bit-identity check" seed = seed t_on = t_on steps = steps pre_toggle_identical = true control_outline_sizes = [count(m) for m in control_outlines] injection_outline_sizes = [count(m) for m in injection_outlines]
    return (t_on = t_on, steps = steps,
            control_frames = control_frames, injection_frames = injection_frames,
            control_outlines = control_outlines, injection_outlines = injection_outlines)
end

fig7 = _fig7_pair(fig7_seed)

# =============================================================================
# Save
# =============================================================================
meta_created = """
Created $(now()) by Compute-ModelB-StripFrames.jl (GRIDN=$GRIDN, STEPS=$STEPS, P0=$P0).
Fig5: seed=$fig5_seed (median-representative among $(nrow(collapse_b_interior)) nucleated collapse rows with birth_dist>=10, out of $(nrow(collapse_b)) total nucleated; median t_on over ALL nucleated rows=$med_onset_fig5); steps=$fig5_steps (birth=$fig5_birth, mid, t_on=$fig5_onset, t_on+200); birth site=(row=$fig5_row, col=$fig5_col), birth_dist=$fig5_dist; outline = birth-lineage chain.
Fig6: seed=$fig6_seed (median-representative among $(length(common_seeds)) seeds with finite onset in both freeze and collapse per SeedSweep trajectories; median_freeze=$med_freeze_sweep, median_collapse=$med_collapse_sweep); freeze recomputed t_on=$(fig6_freeze.t_on) steps=$(fig6_freeze.steps); collapse recomputed t_on=$(fig6_collapse.t_on) steps=$(fig6_collapse.steps); outline = per-frame largest sell cluster.
Fig7: seed=$fig7_seed (median-representative among $(nrow(accel)) accelerating (dv>0) injection pairs out of $(nrow(injection)) included; median dv=$med_dv); recomputed t_on=$(fig7.t_on) steps=$(fig7.steps); pre-toggle bit-identity asserted at t_on-1; outline = per-frame largest sell cluster.
"""

out_path = joinpath(_PATH_TO_DATA, "ModelB-StripFrames.jld2")
jldopen(out_path, "w") do file
    file["fig5/frames"]   = fig5_frames
    file["fig5/steps"]    = fig5_steps
    file["fig5/birth"]    = (Int(fig5_row), Int(fig5_col))
    file["fig5/seed"]     = Int(fig5_seed)
    file["fig5/outlines"] = fig5_outlines

    file["fig6/freeze/frames"]   = fig6_freeze.frames
    file["fig6/freeze/steps"]    = fig6_freeze.steps
    file["fig6/freeze/seed"]     = Int(fig6_seed)
    file["fig6/freeze/outlines"] = fig6_freeze.outlines

    file["fig6/collapse/frames"]   = fig6_collapse.frames
    file["fig6/collapse/steps"]    = fig6_collapse.steps
    file["fig6/collapse/seed"]     = Int(fig6_seed)
    file["fig6/collapse/outlines"] = fig6_collapse.outlines

    file["fig7/control/frames"]   = fig7.control_frames
    file["fig7/control/steps"]    = fig7.steps
    file["fig7/control/seed"]     = Int(fig7_seed)
    file["fig7/control/outlines"] = fig7.control_outlines

    file["fig7/injection/frames"]   = fig7.injection_frames
    file["fig7/injection/steps"]    = fig7.steps
    file["fig7/injection/seed"]     = Int(fig7_seed)
    file["fig7/injection/outlines"] = fig7.injection_outlines

    file["meta/created"] = meta_created
end
@info "Saved: ModelB-StripFrames.jld2" path = out_path

@info "Compute-ModelB-StripFrames.jl complete."
