# Boundary-vs-Bulk Seeding — Design Spec

**Date:** 2026-07-17
**Predecessors:** `code/model-b/Compute-ModelB-NucleationSeeds.jl` (seed
sweep, `8e90fb0`) and `code/model-b/Compute-ModelB-BudgetToggle.jl` (budget
toggle + edge-ring trace, `1045602`/`ba5a8fb`).
**Scope:** One new analysis script answering where Model B's dominant sell
nucleus comes from — the price-driven edge ring or the bulk interior — with
an observational arm (birth-site tracking across the seed ensemble) and an
interventional arm (paired patch-seeding at a distance gradient). No changes
to `code/src/`.

## Goal

The budget-toggle work established that budgets reach the growing front only
through the price → contrarian edge band → boundary-ring conduit, and the
edge trace showed the loose-config ring *selling* before onset (~0.35
declining to 0 at onset). That raises the question this analysis settles: is
the nucleus itself boundary-seeded (born at or fed by the ring) or
bulk-seeded (born in the interior from the minority-rule mixture), with the
ring only modulating growth afterwards? The answer determines whether the
paper's arrested-nucleation story is "the boundary creates and gates the
crash" or "the bulk creates it; the boundary gates it."

## Approach (chosen)

Backward-lineage tracing: label interior sell clusters at every step, take
the largest cluster at onset, and trace it backward by maximal cell overlap
to its birth site; then calibrate a paired patch-seeding intervention from
the observed birth statistics. Alternatives considered and rejected: a full
forward lineage forest through merges/splits (richer — captures failed
nucleation attempts — but substantially more bookkeeping, and merge/split
identity is ambiguous in exactly the crowded early phase that matters), and
a minimal threshold-snapshot design with no lineage (cluster identity can
jump between snapshots, so birth-site attribution is noisy and
ring-attachment timing is unavailable).

## Shared configuration

Both arms use the two nucleating probe configs (stable is excluded — nothing
nucleates):

| name     | f    | initial_cash | λ    | k   | spread | cost_basis | P0  |
|----------|------|--------------|------|-----|--------|------------|-----|
| freeze   | 0.20 | 500          | 0.02 | 1.0 | 0.5    | false      | 100 |
| collapse | 0.20 | 5000         | 0.02 | 1.0 | 0.5    | false      | 100 |

Grid 64×64, seeds 1:20, `snapshot_steps = 1:STEPS` (dense frames, processed
per-run inside the threaded loop and discarded).

**STEPS = 1500** — a deliberate deviation from the seed sweep's 1000: the
budget toggle observed onsets up to t ≈ 1044, so a 1000-step horizon censors
late nucleators and shrinks the birth-site sample. The script header notes
this.

**Onset:** first t where the largest interior sell cluster ≥ 5% of the full
grid (`ONSET_FRAC = 0.05`, N = 64²) — same threshold and normalization as
the budget toggle, but on interior-only labeling (below); the script header
notes the definitional difference. Runs that never reach onset by STEPS are
recorded with `included = false` and excluded from birth/onset statistics.

**Interior-only cluster labeling:** BFS, 4-neighbour, over rows/cols 2..63
only, state == Sell. Ring cells are exogenously band-driven, so including
them would conflate forcing with response; boundary attachment is measured
separately (below). This is the one reduction difference from the probe/seed
sweep's full-grid `_sell_clusters`.

## 1. Observational arm — birth-site tracking (40 runs)

**Backward lineage.** Let C(t_on) be the largest interior cluster at onset.
For t descending from t_on: the predecessor of C(t) is the cluster at t−1
with maximal cell overlap |C(t) ∩ C(t−1)|; ties broken by larger cluster
size, then row-major order of the cluster's first cell (deterministic). If
no cluster at t−1 overlaps, check t−2 before declaring birth (gap-1
tolerance: the herding rule's oscillatory phase can blink a small domain off
for one step). Birth = the earliest step reached by the chain.

**Per-run record** (`ModelB-Nucleation-BirthSites.csv`, one row per
config × seed): `config, f, cash, seed, included, t_on, birth_step,
birth_size, birth_row, birth_col` (centroid, rounded), `birth_dist` — the
minimum over birth-cluster cells of the Chebyshev distance to the frame,
d(r,c) = min(r−1, 64−r, c−1, 64−c) — plus `attach_step` (first lineage step
at which any lineage cell is 4-adjacent to an *active* ring cell whose
current state is Sell; missing if never) and `attached_before_onset`.

**Null model (no extra runs).** Under uniform placement on the 62×62
interior, the shell counts are analytic: cells with d ≥ j form a square of
side 64 − 2j, so count(d = j) = (64−2j)² − (62−2j)² for j = 1..31 (interior
cells have d ≥ 1). Concretely P(d ≤ 2) = (62² − 58²)/62² ≈ 0.125.

**Headline statistic:** observed fraction of births with d ≤ 2 vs the null
0.125, exact two-sided binomial test, per config and pooled; plus the full
birth-distance histogram against the null PMF, and the attachment timing
(attach_step − birth_step, and attached_before_onset rate) as the
mechanism-timing readout.

## 2. Interventional arm — paired patch seeding (160 runs)

**Patch size calibration (staged).** From arm 1's pooled median birth_size
m: the patch is s×s with s the odd integer in {3, 5} whose square is closest
to m (tie → 3). The stamped nucleus is one the dynamics itself considers
newborn, not a super-critical slab.

**Four arms per (config, seed)** — control (no patch) and three placements
of an all-Sell s×s patch at a distance gradient (coordinates derived from
GRIDN so smoke mode works):

- **edge** — centered on the interior cell adjacent (inward) to the active
  ring cell nearest to top-center (1, 32); ties broken by the sorted ring
  order. The patch's outermost cells sit at d = 1. Center clamped so the
  patch stays inside rows/cols 2..63. Placement is relative to the *ring*,
  not the frame, because ring cells cover only ~25% of the boundary and the
  hypothesis is attachment to a driven cell, not geometric proximity.
- **mid** — centered at (17, 32): patch center at d = 16.
- **center** — centered at (32, 32): d = 31.

**Pairing.** All four arms use `initial_condition = :custom` with initial
grids built from one shared background per (config, seed): a balanced
perturbation replicating the factory defaults (5% Buy + 5% Sell interior
cells, exact counts, boundary Hold) drawn from a dedicated stream
`Xoshiro(10_000 + seed)`. Because every arm passes `:custom`, RNG
consumption inside `simulate` is identical across arms — same ring
positions, same band half-widths, same minority-rule placement — so arms
differ only in the stamped cells. The patch overwrites whatever the
background placed there (the few background cells overwritten differ by
location; negligible and noted in the script). Runs are comparable in kind,
not bit-identical, to the original ensemble; the paired contrast is the
result, exactly as in the budget toggle.

**Outcomes per run** (`ModelB-Nucleation-SeedingIntervention.csv`, one row
per config × seed × arm): `config, seed, arm, patch_size, patch_row,
patch_col, included, t_on, front_final` (largest-cluster fraction at STEPS),
`dominant_from_patch` — the backward lineage from the onset cluster reaches
t = 1 with ≥ 1 cell of overlap against the stamped patch (false for control
and for runs with no onset) — plus, from a *forward* trace seeded at the
patch (same max-overlap rule run forward), `patch_lineage_max` (largest size
the patch's lineage ever reaches) and `patch_alive_at_onset`.

**Statistics.** Per config: (a) onset advance Δt_on = t_on(control) −
t_on(arm), paired per seed, sign test per placement, plus the edge-vs-center
paired contrast; (b) dominance rates by placement with the edge-vs-center
paired (McNemar-style sign) comparison. Censored runs (no onset) drop from
Δt_on pairs but count in dominance denominators.

## 3. Script structure, outputs, validation

**Script:** `code/model-b/Compute-ModelB-BoundaryVsBulk.jl`, self-contained,
staged internally: arm 1 runs first, prints its summary, calibrates s; arm 2
follows. Stage-2 threading contract: preallocated result slots indexed by
run id, `Threads.@threads :dynamic`, all file I/O and plotting outside the
threaded loop. `SMOKE=1` env var → GRIDN 32, STEPS 300, seeds 1:2 (patch
coordinates scale with GRIDN).

**Data:** `code/data/ModelB-Nucleation-BirthSites.csv`,
`code/data/ModelB-Nucleation-SeedingIntervention.csv`.

**Figures:**
- `code/figs/ModelB-Nucleation-BirthSites.pdf` — (a) birth-site scatter on
  the grid outline, both configs; (b) birth-distance histogram vs the
  analytic null PMF, per config; (c) attachment timing panel.
- `code/figs/ModelB-Nucleation-Seeding.pdf` — (a) paired t_on dots by arm
  (control/edge/mid/center) per config; (b) dominance-rate bars by
  placement; (c) exemplar largest-cluster trajectories.

**In-script assertions:** birth_step ≤ t_on and birth_size ≥ 1 for every
included run; per (config, seed) the four arms' returned
`edge_coordinates` and `edge_k` are identical. Forward/backward lineage
agreement (backward-reaches-patch vs patch_alive_at_onset) is *reported as a
warning count*, not asserted — the two tracers follow max-overlap in
opposite directions and can legitimately route through different branches.

**Cost:** 200 runs × 1500 steps at 64×64 with dense frames ≈ 3–4× the seed
sweep; runs threaded, frames processed and dropped per run (peak memory ≈
n_threads × ~70 MB).

## Interpretation map (what each outcome means)

- Births uniform (d ≤ 2 fraction ≈ 12.5%) + no placement effect → bulk
  nucleation; the ring only gates growth. Paper: "the bulk creates, the
  boundary gates."
- Births boundary-enriched + edge placement dominates/advances onset →
  boundary-seeded nucleation; the conduit both creates and gates. The
  pre-onset ring selling in the loose config was seeding, not noise.
- Births boundary-enriched but placement null (or vice versa) → the
  observational enrichment is confounded (e.g., by minority-cell density
  fluctuations) or the stamped patch is the wrong probe size; revisit patch
  calibration before interpreting.
