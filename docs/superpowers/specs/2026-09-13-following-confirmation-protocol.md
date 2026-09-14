# Following experiments: confirmation protocol

Recorded after completion of the pilot and before launching the confirmation
simulations. This freezes the core comparison and its diagnostic slice under
the research plan dated 13 September 2026.

The pilot completed all 3,420 manifest jobs, comprising 3,360 treated runs and
60 shared no-following controls. Every treatment reproduced its control's
pre-intervention state and price history, and every run reconciled individual
orders with aggregate execution and conserved cash and shares. The synthetic
streams were active for about one half of steps; completed-trade sources
remained active. These checks did not identify a reason to change the principal
source distributions, adoption levels, observation horizon, or sample size.

The deposited pilot summary and paired contrasts are exploratory. They suggest
that source concentration affects non-followers and that follower returns and
market drawdown can move in different directions. They are not pooled into the
confirmation sample. The complete pilot tables remain available, including
conditions with weak responses.

**Core confirmation.** Retain the 168 treatment cells in the original plan:
adoption 0.05/0.10/0.20/0.40; one/four/sixteen sources; capacities
0.1/1/unlimited; technical traders held/active; synthetic advice and copying
completed trades, plus independently generated advice for every follower.
Use fifty new market seeds, 620001 through 620050, with four design replicates
per market. This requires 33,600 treatment simulations and 300 shared controls.
Keep the original 1,000-step warm-up and 3,000 treated steps on the 64 by 64 grid.
The implementation and environment digests are recorded in
`Following-Confirmation-Protocol.toml` before launch.

**Primary comparisons.** For synthetic advice compare one common source with
independent streams. For copying compare one leader with sixteen. Match adoption,
market seed, design replicate, dealer capacity, and technical-trader condition.
Measure follower mean return and mean individual portfolio drawdown, market
price drawdown, dealer rejection of eligible sells, and time-averaged Sell
decisions among the remaining non-followers. Compare each condition to its own
no-following market using the same prospective cohort identities. Other
outcomes, including majority events, source agreement, lower-decile returns,
and leader-follower gaps, remain secondary.

**Analysis.** Use 2,000 complete-market bootstrap resamples with common resample
indices across conditions. Estimates and intervals are pointwise; the manuscript
will not interpret them as simultaneous confidence over every parameter value.
Individual traders and design replicates within the same market are not
independent markets. Missing denominators remain missing. Majority events use
the overlaid decisions that generated orders, and unobserved onsets are censored.
For saturated event probabilities use the exact independent-market boundary
bound. For paired event contrasts with no observed variation, bound the chance
of an unobserved discordance at the market level rather than reporting a
zero-width bootstrap interval as certainty. No p-value-selected parameter cells
or extrapolated transition thresholds are used.

If equivalence labels are reported, the complete paired 95% interval must fall
within one percentage point of normalized return/drawdown or five percentage
points of rejection/non-follower Sell fraction. These are simulation reporting
margins, not economically calibrated criteria. No single overall "good/bad"
score combines investor gains with market risk.

**Required diagnostics.** Retain adoption 0.10/0.40, one/sixteen sources,
capacities one/unlimited, both technical-trader conditions, and all confirmation
markets/design replicates. The diagnostic manifest includes live sources,
withdrawal, transmission masking, desired-decision copying, fixed replay of
desired and completed leader tapes, memoryless advice, and reversed advice.
Live-condition endpoints receive a separate simultaneous-exit stress test.
The base diagnostic campaign has 35,200 treated runs and 800 controls. Including
the planned size 32/128, horizon 10,000, and impact 0.005/0.05 sensitivities gives
67,200 treated runs and 4,800 controls, or 72,000 simulations in total. These are
additional runs, not additional independent market seeds. Exact duplicate
configurations are shared within the diagnostic design.

The capacity-one no-following market supplies fixed leader tapes for replay
across capacities. No new trader money or shares are introduced during the
exit test; report cash recovered and unsold shares separately. With fixed
sources and technical traders held, masked non-followers must exactly reproduce
their baseline decision histories. Live completed-trade copying does not have
the ordinary held-lattice financial-independence property.

**Figures and scope.** Show full adoption curves for the principal contrasts.
Use capacities one and unlimited for detailed cohort/exit comparisons; retain
capacity 0.1 in complete tables and overview figures. Choose example trajectories
nearest the within-condition median primary outcome, breaking ties by market
seed and design replicate. Include weak-response conditions. Main figures
separate changes in non-follower decisions from investment and execution
outcomes. Use at most two additional main figures; wider control grids belong
in the supplement.

The work tests synthetic common advice and single-asset unit-trade copying.
It does not test a deployed AI product, net-of-fee investment performance, or
multi-asset portfolio overlap. Performance-based leader choice and heterogeneous
delays remain secondary extensions; they are not prerequisites for the
confirmed principal comparisons.
