# Nucleation-Spine Paper Restructure (Phase 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `paper-arxiv/Paper_v1.tex` around the arrested-nucleation spine — three acts (Model A clean nucleation → quantitative barrier theory → Model B budget-gated fate) — consuming the completed Phase 1 escape-time results, per the spec `docs/superpowers/specs/2026-07-20-nucleation-spine-restructure-design.md` (including its Amendments and Outcomes sections).

**Architecture:** The paper is ONE file, `paper-arxiv/Paper_v1.tex` (1,239 lines at start; `sections/` is a dead March-era leftover, deleted in Task 18). Writing proceeds in the spec's dependency order: figures/bib first (unblocks builds), then Methods → Results II (7.1–7.5) → Theory bridge → Results I → Related Work → Discussion → Conclusion → Introduction → Abstract → Appendices → cleanup → verification. Every task ends with a clean `Build.sh` run and a commit, so the paper is always compilable.

**Tech Stack:** LaTeX (NeurIPS 2026 preprint class, natbib/unsrtnat), Julia 1.12 (`--project=code`) for figure regeneration, git.

## Global Constraints

- **Build command (the "test" for every writing task):** `cd paper-arxiv && bash Build.sh Paper_v1`. Pass = pdflatex exits without `LaTeX Error`, and `grep "Warning: Reference\|Warning: Citation" Paper_v1.log` returns nothing (after the final pass). Exception: from Task 4 until Task 17 resolves them, exactly two forward references — `app:stage2` and `app:censoring` — are allowed to warn as undefined; any OTHER reference/citation warning is a task failure.
- **Julia commands run from the repo root** `/Users/jdv27/Desktop/julia_work/Wolfram-markets-abm-paper` with `--project=code`. Long compute reruns use `-t 6 --gcthreads=1` (Julia 1.12.6 segfaulted at `-t 8` under dense-frame allocation — spec Amendment 4).
- **Lab voice (from project memory, applies to ALL prose):** long flowing sentences; semicolons and em-dashes; tricolon lists; a narrative arc per paragraph; first-person plural; strategic `\emph{}`; citations woven grammatically into sentences; past tense in Results.
- **arXiv style adaptations (settled; do not re-litigate during execution):** subsection headings ARE allowed in Results/Discussion (spec decision 7 — the no-subsections rule applies only to the later PNAS version); em-dashes ARE allowed (lab voice + the entire existing draft); the `Section~\ref{sec:...}` roadmap convention of the existing draft stays; `style-check` rules about `main.tex`, line numbers, keywords, and figures-at-end are PNAS-template rules and do not apply. The no-bullet-points rule DOES apply: no `itemize`/`enumerate` anywhere in prose.
- **SEVEN prose obligations (hard requirements; the final task audits each):**
  1. The freeze/mid-patch onset delay (median −257 steps, sign-flip-on-MEAN p = 0.0238 with the +1 MC correction) is EXPLORATORY: uncorrected across a 6-test family, fails Bonferroni (0.0083). The paper must say so wherever it is mentioned.
  2. The crash-prone exemplar (run 9652) is the atypical tail; the typical crash-prone run freezes. "Crash" means majority-sell lock-in (Sell fraction ≥ 0.5), not a price discontinuity. The exemplar caption must carry BOTH caveats.
  3. Cite seed-sweep MEDIANS (0.26 freeze / 0.44 collapse), never the probe values (0.66/0.72).
  4. If Stage 2 oscillation counts are cited, normalize `_REGIME_OSC_XINGS` by steps (≥ 20 φ sign flips per 2,000 steps); Stage 2 marginal "error bars" are pooled std, not CIs — never cite them as uncertainty. (This plan simply never cites the marginal error bars.)
  5. Injection sign test p = 0.064 (14/19 seeds) is reported as-is, never rounded to "significant".
  6. A2 is the POOLED negative velocity–suppression relationship, reinforced by within-dose agreement (ρ negative in all five doses, −0.38 to −0.52; leave-one-dose-out p ≤ 0.0014) — NEVER a monotone-in-cash dose ladder (median velocity is U-shaped in cash; median suppression varies little, 517–595 orders/step).
  7. Say "no DETECTABLE barrier shift" — the null is underpowered (point estimates of B differ 2.5×; the cash-500 f0 lower CI bound of 0.000 is the physical/grid boundary of the fit domain, not a data quantile).
- **Numbers come from committed CSVs**, primarily `code/data/ModelB-Nucleation-EscapeTime{,-Fits}.csv`, `ModelB-Nucleation-{SeedSweep,BudgetToggle,BirthSites,SeedingIntervention}.csv`, `ModelB-Stage2-{Summary,VarianceDecomposition}.csv`. Every number used below is transcribed in the task that needs it.
- **Do not push.** main is already ahead of origin by 16+ commits; the user pushes when ready.

## Target section map (labels later tasks rely on)

```
1  Introduction                                          (rewritten, Task 15)
2  Related Work            \label{sec:related}           (+1 paragraph, Task 12)
3  Background              \label{sec:background}        (untouched)
4  Methods                 \label{sec:methods}
   4.1 Model A             \label{sec:model-a}           (panel-ref fix, Task 4)
   4.2 Model B             \label{sec:model-b}           (rewritten, Task 4)
   4.3 Phase Sweep Protocol \label{sec:phase-sweep}      (kept)
   4.4 Model B Nucleation Campaigns \label{sec:mb-protocols}  (NEW, Task 4)
5  Results I: Model A, the Clean Nucleation Baseline
                           \label{sec:results}           (retitle + frame, Task 11)
6  Theory: The Nucleation Barrier \label{sec:theory}     (NEW wrapper, Task 10)
   (existing sec:potts, sec:mean-field, sec:pair-approx, sec:nucleation move inside)
7  Results II: Model B, the Barrier under Budget Constraints
                           \label{sec:results-b}         (NEW, Tasks 5–9)
   7.1 \label{sec:mb-transition}   7.2 \label{sec:mb-spatial}
   7.3 \label{sec:mb-barrier}      7.4 \label{sec:mb-gating}
   7.5 \label{sec:mb-intervention}
8  Discussion              \label{sec:discussion}        (NEW, Task 13)
9  Conclusion              \label{sec:conclusion}        (rewritten, Task 14)
Appendix A \label{app:pair}  B \label{app:stage2}  C \label{app:censoring}  (Task 17)
```

Figure files the paper will reference (all in `paper-arxiv/figs/` when Tasks 1–2 finish): `Fig2-Combined.pdf`, `Fig3-PhaseDiagram.pdf` (present), `Fig-ModelB-Exemplars.pdf` (present), `ModelB-Nucleation-SeedSweep.pdf`, `ModelB-Nucleation-BirthSites.pdf`, `ModelB-Nucleation-BarrierLaw.pdf`, `ModelB-Nucleation-VelocitySuppression.pdf`, `ModelB-Nucleation-Seeding.pdf`, `ModelB-Nucleation-BudgetToggle.pdf`, `ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf`. The optional `ModelB-Stage2-RegimeMap` is NOT promoted (spec marks it optional; 7.1 carries the λ-independence claim in prose).

---

### Task 1: Promote the CSV-standalone nucleation figures into paper-arxiv/figs

The spec requires nucleation figures to be *regenerated* into `paper-arxiv/figs/`, never hand-copied. `code/model-b/Include.jl` already provides the mechanism: `_save_figure(fig, name)` writes to `code/figs/` AND copies to `paper-arxiv/figs/` (lines 24–30). Three standalone scripts still call `savefig` directly.

**Files:**
- Modify: `code/model-b/Figs-ModelB-BarrierLaw.jl` (line 97 + header comment line 8)
- Modify: `code/model-b/Figs-ModelB-VelocitySuppression.jl` (line 57 + header comment line 6)
- Modify: `code/model-b/Figs-ModelB-BoundaryVsBulk.jl` (lines 111, 167 + header comment lines 11–12)

**Interfaces:**
- Consumes: `_save_figure(fig, filename::String)` from `code/model-b/Include.jl` (already included by all three scripts via their `isdefined` guard).
- Produces: `paper-arxiv/figs/ModelB-Nucleation-{BarrierLaw,VelocitySuppression,BirthSites,Seeding}.pdf` — referenced by Tasks 6, 7, 8.

- [ ] **Step 1: Switch the four savefig call sites to _save_figure**

In `Figs-ModelB-BarrierLaw.jl` replace
```julia
    savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-BarrierLaw.pdf"))
```
with
```julia
    _save_figure(fig, "ModelB-Nucleation-BarrierLaw.pdf")
```
In `Figs-ModelB-VelocitySuppression.jl` replace
```julia
    savefig(fig, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-VelocitySuppression.pdf"))
```
with
```julia
    _save_figure(fig, "ModelB-Nucleation-VelocitySuppression.pdf")
```
In `Figs-ModelB-BoundaryVsBulk.jl` replace
```julia
    savefig(fig1, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-BirthSites.pdf"))
```
with
```julia
    _save_figure(fig1, "ModelB-Nucleation-BirthSites.pdf")
```
and
```julia
    savefig(fig2, joinpath(_PATH_TO_FIGS, "ModelB-Nucleation-Seeding.pdf"))
```
with
```julia
    _save_figure(fig2, "ModelB-Nucleation-Seeding.pdf")
```
Update each script's `# Writes:` header comment to say `code/figs/ + paper-arxiv/figs/`.

- [ ] **Step 2: Run all three scripts (they read only committed CSVs)**

```bash
julia --project=code code/model-b/Figs-ModelB-BarrierLaw.jl
julia --project=code code/model-b/Figs-ModelB-VelocitySuppression.jl
julia --project=code code/model-b/Figs-ModelB-BoundaryVsBulk.jl
```
Expected: each logs `Saved: <name>.pdf`; no exceptions.

- [ ] **Step 3: Verify the four PDFs landed in paper-arxiv/figs**

```bash
ls -la paper-arxiv/figs/ModelB-Nucleation-BarrierLaw.pdf \
      paper-arxiv/figs/ModelB-Nucleation-VelocitySuppression.pdf \
      paper-arxiv/figs/ModelB-Nucleation-BirthSites.pdf \
      paper-arxiv/figs/ModelB-Nucleation-Seeding.pdf
```
Expected: all four exist with today's timestamp.

- [ ] **Step 4: Commit**

```bash
git add code/model-b/Figs-ModelB-BarrierLaw.jl code/model-b/Figs-ModelB-VelocitySuppression.jl \
        code/model-b/Figs-ModelB-BoundaryVsBulk.jl code/figs/ModelB-Nucleation-*.pdf \
        paper-arxiv/figs/ModelB-Nucleation-*.pdf
git commit -m "Promote CSV-standalone nucleation figures into paper-arxiv/figs via _save_figure"
```

### Task 2: Regenerate the compute-drawn figures (SeedSweep, BudgetToggle, EdgeTrace) into paper-arxiv/figs

`ModelB-Nucleation-SeedSweep.pdf` is drawn inside `Compute-ModelB-NucleationSeeds.jl` (60 runs × 1,000 steps) and `ModelB-Nucleation-BudgetToggle{,-EdgeTrace}.pdf` inside `Compute-ModelB-BudgetToggle.jl` (3 arms × 20 seeds, paired 1,500-step runs) — their per-step series are not persisted, so regeneration means re-running the deterministic campaigns. Both have byte-identical-rerun precedent. **CSV byte-identity is the regression test: if `git diff` shows CSV changes, STOP — do not commit — and report; something in the environment changed.**

**Files:**
- Modify: `code/model-b/Compute-ModelB-NucleationSeeds.jl` (its `savefig(...)` call for `ModelB-Nucleation-SeedSweep.pdf` → `_save_figure`)
- Modify: `code/model-b/Compute-ModelB-BudgetToggle.jl` (lines 253 and 300: `savefig(fig, ...)` / `savefig(fig_edge, ...)` → `_save_figure(fig, "ModelB-Nucleation-BudgetToggle.pdf")` / `_save_figure(fig_edge, "ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf")`)

**Interfaces:**
- Consumes: `_save_figure` from `Include.jl`; committed CSVs `code/data/ModelB-Nucleation-SeedSweep.csv`, `code/data/ModelB-Nucleation-BudgetToggle.csv` as byte-identity baselines.
- Produces: `paper-arxiv/figs/ModelB-Nucleation-{SeedSweep,BudgetToggle,BudgetToggle-EdgeTrace}.pdf` — referenced by Tasks 6 and 9.

- [ ] **Step 1: Switch the three savefig call sites to _save_figure** (same edit pattern as Task 1; keep filenames identical).

- [ ] **Step 2: Re-run the seed sweep (fast, ~minutes)**

```bash
julia --project=code -t 6 --gcthreads=1 code/model-b/Compute-ModelB-NucleationSeeds.jl
```
Expected: completes without error; rewrites `code/data/ModelB-Nucleation-SeedSweep.csv` and saves the figure to both figs dirs.

- [ ] **Step 3: Re-run the budget toggle (the long one; TOGGLE_SMOKE must NOT be set)**

```bash
julia --project=code -t 6 --gcthreads=1 code/model-b/Compute-ModelB-BudgetToggle.jl
```
Expected: completes without error (no `TOGGLE_SMOKE` warning in output); saves both toggle figures to both figs dirs.

- [ ] **Step 4: Byte-identity regression check on the CSVs**

```bash
git diff --exit-code -- code/data/ModelB-Nucleation-SeedSweep.csv code/data/ModelB-Nucleation-BudgetToggle.csv
```
Expected: exit 0 (no diff). If nonzero: STOP the task, `git checkout --` the CSVs, and report the discrepancy to the user before touching anything else.

- [ ] **Step 5: Commit** (PDFs will differ binarily from committed versions — pdf CreationDate — that is expected; CSVs must NOT be in the diff)

```bash
git add code/model-b/Compute-ModelB-NucleationSeeds.jl code/model-b/Compute-ModelB-BudgetToggle.jl \
        code/figs/ModelB-Nucleation-SeedSweep.pdf code/figs/ModelB-Nucleation-BudgetToggle.pdf \
        code/figs/ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf \
        paper-arxiv/figs/ModelB-Nucleation-SeedSweep.pdf paper-arxiv/figs/ModelB-Nucleation-BudgetToggle.pdf \
        paper-arxiv/figs/ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf
git commit -m "Regenerate seed-sweep and budget-toggle figures into paper-arxiv/figs (CSVs byte-identical)"
```

### Task 3: Add the new bibliography entries

New prose (Methods disposition effect, Related Work paragraph, Discussion moral hazard, Theory Kramers citations) needs references that are absent from `References_v1.bib` (verified by grep).

**Files:**
- Modify: `paper-arxiv/References_v1.bib` (append at end)

**Interfaces:**
- Produces: citation keys `shefrin1985disposition`, `odean1998investors`, `kyle1985continuous`, `brunnermeier2009market`, `kirilenko2017flash`, `bouchaud2013crises`, `farhi2012collective`, `subrahmanyam1994circuit`, `kramers1940brownian`, `hanggi1990reaction` — used by Tasks 4, 10, 12, 13.

- [ ] **Step 1: Append these entries verbatim**

```bibtex
@article{shefrin1985disposition,
  author  = {Shefrin, Hersh and Statman, Meir},
  title   = {The Disposition to Sell Winners Too Early and Ride Losers Too Long: Theory and Evidence},
  journal = {The Journal of Finance},
  volume  = {40},
  number  = {3},
  pages   = {777--790},
  year    = {1985}
}

@article{odean1998investors,
  author  = {Odean, Terrance},
  title   = {Are Investors Reluctant to Realize Their Losses?},
  journal = {The Journal of Finance},
  volume  = {53},
  number  = {5},
  pages   = {1775--1798},
  year    = {1998}
}

@article{kyle1985continuous,
  author  = {Kyle, Albert S.},
  title   = {Continuous Auctions and Insider Trading},
  journal = {Econometrica},
  volume  = {53},
  number  = {6},
  pages   = {1315--1335},
  year    = {1985}
}

@article{brunnermeier2009market,
  author  = {Brunnermeier, Markus K. and Pedersen, Lasse Heje},
  title   = {Market Liquidity and Funding Liquidity},
  journal = {The Review of Financial Studies},
  volume  = {22},
  number  = {6},
  pages   = {2201--2238},
  year    = {2009}
}

@article{kirilenko2017flash,
  author  = {Kirilenko, Andrei and Kyle, Albert S. and Samadi, Mehrdad and Tuzun, Tugkan},
  title   = {The Flash Crash: High-Frequency Trading in an Electronic Market},
  journal = {The Journal of Finance},
  volume  = {72},
  number  = {3},
  pages   = {967--998},
  year    = {2017}
}

@article{bouchaud2013crises,
  author  = {Bouchaud, Jean-Philippe},
  title   = {Crises and Collective Socio-Economic Phenomena: Simple Models and Challenges},
  journal = {Journal of Statistical Physics},
  volume  = {151},
  number  = {3--4},
  pages   = {567--606},
  year    = {2013}
}

@article{farhi2012collective,
  author  = {Farhi, Emmanuel and Tirole, Jean},
  title   = {Collective Moral Hazard, Maturity Mismatch, and Systemic Bailouts},
  journal = {American Economic Review},
  volume  = {102},
  number  = {1},
  pages   = {60--93},
  year    = {2012}
}

@article{subrahmanyam1994circuit,
  author  = {Subrahmanyam, Avanidhar},
  title   = {Circuit Breakers and Market Volatility: A Theoretical Perspective},
  journal = {The Journal of Finance},
  volume  = {49},
  number  = {1},
  pages   = {237--254},
  year    = {1994}
}

@article{kramers1940brownian,
  author  = {Kramers, Hendrik A.},
  title   = {Brownian Motion in a Field of Force and the Diffusion Model of Chemical Reactions},
  journal = {Physica},
  volume  = {7},
  number  = {4},
  pages   = {284--304},
  year    = {1940}
}

@article{hanggi1990reaction,
  author  = {H{\"a}nggi, Peter and Talkner, Peter and Borkovec, Michal},
  title   = {Reaction-Rate Theory: Fifty Years After {K}ramers},
  journal = {Reviews of Modern Physics},
  volume  = {62},
  number  = {2},
  pages   = {251--341},
  year    = {1990}
}
```

- [ ] **Step 2: Build to confirm the bib still parses** (unused entries are inert under natbib; the build must stay clean)

```bash
cd paper-arxiv && bash Build.sh Paper_v1
```
Expected: exits clean; no new warnings.

- [ ] **Step 3: Commit**

```bash
git add paper-arxiv/References_v1.bib
git commit -m "Add references for disposition effect, liquidity interventions, and Kramers theory"
```

### Task 4: Methods expansion — Model B mechanics and the nucleation campaign protocols

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — subsection 4.1 (anchor: `In Model~A (Figure~\ref{fig:schematic}B)`, currently line 811), subsection 4.2 (anchor: `\subsection{Model~B: Closed (Endogenous Price) Simulation}` … through the paragraph ending `closing the feedback loop.`, currently lines 833–852), and a NEW subsection 4.4 inserted after the Phase Sweep Protocol subsection (i.e., immediately before `\section{Results and Discussion}`, currently line 866).

**Interfaces:**
- Consumes: bib keys from Task 3 (`shefrin1985disposition`, `odean1998investors`, `kyle1985continuous`, `farmer2005predictive` already in bib).
- Produces: `\label{sec:mb-protocols}`; onset/cluster definitions and campaign protocols that Results II (Tasks 5–9) cites via `Section~\ref{sec:mb-protocols}`; equation label `eq:imbalance` now defined as EXECUTED imbalance (keep the label; Results II references it).

- [ ] **Step 1: Fix the two wrong schematic panel references** — Model A's Methods text says `Figure~\ref{fig:schematic}B` but the Model A panel is C; Model B's says `\ref{fig:schematic}C` but its panel is D. Change B→C (line ~811) and C→D (line ~835).

- [ ] **Step 2: Rewrite subsection 4.2 (Model B).** Replace the current three-paragraph body. Content requirements (all verified against `code/src/Simulate.jl` and `code/src/Factory.jl` — the docstring at `Simulate.jl:284–320` is the authoritative step order):
  - Every trading cell (interior agent or active edge agent) carries a book: cash (initialized to `initial_cash`, the sweep variable, default 1000), a share inventory (initialized to 10 shares at cost basis P0 = 100), and an average cost basis. A cell in the Buy (Sell) state submits a one-share buy (sell) order every step it remains in that state; Hold cells submit nothing. Orders fill at the standing quote $P_{\tau-1}$ against an infinite-inventory market maker (cite `kyle1985continuous`, `farmer2005predictive`); a buy fills iff cash $\ge P$; a sell fills iff shares $\ge 1$ and, when the disposition toggle is on, $P > $ the cell's average cost basis — this cost-basis sell rule is the \emph{disposition effect} (cite `shefrin1985disposition`, `odean1998investors`), a behavioral bias, and it is a sweep factor, not an assumption. Unfilled orders are counted as \emph{suppressed} — constraints suppress orders, never CA states; sentiment propagation is unchanged from Model A, which is what makes the two models' interiors directly comparable.
  - Replace the state-count imbalance with the executed-flow imbalance, keeping the label: $\varphi_\tau = (\text{executed buys}_\tau - \text{executed sells}_\tau)/N_{\text{traders}}$ with $N_{\text{traders}} = N_{\text{interior}} + N_{\text{active edge}}$ (`\label{eq:imbalance}`), and keep $P_{\tau+1} = P_\tau \exp(\lambda \varphi_\tau)$ (`\label{eq:price-update}`).
  - Edge agents are full participants in $\varphi$ and draw per-agent band half-widths $k_i \sim U(k(1-\delta),\, k(1+\delta))$ where $\delta$ is the band-spread parameter (breaks all-or-none edge lockstep); the EMA/volatility recursions observe the newly generated price.
  - A deterministic intervention hook — a function of $(t, \text{books})$ invoked at the top of step $t$, before orders execute — implements mid-run liquidity injections/withdrawals by scaling every cell's cash; determinism preserves the same-seed ⇒ identical-trajectory contract that the paired counterfactuals in Results II rely on.
- [ ] **Step 3: Insert new subsection 4.4** after the Phase Sweep Protocol subsection:

```latex
\subsection{Model~B Nucleation Campaigns}
\label{sec:mb-protocols}
```
Content requirements (flowing prose, no lists):
  - Shared configuration for all nucleation campaigns: $64 \times 64$ grid, $\lambda = 0.02$, $k = 1$, band spread $\delta = 0.5$, disposition off, $P_0 = 100$, deterministic seeds; horizon 1,000 steps for the seed sweep, 1,500 for the budget-toggle and boundary-vs-bulk campaigns, and 2,000 for the escape-time campaign (verified against the scripts' `STEPS` constants).
  - Cluster and onset definitions, stated ONCE here: sell clusters are labeled by breadth-first search over 4-connected Sell cells on the full grid; onset $t_{\mathrm{on}}$ is the first step at which the largest sell cluster reaches 5\% of the grid. The boundary-vs-bulk birth analysis alone uses interior-only labeling (so ring-attached and bulk clusters can be distinguished); every other campaign uses the full-grid definition, so velocities and onsets compose across analyses.
  - Seed sweep: three configurations — stable ($f=0.10$, cash 1000), freeze ($f=0.20$, cash 500), collapse ($f=0.20$, cash 5000) — at 20 seeds each.
  - Budget toggle: per-seed paired counterfactuals; at $t_{\mathrm{on}}$ every cell's cash is scaled by $\times 10$ (injection), $\times 0.1$, or $\times 0.01$ (withdrawal doses); pre-toggle histories are asserted bit-identical; outcomes are measured in an onset-aligned window of $W = 400$ steps; front velocity is the OLS slope of front extent over the window.
  - Boundary-vs-bulk: birth-site tracking of the onset cluster's founding cell versus the analytic null for uniform births (fraction within distance 2 of the boundary = 0.125), plus a stamped $3\times3$ sell-patch intervention arm (patch at boundary-adjacent, mid, and center placements; paired with unstamped controls).
  - Escape-time campaign: cash $\in \{500, 1000, 5000\}$; pilot $f \in \{0.12, 0.15, 0.18, 0.20, 0.25, 0.30\}$ at 20 seeds; refinement $f \in \{0.156, 0.162, 0.168, 0.174, 0.177\}$ at 40 seeds (placed after the pilot located the onset cliff between 0.15 and 0.18 at all three cash levels); $\tau = t_{\mathrm{on}}$, right-censored at 2,000 steps and never dropped — per-$f$ medians are Kaplan--Meier; the Kramers form $\ln\tilde\tau = A + B/(f - f_0)$ is fit per cash level by nonlinear least squares on the censored medians with $f_0$ free, and 95\% CIs on $(A, B, f_0)$ come from 2,000 bootstrap resamples of seeds within each $f$.
  - Velocity--suppression dose-response: the $f = 0.20$ slice extended with cash 250 and 2{,}000 (five doses, 20 seeds each); per run, over the window $[t_{\mathrm{on}}+50,\, t_{\mathrm{on}}+400]$, velocity is the OLS front-extent slope and suppression is the mean \emph{absolute} suppressed-buy orders per step; the test is Spearman rank correlation with a 10{,}000-draw permutation $p$; runs censored before onset or with $t_{\mathrm{on}} + 400 >$ horizon are excluded and counted.
  - Stage 2 factorial (context for 7.1): full factorial $f \in \{0, 0.1, 0.15, 0.2, 0.3\} \times \lambda \in \{0.005, 0.01, 0.02, 0.05\} \times$ cash $\in \{500, 1000, 5000\} \times$ disposition $\in \{\text{off, on}\} \times \delta \in \{0, 0.5, 0.9\} \times k \in \{0.5, 1, 2\}$ — 1,080 configurations × 10 seeds = 10,800 runs of 2,000 steps; full detail in Appendix~\ref{app:stage2}.
- [ ] **Step 4: Build**  — `cd paper-arxiv && bash Build.sh Paper_v1`. Expected: clean; `app:stage2` will warn as undefined until Task 17 — acceptable ONLY for this reference; note it and confirm it is the sole undefined reference.
- [ ] **Step 5: Commit** — `git add paper-arxiv/Paper_v1.tex && git commit -m "Expand Methods: Model B budget mechanics, onset definitions, nucleation campaign protocols"`

### Task 5: Results II shell + 7.1 "The Transition Survives Budgets"

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — insert the new Section 7 immediately BEFORE `\section{Conclusion}` (currently line 1146).

**Interfaces:**
- Consumes: `Fig-ModelB-Exemplars.pdf` (already in paper-arxiv/figs); Stage 2 numbers below; `\ref{sec:mb-protocols}`, future `\ref{app:stage2}`.
- Produces: `\label{sec:results-b}`, `\label{sec:mb-transition}`, `\label{fig:mb-exemplars}`.

- [ ] **Step 1: Insert the section shell and 7.1.** Skeleton:

```latex
% ============================================================================
\section{Results II: Model~B, the Barrier under Budget Constraints}
\label{sec:results-b}
% ============================================================================

<2–3 sentence section lead: Results I established the clean nucleation
baseline and the Theory section quantified its barrier; Results II asks,
in five steps, what finite budgets do to that picture — whether the
transition survives (7.1), whether the nucleus remains spatial (7.2),
whether budgets move the barrier (7.3), where budget effects act (7.4),
and what that implies for intervention (7.5).>

\subsection{The Transition Survives Budgets}
\label{sec:mb-transition}
```

Content requirements for 7.1 (past tense, lab voice):
  - The Stage 2 factorial (10,800 runs; protocol in Methods) showed the crash transition survives budget constraints: the sell-dominated regime appeared abruptly between $f = 0.15$ and $f = 0.20$ at every price-impact $\lambda$, matching Model A's threshold; the sweep knobs explained 94–98\% of outcome variance, the seed at most 5.4\%.
  - Of five possible regimes in the classifier (inert, crash-prone, oscillatory, plateau, drift — defined in Appendix~\ref{app:stage2}), only two were realized: oscillatory (6,589 runs, 61\%) and crash-prone (4,211 runs, 39\%). "Crash-prone" is behavioral — at least 1\% of steps with Sell fraction $\ge 0.5$ — a majority-sell episode, not a price drawdown.
  - The freeze phenomenon, the first genuinely new Model B behavior: the typical crash-prone run is a sell-saturated liquidity freeze — median maximum drawdown ${\sim}5\%$, and half of crash-prone runs never traded below $P_0$ (median price minimum 100.00) — because the interior locks near Sell $\approx 0.88$ while budget exhaustion suppresses the order flow that would move the price. True price collapses are the tail: 897 of 4,211 runs reached price minima below 90, and the worst — concentrated at $f = 0.2$, $\lambda = 0.05$, cash 5000, disposition off — inflated 2.5–2.7$\times$ bubbles before crashing 40–69\%. Disposition roughly doubled return volatility (ratio 2.40$\times$).
  - Figure block:

```latex
\begin{figure}[tb]
  \centering
  \includegraphics[width=0.95\linewidth]{figs/Fig-ModelB-Exemplars.pdf}
  \caption{Model~B regime exemplars: price, interior state fractions, and
  suppressed orders for a crash-prone run (left, run 9652) and an
  oscillatory run (right, run 5916). The crash-prone exemplar is the
  dramatic tail of its regime---a bubble-and-collapse trajectory
  ($100 \to 266 \to 83$)---shown because it makes the mechanism visible;
  the \emph{typical} crash-prone run is a liquidity freeze in which the
  grid locks near a Sell fraction of $0.88$ while the price barely moves.
  ``Crash-prone'' throughout denotes majority-sell lock-in (Sell fraction
  $\ge 0.5$ on at least 1\% of steps), not a price discontinuity.}
  \label{fig:mb-exemplars}
\end{figure}
```
(The caption carries BOTH obligation-2 caveats; keep them through any edit.)
- [ ] **Step 2: Build** — expected clean apart from the known `app:stage2` forward reference.
- [ ] **Step 3: Commit** — `git commit -m "Add Results II shell and 7.1: the transition survives budgets"`

### Task 6: 7.2 "The Nucleus Is Spatial and Bulk-Born"

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — append after 7.1, inside Section 7.

**Interfaces:**
- Consumes: `paper-arxiv/figs/ModelB-Nucleation-SeedSweep.pdf` (Task 2), `ModelB-Nucleation-BirthSites.pdf` (Task 1).
- Produces: `\label{sec:mb-spatial}`, `\label{fig:mb-seedsweep}`, `\label{fig:mb-birthsites}`.

- [ ] **Step 1: Write 7.2.** `\subsection{The Nucleus Is Spatial and Bulk-Born}\label{sec:mb-spatial}` Content requirements:
  - Spatial, not mean-field (20 seeds × 3 configs): in the stable configuration the largest-cluster/total-sell ratio stayed at 0.022 (IQR 0.018–0.027) — ${\sim}500$ dispersed fragments, largest cluster ${\sim}0.5\%$ of the grid, 20/20 seeds flat — with ZERO overlap against freeze (median ratio 0.26) and collapse (median 0.44): one dominant sell domain nucleates and grows. Cite ONLY these medians (obligation 3).
  - The trajectory fans are time-shifted sigmoids: broad IQRs reflect stochastic nucleation \emph{waiting times} — the Kramers picture already showing up in Model B and the observation that motivated the onset-aligned analyses that follow.
  - Births are bulk, uniform (40 runs, 39 with onset): the founding cell of the onset cluster sat within distance 2 of the boundary in a pooled fraction 0.077 of runs versus the 0.125 uniform-null expectation (binomial $p = 0.47$; the freeze configuration alone, $p = 1.0$); median birth distance from the boundary 12 (deep bulk), median birth size 1 cell (single-cell fluctuations), median birth step 256, onsets spanning 75–1,115. Pre-onset ring attachment occurred only in the collapse configuration (6/19 runs; freeze 0/20) — a first hint that the boundary matters for growth, not birth, taken up in 7.4.
  - Two figure blocks (`width=0.95\linewidth`, `[tb]`), captions stating: (SeedSweep) largest-sell-cluster trajectories per seed for the three configurations with the ratio summary — medians 0.26/0.44, stable 0.022, zero overlap; (BirthSites) birth-location map and distance histogram against the uniform null, pooled frac $d \le 2$ 0.077 vs 0.125, $p = 0.47$.
- [ ] **Step 2: Build.**
- [ ] **Step 3: Commit** — `git commit -m "Add 7.2: the nucleus is spatial and bulk-born"`

### Task 7: 7.3 "Budgets Do Not Move the Barrier" (+ Kramers fit table)

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — append after 7.2.

**Interfaces:**
- Consumes: `paper-arxiv/figs/ModelB-Nucleation-BarrierLaw.pdf` (Task 1); fit numbers from `code/data/ModelB-Nucleation-EscapeTime-Fits.csv` (transcribed below); future `\ref{app:censoring}`.
- Produces: `\label{sec:mb-barrier}`, `\label{fig:mb-barrier}`, `\label{tab:kramers-fits}`.

- [ ] **Step 1: Write 7.3.** `\subsection{Budgets Do Not Move the Barrier}\label{sec:mb-barrier}` This is the third-outcome headline (neither spec fallback occurred): the Kramers law SURVIVES at every cash level, and no barrier shift is detectable. Content requirements:
  - Both models obey the same escape law: fitting $\ln\tilde\tau = A + B/(f - f_0)$ to Kaplan--Meier median onset times gave $r^2 = 0.978/0.990/0.980$ for cash 500/1000/5000 (on 5/6/6 median points), comparable to Model A's 0.991 — nucleation under budgets is still barrier-crossing.
  - The null, phrased per obligation 7: there was \emph{no detectable barrier shift} — bootstrap 95\% CIs overlap between tight and loose cash on both $f_0$ ((0.000, 0.153) vs (0.077, 0.157)) and $B$ ((0.070, 1.135) vs (0.050, 0.415)); the onset cliff sat between $f = 0.15$ and $f = 0.18$ at every cash level. State the power caveat explicitly: the $B$ point estimates differ by 2.5$\times$, and the cash-500 $f_0$ lower bound of 0.000 is the physical boundary of the fit domain, not a data quantile — the data bound the shift, they do not exclude a small one.
  - The consequence that reframes the paper's spine: nucleation — birth (7.2) and escape (this section) — shows no detectable budget dependence (never phrase this as flatly "budget-independent"; obligation 7); budget effects instead act \emph{downstream}, on growth, which 7.4 demonstrates. One exploratory observation points the same way and must be labeled exploratory/uncorrected: near the cliff the onset RATE was monotone in cash ($f = 0.174$: 0.45/0.62/0.70 tight→loose; $f = 0.177$ KM medians 1,598/1,427/1,208) — a growth-gating signature upstream of the 5\%-cluster onset trigger, since a faster-growing front reaches the trigger sooner.
  - Figure block for `figs/ModelB-Nucleation-BarrierLaw.pdf` (`\label{fig:mb-barrier}`): caption states the three Model B divergence curves with the Model A reference curve, KM medians as points, fitted curves drawn to a display ceiling so the medians are not crushed by the divergence, and censoring detail deferred to Appendix~\ref{app:censoring}.
  - The fit table, verbatim (values transcribed from `ModelB-Nucleation-EscapeTime-Fits.csv`; Model A row from the Section 6 fit):

```latex
\begin{table}[tb]
\centering
\caption{Kramers escape-law fits $\ln\tilde\tau = A + B/(f - f_0)$ to
Kaplan--Meier median onset times, per cash level, with the Model~A fit for
reference. Brackets are 95\% bootstrap CIs (2{,}000 resamples of seeds
within each~$f$). The cash-500 $f_0$ lower bound of $0.000$ is the physical
boundary of the fit domain, not a data quantile. CIs overlap between tight
(500) and loose (5000) cash on both $B$ and $f_0$: no detectable barrier
shift.}
\label{tab:kramers-fits}
\small
\begin{tabular}{lccccc}
\toprule
Configuration & $n_f$ & $A$ & $B$ & $f_0$ & $R^2$ \\
\midrule
Model~A (reference)  & 12 & 2.78 & 0.389 & 0.101 & 0.991 \\
Model~B, cash 500    & 5  & 3.38 & 0.247~[0.070, 1.135] & 0.112~[0.000, 0.153] & 0.978 \\
Model~B, cash 1000   & 6  & 3.80 & 0.143~[0.071, 0.691] & 0.135~[0.048, 0.152] & 0.990 \\
Model~B, cash 5000   & 6  & 4.10 & 0.098~[0.050, 0.415] & 0.143~[0.077, 0.157] & 0.980 \\
\bottomrule
\end{tabular}
\end{table}
```
- [ ] **Step 2: Build.**
- [ ] **Step 3: Commit** — `git commit -m "Add 7.3: budgets do not move the barrier (Kramers fits + table)"`

### Task 8: 7.4 "Growth Is Gated at the Boundary"

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — append after 7.3.

**Interfaces:**
- Consumes: `paper-arxiv/figs/ModelB-Nucleation-Seeding.pdf`, `ModelB-Nucleation-VelocitySuppression.pdf` (Task 1).
- Produces: `\label{sec:mb-gating}`, `\label{fig:mb-seeding}`, `\label{fig:mb-velsupp}`.

- [ ] **Step 1: (optional but recommended) Recompute the within-dose Spearman values for exact citation** — the range −0.38 to −0.52 comes from the Phase 1 final review; to cite per-dose values, run:

```julia
# julia --project=code, run from repo root
include("code/model-b/Include.jl"); include("code/model-b/EscapeTime-Lib.jl")
using CSV, DataFrames
df = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-EscapeTime.csv"), DataFrame)
sl = df[(df.f .== 0.20) .& .!df.censored .& .!ismissing.(df.v_front), :]
for g in groupby(sl, :cash)
    println(g.cash[1], " n=", nrow(g), "  rho=", spearman_rho(g.v_front, g.suppb_w))
end
```
(Adapt to the lib's actual exported names — check `EscapeTime-Lib.jl` for `spearman_rho`/`spearman_perm_p` signatures and the CSV's censoring/window-validity flags before running; the A2 analysis in `Figs-ModelB-VelocitySuppression.jl` shows the canonical filtering.) If the recompute is awkward, cite the range −0.38 to −0.52 without per-dose values.

- [ ] **Step 2: Write 7.4.** `\subsection{Growth Is Gated at the Boundary}\label{sec:mb-gating}` Content requirements:
  - Stamped-seed rejection: a $3\times3$ sell patch stamped into the grid NEVER founded the winning domain — dominance 0/20 in all six configuration×placement cells; forward lineages grew to 9–15 cells and died, never alive at onset; no placement advanced onset. The interior does not lack seeds; single-cell fluctuations (7.2) supply them constantly — what is scarce is growth.
  - The one nominal placement effect, with obligation 1 attached in the same sentence: the freeze-configuration mid-grid patch \emph{delayed} onset (median $-257$ steps, sign-flip $p = 0.0238$) — an exploratory observation, uncorrected across a six-test family, failing the Bonferroni threshold of 0.0083, and resting on a sign-flip of the mean; we report it as a lead, not a result.
  - The A2 dose-response, phrased per obligation 6: across the five budget doses at $f = 0.20$ (cash 250–5,000; $n = 97$ included, 3 excluded by the window rule), front velocity fell as the \emph{absolute} suppression rate rose — pooled Spearman $\rho = -0.372$, permutation $p = 0.0003$ — and the relationship held within every dose ($\rho$ between $-0.38$ and $-0.52$; leave-one-dose-out $p \le 0.0014$), so it is not a between-dose confound. State the shape honestly: median suppression varied little across doses (517–595 orders/step) and median velocity was U-shaped in cash, so the supported claim is the pooled (and within-dose) negative velocity--suppression relationship, NOT a monotone-in-cash dose ladder.
  - Close the loop: birth is bulk and free (7.2), escape shows no detectable budget dependence (7.3), and the budget's lever is the growth rate of the front — with the conduit identified causally in 7.5.
  - Two figure blocks: `figs/ModelB-Nucleation-Seeding.pdf` (`\label{fig:mb-seeding}`; caption: stamped-patch outcomes across placements and configurations, dominance 0/20 everywhere, the freeze/mid delay flagged exploratory in the caption too) and `figs/ModelB-Nucleation-VelocitySuppression.pdf` (`\label{fig:mb-velsupp}`; caption: velocity vs mean absolute suppressed-buy orders per step, per-cash medians marked, $\rho = -0.372$, permutation $p = 0.0003$, $n = 97$).
- [ ] **Step 3: Build.**
- [ ] **Step 4: Commit** — `git commit -m "Add 7.4: growth is gated at the boundary"`

### Task 9: 7.5 "The Intervention Asymmetry"

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — append after 7.4, closing Section 7.

**Interfaces:**
- Consumes: `paper-arxiv/figs/ModelB-Nucleation-BudgetToggle.pdf`, `ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf` (Task 2).
- Produces: `\label{sec:mb-intervention}`, `\label{fig:mb-toggle}`, `\label{fig:mb-edgetrace}`; the asymmetry framing consumed by Discussion (Task 13), Introduction (Task 15), Abstract (Task 16).

- [ ] **Step 1: Write 7.5.** `\subsection{The Intervention Asymmetry}\label{sec:mb-intervention}` Content requirements:
  - Design recap in one sentence (paired counterfactuals, cash scaled at onset, W = 400 window; Methods).
  - Injection accelerates the crash (obligation 5 phrasing): scaling cash $\times 10$ at onset in the tight (cash 500) configuration \emph{accelerated} the front in 14 of 19 seeds (sign test $p = 0.064$; we report the count and $p$ as-is): median velocity $1.39 \to 3.55 \times 10^{-4}$ grid fractions per step, front extent at onset+400 $0.112 \to 0.192$, suppressed buys down 29\%.
  - The mechanism is price-mediated boundary gating, not interface starvation: sells need shares, not cash, and the interior CA never sees the books — the only conduit from budgets to the front is executed flow → price → edge bands → boundary ring. The edge trace showed injection flipping the contrarian ring instantly at the toggle from ${\sim}0.5$ Buy / 0 Sell to 0 Buy / ${\sim}1.0$ Sell — injected cash executes the queued buys, the supported price ($113$ vs $93$ at onset+400) breaks above the upper band, and the whole contrarian ring dumps — decaying back over 100–200 steps as the EMA band catches up. The boundary switches from brake to accelerant; a sign reversal, not a modulation.
  - Withdrawal is null at BOTH doses — the asymmetry is real, not dosing: $\times 0.1$ left suppressed buys $+7\%$ ($p = 0.65$); $\times 0.01$ \emph{binds} (cash ${\sim}50 <$ price; buys die; suppressed buys $524 \to 680$ per step) yet velocity moved $2.23 \to 2.38 \times 10^{-4}$ (11/19 seeds, $p = 0.29$) and the price barely moved ($123.6$ vs $119.5$). The trace explains why: the control ring is already ${\sim}0.46$ Buy post-onset — a saturated brake — and the cut only strengthens it transiently (Buy to ${\sim}0.72$–$0.74$, relaxing back by ${\sim}200$ steps).
  - The two-part explanation: (i) ceiling and sign — only injection can \emph{reverse} the boundary's sign, withdrawal merely tweaks an engaged brake; (ii) crashes self-finance their stabilizers — each front recruit sells up to its 10-share endowment at $P \approx 100$–$120$, banking ${\sim}1{,}000$ in fresh cash, so cutting the cash \emph{stock} cannot stop the cash \emph{flow} the sell wave generates for its own dip-buyers.
  - Name the frame: a \emph{liquidity-intervention asymmetry} — injections prop the price, flip the contrarian boundary to selling, and accelerate the sentiment crash; withdrawals are near-inert. Hand off to the Discussion.
  - Two figure blocks: `figs/ModelB-Nucleation-BudgetToggle.pdf` (`\label{fig:mb-toggle}`; caption: paired front trajectories and velocity shifts per arm; injection 14/19 accelerated, $p = 0.064$; withdrawal null at both doses) and `figs/ModelB-Nucleation-BudgetToggle-EdgeTrace.pdf` (`\label{fig:mb-edgetrace}`; caption: edge-ring Buy/Sell composition around the toggle; injection flips the ring $0.5$-Buy $\to {\sim}1.0$-Sell then decays over 100–200 steps; withdrawal transiently deepens an already-engaged brake).
- [ ] **Step 2: Build.**
- [ ] **Step 3: Commit** — `git commit -m "Add 7.5: the liquidity-intervention asymmetry"`

### Task 10: Section 6 — promote the theory subsections with bridge framing

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — insert `\section` header immediately BEFORE `\subsection{Potts Energy Mapping}` (currently line 945); insert an outro paragraph after the Nucleation Theory "Summary" paragraph (currently ends line 1142); add Kramers citations.

**Interfaces:**
- Consumes: bib keys `kramers1940brownian`, `hanggi1990reaction` (Task 3); `\ref{sec:results-b}` (Task 5).
- Produces: `\label{sec:theory}`; the framing "the law Model B must answer" consumed by 7.3's opening and the Introduction.

- [ ] **Step 1: Insert the section wrapper and bridge intro:**

```latex
% ============================================================================
\section{Theory: The Nucleation Barrier}
\label{sec:theory}
% ============================================================================
```
followed by a bridge paragraph (prose): Results I established WHAT happens — a discontinuous transition with spatially coherent fronts; this section establishes WHY, by a hierarchy of approximations that progressively eliminates every non-spatial explanation (mean-field fails, pair approximation fails, nucleation succeeds), terminating in a quantitative escape law; that law — $\ln\bar\tau = 2.78 + 0.389/(f - 0.101)$, $R^2 = 0.991$ — is the quantitative claim Model B must answer in Results II: if budget constraints change the physics of the transition, they must move this barrier.
- [ ] **Step 2: Add the Kramers citations** in the "Kramers escape scaling" paragraph: cite `kramers1940brownian` at the first mention of the Kramers form and `hanggi1990reaction` for the modern rate-theory context.
- [ ] **Step 3: Add the outro paragraph** after the Summary paragraph: the barrier picture makes three falsifiable predictions for the budget-constrained model — escape times should still diverge as $A + B/(f-f_0)$ if nucleation survives; any budget effect on nucleation itself must appear as a shift in $(B, f_0)$; and if budgets act elsewhere, the law should hold with the SAME barrier while growth-sensitive observables move — and Results II (`Section~\ref{sec:results-b}`) tests exactly these.
- [ ] **Step 4: Build; commit** — `git commit -m "Promote theory subsections to Section 6 with nucleation-barrier bridge framing"`

### Task 11: Results I — retitle, frame, and fix the Fig 3 caption

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — `\section{Results and Discussion}` (currently line 867), the 5.1/5.2 intro sentences, Fig 3 caption (currently lines 935–940).

**Interfaces:**
- Produces: retitled `\section{Results I: Model~A, the Clean Nucleation Baseline}` keeping `\label{sec:results}` (the Introduction roadmap references it).

- [ ] **Step 1: Retitle the section** to `Results I: Model~A, the Clean Nucleation Baseline`, keeping `\label{sec:results}`, and add a 2–3 sentence section lead naming the role this act plays: Model A is the unconstrained baseline in which a sell nucleus, once formed, runs to completion — the clean phenomenon that the Theory section quantifies and Model B constrains.
- [ ] **Step 2: Light nucleation framing pass over 5.1–5.2** (targeted edits only, not a rewrite): where 5.1 describes the $t = 8{,}236$ cascade, name it explicitly as nucleation-and-growth (localized seed, coherent front, spatial history); where 5.2 interprets the transition, connect "coordination failure" to the metastability language the Theory section formalizes. Do not touch the numbers.
- [ ] **Step 3: Fix the Fig 3 caption style** — change `\textbf{A:}~`, `\textbf{B:}~`, `\textbf{C:}~` to the Fig 1 non-bold style `A:~`, `B:~`, `C:~`.
- [ ] **Step 4: Build; commit** — `git commit -m "Retitle Results I as the clean nucleation baseline; fix Fig 3 caption style"`

### Task 12: Related Work — the metastability and liquidity-intervention paragraph

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — add ONE paragraph at the end of subsection 2.2 (after the paragraph ending `...suggesting that the structure of interaction may matter more than the sophistication of individual decision rules.`, currently line 658), before the "Our approach generalizes..." positioning paragraph.

**Interfaces:**
- Consumes: bib keys `bouchaud2013crises`, `sornette2003endogenous` (already in bib), `brunnermeier2009market`, `kirilenko2017flash`, `subrahmanyam1994circuit`, `farhi2012collective`.

- [ ] **Step 1: Write the paragraph.** Content requirements: metastability and nucleation as an organizing idea in economics — Bouchaud's program of collective socio-economic phenomena treats crises as barrier-crossing transitions between metastable states (`bouchaud2013crises`), and the endogenous/exogenous decomposition of Sornette and Helmstetter locates large events in internal dynamics (`sornette2003endogenous`) — yet the nucleation picture has rarely been made quantitative at the agent level; and the liquidity-intervention literature — funding and market liquidity spirals (`brunnermeier2009market`), the Flash Crash record (`kirilenko2017flash`), circuit breakers (`subrahmanyam1994circuit`), and bailout-induced moral hazard (`farhi2012collective`) — studies interventions on real markets where counterfactuals are unobtainable; our contribution sits at the join: a model minimal enough to measure the barrier and run the counterfactual intervention exactly.
- [ ] **Step 2: Build; commit** — `git commit -m "Add related-work paragraph: metastability in economics and liquidity interventions"`

### Task 13: Discussion (new Section 8)

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — insert `\section{Discussion}\label{sec:discussion}` between the end of Section 7 (after 7.5) and `\section{Conclusion}`.

**Interfaces:**
- Consumes: results from Tasks 5–9; bib keys `farhi2012collective`, `brunnermeier2009market`, `subrahmanyam1994circuit`, `kirilenko2017flash`.
- Produces: `\label{sec:discussion}`; limitation statements the Conclusion may echo.

- [ ] **Step 1: Write the Discussion** (flowing prose; paragraph headings allowed but prefer none). Content requirements, one paragraph each:
  - The asymmetry as a micro moral-hazard analog: in the model, liquidity support does not merely fail to stop the sentiment crash — it recruits the contrarian boundary into accelerating it, while withdrawal is inert because crashes self-finance their own dip-buyers; connect to collective moral hazard (`farhi2012collective`) and liquidity-spiral intuitions (`brunnermeier2009market`), with the explicit caveat that the mechanism runs through a stylized contrarian band rule and the analogy is structural, not calibrated.
  - What the model says about WHERE policy can act: since nucleation shows no detectable budget dependence (7.3) and budgets gate growth at the boundary (7.4), interventions that target order flow at the growing interface (circuit-breaker-like arrest, `subrahmanyam1994circuit`) address the controllable stage, while interventions on aggregate liquidity address the wrong stage — stated as a model-generated hypothesis, not policy advice.
  - Limitations (fold the existing Conclusion "Limitations" content in here, updated): single $64\times64$ grid for the Model B campaigns and a single asset; QQQ boundary data validates only Model A; deterministic rules without learning; the annealed treatment of contrarian disorder in the theory; the exploratory flags of 7.3 (onset-rate-in-cash) and 7.4 (freeze/mid delay) are uncorrected observations; the barrier-shift null is a power-bounded statement (obligation 7 phrasing again).
  - Rule-space generality, brief: the full $3^9$ rule space is enumerable and the majority/contrarian pair is one point in it; a systematic screen of the space is future work (do NOT elaborate a strategy — the 4-move compression stays parked).
- [ ] **Step 2: Build; commit** — `git commit -m "Add Discussion: moral-hazard analog, intervention staging, limitations, generality"`

### Task 14: Conclusion rewrite

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — replace the body of `\section{Conclusion}` (currently lines 1150–1221; its Limitations/Future-directions paragraphs were absorbed by Task 13's Discussion — delete them here).

**Interfaces:**
- Consumes: the full arc (Tasks 5–13).

- [ ] **Step 1: Rewrite the Conclusion around the arc** (shorter than the current one; no `\paragraph{}` blocks). Content requirements: restate the three acts — a minimal CA market where crashes are nucleation events with spatial histories (Model A; first-order transition at $f_c \approx 0.145$ at the simulation horizon); a quantitative barrier established by elimination (mean-field and pair approximation fail; Kramers law $\ln\bar\tau = 2.78 + 0.389/(f - 0.101)$, $R^2 = 0.991$, absolute stability below $f_0 \approx 0.10$); and the budget-constrained fate of the same nucleus — the law survives all cash levels with no detectable barrier shift, births are bulk and free, budgets gate front growth through the price-mediated boundary, and the practical face of that gating is the liquidity-intervention asymmetry. Close with the two future directions worth keeping: a quenched-disorder nucleation calculation predicting $(B, f_0)$ from first principles, and the systematic rule-space screen the enumerable framework makes possible.
- [ ] **Step 2: Build; commit** — `git commit -m "Rewrite Conclusion around the arrested-nucleation arc"`

### Task 15: Introduction rewrite

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — rewrite paragraphs 3–4 of the Introduction (the "In this paper, we close that gap..." paragraph, currently lines 117–139, and the roadmap paragraph, currently lines 140–144). Paragraphs 1–2 (crash phenomenology + literature gap) need only a targeted extension.

**Interfaces:**
- Consumes: contributions from all Results tasks; `\ref{sec:theory}`, `\ref{sec:results-b}`, `\ref{sec:discussion}` labels.

- [ ] **Step 1: Extend paragraph 1** with the question shift: from "when do markets crash" to "what decides a nucleus's fate" — crashes as nucleation events whose birth, escape, and growth are separable stages, and whose fate under realistic constraints (finite budgets) is the object of study.
- [ ] **Step 2: Rewrite the contributions paragraph** around four contributions, in the spec's order, each with its headline number: (i) a minimal CA market with a first-order transition ($f_c \approx 0.145$) and spatially coherent crash fronts (Model A); (ii) a quantitative nucleation barrier — zero-temperature Potts mapping plus the Kramers escape law $\ln\bar\tau = 2.78 + 0.389/(f-0.101)$, $R^2 = 0.991$; (iii) the same nucleus under finite budgets has a budget-gated fate — the escape law survives every cash level with no detectable barrier shift, nuclei are bulk-born, and budgets gate growth through a price-mediated contrarian boundary (Model B); (iv) a liquidity-intervention asymmetry: injections flip the stabilizing boundary into an accelerant (14/19 seeds), withdrawals are inert because crashes self-finance their dip-buyers.
- [ ] **Step 3: Update the roadmap paragraph** to the new section map (Background, Methods, Results I, Theory, Results II, Discussion, Conclusion — using the existing `Section~\ref{...}` convention with the new labels).
- [ ] **Step 4: Build; commit** — `git commit -m "Rewrite Introduction: nucleus-fate question and four contributions"`

### Task 16: Abstract rewrite (last, once the arc is real)

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — replace the abstract body (currently lines 64–81).

- [ ] **Step 1: Rewrite the abstract.** Beat structure (one flowing paragraph, lab voice, ~180–220 words): (1) markets crash without proportionate shocks; we ask what decides the fate of a crash nucleus, not just when crashes happen; (2) minimal model — 2D grid, three states, two Wolfram totalistic rules differing in one digit, minority fraction $f$ the single control; (3) Model A: first-order transition ($f_c \approx 0.145$), crashes nucleate and propagate as coherent fronts; (4) the barrier is quantitative: mean-field and pair approximations fail, and the metastable lifetime obeys a Kramers law diverging at $f_0 \approx 0.10$; (5) Model B (endogenous price, per-agent budgets): the SAME escape law survives every budget level with no detectable barrier shift; budgets instead gate front GROWTH through a price-mediated contrarian boundary; (6) the payoff: a liquidity-intervention asymmetry — cash injections flip the stabilizing boundary into an accelerant while withdrawals are inert, because crashes finance their own dip-buyers; (7) the rule space is finite and enumerable, so the framework supports systematic screening. Constraints: mention BOTH models by name; do not use the word "significant" anywhere near the toggle result; keep every number consistent with the sections (0.145, 0.10; no p-values in the abstract).
- [ ] **Step 2: Build; commit** — `git commit -m "Rewrite abstract around the arrested-nucleation arc"`

### Task 17: Appendices A–C + Acknowledgments stub handling

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex` — replace the appendix stub (currently lines 1232–1237) with three appendix sections; comment out the Acknowledgments TODO.

**Interfaces:**
- Consumes: `code/model-a/PairApproximation.jl` (implementation being described); `code/data/ModelB-Nucleation-EscapeTime.csv` (censoring counts); Stage 2 CSVs; resolves forward references `app:stage2` (Task 4/5), `app:censoring` (Task 7).
- Produces: `\label{app:pair}`, `\label{app:stage2}`, `\label{app:censoring}`. Update the Pair Approximation subsection's pointer "(see Supplementary Material for the full derivation)" to `(Appendix~\ref{app:pair})`.

- [ ] **Step 1: Appendix A — pair-approximation derivation** (`\section{Pair-Approximation Derivation}\label{app:pair}`). The derivation must match `code/model-a/PairApproximation.jl` exactly. Content, with equations:
  - Annealed effective rule: $R_f(c \to b) = (1-f)\,\mathbb{1}[\mathcal{R}_{19280}(c) = b] + f\,\mathbb{1}[\mathcal{R}_{19286}(c) = b]$ — the two tables differ only at $c = 1$.
  - State: symmetric pair densities $\rho_{ab}$, $a, b \in \{0,1,2\}$, $\sum_{ab}\rho_{ab} = 1$; marginals $\rho_a = \sum_b \rho_{ab}$; conditionals $q(s \mid a) = \rho_{as}/\rho_a$.
  - Trinomial sum of the three non-partner neighbors: $\Pr(m = k \mid a) = \sum_{\substack{n_0+n_1+n_2=3\\ n_1+2n_2=k}} \binom{3}{n_0, n_1, n_2}\, q(0\mid a)^{n_0} q(1\mid a)^{n_1} q(2\mid a)^{n_2}$, $k = 0,\dots,6$.
  - Transition kernel: $T_b(a, a') = \sum_{k=0}^{6} \Pr(m = k \mid a)\; R_f(a' + k \to b)$ — the focal site's neighborhood sum is the partner's state plus the trinomial sum (the Gutowitz local-structure closure, cite `gutowitz1987local`).
  - Synchronous pair update: $\rho'_{bb'} = \sum_{a,a'} \rho_{aa'}\, T_b(a, a')\, T_{b'}(a', a)$ (Eq. \ref{eq:pair-update} of the main text).
  - Numerical protocol: iteration to $\lVert \rho' - \rho \rVert_1 < 10^{-14}$; the $6\times6$ Jacobian on the independent components $(\rho_{00}, \rho_{01}, \rho_{02}, \rho_{11}, \rho_{12}, \rho_{22})$ computed by finite differences with step $\delta = 10^{-7}$ at the uncorrelated fixed point; correlated initial conditions with same-state correlation $\varepsilon \in [0.1, 0.5]$, buy- and sell-biased; spectral radius $< 1$ for all $f \in [0,1]$ (0.95 at $f = 0$ to 0.71 at $f = 0.5$), every trajectory converging to the uncorrelated buy-dominated or all-Sell fixed point.
- [ ] **Step 2: Appendix B — Stage 2 factorial detail** (`\section{Model~B Stage~2 Factorial}\label{app:stage2}`). Content: the six factors and levels (from Task 4's Methods list, repeated in a small `booktabs` table — factor, levels); the regime classifier in strict decision order — inert (zero return std), crash-prone (crash frequency $\ge 0.01$, where a crash step has Sell fraction $\ge 0.5$), oscillatory ($\ge 20$ $\varphi$ sign flips per 2{,}000 steps — state the per-step normalization per obligation 4), plateau (price range $< 0.10\,P_0$), drift (otherwise); realized counts 6,589 oscillatory / 4,211 crash-prone / 0 for the other three; variance decomposition — sweep knobs 94–98\% of variance across summary metrics, seed $\le 5.4\%$; the freeze-vs-tail decomposition of crash-prone runs (median max drawdown ${\sim}5\%$, median price minimum 100.00; 897 runs below 90, 451 below 80, worst collapses 40–69\% after 2.5–2.7$\times$ bubbles at $f{=}0.2$, $\lambda{=}0.05$, cash 5000, disposition off).
- [ ] **Step 3: Appendix C — escape-time censoring and survival detail** (`\section{Escape-Time Censoring and Survival Detail}\label{app:censoring}`). Content: the censoring rule ($\tau$ right-censored at 2,000 steps; censored runs enter the Kaplan--Meier estimator, never dropped); per-(f, cash) onset counts — extract with:

```bash
python3 - <<'EOF'
import csv
from collections import defaultdict
d = defaultdict(lambda: [0, 0])
for row in csv.DictReader(open('code/data/ModelB-Nucleation-EscapeTime.csv')):
    key = (row['f'], row['cash'])
    d[key][0] += 1
    d[key][1] += (row['censored'] in ('true', 'True', '1'))
for (f, cash), (n, c) in sorted(d.items(), key=lambda kv: (float(kv[0][1]), float(kv[0][0]))):
    print(f"f={f} cash={cash}  n={n}  censored={c}  onset_rate={(n-c)/n:.2f}")
EOF
```
Report these counts in a small table (f × cash: n, censored, onset rate); state which (f, cash) cells had a defined KM median (the fit used 5/6/6 points for cash 500/1000/5000) and why cash 500 has one fewer (at $f = 0.174$ the onset rate was 0.45, below the 0.5 needed for a finite median, which triggered the second-pass refinement at $f = 0.177$); the bootstrap procedure (2,000 resamples of seeds within each f, refit per resample, percentile CIs); the exploratory onset-rate observation (0.45/0.62/0.70 at $f = 0.174$; KM medians 1,598/1,427/1,208 at $f = 0.177$) labeled uncorrected here as in 7.3.
- [ ] **Step 4: Fix the dangling supplement pointer** — in the Pair Approximation subsection change `(see Supplementary Material for the full derivation)` to `(Appendix~\ref{app:pair})`.
- [ ] **Step 5: Comment out the Acknowledgments TODO** (`% TODO: Acknowledgments here.` with the `\section*` kept commented too) so no TODO text can reach the built PDF; flag in the final report that the user must supply acknowledgments before arXiv submission.
- [ ] **Step 6: Build** — this build must now have ZERO undefined references (app:stage2 and app:censoring resolve).
- [ ] **Step 7: Commit** — `git commit -m "Write appendices: pair-approximation derivation, Stage 2 factorial, censoring detail"`

### Task 18: Retire the casualties

**Files:**
- Delete: `code/model-b/Fig4-ClosedLoop.jl`, `code/model-b/Fig5-PhaseDiagram.jl`, `code/comparison/Fig6-ReturnDistributions.jl`, `code/comparison/Fig7-SOC.jl`, `code/comparison/Fig8-MeanField.jl`, `code/comparison/Table2-StylizedFacts.jl` (all six carry STALE markers)
- Delete: `paper-arxiv/figs/{Fig4-ClosedLoop,Fig5-PhaseDiagram,Fig6-ReturnDistributions,Fig8-MeanField}.pdf` and the same four from `code/figs/`
- Delete: `paper-arxiv/figs/Probe-ModelB-Nucleation-{Grids,Clusters}.pdf` (probe superseded by the seed sweep; obligation 3 — the `code/figs/` copies stay)
- Delete: `paper-arxiv/sections/` (entire directory — March-era template leftovers; `Paper_v1.tex` contains no `\input`)

Fig8-MeanField retires because Section 6 (Task 10) claims no figure — the spec's condition for retention is not met.

- [ ] **Step 1: Guard — confirm nothing references the casualties**

```bash
grep -n "Fig4-ClosedLoop\|Fig5-PhaseDiagram\|Fig6-ReturnDistributions\|Fig8-MeanField\|Probe-ModelB\|sections/" paper-arxiv/Paper_v1.tex
grep -rn "Fig4-ClosedLoop\|Fig5-PhaseDiagram\|Fig6-ReturnDistributions\|Fig7-SOC\|Fig8-MeanField\|Table2-StylizedFacts" code --include="*.jl" | grep -v "^code/model-b/Fig4\|^code/model-b/Fig5\|^code/comparison/"
```
Expected: no matches in `Paper_v1.tex`; no references from surviving scripts. If any match appears, STOP and report instead of deleting.
- [ ] **Step 2: Delete with git rm**

```bash
git rm code/model-b/Fig4-ClosedLoop.jl code/model-b/Fig5-PhaseDiagram.jl \
       code/comparison/Fig6-ReturnDistributions.jl code/comparison/Fig7-SOC.jl \
       code/comparison/Fig8-MeanField.jl code/comparison/Table2-StylizedFacts.jl \
       paper-arxiv/figs/Fig4-ClosedLoop.pdf paper-arxiv/figs/Fig5-PhaseDiagram.pdf \
       paper-arxiv/figs/Fig6-ReturnDistributions.pdf paper-arxiv/figs/Fig8-MeanField.pdf \
       code/figs/Fig4-ClosedLoop.pdf code/figs/Fig5-PhaseDiagram.pdf \
       code/figs/Fig6-ReturnDistributions.pdf code/figs/Fig8-MeanField.pdf \
       paper-arxiv/figs/Probe-ModelB-Nucleation-Grids.pdf paper-arxiv/figs/Probe-ModelB-Nucleation-Clusters.pdf
git rm -r paper-arxiv/sections
ls code/comparison/ 2>/dev/null   # if now empty, git already removed it
```
- [ ] **Step 3: Rebuild to prove the paper never needed them** — `cd paper-arxiv && bash Build.sh Paper_v1`. Expected: clean, zero undefined references.
- [ ] **Step 4: Commit** — `git commit -m "Retire stale legacy figures, scripts, and the dead sections/ directory"`

### Task 19: Final verification and obligation audit

**Files:**
- Read/verify only (fix-in-place edits to `paper-arxiv/Paper_v1.tex` if audits fail, then re-commit).

- [ ] **Step 1: Full clean build** — `cd paper-arxiv && bash Build.sh Paper_v1`; then

```bash
grep -c "LaTeX Warning: Reference" paper-arxiv/Paper_v1.log ; grep -c "LaTeX Warning: Citation" paper-arxiv/Paper_v1.log
```
Expected: `0` and `0` (grep -c exits 1 on zero matches — that IS the pass condition).
- [ ] **Step 2: Julia tests still green** (the only code touched was savefig call sites, but verify):

```bash
julia --project=code code/model-b/Test-EscapeTime.jl
julia --project=code code/model-b/Test-BoundaryVsBulk.jl
```
Expected: all tests pass.
- [ ] **Step 3: Seven-obligation audit** — for each obligation, locate the claim in `Paper_v1.tex` and verify the required phrasing (grep is a locator, not the judge; read the sentence):
  1. Every mention of the freeze/mid-patch delay carries exploratory/uncorrected/Bonferroni language (7.4 body, fig:mb-seeding caption).
  2. `grep -n "9652" paper-arxiv/Paper_v1.tex` — the exemplar caption states BOTH the atypical-tail and majority-sell caveats.
  3. `grep -n "0\.66\|0\.72" paper-arxiv/Paper_v1.tex` — 0.66 must not appear as a cluster ratio; 0.72 may appear ONLY as the edge-trace Buy fraction 0.72–0.74 in 7.5.
  4. Oscillatory-regime definition (Appendix B) states the per-2,000-steps normalization; `grep -in "pooled std\|error bar" Paper_v1.tex` confirms Stage 2 marginal error bars are never cited as uncertainty.
  5. `grep -n "0\.064" paper-arxiv/Paper_v1.tex` — present; the surrounding sentence does not call it significant (`grep -in "significant" Paper_v1.tex` and check each hit).
  6. 7.4 states the pooled + within-dose phrasing, mentions the U-shape and the 517–595 suppression range, and contains no monotone-in-cash dose-ladder claim.
  7. `grep -in "detectable" paper-arxiv/Paper_v1.tex` — 7.3 and the table caption use "no detectable barrier shift"; the f0-lower-bound-is-boundary note is present.
- [ ] **Step 4: Style and review skills over the rewritten prose** — run the `style-check`, `review-section`, and `audit-magic-numbers` skills on the paper, interpreting `style-check` per the Global Constraints arXiv adaptations (dash rules, heading rules, `Section~\ref` roadmap, and PNAS-template rules are waived; the no-bullets rule is enforced). Fix real findings; record the waived ones.
- [ ] **Step 5: Confirm the spec's verification checklist** (spec Part 3) is fully satisfied and append a short "Phase 2 execution" note to the spec's Amendments section recording: date, any deviations taken during execution, and the RegimeMap-not-promoted decision.
- [ ] **Step 6: Final commit** — `git add -A && git commit -m "Record Phase 2 execution outcome in the nucleation-spine spec"`. Do NOT push; report to the user that main is ahead of origin and awaiting their push, and that Acknowledgments needs their content before arXiv submission.
