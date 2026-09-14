# Transmission controls after the reserve execution repair

The first repaired pilot found a follower cash advantage after liquidation
for shared advice with deep dealer reserves, alongside increased selling
among non-followers. The next question is whether the local influence of
followers raises that advantage. This protocol is recorded before running
the new controls. It follows up the existing exploratory sample, so it is
not an independent confirmation or a public preregistration.

## Comparisons

Use the unchanged reserve-v2 execution engine and the same ten starting
markets (631001 through 631010), two design replicates, 64 by 64 grid,
1,000 baseline and 3,000 intervention steps, reserves h=1/100, and technical
traders held/active. Advice adoption is 10%/40%, with one shared source or
independent streams. Persistence remains 0.8. The primary comparison is
40% adoption, one source, h=100, technical traders held. All other specified
settings are reported as comparisons of scope.

For each setting run continuous advice, transmission masking, and withdrawal.
Each of 80 blocks shares one no-following control, giving 960 treated and
80 control runs (1,040 total). All continuous-advice rows must reproduce the
corresponding earlier pilot rows exactly for common recorded outcomes.

Masking preserves the same follower identities and advice streams. During
the local update of each non-follower, replace a follower neighbor's visible
state with that neighbor's state in the paired no-following run. Orders and
settlement still use actual states and books. In the held condition every
non-follower decision history must then equal its no-following history
exactly. Active technical traders retain the indirect route through prices,
so this intervention only removes the direct local route in that condition.
Identical follower submitted orders in continuous and masked runs are checked
over the entire intervention. Different fills remain possible.

Withdrawal follows precisely the same advice for the first 1,000 intervention
steps, then returns the followers to local-rule decisions for the remaining
2,000 steps, without resetting books, prices, or decisions. The two histories
must match through the last advised step. Report non-follower selling over
the whole intervention, after withdrawal, and in the final 500 steps.
Withdrawal changes followers' orders as well as their influence and does not
isolate transmission by itself.

## Outcomes and interpretation

The primary endpoint is follower final cash, normalized by each trader's
value at adoption, after identical simultaneous liquidation in every arm.
Compare the same prospective cohort with its no-following counterpart.
The main mechanism contrast is continuous advice minus masking. Also report
withdrawal minus continuous advice, and shared minus independent advice
separately for all three interventions. A positive continuous-minus-mask
contrast means the allowed local route increased the cash advantage in this
experiment; it is not a general mediation proportion.

All traders request sales during liquidation, with no new buys, fees, or
outside funds. Each arm must liquidate all trader shares. Save unnormalized
cash changes for followers, all remaining traders (including technical
traders and reserved leaders), and the dealer. They must reconcile. The
dealer's invariant and the common total share supply imply identical final
dealer and aggregate trader cash between paired arms, up to rounding.
Test the new detailed ledger against the existing liquidation summaries.

Secondary outcomes are marked follower returns, non-follower Sell decisions,
late Sell decisions, market drawdown, normalized non-follower liquidation
cash, and the raw cash decomposition. Use 2,000 bootstrap resamples of whole
starting markets after averaging the two design replicates. Intervals are
pointwise and do not adjust for the many comparisons. Report negative,
zero, and uncertain contrasts alongside positive ones. No threshold for
publication readiness is inferred from these pilot controls.

## Reproducibility

Run small controls and ledger checks before the full campaign. Verify exact
threaded/serial and checkpoint-resume agreement. Preserve the reserve-v2
engine and old outputs. Store the new manifest, source/environment/specification
digests, atomic block checkpoints, summaries, analysis, and validation in
`output/repaired/transmission-v1-{smoke,pilot}`. Freeze source before each
campaign, reject changed source on resume, and archive the executed files.
