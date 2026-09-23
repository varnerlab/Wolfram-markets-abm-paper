# Scientific Publication Style and Interactive Review

> **Superseded on voice, 23 September 2026.** [VOICE_GUIDE.md](VOICE_GUIDE.md)
> now governs sentences, paragraphs, and review workflow. In particular, the
> rules below that split sentences ("one main assertion", "periods between
> independent assertions", the blanket semicolon ban) were assistant
> defaults, not author requests, and they produced the choppiness he
> objected to. Review is now by whole section, not by passage.

Working guide, 16 September 2026. Use this guide with `paper-section-review`
for Jeffrey Varner's scientific manuscripts and their supporting material.
The author's stated preferences are simple, direct language, few decorative
adjectives, sentences without chains of comma- or semicolon-linked clauses,
and long, well-developed paragraphs. These preferences govern the review.
The operating defaults below can be refined through the interactive review.
The author identified lack of voice and formulaic or choppy writing as the
problems with earlier polish rounds. Calibration should address those
problems while preserving the depth of technical review.

Read [HOUSE_STYLE.md](HOUSE_STYLE.md) for this paper's terminology, structure,
evidence, generators, and build requirements. Current author instructions
take precedence. This guide governs voice and interactive review; the house
guide supplies project-specific requirements. Keep model-specific decisions
out of reusable style rules.

## Voice: simple sentences, developed paragraphs

Write as a scientist explaining a question, a calculation, and its meaning
to another scientist. Prefer familiar words, concrete subjects, and direct
verbs. Use "we compared" when the authors made a comparison. Name the
measured quantity when reporting its behavior. Passive voice is useful when
the object or procedure matters more than the actor; do not rewrite every
sentence into the same grammatical form.

- Prefer "use," "change," "measure," and "compare" to abstract phrases
  such as "utilize," "modulate," or "conduct an assessment of." Preserve
  technical terms when they make a distinction the reader needs.
- Remove praise and unmeasured emphasis: "remarkable," "powerful,"
  "crucial," "dramatic," and similar words usually add no scientific
  content. Keep descriptive modifiers that identify a condition or a
  tested property. "Finite reserves" and "paired comparison" carry meaning.
- Give each sentence one main assertion. Split a sentence when its subject
  changes, it accumulates independent findings, or the reader must hold
  several qualifications before reaching the verb. Keep qualifications
  needed to make the assertion true.
- Use periods between independent assertions. Use commas for their
  grammatical purpose. Do not join clauses with semicolons merely to make
  the prose flow. Preserve punctuation needed in mathematics, code, and
  lists containing internal commas.
- Avoid narrative em/en dashes, stacked parenthetical explanations, and
  strings of noun modifiers. Hyphens in established terms, numeric ranges,
  panel ranges, and minus signs serve different purposes.
- Do not add "importantly," "interestingly," "notably," or generic
  transition sentences. State the finding or the actual connection.

Long paragraphs should contain a developed argument, not long sentences.
Open with the scientific point or question. Supply the definitions, design,
evidence, and reasoning the reader needs. Explain the supported consequence
when it is not already clear. These are paragraph functions, not mandatory
sentence slots. A paragraph can develop its purpose without announcing
"To investigate ..." and need not end with "These results demonstrate ...".

Keep related sentences together. Split at a change in scientific purpose,
not after an arbitrary number of sentences. Develop thin paragraphs by
restoring missing explanation or evidence, or join them to the argument they
support. Do not pad them with repeated conclusions. A longer paragraph may
also need material removed when it repeats a point or inventories numbers
better read in a table.

Preserve the argument across the whole section during an interactive review.
A passage discussed separately is a review unit, not automatically a new
paragraph. Integrate literature by the scientific connection being explained,
and develop model descriptions within that argument. Do not accumulate
standalone summaries of papers, mechanisms, and controls. When combining
passages, remove repeated openings and conclusions and rewrite the transitions.
Deleting blank lines alone does not make a connected argument. Respect an
explicit paragraph limit; this paper's Introduction has a maximum of four.

Sentence lengths, paragraph lengths, and comma counts are diagnostic clues,
not targets or acceptance tests. Never join clear sentences to meet a
minimum median length. Read adjacent sentences for continuity: each should
use or advance something the reader has just learned. Repeat a precise term
when "this behavior" or "these findings" would have an unclear antecedent.

Name the model, participant, quantity, or price directly in explanations.
The author specifically rejected "this market" and "that price": write
"the cellular automaton market" and "the dealer's quoted price" when those
are the intended referents. Distinguish an intended action from an action
actually carried out. Define terms such as "completed trade" through the
observable exchange, and explain a ratio by naming the numerator,
denominator, and consequence of each changing.

In the Introduction, prefer a name that conveys the scientific setting.
For the current paper, the author chose "synthetic market" rather than
"world" or "grid" for the simulated environment. Describe the arrangement
of traders in plain language and retain mathematical geometry where it is
needed to specify the method. This is a naming preference, not a change in
the model or its interaction structure.

## Scientific argument and evidence

Review technical correctness before polishing a claim. Distinguish what was
assumed, calculated, observed, and inferred. Preserve the difference between
a model choice and a mathematical requirement, a selected example and an
ensemble result, and an association and a supported causal explanation.
Place material qualifications beside the claims they limit. Avoid repeating
the same disclaimer at the end of every paragraph.

For each substantive claim in the current review unit:

- Trace a numerical result to the current data or calculation. Check the
  condition, units, denominator, sample size, observation window, rounding,
  and definition of uncertainty. Check paired effects using paired data.
- Read the cited figure or table and confirm that it supports the stated
  result. A citation to a related experiment is not evidence for a different
  quantity. Keep the reference near the claim.
- Compare model descriptions, equations, algorithms, and the executed code.
  Check update order, initialization, indexing, boundary conditions,
  conservation, feasibility, and stopping rules when they affect the claim.
- Verify claims about prior work against the source, preferably the primary
  publication. A verified DOI confirms an entry's identity, not the
  manuscript's interpretation of that work.
- Give broad literature coverage through suitable reviews, then develop
  primary studies selected for their connection to the paper's question.
  Make the selection principle clear. Do not let a few examples stand for
  an entire field or use an omitted study as evidence of a research gap.
  Check the closest related work before making a claim of novelty.
- Mark missing support as **unverified** and state what would resolve it.
  Do not call an unchecked claim false or treat agreement among manuscript
  sections as independent verification.

Do not simplify prose by removing a necessary condition or increasing the
strength of a conclusion. An unresolved scientific discrepancy needs a
specific finding and correction path. It must not be hidden by fluent prose.
Use existing checks or targeted calculations when sufficient. A prose review
does not itself authorize a new simulation campaign or a change to the model.

## Section purpose and narrative format

Keep the research narrative in connected paragraphs. Use Methods subsections
for navigation where useful. Do not import notebook learning objectives,
callout boxes, task headings, or a heading for every paragraph. Lists remain
appropriate for algorithm steps and required reporting material.

Introduce a model through its participants, their interactions, and its
constraints before describing experimental operations or controls. In an
Introduction, explain what differs between the compared populations before
describing a change to a lookup table or another implementation detail.

Use past tense throughout the closing "In this study," paragraph when
describing a completed study. Name the populations or quantities being
varied. Explain a control by identifying the connection it removed and the
processes that continued. When comparing simulations with a common history,
make clear when their states matched and when their behavior could diverge.
Place citations beside the method or prior claim they support, not after
an unrelated model component.

When closing the study overview, explain how the study addressed its aim.
The author requested a concrete connection between the comparisons made and
the contribution supported, rather than ending with the broader aim alone.
Keep that connection qualitative and within the tested model and conditions.

| Material | What the review should establish |
|---|---|
| Title and abstract | The question, approach, supported finding, and implication are clear at the paper's scope. Preserve the chosen qualitative or quantitative abstract style. |
| Introduction | The motivation and literature lead to a specific question and the study's approach. Explain differences among earlier models accurately. The closing "In this study," paragraph follows this paper's policy on reporting results. |
| Methods and theory | A reader can identify the objects, assumptions, operations, comparisons, measurements, and analysis. Explain why each construction is needed. |
| Results | The reader understands what was compared, what happened, the evidence, and the supported interpretation. Put detailed values into the developing argument. Report experimental actions and findings in past tense. |
| Discussion | Explain what the findings mean, how they relate to prior work, and what remains unresolved. Develop limitations in context. Avoid repeating the Results as a second inventory. |
| Conclusion | State the supported consequence. Introduce no new evidence, stronger claim, or promise of future work. |

A Results opening may give the purpose, comparison, or finding first. Choose
the order that makes the paragraph easiest to follow. Do not require action,
finding, and whole-figure citation in one sentence. Use a panel reference
when that panel supplies the evidence. Figure and table references normally
remain parenthetical; the scientific subject should carry the finding.

Avoid section self-references such as "as described in Methods." Name the
method or quantity instead. Keep useful equation, figure, table, algorithm,
and appendix references. Define abbreviations at first use in each part that
must stand alone, and avoid sentence-initial acronyms.

## Mathematics and algorithms

Define symbols by meaning before their first displayed use. Include units,
indices, domains, and constraints when relevant. Membership in a set alone
does not explain what a symbol represents. Introduce a display with a
complete grammatical lead-in ending in a colon. Punctuate the display as
part of the surrounding prose. Explain how consecutive equations follow
from one another. Do not use a trailing "where" clause as a substitute for
introducing the notation.

Check dimensions, signs, normalizations, denominators, limiting cases, and
the assumptions of a derivation. Use the same symbol for the same quantity
across text, plots, tables, and code descriptions. Preserve a distinction
between a quantity's mathematical meaning and its storage or index in code.

Pseudocode must define inputs and outputs and describe the operations that
affect the result. Check old versus updated state, operation order, branches,
ties, termination, and restricted modes against the implementation. Captions
and comments should explain the algorithm in the same direct voice as the
paper. Low-level implementation details belong only where they affect its
meaning or reproducibility.

## Figures, tables, supplements, and publication correspondence

Inspect the actual visual alongside its source data and caption. Check panel
letters, axes, units, transformations, ranges, color meanings, sample sizes,
uncertainty, observation windows, and selection of examples. A caption
should identify the comparison and give enough context to interpret it
independently. Use full sentences where they explain the graphic and compact
labels where they identify a panel. Do not turn a caption into another
Discussion paragraph.

Tables should name quantities and units, distinguish missing observations
from zeros, define conditional statistics, and identify paired differences.
Review their headers and footnotes as prose. Check every changed figure and
table at the size used in the manuscript for clipping, unreadable text,
ambiguous legends, awkward wrapping, and page breaks.

Apply the same evidence and language standards to supplementary methods,
validation, data and code availability statements, and algorithm descriptions.
Keep computational provenance precise without filling the main narrative
with internal filenames or the history of drafting and repairs. Explain the
current study; retain necessary change history in the appropriate record.

For a reviewer response, answer the scientific point directly, explain the
evidence or correction, and identify its manuscript location. Respectfully
explain a disagreement with reasons. Do not claim that an analysis was run,
a concern resolved, or a manuscript changed unless that work is complete.
Cover letters should state the contribution and fit without promotional
adjectives. Never invent declarations, approvals, funding, or author roles.

## Interactive review and calibration

Use one section as the working unit. For a long Methods or Results section,
use one subsection or coherent group of paragraphs while reading the full
section for context. Review the linked equations, figures, captions, tables,
algorithms, and evidence with that unit. Track coverage so detached floats
and supplementary material are not missed.

For each unit, explain its intended contribution, identify the substantive
issues, and present proposed prose as a continuous passage the author can
read for voice. Distinguish verified technical errors, interpretation or
evidence gaps, and editorial preferences. Give locations and reasons for
findings. Group minor wording changes instead of presenting a long lint
report. Preserve effective passages rather than rewriting for uniformity.

An interactive review requests author participation in the wording and
argument. Do the source reading and evidence checks before presenting the
passage. Keep the current unit open for discussion instead of revising every
section at once. Review alone does not authorize manuscript edits; explicit
instructions to revise or apply changes do. Carry that authorization forward
within its scope without repeatedly asking for the same permission.

Record accepted wording and the reason it works. Treat accepted passages as
calibration examples for later sections. Label any unaccepted illustration
as a proposal. Promote a correction into a reusable rule only when it
expresses a preference that applies beyond that passage. Do not imitate
every feature of an older exemplar when the author's current request differs.

When edits are authorized, change the authoritative source or generator.
Recheck affected claims and references, build the manuscript, and inspect
changed pages and neighboring pages affected by reflow. A successful compile
does not verify voice, evidence, or layout. A final manuscript pass checks
agreement across all sections and inspects the complete rendered document.
State what was checked and what remains open.
