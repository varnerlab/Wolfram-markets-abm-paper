# Discussion revision after cold-read audit

User authorized cleanup passes after review-only round 1. The original snapshot is retained (six paragraphs, 1586 prose words); no restructuring or larger word allowance authorized. Only discussion.tex may change as manuscript source.

| Round | Context | Severity 3 | Severity 2 | Severity 1 |
|---|---|---:|---:|---:|
| 1 (audit) | Full preceding paper | 0 | 4 | 1 |
| 1 (audit) | Abstract/Introduction, skipping Methods/Results | 0 | 3 | 0 |

The original audit.md preserves raw severity and triage. Eight flags correspond to seven distinct concerns; the two readers overlap on the rules/intentions wording. An editor additionally identified the inaccurate common mechanism attributed to three microstructure sources.

## Repairs following round 1

- P1: Replace exclusion of selling from the price mechanism with dependence on resources as well. Name selling intentions as what spreads. Describe the tested pulse/switch contrast without claiming it isolates duration. Both interventions differ in what is changed as well as duration; existing protocol verifies this narrower wording.
- P2: Explicitly identify displayed markets as technical traders active. Retain held evidence as establishing that price feedback is unnecessary. Name selling, not rule responses, as what spreads. Verified against Figure 4 caption and Methods selection protocol.
- P4: Explain band width through thresholds around a moving reference; preserve Buy/Sell as intentions. Identify majority-probability differences across depths as the outcome. State that baseline widths can differ across depths and starting markets, and retain uncertainty in the paired comparison. Verified against Methods band rule and supplementary band-control protocol. Exact equations and bootstrap settings are unnecessary here.
- P4 literature: Replace the shared “assigned impact coefficient” attribution with dealer inference or order-book dynamics as distinct links from order flow to price. Preserve all three citation keys and citation style. Kyle's market makers price conditionally on order flow; Farmer et al. derive impact from order-book supply; Bouchaud et al. review order-book dynamics and price formation. Sources: https://people.stern.nyu.edu/lpederse/courses/LAP/papers/Information%2CFundamental/Kyle85.pdf ; https://arxiv.org/html/cond-mat/0309233 ; https://arxiv.org/abs/0809.0822 . This corrects the comparison's claim, not the model or results.
- P5: Distinguish individual benefit from the all-adopt versus all-fundamental comparison in Joshi et al. (source retained in audit.md). Clarify that rules do not evolve by learning while an externally assigned switch still occurs. Cut repeated pairing/setup detail to fund necessary definitions in P4; no idea moved between paragraphs.

All original paragraph roles are retained. P3 and P6 are unchanged. No optional procedural detail was imported; no sections, lists, or formatting changes were introduced.

## Round 2 reports and repairs

| Context | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full | 0 | 2 | 0 |
| Skim | 0 | 0 | 2 |

- Full P4.S6–S11 OVERLOAD (2) and skim P4.S11 PURPOSE (1) overlap. Compressed the band reminder and explicitly connected other price mechanisms to dependence of drawdown on model choice. Removed the misleading “therefore” connection from the literature sentence to the closing outcome definitions. All material remains in original P4.
- Full P5.S6 REFERENT (2): identify a game-theoretic analysis of traders choosing forecast-revision rates, rather than imply an observed dynamic convergence of the rate itself. Verified against the original paper, abstract/introduction and game-theoretic setup: https://people.reed.edu/~mab/publications/papers/joshi.ce.pdf . The equilibrium's lower collective earnings remain unchanged.
- Skim P2.S7 UNDEFINED (1): name the majority-probability rise and define its midpoint as the switched fraction at which half the markets reached a majority. Existing Methods defines the same f50; no new result introduced.
- Cut repetition in P1's screen description to fund clarity elsewhere; paragraph purpose and claims remain in place. No optional Methods detail added.

## Round 3 reports and repairs

| Context | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full | 0 | 1 | 0 |
| Skim | 0 | 1 | 1 |

- Full P5.S5 REFERENT (2): explicitly locate the technical-rule comparison within the Santa Fe model. Both cited Joshi studies use that model, verified in their primary papers. This identifies the literature example, without adding procedure or changing its result.
- Skim P1.S6 UNDEFINED (2): replace the opaque “screen placed” description with what was tested and the supported implication: alternative single-response changes showed that majority formation depended on which response changed. Results and supplementary rule screen verify that some changes at a given fraction produced majorities and others did not. Keep conclusions scoped to tested rules.
- Skim P4.S9 REFERENT (1): replace “additional dealer depths” with “varying dealer depth”; the funding/sensitivity coupling follows from the reserve mechanism for all depth comparisons, not merely a supplementary subset. The original supplementary-table citation remains. No optional detail added.

## Round 4 reports and repairs

| Context | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full | 0 | 0 | 1 |
| Skim | 0 | 2 | 0 |

- Skim R4-SKIM-1 REFERENT (2): identify lower average trader earnings at equilibrium versus a comparison in which all traders revise more slowly. Primary Joshi et al. 2002 paper supports this collective comparison; no claim of dynamic convergence is made.
- Skim R4-SKIM-2 OVERLOAD (2) and full P5.S6 PURPOSE (1) overlap. Put P5's organizing comparison (assigned rule switch versus learning/strategic choice, and interaction structure) at its opening. Condense minority-game setup and remove the histories-to-traders parameter, which was intelligible but dispensable to that comparison. Cut the repeated later statement of the assigned-intervention contrast. Tie the Santa Fe earnings examples to the consequence of strategic choices. All literature examples and citation keys remain in P5, and its scope/tradeoff conclusion remains. No paragraph split, merge, or cross-paragraph movement.

## Round 5 reports and repairs

| Context | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full | 0 | 1 | 0 |
| Skim | 0 | 2 | 0 |

- Full P5.S4–S6 PURPOSE (2) and skim P5.S4–S6 OVERLOAD (2) overlap. Both identify earnings details as OPTIONAL DETAIL for the model-mechanism comparison. Condensed those details to the strategic choices studied: incentives to adopt technical rules and choose forecast-revision rates. Retained both citation commands/keys. This removes a literature-outcome digression rather than any finding of the present study, and preserves the paragraph's comparative purpose.
- Skim P4.S6–S8 OVERLOAD (2): put the inconclusive finding first and compress the threshold explanation. Retain the moving reference price, continuing price feedback, and baseline width differences across depths/starting markets. Omit repeated setup phrasing, not the material scientific limitation. The report explicitly classified further mechanics as OPTIONAL DETAIL.

## Round 6 reports and repairs

| Context | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full | 0 | 1 | 0 |
| Skim | 0 | 1 | 1 |

- Full P3.S4 REREAD (2): clarify “later net sales” as continued net selling. The reader's guess that varying batch sizes invalidate monotonic execution prices is incorrect for consecutive net-selling batches. From the executed constant-product clearing equations, F_next/F_current = Q/(Q+s+r) < 1 for positive reserve Q and positive net sales s,r, regardless of their relative sizes. Algebra and exact-fraction spot checks verified this; no simulation or result changed. The phrase change makes the continued-selling scope explicit.
- Skim P4.S6–S7 OVERLOAD (2): do NOT adopt the guessed attribution to unmatched baseline widths. The stored paired bootstrap interval spans zero; uncertainty is the stated reason the contribution remains unresolved. Restore that explicit reason and briefly define threshold widths around the moving average. Retain continuing price feedback and baseline differences; do not claim those differences alone invalidate the matched comparison.
- Skim P6.S9 REREAD (1): replace the formal round-trip label with its existing cash-restoration property, preserving the limitations on realism and profits from other traders. Verified against Methods constant-product settlement and the abstract.
- Local voice check: replace “this market” with “the Santa Fe market.”

## Round 7 reports and repairs

| Context | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full | 0 | 0 | 0 |
| Skim | 0 | 1 | 0 |

- Skim P4.S7–S8 UNDEFINED (2): specify that threshold distances are fixed within each market. The existing supplementary protocol freezes each path at its pre-switch values while allowing widths to differ across depths and starting markets. This three-word qualification resolves the apparent contradiction between fixed widths and baseline width differences without importing procedural detail.

## Round 8 reports and triage

| Context | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full | 0 | 0 | 1 |
| Skim | 0 | 0 | 1 |

- Full P4.S6–S8 ORDER (1): retained the definition-before-comparison order. The reader correctly understood the purpose; moving the conclusion earlier would use adapting widths before the local definition. Earlier rounds tested that ordering and produced substantive skim-reader confusion. This remains a minor local ordering preference, not an unresolved substantive issue.
- Skim R8-SKIM-1 UNDEFINED (1): name f as the switched fraction, adding one word. This makes the sole mathematical symbol in Discussion recoverable without Methods or Results.

## Round 9 reports and repairs

| Context | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full | 0 | 0 | 0 |
| Skim | 0 | 1 | 0 |

- Skim P4.1 UNDEFINED (2): explicitly distinguish distances that normally adapt over time from the intervention fixing them at pre-switch values. Use “distances” consistently instead of introducing “widths” as an implied synonym; state the comparison's purpose before its preserved properties. This also addresses the prior round's ordering preference without using undefined terminology. The supplementary protocol verifies each statement. Retain the uncertainty of the paired contrast and the continuing moving-average response. No formula or procedural detail added.

## Round 10 reports and repairs

| Context | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full | 0 | 0 | 2 |
| Skim | 0 | 1 | 1 |

- Skim D2 OVERLOAD (2): compress the four-sentence threshold comparison to two sentences, retaining the adaptive baseline, each market's own pre-switch distances, continuing price feedback, the paired uncertainty, and the outcome across depths. Remove a separate restatement of between-market differences because “each market's pre-switch values” now carries this qualification. The material limitations on funding and price sensitivity remain.
- Skim D1 UNDEFINED (1): replace implementation-specific “neighbor sums” with neighboring intentions seen by adjacent interior traders. The numerical encoding is optional detail; the causal pathway is unchanged.
- Full P5.S12 PURPOSE (1): include the already discussed resources/execution question in the concluding scope sentence, so it does not appear to omit the financial contribution. No new result or claim introduced.
- Full P2.S6 UNDEFINED (1): retain the broad local-spread connection. The sentence already links intervention fraction to population spread; specifying a distinct mechanism shared by all four cited theories would overstate this analogy. Further source-specific comparison is optional to the stated resemblance.

## Round 11 final reports and disposition

| Context | Severity 3 | Severity 2 | Severity 1 |
|---|---:|---:|---:|
| Full | 0 | 0 | 1 |
| Skim | 0 | 0 | 1 |

Both independent readers understand the six paragraph arguments and identify no substantive confusion. Two minor notes remain explicitly recorded, not counted as resolved:

- Full D1 REFERENT (1): asks for a more specific name for the population-spread analogy in P2. Retain the broad connection for the reason recorded in round 10; the paragraph explicitly limits the analogy and does not identify the model with a single cited mechanism.
- Skim P6.S2 UNDEFINED (1): asks what is summed in “different neighbor configurations with the same sum.” The full paper defines the intention encoding, while the skim reader understands the information-loss limitation but must infer the summed quantity. This is a residual minor comprehension note, not a substantive problem. The requested task targeted remaining substantive issues; no claim that every minor note is resolved.

## Final verification

- Original snapshot retained: 6 paragraphs and 1586 prose words. Final: 6 paragraphs and 1491 prose words (95 fewer). No explicit page limit.
- Original paragraph identities, boundaries, order, purposes, heading and formatting preserved. Manual inventory: P1 interpretation/paired attribution; P2 neighbor spread/finite evidence; P3 execution/reserves; P4 feedback/limits of mechanistic attribution; P5 literature/contribution; P6 limitations. No cross-paragraph movement of claims.
- Structure guard passes. Invariant checker raises no flags. Independent multiplicity checks show identical citation commands/keys, references, mathematical expressions and numbers. No scientific results or numerical calculations changed.
- Local voice checker: no flags. Git whitespace check passes.
- Normal build `make -C paper-arxiv` succeeds. Final log contains no warnings, overfull boxes, underfull boxes or undefined references. Main PDF has 31 pages; Discussion remains on pages 10–12.
- Visually inspected affected pages of the rebuilt main PDF and the latexdiff markup. Paragraphs remain connected prose; no clipping, overlap or broken references. Markup changes appear on pages 10–12; the markup moves the Conclusion to page 13.
- Final manuscript source edit in this cleanup: discussion.tex only. Other pre-existing/concurrent repository changes left intact. Normal build artifacts refreshed. No simulations or release-package refresh performed.
