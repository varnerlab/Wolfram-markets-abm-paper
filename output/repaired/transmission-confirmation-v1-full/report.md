# Fresh-market confirmation of local advice influence

Both predeclared endpoints passed: the joint claim was confirmed on fresh starting markets.

Completed 5,200 runs across 50 starting markets. Pilot observations were not pooled with confirmation. All results use the unchanged repaired engine.

The primary setting is 40% adoption of one shared source, reserves of 100 shares per trader, and technical traders held. Cash is measured after all traders liquidate, relative to the same prospective cohort in its no-following market, normalized by value at adoption.

| Required endpoint | Mean change (pp; adjusted interval) | Positive lower limit |
|---|---:|---|
| continuous_cash_advantage | +26.706 [+25.425, +28.062] | True |
| continuous_minus_mask | +23.818 [+22.304, +25.299] | True |

The two required endpoints use 97.5% percentile intervals with a Bonferroni adjustment for nominal 95% family coverage. Both lower limits must exceed zero. Bootstrap coverage is approximate. The analysis averages design replicates within each starting market, then resamples whole markets 10,000 times. The following secondary intervals are pointwise 95% intervals.

| Technical traders | Reserves/trader | Advice intervention | Follower cash difference (pp; 95% interval) |
|---|---:|---|---:|
| active | 1 | live | -18.082 [-18.321, -17.847] |
| active | 1 | mask | -12.709 [-12.912, -12.513] |
| active | 1 | withdrawal | -12.740 [-13.181, -12.274] |
| held | 1 | live | -3.122 [-4.419, -1.808] |
| held | 1 | mask | -12.519 [-12.831, -12.205] |
| held | 1 | withdrawal | +0.551 [-0.174, +1.279] |
| active | 100 | live | +20.141 [+19.052, +21.255] |
| active | 100 | mask | -2.561 [-3.246, -1.883] |
| active | 100 | withdrawal | +10.755 [+9.988, +11.497] |
| held | 100 | live | +26.706 [+25.580, +27.875] |
| held | 100 | mask | +2.888 [+2.181, +3.584] |
| held | 100 | withdrawal | +12.187 [+11.347, +12.992] |

Masking retains follower submitted advice orders while changing what their neighbors read. Held non-followers reproduce their no-following decision histories exactly; active technical traders retain the route through prices. Withdrawal also changes follower orders and therefore does not isolate local influence by itself.

The largest absolute dealer cash difference was 6.55651e-07 currency units. The corresponding aggregate trader cash difference was 1.13156e-07. With all trader shares liquidated, the dealer's reserve invariant fixes equal final dealer cash. Follower cash gains redistribute cash among traders.

Complete secondary estimates are in [Grouped.csv](Grouped.csv), [Contrasts.csv](Contrasts.csv), and [Source-contrasts.csv](Source-contrasts.csv). The [market-level primary values](Primary-markets.csv) and [bootstrap draws](Primary-bootstrap.csv) reproduce the fixed decision. See the [protocol](../../../docs/superpowers/specs/2026-09-14-reserve-transmission-confirmation.md).

The confirmation tests new starting markets within this model and its specified settings. It does not establish useful information about an external asset value, real investment performance, copying effects, transaction-cost robustness, alternative execution mechanisms, or size/horizon sensitivity.
