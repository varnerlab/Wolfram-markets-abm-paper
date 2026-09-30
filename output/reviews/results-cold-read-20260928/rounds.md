# Results cold read

| Round | Context / audited paragraphs | Severity 3 | Severity 2 | Severity 1 |
|---|---|---:|---:|---:|
| 1 | Full preceding context; P1, P2, P4, P5, P6 | 0 | 4 | 1 |

One reader per round; five unique first-round flags, no overlapping-reader counts. P3 is read-only context from finite-size-results.tex.

## Round 1 triage

- P1.S12, severity 2: in-place scope repair. Persistent response changes and one-time Sell intentions differ in intervention type as well as duration; state the tested contrast without attributing it to duration alone. Verified against pulse protocol in revision-controls.tex and WriteResults.py.
- P4.S5, severity 2: in-place referent repair. Attach the three onset times to their fractions, confirmed against market-panel-horizons-table.tex and saved trajectory summary.
- P4.S11, severity 2: in-place referent repair. Identify drawdowns as belonging to switched markets. Same table and saved summary verify the group.
- P6.S11, severity 1: reader marked OPTIONAL DETAIL; cheap in-place repair warranted because the original sentence names a relationship without saying what it means. State that few dealer rejections do not imply small drawdown; saved balance-sheet grouped data support this (at h=100, rejection fractions remain below 10^-6 while median drawdown reaches about 0.79). No new numeric claim added.
- P6.S13, severity 2: in-place scope repair. Describe financial outcomes in switched markets rather than an effect attributable to switching. Methods explicitly says these resource comparisons lack separate no-switch controls.

## Additional editor repairs

Named the active/held comparison, clarified the paired drawdown baseline and the subtraction defining the band-width contrast, and distinguished orders backed by resources from all desired orders. Replaced opaque wording about the held update with its implication for decisions. Cut repetition to fund the onset/fraction mapping. No claims moved between paragraphs; all original paragraph roles and opening/closing purposes retained. No PURPOSE removals or expanded Methods detail.

## Scope and provenance

The explicit cold-read contract restricts source edits to results.tex. Its generating template code/rebuild/WriteResults.py was read for evidence but not edited, and frozen study sources were not changed. Regenerating Results from that template would overwrite this prose revision. Normal make compiles TeX and does not regenerate it.

## Round 2

| Context / audited paragraphs | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full preceding context; P1, P2, P4, P5, P6 | 0 | 4 | 1 |

Five unique flags in this round. P1's scope flag overlaps the topic of R1 P1 but identifies a newly ambiguous universal reading.

- P1.S13, severity 2: in-place repair; add "some" to avoid implying every lasting switch produced majorities.
- P2.S6, severity 1: cut redundant bookkeeping sentence; the opening already establishes continued trading and price movement.
- P4.S10, severity 2: in-place scope repair; introduce the frequency question specifically at f=0.150.
- P5.S13-S15, severity 2: in-place bridge repair; explicitly connect the band comparison to dealer depth's effect on majority probability near the crossover. Same paragraph and argument order retained.
- P5.S15, severity 2: in-place repair; identify starting markets as matched across dealer depths and band conditions. Verified in WriteManuscriptTables.py, which pivots by seed across depth/band combinations before bootstrapping. Additional requested procedure remains optional and is not added.

## Round 3

| Context / audited paragraphs | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full preceding context; P1, P2, P4, P5, P6 | 0 | 1 | 0 |

P5.S13-S17, PURPOSE, severity 2: substantive sequencing issue overlapping R2's P5 flag. The bridge alone did not resolve the interruption. Moved the complete band-width comparison earlier within P5, immediately after the setup of the dealer-depth comparison and before the financial outcomes. This keeps all claims in the same original paragraph and preserves its purpose, beginning, and conclusion. No new detail or changed claims.

## Round 4

| Context / audited paragraphs | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full preceding context; P1, P2, P4, P5, P6 | 0 | 1 | 1 |

- P5.S5-S8, ORDER, severity 2: overlapping sequencing flag. Revised P5's opening to state both its existing jobs: majority probability and price decline. This makes the opening promise match the retained experiments; its original distinction between majority formation and price severity remains explicit in the findings and conclusion.
- P5.S18, REFERENT, severity 1: named the three displayed depths (h=0.1, 1, 100), verified against Methods and Figure 5 caption, replacing "all three" after the paragraph's five positive depths and zero-depth limit. No new result.

## Round 5

| Context / audited paragraphs | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full preceding context; P1, P2, P4, P5, P6 | 0 | 0 | 2 |

- P5.S20, PURPOSE, severity 1: added "across the tested depths" to keep the concluding statement explicitly within the comparison's scope.
- P6.S1, INCONSISTENT, severity 1: replaced "dealer's reserves are only one side of each trade" with an opening about trades also depending on trader resources. The dealer does not need to be the counterparty to each order; opposing trader orders can match. This repairs the transition without changing the experiment or paragraph purpose.

## Round 6 and completion

| Round | Context | Severity 3 | Severity 2 | Severity 1 |
|---|---|---:|---:|---:|
| 1 | Full preceding context | 0 | 4 | 1 |
| 2 | Full preceding context | 0 | 4 | 1 |
| 3 | Full preceding context | 0 | 1 | 0 |
| 4 | Full preceding context | 0 | 1 | 1 |
| 5 | Full preceding context | 0 | 0 | 2 |
| 6 | Full preceding context | 0 | 0 | 0 |

Each round used a new independent reader. Final reader found no issues. No wording changes followed round 6. The final source retains five prose paragraphs and the standalone input directive (six guard blocks); words decreased from 1361 to 1331. All original numerical findings, references, citations, labels, and protected formatting were retained. Repeated fraction/depth values identify existing examples; no calculations changed.

Normal build passed with no LaTeX warnings, undefined references, or overfull/underfull boxes. Final PDF has 31 pages; Results target occupies pages 8-10. Affected pages and adjacent reflow were inspected visually. The marked-up PDF has 32 pages, with edits on pages 8-10. No explicit page limit applied. Invariants and local voice checks passed; manual paragraph identity and purpose checks passed. The original snapshot was retained unchanged.

Only results.tex was edited as manuscript source. Other workspace changes were concurrent or pre-existing and were preserved. No simulations, package installation, archive publication, or commits were performed. See validation.json and raw reader reports for evidence and remaining provenance limitation (unchanged generator).
