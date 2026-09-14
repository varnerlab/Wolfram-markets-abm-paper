# Complete corrected manuscript rerun

The corrected model uses a finite constant-product dealer and uniform batch execution at a price supported by its reserves. It removes the isolated dealer round-trip cash extraction present in the old standing-quote/exponential-update combination. It also changes the price mechanism, so old/new differences cannot be attributed to settlement alone. Dealer depth now changes funding and price sensitivity together. The former independent impact-coefficient sweep is replaced by depths 40, 100, and 400. The h=0 matched-trade, fixed-price condition remains a separate control.

Order suppression and rejection statistics now use the post-switch window consistently. The old main-campaign order summaries included baseline steps; this measurement change is also recorded in the protocol.

The rerun uses the retained study's original seed sets to make the mechanism comparison reproducible. Fresh-market confirmation of the separate advice-transmission study is recorded in `output/repaired/transmission-confirmation-v1-full/`; those results are not pooled into these six rule-switch figures. Retired experiments are retained as historical records and are not manuscript evidence.

Historical results were preserved for audit rather than deleted. `Protocol.json` records zero initial cached files and no historical imports. Each execution-ledger entry is written only after a new full simulation and its conservation/resource checks complete. The sole production-source amendment changed checkpoint scheduling from dynamic to greedy after a 480-check equivalence test; its exact one-line diff, hashes, and original protocol are archived. Numerical simulator functions were unchanged throughout production.

## Findings

- Every retained campaign was rerun from empty data and figure directories, including full financial simulations with technical traders held. The execution ledger contains **51,056** newly completed full simulations. The fixed campaign manifest contributes 45,910; refinement, extensions, selected figure histories, and wrapper validation are counted separately in `Verification.json`.
- With active technical traders and depth h=100, the rule campaign produced 0/50 Sell majorities at fractions .10 and .15, and 50/50 at .20 and .25. All matched no-switch controls remained below a majority over 3,000 steps.
- The persistent rule effect survives the repaired execution mechanism. The one-time Sell-pulse probabilities ranged from 0.00 to 0.00. In the eighteen-rule screen at f=.20, 6 rules produced majorities in all twenty starting markets under both feedback conditions and 12 produced none.
- The old protective interpretation of a small dealer does **not** survive. At f=.20, active median drawdown is 99.99% at h=.1 and 25.15% at h=100. However, the corresponding no-switch medians are 77.04% and 0.75%. Median paired increases are 22.96 and 24.39 percentage points. Table S2 reports all eight depths and pointwise bootstrap intervals.
- Held decisions are financially independent by construction; the fresh run also verifies matching final states, onset, and final mean Sell fraction across depths and resource changes. Separately, all 3,000 newly computed held size outcomes match the historical decision summaries. That old/new comparison supplies no manuscript inputs. The 5 refined held curves also match the historical midpoints, widths, susceptibility peaks, and their confidence intervals exactly.
- The held majority midpoint changes from 0.216 at L=32 to 0.166 at L=128. At L=64, extending observation from 3,000 to 9,000 steps changes it from 0.178 to 0.167. These are finite-grid, finite-time comparisons.
- The h=.1 minus h=100 majority contrast at f=.175 is -0.06 with adaptive widths and -0.26 with frozen widths. Their difference is +0.20, with a paired 95% bootstrap interval [-0.08, +0.50].
- The 100,000-step no-switch controls gave active: 0/10; held: 0/10 majorities. At f=.15 and 10,000 steps, the fifty-market extension gave 2/50 majorities with the changed rule and 0/50 in matched controls.

## Verification and reproduction

All six figure PDFs and all eleven tables were regenerated. The model tests passed 6,028 checks, the rebuild tests passed 79, and scheduling equivalence passed 480. `Verification.json` records manifest completeness, source hashes, newly recomputed overlaps, and conservation bounds. `Build.json` records the compiled PDF and input hashes; the build has zero LaTeX/BibTeX warnings and zero overfull boxes. Visual review and installation are recorded separately in `Visual-Review.json` and `Build.json`.

Reproduction instructions are in `code/rebuild/README.md`. Use `ColdClone.py` to create another empty-data copy of this exact executed source. Earlier checkpoint directories are never copied. Additional manuscript postprocessing and presentation adjustments are versioned separately from the frozen production source.
