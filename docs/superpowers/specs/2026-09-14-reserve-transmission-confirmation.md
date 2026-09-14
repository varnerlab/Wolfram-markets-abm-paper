# Fresh-market confirmation of the repaired advice experiment

Recorded after the ten-market transmission pilot and before running any of
the confirmation markets. This is a prospective local protocol, not a public
preregistration. Pilot results selected the question and primary setting;
they will not be pooled with confirmation results.

## Fixed design

Use 50 new starting markets, seeds 641001 through 641050, and two design
replicates per market. Before launch, audit these seeds against the archived
and repaired campaign manifests and summaries. A separate workflow smoke
test uses seed 640001 on a smaller grid and never enters confirmation.

Repeat the transmission pilot's complete design with the unchanged reserve-v2
execution engine: a 64 by 64 grid, 1,000 baseline and 3,000 intervention
steps, initial cash 1,000 and ten shares per trader, reserves of 1 or 100
shares per trader, and technical traders held or active. Advice adoption is
10% or 40%, with one shared source or independent streams and persistence
0.8. For every setting compare continuous advice, local influence masked,
and advice withdrawn after 1,000 intervention steps. Masking changes what
non-followers read from follower neighbors while preserving follower advice
and actual trading. Withdrawal resumes followers' local rules without
resetting the market. Each market/replicate/reserve/technical-trader block
has one no-following control and 12 advice treatments: 400 blocks and 5,200
runs, including 400 controls. Complete all blocks without interim outcome
inspection, optional stopping, replacement markets, or parameter selection.

## Confirmation criteria fixed before launch

The primary setting is 40% adoption of one shared source, reserves of 100
shares per trader, and technical traders held. The endpoint is follower
final cash after identical simultaneous liquidation in each arm, normalized
by each trader's value at adoption. Each arm compares the same prospective
follower cohort with its no-following counterpart. All trader shares must
be sold, without trader buys, outside cash, or fees during liquidation.

Require positive lower confidence limits for both of these fixed endpoints:

1. The continuous-advice follower cash difference from no following.
2. The paired continuous-minus-masked difference in that cash advantage.

Use two-sided 97.5% percentile bootstrap intervals for each endpoint
(quantiles 0.0125 and 0.9875). This applies a Bonferroni adjustment to the
two-endpoint family with nominal 95% family coverage; bootstrap coverage is
approximate. Both lower limits must exceed zero to confirm the specified
joint claim. No minimum economic effect is asserted by this criterion.
Failure of either criterion is reported as failure to confirm the joint
claim, with both estimates and intervals retained.

Average the two paired design-replicate values within each starting market
before averaging markets or resampling. Use 10,000 bootstrap resamples of
whole markets, with NumPy PCG64 seed 2026091401 and common resample indices
across conditions. No trader or design replicate is counted as an independent
market. Require every primary observation to be finite and both replicates
to be present for all 50 markets. Save the market-level primary values and
bootstrap draws so the decision can be independently checked.

## Scope comparisons and reporting

Report every specified condition and the pilot's eleven outcomes: normalized
follower exit cash, marked follower returns, non-follower Sell decisions
over the intervention, after withdrawal, and in the final 500 steps, market
drawdown, normalized remaining-trader exit cash, and raw follower,
remaining-trader, dealer, and aggregate-trader cash differences. For all
outcomes report continuous minus masked advice, withdrawal minus continuous
advice, and shared minus independent advice within each intervention.
These secondary estimates use pointwise 95% intervals from the same
10,000 resamples; they are not simultaneous confirmation claims.

Display the primary confirmation alongside the ten-market pilot without
pooling samples or treating agreement in magnitude as an equivalence test.
Report losses, negative effects, and uncertain comparisons. Use the two
primary endpoints for the confirmation decision even if secondary conditions
look stronger. Extra follower cash redistributes cash among traders after
matched liquidation; it is not aggregate wealth creation or evidence of
information about an external asset value. Confirmation concerns sampling
new starting markets in this model. Copying, transaction costs, other market
mechanisms, and size or horizon sensitivity remain outside this campaign.

## Execution and provenance

Keep the pilot engine and its files unchanged. Before the full campaign,
test the manifest, threaded execution, checkpoint resume, the market-level
analysis, and the two-endpoint decision. Run the complete preparation,
simulation, analysis, verification, and figure workflow on the smoke sample.
Smoke results never receive a confirmation label.

Before each campaign, save source/environment/specification hashes, a prior
market audit, and the complete manifest in
`output/repaired/transmission-confirmation-v1-{smoke,full}`. Freeze the
analysis code along with the simulation code, and reject changed source or
manifest on resume. Use one writer per campaign and atomic block checkpoints.
Run the full campaign with 12 simulation threads and one garbage-collection
thread by default. Progress inspection is limited to checkpoint counts and
errors until every planned block has completed.

Verify manifest coverage and checkpoint-summary identity; paired starting
histories; unchanged follower advice under masking; exact restoration of
non-follower histories with technical traders held; withdrawal prefixes;
complete liquidation and cash reconciliation; disjoint starting markets;
all grouped estimates; and the primary decision from saved market values.
Record complete verification before describing the confirmation as complete.
Archive the frozen source and retain all pilot and confirmation outputs.
