# Response to the synthetic peer review

This revision treats the review as a request for new evidence and narrower
claims, not as evidence that its suggested mechanisms are correct. The original
review remains unchanged in `peer-review.md`. New experiments and analysis are
reproducible through `code/revision/README.md`.

## Main findings

- A one-time Sell pulse at the same selected sites produced no majority
  transitions in 50 seeds at f=0.15, 0.20, or 0.25 under either boundary.
  Persistent Rule 19286 activation produced 50/50 transitions at the two larger
  fractions. The state pulse and persistent rule intervention are therefore
  distinguishable in this design.
- All 18 single-entry neighbors were screened at three fractions, with 20 seeds
  under each boundary. At f=0.20, six rules produced 20/20 transitions under both
  boundaries; twelve produced none. The other effective entries are c=2, 3, 4,
  and 5. The chosen c=1 entry is neither unique nor representative of every edit.
- The fixed-band control removed the point-estimate advantage of h=0.1 over an
  unlimited dealer: the probability contrast changed from +0.38 to -0.02.
  Other non-monotone differences remain. This implicates post-switch adaptive
  normalization without proving a unique explanation of all dealer effects.
- The decade-wide impact sweep retained the drawdown ordering h=0.1 < 1 <
  infinity at each coefficient. Magnitudes changed substantially.
- Size-scaled horizons retained the endpoint midpoint ordering, but longer runs
  continued to shift the curves. The result remains explicitly finite-time.
- None of ten no-switch seeds under either boundary crossed during 100,000
  additional steps. This extends the observation window without proving
  asymptotic or global stability.

## Consolidated action items

Numbers below correspond to the review's 21-item consolidated list.

| Item | Resolution | Evidence or manuscript location |
|---|---|---|
| 1. Matched null interventions | Added matched Sell pulses and all alternative single-entry changes. | Supplementary pulse and rule tables; `ModelB-Revision-pulse.csv`, `-screen.csv`. |
| 2. Single-entry rule screen | All 18 neighbors, both boundaries, three fractions, 20 seeds. Exploratory uncertainty is explicit. | Supplementary rule table; `Compute-Controls.jl screen`. |
| 3. Adaptive grid refinement | Original 50 seeds retained; bisect intervals until every one of 15 curves has at least five sampled fractions with 0.05 < p < 0.95. | Figure 3, Table S3; `Compute-Refinement.jl`. |
| 4. Bootstrap intervals | 2,000 whole-seed resamples across fractions; intervals for f25/f50/f75, width, susceptibility peak and its sampled location. Reported precision reduced. | Methods, Table S3, refined scaling CSV. |
| 5. Non-monotone dealer effect | Quantified the 38-point difference and added paired frozen-deviation controls with uncertainty. Limited the mechanistic claim. | Main Results/Discussion and supplementary band table. |
| 6. Horizon scaling | Endpoint windows use 3000(L/64)^z, z=1,2, alongside the original horizon; L=64 adds 9,000 steps. | Supplementary horizon table and `ModelB-Revision-Horizons.csv`. |
| 7. Price-impact sweep | Three coefficients spanning a decade, three capacities, 50 seeds. | Supplementary impact table. |
| 8. Long no-switch controls | Ten original seeds per boundary extended 100,000 steps; bounded interpretation and Wilson limit supplied. | Baseline/long-horizon appendix paragraph. |
| 9. Logistic/probit fit | Monotone logistic sensitivity, bootstrap midpoint/width standard errors, dashed fitted curves versus raw points. | Figure 3A and supplementary fit table. |
| 10. Totalistic restriction | Added the scalar-score interpretation, an explicit conflated-neighborhood example, and a limitation to this rule class. No non-totalistic robustness claim. | Methods and Discussion. |
| 11. Causal framing | Recast the abstract, introduction, results, discussion, and conclusion around response versus activated fraction and execution stages. Deterministic attribution is a protocol property. | Main text throughout. |
| 12. Dealer comparison | Removed the unsupported comparison of effect sizes across unlike outcomes; stated 38 percentage points / factor 2.4 near the window. | Results and Discussion. |
| 13. Baseline characterization | Added two pre-switch Sell windows, return standard deviation/quantiles, zero-return frequency, and stationarity/calibration limits. | Baseline appendix paragraph. |
| 14. Majority criterion sensitivity | Recomputed first passage at 0.4, 0.5, 0.6 over the horizon grid. Qualitative ordering survives; numerical midpoints differ. | Supplementary horizon table. |
| 15. Behavioral interpretation | Added minimal aggregate selling-pressure interpretation and explained what it discards. | CA Methods subsection. |
| 16. Title scope | Revised to “Local rule activation and dealer capacity in a cellular automaton market.” | Title, metadata. |
| 17. Missing Table S2 source | Added explicit ignore exceptions for the full paired-switch summary, trajectories, and exemplar, with regeneration command. | `.gitignore`, `code/data/README.md`. |
| 18. h=10 display | Added a dashed Figure 2A overlay and explicit h=10 level in panels B–D. | Figure 2 and plotting script. |
| 19. Interior-point counts | Added n_int to Table S3. Susceptibility peak location is explicitly a sampled grid value. | Table S3 and supplementary fit table. |
| 20. Advance selection | Did not invent preregistration or a power calculation. Documented fixed campaign constants, existing pilot/full modes, and lack of a prospective record. | Appendix campaign inventory. |
| 21. Single-seed illustration | Explicitly labeled the Figure 5 trajectory as an illustration and pointed to ensemble evidence. | Figure 5 caption. |

## Limits and questions not converted into unsupported claims

- A composition-based robustness experiment was not performed. Merely rewriting
  a totalistic lookup in terms of state counts is algebraically equivalent and
  would not test the restriction; choosing a genuinely different response
  requires additional behavioral assumptions. The manuscript defends the
  abstraction and states its limitation, satisfying item 10's defend-or-test
  alternative without implying a completed non-totalistic experiment.
- No basin boundary or complete attractor classification was established. Long
  controls constrain observed trajectories, not all reachable states.
- No final-window stationarity, infinite-time transition, or susceptibility
  exponent is claimed. Horizon dependence remains visible in the new data.
- No fixed-absolute-dealer-capacity size series was run. The manuscript states
  that absolute capacity grows with trader count in the reported size series.
- The frozen deviation is path-specific. It removes post-switch adaptation
  while preserving exact prehistory; it does not impose one common width across
  capacities. The moving center and execution dynamics remain active.
- Bootstrap intervals condition on the adaptively selected grid. They do not
  eliminate interpolation or selection bias. The logistic curve is a shape
  sensitivity check, not a validated microscopic probability law.
- The calm baseline is characterized quantitatively, not fitted to an existing
  market model. Neither return calibration nor realistic crash forecasting is
  claimed.

## Reproduction and submission preparation

The deposited revision seed summaries, generated LaTeX snippets, and plotting
scripts replace the prior unsupported finite-size precision. Original production
files remain for provenance. `code/revision/Check-Revision-Data.py` checks
campaign completeness, threshold nesting, seed counts, bootstrap coverage, and
agreement with 1,800 archived held-boundary outcomes.

`paper-arxiv/package_arxiv.py` assembles only reachable source files, figures,
local styles, and bibliography into `output/arxiv/`. It follows the file-content
requirements in the [arXiv TeX submission documentation](https://info.arxiv.org/help/submit_tex.html).
The archive is intended for author review and upload; local compilation is not
a substitute for inspecting arXiv's generated preview.

## Validation completed

- 313 existing Model B checks and 61 revision intervention checks passed.
- All 15 refined curves met the five-interior-point criterion after 2,400
  additional seed-level runs; every bootstrap replicate bracketed its crossings.
- Revision data checks passed, including agreement with 1,800 archived outcomes.
- The 28-page manuscript compiled without LaTeX warnings, unresolved references,
  or overfull boxes; all pages and revised figures were visually inspected.
- The house-style pass checked developed narrative paragraphs, the required
  closing Introduction paragraph, opening evidence citations in all six Results
  paragraphs, complete equation introductions, and coverage of all figure,
  table, and algorithm references. The pulse table was generated from the
  existing summaries; the previously reported numerical tables were preserved.
- The author-voice pass revised the abstract, Methods, Results, Discussion,
  Conclusion, and supplementary narrative using the supplied reference papers.
  Developed paragraphs and opening Results citations were retained. Equations,
  algorithms, numerical tables, and literature citations were unchanged by this pass.
- The Results were consolidated from twelve to six developed paragraphs, reducing
  narrative length by about half. Control details remain in the supplement; all
  figure and table citations were retained.
- All ten tables now follow the references, followed by the six figures and
  then supplementary methods and validation. Numbering, captions, and narrative
  citations were preserved; captions remain with their tables or figures.
- The 23-file source archive compiled in an isolated temporary directory and
  reproduced the manuscript's extracted PDF text exactly. Its checksum and
  validation result are in `output/arxiv/validation.json`.

To rebuild and verify the upload archive:

```bash
make -C paper-arxiv
python3 paper-arxiv/package_arxiv.py --verify
```

The narrative pass connected investor decision rules, market instability, and
price crashes throughout the manuscript. Instability describes the shift toward
a Sell majority after the rule change; a price crash describes a large simulated
price decline measured through drawdown. The text distinguishes these outcomes
without introducing a binary crash threshold. Developed paragraphs, numerical
evidence, and model definitions were preserved. Independent reviews checked that
the wording did not imply permanent Sell states, learning, or rule adoption
outside the selected traders, and that crash language referred to price declines;
identified wording issues were corrected and rechecked.


The plain-English pass revised the abstract, Introduction, Methods, Results,
Discussion, Conclusion, captions, and supplementary prose. It names each
comparison directly and explains how selected traders at the edge use prices
to make decisions. Computational shorthand was replaced with descriptions of
trader decisions, available cash and shares, and completed trades. Formal terms
needed for equations and figure labels remain defined in the Methods. The pass
retained four Introduction paragraphs and six developed Results paragraphs.
Independent reviews checked the meaning of the revised language and confirmed
that the equations, algorithms, numerical evidence, and literature citations
were preserved; the identified ambiguities were resolved and rechecked.
