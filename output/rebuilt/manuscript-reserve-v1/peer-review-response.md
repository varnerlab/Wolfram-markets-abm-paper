# Response to the synthetic peer review: corrected model

The original review remains in `peer-review.md`. This response supersedes numerical claims from the standing-quote model. Every retained experiment was repeated under the corrected protocol.

The corrected model uses a finite constant-product dealer and uniform batch execution at a price supported by its reserves. It removes the isolated dealer round-trip cash extraction present in the old standing-quote/exponential-update combination. It also changes the price mechanism, so old/new differences cannot be attributed to settlement alone. Dealer depth now changes funding and price sensitivity together. The former independent impact-coefficient sweep is replaced by depths 40, 100, and 400. The h=0 matched-trade, fixed-price condition remains a separate control.

Order suppression and rejection statistics now use the post-switch window consistently. The old main-campaign order summaries included baseline steps; this measurement change is also recorded in the protocol.

The rerun uses the retained study's original seed sets to make the mechanism comparison reproducible. Fresh-market confirmation of the separate advice-transmission study is recorded in `output/repaired/transmission-confirmation-v1-full/`; those results are not pooled into these six rule-switch figures. Retired experiments are retained as historical records and are not manuscript evidence.

Historical results were preserved for audit rather than deleted. `Protocol.json` records zero initial cached files and no historical imports. Each execution-ledger entry is written only after a new full simulation and its conservation/resource checks complete. The sole production-source amendment changed checkpoint scheduling from dynamic to greedy after a 480-check equivalence test; its exact one-line diff, hashes, and original protocol are archived. Numerical simulator functions were unchanged throughout production.

## Recomputed findings

- Every retained campaign was rerun from empty data and figure directories, including full financial simulations with technical traders held. The execution ledger contains **51,056** newly completed full simulations. The fixed campaign manifest contributes 45,910; refinement, extensions, selected figure histories, and wrapper validation are counted separately in `Verification.json`.
- With active technical traders and depth h=100, the rule campaign produced 0/50 Sell majorities at fractions .10 and .15, and 50/50 at .20 and .25. All matched no-switch controls remained below a majority over 3,000 steps.
- The persistent rule effect survives the repaired execution mechanism. The one-time Sell-pulse probabilities ranged from 0.00 to 0.00. In the eighteen-rule screen at f=.20, 6 rules produced majorities in all twenty starting markets under both feedback conditions and 12 produced none.
- The old protective interpretation of a small dealer does **not** survive. At f=.20, active median drawdown is 99.99% at h=.1 and 25.15% at h=100. However, the corresponding no-switch medians are 77.04% and 0.75%. Median paired increases are 22.96 and 24.39 percentage points. Table S2 reports all eight depths and pointwise bootstrap intervals.
- Held decisions are financially independent by construction; the fresh run also verifies matching final states, onset, and final mean Sell fraction across depths and resource changes. Separately, all 3,000 newly computed held size outcomes match the historical decision summaries. That old/new comparison supplies no manuscript inputs. The 5 refined held curves also match the historical midpoints, widths, susceptibility peaks, and their confidence intervals exactly.
- The held majority midpoint changes from 0.216 at L=32 to 0.166 at L=128. At L=64, extending observation from 3,000 to 9,000 steps changes it from 0.178 to 0.167. These are finite-grid, finite-time comparisons.
- The h=.1 minus h=100 majority contrast at f=.175 is -0.06 with adaptive widths and -0.26 with frozen widths. Their difference is +0.20, with a paired 95% bootstrap interval [-0.08, +0.50].
- The 100,000-step no-switch controls gave active: 0/10; held: 0/10 majorities. At f=.15 and 10,000 steps, the fifty-market extension gave 2/50 majorities with the changed rule and 0/50 in matched controls.

## Review items

| Item | Resolution | Evidence |
|---|---|---|
| 1. Matched null interventions | Fresh paired Sell pulses and persistent rule switches at identical target sets. | Table S5 |
| 2. Single-entry rule screen | All eighteen alternative single-entry rules, three fractions, twenty starting markets, both feedback conditions. | Table S6 |
| 3. Adaptive refinement | Bisect fraction intervals near the majority crossover, up to ten rounds; report actual interior-point counts. | Figure 3; Table S3 |
| 4. Bootstrap uncertainty | 2,000 whole-market resamples; report crossing, width, and sampled susceptibility-peak intervals. | Methods; Table S3 |
| 5. Dealer feedback mechanism | Recompute adaptive/frozen band contrasts and paired uncertainty; remove the obsolete +.38 claim. | Table S7 |
| 6. Horizon scaling | Recompute fixed, size-dependent, and extended windows with full held financial histories. | Table S9 |
| 7. Impact sensitivity | Replace the obsolete independent exponential coefficient with reserve depths 40, 100, and 400; state their coupled effects. | Table S8 |
| 8. Long no-switch controls | Rerun ten starting markets per feedback condition for 100,000 additional steps. | Supplementary methods |
| 9. Logistic sensitivity | Refit increasing logistic curves and bootstrap their midpoint/width uncertainty from fresh data. | Figure 3A; Table S10 |
| 10. Totalistic restriction | Explain which neighbor configurations are conflated; retain the limitation to this rule class. | Methods; Discussion |
| 11. Causal framing | Separate persistent rule assignment, Sell-majority formation, execution, and drawdown; include matched financial controls. | Results; Table S2 |
| 12. Dealer comparison | Replace historical price outcomes and the small-dealer crash ceiling with reserve-model results. | Figures 2 and 5; Table S2 |
| 13. Baseline characterization | Recompute pre-switch Sell windows and return summaries; avoid stationarity or calibration claims. | Supplementary methods |
| 14. Majority threshold | Recompute first passage for Sell fractions .4, .5, and .6 on the horizon grid. | Table S9 |
| 15. Behavioral interpretation | Explain the ordered Buy/Hold/Sell score and the information omitted by a totalistic rule. | Methods |
| 16. Title scope | Retain the title restricted to local rule activation and dealer capacity in a cellular automaton market. | Title |
| 17. Table S2 source | Generate the table from fresh rule summaries and all-depth paired drawdown comparisons. | WriteManuscriptTables.py |
| 18. h=10 display | Keep h=10 explicitly as a distinct finite comparison; the deep arm is h=100. | Figure 2 |
| 19. Interior-point counts | Report actual counts and distinguish sampled peak locations from fitted estimates. | Tables S3 and S10 |
| 20. Advance selection | Freeze this rerun protocol and manifests before production; do not retroactively claim preregistration of the original study. | Protocol.json; supplementary methods |
| 21. Single-seed illustration | Select new examples by the documented numerical rule before viewing images; cite ensemble comparisons. | Figures 4 and 5; Table S11 |

## Limits

No infinite-time threshold, global attractor classification, classical nucleation mechanism, fitted susceptibility exponent, empirical market calibration, or general arbitrage-free theorem is claimed. Held financial invariance follows from the update structure and does not establish realism. Bootstrap intervals condition on the selected fraction grid. Frozen bands retain path-specific baseline widths and a moving center. Absolute dealer reserves grow with trader count in the size series.

## Validation

All six figure PDFs and all eleven tables were regenerated. The model tests passed 6,028 checks, the rebuild tests passed 79, and scheduling equivalence passed 480. `Verification.json` records manifest completeness, source hashes, newly recomputed overlaps, and conservation bounds. `Build.json` records the compiled PDF and input hashes; the build has zero LaTeX/BibTeX warnings and zero overfull boxes. Visual review and installation are recorded separately in `Visual-Review.json` and `Build.json`.

Reproduction instructions are in `code/rebuild/README.md`. Use `ColdClone.py` to create another empty-data copy of this exact executed source. Earlier checkpoint directories are never copied. Additional manuscript postprocessing and presentation adjustments are versioned separately from the frozen production source.
