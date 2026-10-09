# Interactive Publication Review

Started 16 September 2026. This records the current review, not the historical
validation of the corrected simulation study.

- **23 September: review switched to whole sections** against
  [VOICE_GUIDE.md](VOICE_GUIDE.md); one line per section from here on.
  Results rewritten, approved, and applied through the generators (23 Sep).
  Paper-wide nomenclature pass applied the same day (table in HOUSE_STYLE.md);
  change PDF in `output/review/2026-09-23-nomenclature/`. Discussion rewritten,
  approved with the author's opening, and applied (23 Sep). Abstract, Conclusion,
  and new title ("When Selling Spreads: ... in a Simulated Market") applied the
  same day; the subtitle keeps the scope restricted to the model (item 16).
  Introduction and Methods rejoined to the author's rhythm (median 16 -> 24-26
  words) and the uncertainty-scope passage written (23 Sep). Open: the
  Introduction describes crowding/following experiments not yet in the paper.
- Voice and review guide: [PUBLICATION_STYLE.md](PUBLICATION_STYLE.md).
- Project requirements and evidence: [HOUSE_STYLE.md](HOUSE_STYLE.md).
- Active manuscript: [paper-arxiv/Paper_v1.tex](paper-arxiv/Paper_v1.tex).
- Current stage: “Three-state cellular automaton” is accepted, applied,
  and verified through selection and initialization on 17 September.
  The orders/resources opening and a corresponding Discussion limitation
  are accepted, applied, and verified, as are dealer reserves and the
  execution-price construction. Trade-quantity selection and allocation
  are also accepted, applied, and verified. Settlement and the dealer's
  quoted price are now applied and verified with the accepted transaction-fee
  extension. On 18 September, completed 8,400 additional full financial
  simulations and integrated their Methods, Results, Table S12, and
  supplementary validation. Independent technical and numerical review and
  PDF checks passed. The technical-trader opening is accepted, applied,
  and verified, retaining the Bollinger-band-type description. The band
  calculation and initialization are also accepted, applied, and verified.
  The trading-step sequence and held/active comparison are also accepted,
  applied, and verified. The paired rule-switch opening is also accepted,
  applied, and verified. Simulation counts, initial holdings, observation
  periods, and supplementary comparisons are also accepted and applied.
  The fractions, dealer reserves, and market sizes tested are also
  accepted, applied, and verified. Trader-resource interventions are also
  accepted and applied. The transaction-fee design opening is also
  accepted, applied, and verified, as are its outcomes and uncertainty
  sentences. The market-outcomes opening, defining majority formation,
  onset, probability, and final-window averages, is also accepted,
  applied, and verified. The susceptibility definition is also accepted,
  applied, and verified. Interpolated midpoints and response widths are
  also accepted, applied, and verified, as are Wilson intervals and
  summaries of variation between runs. The financial-outcomes opening,
  defining drawdown and its measurement window, is also accepted,
  applied, and verified, as are unfilled-order classifications and the
  dealer-rejection fraction and the closing financial-summary sentence.
  Adaptive selection of additional tested fractions is also accepted,
  applied, and verified, as is the clarified bootstrap uncertainty
  explanation and the logistic-curve comparison. The scope and limits
  of the uncertainty estimates are under discussion.
  The Introduction remains an accepted “good draft.”
- Manuscript edits in this round: full Introduction consolidation, preserving
  the accepted opening and central model explanations. The resources argument
  now belongs to the model overview. The closing paragraph develops the
  comparisons. The closing paragraph now distinguishes mixture comparisons
  from market-size experiments, covers both sides of trade execution, and
  includes the following experiments. The accepted first Methods subsection
  is applied, including totalistic decisions, rule encoding, selection, and
  initialization. Seed and priority details remain in the supplement.
- First review unit selected by the author: Introduction. Title and abstract
  remain pending.

## Coverage

The Introduction is a **good draft**, accepted by the author for moving on,
with its changes applied and verified. The first Methods subsection is
**accepted and applied**, as are the orders/resources opening and dealer
execution-price construction, trade-quantity selection, allocation,
settlement, and quoted price. The accepted transaction-fee extension is
**implemented and verified**, with new simulation evidence and generated
manuscript additions; the author's review of their voice remains open.
The technical-trader subsection is **accepted and applied**, including
the held/active comparison. The paired rule-switch opening is also
**accepted and applied**, as are its study-design summary and main
parameter comparisons and trader-resource interventions. The transaction-fee
design opening, outcome measures, and uncertainty sentences are
**accepted and applied**. The market-outcomes opening is also
**accepted and applied**, as are its susceptibility definition and
interpolated midpoints and response widths. Wilson intervals and
interquartile summaries are also **accepted and applied**. The
financial-outcomes opening, unfilled-order classifications, dealer-rejection
fraction, and closing financial-summary sentence are also **accepted and
applied**, as is adaptive selection of additional tested fractions.
The clarified bootstrap uncertainty explanation is **accepted and applied**.
The logistic-curve comparison is also **accepted and applied**. The scope
and limits of the uncertainty estimates are **under discussion**.
Targeted Discussion
limitations are applied; the full Discussion review remains pending.
Remaining Methods units and other sections are **pending**. Integration
of crowding and following into later sections and final manuscript-wide
consistency review remain pending.
Locating a file does not count as reviewing
its science or rendered appearance. Mark a unit reviewed only after its
findings have been discussed; record editing and verification separately.

| Unit | Source and associated material |
|---|---|
| Title and abstract | `Paper_v1.tex`; check claims against the completed Results review again at the end |
| Introduction — good draft | `sections/introduction.tex`; accepted by the author for moving on; four paragraphs retained |
| Methods: three-state cellular automaton — accepted/applied | `sections/methods.tex`; opening, rule construction, selection, and initialization verified |
| Methods: orders, resources, and trades — accepted/applied | `sections/methods.tex`; opening, dealer/execution-price construction, quantity selection, allocation, settlement, and quote verified; accepted fee extension included |
| Methods: technical traders and feedback — accepted/applied | `sections/methods.tex`; opening, bands, initialization, step sequence, and held/active comparison verified |
| Methods: paired experiments — accepted/applied | `sections/methods.tex` and generated `sections/transaction-fees-methods.tex`; original comparisons, fee design, outcomes, and uncertainty verified |
| Methods: outcomes and analysis — accepted/applied through logistic comparison | `sections/methods.tex`; decision outcomes, susceptibility, midpoint/width, Wilson/quartile summaries, financial outcomes, adaptive fraction selection, bootstrap, and logistic comparison verified; uncertainty limitations proposed next, followed by selection of examples |
| Methods: crowding and following — pending integration | Corrected advice/copying pilot and shared-advice confirmation protocols; no manuscript method text yet |
| Results: rule change | `sections/results.tex`; Figure 1; Tables S1, S2, S5, S6 |
| Results: technical traders held | `sections/results.tex`; Figure 2A,B and linked comparisons |
| Results: size and observation window | `sections/finite-size-results.tex`; Figure 3; Tables S3, S9, S10 |
| Results: spatial histories | `sections/results.tex`; Figure 4; Table S11 |
| Results: dealer reserves | `sections/results.tex`; Figures 2C,D and 5; Tables S2, S7, S8 |
| Results: trader cash and shares | `sections/results.tex`; Figure 6; Table S4 |
| Transaction-fee extension — implemented/verified | `sections/transaction-fees-{methods,results,table,validation}.tex`; 8,400 simulations; Table S12; independent numerical and implementation review passed; author voice review remains open |
| Results: crowding and following — pending integration | `output/repaired/following-reserve-v2-pilot/` and `output/repaired/transmission-confirmation-v1-full/`; generators, figures, tables, and Discussion coverage pending |
| Discussion — full review pending | `sections/discussion.tex`; targeted limitation on intentions without trading resources applied; remaining interpretations and literature pending |
| Conclusion | `sections/conclusion.tex`; scope and consistency with the findings |
| Supplement: simulation step | `sections/appendix.tex`; both algorithms and their implementation |
| Supplement: rationing and reproducibility | `sections/appendix.tex`; pairing and randomization |
| Supplement: conservation and limits | `sections/appendix.tex`; equations, tests, and validation claims |
| Supplement: simulation design | `sections/appendix.tex` and `sections/rebuild-validation.tex`; executed protocol and records |
| Supplement: controls | `sections/revision-controls.tex`; controls, sensitivity analyses, and linked tables |
| Bibliography and publication statements | `References_v1.bib`; citations, availability, acknowledgments, and funding if applicable |
| Complete manuscript | Cross-section terminology, claim consistency, float coverage, references, and every rendered page |

Figure captions live in `sections/figures.tex`. Table material lives in
`sections/tables.tex`, `sections/finite-size-table.tex`,
`sections/revision-tables.tex`, `sections/revision-fits-table.tex`, and
`sections/market-panel-horizons-table.tex`, and
`sections/transaction-fees-table.tex`. Review each with the passage it
supports, then confirm coverage of all six figures and twelve tables.
Manuscript paths in the table are relative to `paper-arxiv/`; the two
following-study output paths are relative to the repository root. Additional
following-study figures and tables remain to be selected and integrated.

## Source handling

Results, captions, tables, and supplementary control and validation text are
generated. Consult `code/rebuild/WriteResults.py`, `WriteCaptions.py`,
`WriteManuscriptTables.py`, and `Verify.py` before an authorized edit. These
writers target the isolated study's manuscript; follow the build and install
workflow in [code/rebuild/README.md](code/rebuild/README.md). Preserve the
executed simulation snapshot and its provenance.

The fee extension uses `code/fees/WritePaper.py` and the separate completed
study `output/rebuilt/transaction-fees-v1/`. Preserve its four generated
inputs when regenerating original Results or tables. Its reporting-only
analysis correction is recorded in `Postprocessing-Sources.json`; frozen
simulation and numerical-analysis sources remain unchanged.

## Decisions and calibration

**Author preferences stated 16 September:** simple and direct language;
restrained adjectives; clear sentences without comma or semicolon chains;
long, well-developed paragraphs; technical correctness and voice reviewed
together; an interactive review covering every section.

**Structural correction, 16 September:** the author explicitly requires at
most four Introduction paragraphs and rejected the accumulation of isolated
vignettes during the passage-by-passage review. A review unit is not a
manuscript paragraph. Preserve the section's integrated argument while
revising individual passages. This limit is now in both style guides.
The earlier six-part progression below is historical and superseded by the
four-paragraph revision recorded at the end.

**Draft editorial changes:** remove sentence-length quotas and a compulsory
Results lead formula. Judge paragraph development by the argument and its
evidence. These implement the stated preferences and can be refined during
the review.

**Author calibration feedback:** earlier polish rounds did not sound like
the author and felt formulaic or choppy. The author did not report a known
failure of technical checking. Improve voice and continuity while retaining
the evidence checks; do not infer that prior scientific errors were found.

**Accepted Introduction opening:** retain “An investor’s decision to sell
can prompt others to do the same.” Name buyers and sellers, include buyers'
perceptions of value, and identify their funds as supporting purchases.
Use “traded financial assets such as stocks” for the scope.

**Introduction, 16 September:** the author chose this as the first section.
The [review record](docs/reviews/2026-09-16-introduction.md) contains the
argument, located findings, checked evidence, the applied first paragraph,
verification, and the next paragraph proposal.

**Introduction opening feedback, 16 September:** start with markets as the
collective outcome of human interactions, including our ingenuity and
failings. Introduce that motivation before the detailed model literature.
The suggested quotation was verified in the Financial Crisis Inquiry
Commission's 2011 report on the 2008 crisis, page xvii. The author also asked
to omit the assistant's verification aside about the simulator from the
reader-facing explanation. The opening and report reference were applied
after the author's “Agree. Update. Next.”

**Trade-price explanation feedback:** identify the sellers and buyers and
explain whose funds support the purchase. Include perceptions of asset value
alongside financial resources. The accepted wording distinguishes buyers'
willingness to pay from their ability to pay. The author accepted the scope
of traded financial assets such as stocks without assuming liquidity
persists during a decline.

**Opening verification, 16 September:** normal build and isolated archive
compile passed with identical extracted PDF text. No LaTeX or BibTeX warnings,
undefined references, or overfull boxes. The revised PDF has 30 pages.
Inspected reflowed main text, bibliography, adjacent tables, and supplementary
pages (PDF pages 2–17 and 26–30). An independent read-only technical review
found no material issue in the opening or the new bibliography entry. The
review record identifies the checked PDF hash and the scope of these checks.
At that stage, only the opening had been applied. The subsequent literature
revision and its verification are recorded below.

**Literature coverage feedback:** the proposed examples cannot stand for the
full agent-based finance literature. Use review articles for breadth and
primary studies for the mechanisms relevant to the paper. Farmer and Joshi
(2002) is already in the bibliography and directly concerns trading rules
and price formation. Its model description was checked against the primary
paper. The proposed paragraph needs less detail on the Santa Fe family and
a clearer explanation of why particular examples are discussed. Frame the
contribution through the specific comparison performed here; a claim about
what the entire literature has not addressed is not established by this review.

**Prior work supplied by the author:** checked Wheeler and Varner,
*Scalable Agent-Based Modeling for Complex Financial Market Simulations*,
arXiv:2312.14903v2. Record and proposed wording are in the Introduction review
notes. Use this work to discuss explicit order matching. The reference is
now in the manuscript bibliography as `wheeler2023scalable`.

**Literature and grid revision applied:** the author accepted the revised
Bornholdt explanation and requested application. The model examples form
one paragraph, followed by the developed account of the grid as an influence
network. The closing sentence distinguishes the connections from the rule
used to respond to neighboring decisions. Farmer–Joshi, Santa Fe, and
Wheeler–Varner have specific roles in the broader discussion; Iori and
Bornholdt support the grid and Ising explanation. The new source does not
claim exhaustive literature coverage or a field-wide absence of prior work.

**Literature verification:** the normal build and isolated archive compile
passed with identical extracted PDF text. No LaTeX/BibTeX warnings, undefined
references, or overfull boxes. The PDF now has 29 pages. Inspected PDF pages
2–15 and 25–29. Independent read-only reviewer `literature_technical_check`
found no material scientific issue in the edited paragraphs or new reference.
The updated PDF hash and next paragraph proposal are in the review record.
At that stage, the later Introduction paragraphs remained unchanged.

**Model overview applied:** after the author's “Agree. Next,” applied the
general account of two interior trader types with one differing response,
technical traders carrying price information into the grid, and the dealer
acting as market maker. Table-entry operations, the Sell pulse, and the
shared-history comparison remain in Methods and the pending closing study
paragraph. This describes the existing experiment without changing its timing.

**Model overview verification:** the normal build and isolated archive
compile passed with identical extracted PDF text. The PDF remains 29 pages,
with no LaTeX/BibTeX warnings, undefined references, or overfull boxes.
Inspected rendered pages 2–15. Independent read-only reviewer
`model_overview_check` found no material issue in the saved paragraph.
The output PDF and source archive were refreshed. The review record contains
the current hash and the next resources-paragraph proposal.

**Next-paragraph citation finding:** Braun-Munzinger and colleagues explicitly
do not constrain their market maker's balance sheet. Do not use that study
as evidence of finite dealer reserves. The proposed resource summary uses
Raberto and colleagues for trader resources and Thurner and colleagues for
borrowing limits. The subsequent structural rewrite removes this attribution
from the Introduction and integrates resources into the model overview.

For each completed unit, record its location, the author's wording or
structural decisions, source edits if any, evidence checked, visual checks,
and unresolved questions. Do not mark an unverified claim as resolved merely
because its wording was accepted.

**Four-paragraph consolidation:** the author rejected the fragmented
Introduction and required at most four paragraphs. Reorganized the complete
section, preserving the opening and connecting literature, influence,
trader types, resources, prices, and the study comparisons. Review the
whole revised Introduction next; do not resume adding separate paragraphs.
Both style guides now record the structural correction.

**Consolidation verification:** exactly four Introduction paragraphs. Normal
build and isolated archive compile passed with identical extracted PDF
text; no warnings or overfull boxes. The PDF is now 28 pages. Inspected
rendered pages 2–14 and 24–28. Independent read-only reviewer
`integrated_introduction_check` found no substantive scientific issue.
The refreshed PDF hash and scoped checks are in the review record. The
new integrated wording remains open for author discussion.

**Intentions, execution, and explicit names:** the author flagged language
that could imply short selling, omitted buyers without cash, and left the
cash/share quote unexplained. Introduction paragraphs 3–4 now define Buy
and Sell as intentions and a completed trade as an actual transfer of cash
and shares. Traders without shares cannot sell; traders without enough cash
cannot buy. Neighbors can still respond to their intentions. The dealer's
quoted price is explicitly remaining cash divided by share count after
trading. The final paragraph names the three-state cellular automaton market.
Both guides now emphasize these distinctions and explicit referents.

**Clarification verification:** four paragraphs retained; the first two are
unchanged. The build and isolated archive compile passed with identical
extracted PDF text and no warnings or overfull boxes. Inspected rendered
pages 2–15 and 25–29 of the revised 29-page PDF. The independent technical
review found no material issue in the saved paragraphs. Current hash and
scope are in the Introduction review record; no model or data changed.

**Introduction accepted; Methods started:** after “Agree. Update. Next,”
recorded acceptance of the already saved and verified Introduction. The
[next review record](docs/reviews/2026-09-16-methods-cellular-automaton.md)
checks the cellular-automaton opening against executed code and proposes
one developed paragraph with its equations. The proposal distinguishes
intentions from execution, names the dealer quote and price history,
and preserves the exact neighbor inputs and simultaneous interior update.
The later rule-assignment paragraph remains to discuss. No Methods edit
or PDF rebuild was needed in this review-only turn.

**Still on the Introduction:** the author clarified that the closing
paragraph remained under review. The earlier decision to mark the whole
Introduction accepted and move to Methods was premature. The Methods
proposal is parked, and no Methods source has been changed.

**Closing paragraph correction:** specified that paired simulations had
identical intentions and financial conditions when the second trader type
was introduced, while subsequent intentions and trades could differ.
Named the varied quantity as the fraction of interior traders using the
second rule. Explained that holding technical traders in Hold left interior
trading and dealer quote updates active but removed the price signal from
neighbor inputs. Removed the paired-simulation citations from the trader-type
sentence and retained their existing Discussion use. The entire closing
paragraph is now in past tense. Four Introduction paragraphs remain.

**Closing verification:** first three paragraphs unchanged. Normal build,
isolated archive compile, and PDF-text comparison passed without warnings
or overfull boxes. The PDF remains 29 pages. Inspected rendered pages 2–14.
Independent read-only recheck found no material scientific issue. Refreshed
the output PDF and recorded the hash in the Introduction review notes.

**Synthetic market terminology:** used the author's preferred setting name
throughout the Introduction, with rows, columns, and neighboring traders
where the arrangement matters. Size comparisons now name different numbers
of traders. Four paragraphs and the closing paragraph's past tense remain.
Normal and isolated archive builds passed; extracted PDF text matched.
Visually inspected pages 2–12 of the 29-page PDF. The independent technical
review found no material issue. Refreshed the output PDF and recorded its
hash in the Introduction review notes. Methods remains pending.

**Author's verb correction:** changed “used” to “constructed” in “In this
study, we constructed a synthetic market ...”. Independent recheck, normal
build, and archive verification passed. Inspected pages 2–4; only page 3's
text changed. Refreshed the output PDF and recorded its current hash.

**Closing paragraph remains in discussion:** checked the distinction between
equal trader counts within paired mixture comparisons and the separate
market-size experiments against the frozen design and data. Proposed simpler
language for later decisions and trades, an explicit buyer-affordability
explanation in the held condition, and a final sentence about understanding
market crashes. The proposal has not been applied; manuscript and PDF remain
at the verified “constructed” revision.

**Broader purpose under discussion:** seller-side execution wording was
accepted. The author then asked whether the study accomplished its aim and
made a worthwhile contribution. Checked frozen paired-rule, resource,
dealer, and control summaries. The review record distinguishes the supported
controlled-model findings from independence built into the held decision
rules, assumed price formation, and untested empirical generality. The
closing paragraph and its final purpose sentence remain pending application.

**Crowding and copy trading:** the author identified these missing extensions
in the study overview and clarified “crowding,” not spatial clustering.
They are currently absent from the active manuscript's Methods and Results
as well as its Introduction. Reviewed the repaired ten-market advice/copying
pilot and the separate 50-market shared-advice confirmation. Plan their
coverage within the ongoing section review; preserve the distinction between
confirmed shared-advice findings and exploratory copying results. Introduction
wording remains a proposal; matching Methods, Results, figures/tables, and
Discussion coverage is pending. No new simulations or manuscript edits made.

**Complete closing paragraph applied:** integrated the accepted comparisons,
execution clarification, crowding/shared-advice/copying overview, and
contribution ending. The first three paragraphs are unchanged and the
Introduction remains four paragraphs. Limited the held price-feedback claim
to the rule-change experiments after independent review identified the
execution-mediated route in copying. The reviewer confirmed the correction.
Normal and isolated archive builds passed without warnings or overfull boxes;
archive PDF text matched. Visually inspected pages 2–12 of the 29-page PDF.
The complete paragraph fits on page 3. Refreshed the output PDF and recorded
its hash. Later-section integration of the following studies remains pending.

**Introduction good draft; Methods resumed:** the author explicitly accepted
the Introduction as a “good draft” and asked to move on. Reopened the first
Methods subsection and its earlier parked review. The current proposal
defines the synthetic market through rows and columns, distinguishes
intentions from trades, explains the neighbor inputs and update order, and
defines the rule encoding before its equations. The rule-assignment and
initialization paragraph remains the next passage within that subsection.
No manuscript or PDF change was made in this review turn.

**Methods opening revision:** the author identified the decision rule as
totalistic and found the first proposal choppy. Verified the terminology
against Wolfram's own description and the frozen implementation. Revised
the proposal around how neighboring intentions determine a local decision.
Moved the proposed explanation of the rule-number encoding to the next
paragraph on the two rules; the equation and its label must be preserved
when applied. The proposal remains under discussion; no Methods source or
PDF change was made.

**Methods opening clarification:** removed the author's rejected same-sum
example from the proposal. Introduced technical traders and their edge
positions before describing their influence on interior traders. Replaced
bare “updated” with “updated their intended actions.” The likely recalled
reference is the existing Packard–Wolfram 1985 paper; publisher metadata
confirms the 1985 date and Institute for Advanced Study affiliation in
Princeton. The opening remains a proposal, with no manuscript/PDF edit.

**Rule construction applied, 17 September:** the author accepted the proposed
explanation of nine outputs, base-three digit order, the 19,683 possible
rules, and the single response distinguishing Rules 19280 and 19286.
Applied the passage with the existing citations and equation label.
The accepted opening and source from “Before each run” onward are unchanged.
Independent read-only technical review found no material issue. Normal
build and isolated 25-file archive compilation passed with identical PDF
text and clean final logs. The PDF remains 29 pages; text changed only on
pages 3–4, and pages 2–5 were visually inspected. Refreshed the output PDF.
The review record contains the new hash and the next proposal on selection,
initialization, reproducibility, and the rule change. That proposal makes
clear that the rule change itself does not change cash or shares; separate
resource interventions remain distinct operations.

**Selection proposal feedback, 17 September:** use “an approximate fraction”
and omit the extra explanation of rounding. Remove seed and order-priority
details from this passage; they are already covered in the supplement.
Clarify the rule switch through its use for the next intended action and
the absence of a trade or financial reset caused by assigning the rule.
Updated the proposal in the review record; manuscript and PDF are unchanged.

**Selection and initialization applied, 17 September:** the author accepted
the revised proposal. Applied “an approximate fraction,” removed the extra
rounding explanation and seed/priority details, and clarified the next
intention update and the absence of a trade or financial reset caused by
rule assignment. Other manuscript passages are unchanged. Independent
read-only review found no material issue. Normal and isolated archive
builds passed with identical PDF text and clean final logs. Only page 4
changed; inspected pages 3–5 of the 29-page PDF and refreshed the output
copy. The complete first Methods subsection is now accepted and applied.
The [orders review](docs/reviews/2026-09-17-methods-orders.md) contains the
next proposed passage and its implementation checks.

**Orders and behavioral interpretation, 17 September:** the author requested
“A Buy action ... a Sell action ...” and a simpler uniform-price sentence.
Updated the proposal only. Checked the existing disposition literature:
selling below purchase cost alone does not establish irrationality.
The author raised a substantive concern about Sell intentions without shares.
Verified that these traders cannot sell but still influence neighbors and
count toward a Sell majority. The review record identifies this as a
modeling assumption, proposes explicit wording, and records the need for
a specific Discussion limitation. Behavioral framing remains open; no
manuscript, model, or PDF edit and no new simulation was made.

**Orders opening and limitation applied, 17 September:** the author accepted
the action and common-price wording, neutral treatment of sales below cost,
and explicit assumption that intentions influence neighbors even when the
trader cannot execute them. Applied the complete Methods opening and three
sentences in the Discussion identifying the continued influence and counting
of Sell intentions after shares are exhausted, and the untested alternative
of conditioning communicated intentions on resources. No claim of irrationality
or empirical validation of this assumption was added. Existing behavioral
citations now describe the omitted reluctance to realize losses.
Independent read-only review found no material issue. Normal and isolated
archive builds passed with identical PDF text and clean final logs. The
29-page PDF changed on pages 4, 10, and 11; inspected those and adjacent
pages 3, 5, 9, and 12. Refreshed the output PDF. The orders review records
the hash and the next proposal on dealer reserves and execution price.

**Dealer and execution-price construction applied, 17 September:** applied
the accepted reserve initialization, signed net trade, reserve-product
balance, price derivation, and explicit zero-net-trade price. Preserved the
execution-price equation label and existing Angeris citation. All other
source is unchanged. Independent read-only review found no material issue.
Normal build and isolated archive compilation passed with identical PDF
text and clean final logs. The PDF remains 29 pages; text reflowed on pages
4–11, and pages 3–12 were visually checked. Refreshed the output PDF.
The orders review records the hash and next proposal on selecting the net
trade, completed order counts, and dealer rejection.

**Trade quantity and allocation applied, 17 September:** the author accepted
and requested application of the explanation of candidate eligibility,
trade direction, the largest supported integer net quantity, completed
order counts, and dealer rejection. Both numbered equation labels are
preserved. Independent read-only review found no substantive issue. Normal
and isolated archive builds passed with identical PDF text and clean final
logs. The PDF remains 29 pages; changed pages 4–11 and adjacent pages 3 and
12 were rendered and inspected. Refreshed the output PDF. The current PDF
SHA-256 is `283f5e4eae6e926b95504e0439517655558289fc5ef6135db297a2ab8a82719a`.
Settlement and the dealer's quoted price are now under discussion. The
proposal and implementation/algebra checks are recorded in
[the orders review](docs/reviews/2026-09-17-methods-orders.md); that next
passage has not been applied.


**Settlement and transaction fees applied, 18 September:** applied the
accepted common execution-price explanation and proportional fees on each
completed buy and sell, collected separately from dealer trading reserves.
Fees enter buyer affordability. The original zero-fee study is retained;
8,400 new full financial simulations compare 0, 5, 10, and 25 basis points
across three reserve depths, two feedback modes, six fractions, and 50
starting markets with fresh paired controls. Updated Methods, Results,
Table S12, pseudocode, conservation, and targeted Discussion wording.
Fees did not uniformly reduce drawdowns. Independent implementation and
numerical review passed, including all summaries and intervals. Normal and
isolated archive builds passed with identical PDF text and clean final
logs. All 31 rendered pages and the standalone sensitivity plot were
inspected. Refreshed output PDF SHA-256:
`1e9a82ce251c523b17ca01c08e5d3e69794c613d737c3f71640c33e390898212`.
The [fee review](docs/reviews/2026-09-18-transaction-fees.md) records the
protocol, numerical evidence, and review corrections. The next
[technical-trader opening](docs/reviews/2026-09-18-methods-technical-traders.md)
is proposed and remains unapplied. Broader section and author voice
reviews remain pending.


**Technical-trader opening applied, 18 September:** the author accepted the
opening and reaffirmed the Bollinger-band-type name. Applied placement,
Buy/Hold/Sell intentions, and timing; retained the qualified strategy name
and existing contrarian comparison. Named the width as an exponentially
smoothed absolute departure rather than standard deviation. Equations,
model behavior, and numerical results are unchanged. Primary-source naming
check and independent saved-state implementation review passed. Normal and
isolated archive builds passed with identical PDF text and clean final
logs. Inspected changed pages 5–12 and adjacent pages 4 and 13. Refreshed
31-page PDF SHA-256:
`193652994b614b124526d02613fb30f12dba5d7ff77acd93478fba2f6a644487`.
The [technical-trader review](docs/reviews/2026-09-18-methods-technical-traders.md)
contains the next band-calculation and initialization proposal, not yet
applied. The full feedback comparison remains pending.


**Band calculation and initialization applied, 18 September:** applied the
accepted EMA/departure explanation, aligned recurrences, initial values,
and fixed individual band multipliers. Preserved the distinction from
standard deviation and moved the unchanged normalized net purchase
definition after the band calculation. Equation labels and supplementary
references remain correct. Independent saved-state review found no
substantive issue. Normal and isolated archive builds passed with identical
PDF text and clean final logs. Inspected changed pages 5, 6, and 27 plus
adjacent pages 4, 7, 26, and 28. Refreshed 31-page PDF SHA-256:
`184dee0ae101313781d70cd5bd7b47afc0751f8d4aaba908c64e45bd93d67f46`.
The [technical-trader review](docs/reviews/2026-09-18-methods-technical-traders.md)
contains the next proposed step-order paragraph, not yet applied. The
held/active comparison follows that unit.


**Trading-step sequence applied, 18 September:** applied the accepted
paragraph and removed the repeated arrow display. Preserved the ordering
of scheduled interventions, orders, settlement, technical intentions, and
simultaneous interior updates, with orders from the new intentions at the
following step. Independent saved-state review found no substantive issue.
Normal and isolated archive builds passed with identical PDF text and
clean final logs. Inspected changed page 6 and adjacent pages 5 and 7.
Refreshed 31-page PDF SHA-256:
`dc87cdd333f07b7222a9c59fde2607fe6c0197b197950a3ed98cf773c1e3e0a0`.
The [technical-trader review](docs/reviews/2026-09-18-methods-technical-traders.md)
contains the next held/active comparison proposal, not yet applied. It
clarifies Hold from initialization, no technical orders, continued interior
trading and financial updates, and shared initialization rather than shared
pre-switch trajectories across the feedback conditions.


**Held/active comparison applied, 18 September:** applied the accepted
explanation of Hold from initialization, no technical orders, continued
interior trading and price updates, and matching initial markets and
rule-change targets. This completes the technical-trader subsection's
interactive pass. Independent saved-state implementation review found no
substantive issue. Normal and isolated archive builds passed with identical
PDF text and clean final logs. Inspected changed page 6 and adjacent pages
5 and 7. Refreshed 31-page PDF SHA-256:
`a328db71c0f3d5e037e8eee45e0c21b6284888e867320e2f260a4466920029bc`.
The [paired-experiment review](docs/reviews/2026-09-18-methods-paired-experiments.md)
contains the next opening proposal, not yet applied. It separates common
rule-switch/control history and the first possible changed intention from
the distinct held/active and resource-intervention comparisons.


**Paired-rule-switch opening applied, 18 September:** applied the author's
revised opening, naming investors assigned the new rule and explaining
shared history up to the switch. Removed the detailed first-post-switch
trade/quote explanation from this opening; the correct implementation
statement remains in the supplement. Independent saved-state review found
no substantive issue. Normal and isolated archive builds passed with
identical PDF text and clean final logs. Inspected changed pages 6 and 7
and adjacent pages 5 and 8. Refreshed 31-page PDF SHA-256:
`e1764d50db24ddeb2388f2f51850a1694cc1ea1f34414455970e0d6cbc085a10`.
The [paired-experiment review](docs/reviews/2026-09-18-methods-paired-experiments.md)
contains the next study-design summary proposal, not yet applied, covering
50 starting markets per main condition, initial holdings, observation
period, and supplementary comparisons. Main parameter grids and resource
interventions remain subsequent units.


**Study-design summary applied, 18 September:** applied the accepted
summary of 50 starting markets per main condition, initial holdings,
3,000 post-baseline steps, and separate supplementary comparisons. Kept
the summary in the developed opening paragraph. Independent saved-state
review found no substantive issue. Normal and isolated archive builds
passed with identical PDF text and clean final logs. Inspected changed
pages 6 and 7 and adjacent pages 5 and 8. Refreshed 31-page PDF SHA-256:
`40e7d59c3df85d7d132d0d60d8ea3d1146219a2367c1a8c5ad4fe0d300657a8f`.
The [paired-experiment review](docs/reviews/2026-09-18-methods-paired-experiments.md)
contains the next fraction/reserve/size proposal, not yet applied, checked
against the frozen drivers and canonical run summaries. The subsequent
resource-intervention unit remains pending.


**Main parameter comparisons applied, 18 September:** applied the accepted
fractions, dealer reserves, market sizes, and reserve-scaling explanation.
Independent saved-state review found no substantive issue against the
frozen drivers and canonical summaries. Normal and isolated archive builds
passed with identical PDF text and clean final logs. Inspected changed
pages 6 and 7 and adjacent pages 5 and 8. Refreshed 31-page PDF SHA-256:
`1447c24e8cc671c5211fcdff7b75cfbae6228d16cd131b9d5ec9994b4f0e16e8`.
The [paired-experiment review](docs/reviews/2026-09-18-methods-paired-experiments.md)
contains the next trader-resource proposal, not yet applied. It distinguishes
nine resource combinations, including an unchanged-resource reference,
from the no-rule-switch comparison and explains the expected independence
of held intentions from financial resources. The fee paragraph follows.


**Trader-resource intervention passage applied, 18 September:** applied
the accepted current-holdings rescaling, nine combinations including the
unchanged reference, share rounding, no direct dealer-reserve scaling,
common prehistory, and held-intention independence. Independent saved-state
review found no substantive issue. Normal and isolated archive builds
passed with identical PDF text and clean final logs. Inspected changed
pages 6–12 and adjacent pages 5 and 13. Refreshed 31-page PDF SHA-256:
`0ad5cf51f7bb4286d9500619158170aebc77ea2f428efa8a828ad7d555c9d448`.
The [paired-experiment review](docs/reviews/2026-09-18-methods-paired-experiments.md)
contains the next fee-design prose proposal, not yet applied. Its data and
implementation are already validated; any accepted prose edit must use
the fee manuscript generator and update postprocessing provenance. The
fee outcome/uncertainty sentences are the following unit.


**Transaction-fee design opening applied, 18 September:** applied the
accepted fee rates, basis-point definition, initialization timing, tested
conditions, shared controls, and 8,400-run count through the authoritative
fee manuscript writer. Refreshed its study copy, postprocessing hash, and
generation record. Frozen sources and numerical records remain unchanged,
as do the other three generated fee manuscript inputs. Independent
saved-state review found no substantive issue. Normal and isolated archive
builds passed with identical PDF text and clean final logs. Inspected
changed pages 6 and 7 and adjacent pages 5 and 8. Refreshed 31-page PDF
SHA-256:
`8dfa70b64b9e9e8688d60a4a6208e1b35f0d6bdecc48aedb75fd8d0a2f444622`.
The [paired-experiment review](docs/reviews/2026-09-18-methods-paired-experiments.md)
contains the next fee outcomes and uncertainty proposal, not yet applied.
It identifies buy suppression and distinguishes rule-change/control
comparisons at a fixed fee from positive-fee/zero-fee comparisons under
the same rule change.

**Fee-outcome wording feedback, 18 September:** the author requested
explicit recording at each simulation turn. Checked the frozen recording
and metric code. Revised the pending proposal to identify the time series
recorded at each simulation step, with Sell-majority formation and maximum
drawdown subsequently calculated from those histories. The proposal in the
paired-experiment review is updated; manuscript application remains pending.


**Fee outcomes and uncertainty applied, 18 September:** applied the
accepted revision through the authoritative fee writer, including the
author's per-step timing clarification. Distinguished recorded histories
from derived majority and drawdown outcomes and specified both paired
comparisons. Regenerated the input and refreshed the copied writer,
postprocessing hash, and generation record. All numerical inputs and
frozen sources remain unchanged; the other three generated fee inputs
are byte-identical. Independent saved-state review found no substantive
issue. Normal and isolated archive builds passed with identical PDF text
and clean final logs. Visually inspected changed pages 7–12 and neighbors
6 and 13. Refreshed 31-page PDF SHA-256:
`94ae7d1a9bd804a7d907380ec891653aa4d4a18e5f5095f22392938e9aaafe5a`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next opening proposal, not yet applied. Its final-500-step
average is scoped to dealer-reserve, market-size, and trader-resource
comparisons; other campaigns use different summaries.


**Market-outcomes opening applied, 18 September:** applied the accepted
definition of the interior Sell fraction, majority crossing, onset time,
majority probability, conditional onset summaries, and final-500-step
average scoped to the reserve, size, and trader-resource comparisons.
Retained the developed paragraph and subsequent equation. Independent
saved-state review found no substantive issue. No code or numerical
results changed. Normal and isolated archive builds passed with identical
PDF text and clean final logs. Visually inspected changed page 7 and
neighbors 6 and 8. Refreshed 31-page PDF SHA-256:
`7ffdb46d3893b4e0224847160a645e6e6fadab913baff816a3edacf83b4c4a90`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next susceptibility proposal, not yet applied. It identifies
the market-size comparison and variance across 50 starting markets at
fixed parameters. A read-only calculation reproduced all 230 refined
susceptibility values from the archived per-run means.


**Susceptibility definition applied, 18 September:** applied the accepted
market-size scope, final-500-step mean, variance across 50 starting
markets at fixed parameters, and fixed-size interpretation. Preserved the
equation, its label, the existing citations, and paragraph structure.
Independent saved-state review found no substantive issue. No code or
numerical results changed. Normal and isolated archive builds passed with
identical PDF text and clean final logs. Visually inspected changed page 7
and neighbors 6 and 8. Refreshed 31-page PDF SHA-256:
`3ceaf5d6bb45490b7447bb39ff4c5af840131390c0668edb6a0275ab9c3ddc84`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next midpoint/width proposal, not yet applied. Checked all
three interpolated crossings and response widths against the archived
refined results for 15 curves. The Wilson-interval and interquartile-range
sentences remain a subsequent review unit.

**Interpolation wording feedback, 19 September:** the author found the
generic fraction/probability notation unclear. Revised the pending opening
in the [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
to distinguish traders receiving the new rule from simulations forming a
Sell majority, name the 25%, 50%, and 75% levels, and explain the straight
line used for interpolation. The manuscript and PDF remain unchanged;
the revised proposal is still under discussion.

**Interpolated midpoint and width applied, 19 September:** applied the
accepted opening that separates traders assigned the rule from runs
forming a majority, names the three probability levels, and explains
straight-line interpolation. Applied the associated midpoint, width,
first-crossing, and local-decrease sentences within the existing paragraph.
Independent saved-state review found no substantive issue against the
refined analysis. No numerical results or code changed. Normal and
isolated archive builds passed with identical PDF text and clean final
logs. Visually inspected changed pages 7–12 and neighbors 6 and 13.
Refreshed 31-page PDF SHA-256:
`ea918ef3c9e1df296e0ce10e255efd30b7abc2e074158bd42fac5052c4941c92`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next Wilson/interquartile proposal, not yet applied. It
distinguishes uncertainty in individual probability estimates from
variation between runs, without implying quartiles accompany every median.

**Wilson and interquartile wording applied, 19 September:** applied the
accepted distinction between uncertainty in majority probabilities and
variation between run outcomes, with interquartile bands scoped to where
they are shown. Preserved the Wilson citation and paragraph structure.
Independent saved-state review found no substantive issue. No numerical
results or code changed. Normal and isolated archive builds passed with
identical PDF text and clean final logs. Visually inspected changed
pages 7–12 and neighbors 6 and 13. Refreshed 31-page PDF SHA-256:
`16081331f335b8628e31276ffdb214280ac45225f1b80b6f18c894d7ca035f80`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next drawdown proposal, not yet applied. It brings the
existing price-window definition alongside the metric and preserves
descriptive use of price crash without a classification threshold.

**Drawdown opening applied, 19 September:** applied the accepted distinction
between Sell intentions and price declines, running-peak drawdown, and
descriptive use of price crash. Moved the existing quote-window definition
next to the metric and removed its duplicate later clause, retaining the
majority-detection sentence. Independent saved-state review found no
substantive issue. No code or numerical results changed. Normal and
isolated archive builds passed with identical PDF text and clean final
logs. Visually inspected changed pages 7–12 and neighbors 6 and 13.
Refreshed 31-page PDF SHA-256:
`75b1271152f686faa3873c5d9157d5a84ca3e0b1a7c1da13d13eb6da866b2a19`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next unfilled-order proposal, not yet applied. It includes
fees in buyer affordability, distinguishes eligible unfilled orders from
trader-resource exclusions, and scopes the pooled rejection fraction to
where it is reported, including its zero-eligible convention.

**Unfilled-order wording revised, 19 September:** at the author's request,
revised the pending proposal to define eligibility for Buy and Sell orders
before introducing suppression and rejection. The calculation and scope
are unchanged. The updated proposal remains under discussion in the
[market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md);
the manuscript and PDF have not been changed in this discussion turn.

**Unfilled-order wording applied, 19 September:** applied the accepted
eligibility-first passage, including fee-inclusive Buy affordability,
the one-share Sell requirement, suppression versus rejection, each run's
pooled rejection fraction where reported, and its zero-eligible convention.
Independent saved-state technical review found no substantive issue.
Normal and isolated archive builds passed with identical PDF text and
clean final logs. Visually inspected changed pages 7–12 and neighbors
6 and 13. Generated fee inputs and archived numerical records are unchanged.
Refreshed 31-page PDF SHA-256:
`4b8c022ff4879644872a604530cf40e11807f2d78bb31735d5d566a82c43ccd8`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next proposal, not yet applied: replace the repeated majority
timing, broad financial-summary claim, and closing interpretation with a
single sentence specifying medians for drawdown and rejection fractions.

**Financial-summary sentence applied, 19 September:** replaced the repeated
onset and trade-outcome explanations and broad summary claim with the
accepted sentence specifying median drawdown and rejection fractions
across starting markets under the same conditions. Independent saved-state
review found no substantive issue or lost measurement-window detail.
Normal and isolated archive builds passed with identical extracted PDF
text and clean final logs. Visually inspected changed pages 7–12 and
neighbors 6 and 13. Generated fee inputs and archived numerical records
remain unchanged. Refreshed 31-page PDF SHA-256:
`0493f3e8328ced52e2a0771787c40b2dd2f6a2e5e3d171e4b934c71011c89bc8`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next proposal, not yet applied: explain adaptive fraction
selection for market-size curves, its probability-based target, midpoint
selection, ten-round limit, and reuse of starting markets. Read-only
reconstruction matched both archived refinement manifests exactly and
confirmed that all 15 curves met the criterion within two rounds.

**Adaptive fraction-selection passage applied, 19 September:** applied the
accepted market-size scope, strict probability target, directional midpoint
selection, ten-round limit, reuse of starting markets, and reference to
the actual qualifying counts in Table S3. Independent saved-state review
found no substantive issue. Normal and isolated archive builds passed
with identical extracted PDF text and clean final logs. Visually inspected
changed pages 7–12 and neighbors 6 and 13. Generated fee inputs and archived
numerical records remain unchanged. Refreshed 31-page PDF SHA-256:
`d8734fc0b589dccf84a14a8a01afdcfb8310082858cf5d67f9987fd0ca10ce6e`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next proposal, not yet applied: describe bootstrap resampling
of starting markets, keeping their outcomes together across fractions,
recalculating crossings and the susceptibility maximum, and constructing
95% percentile intervals. All archived market-size bootstrap crossing
validity fractions are one; no samples were excluded there.

**Bootstrap wording clarified, 19 September:** the author questioned what
it meant to keep outcomes together across fractions. Revised the pending
proposal to state that each bootstrap sample uses the same selection of
starting markets at every tested fraction. Repeated selections count
equally at all fractions. Only the review proposal changed; manuscript
source and PDF remain at the last accepted fraction-selection revision.

**Clarified bootstrap passage applied, 19 September:** applied the accepted
description of 2,000 samples of 50 starting markets with replacement,
using the same market selection at every fraction, recalculating crossings,
width, and susceptibility maxima, and defining percentile confidence limits.
Independent saved-state review found no substantive issue. Normal and
isolated archive builds passed with identical extracted PDF text and clean
final logs. Visually inspected changed pages 7–12 and neighbors 6 and 13.
Generated fee inputs and archived numerical records remain unchanged.
Refreshed 31-page PDF SHA-256:
`8de74b6b502b390658c42482e34c9544c41e05f9972f29288629288eeabfc9ab`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next proposal, not yet applied: explain the logistic comparison's
purpose, retain its equation, identify its centering and scaling constants,
and clarify fitting, bootstrap refitting, and standard errors for midpoint
and width. The displayed parameterization reproduces all 15 archived
logistic midpoint and width estimates to floating-point precision.

**Logistic wording clarified, 21 September:** revised the pending proposal
to name the Sell-majority probability curve when referring to its midpoint
and width, use "modeled" for the probability model, and specify "probability
curve" for position and bootstrap refitting. The definitions remain the
50% crossing and the difference between the 75% and 25% crossings in the
fraction assigned the new rule. Only the review proposal changed;
manuscript source and PDF remain at the accepted bootstrap revision.

**Logistic comparison applied, 21 September:** applied the accepted
probability-curve wording, explicit comparison with linear interpolation,
parameter roles, fixed centering and scaling, binomial fitting, refits of
the same bootstrap samples, and standard errors for the probability
curve's midpoint and width. The displayed equation is unchanged.
Independent saved-state review found no substantive issue. Normal and
isolated archive builds passed with identical extracted PDF text and
clean final logs. Visually inspected changed pages 7–12 and neighbors
6 and 13. Generated fee inputs and archived numerical records remain
unchanged. Refreshed 31-page PDF SHA-256:
`b6b4e4e1fd1fb27b48d09b76ed0bac3be533f8a61a98b91a65336789653b0dbd`.
The [market-outcomes review](docs/reviews/2026-09-18-methods-outcomes.md)
contains the next proposal, not yet applied: explain sampling uncertainty
with the tested fractions and observation period fixed, distinguish the
choice of additional fractions and straight-line approximation error,
and avoid calling changes over longer observation periods errors.

**Full cold read and fixes, 29 September:** twelve fresh readers over the
whole manuscript (reports in `output/reviews/full-cold-read-20260929/`).
Added the following experiments (Methods subsection, two Results
paragraphs, Discussion paragraph, Table S following from
`code/repaired/WriteFollowingTable.py`, abstract and Conclusion sentences)
from the reserve-engine confirmation and pilot only; removed the
round-trip, nucleation, band-test, and long-control caveats; deleted
Discussion P4 (two ideas moved to P2 and P6); fixed the fee closing
sentence and the abstract crossover; unified terms in prose, captions, and
generators. Codex check: no numeric errors; five wording fixes adopted,
two declined; re-check all resolved. Markup:
`output/review/2026-09-29-cold-read-fixes/markup.pdf`.

**Revision timing, interior technical traders, and price-feedback claims, 2 October:** author decisions after the simulated peer review: keep the synchronous model as the main model and report revision probability $r$ as robustness; keep "a Sell majority formed when no decision responded to price", drop the general "price feedback had a small effect" claim (now scoped to edge placement), and remove the by-construction "cash, shares, and fees altered decisions only through technical traders" from the abstract, Results closings, Discussion, and Conclusion (it stays in Methods). Added the Methods subsection, one Results paragraph, Discussion sentences, Tables S15 and S16 and Appendix A.7 (`code/variants/WritePaper.py`, study `output/rebuilt/lazy-revision-interior-technical-v1/`), the Huberman and Glance (1993) citation (Crossref-verified), and the Fig. 4 caption sentence on checkerboard halves; corrected the Packard and Wolfram rule-class sentence (outer totalistic, ignoring the cell's own state). Codex check: no numeric errors; nine wording fixes adopted, none declined; re-check all resolved. Markup: `output/review/2026-10-02-update-timing-placement/markup.pdf`. The arXiv archive is NOT rebuilt (author-gated).
**Supplementary Fig. S1, 2 October:** at the author's request, added the revision-probability counterpart of Fig. 4 (r = 0.9, active technical traders, h = 100, 3,000 steps). Fractions matched to Fig. 4 by majority probability and markets chosen from campaign summaries by the Fig. 4 rule (`code/variants/Figs-Variants-MarketPanels.jl`, selection in the study's `FigS1-Selection.csv`, each rerun checked against its archived onset and final-grid hash); caption from `code/variants/WritePaper.py`; one Results sentence and one Fig. 4 caption clause cite it. Fig. 4 is now drawn at 0.85 linewidth to keep it on one page. Codex: three items adopted (tie-rounding documented, claims limited to displayed markets, symbol naming); re-check all resolved.
**Supplementary tables moved into the supplement, 2 October:** at the author's request ("All the suppl tables should be in the supplement"), the end matter is now references, main Figures 1 to 6, Appendix A (supplementary methods and validation), and Appendix B "Supplementary tables and figure" (Tables S1 to S16, then Fig. S1). The `\section*{Tables}` heading was removed from the `tables.tex` template in `code/rebuild/WriteManuscriptTables.py`; the generator was verified on a scratch copy of the rebuild study to reproduce the root table files exactly before and after the edit, and the frozen staged copy was not touched. Build clean, 41 pages.


**Public intentions and hypothetical inventory information, 7 October:** author-approved
four-branch observation experiment completed in `output/rebuilt/inventory-visibility-v1/`:
2,800 initial trajectories plus 1,600 from the predefined extension, over 50 fresh
starting markets. The baseline simulator was copied unchanged. At the primary
setting (f=0.20, h=100, technical traders held), the paired change in the switch
effect on late raw Sell fraction was -52.28 percentage points, 95% interval
[-54.46, -49.86]. Majority formation was 50/50 with original observations and
0/50 with inventory-conditioned signals; it reappeared at larger fractions.
Added the public-intention interpretation throughout the manuscript, generated
Results paragraph, Appendix A.8, Table S17, and Fig. S2. The counterfactual
specifies a behavioral response to inventory information and does not assert
that such information is available in actual markets. Independent read-only
review reproduced all 160 contrasts and intervals, checked all 4,400 run
summaries and 16 retained histories, and confirmed the final corrections.
Restricted checkerboard independence to original observations, explained the
holdings feedback with technical traders held, and clarified sender counts.
The 45-page build is clean. All pages were visually inspected, with detailed
inspection and final re-rendering of the new and corrected material. The
shareable PDF was refreshed. Added synchronized `paper-arxiv/abstract.txt`
(240 words, 1,624 characters) and an automatic arXiv limit check to the build;
the future source packager includes this file. The author-gated arXiv release
archive remains unchanged. No commit or push was made. Final PDF SHA-256:
`9894c11c19b214788b95c2aab0259415eb4932bd68c19e4e461054e77fbbdb91`.

**Inventory result condensed, 7 October:** at the author's request, reduced the
main Results paragraph to one sentence: reading an empty seller's intention as
Hold reduced mean maximum drawdown from 24.36% to 3.23%, scoped to held
technical traders, dealer depth h=100, and switched fraction f=0.20, citing
Fig. S2C and Table S17. Moved the detailed findings to Appendix A.8 through
the reporting generator. Independent saved-state review found no substantive
issue; the 45-page build is clean, and rendered pages 12–17 and 31–34 were
inspected. Refreshed the shareable PDF and synchronized abstract.txt. Frozen
computation and the release archive remain unchanged. Current PDF SHA-256:
`648b67f0ba5da76f9ea2008f6f3f2b8f91125ff417de8425e698b551964418f2`.
