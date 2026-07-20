# Nucleation-Spine Restructure — Design Spec

**Date:** 2026-07-20
**Predecessors:** seed sweep (`8e90fb0`), budget toggle + edge trace
(`1045602`/`ba5a8fb`), boundary-vs-bulk seeding (`629a1d1..7954b72`,
loose ends `a477211`). All three mechanism legs of the arrested-nucleation
story are now evidenced.
**Scope:** (1) Two confirmatory analyses — the Model B escape-time/barrier
law and the front-velocity vs absolute-suppression dose-response — run
BEFORE any paper writing; (2) the full restructure of the arXiv paper
(`paper-arxiv/`, NeurIPS style) around the arrested-nucleation spine,
consuming those results. A PNAS-format version is a separate later effort
and out of scope here.

## Decisions (settled during brainstorming, 2026-07-20)

1. **Venue:** arXiv long-form now (NeurIPS style, in `paper-arxiv/` — the
   directory was renamed from `paper/`); PNAS compression later.
2. **Restructure depth:** rebuild the spine (abstract, Introduction, all of
   Results) as a nucleation arc; keep Related Work, Background, Methods as
   scaffolding with targeted edits.
3. **Sequencing:** analyses first, then writing. Every Results II claim is
   written once, with final numbers.
4. **Spec scope:** combined — analysis protocols and the paper outline live
   in this one document so the analyses aim at defined figure slots.
5. **Barrier-law axis:** f-sweep at three cash levels (not cash-sweep at
   fixed f, not a full 2D grid).
6. **Results architecture:** theory-as-bridge — the theory subsections are
   promoted to their own section between the Model A and Model B Results
   acts, so Results II reads as a hypothesis test of the barrier picture.
7. **Headings:** Results/Discussion keep subsection headings in the arXiv
   version; style-check's no-subsections rule applies to the PNAS version.

## Goal

The current draft is a Model A paper: the abstract never mentions Model B,
the theory lives as Results subsections, and Model B has a Methods stub with
no results. The restructured paper tells one story in three acts: a sell
nucleus crosses a barrier and runs to completion (Model A); the barrier is
quantitative (Potts energy + Kramers escape law, ln τ = 2.78 +
0.389/(f − 0.101), R² = 0.991); and the SAME nucleus under finite budgets
has a budget-gated fate — bulk-born, boundary-gated, arrestable — with a
liquidity-intervention asymmetry as the applied payoff.

---

# Part 1 — Confirmatory analyses

Both analyses come from ONE instrumented simulation campaign so the grid is
not run twice.

## Shared configuration and instrumentation

Standard Model B parameters, matching the probe / seed-sweep / toggle line
of work: grid 64×64, λ = 0.02, k = 1, spread = 0.5, disposition = false,
P0 = 100, deterministic seeds. **STEPS = 2000** — longer than
boundary-vs-bulk's 1500 because escape-time statistics are the point:
censoring must be minimized, and Stage 2 already established 2000 as a
standard horizon.

Per-step records for every run: largest sell-cluster fraction, front extent
(same definition as `Compute-ModelB-BudgetToggle.jl` — the lib reuses that
computation, not a reimplementation), suppressed buy and sell order counts
(absolute, unnormalized), price, and aggregate cash. Cluster labeling is **full-grid BFS 4-neighbour on Sell**
and onset is **t_on = first step the largest sell cluster ≥ 5% of the
grid** — the budget toggle's definitions, chosen so velocities and onsets
compose directly with the toggle results (note: boundary-vs-bulk used
interior-only labeling; the script header must state this difference).

New code, following the boundary-vs-bulk pattern (lib + tests + compute +
standalone figures):

- `code/model-b/EscapeTime-Lib.jl` — pure functions: onset extraction,
  censored medians (Kaplan–Meier when any run is censored), Kramers fit,
  velocity/suppression window statistics.
- `code/model-b/Test-EscapeTime.jl` — tests written first (TDD).
- `code/model-b/Compute-ModelB-EscapeTime.jl` — the campaign; emits CSVs.
- `code/model-b/Figs-ModelB-BarrierLaw.jl` and
  `Figs-ModelB-VelocitySuppression.jl` — read ONLY the committed CSVs;
  reproducible without re-simulation.

Data: `code/data/ModelB-EscapeTime.csv` (one row per run: config, f, cash,
seed, t_on or censored flag, velocity, mean absolute suppression in window,
summary stats) plus `code/data/ModelB-EscapeTime-Trajectories.csv` if the
figures need per-step series (wide, integer counts, matching the seeding
trajectories precedent).

## A1 — Escape-time / barrier law

**Question:** does Model A's Kramers form ln τ = A + B/(f − f0) survive
under budgets, and does the budget shift the barrier?

**Protocol.**
- Cash levels: 500 (tight), 1000 (mid), 5000 (loose).
- Pilot f-grid: {0.12, 0.15, 0.18, 0.21, 0.25, 0.30}, 20 seeds per
  (f, cash) point. From the pilot, add up to 4 refinement f-values per cash
  level near the observed divergence, at 40 seeds. Exact refinement values
  are a pilot-driven decision, not fixed here.
- τ = t_on. Runs with no onset by STEPS are right-censored: recorded with a
  censored flag, included via Kaplan–Meier medians, never silently dropped.
- Fit ln(median τ) = A + B/(f − f0) per cash level, f0 free (nonlinear
  least squares on the per-f censored medians); bootstrap CIs on (A, B, f0)
  by resampling seeds within each f.

**Confirmation criteria.**
1. The Kramers form fits each cash level with quality comparable to Model
   A's fit (R² on medians ≈ 0.99; degraded but clearly divergent fits are
   reported as-is).
2. The budget effect appears as a shift in f0 and/or B with non-overlapping
   bootstrap CIs between tight (500) and loose (5000) cash.

**Figure slot (paper 7.3):** `ModelB-Nucleation-BarrierLaw.pdf` — three
Model B divergence curves overlaid with the Model A curve. One panel says
"budgets raise the barrier" (or, see fallback, "budgets break the law").

## A2 — Front velocity vs absolute suppression

**Question:** the quantitative arrest claim — does front velocity fall as
the absolute budget-suppression rate rises? This fixes the per-panel
scaling flaw flagged in the pivot memo: suppression must be in absolute
orders/step, comparable across configs.

**Protocol.**
- The f = 0.20 slice of A1 (cash 500/1000/5000) extended with cash 250 and
  2000 at f = 0.20 only, 20 seeds each — five budget doses.
- Per run, onset-aligned window [t_on + 50, t_on + 400] (matching the
  toggle's W = 400 post-window): velocity = OLS slope of front extent;
  suppression = mean absolute suppressed-buy orders per step. Runs censored
  before onset, or with t_on + 400 > STEPS, are excluded and the exclusion
  count reported.
- Test: monotone dose-response, velocity vs suppression, Spearman ρ pooled
  across all runs with a permutation p (10,000 permutations); figure also
  shows per-cash medians on shared axes.

**Confirmation criterion:** monotone negative relationship at permutation
p < 0.05.

**Figure slot (paper 7.4):** `ModelB-Nucleation-VelocitySuppression.pdf` —
scatter of velocity vs absolute suppression, per-cash medians marked.

**Compute estimate:** A1 ≈ 3×6×20 pilot + ≤ 3×4×40 refinement ≈ 840 runs;
A2 adds 2×20 = 40. Under 900 runs of 2000 steps at 64×64 — a fraction of
the Stage 2 factorial (10,800 runs).

---

# Part 2 — Paper restructure (`paper-arxiv/Paper_v1.tex`)

## Target section structure

1. **Introduction** — rewritten. Crashes as nucleation events; the question
   shifts from "when do markets crash" to "what decides a nucleus's fate".
   Contributions: (i) minimal CA market with a first-order transition and
   spatially coherent crash fronts (Model A); (ii) a quantitative
   nucleation barrier (Potts mapping + Kramers law); (iii) budgets arrest
   the same nucleus, mechanism traced to price-mediated boundary gating
   (Model B); (iv) a liquidity-intervention asymmetry.
2. **Related Work** — kept; add one paragraph on metastability/nucleation
   in economics and the liquidity-intervention literature.
3. **Background** — kept; targeted edits only.
4. **Methods** — kept; the Model B subsection expands to cover budget and
   suppressed-order mechanics, the deterministic intervention hook, the
   onset definitions (full-grid for toggle/escape-time, interior-only for
   boundary-vs-bulk — stated once, here), BFS cluster labeling, and the
   Part 1 sweep protocols.
5. **Results I: Model A — the clean nucleation baseline.** Current 5.1
   (grid dynamics) + 5.2 (phase diagram) nearly as-is.
   Figures: `Fig2-Combined`, `Fig3-PhaseDiagram`.
6. **Theory: the nucleation barrier.** Current 5.3–5.6 (Potts energy,
   mean-field, pair approximation, nucleation/Kramers) promoted to a
   standalone section with new bridging intro/outro; the Kramers fit is
   stated as the quantitative claim Model B must answer. No new figure
   required — the Model A curve rides in the 7.3 barrier figure. Optional
   energy/entropy-vs-f figures go to the appendix or are deferred.
7. **Results II: Model B — the barrier under budget constraints.**
   - 7.1 *The transition survives budgets.* Stage 2: sharp λ-independent
     transition between f = 0.15 and 0.20; two realized regimes of five
     possible; the freeze phenomenon (crash exemplar freezes near
     Sell ≈ 0.88 as budgets exhaust). Figures: `Fig-ModelB-Exemplars`
     (+ optionally `ModelB-Stage2-RegimeMap`).
   - 7.2 *The nucleus is spatial and bulk-born.* Seed sweep (stable ratio
     0.022, zero overlap with freeze 0.26 / collapse 0.44 — MEDIANS, never
     the upper-tail probe values) + birth sites (uniform: pooled
     frac d ≤ 2 = 0.077 vs 0.125 null, p = 0.47; median birth size 1,
     distance 12). Figures: `ModelB-Nucleation-SeedSweep`,
     `ModelB-Nucleation-BirthSites`.
   - 7.3 *Budgets shift the barrier.* NEW — A1 figure + fit table.
   - 7.4 *Growth is gated at the boundary.* Stamped-patch rejection
     (dominance 0/20 in all six config×arm cells) + the velocity
     dose-response. NEW A2 figure + `ModelB-Nucleation-Seeding`.
   - 7.5 *The intervention asymmetry.* Budget toggle + edge trace:
     injection flips the contrarian ring from brake (~0.5 Buy) to
     accelerant (~1.0 Sell) and accelerates the front (14/19, sign
     p = 0.064); withdrawal null at both doses (x0.1 and x0.01-binding,
     p = 0.29) — ceiling + sign asymmetry, and crashes self-finance their
     dip-buyers. Figures: `ModelB-Nucleation-BudgetToggle`,
     `ModelB-Nucleation-BudgetToggle-EdgeTrace`.
8. **Discussion** — new: the liquidity-intervention asymmetry as a micro
   moral-hazard analog; limitations (64×64 single asset, QQQ boundary data
   only in Model A, exploratory flags below); a brief rule-space generality
   note (the parked 4-move compression strategy stays parked).
9. **Conclusion** — rewritten around the arc.
**Appendix** — pair-approximation derivation (referenced by current 5.5; an
arXiv version cannot ship the dangling reference, so writing it is IN SCOPE
for Phase 2), Stage 2 factorial detail, A1 censoring/survival detail.

## Prose obligations (hard requirements, from the run logs)

1. The freeze/mid patch onset delay (p = 0.024) is EXPLORATORY: uncorrected
   across a 6-test family, fails Bonferroni (0.0083), sign-flip on the
   MEAN. The paper must say so wherever it is mentioned.
2. The crash-prone exemplar (run 9652) is the atypical tail; the typical
   crash-prone run freezes. "Crash" means majority-sell lock-in, not a
   price discontinuity. Caption must carry both caveats.
3. Cite seed-sweep MEDIANS (0.26/0.44), never the probe values (0.66/0.72).
4. If Stage 2 oscillation counts are cited, normalize `_REGIME_OSC_XINGS`
   by steps first (it is an absolute count tuned to 2000 steps); Stage 2
   marginal "error bars" are pooled std, not CIs — do not cite as
   uncertainty.
5. Injection sign test p = 0.064 is reported as-is (14/19 seeds), not
   rounded to "significant".

## Old→new mapping and casualties

- Abstract: fully rewritten (currently 100% Model A).
- Current 5.1–5.2 → Section 5; 5.3–5.6 → Section 6 with new framing.
- Section 7 written from scratch; Discussion split out of the current
  combined "Results and Discussion".
- Nucleation figures promoted from `code/figs/` into `paper-arxiv/figs/`
  via their standalone scripts (regenerated, not copied by hand).
- Legacy `Fig4-ClosedLoop`, `Fig5-PhaseDiagram`, `Fig6-ReturnDistributions`
  retire with their stale scripts; `Fig8-MeanField` is retained only if
  Section 6 claims it, else it retires too.
- Figure 3 caption's `\textbf{A:}` style fixed to match Fig 1 (existing
  TODO) while the file is open.

---

# Part 3 — Sequencing, surprise handling, verification

## Phases

1. **Analyses** (blocks writing): lib + tests (TDD) → pilot → refinement →
   full campaign → CSVs committed → standalone figure scripts →
   deterministic rerun reproduces CSVs (byte-identical, as achieved for
   boundary-vs-bulk).
2. **Writing**, in dependency order: Methods expansion → Results II →
   Theory bridge framing → Results I touch-ups → Related Work paragraph →
   Discussion → Conclusion → Introduction → Abstract (last, once the arc
   is real). Lab voice per the established writing-style conventions.
3. **Verify and clean:** `bash Build.sh Paper_v1` builds clean from
   `paper-arxiv/`; style-check, review-section, and audit-magic-numbers
   run over the rewritten sections; stale figure scripts retired.

## Surprise handling

- **A1: Kramers form fails under budgets** → 7.3 becomes "budgets break
  the barrier law" — reported as a headline result, not a failure; the
  Theory bridge is reframed as "the law Model B must break or obey".
- **A2: null or non-monotone dose-response** → 7.4 leans on the toggle's
  causal result alone; A2 is reported honestly in the appendix.
- **Heavy censoring near the divergence** (most runs never onset by 2000)
  → report survival curves instead of forcing median fits; cap grid
  refinement rather than chasing τ → ∞.

## Verification checklist

- [ ] `Test-EscapeTime.jl` passes.
- [ ] Rerun of `Compute-ModelB-EscapeTime.jl` reproduces committed CSVs.
- [ ] Both figure scripts run from CSVs alone on a clean checkout.
- [ ] `bash Build.sh Paper_v1` exits clean; no undefined references.
- [ ] All five prose obligations verified present in the built PDF.
- [ ] style-check / review-section / audit-magic-numbers pass on rewritten
      sections.

---

# Amendments (Phase 1 execution, 2026-07-20)

1. **CSV naming:** campaign outputs renamed to the `ModelB-Nucleation-EscapeTime*`
   prefix (pre-execution) to match the `.gitignore` carve-out and the naming of
   every other nucleation-line CSV; the driver is
   `Compute-ModelB-Nucleation-EscapeTime.jl` accordingly.
2. **Pilot f-grid:** swapped 0.21 → 0.20 so the pilot hits the canonical f = 0.20
   config line and doubles as the A2 slice (plan decision, recorded pre-pilot).
3. **Refinement grid (Task 6 checkpoint):** the onset cliff sat between 0.15
   (rate 0.10) and 0.18 (rate 0.80–0.85) at ALL THREE cash levels, so the rule
   gave {0.156, 0.162, 0.168, 0.174} × cash {500, 1000, 5000} at 40 seeds. A
   **second pass** added f = 0.177 × 3 cash after the first pass left cash 500
   with only 4 defined medians (0.174 onset rate 0.45); appended at the end of
   REFINE so first-pass CSV row order is preserved as a prefix.
4. **Runtime:** the first production attempt segfaulted inside the threaded
   sweep (Julia 1.12.6, 8 threads, heavy dense-frame allocation); production
   runs use `-t 6 --gcthreads=1`. Results are thread-count-independent
   (per-run seeded RNG; results indexed by work item), verified by the
   byte-identity rerun.
5. **Barrier figure:** fit curves are drawn down to a display ceiling
   TAU_MAX = 3e4 (not f0 + 0.008 as the plan's illustrative code had), so the
   medians occupy the panel instead of being crushed by the divergence.

## Outcomes vs the confirmation criteria

- **A1 criterion 1 — MET.** The Kramers form lnτ = A + B/(f − f0) fits every
  cash level: r² = 0.978 / 0.990 / 0.980 (cash 500/1000/5000, on 5/6/6
  KM-median points), comparable to Model A's 0.991.
  Fits (A, B, f0): (3.379, 0.2467, 0.1121), (3.797, 0.1431, 0.1345),
  (4.105, 0.0984, 0.1430). Model A reference: (2.78, 0.389, 0.101).
- **A1 criterion 2 — NOT MET (robust null).** Bootstrap CIs overlap between
  tight and loose cash on both f0 ((0, 0.153) vs (0.077, 0.157)) and B
  ((0.070, 1.135) vs (0.050, 0.415)): **no detectable barrier shift with
  budgets.** The onset cliff sits at the same f at every cash level.
- **A2 criterion — MET.** Velocity vs ABSOLUTE suppression at f = 0.20:
  Spearman ρ = −0.372, permutation p = 0.0003 (n = 97, 3 excluded).
- **Exploratory observations (uncorrected; prose must label them so):**
  onset RATE near the cliff is monotone in cash (f = 0.174: 0.45/0.62/0.70;
  f = 0.177 KM medians 1598/1427/1208 tight→loose) — a growth-gating
  signature upstream of the 5%-cluster onset trigger; median suppression
  varies little across doses (517–595 orders/step) and median velocity is
  U-shaped in cash, so the supported A2 claim is the pooled negative
  velocity–suppression relationship, NOT a monotone-in-cash dose ladder.

**Framing consequence for Phase 2 (§7.3):** neither spec fallback occurred.
The result is a third, cleaner outcome — *the barrier survives budgets
unmoved*: nucleation (birth + escape) is budget-independent, and budget
effects act downstream, gating front GROWTH (A2, budget toggle, boundary
ring). §7.3 becomes "budgets do not move the barrier"; §7.4 carries the
arrest mechanism. This strengthens the bulk-creates / boundary-gates spine.
