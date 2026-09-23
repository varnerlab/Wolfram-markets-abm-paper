# Methods: three-state cellular automaton

Status: the complete first Methods subsection is accepted, applied, and
verified through the revised selection and initialization passage on
17 September. Continue with `2026-09-17-methods-orders.md`. The Introduction
remains a “good draft.” Earlier proposal statuses below record their
historical stage; the applied-update entries identify the saved state.

## Scope and findings

Source: `paper-arxiv/sections/methods.tex`, first subsection, especially
the opening paragraph and Eqs. `eq:neighborhood-sum` and `eq:rule-index`.
Retain one developed opening paragraph with its equations. The four-paragraph
maximum applies to the Introduction, not to the entire Methods section.

1. The current technical-trader description says each trader “bought” or
   “sold” when the quote crossed a band. The band rule produces intentions;
   it does not guarantee execution. Define the three states as intentions
   and leave the detailed band rule with the technical-trader subsection.
2. “Observed price alone” obscures the recent price history used to form the
   reference band. Name the dealer's quote and recent price history.
3. Define the grid, neighbor set, time index, input state, neighbor sum,
   lookup-table output, and rule index before displaying the equations.
   Use `k` for a table-entry index so `j` continues to identify a neighbor.
4. Preserve the implemented update order: new technical-trader states,
   previous interior states, then simultaneous interior updates. Do not
   describe all inputs as previous-step states or introduce sequential
   interior updates.
5. Explain the totalistic rule through the neighbor sum and cite the
   existing Packard–Wolfram reference. The author explicitly removed the
   same-sum example from the earlier proposal; do not restore it.

## Evidence checked

All implementation paths below are inside the frozen executed snapshot
`output/rebuilt/manuscript-reserve-v1/`.

- `code/src/Simulate.jl:101–135`: `_ca_step` copies the input grid and
  updates only interior sites. Four adjacent states are summed, excluding
  the trader's own state. Each trader's assigned table supplies the output.
- `code/src/Simulate.jl:697–754`: orders settle before technical-trader
  states are updated. Updated technical-trader states are written to the
  grid before the simultaneous interior update. The active path updates
  price-history statistics and uses the new dealer quote. The held path
  writes Hold.
- `code/src/Compute.jl:59–62`: `compute_band_state` returns a state code;
  it does not perform a trade.
- `code/src/Factory.jl:330–365`: initialization places Buy and Sell states
  without replacement inside an otherwise Hold grid. The perimeter starts
  in Hold. `_ca_step` preserves unselected perimeter states.
- `code/src/Simulate.jl:28–89` and `:590–610`: selected interior traders
  receive a preselected rule assignment. Delayed activation initially
  restores their baseline rule without resetting dynamic state.
- `code/rebuild/RebuildRuntime.jl:5–9`: the corrected study selects reserve
  clearing explicitly. The old standing-quote comment in the general
  simulation loop does not describe the executed reserve branch.

Targeted arithmetic check, with no simulation: Rule 19280 has outputs
`[2,0,0,0,1,1,2,2,2]` for sums 0 through 8. Rule 19286 has outputs
`[2,2,0,0,1,1,2,2,2]`. Their base-three strings match the manuscript and
only the response at sum 1 changes. Both illustrative neighborhoods in
the opening paragraph sum to 2.

## Revised proposal: totalistic decisions

The author identified the rule as totalistic and rejected the previous
proposal's choppy sequence of definitions. Verified Wolfram's definition
in *A New Kind of Science*, page 60:
https://www.wolframscience.com/nks/p60--more-cellular-automata/ .
His definition uses the average of neighborhood states; with four equally
weighted neighbors this is equivalent to using their sum. The frozen
`Factory.jl:14–43` assigns equal weights and decodes base-three outputs.
The executed `_ca_step` sums exactly four adjacent states, excluding the
center. Wolfram's example on page 170 includes the center, so retain the
explicit four-neighbor scope of this model rather than copying that
neighborhood convention.

Reorganize the opening around how neighboring intentions determine the
next local decision. The author subsequently removed the illustrative
same-sum example in favor of a reference, requested that technical traders
be introduced before their effect on nearby interior traders, and required
“updated” to name the intended actions being updated. The technical-trader
description and update order explain which intentions enter the sum.
Move the rule-number definition and `eq:rule-index` to the next developed
paragraph introducing Rules 19280 and 19286. Preserve that equation and
its label; it is relocated, not removed. The next paragraph must define
the output index `k`, output `a_k`, and encoding `R` before the display.
The two-equation opening proposed earlier is superseded, not applied.

```tex
We represented the synthetic market as $L$ rows and $L$ columns, with
$(L-2)^2$ traders in the interior. We recorded each trader's intended
action as Buy ($s=0$), Hold ($s=1$), or Sell ($s=2$). Technical traders
occupied selected positions along the edge and formed their intentions
from the dealer's quoted price and recent price history. The remaining
edge positions stayed in Hold. Each interior trader formed its local
decision from the intentions of its four neighbors above, below, to the
left, and to the right. The decision rules were totalistic: each trader's
next intention depended only on the sum of these four neighboring
states~\cite{packard1985two}. For interior traders next to the edge, this
sum could therefore include the intentions of technical traders. At each
time step $t$, the technical traders updated their intended actions
using the latest quote and price history. All interior traders then
updated their intended actions together using the previous interior
states and the newly updated edge states. We denoted the four neighbors
of trader $i$ by $\partial i$ and the state supplied by neighbor $j$ at
step $t$ by $s_j^{\rm in}(t)$. The totalistic rule used their sum $c_i(t)$,
defined by:
\begin{equation}
  c_i(t)=\sum_{j\in\partial i}s_j^{\rm in}(t)\in\{0,1,\ldots,8\}.
  \label{eq:neighborhood-sum}
\end{equation}
```

The likely reference recalled by the author is Packard and Wolfram,
*Two-dimensional cellular automata*, published in March 1985, received
October 1984. The publisher lists both authors at the Institute for
Advanced Study in Princeton. Verified date, title, authors, affiliation,
and DOI at https://link.springer.com/article/10.1007/BF01010423 and the
author's publication list. The entry `packard1985two` is already in the
bibliography. The official full-paper links failed or returned unrelated
content through the web tool; they were not treated as successful full-text
verification. The totalistic definition was independently checked in the
author's book as recorded above. Retain the applicable existing citations
when integrating the rule-encoding paragraph. No new bibliography entry
is needed. No Methods source, model, data, PDF, or
archive was changed in this review-only turn. Independent review and
rendered verification will follow an authorized manuscript edit.

## Applied update and stopping point

The author approved the final opening and requested an update before pausing.
Applied the quoted opening and its neighbor-sum equation. Moved the
rule-number equation to the start of the next paragraph with definitions
of output `a_k`, sum index `k`, and number `R`. Preserved both equation
labels and the existing citations. The manuscript from “Rule 19280” onward
is byte-for-byte unchanged, as is the accepted Introduction. The moved
definitions are a necessary bridge, not acceptance of the next paragraph's
remaining prose.

Independent read-only review found no material issue in the final saved
state. The geometry, intention codes, four-neighbor totalistic sum,
simultaneous interior update, input timing, and base-three encoding agree
with the frozen implementation. No simulation or model source changed.

The normal build passed without LaTeX/BibTeX warnings, undefined references,
or overfull boxes. The PDF remains 29 pages. Extracted text changed on pages
3–11; visually inspected pages 2–12, including adjacent pages. The opening
and neighbor-sum equation fit together on page 3; the rule encoding begins
page 4. No clipping, overlap, or broken layout was seen. The 25-file source
archive passed its isolated compile with identical extracted PDF text.
Refreshed the output PDF copy. Root, output, and archive validation SHA-256:
`50486c3ad264d52ca398dbf1be742736b4e1c849befddb99e9fe6a5af0584183`.

Resume at the rule-number and two-rule paragraph when the author returns.
Do not advance the review during the requested break.

## Rule construction review, 17 September 2026

The author resumed the review and requested the rule-construction material.
Current scope is `paper-arxiv/sections/methods.tex:29–41`, ending before
selection of the traders whose rules will change. Assignment and
initialization remain the following review unit; this division does not
require a new manuscript paragraph.

The existing equation, base-three strings, and single changed response
are correct. The main editorial gap is the connection between the nine
neighbor sums, their output codes, and the digit order in the rule number.
The current text defines an output as an intended action but can identify
it more precisely as the trader's next intended action. Explain the rule
construction before introducing the two selected rules and their behavioral
difference. Retain the existing three-Buy/one-Hold example, which describes
the changed response. This is distinct from the rejected same-sum example
in the opening paragraph.

Evidence checked in the frozen executed snapshot:

- `code/src/Factory.jl:14–43`: nine configurations for three states and four
  neighbors; base-three decoding associates digit `k` with sum `k`.
- `code/src/Simulate.jl:101–135`: each interior trader's assigned rule maps
  the four-neighbor sum to its next state, using a separate output grid.
- Targeted Python arithmetic reproduced both nine-digit strings and
  output vectors. The only difference is at sum 1: Buy (0) becomes Sell (2).
  Enumeration of all 81 four-neighbor configurations confirmed that sum 1
  means three Buy states and one Hold state, in any position. The nine
  independently specifiable ternary outputs give `3^9 = 19683` rules.
- Wolfram's *A New Kind of Science*, page 60, explicitly describes numbering
  totalistic rules using base-three output digits, with the smallest input
  at the right. Checked at
  https://www.wolframscience.com/nks/p60--more-cellular-automata/ . Its
  illustrated neighborhood has three cells, so its count of 2187 rules
  is not the count for the four-neighbor model here. The proposed count
  was calculated for the implemented model.

### Proposed passage, not applied

Each totalistic decision rule assigned an intended action to each of the
nine possible neighbor sums. For a sum $k\in\{0,1,\ldots,8\}$, we denoted
the trader's next intended action by $a_k\in\{0,1,2\}$, using the codes
for Buy, Hold, and Sell. Specifying these nine outputs defined the complete
rule, giving $3^9=19{,}683$ possible rules for the four-neighbor model.
We identified each rule by its Wolfram rule number $R$, with the outputs
written as base-three digits from $a_8$ on the left to $a_0$ on the right.
The rule number was therefore defined by:

```tex
\begin{equation}
  R=\sum_{k=0}^{8}a_k3^k.
  \label{eq:rule-index}
\end{equation}
```

We used Rule 19280, $(222110002)_3$, as the baseline and Rule 19286,
$(222110022)_3$, for the selected traders after the rule change. The two
rules differed only in their response to neighbor sum $k=1$, corresponding
to three neighbors intending to Buy and one intending to Hold. For this
configuration, Rule 19280 assigned Buy and Rule 19286 assigned Sell as the
trader's next intended action. All other neighbor sums produced the same
intended action under both rules.

Retain the existing Wolfram and Packard–Wolfram citations beside the encoding
definition if applied. The live source and PDF remain unchanged, so the
earlier build and visual verification record still describes the saved
manuscript. This turn checked source and arithmetic; no simulation or new
rendered review was performed.

## Rule construction applied and verified, 17 September

The author accepted the construction proposal and requested “Update. Next.”
Applied that wording in `paper-arxiv/sections/methods.tex:29–48`, retaining
the existing citations and `eq:rule-index`. The opening and source from
“Before each run, we selected” onward are unchanged. No new manuscript
paragraph break was introduced between rule construction and selection.

Independent read-only reviewer `rule_construction_check` found no material
issue in the saved passage. The reviewer checked the rule count, encoding,
digit strings, changed response, and intention semantics against the frozen
implementation and independent arithmetic. That check did not cover the
next selection/initialization proposal or rendered layout.

`make -C paper-arxiv` passed. Final LaTeX and BibTeX logs have no warnings,
undefined references, or overfull boxes. The PDF remains 29 pages; extracted
text changed only on pages 3 and 4. Rendered and inspected pages 2–5 at
85 dpi. Rule construction now begins near the bottom of page 3 and continues
on page 4, with its equation lead-in and equation together. No clipping,
overlap, or isolated paragraph line was observed. The 25-file arXiv archive
passed an isolated build with identical extracted PDF text and no warnings
in the final compilation pass. Initial-pass unresolved references resolved
during the normal latexmk reruns. Refreshed the output PDF copy.

Current root PDF, output PDF, and archive-validation manuscript SHA-256:
`7d63e77ef901b878c26b872f58daa35c96efddec6e34de3cea07ac2dc93206e7`.

## Selection and initialization: next proposal, not applied

Scope: the rest of the current subsection, beginning “Before each run”
(`paper-arxiv/sections/methods.tex:48–62`). Explain the selection and rounded
counts in plain language and preserve nonoverlapping initial placements.
Keep seed and priority details in the supplementary reproducibility text.
Distinguish the
rule-change operation from a separately scheduled resource intervention.
The current blanket statement about retaining holdings at the intervention
could otherwise be read to cover the cash/share experiments too.

Evidence checked in `output/rebuilt/manuscript-reserve-v1/`:

- `code/src/Simulate.jl:78–85`: interior candidates are selected with
  `randperm` and the count is `round(Int, f * length(candidates))`.
- `code/src/Factory.jl:240–243,330–366`: the main default initialization
  uses equal Buy/Sell fractions of 0.05, rounded separately to integer
  counts and assigned to distinct positions using one random permutation.
  The remaining positions start in Hold.
- `code/model-b/Compute-ModelB-RuleQuench.jl:55–69,101–115`: the main paired
  campaign uses these defaults, interior-only selection, and delayed rule
  activation. Supplementary alternative initial-condition controls are
  outside this description of the main setup.
- `code/src/Simulate.jl:579–608`: the setup generator is seeded; locations,
  bands, initial states, and target selection follow a reproducible order.
  Selected rules are stored and reset to the baseline before the run.
- `code/src/Simulate.jl:232–256` and `code/src/ReserveClearing.jl:78–87`:
  rationing priorities depend on seed, step, trader identity, and side.
  A fixed seed does not imply one unchanging priority order over time.
- `code/src/Simulate.jl:678–692`: the rule branch changes only the rule
  field; the separately scheduled resource intervention executes afterward.
  Thus the rule change itself preserves intention and holdings, although
  a simultaneous resource intervention can change the latter.

Proposed continuous passage:

Before each run, we specified an approximate fraction $f$ of interior
traders to receive Rule 19286 later in the simulation. We selected
$\operatorname{round}(f(L-2)^2)$ traders uniformly without replacement.
We initialized the interior with
$\operatorname{round}(0.05(L-2)^2)$ traders intending to Buy and the same
number intending to Sell. Their positions were chosen uniformly without
replacement, and all remaining interior traders began in Hold.
All interior traders initially used Rule 19280, allowing the market to
develop before the scheduled rule change. At the switch, the selected
traders received Rule 19286 and first used it to determine their next
intended action. All other interior traders continued using Rule 19280.
Assigning the new rule did not execute a trade or reset any trader's cash
or shares.

This proposal preserves the current setup and rule-switch procedure. It
does not change the separate experimental protocols or apply edits to the
remaining Methods text. Timing and paired-control detail remain in the
paired-experiments subsection for its later review.

Author feedback, 17 September: use “an approximate fraction,” delete the
separate rounding explanation, and omit the seed and order-priority detail
from this passage as implementation detail. These details are already in
the supplementary rationing and reproducibility material (`appendix.tex`,
the priority-score description and the seeded-Xoshiro description). Also
clarify the final statement about intentions and holdings by explaining
that the new rule is first used for the next intended action, and that
assigning the rule performs no trade or reset of financial holdings.
The revised proposal above replaces the previous proposal; no manuscript
or PDF update was made in this discussion turn.

## Selection and initialization applied and verified, 17 September

The author accepted the revised proposal and requested “Update. Next.”
Applied the exact revised wording, with normal LaTeX rule-number spacing,
to `paper-arxiv/sections/methods.tex:48–59`. The previously accepted rule
construction and all source from the next subsection onward are unchanged.
Preserved the existing paragraph structure. Seeded setup and order
priorities remain documented in the unchanged supplementary material.

Independent read-only reviewer `rule_construction_check` verified the
rounded selection and initial counts, without-replacement sampling, Hold
and baseline initialization, delayed rule use, and absence of a trade or
financial reset in the assignment operation. No material issue was found.
No model code or data changed and no simulations were run.

Normal build and isolated 25-file source-archive compilation passed with
identical extracted PDF text. Final LaTeX/BibTeX logs were clean: no
warnings, undefined references, or overfull boxes. The PDF remains 29
pages; only page 4's extracted text changed. Rendered and visually inspected
pages 3–5 at 85 dpi. The revised passage fits on page 4; the following
heading and equations remain legible and unbroken. No clipping, overlap,
or isolated paragraph line was observed. Refreshed the output PDF copy.

Current root PDF, output PDF, and archive-validation manuscript SHA-256:
`724537f67b51d5487b65c7c473f73d0a307c98d88e7fab0d736d693b93ed0e98`.

The subsection is now complete for this interactive review. Next is the
opening paragraph of “Orders, trader resources, and completed trades”; its
proposal and checks are recorded in `2026-09-17-methods-orders.md`.
