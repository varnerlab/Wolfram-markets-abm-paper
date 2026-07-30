# Author-Queue Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the 14-item author decision queue from the market-strip campaign's review-section pass plus the post-merge code cleanup ticket, per the user's directive "fix all these issues" and their three recorded decisions.

**Architecture:** Three tasks with disjoint file sets: (1) results.tex prose + new bibliography entries + one conclusion.tex citation; (2) appendix.tex polish batch + SI table renumbering + a Methods note on the Fig 5 exemplar filter + sanctioning appendix refs in the review-section skill; (3) code-side cleanup (shared letter-row helper, stale comments, a two-sided assert, Fig 3 panel B label legibility) with figure regeneration and a paper rebuild.

**Tech Stack:** LaTeX (pdflatex + bibtex via `bash build.sh Paper_v1` from inside `paper-arxiv/`), Julia/Plots.jl (`julia --project=code code/<dir>/<script>.jl` from repo root).

## Global Constraints

- USER DECISIONS (2026-07-29, binding): `Appendix~\ref{app:...}` pointers are SANCTIONED house style (do not remove them; document the exception in the review-section skill); SI tables renumber to S1/S2; the abstract and Acknowledgments are OUT OF SCOPE.
- LaTeX prose gates (zero tolerance): no `\ref{sec:...}`-style section self-refs, no itemize/enumerate, no em/en dashes in narrative, figure refs parenthetical and never sentence-subject, whole-figure refs in beat leads, panel refs in body sentences, Results in past tense, no promotional intensifiers.
- Palette and style are a CONTRACT: use only `_BUY_COLOR/_HOLD_COLOR/_SELL_COLOR/_EDGE_COLOR`, `_SERIES_COLORS`, `_panel_kw`, `_grid_cgrad()`, `_panel_letter!` from `code/src/PaperStyle.jl`. Never edit PaperStyle.jl. Shared strip idioms belong in `code/src/StripPanels.jl`; per-figure margins/legends in the figure assemblies.
- Figures save via `_save_figure` (writes `code/figs/` AND `paper-arxiv/figs/`). Do NOT regenerate campaign CSV/JLD2 caches; code-only edits must not change any figure's data.
- Paper build: from inside `paper-arxiv/`, `bash build.sh Paper_v1`; gates: `grep -c 'undefined refer' Paper_v1.log` = 0, page structure text → refs → Figs 1-7 → Tabs 1-2 → appendices → S-floats.
- Tracked build artifacts (Paper_v1.pdf/.aux/.fff/.log etc.) are committed alongside source changes, repo convention.
- Commit after every task; never amend; commit trailer (both lines):
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01WSePx8SXGESkPChNKs79Cc`
- Line numbers below are from the reviewing pass and are approximate; locate each edit by its quoted text. If a quoted string cannot be found verbatim, report it rather than improvising.

---

### Task 1: results.tex prose queue + bibliography

**Files:**
- Modify: `paper-arxiv/sections/results.tex`
- Modify: `paper-arxiv/References_v1.bib`
- Modify: `paper-arxiv/sections/conclusion.tex` (one citation)

**Interfaces:**
- Produces: bib keys `weibull1951statistical`, `kolmogorov1937statistical`, `johnson1939reaction`, `avrami1939kinetics`, `potts1952some` (Task 2/3 do not consume them; listed for cross-task uniqueness).

- [ ] **Step 1: Add five bibliography entries** to `References_v1.bib`, matching the file's existing key style:

```bibtex
@article{weibull1951statistical,
  author  = {Weibull, Waloddi},
  title   = {A statistical distribution function of wide applicability},
  journal = {Journal of Applied Mechanics},
  volume  = {18},
  number  = {3},
  pages   = {293--297},
  year    = {1951}
}
@article{kolmogorov1937statistical,
  author  = {Kolmogorov, Andrei N.},
  title   = {On the statistical theory of the crystallization of metals},
  journal = {Izvestiya Akademii Nauk SSSR, Seriya Matematicheskaya},
  volume  = {1},
  number  = {3},
  pages   = {355--359},
  year    = {1937}
}
@article{johnson1939reaction,
  author  = {Johnson, William A. and Mehl, Robert F.},
  title   = {Reaction kinetics in processes of nucleation and growth},
  journal = {Transactions of the American Institute of Mining and Metallurgical Engineers},
  volume  = {135},
  pages   = {416--442},
  year    = {1939}
}
@article{avrami1939kinetics,
  author  = {Avrami, Melvin},
  title   = {Kinetics of phase change. I. General theory},
  journal = {The Journal of Chemical Physics},
  volume  = {7},
  number  = {12},
  pages   = {1103--1112},
  year    = {1939}
}
@article{potts1952some,
  author  = {Potts, Renfrey B.},
  title   = {Some generalized order-disorder transformations},
  journal = {Mathematical Proceedings of the Cambridge Philosophical Society},
  volume  = {48},
  number  = {1},
  pages   = {106--109},
  year    = {1952}
}
```

- [ ] **Step 2: Weave the citations in** (grammatically, `~\cite{}` form):
  - Near :33, the brittle-fracture size-effect sentence ("It is the size effect of brittle fracture, where a bigger specimen fails at lower stress...") gains `~\cite{weibull1951statistical}`.
  - Near :33, the Avrami sentence ("Writing the converted fraction as $X(t) = 1 - \exp[-(Kt)^{n}]$ identifies that clock...") gains `~\cite{kolmogorov1937statistical,johnson1939reaction,avrami1939kinetics}`.
  - Near :62, the Potts mention gains `~\cite{potts1952some}` (see also Step 6 terminology edit, which rewrites this phrase).
  - `conclusion.tex:13` "Potts-inspired" gains `~\cite{potts1952some}`.

- [ ] **Step 3: Insert the ten missing panel references** (parenthetical, sentence-final; where a parenthesis already exists, put the figure ref first inside it):
  1. :11 "In the homogeneous model, $f = 0$, the grid settled into a fine-grained mixture" — append `(Figure~\ref{fig:crossover}A)` to this sentence (or to the "Three values of~$f$ fix the picture" sentence if it reads better there).
  2. :11 "Sweeping~$f$ from $0.0$ to $0.50$ at a fixed seed on a $128 \times 128$ lattice placed the change between the sampled values $f = 0.14$ and $f = 0.15$." — add `(Figure~\ref{fig:crossover}B)`.
  3. :11 "where crash frequency rose above $95\%$" — add `(Figure~\ref{fig:crossover}C)`.
  4. :33 "larger lattices crashed at lower contrarian fractions" — add `(Figure~\ref{fig:finite-size}B)`.
  5. :62 "On a $128 \times 128$ lattice it held at $e \approx -0.37$ and site entropy $S_1 \approx 1.06$ below the crossover and fell to $-0.93$ and $0.18$ above." — add `(Figure~\ref{fig:theory}A)`.
  6. :62 "Its Jacobian at the uncorrelated fixed point had spectral radius strictly below unity at every sampled~$f$, falling from $0.95$ at $f = 0$ to $0.71$ at $f = 0.5$" — add `(Figure~\ref{fig:theory}B)`.
  7. :94 the boundary-band/deep-bulk findings ("fell in the boundary band at a pooled fraction of $0.077$ ... the median founding cell sat a distance $12$ into the deep bulk") — add `(Figure~\ref{fig:nucleus}B,C)`, placed on the appropriate sentence(s) after the Step 8 run-on split; if the split yields one sentence per panel, use `(Figure~\ref{fig:nucleus}B)` and `(Figure~\ref{fig:nucleus}C)` separately.
  8. :122 the Kaplan--Meier fit sentence — extend its existing parenthesis to `(Figure~\ref{fig:growth-gating}B; Table~\ref{tab:kramers-fits}; Appendix~\ref{app:censoring})`.
  9. :122 "the front velocity fell as the absolute suppression rate rose, at a pooled Spearman $\rho = -0.372$ with permutation $p = 0.0003$" — add `(Figure~\ref{fig:growth-gating}C)`.
  10. :183 the injection acceleration finding — its parenthesis becomes `(Figure~\ref{fig:intervention}C; sign test $p = 0.064$)` (this replaces the old parenthesis; see Step 5 item 4).

- [ ] **Step 4: Resolve the fig:theory C forward reference.** The finite-size beat (:33) currently carries the cluster-criterion caveat ending "...its median largest-ever sell cluster reaching $98$~cells at $f = 0.145$ (Figure~\ref{fig:theory}C)", a forward reference into the theory beat's figure. Move the criterion-is-not-scale-free caveat (the clause chain from "That criterion is also not a scale-free detector of nucleation" through the 98-cells parenthetical) into the theory beat (:62), placing it with the cluster-size discussion so `(Figure~\ref{fig:theory}C)` no longer points forward; leave the 32×32-exclusion sentence in :33 (it is finite-size-specific) and keep both locations grammatical. The Step 7 semicolon fix at this spot makes the split point clean.

- [ ] **Step 5: Remove the six editorializing constructions** (exact replacements):
  1. :183 "and it runs opposite to the naive mechanism, which makes it diagnostic." → "and it runs opposite to the naive mechanism."
  2. :94 "A boundary that touches growth but not birth sharpens the question of which of the two a budget acts on." → "A boundary that touched growth but not birth left open which of the two a budget acts on."
  3. :122 "One comparison is worth flagging without promoting: between cash $1{,}000$ and $5{,}000$ near the threshold the intervals exclude zero" → "Between cash $1{,}000$ and $5{,}000$ near the threshold the intervals excluded zero" (keep the rest of the sentence, adjusting case).
  4. :183 "(sign test $p = 0.064$; we report the count and the $p$-value as they stand)" → "(Figure~\ref{fig:intervention}C; sign test $p = 0.064$)" (this is Step 3 item 10).
  5. :183 "Releasing the brake made the crash faster, and tightening it did nothing at all." → "Releasing the brake made the crash faster, and tightening it had no detectable effect."
  6. :183 "Withdrawal, which by symmetry ought to have braked the crash, did nothing of the kind at either dose" → "Withdrawal, which by symmetry ought to have braked the crash, did not, at either dose".

- [ ] **Step 6: Consistency and framing edits:**
  1. :11 drop the uniform-mixture comparison: delete ", close to the $1/3$ expected of a uniform random mixture of three states" and let the $0.26$ stand (the theory beat's marginals $0.49/0.24/0.26$ contradict the uniform framing).
  2. :62 rename the statistic: "the nearest-neighbor alignment statistic~$e$" → "the nearest-neighbor energy~$e$ of a three-state Potts model~\cite{potts1952some}" (harmonizes with the Figure 4A caption's "Potts energy~$e$"; fold with Step 2's citation so `\cite{potts1952some}` appears once here).
  3. :62 positive form: "is not a static equilibrium but a dynamic mixed-state attractor at $p_0 \approx 0.49$..." → "is a dynamic mixed-state attractor at $p_0 \approx 0.49$, $p_1 \approx 0.24$, $p_2 \approx 0.26$, not a static equilibrium" (keep any trailing clause).
  4. :94 lowercase "Sell fraction"/"Sell cells"/"Sell population" in the nucleus beat, EXCEPT where Sell names the CA state itself ("a single Sell cell" stays capitalized). Match the rest of the file's usage.
  5. :122 "on the $5$, $6$, and $6$ cells whose onset rate reached one half" → "on the $5$, $6$, and $6$ sweep points whose onset rate reached one half".
  6. Fig 7 caption: "although $11$ of its $19$ pairs individually fell" → "although only $8$ of its $19$ pairs individually rose" (removes the 11-of-19 collision with the harsh-arm prose).
  7. :183 add the mild-arm discordance to prose: extend the mild-cut finding so it reads that the mild cut "left the front statistically untouched (sign-flip permutation $p = 0.67$), its marginal medians rising from $2.23$ to $3.57$ even though only $8$ of $19$ pairs individually rose," before the suppression-load clause — the caption then confirms rather than corrects the prose. Coordinate with the Step 8 split of this sentence.
  8. :33 "since the mixed state threw up clusters of the same size unprompted" → "since the mixed state produced clusters of the same size unprompted" (this clause moves in Step 4; apply the wording change wherever it lands).
  9. :33 "certain conversion required $f \approx 0.155$ at $64 \times 64$" → "conversion in every seed required $f \approx 0.155$ at $64 \times 64$".
  10. :183 remove `\emph{}` from "accelerated", "instantly", "reverse", "further" (keep `\emph{sell}` and `\emph{bound}`).
  11. :94 "roughly $500$ dispersed fragments the largest of which" → "roughly $500$ dispersed fragments, the largest of which".

- [ ] **Step 7: Replace five connector semicolons with periods:**
  1. :33 "every lattice above the spreading threshold converts eventually; it decides only what has happened inside a fixed window." → "... converts eventually. It decides only what has happened inside a fixed window."
  2. :33 "so we kept it out of the conversion-curve fits; and that criterion is not a scale-free detector" → "... out of the conversion-curve fits. That criterion is also not a scale-free detector" (this is the Step 4 split point).
  3. :94 "at most $5.4\%$ to disorder seeds within a configuration; that decomposition is descriptive" → period.
  4. :122 "(...; Appendix~\ref{app:censoring}); the few points and the three free parameters make the curves descriptive" → period after the closing parenthesis.
  5. :183 "while withdrawals are near-inert; what that asymmetry would mean" → period.
  Keep the two earning semicolons at :33 ("all converted at $256 \times 256$ and above; certain conversion...") and :183 ("suppressed buys moving $+7\%$; the harsh cut..." — though Step 8 splits this sentence anyway).

- [ ] **Step 8: Split the four run-ons** (the two long beats' sentence medians are 48w against the ~25w house target):
  1. :183 mild/harsh 107-word sentence: break at the semicolon into a mild-cut sentence (which absorbs Step 6 item 7) and a harsh-cut sentence; break the harsh clause again after "$524$ to $680$ orders per step" so `\emph{bound}`/suppression-load and velocity/price are separate sentences.
  2. :94 boundary-versus-bulk 98-word sentence: break after the binomial parenthesis, and again before "with a median birth step of $256$"; place the Step 3 item 7 panel refs on the resulting sentences.
  3. :94 ratio/sigmoids 86-word sentence: split before "and the above-threshold trajectories formed time-shifted sigmoids".
  4. :183 ring-flip 91-word sentence: keep the colon and the three-step mechanism; split the decay clause ("the flipped state decaying back over the following $100$--$200$ steps...") into its own sentence, and move `(Figure~\ref{fig:intervention}B)` to the end of that new sentence so the colon follows its clause directly.

- [ ] **Step 9: Expand the setup preamble** (:7-9). Replace the three-sentence preamble with ONE developed past-tense paragraph that names both models and the shared protocol: Model A as the unconstrained spatial baseline (external prices, no budget filtering), Model B as the same rule pair and quenched disorder with endogenous price feedback and per-agent budgets; the lattice sizes, disorder-seed replication (20 seeds), and run horizons used by the beats; with the parameter/initial-condition table reference(s) in the lead parenthesis. Pull exact values and table labels from `methods.tex` and the existing beats (grep for `tab:` labels; verify every number against the source before asserting it). Obey the clean-lead rule: the lead sentence carries generic descriptors + refs, numbers go in follow-up sentences. Then delete the Model B introduction sentence from the tail of the theory beat (:62, "Model~B keeps these rules and this quenched disorder but adds endogenous price feedback...") and replace it with a bare transition into the nucleus beat.

- [ ] **Step 10: Build + gates.** From inside `paper-arxiv/`: `bash build.sh Paper_v1`. Check: `grep -c 'undefined refer' Paper_v1.log` = 0 (the new `\cite` keys must resolve — bibtex runs in build.sh); no overfull warnings introduced; render the Results pages and each edited caption's figure page (`pdftoppm -png -r 100 -f <p> -l <p> Paper_v1.pdf <scratch>/p`) and confirm the new panel refs name panels that exist. Run the zero-tolerance greps on results.tex and conclusion.tex (self-refs, itemize, em dashes): all zero.

- [ ] **Step 11: Commit** ("Results: panel references, canonical citations, and the review-section prose queue") — .tex, .bib, and changed tracked build artifacts together.

---

### Task 2: appendix.tex polish + SI table renumbering + Methods exemplar note + skill sanction

**Files:**
- Modify: `paper-arxiv/sections/appendix.tex`
- Modify: `paper-arxiv/sections/methods.tex` (one added passage)
- Modify: `/Users/jdv27/.claude/skills/review-section/SKILL.md` (documentation of the sanctioned exception)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: SI tables render as "Table S1"/"Table S2".

- [ ] **Step 1: Renumber the SI tables.** Before the first SI table environment (near :126), insert:

```latex
\setcounter{table}{0}
\renewcommand{\thetable}{S\arabic{table}}
```

Both `tab:stage2-design` and `tab:censoring-counts` are referenced only from within appendix.tex (verified during review), so `Table~\ref{...}` text updates automatically. After the build, confirm the rendered floats say "Table S1"/"Table S2" and that no other float numbering shifted.

- [ ] **Step 2: Merge the orphan opener of Appendix B** (:122-124, one sentence) into the classifier paragraph (:147) with the bridge: "... every Model~B summary statistic in this study is drawn (Table~\ref{tab:stage2-design}). Within that design, every run was assigned to one of five candidate regimes by a classifier evaluated in strict order, ..." — carrying the table reference into the merged lead.

- [ ] **Step 3: De-list the classifier prose** (:147-156). Replace the "Failing that," ×3 chain with the combined form: "Every run was assigned to one of five candidate regimes by a classifier evaluated in strict order, each test applying only to runs that failed all earlier ones. A run with zero return standard deviation was inert; failing that, a run was crash-prone when its crash frequency, the fraction of steps at which the grid's Sell fraction stood at or above $0.5$, reached at least $1\%$ of steps, oscillatory when the net order imbalance $\varphi$ changed sign at least $20$ times per $2{,}000$ steps, a plateau when its total price range stayed below $0.10\,P_0$, and a drift otherwise." Keep the rate-transfer sentence ("That threshold is a rate, one flip per $100$ steps, ...") as its own following sentence. (Note the crash-frequency threshold is stated as "$1\%$ of steps", folding in Step 5 item 4.)

- [ ] **Step 4: Tense harmonization** (five exact edits): :44-45 "the Jacobian at the buy-dominated branch has complex eigenvalues" → "had complex eigenvalues"; :73-74 "The implementation symmetrizes and renormalizes $\rho'$ after every step" → "We symmetrized and renormalized $\rho'$ after every step"; :189 "The resulting counts are recorded for every ... cell" → "We recorded the counts for every ... cell"; :194 "Those cells feed the dose-response analysis" → "Those cells fed the dose-response analysis"; :233 "Cash $500$ has one fewer" → "Cash $500$ had one fewer".

- [ ] **Step 5: Wording, punctuation, and precision batch** (each is an exact or near-exact replacement; verify any number against code/paper before asserting):
  1. :190 semicolon → period ("... of the campaign (Table~\ref{tab:censoring-counts}). Rows at $20$ seeds belong to the pilot pass ...").
  2. :270 semicolon → period ("... shown because it makes the mechanism visible. The \emph{typical} crash-prone run is a liquidity freeze ...").
  3. :95-98 the three-arm series gains semicolons between arms (each arm's tuple commas stay): "We ran $\varepsilon \in \{0.1,\, 0.3,\, 0.5\}$ on buy-biased marginals $(0.50,\, 0.30,\, 0.20)$; $\varepsilon \in \{0.1,\, 0.3\}$ on sell-biased marginals $(0.20,\, 0.10,\, 0.70)$; and $\varepsilon = 0.5$ on $(0.10,\, 0.05,\, 0.85)$, together with ...".
  4. :151 "reaches at least $0.01$" → "reaches at least $1\%$ of steps" (done inside Step 3's rewrite; do not double-apply).
  5. :77-78 "every trajectory reported here converged within a few hundred iterations" → state the actual worst case: extract the maximum iteration count from the pair-approximation runs (`pair_steady` in `code/model-a/PairApproximation.jl`; run `julia --project=code code/model-a/PairApproximation.jl` if it completes in a few minutes, or instrument a small script that calls the same entry points). If extraction is impractical (>10 min), keep the original wording and report that in the task report.
  6. :271-272 "while the price barely moves" → give the number already used elsewhere for this exemplar (the FigS1 caption / crash-prone discussion cites a maximum drawdown near $5\%$ — verify the exact figure in the file and reuse it verbatim), e.g. "while its maximum drawdown stayed near $5\%$".
  7. :269-270 "the dramatic tail of its regime" → "the extreme tail of its regime".
  8. :174 "so half the class never traded below the initial quote at all" → "so half the class never traded below the initial quote".
  9. :383 "declines from ${\sim}0.37$ well before onset to zero just after" → drop "well" or state the interval in steps (read the FigS6 panel/code to get the actual lead time if stated; otherwise just drop "well").
  10. :235-237 "It was this gap that prompted extending the refinement grid to $f = 0.177$, so that the tightest budget still contributed a point hard against the cliff." → "That gap prompted extending the refinement grid to $f = 0.177$, so that the tightest budget still contributed a point close to the cliff."
  11. :233-234 "just below the one-half a finite median requires" → "below the one-half that a finite median requires".
  12. :245-246 "and weighed accordingly" → replace with the FigS5 phrasing "a lead rather than a result" so the passage reads as a plain statement (match the surrounding sentence's grammar).
  13. :78-85 split the stability sentence at the trailing absolute: "... computed by finite differences with step $\delta = 10^{-7}$. Each perturbed matrix was projected back onto the probability simplex before the map was applied."
  14. :380-384 FigS6 closer: split the "and the Sell fraction, which ..., remains indistinguishable" clause into its own sentence.
  15. :168-169 bridge the factor finding: "Among the individual factors, enabling the disposition rule increased return standard deviation by a factor of $2.40$ on average across matched design cells."
  16. :114-115 "supports no correlated fixed point, which is the negative result on which the nucleation argument rests." → "supports no correlated fixed point, the negative result on which the nucleation argument rests."
  17. :17-18 "splitting $c = 1$ between Buy, with probability $1 - f$, and Sell, with probability~$f$." → "splitting $c = 1$ between Buy with probability $1-f$ and Sell with probability~$f$."
  18. :177 "concentrated at $f = 0.2$, $\lambda = 0.05$, cash $5{,}000$, disposition off, the loosest budget regime in the design" → "concentrated at $f = 0.2$, $\lambda = 0.05$, cash $5{,}000$, and the disposition rule off, the loosest budget regime in the design".
  19. FigS7 caption :395-396 "against the $N^{-1/2}$ self-averaging reference" (second "against") → "compared with the $N^{-1/2}$ self-averaging reference"; :399-400 "saturating above $f \approx 0.17$" → "flat in lattice size above $f \approx 0.17$" (confirm direction against the rendered FigS7 panel B before committing).
  20. :294 FigS2 (E) "Largest-cluster fraction of the grid at the end of the run." → "The same comparison for the largest-cluster fraction of the grid at the end of the run."
  21. :321-323 "That overlap is not itself a test; the paired equivalence analysis reported in the text is, and it bounds ..." → "That overlap is not itself a test. The paired equivalence analysis reported in the text is the test, and it bounds ...".
  22. :349 "so the bars are true but sit at zero height" → "so the bars are drawn at zero height and the panel states the count as text".
  23. :340 gloss the arm label once: "stamped at edge (boundary-adjacent), mid, and center placements" (keep the axis word "edge" as-is in the figure).

- [ ] **Step 6: Add the Fig 5 exemplar-filter note to Methods.** Locate the Methods passage describing the Model B simulation protocol or figure exemplars (grep methods.tex for the nucleation/strip/exemplar context; if Methods has no natural home, the Model B appendix section is the fallback). Add 1-2 sentences in the established voice stating the selection rule: the nucleus-figure exemplar was chosen from the 20 disorder seeds among interior births (founding cell at least 10 cells from the boundary) whose onset-cluster lineage survived to engulfment, and one of eleven interior candidates satisfied the survival requirement. VERIFY the numbers against `code/model-b/Compute-ModelB-StripFrames.jl` (the fig5 selection block and its comments/provenance string) before asserting them; use the code's actual thresholds and counts.

- [ ] **Step 7: Sanction appendix refs in the review-section skill.** In `/Users/jdv27/.claude/skills/review-section/SKILL.md`, Cross-references section, "What is still allowed" list, add one bullet: "`Appendix~\ref{app:...}` pointers to this paper's lettered appendices are sanctioned house style (author decision 2026-07-29) and must not be flagged; the ban covers `sec:`-labelled references and soft section pointers only." Do not alter the detection greps (they already do not match `app:`).

- [ ] **Step 8: Build + gates.** `bash build.sh Paper_v1` from `paper-arxiv/`; `grep -c 'undefined refer' Paper_v1.log` = 0; render the SI table pages and confirm "Table S1"/"Table S2"; render the edited SI figure caption pages (S2, S5, S6, S7) and spot-check against their figures; zero-tolerance greps on appendix.tex and methods.tex all clean.

- [ ] **Step 9: Commit** ("Appendix polish: S-numbered SI tables, classifier prose, precision fixes; Methods notes the Fig 5 exemplar filter").

---

### Task 3: code cleanup + Fig 3 panel B label legibility

**Files:**
- Modify: `code/src/StripPanels.jl` (new `_strip_letter_row` helper)
- Modify: `code/model-b/Figs-ModelB-BoundaryVsBulk.jl`, `code/model-b/Figs-ModelB-BarrierLaw.jl`, `code/model-b/Figs-ModelB-BudgetToggle.jl` (use helper; comment fixes)
- Modify: `code/model-a/Figs-ModelA-FiniteSize.jl` (use helper if its corner-letter block matches; panel B end-labels; stale comment)
- Modify: `code/model-a/Figs-ModelA-Theory.jl` (two-sided assert)
- Modify: `code/model-a/FiniteSize-Lib.jl` (+ `code/model-a/Compute-FiniteSizeScaling.jl`) (shared burn-in constant)

**Interfaces:**
- Produces: `_strip_letter_row(letter::AbstractString; kwargs...)` in StripPanels.jl returning the blank letter-row panel the four figure scripts currently build inline. Signature may take whatever the four call sites actually need (inspect them first); the contract is that all four render pixel-identically after the refactor.

- [ ] **Step 1: Extract the letter-row helper.** Read the four `_letterA`-style blank-panel blocks (three Model B scripts' strip anchors + Fig 3's corner-letter panel in `Figs-ModelA-FiniteSize.jl`). Factor the common construction into `_strip_letter_row` in `StripPanels.jl` (exported alongside the existing functions); refactor the call sites that genuinely share the shape (if Fig 3's corner block differs materially, leave it and say so in the report). Add a focused test in `code/test/test_strippanels.jl` asserting the helper returns a plot object with the letter annotation present.

- [ ] **Step 2: Verify pixel-identity of the refactor.** Regenerate the affected figures; for each, compare rendered pixels against the committed copy: `pdftoppm -png -r 72 <new>.pdf /dev/stdout | shasum` vs `git show HEAD:<path> > /tmp/old.pdf` + same pipeline. All refactor-only figures MUST hash identically; if one differs, fix the refactor rather than accepting the change.

- [ ] **Step 3: Comment corrections** (exact content, adjust to each file's comment style):
  1. `Figs-ModelB-BarrierLaw.jl` panel-A comment claiming "freeze/cash 500 nucleates later than collapse/cash 5000": rewrite to state both facts — population medians go 412 vs 374 (freeze later), but the seed-17 strips actually drawn have freeze t_on = 350 before collapse t_on = 374.
  2. `Figs-ModelB-BudgetToggle.jl:127` "Fig7's panels C/D" → the edge-ring trace panel is now Fig 7 panel B only.
  3. `Figs-ModelA-FiniteSize.jl:151-153` stale "the mixed state throws up 30-60 cell fluctuations on its own" → update to the 20-seed statistics (subcritical median mean-max 57.5-90.0; see the asserts in `Figs-ModelA-Theory.jl`).
  4. `Figs-ModelB-BoundaryVsBulk.jl:288` comment claiming Results prose reports the 95% Wilson upper bound → correct: Results prose reports the raw $0/20$ count (citing Figure S5); no Wilson bound appears in the paper.
- [ ] **Step 4: Two-sided assert.** `Figs-ModelA-Theory.jl:228` `@assert max_ever_median[fC .== 0.16][1] > 150` → `@assert isapprox(max_ever_median[fC .== 0.16][1], 252.5; atol = 60)`.
- [ ] **Step 5: Shared burn-in constant.** In `FiniteSize-Lib.jl` define `const FINITE_SIZE_BURN_IN = 200` near the top with a one-line comment ("campaign-wide burn-in; keep in sync with the committed CSV/JLD2 caches"), use it as `run_cell_frames`'s `burn_in` default, and have `Compute-FiniteSizeScaling.jl`'s `BURN_IN` reference it (`BURN_IN = FINITE_SIZE_BURN_IN`) — no behavioral change anywhere (same value 200). Leave test-file literals as-is.
- [ ] **Step 6: Fig 3 panel B end-labels.** In `Figs-ModelA-FiniteSize.jl`, the three "L = 64/128/512" end-labels currently sit at a fixed vertical stagger while all three curves terminate at 1.0, so matching relies on color alone. Reposition each label adjacent to its own curve at an x-position where the three curves are visually separated (e.g., near each curve's half-rise), keeping each label's color tied to its series; confirm by render that each label unambiguously attaches to its curve, nothing overlaps, and the panel stays inside its margins. This intentionally changes the figure.
- [ ] **Step 7: Regenerate + verify.** Rerun the changed figure scripts (`Figs-ModelA-FiniteSize.jl`, `Figs-ModelA-Theory.jl` — assert must pass — plus any Model B script whose file changed beyond comments if the helper landed there). Pixel-hash-compare everything that should NOT have changed; visually inspect Fig 3 panel B (the intended change). Run the suite: `julia --project=code code/test/runtests.jl`.
- [ ] **Step 8: Rebuild the paper** (Fig 3 changed): `bash build.sh Paper_v1` from `paper-arxiv/`; 0 undefined refs; render the Fig 3 page and check panel B.
- [ ] **Step 9: Commit** ("Code cleanup: shared strip letter-row helper, comment corrections, two-sided Fig 4C assert, legible Fig 3 end-labels") — source, changed figure PDFs (both copies), tracked build artifacts. `git restore` any pixel-identical timestamp-only PDF churn instead of committing it.

---

## Verification (whole-pass)

- `bash code/run_all.sh tests` and `julia --project=code code/test/runtests.jl` green.
- Paper builds clean: 0 undefined refs; SI tables S1/S2; all new `\cite` keys resolve.
- Zero-tolerance greps clean on all four edited .tex files.
- Final whole-branch review before merge.
