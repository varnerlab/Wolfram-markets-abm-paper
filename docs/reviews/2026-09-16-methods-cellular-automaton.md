# Methods: three-state cellular automaton

Status: opening accepted, applied, and verified; review paused at the author's
request. The Introduction remains a “good draft.” Resume with the next
paragraph on the rule-number encoding, Rules 19280 and 19286, assignment,
and initialization. Its encoding equation and definitions were relocated
as agreed, but the rest of that paragraph still needs interactive review.

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
