# Triage of the GPT-5.6 cold review (`things-to-consider.md`)

Date: 2026-08-05. Protocol (per venue decision): every reviewer claim was verified
against the manuscript, code, and committed CSVs before disposition. Five parallel
verification passes covered (1) initial-condition/assignment code, (2) experiment and
metric code, (3) committed data summaries, (4) manuscript text, (5) bibliography and
packaging. Dispositions: **A** quick edits, **B** free reanalyses from committed data,
**C** compute campaigns, **D** user decisions, **E** won't-do with rationale.

## Verdict on the review itself

The review is unusually accurate. Nearly every factual claim reproduced exactly against
the code and committed data: the finite-size conversion counts, the Avrami fit
heterogeneity (L=64 at f=0.16: mean R²=0.649, n spanning 0.35–4.70), the 5/6/6-point
three-parameter escape-time fits, the 3-of-39 founder count on 20 reused landscapes, the
freeze/collapse baseline asymmetry (cash 500×10 vs 5000×0.1/0.01, never a shared
baseline), the area-fraction "front velocity", the annealed closures, and the price
outcomes (crash-prone median drawdown 4.9%, median minimum price exactly 100.00; the
collapse configuration's median path ends UP 19.5% after peaking at 154).

Reviewer errors found (4) — do not act on these:

1. **"Finite-size scaling" terminology charge is off-target.** The paper never uses the
   phrase; it says "system-size dependence" (Fig 3 caption) and disclaims thermodynamic
   criticality at results.tex:22, results.tex:38-39, and methods.tex:181-182. The
   substantive asks in item 3 (L=32, hazard scaling, horizons) stand anyway.
2. **The Figure 5 exemplar filter IS disclosed** (methods.tex:235-240), and the survivor
   pool was 1 of 11, not the reviewer's "2 of 11" — the committed JLD2 provenance string
   and the manuscript agree with each other.
3. The volatility-band recursion is **Equation (4)**, not (5).
4. The reviewer self-corrected on the pair fixed point (it is genuine to numerical
   precision) — no work there.

Verification also found several things **worse** than the review states; see "New
defects" below.

---

## A. Quick edits (text/bib/repo only, no computation)

Safe to do now — no pending analysis can change them.

| # | Edit | Anchors | Review item |
|---|------|---------|-------------|
| A1 | State Model B's initial condition (exact-count 5% Buy + 5% Sell on the interior, boundary Hold) in Methods and in the escape-time/toggle/birth campaign descriptions | methods.tex:110-136, 184-240 | 1 |
| A2 | Add the finite-size protocol to Methods (periodic boundaries, uniform three-state init, 200-step burn-in, 10⁵-step horizon, 20 seeds) — currently the campaign has NO Methods paragraph at all; fold into the existing protocol-family paragraph, no new stub | methods.tex Simulation Protocols; results.tex:44,49 | 1 |
| A3 | Campaign specification table (SI float): lattice, boundary, forcing, init, burn-in, horizon, rule-assignment population, fraction denominator, cluster region, threshold, seeds. Wire the reference in the same edit | appendix.tex | 1, 17 |
| A4 | Rename the theory "annealed mean-field / annealed pair closures" throughout; narrow "erase exactly what the lattice supplies" (results.tex:74) and "supports no correlated fixed point, the negative result on which the nucleation argument rests" (appendix.tex:116-117) to the tested closure + IC family; make "afresh" explicitly per-update | appendix.tex:8-18, 91-119; results.tex:74; discussion.tex:131-136 | 2 |
| A5 | Fix the Jacobian sentence: six symmetric components minus normalization = 5-dimensional tangent space; report the projected spectrum or reword. Also reconcile 12 vs 13 f-grid values | appendix.tex:80-101 | 2 |
| A6 | Fix "every lattice above the spreading threshold converts eventually" (unproved for a deterministic finite CA) and the monotonicity sentence "larger lattices crashed at lower contrarian fractions" (non-monotone in committed data: at f=0.13 L=32 gives 15/20 vs 0/20 at L=64,128); give L=32 an honest treatment — the 100-cell-threshold rationale does not apply to the conversion observable | results.tex:44 | 3 |
| A7 | Soften "An exponent near 2 says the vulnerable regions were fixed before the clock started" → compatible-with, not proof; report the n heterogeneity across L and f (committed: L=64 f=0.16 mean R²=0.649; L=128 f=0.16 max n=8.72); disclose baseline/window/no-t₀ fit sensitivities | results.tex:44; discussion.tex:23-27 | 4 |
| A8 | Replace "inverse-distance form of Kramers-type escape problems" (results.tex:74), "stochastic nucleation waiting times" (Fig S2 caption, appendix.tex:344-345), "barrier law/fits" (appendix.tex:253, 297-298; Fig S4 caption) with the empirical-curve / disorder-induced-variation language the paper already uses elsewhere | results, appendix | 5 |
| A9 | Qualify "censored runs were never dropped": true inside each KM cell, but the fitted onset law uses only the 5/6/6 finite-median points; note the Model A fit drops 7 of 19 f-values; state the equivalence margin's tested range narrowly and drop "fixed in advance" unless a dated protocol exists | appendix.tex:245-248; methods.tex:247-249; results.tex:74, 136 | 6 |
| A10 | Birth-site language: state the raw count (3 of 39), replace "consistent with a uniform distribution / statistically indistinguishable" with failure-to-reject phrasing, acknowledge the 39 births sit on 20 paired landscapes (same seeds, byte-identical disorder across arms), soften "the winning nucleus was an interior single-cell fluctuation" (single-path max-overlap genealogy) | results.tex:108, 126-130 | 7 |
| A11 | Patch experiment: drop "the experiment that settled the point is a null with a working lever" (discussion.tex:28-30); fix "grew only to 9–15 cells" (committed max 78; 10 of 120 runs exceed 15); replace "no placement advanced onset" (S5 caption + results.tex:136) — 43 of 116 committed pairs DID advance individually, largest by 1,127 steps — with "no consistent, sign-stable advancement" | results.tex:136; appendix.tex:400-402; discussion.tex | 8 |
| A12 | State the injection/withdrawal baseline confound (direction inseparable from baseline regime) and keep the oracle-timing distinction explicit; do not claim a general directional asymmetry | results, discussion | 9 |
| A13 | Rename "front velocity" → "largest-domain areal growth rate" in prose; fix "OLS slope of the front extent" (methods.tex:262-263). Figure 6 axis label rename batches with C3's rerun | methods, results, discussion | 10 |
| A14 | "Traced that gating to the boundary ring" (abstract, introduction.tex:68) → "consistent with boundary mediation"; keep the architectural fact (price reenters ONLY via the edge ring — true by construction) separate from the empirical mediation claim; retire "the lattice answered yes", "draws that line cleanly" | Paper_v1.tex:87-88; introduction.tex:68; discussion.tex:6-7, 31, 40-42 | 11 |
| A15 | Suppression: association language only ("realized suppression tracked the slowing"); fix discussion.tex:45-46 "the causal one" | discussion.tex:45-46; results.tex:136 | 12 |
| A16 | Rule naming: Methods and Table 1 still say "majority/herding rule ... adopt the dominant state" while results.tex:74 discloses the all-Buy→Sell counterexample. Rename to "sum-threshold (herding-like) Rule 19280" at first use and in Table 1; optionally add one sentence quantifying modal-state agreement (cheap enumeration of 126 compositions) | methods.tex:44, 50-52 | 14 |
| A17 | Band terminology: Eq (4) is an EMA of \|P−Ŝ\| (an EWMAD), not a standard deviation; fix "k standard deviations" (methods.tex:83-85, 108), "Bollinger Band filter" (introduction.tex:57-59); state α=1/60 with a defined convention (mean age ≈59 steps / half-life ≈41) instead of "a 60-minute window" | methods.tex:71-73, 83-86, 107-108 | 15 |
| A18 | Disclose the QQQ concatenation: the forcing runs the 61 sessions as one series with EMA/band carrying across the 60 overnight joins, while the benchmark removes joins and standardizes within session; justify typical-price returns (the 0.30 lag-one autocorrelation likely reflects (H+L+C)/3 bar construction) | methods.tex:90-98, 213-216 | 16 |
| A19 | f is assigned among all L² sites, not interior-only: fix "a fraction f of interior agents" (methods.tex:101-103) to nominal all-site assignment with realized interior fraction ≈ f (hypergeometric); denominators go in the A3 table | methods.tex:101-105 | 17 |
| A20 | Stage 2: report the predicate overlap (ALL 4,211 crash-prone runs also satisfy the oscillatory criterion — min φ-crossings among them is 200 vs threshold 20; the priority order does the classification) and that the class boundary sits in a dense continuum (min crash-freq 0.0105 vs max 0.0095); keep the "between-configuration share" language | results.tex:106; appendix.tex:136-139 | 19 |
| A21 | Bib: add Bartolozzi & Thomas PRE 69, 046112 (2004) and Qiu, Kandhai & Sloot PRE 75, 046116 (2007); rework "we are aware of three" (relatedwork.tex:119-121); verify the Qiu given name on the existing ACS entry ("Guoping" is likely wrong); reposition the contribution as quenched deterministic totalistic heterogeneity + spatial founder/front measurement + budget feedback | References_v1.bib:314-321; relatedwork.tex:119-132 | 20 |
| A22 | Repo: un-ignore and commit `code/Manifest.toml`; expand the 2-line root README (typo "worlfram") into a reviewer entry point (build, tests, figure map, runtimes); add a Data Availability + software-citation paragraph (Julia and key packages are currently uncited anywhere) | .gitignore:24; README.md; Paper_v1.tex | 23 |

**New defects found during verification (not in the review), fold into the A-wave:**

- relatedwork.tex:127-129 calls the paper's own result "our phase diagram", and
  :137-138 says it "identifies a discontinuous transition" — the only two places the
  paper breaks its own criticality discipline. Fix both.
- The 94–97% variance-decomposition numbers are not derivable from any committed file
  (`ModelB-Stage2-VarianceDecomposition.csv` is a different, 21-term decomposition whose
  sums are 0.91–0.96); commit the whole-configuration grouping that produces the quoted
  figures (B7).

**Sequencing caution:** hold the number-carrying sentences (Avrami exponent A7, CV
"halving on each doubling", uniform-null A10) until their B-reanalysis lands — the
refits may change the numbers those sentences cite. Everything else in A is
analysis-proof.

## B. Free reanalyses (committed data, no new simulations)

These upgrade several P0s substantially and are cheaper than the review assumes:

| # | Analysis | Data (verified present) | Review item |
|---|----------|-------------------------|-------------|
| B1 | Multi-horizon conversion: pseudo-threshold f½(L,T) with intervals, and the rare-region hazard test P(L,T)=1−exp(−L²H(f,T)) — per-seed `t_conv` is committed, so any T ≤ 10⁵ is derivable without new runs | `ModelA-FiniteSizeScaling.csv` | 3 |
| B2 | Avrami robustness: refit with t₀, baseline/window/stopping sensitivity, full L×f distributions, held-out collapse (estimate K on one size, predict others) | `ModelA-AvramiTrajectories.csv` (committed, 3.5 MB) | 4 |
| B3 | Survival reanalysis: fit individual (time, event) records (discrete-time hazard or AFT), compare inverse-distance vs power-law vs exponential vs flexible monotone by held-out/IC performance, cluster bootstrap by shared seed across f preserving cash pairing, raw KM curves with risk counts as an SI figure | `ModelB-Nucleation-EscapeTime.csv` + trajectories | 6 |
| B4 | Birth sites: full distance-distribution test with seed-clustered/paired uncertainty (freeze/collapse arms as paired outcomes on 20 landscapes) | `ModelB-Nucleation-BirthSites.csv` | 7 |
| B5 | Patch: per-arm success probabilities with binomial upper bounds (0/20 ≠ zero), paired onset-time analysis with multiplicity adjustment | `ModelB-Nucleation-SeedingIntervention.csv` | 8 |
| B6 | CV self-averaging: fit the log-log slopes instead of the anchored guide (already computed in triage: −0.49 to −0.57 with R² ≥ 0.96 for f ≥ 0.16; flat-then-drop near threshold — report honestly) | `ModelA-FiniteSizeSummary.csv` | 3 |
| B7 | Stage 2: predicate overlap matrix, threshold sensitivity sweep (vary 1%/20/10% cutoffs), commit the provenance CSV for the 94–97% figures | `ModelB-Stage2-Summary.csv` | 19 |

## C. Compute campaigns (new simulations or new theory), ranked by referee-impact per cost

| # | Campaign | Size | Review item |
|---|----------|------|-------------|
| C1 | **Quenched (rule-type-resolved) mean-field and pair closures** — track state×rule-type marginals/pairs, continuation + basin search including cycles. The most claim-critical item: the current negative theory result cannot support the nucleation argument's key sentence (A4 softens it now; only this can re-strengthen it) | theory + small numerics | 2 |
| C2 | **One boundary-mediation ablation** — the Discussion already proposes them; run at least one (freeze boundary state through onset, or force the edge flip without touching books). Needs a new simulate hook + ~40–80 runs at 64² | small | 11 |
| C3 | **Crossed toggle design**: direction × baseline (injection AND withdrawal from BOTH cash-500 and cash-5000 baselines), interior-only + lineage-tracked outcome metric, doubled seeds. This one campaign absorbs the already-planned p=0.064 seed doubling — running the doubling alone would leave the baseline confound (item 9) and metric contamination (item 10) intact, so fold it in | few hundred 64² runs | 9, 10, 3-known |
| C4 | Patch dose-response (grow patch size to a working positive control), randomized placements within strata, post-burn-in stamping arm | small | 8 |
| C5 | Matched simulation null for births (frozen/neutral boundary founders on the same landscapes) + genealogy sensitivity (all-ancestor graph vs max-overlap chain) | small | 7 |
| C6 | Initial-condition robustness: Model B headline campaigns at 2–3 perturbation densities/compositions; finite-size at an alternate init mixture and a second burn-in (L ≤ 256 grid + spot-check 512) | medium | 1 |
| C7 | Endogenous grid-size robustness at 128² (already on the roadmap; unchanged by this review) | medium | known |
| C8 | QQQ forcing robustness ladder (user-added 2026-08-05): (a) reset EMA/band at session opens; (b) many windows from the committed file — sliding ~20-session sub-windows (~7,800 steps, sufficient for crossover diagnostics) and session-level block bootstrap (preserves intraday structure, breaks the particular ordering); (c) surrogate arms: IAAFT/phase-randomized (preserves marginal + spectrum), GARCH(1,1) (parametric with vol clustering), and GBM as the deliberately-wrong no-stylized-facts end member. GBM is an ablation arm here, NOT a data replacement — see D4. No new data needed for any arm (fresh-calendar-windows arm dropped with the re-acquisition veto). Each arm is one sweep at 128² | medium | 16 + user Q |
| C9 | One asynchronous update scheme + one alternate boundary topology at headline settings | medium | 18 |
| C10 | L=32 small-lattice study (why it converts at LOWER f: basin structure / wrap-around interactions at 200-step burn-in scale) | small | 3 |
| C11 | Rule-pair genericity screen (parked strategy; already on the roadmap) | medium | known |

## C′. Revised compute program (2026-08-05; supersedes the C-table sizing)

User directive: the audit's technical core is the priority; packaging items are
closed or parked. Re-sizing correction, grounded in the committed campaign log
(`FiniteSizeScaling-run.log`): the full 900-run survey (5 L × 9 f × 20 seeds,
T=10⁵, 24 threads) took ≈93 s wall; the worst cell (L=512, f=0.13, mostly
censored) was 31 s for 20 seeds. Model A compute is essentially free at
referee-proof scale — the binding cost is instrumentation code and analysis, not
CPU. The B-reanalyses are demoted to diagnostics that feed campaign design; they
do not substitute for the campaigns. Consolidated program:

**Campaign I — Model A size/horizon/kinetics (items 1, 3, 4 — the technical
core).** Seeds 20 → 200 (500 at f½-bracketing cells); f-grid refined to
Δf=0.0025 across the crossover per L; add L=1024; extend T to 10⁶ at censored
large-L cells (tests "converts eventually" honestly and gives the hazard model
its T-dependence); instrument runs to MEASURE what Avrami fitting only infers —
domain birth-time distributions (first appearance of each surviving cluster
lineage) and interface velocity (largest-cluster perimeter tracking); alt-IC and
alt-burn-in arms at a subset of cells; dedicated L=32 mechanism study. Estimated
wall time from measured throughput: single-digit hours; overnight with margin.
Deliverables: f½(L,T) with intervals, per-area hazard test, measured
birth/growth kinetics replacing exponent inference, fitted CV slopes.

**Campaign II — Model B escape-time + intervention redesign (items 6, 9, 10, 11
+ the p=0.064 doubling).** Escape-time: horizon 2,000 → 20,000 at censored
low-f cells (lifts the 5/6/6-point poverty to 8–10 finite medians per arm),
seeds → 100. Toggle: crossed direction × baseline (both from cash-500 and
cash-5000), doubled seeds, interior-only + lineage-tracked outcome metrics, and
at least one boundary-mediation ablation arm (freeze-edge hook; force-flip
hook). IC-robustness and 128² grid-size arms fold in here. Code work: new
simulate hooks + interior metrics.

**Campaign III — birth/patch program (items 7, 8).** Matched frozen-boundary
simulation nulls on the same landscapes; patch dose ladder (3×3 → 9×9) ×
randomized placements per stratum × stamp-after-burn-in arm; all-ancestor
genealogy sensitivity.

**Campaign IV — structural robustness (items 16, 18; C11).** One asynchronous
update scheme (code work), one alternate boundary topology, rule-pair
perturbation screen, QQQ forcing ladder (C8 arms).

**Theory track (item 2, parallel):** quenched rule-type-resolved closures —
analyst-time-bound, not CPU-bound.

Order: I first (it answers the items the reviewer called the paper's weakest),
II second, III/IV as they slot in. Prose edits that cite campaign numbers wait
for their campaign; the rest of the A-wave can interleave.

## D. User decisions (flagged, not acted on)

1. **Title / "market crash" framing (item 13).** The title is user-picked (3c8c037).
   The committed data make "market crashes" genuinely attackable: the modal crash-prone
   run's median drawdown is 4.9% with median minimum price exactly 100.00, and the
   "collapse" configuration's median path ends +19.5%. Options: (a) retitle to
   sell-domain/sell-state language (reviewer's preference, safest); (b) keep the title
   and add a declared price-drawdown criterion reported separately wherever "crash"
   appears (defensible but adds work); (c) keep as-is (referee bait). Prose-level
   separation of grid label vs price observable proceeds under A regardless.
2. **Abstract reframing (items 13/21).** The abstract is user-owned (e4aad3c). The
   reviewer wants physics-first hierarchy (quenched-disorder CA → closures/scaling →
   market as application). Recommend revisiting AFTER the A-wave settles the vocabulary.
3. **endfloat / REVTeX / figure sizes (item 22).** Collides with two prior decisions:
   figures-after-references is the deliberate Kompala calibration, and the venue memo
   records REVTeX-at-acceptance. Cheap compromise: keep the current layout as canonical
   and add a Makefile target that disables endfloat for a referee-friendly PDF
   (package-option toggle). Enlarging Figs 4/S6/S7 is real figure work either way.
4. **QQQ redistribution rights (item 23; narrowed 2026-08-05, then largely
   DEFUSED by provenance).** The file is committed under repo-wide MIT while
   `code/data/README.md` says the vendor's license terms are unrecoverable.
   **Key provenance fact (user, 2026-08-05): the data was never purchased** —
   oneminutedata.com published it freely to the public (releasing more tickers
   as pages accumulated likes) and then vanished. No purchase, no executed
   license agreement, no recoverable terms: the usual contractual hook for
   redistribution restrictions never existed, and factual price data itself is
   not copyrightable in the US. Residual exposure is minimal. Plan: (1) a
   data-license note excluding the QQQ file from the MIT grant (third-party
   factual data the authors did not create; archival reproducibility copy);
   (2) a Data Availability Statement stating the strong version — freely
   published by the vendor, no license was involved, vendor defunct with no
   archived terms, SHA-256 checksum, series cannot be re-obtained; (3) update
   `code/data/README.md` to record the free-publication provenance (fold into
   A22). Keeping the raw OHLCV file is now the default; the derived-P-only
   variant is unnecessary. Re-acquisition remains vetoed and moot. **Replacing the data with a
   fitted GBM generator was considered and rejected**: it would delete the
   "couples the CA to real market data" differentiator (relatedwork.tex:130-132),
   the adaptive EMA/EWMAD classifier transmits excursion/clustering structure
   that GBM lacks by construction, and it invites the stylized-facts objection
   with no upside. Synthetic forcing enters only as the C8(d) robustness ladder.
   **De-identifying the data was also considered and rejected** (2026-08-05): a
   public asset's minute-bar series is re-identifiable in seconds (the content IS
   the identity — even affine-rescaled prices, though they'd reproduce Model A
   exactly via band-classifier invariance, re-identify from returns), so it
   changes nothing legally while forfeiting the "real market data" differentiator
   and reading as evasive to referees. The labeled archival-copy carve-out
   remains the recommendation.
5. **Zenodo/OSF archival release with DOI (item 23).** Needs an account decision; I can
   prepare the release (pinned commit, Manifest, data dictionary, one-command rebuild).
6. **Reduced-scope fallback** (review's closing section): a scope decision, only
   sensible after seeing C1–C3 outcomes.
7. **Acknowledgments** — already on the user-owned TODO; still only a comment.

## E. Won't-do, with rationale

1. **Reassigning rule types interior-only in code** (item 17's first option): would
   invalidate every committed campaign to remove a cosmetic inexactness. Instead:
   disclose nominal all-site assignment and report realized interior f (A19 + A3).
2. **Instrumented causal test of suppression** (item 12's full ask): a book-constraint
   intervention holding band classification fixed is a follow-up paper. The paper keeps
   the robust descriptive association (A15).
3. **Full REVTeX conversion now** (item 22): per the standing venue decision, REVTeX is
   mandatory only at acceptance; the referee-variant PDF (D3) covers the usability
   complaint without maintaining two sources.
4. **"Demonstrably complete" literature search** (item 20's coda): unbounded as stated;
   we run a targeted sweep over CA finance, kinetic opinion models, Griffiths/rare
   regions, first-passage, and KJMA-misuse (the Erukhimovitch & Baram PRB 51, 6221
   (1995) caution is worth citing in the Avrami paragraph).

## Style-gate notes for whoever implements

- New Methods disclosures merge into the existing four protocol paragraphs
  (zero-tolerance paragraph gate); the campaign table is a float and its `\ref` gets
  wired in the same edit (cross-reference gate). No new `\label{sec:*}`.
- Replacement phrasings are precision statements ("consistent with boundary
  mediation"), not hedge stacks — the hedging-qualifier gate still applies. No em
  dashes, no Results subsections, colon lead-ins on any new display equation.
- Caption-only edits (S2/S4/S5) need no figure regeneration; the Fig 6 axis-label
  rename ("Front velocity") regenerates with C3.
