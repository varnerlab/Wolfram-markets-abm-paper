# Smoke workflow: no confirmation claim

This small workflow check is excluded from confirmation.

Completed 52 runs across 1 starting markets. Pilot observations were not pooled with confirmation. All results use the unchanged repaired engine.

The primary setting is 40% adoption of one shared source, reserves of 100 shares per trader, and technical traders held. Cash is measured after all traders liquidate, relative to the same prospective cohort in its no-following market, normalized by value at adoption.

| Required endpoint | Mean change (pp; adjusted interval) | Positive lower limit |
|---|---:|---|
| continuous_cash_advantage | +4.316 [+4.316, +4.316] | True |
| continuous_minus_mask | -2.999 [-2.999, -2.999] | False |

The two required endpoints use 97.5% percentile intervals with a Bonferroni adjustment for nominal 95% family coverage. Both lower limits must exceed zero. Bootstrap coverage is approximate. The analysis averages design replicates within each starting market, then resamples whole markets 10,000 times. The following secondary intervals are pointwise 95% intervals.

| Technical traders | Reserves/trader | Advice intervention | Follower cash difference (pp; 95% interval) |
|---|---:|---|---:|
| active | 1 | live | -1.970 [-1.970, -1.970] |
| active | 1 | mask | -3.929 [-3.929, -3.929] |
| active | 1 | withdrawal | -1.526 [-1.526, -1.526] |
| held | 1 | live | -1.134 [-1.134, -1.134] |
| held | 1 | mask | -4.148 [-4.148, -4.148] |
| held | 1 | withdrawal | -1.516 [-1.516, -1.516] |
| active | 100 | live | +3.004 [+3.004, +3.004] |
| active | 100 | mask | +7.301 [+7.301, +7.301] |
| active | 100 | withdrawal | -0.320 [-0.320, -0.320] |
| held | 100 | live | +4.316 [+4.316, +4.316] |
| held | 100 | mask | +7.314 [+7.314, +7.314] |
| held | 100 | withdrawal | -0.052 [-0.052, -0.052] |

Masking retains follower submitted advice orders while changing what their neighbors read. Held non-followers reproduce their no-following decision histories exactly; active technical traders retain the route through prices. Withdrawal also changes follower orders and therefore does not isolate local influence by itself.

The largest absolute dealer cash difference was 1.86265e-09 currency units. The corresponding aggregate trader cash difference was 3.0559e-10. With all trader shares liquidated, the dealer's reserve invariant fixes equal final dealer cash. Follower cash gains redistribute cash among traders.

Complete secondary estimates are in [Grouped.csv](Grouped.csv), [Contrasts.csv](Contrasts.csv), and [Source-contrasts.csv](Source-contrasts.csv). The [market-level primary values](Primary-markets.csv) and [bootstrap draws](Primary-bootstrap.csv) reproduce the fixed decision. See the [protocol](../../../docs/superpowers/specs/2026-09-14-reserve-transmission-confirmation.md).

The confirmation tests new starting markets within this model and its specified settings. It does not establish useful information about an external asset value, real investment performance, copying effects, transaction-cost robustness, alternative execution mechanisms, or size/horizon sensitivity.
