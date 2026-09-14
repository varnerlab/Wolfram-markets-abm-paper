# What survives the execution repair

**Fresh-market confirmation completed:** both predeclared criteria passed in
5,200 runs across 50 new starting markets. The
[confirmation assessment](transmission-confirmation-v1-full/ASSESSMENT.md)
reports the surviving deep-reserve cash advantage and the local-influence
effect. This document records the preceding execution-repair comparison.

**Follow-up completed:** the
[transmission controls](transmission-v1-pilot/ASSESSMENT.md) now test the
mechanism behind the deep-reserve follower advantage. The assessment below
records the preceding execution-repair comparison.

The local-rule cascade survives. The financial interpretation changes
substantially. Following still changes other traders' decisions, and some
follower gains survive liquidation, but their sign depends on dealer reserves.

The repaired mechanism is a uniform-price auction against a constant-product
cash-and-share dealer. Traders settle at a price that includes their batch's
effect on the dealer, and affordability uses that execution price. The
implementation preserves cash and shares and removes the diagnosed isolated
round-trip profit. It also replaces the old inventory band and exponential
repricing rule. This is a comparison between market mechanisms, not an estimate
of the effect of changing settlement alone or a calibrated equity exchange.
The [protocol](../../docs/superpowers/specs/2026-09-14-reserve-clearing-repair.md)
states the equations, assumptions, and limits.

## Execution checks

All 6,087 repair and paired-following test assertions passed. They cover
closed signed paths, reversed trades, intervening holds, order splitting,
actual-price affordability, mixed orders, exhaustive auction comparisons,
cash/share accounting, scarcity, paired histories, and threaded checkpoints.
Existing model, revision, following, and following-control regressions also
passed during the repair.

The original exploit was also replayed through both complete simulators in
64 deterministic scenarios. For the original 1,538-trader group and dealer
reserve of one share per trader, 100 buy–sell cycles previously earned
79.041223 currency units per participant. The repaired simulator returns
**exactly zero** in that case, with the original quote and holdings restored.
All 32 repaired cases had aggregate round-trip cash gains below 1e-6 in
absolute value. See [the comparison](round-trips-v2/Summary.csv).

## Original rule-switch story

The complete comparison contains 1,600 runs: 1,200 switched markets and 400
no-switch controls, using the original 50 starting markets, four reserve
levels, and both technical-trader conditions. Every planned row is present.
With technical traders held in Hold, the Sell-majority counts are unchanged
at every reserve level:

| Fraction assigned the changed rule | Markets reaching a Sell majority |
|---|---:|
| 15% | 0/50 |
| 17.5% | 17/50 |
| 20% | 50/50 |

Complete held decision histories at 20% match the archived simulator exactly
for every starting market and reserve level. This is expected: holding
technical traders removes the route by which prices affect future decisions.
It preserves the decision mechanism, not an independent financial validation.
The counts apply to the tested 3,000-step observation period.

The earlier interpretation that small dealer capacity protects prices does
not survive this replacement. At one initial reserve share per trader, with
technical traders held and 20% switching, the median drawdown changes from
3.921% in the archived model to 99.528%. The repaired no-switch median is
already 44.519%; the mean paired increase attributable to switching within
the repaired model is **54.840 percentage points**. The old drawdown ceiling
was imposed by its price rule and inventory band. The replacement instead
allows continued selling at progressively lower prices. Equal reserve
endowments do not imply equal price depth across mechanisms.

Active technical traders also retain the broad distinction between 15%
(0/50 majorities) and 20% (50/50) in every tested condition. At 17.5%, the
counts change with the mechanism and reserves. The exact previous financial
feedback results cannot be carried forward. See the
[complete original-story report](reserve-v2-full/report.md).

## Following pilot

The completed pilot contains 880 runs across ten new starting markets, with
two design replicates each. It compares advice and copying, 10%/40% adoption,
one/sixteen sources plus independent advice, two reserve levels, and held/active
technical traders. It is exploratory; it does not replace the old 50-market
confirmation campaign.

At 40% adoption of one shared advice source, the paired results are:

| Technical traders | Reserve shares/trader | Non-follower Sell change (pp) | Follower exit-cash change (pp; 95% interval) |
|---|---:|---:|---:|
| held | 1 | +18.904 | −5.697 [−7.851, −3.510] |
| active | 1 | +18.568 | −18.526 [−19.081, −17.961] |
| held | 100 | +18.904 | +27.008 [+24.030, +29.996] |
| active | 100 | +18.715 | +20.640 [+18.048, +23.417] |

Each difference compares the same prospective follower cohort against its
own no-following control. Exit cash is normalized by each trader's value at
adoption. All traders sell under identical liquidation rules, with no new
buys or outside cash. Both arms liquidate every follower share. Intervals
resample whole starting markets and are pointwise, without adjustment for
the many comparisons.

The shared-advice effect on non-followers survives. A universal follower-profit
claim does not. In the deep-reserve condition, a positive cash difference
survives liquidation, so it cannot all be explained by the diagnosed isolated
round trip or endpoint marking. That still does not establish useful
information, a real investment return, or the proposed transmission mechanism
without repeating its controls. Copying outcomes are also conditional: for
example, copying one leader at 40% adoption reduces non-follower selling
relative to control when technical traders are active in this pilot.
The [full following report](following-reserve-v2-pilot/report.md) includes
every tested condition and both marked and liquidation outcomes.

The reserve invariant gives an additional accounting interpretation. When
every trader liquidates, the dealer ends with the same total shares in both
paired arms. Its unchanged cash-times-shares product then fixes the same
terminal dealer cash. Aggregate trader cash is therefore also the same,
up to numerical error. A cohort's extra exit cash redistributes cash among
traders; it does not create aggregate cash wealth.

## Provenance and remaining scope

[Verification](verification.json) checks source/environment digests, manifests,
complete checkpoint coverage, summary identity, and the round-trip cases.
Version 2 fixes a Julia allocation problem without changing arithmetic: all
400 original-story checkpoints and all 14 completed version 1 following
checkpoints match byte for byte. Version 1's partial following campaign is
superseded; its source and outputs remain available. Final source is archived
in `../recovery/20260914-reserve-v2-executed-source/`.

The old manuscript and campaign data remain records of the archived model.
Its financial conclusions require revision. Subsequent advice experiments
completed masking and withdrawal controls and confirmed the primary local
influence result on fresh starting markets. The repaired campaigns have not
repeated the full size/horizon, resource-multiplier, replay, copying-control,
or transaction-cost comparisons. These results do not yet support a claim
of journal readiness.
