# House Style: Wolfram Markets Manuscript

This guide records the writing, structure, and verification conventions for
*Local rule activation and dealer capacity in a cellular automaton market*
(`paper-arxiv/Paper_v1.tex`). Apply it to every prose edit, every response to
review, and every generated section. Where this guide and a generic template
disagree, this guide wins. Where this guide and the author's `review-section`
skill disagree, the skill wins and this guide should be updated.

`Paper_v1.tex` is the arXiv preprint; the `neurips_2026` class in `[preprint]`
mode is deliberate. A journal version will be built later from the same
`sections/*.tex` sources, so journal-specific formatting never goes into
`Paper_v1.tex`.

## Core Principle

Plain, direct, dense English. Technical claims stay exact, but the reader
should not decode the prose before understanding the science. The author is a
chemical engineer, not a statistical physicist: analogies from fracture,
boiling, and nucleation land, bare stat-mech vocabulary does not. Define every
borrowed term in market language on first use or avoid it. Prefer
interpretable quantities (steps, percentages, probabilities, ratios) over
fitted constants. Show the evidence rather than assert it.

Prefer concrete verbs and nouns over abstract or pseudo-technical phrasing.
Write "the dealer rejected the unmatched sells that exceeded its capacity,"
not "residual flow was constrained by intermediary balance-sheet limits."
Write "a lattice full of sellers lowered the price only as far as someone
was able to buy," not "price impact was bounded by counterparty absorption."

### Plain-English check

The author explicitly requested a manuscript-wide removal of internal jargon.
Name the action and comparison rather than writing "repeated the experiment."
Describe selected edge traders as traders who use price changes to decide
whether to buy, hold, or sell; do not call them "price-responsive traders."
Explain that keeping them in Hold prevents price changes from influencing
later decisions. Use "grid," "starting market," "completed trades," and
"fraction of traders given the new rule" in narrative passages. Reserve
"lattice," "seed," "eligibility," and "activation fraction" for definitions,
mathematical notation, and compact labels where needed. Translate conditions
such as "held boundary" and "endogenous boundary" into what the edge traders
do. Avoid "activation window," "principal fraction," "eligible flow," and
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
held-boundary control removes price feedback by holding boundary traders at
Hold. Dealer capacity h (net units per trader, 0 to 10 and unlimited) limits
the unmatched flow that can execute. Four production campaigns, 30,550
simulations, 50 seeds each, plus the supplementary controls added in the
peer-review revision.

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
model, and use investors for the broader question. A Sell state represents
a current decision, not a permanent sell-only strategy. The changed rule is
assigned only to the selected traders; decisions to sell can spread while
other traders retain their original rules. Do not imply learning, optimizing
returns, or endogenous adoption of new rules.

The two-part thesis, in the order every section follows: interacting decision
rules can destabilize trading; execution determines whether the resulting
selling accompanies a small price decline or a simulated crash.

### Terminology

| Use in prose | Never use in prose | Notes |
|---|---|---|
| rule switch, rule activation, persistent activation | quench, contrarian activation | "Quench" survives only in filenames, LaTeX labels, and Julia |
| no-switch control, matched control | dormant control | |
| activation fraction, activation-fraction snapshots | dose, dose atlas, activated fraction | `f` in math |
| held boundary / endogenous boundary | exogenous model, endogenous model | one model, two boundary conditions |
| dealer, dealer capacity `h` | market maker (in prose) | code and CSV columns say `market_maker` |
| agent suppression / dealer rejection | | the two stages at which a desired order fails |
| Sell majority, transition, onset, crossing | escape, conversion | "transitioned" = interior Sell fraction reached 0.5 at least once after activation; crash refers to the price decline, not this crossing |
| growth and merger of Sell-rich domains, finite-time crossover | classical nucleation, critical point, asymptotic threshold | the paper explicitly disclaims these |
| Model (singular) | Model A, Model B | directory names `code/model-a`, `code/model-b` are historical |

The one sanctioned use of "contrarian" is the Methods sentence that scopes
it. "Quenched disorder" in the appendix is the physics sense and stays.

## Structure

Order: Introduction, Methods, Results, Discussion, Conclusion, References,
Tables, Figures, Appendix. All floats are collected after the references
(`sections/tables.tex`, then `sections/figures.tex`), each group starting on
a new page. There is no Related Work section; the Introduction carries every
prior-work citation.

**Introduction.** At most four paragraphs, wide to narrow, densely cited
(cite clusters of 6 to 12 keys are welcome in the first three). P1: empirical
record and named episodes, the modeling literature, the gap. P2: the model
family and why a lookup table makes a persistent behavioral change precise.
P3: execution constraints, the second question. P4 begins "In this study,"
gives the study-level question, then approach, principal evidence,
interpretation, and a one-sentence thesis. P4 carries the headline numbers
and cites where they live (the abstract is number-free, so the Introduction
is the first place a number appears and it must point to a table or figure).
No subsections, no headings.

**Methods.** Subsections allowed, `\subsubsection` never. Every symbol is
defined in prose before its display equation; no post-equation "where"
clauses. Every prose-to-equation transition ends in a colon with a varied
connector ("is given by:", "according to:", "the executed counts were:").
Setup, notation, and protocol belong here, not in a standalone section.
Procedural paragraphs may run 70 to 130 words, but a subsection holds three
or four dense paragraphs organized by protocol family, never one stub per
campaign. Software versions, seeds, thread counts, and the repository are
reproducibility details and stay. Hardware, CPU, memory, and wall-clock
numbers are benchmarking and are out of scope; never propose adding them.

**Results.** Six developed paragraphs, no subsections, no `\paragraph{}`
headings, past tense throughout. Fixed order, matching the abstract,
Introduction P4, and Discussion:

1. Paired switch, matched Sell pulse, single-entry rule screen (Fig. 1,
   Tables S1, S2, S5, S6).
2. Held boundary: the transition survives removal of price feedback
   (Fig. 2A,B).
3. Finite size and horizon (Fig. 3, Tables S3, S9, S10). This paragraph is
   `\input{sections/finite-size-results}` and is GENERATED (see below).
4. Domain growth in the prespecified time-sliced runs (Fig. 4).
5. Dealer capacity: probability versus drawdown, frozen band, impact sweep,
   matched seed (Fig. 2C,D, Fig. 5, Tables S7, S8).
6. Cash and share interventions (Fig. 6, Table S4).

Supporting controls are integrated into these paragraphs and detailed in the
appendix; never add a paragraph per control.

**Discussion.** No subsections or headings. Opens with a plain thesis
sentence connecting investor decisions to market instability and price declines. Then: the persistent local
change and what the paired design attributes; the lattice mechanism, size
and time, and the nucleation disclaimer; trader and dealer resources; price
feedback and the non-monotone capacity response; limitations last. Each
paragraph cites the relevant theory or microstructure literature.

**Conclusion.** One paragraph. Ends on the plain consequence: traders can continue deciding to sell
after the dealer exhausts its ability to buy their shares.

**Abstract.** One paragraph, about 300 words, qualitative: problem,
approach, design, insight, implication. Zero computed numbers. Do not
reintroduce magnitudes here.

**Appendix.** Supplementary methods and validation: one complete step and
the two algorithms, rationing and paired reproducibility, conservation and
limiting cases, campaign inventory, then the generated controls subsection
(`app:revision-controls`). Tables S1 to S10 live in `tables.tex`,
`finite-size-table.tex`, `revision-tables.tex`, and `revision-fits-table.tex`.

## Paragraphs and Sentences

The calibration exemplar is `~/Desktop/papers/Kompala-Model-LP-Paper`.
Measure, do not eyeball:

- Results and Discussion paragraphs: 150 to 480 words, typically 180 to 310.
  Introduction paragraphs: 150 to 370. Nothing under 6 sentences in Results
  or Discussion; roadmap stubs merge into the paragraph that follows. A
  structural edit must merge paragraphs in the same pass, never later.
- Sentence length: median about 25 words, p90 about 48, commas per sentence
  about 1. Flag comma-chained sentences over 60 to 70 words as split
  candidates even when grammatical. Split only true run-ons.
- **The "robotic" signature** (author, 2026-09-06): a section whose sentence
  median has dropped below about 20 words reads as a string of short
  declaratives even when every sentence is correct. The fix is not fancier
  words. It is (a) one plain question or purpose sentence to open each
  paragraph, (b) subordinating choppy pairs with "whereas", "because", "so",
  "which", (c) one plain consequence sentence to close each paragraph, and
  (d) a one-sentence bridge whenever the next paragraph's reason is not
  obvious. Check the medians before and after.
- Flowing, dense prose; punctuation earns its place. A semicolon or colon
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

## Results Paragraph Template

Every Results paragraph follows: question or purpose, what was compared or
calculated, the finding with its inline reference, what it does and does not
show. Concretely:

1. An optional opening sentence that states the question in plain terms
   ("A Sell majority could spread through neighbor responses alone or
   through the price signal that boundary traders fed back into the
   lattice.").
2. The lead: an action clause AND a number-free generic observation, ending
   with a citation of the WHOLE figure or table: "We changed the decision rule for selected interior traders while
   keeping edge traders in Hold and found that a Sell majority still formed
   (Fig.~\ref{fig:reservoir})." Both halves are required; a lead that only
   states the action fails, and so does one that only states the finding.
3. Follow-up sentences carry the specific values, per-condition breakdowns,
   and the panel references (`Fig.~\ref{fig:reservoir}A,B`).
4. A closing sentence that states the consequence in plain language,
   bounded to what was tested.

Design parameters (four fractions, eight capacities, five sizes, multipliers
0.1, 1, or 10) may appear in the lead. Result numbers (percentages, per-row
values, outcome ranges) may not. Write "in-sample" and "out-of-sample" in
full in a lead. Panel-only citations belong in body sentences, never in the
lead. Transition leads ("Having located the instability in the lattice, we
asked ...") follow the same template.

## Zero-Tolerance Gates

Run these before declaring any section clean. Line-wrapped LaTeX hides hits
from a naive grep, so de-wrap first where shown. Every hit is a violation
unless it is on the allow-list.

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
- Verify against the data, not against memory or the previous draft. Sources:
  `code/data/ModelB-ReservoirQuench-Full-{Summary,Derived,Grouped}.csv`,
  `ModelB-BalanceSheetQuench-Full-Grouped.csv`,
  `ModelB-Revision-{FiniteSize-Scaling,Horizons-Scaling,Controls-Grouped,band,impact,pulse,screen,long}.csv`.
  Boundary is `endogenous`/`hold`; capacity is `Inf` for unlimited;
  drawdowns are stored as fractions. `/opt/homebrew/bin/python3` has a
  working pandas; the Anaconda python does not.
- Give the number instead of the adjective. "Very different price declines"
  becomes "drawdowns from below 1% to above 25%" or "differed by more than
  an order of magnitude."
- Wilson 95% intervals for proportions; medians and interquartile ranges for
  continuous summaries; seed-bootstrap intervals (2,000 whole-seed
  replicates) for midpoints, widths, and susceptibility peaks; all
  conditional on the refined grid and the 3,000-step horizon.
- Measurement windows differ and must be stated: production campaigns
  compute dealer rejection over the full run including the 1,000 baseline
  steps; the supplementary controls use post-activation orders only.
  Drawdown is post-activation in both.
- Claims the paper does NOT make and must not drift into: classical
  nucleation (no free-energy barrier, activation rate, surface tension, or
  critical droplet); an asymptotic or equilibrium threshold (the crossover is
  finite-time and its midpoint drifts with horizon); stationarity of the
  baseline or of the final window; global stability from the 100,000-step
  no-switch runs; a unique mechanism for the non-monotone capacity response
  (the frozen band implicates width adaptation without isolating it);
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
  runs, nearest median final Sell fraction otherwise; seed 25 for the dealer
  panels) is stated in Methods and must not be described as illustrative
  choice.
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
- **Generated files, never hand-edited:** `sections/finite-size-results.tex`,
  `finite-size-table.tex`, `revision-tables.tex`, `revision-fits-table.tex`,
  `revision-controls.tex`. Edit the template strings in
  `code/revision/Write-Revision-Tables.py` and rerun
  `/opt/homebrew/bin/python3 code/revision/Write-Revision-Tables.py` from the
  repo root. The generator substitutes numbers from the revision CSVs; a
  hand edit is overwritten on the next run. Labels in generated text use the
  `app:` prefix.
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
- `code/data/*.csv` is gitignored with explicit exceptions; the Table S2
  source and the trajectories are force-added. Check that any new derived
  CSV a table depends on is tracked.

## Review Workflow

1. Run `/review-section` on the changed sections (it carries the full
   checklist and output format) and fix everything it flags.
2. After a fix pass, run an independent read-only Codex check without being
   asked. From the repo root:

   ```bash
   codex exec -s read-only --ephemeral -c 'notify=[]' -C "$PWD" - > out.md 2>&1 <<'EOF'
   <focused prompt: numbers vs CSVs, unsupported claims, internal consistency, house style, flow;
    reply as file:line — problem — fix, "none" per category>
   EOF
   L=$(grep -nE '^codex$' out.md | tail -1 | cut -d: -f1); tail -n +$L out.md
   ```

   Verify each Codex claim against the source before applying it; it has
   caught code-versus-prose mismatches (rounded seeding, checkpoint scope,
   the rejection window) that self-review missed, and it has also over-read
   the lead-sentence rule. Apply what holds, reject with a reason what does
   not, then run a short RESOLVED / NOT RESOLVED re-check.
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
