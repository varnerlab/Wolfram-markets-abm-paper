# Interactive Publication Review

Started 16 September 2026. This records the current review, not the historical
validation of the corrected simulation study.

- Voice and review guide: [PUBLICATION_STYLE.md](PUBLICATION_STYLE.md).
- Project requirements and evidence: [HOUSE_STYLE.md](HOUSE_STYLE.md).
- Active manuscript: [paper-arxiv/Paper_v1.tex](paper-arxiv/Paper_v1.tex).
- Current stage: paused at the author's request after accepting and applying
  the opening paragraph of “Three-state cellular automaton.” Resume with the
  next paragraph: rule-number encoding, Rules 19280 and 19286, assignment,
  and initialization. The Introduction remains an accepted “good draft.”
- Manuscript edits in this round: full Introduction consolidation, preserving
  the accepted opening and central model explanations. The resources argument
  now belongs to the model overview. The closing paragraph develops the
  comparisons. The closing paragraph now distinguishes mixture comparisons
  from market-size experiments, covers both sides of trade execution, and
  includes the following experiments. The accepted Methods opening is now
  applied. Its rule-number equation and definitions have been moved to the
  next paragraph; that paragraph's prose remains to review.
- First review unit selected by the author: Introduction. Title and abstract
  remain pending.

## Coverage

The Introduction is a **good draft**, accepted by the author for moving on,
with its changes applied and verified. The Methods opening is **accepted and
applied**; review is paused before the rule-definition and initialization
paragraph. Remaining Methods units and all other sections are **pending**. Integration
of crowding and following into later sections and final manuscript-wide
consistency review remain pending.
Locating a file does not count as reviewing
its science or rendered appearance. Mark a unit reviewed only after its
findings have been discussed; record editing and verification separately.

| Unit | Source and associated material |
|---|---|
| Title and abstract | `Paper_v1.tex`; check claims against the completed Results review again at the end |
| Introduction — good draft | `sections/introduction.tex`; accepted by the author for moving on; four paragraphs retained |
| Methods: three-state cellular automaton — partially reviewed | `sections/methods.tex`; opening accepted/applied; resume with rule encoding, two rules, assignment, and initialization |
| Methods: orders, resources, and trades | `sections/methods.tex`; reserve clearing and associated equations |
| Methods: technical traders and feedback | `sections/methods.tex`; price response and associated equations |
| Methods: paired experiments | `sections/methods.tex`; intervention, comparisons, and implementation |
| Methods: outcomes and analysis | `sections/methods.tex`; measurement, uncertainty, and example selection |
| Methods: crowding and following — pending integration | Corrected advice/copying pilot and shared-advice confirmation protocols; no manuscript method text yet |
| Results: rule change | `sections/results.tex`; Figure 1; Tables S1, S2, S5, S6 |
| Results: technical traders held | `sections/results.tex`; Figure 2A,B and linked comparisons |
| Results: size and observation window | `sections/finite-size-results.tex`; Figure 3; Tables S3, S9, S10 |
| Results: spatial histories | `sections/results.tex`; Figure 4; Table S11 |
| Results: dealer reserves | `sections/results.tex`; Figures 2C,D and 5; Tables S2, S7, S8 |
| Results: trader cash and shares | `sections/results.tex`; Figure 6; Table S4 |
| Results: crowding and following — pending integration | `output/repaired/following-reserve-v2-pilot/` and `output/repaired/transmission-confirmation-v1-full/`; generators, figures, tables, and Discussion coverage pending |
| Discussion | `sections/discussion.tex`; each developed interpretation and its supporting literature |
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
`sections/market-panel-horizons-table.tex`. Review each with the passage it
supports, then confirm coverage of all six figures and eleven tables.
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
