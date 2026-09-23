# House Style: Wolfram Markets Manuscript

> **Voice, 23 September 2026:** [VOICE_GUIDE.md](VOICE_GUIDE.md) takes
> precedence over "Paragraphs and Sentences" and "Results Paragraph
> Development" below. This guide still governs terminology, claims,
> numbers, generators, and the build.

**Model status, 14 September 2026:** the corrected manuscript uses finite
constant-product reserve clearing. The complete clean rerun is recorded in
[the rebuild workflow](code/rebuild/README.md) and
[its protocol](docs/superpowers/specs/2026-09-14-clean-manuscript-rerun.md).
The corrected manuscript is installed, with 51,056 completed simulation
records, six regenerated figures, and eleven tables. All 29 PDF pages were
visually reviewed; the source package passed an isolated compile. Earlier
standing-quote financial conclusions are archived and must not be restored.
The language conventions below apply to the corrected model.

**Transaction-fee extension, 18 September 2026:** the author approved
proportional cash fees on completed buys and sales, with dealer revenue
held separately from trading reserves. The original study remains the
zero-fee baseline. The additional versioned study is
`output/rebuilt/transaction-fees-v1/`, with workflow in
`code/fees/README.md`. Fees affect affordability and settlement; the
quote and constant product use trading reserves only. Total cash includes
the dealer's fee account. Do not describe prescribed fees as a dealer
profit objective or infer that traders optimize decisions against fees.

Read [PUBLICATION_STYLE.md](PUBLICATION_STYLE.md) first for the author's
voice and the interactive review process. The current review is tracked in
[REVIEW_PROGRESS.md](REVIEW_PROGRESS.md). The publication guide was drafted
on 16 September 2026 around the author's request for simple sentences and
long, developed paragraphs; refine it through the section reviews.

This guide records the project-specific structure and verification conventions for
*When Selling Spreads: Local Decisions, Limited Resources, and Market Crashes in a Simulated Market*
(`paper-arxiv/Paper_v1.tex`). Apply it to every prose edit, every response to
review, and every generated section. Where this guide and a generic template
disagree, this guide wins. Current author instructions take precedence over
both guides. `PUBLICATION_STYLE.md` governs voice and interactive review;
this guide governs this paper's terminology, scientific scope, and build.
Use the available `paper-section-review` skill with both guides.

`Paper_v1.tex` is the arXiv preprint; the `neurips_2026` class in `[preprint]`
mode is deliberate. A journal version will be built later from the same
`sections/*.tex` sources, so journal-specific formatting never goes into
`Paper_v1.tex`.

## Core Principle

Simple, direct sentences in long, well-developed paragraphs. Technical claims
stay exact, but the reader should not decode the prose before understanding
the science. The author is a
chemical engineer, not a statistical physicist: analogies from fracture,
boiling, and nucleation land, bare stat-mech vocabulary does not. Define every
borrowed term in market language on first use or avoid it. Prefer
interpretable quantities (steps, percentages, probabilities, ratios) over
fitted constants. Show the evidence rather than assert it.

Prefer concrete verbs and nouns over abstract or pseudo-technical phrasing.
Write "the dealer rejected orders that could not clear at the selected price,"
not "residual flow was constrained by intermediary balance-sheet limits."
Explain how the reserve curve changes the price of completed trades. Do not
use the archived claim that a small dealer mechanically contains a crash.

### Plain-English check

The author explicitly requested a manuscript-wide removal of internal jargon.
Name the action and comparison rather than writing "repeated the experiment."
The selected edge traders are "technical traders" (author decision,
2026-09-07, reaffirmed 2026-09-18): they follow a contrarian strategy of the
Bollinger-band type, generating Buy intentions below a band around the
moving average and Sell intentions above it. Their width uses a smoothed
absolute departure rather than standard deviation. Define the rule
once in Methods, keep "along the edge of the grid" at that definition, and do
not call them "price-responsive traders," "edge traders," or "expert traders."
Explain that keeping them in Hold prevents price changes from influencing
later decisions. Use "synthetic market" for the simulated environment in
the Introduction (author decision, 16 September 2026), and explain its
arrangement through rows, columns, and neighboring traders. Describe the
size comparison as markets containing different numbers of traders.
Retain precise square-grid notation where needed in Methods; review later
sections in their turn rather than replacing every use mechanically.
Use "starting market," "completed trades," and
"fraction of traders given the new rule" in narrative passages. Reserve
"lattice," "seed," "eligibility," and "activation fraction" for definitions,
mathematical notation, and compact labels where needed. The two conditions are
"technical traders held" and "technical traders active"; figure legends and
table cells abbreviate them to "held" and "active." "Held boundary" and
"endogenous boundary" survive only in code, CSV columns, and Julia scripts. Avoid "activation window," "principal fraction," "eligible flow," and
"unmatched residual." Explain a statistical quantity through what it measures
before naming it. Simplify vocabulary without breaking developed paragraphs
into short pieces or changing the measured outcomes.

## What the Paper Is

One three-state cellular automaton market (Buy 0, Hold 1, Sell 2; von Neumann
neighborhood; totalistic rules, 3^9 of them). Rule 19280 is the baseline;
Rule 19286 differs at exactly one neighbor sum, c = 1, where 19280 returns Buy
and 19286 returns Sell. The intervention is a paired mid-run rule switch at a
fraction f of interior sites after 1,000 baseline steps, with no reset of any
dynamic state; the matched arm keeps every site on the baseline rule. The
held control removes price feedback by keeping the technical traders at
Hold. Dealer capacity h specifies initial reserve shares per trader; the
constant-product curve determines the common execution price and next
marginal quote. Depth changes both funding and price sensitivity. Four
main campaigns contain 30,550 simulations, with 50 starting markets per
condition. The complete fixed design contains 45,910 simulations before
adaptive refinement and selected trajectory reruns. Every retained held
condition is recomputed with full financial bookkeeping.

The central theme is investor decision-making, market instability, and
market crashes: how a change in some traders' decision rules shifts a market
toward selling, and how available resources determine the resulting price
decline. Use plain terms such as "market dominated by sellers" in place of
"collective selling." Instability describes the observed shift from mixed
decisions to a Sell majority after a rule change; it does not assert formal
or infinite-time instability. A price crash is a large simulated price
decline, measured by drawdown. Do not rename Sell-majority probability
"crash probability," introduce an unmeasured crash threshold, or imply
empirical calibration. The author explicitly requested this framing, which
supersedes the earlier blanket ban on "crash" in prose. Use purpose-first
openings in plain market language, then introduce rule numbers and other
technical details where they explain the experiment. Preserve developed,
connected paragraphs. Describe the agents as traders when explaining the
model, and use investors for the broader question. Buy and Sell represent
current intentions. A completed trade is an actual exchange of cash and
shares. Traders cannot borrow cash or sell shares they do not own. A trader
without shares may want to sell but cannot execute the sale. A trader
without enough cash may want to buy but cannot execute the purchase.
Neighbors respond to intentions even when no exchange occurs. A Sell state
does not represent a permanent sell-only strategy. The changed rule is
assigned only to the selected traders; decisions to sell can spread while
other traders retain their original rules. Do not imply learning, optimizing
returns, or endogenous adoption of new rules.

The two-part thesis, in the order every section follows: interacting decision
rules can destabilize trading; execution determines whether the resulting
selling accompanies a small price decline or a simulated crash.

### Terminology

| Use in prose | Never use in prose | Notes |
|---|---|---|
| rule switch; switched market (treated arm) | rule change, activation, treated, changed-rule, quench, contrarian activation | Author decision 23 Sep 2026. "Quench" survives only in filenames, LaTeX labels, and Julia |
| no-switch control | matched control, comparison market, no-switch comparison, dormant control | |
| fraction $f$ (of interior traders given the new rule) | target fraction, rule fraction, activation fraction, dose | Name the symbol at first use in each sentence: "fraction $f=0.20$" |
| technical traders held / technical traders active (legends: held / active) | held boundary, endogenous boundary, edge traders, exogenous model, endogenous model | one model, two technical-trader conditions; `hold`/`endogenous` survive in code and CSV columns |
| dealer; dealer depth $h$ (the dealer's initial shares per trader); market maker when introducing its role | dealer capacity, reserve depth, reserve level | Author decision 23 Sep 2026. "Dealer reserves" means the dealer's actual cash and shares, not $h$. Name the symbol at first use in each sentence: "dealer depth $h=100$". Code and CSV columns say `market_maker`. |
| trader suppression / dealer rejection; dealer-rejection fraction | agent suppression | the two stages at which a desired order fails |
| Sell majority; "reached a majority"; onset | transitioned, crossed one-half, escape, conversion | reached = interior Sell fraction reached 0.5 at least once after the rule switch; "crossing" is kept only for interpolated probability curves; crash refers to the price decline |
| growth and merger of Sell-rich domains, finite-time crossover | classical nucleation, critical point, asymptotic threshold | the paper explicitly disclaims these |
| traders (model agents); investors only for real markets | investors or agents for the model's traders; sites | Author decision 23 Sep 2026. Edge positions, not perimeter sites |
| quoted price (the dealer's posted price $P_t$) | marginal quote, quote | Author decision 23 Sep 2026. Execution price is a different quantity |
| starting market | seed (except a random-number seed), initial market | |
| grid size $L$; step; observation period | lattice, time step, observation window | |
| Model (singular) | Model A, Model B | directory names `code/model-a`, `code/model-b` are historical |

The one sanctioned use of "contrarian" is the Methods sentence that scopes
it. "Quenched disorder" in the appendix is the physics sense and stays.

## Structure

Order: Introduction, Methods, Results, Discussion, Conclusion, References,
Tables, Figures, Appendix. All floats are collected after the references
(`sections/tables.tex`, then `sections/figures.tex`), each group starting on
a new page. There is no Related Work section; the Introduction carries every
prior-work citation.

**Introduction.** At most four long, developed paragraphs, wide to narrow.
This is an explicit author requirement (16 September 2026). Develop one
integrated argument across the section. Combine related literature and
model explanations, remove repeated motivations, and write transitions that
explain their connection. Reviewing a passage separately does not authorize
making it a separate manuscript paragraph. The author-approved
opening (16 September 2026) starts with markets as the collective outcome
of human interactions and quotes the Financial Crisis Inquiry Commission's
2011 report on the 2008 crisis. It names buyers and sellers, perceived asset
value, and buyers' funds. Scope the discussion to traded financial assets
such as stocks, without assuming liquidity remains available. The modeling
literature follows this opening; then develop the local rule-change question
and the connection between execution, reserves, and price. The closing
paragraph begins "In this study," and states the study question and approach
in the past tense throughout. Explain that paired simulations started from
identical conditions but could develop differently afterward. Holding the
technical traders in Hold removed price inputs to interior decisions while
allowing financially feasible interior trades and dealer quote updates.
Close with a plain qualitative statement of what the study addressed and
how its comparisons supported that contribution (author decision,
16 September 2026). This supersedes the earlier exclusion of all findings
from the closing paragraph. Numerical findings belong in Results. Include
the accepted crowding and following overview, distinguishing shared advice
from copying completed trades. Their matching Methods and Results coverage
is pending in the interactive review. The corrected copying results are
exploratory; the separate fresh-market confirmation concerns shared advice.
No subsections, no headings.

**Methods.** Subsections allowed, `\subsubsection` never. Every symbol is
defined in prose before its display equation; no post-equation "where"
clauses. Every prose-to-equation transition ends in a colon with a varied
connector ("is given by:", "according to:", "the executed counts were:").
Setup, notation, and protocol belong here, not in a standalone section.
Organize developed procedural paragraphs by protocol family, rather than
one stub per campaign. Paragraph length follows the explanation needed,
without a word or sentence quota. Software versions, seeds, thread counts,
and the repository are reproducibility details and stay. Hardware, CPU,
memory, and wall-clock
numbers are benchmarking and are out of scope; never propose adding them.

**Results.** Six developed paragraphs, no subsections, no `\paragraph{}`
headings, past tense throughout. Fixed order, matching the abstract,
Introduction P4, and Discussion:

1. Rule diagrams and paired snapshots (Fig. 1A--C), paired switch,
   matched Sell pulse, and single-entry rule screen (Tables S1, S2, S5, S6).
2. Technical traders held: the transition survives removal of price feedback
   (Fig. 2A,B).
3. Finite size and horizon (Fig. 3, Tables S3, S9, S10). This paragraph is
   `\input{sections/finite-size-results}` and is GENERATED (see below).
4. Growing groups of sellers in the same five examples extended to 10,000
   steps, plus delayed transitions among all 50 original f=0.150 starts
   (Fig. 4, Table S11). Selection remains based on the original 3,000 steps.
5. Dealer depth: probability versus drawdown, matched no-switch drawdowns,
   frozen band, additional reserve depths, and the selected starting market
   (Fig. 2C,D, Fig. 5, Tables S2, S7, S8).
6. Cash and share interventions (Fig. 6, Table S4).

Supporting controls are integrated into these paragraphs and detailed in the
appendix; never add a paragraph per control.

**Discussion.** No subsections or headings. Opens with a plain thesis
sentence connecting investor decisions to market instability and price declines. Then: the persistent local
change and what the paired design attributes; the lattice mechanism, size
and time, and the nucleation disclaimer; trader and dealer resources; price
feedback and the non-monotone capacity response; limitations last. Each
paragraph cites the relevant theory or microstructure literature.

**Conclusion.** One paragraph. End on the supported consequence: the
financial effect of widespread selling depends on how resources enter
execution and price formation. Do not restore the small-dealer crash ceiling.

**Abstract.** One paragraph, about 300 words, qualitative: problem,
approach, design, insight, implication. Zero computed numbers. Do not
reintroduce magnitudes here.

**Appendix.** Supplementary methods and validation: one complete step and
the two algorithms, rationing and paired reproducibility, conservation and
limiting cases, campaign inventory, then the generated controls subsection
(`app:revision-controls`). Tables S1 to S11 live in `tables.tex`,
`finite-size-table.tex`, `revision-tables.tex`, `revision-fits-table.tex`,
and `market-panel-horizons-table.tex`.

## Paragraphs and Sentences

The earlier calibration exemplar is `~/Desktop/papers/Kompala-Model-LP-Paper`.
Use its developed arguments as context, not a source of sentence-length
quotas. The author's current preferences and passages accepted during this
review are the primary calibration.

- Keep long, developed paragraphs whose sentences each advance one argument.
  Merge a roadmap stub into the passage it introduces. Restore missing
  explanation where needed; do not pad paragraphs to reach a length target.
- Prefer simple sentences. Split grammatical but overloaded sentences as
  well as true run-ons. Do not join clear sentences to increase a median
  length or add clauses solely to avoid short sentences.
- Diagnose choppiness through the relationship between sentences. Make
  subjects clear, order the reasoning, and name real dependencies. Add a
  conjunction only when it expresses that relationship accurately.
- Punctuation earns its place. A semicolon or colon
  stays only when it separates list items with internal commas or introduces
  a genuine list or elaboration. As a default connector between two clauses
  that could stand alone, replace it with a period.
- Each paragraph has one job, opens by stating it, and closes by answering
  it or by supplying the reason for the next paragraph. Adjacent paragraphs
  form an argument.
- No vague backward references ("this behavior", "these results", "the
  former") when the reader must recover the antecedent. Name the thing.
  Repeat a key term rather than pronoun it.
- Do not begin a sentence with an acronym. Define every acronym at first use
  separately in the abstract, main text, supplement, and any caption that
  must stand alone.
- Place qualifications beside the claims they limit. Do not end every
  paragraph with a formulaic scope disclaimer.

## Results Paragraph Development

Each paragraph explains the comparison, finding, supporting evidence, and
scientific meaning. Open with the purpose, comparison, or finding that best
orients the reader. These functions need not be combined in one sentence or
follow an identical formula in every paragraph.

Develop the finding through the relevant conditions, measured values, and
figure or table references. Cite the whole figure for a broad finding and
the specific panel for a panel-specific claim, including in an opening
sentence when appropriate. Keep detailed numerical inventories out of the
opening when they obscure the point. State limitations where they affect
interpretation, without attaching a formulaic disclaimer to every ending.
Write "in-sample" and "out-of-sample" in full in narrative prose.

## Contextual Review Searches

Use these searches to locate possible problems, then read each match in
context. Review only active manuscript inputs. Ignore comments, identifiers,
mathematical notation, and legitimate technical uses. A match is not itself
a violation, and a clean search does not establish clear or correct prose.
Line-wrapped LaTeX can hide matches, so de-wrap first where shown.

```bash
cd paper-arxiv
# 1. Section self-references: NONE anywhere. Appendix~\ref{app:...}, Fig., Table, Eq., Algorithm refs are fine.
grep -nE '(\\(ref|Cref|cref|autoref|nameref)\{sec:|§\\?ref|Section~\\ref|Sec\.~\\ref|\\S\\ref)' sections/*.tex Paper_v1.tex
grep -nE '(§[ ~]?[0-9]|Section[ ~][0-9]|Sec\.[ ~][0-9])' sections/*.tex Paper_v1.tex
# 2. Lists and headings in narrative sections.
grep -nE '\\begin\{(itemize|enumerate)\}|\\item\b|subsubsection' sections/*.tex
grep -nE '\\(subsection|paragraph)\{' sections/introduction.tex sections/results.tex sections/finite-size-results.tex sections/discussion.tex sections/conclusion.tex
# 3. Figure or table as grammatical subject, including indirect forms.
grep -nE '(Fig\.|Figure|Table|panel)s?~?\\?(ref\{[^}]*\})?[A-D]?,?[A-D]? ?(show|report|summari|illustrat|display|present|establish|confirm|demonstrat|indicat|reveal)|As shown in|as shown in' sections/*.tex
# 4. Em and en dashes in prose (numeric ranges 32--128 and compounds cash--share, A--C are fine).
grep -nE '—|–|[a-zA-Z] ?--- ?[a-zA-Z]' sections/*.tex
# 5. Vague intensifiers on a comparative (read each hit; see allow-list).
for f in sections/*.tex Paper_v1.tex; do tr '\n' ' ' < $f | grep -oE '\b(far|much|substantially|substantial|considerably|vastly|dramatically|markedly|greatly|very|highly|particularly|sharply|strongly) [a-z]+' | sed "s|^|$f: |"; tr '\n' ' ' < $f | grep -oE '\bwell (below|above|within|short|beyond|under|over)\b' | sed "s|^|$f: |"; done
# 6. Promotional or editorializing words.
grep -niE 'more than (an?|just|merely) |not (a mere|just|simply|only) |most (reveal|strik|notab|import)|strikingl|remarkabl|elegan|compellin|powerful|(unavoidabl|inevitabl)|illuminat|critically|importantly|notably|interestingly' sections/*.tex
# 7. Terminology regressions (de-wrapped).
for f in sections/*.tex Paper_v1.tex; do tr '\n' ' ' < $f | grep -oiE 'dormant|dose atlas|contrarian activation|activated fraction|market maker' | sed "s|^|$f: |"; done | grep -v 'fig:\|Quench.pdf'
# 8. Results leads: print each paragraph's first line and check it by hand.
for f in sections/results.tex sections/finite-size-results.tex; do awk '/^%/{next} /^\\(section|input)/{next} /^[[:space:]]*$/{n=1;next} {if(n){print FILENAME":"NR": "$0;n=0}} BEGIN{n=1}' $f; done
```

Intensifier allow-list: portion quantifiers ("how much", "as much as",
"much of"), idioms ("how far", "as far as"), compound "well-" adjectives,
softening hedges ("broadly similar", "without substantially affecting"),
"an order of magnitude", and threshold-defined terms. Everything else on a
comparative is deleted and the nearby number carries the size.

Also enforced: Results in past tense; captions may use a band, line, row, or
column as a subject; no `\FloatBarrier` after Figs. 2 and 5 in any inline
layout (it costs a page).

## Numbers, Claims, and Limits

- Every computed number in the body cites a figure or table. The only
  exempt numerals are historical dates in Introduction P1 and rule indices.
  Panel citations must point to the panel that actually carries the value
  (widths and midpoints are Fig. 3A,C; susceptibility 3B,D; drawdown 2C;
  rejection 2D; Fig. 6 is A probability, B drawdown, C rejection, D
  scatter). Widths, median onsets, and off-f=0.18 balance-sheet
  probabilities live only in Tables S3, S2, and S4, so cite the table.
  Paired drawdown increments belong to Table S2; total switched-market
  drawdown in Figure 2C is not itself an intervention effect.
- Verify against the data, not against memory or the previous draft. Sources:
  Within `output/rebuilt/manuscript-reserve-v1/code/data/`:
  `ModelB-ReservoirQuench-Full-{Summary,Derived,Grouped}.csv`,
  `ModelB-BalanceSheetQuench-Full-Grouped.csv`,
  `ModelB-Revision-{FiniteSize-Scaling,Horizons-Scaling,Controls-Grouped,band,impact,pulse,screen,long}.csv`.
  The CSV `boundary` column is `endogenous`/`hold` (prose: technical traders
  active/held); the deep reserve comparison is finite `h=100`;
  drawdowns are stored as fractions. Historical `Inf` outputs are not inputs
  to the corrected manuscript. `/opt/homebrew/bin/python3` has a
  working pandas; the Anaconda python does not.
- Give the number instead of the adjective. "Very different price declines"
  becomes "drawdowns from below 1% to above 25%" or "differed by more than
  an order of magnitude."
- Wilson 95% intervals for proportions; medians and interquartile ranges for
  continuous summaries; seed-bootstrap intervals (2,000 whole-seed
  replicates) for midpoints, widths, and susceptibility peaks; all
  conditional on the refined grid and the 3,000-step horizon.
- Measurement windows must be stated: the corrected campaigns
  use post-activation orders for completed counts, suppression, and
  rejection in every campaign. The drawdown window includes the quote at
  activation; majority detection starts with the first updated state afterward.
- Claims the paper does NOT make and must not drift into: classical
  nucleation (no free-energy barrier, activation rate, surface tension, or
  critical droplet); an asymptotic or equilibrium threshold (the crossover is
  finite-time and its midpoint drifts with horizon); stationarity of the
  baseline or of the final window; global stability from the 100,000-step
  no-switch runs; a unique mechanism for the non-monotone capacity response
  (the frozen band tests width adaptation while preserving other feedback);
  empirical calibration of impact, depth, or time; generality beyond the
  totalistic rule class; relative importance of response identity versus
  activated fraction (both mattered; neither was ranked).
- Bound closing sentences to what was tested ("Within the tested
  interventions ...", "Each displayed transition ..."). A single pulse
  control does not establish a general requirement; five displayed runs do
  not establish the ensemble mechanism.
- State the strongest claim the evidence supports, and no stronger. A
  matched null with zero crossings is bounded by its Wilson upper limit,
  not a proof of impossibility.

## Figures, Tables, Algorithms, and Equations

- Citation forms: `Fig.~\ref{fig:x}`, `Figs.~\ref{fig:a}--\ref{fig:b}`,
  `Supplementary Table~\ref{tab:x}`, `Algorithm~\ref{alg:x}`,
  `Eq.~\ref{eq:x}`, `Appendix~\ref{app:x}`. Always parenthetical at the end
  of the clause they support. Never "see Fig."
- Cite every main-text figure and table in Results where its evidence is
  first reported; Methods, captions, and Discussion do not substitute. Cite
  each algorithm in the Methods sentence that summarizes it. Before calling
  the manuscript complete, inventory every `fig:`, `tab:`, `alg:`, `eq:`
  label and confirm it is cited.
- Figure numbering follows the order in `sections/figures.tex`. Filenames
  `paper-arxiv/figs/Fig<N>-<Descriptor>.pdf` must carry the rendered number;
  a rename touches the PDFs in BOTH `paper-arxiv/figs/` and `code/figs/`
  (both tracked, use `git mv`), the hardcoded filename in the generator
  under `code/model-b/`, and the `\includegraphics` path in `figures.tex`.
  About 30 unreferenced PDFs from retired campaigns still sit in `figs/` and
  reuse these prefixes; check `figures.tex` before trusting a `FigN-` name.
- `code/src/PaperStyle.jl` is a contract (palette, `_panel_kw`,
  `_panel_letter!`); per-figure margins and legends go in the figure
  assembly, never in the module. When a figure "shows nothing", check the
  colour and axis scaling against the data range before touching layout.
- Prespecified panel selection (nearest subgroup median onset for crossing
  runs, nearest median final Sell fraction otherwise, with seed breaking
  ties) is stated in Methods. Recompute the selected seeds from the new
  summaries; do not retain a historical seed because it was plotted before.
- Equations: define every symbol in prose first; introduce with a complete
  sentence ending in a colon; connect sequential equations with a sentence
  that says how the second follows.

## Citations and Bibliography

- `~\cite{key}` with the tilde; group as `~\cite{a,b,c}`. natbib loads with
  `numbers, sort&compress`, so brackets are numeric and sorted.
- Dense in Introduction and Discussion, moderate in Methods, light in
  Results. Every factual claim about prior work is cited.
- Every entry in `References_v1.bib` is Crossref-verified from this machine
  (discover with `works?query.bibliographic=`, confirm with `works/<DOI>`,
  pull BibTeX with the `application/x-bibtex` transform; books by ISBN on the
  publisher page). Never add a reference from memory. An entry that cannot
  be confirmed is dropped, not kept. Key format `lastnameYEARfirstword`,
  journal names spelled out, `doi` always present, sentence-case titles with
  braces only on proper nouns, no nested braces deeper than one level. A
  Crossref year or venue mismatch is a false alarm when it matched a reprint
  or working-paper version. `make` must show zero BibTeX warnings.

## Files, Generation, and Build

- Sources: `paper-arxiv/Paper_v1.tex` (preamble, abstract, `\input`s),
  `paper-arxiv/sections/*.tex`, `paper-arxiv/References_v1.bib`. Code under
  `code/` (Julia; run from the repo root as
  `julia --project=code code/<dir>/<script>.jl`).
- **Generated files, never hand-edited:** Results, captions, all table files,
  `finite-size-results.tex`, `revision-controls.tex`, and
  `rebuild-validation.tex`. Edit the corresponding templates in
  `code/rebuild/WriteResults.py`, `WriteCaptions.py`,
  `WriteManuscriptTables.py`, and `Verify.py`, then regenerate from the
  isolated corrected outputs. The old revision writer includes archived
  financial interpretations and must not generate the corrected manuscript.
  The four `transaction-fees-*.tex` inputs are generated separately by
  `code/fees/WritePaper.py` from the validated fee study. Preserve those
  inputs and their inclusion points when regenerating the original results.
- Build with `make` inside `paper-arxiv/` (latexmk). After any prose or
  float change: check `Paper_v1.log` for warnings, undefined references, and
  overfull boxes (expect none); confirm the page count with `pdfinfo`;
  render the changed pages with `pdftoppm -r 60 -f N -l M -png` and look at
  them for widows, orphans, and paragraph breaks (club and widow penalties
  are set to 10000 but pagination still moves).
- Then `python3 paper-arxiv/package_arxiv.py --verify` to rebuild
  `output/arxiv/` and confirm a clean isolated compile with identical PDF
  text, and `cp paper-arxiv/Paper_v1.pdf output/pdf/Wolfram-markets-revised.pdf`
  (the packager does not refresh that copy).
- `git diff --check` before finishing. Commit only when the author asks.
- Current manuscript inputs are in
  `output/rebuilt/manuscript-reserve-v1/code/data/`; root `code/data/` retains
  historical summaries. Fee results come from
  `output/rebuilt/transaction-fees-v1/`. Restart checkpoints are ignored. When the author
  requests a commit, include the canonical summaries, manifests, executed
  source, and verification records needed to reproduce the manuscript.

## Review Workflow

1. Use `paper-section-review` with `PUBLICATION_STYLE.md` and this guide.
   Review one agreed unit with its evidence and associated artifacts. Present
   substantive findings and proposed prose for the author's discussion.
   Track coverage, decisions, and open checks in `REVIEW_PROGRESS.md`.
2. Apply edits within the author's authorized scope. Verify findings against
   their sources before changing scientific claims. Recheck the saved prose,
   evidence, build, and rendered pages. Retain this project's independent
   read-only technical check after an applied manuscript fix pass. Check
   numerical claims, interpretation, and implementation against their
   sources. Verify each finding, apply supported corrections, and recheck
   them on the final saved state. This technical check does not substitute
   for the author's interactive review of voice.
3. When a change responds to a reviewer, update `peer-review-response.md`
   with the same interpretation and terminology as the paper, and name the
   manuscript location.
4. Do not present future work as a promise. State the limitation and, when
   useful, the kind of method that could address it.

## Final Read-Aloud Test

Before considering revised prose complete, ask:

- Would a chemical engineer who has not read the Methods understand why this
  analysis was performed and what the result means for a market?
- Is every technical term necessary, and defined in market language?
- Does each sentence say exactly what happened, in the past tense, bounded
  to what was tested?
- Is any claim stronger than the evidence, or does any number lack a
  figure or table?
- Does the paragraph open with its question and close with its consequence?
- Could the same idea be stated more simply without losing precision? If
  yes, simplify it.


Figure 1 shows both complete rule diagrams (A: Rule 19280; B: Rule 19286)
and paired market snapshots (C). Each four-neighbor diagram represents one
sum, with the center excluded from the input. The highlighted sum of one
is the only changed response, Buy to Sell. Figure 1 no longer contains
price or Sell-fraction curves. Cite Table S2 for the comparison over all
starting markets and onset values; Fig. 1C shows the selected example only.
