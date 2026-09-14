# Does local transmission raise follower cash gains?

Completed 1040 runs across 10 starting markets. The full campaign follows up the same ten-market repaired pilot; it is exploratory. Every arm has a matched no-following prehistory and identical liquidation rules. 320 continuous-advice rows reproduce the earlier pilot exactly.

All 160 held masking runs restored every non-follower's decision history exactly, while keeping follower submitted orders identical to continuous advice. Active technical traders retain the route through prices, so masking removes only the direct local influence in that condition. Withdrawal agrees with continuous advice through the last advised step, then stops advice without resetting the market.

## Primary setting and reserve comparison

The primary setting is 40% adoption of one shared source, h=100, technical traders held. The following table also displays h=1 and active technical traders. Values are mean differences in normalized follower cash against the same cohort's no-following control, after all traders liquidate. Intervals are pointwise 95% intervals from 2,000 whole-market bootstrap resamples.

| Technical traders | Reserve shares/trader | Intervention | Follower exit-cash difference (pp; 95% interval) | Non-follower Sell difference (pp) | Final-window Sell difference (pp) |
|---|---:|---|---:|---:|---:|
| held | 1 | live | -5.697 [-7.807, -3.549] | 18.904 | 18.640 |
| held | 1 | mask | -13.131 [-13.631, -12.613] | 0.000 | 0.000 |
| held | 1 | withdrawal | 0.335 [-1.600, 2.467] | 20.125 | 20.027 |
| active | 1 | live | -18.526 [-19.096, -17.988] | 18.568 | 18.272 |
| active | 1 | mask | -12.882 [-13.193, -12.510] | -1.197 | -1.318 |
| active | 1 | withdrawal | -13.078 [-14.193, -12.150] | 20.158 | 20.465 |
| held | 100 | live | 27.008 [23.874, 30.082] | 18.904 | 18.640 |
| held | 100 | mask | 1.925 [0.497, 3.319] | 0.000 | 0.000 |
| held | 100 | withdrawal | 11.238 [8.711, 13.927] | 20.125 | 20.027 |
| active | 100 | live | 20.640 [17.957, 23.475] | 18.715 | 18.414 |
| active | 100 | mask | -3.391 [-4.844, -1.892] | -1.190 | -1.339 |
| active | 100 | withdrawal | 9.993 [7.714, 12.488] | 20.642 | 21.118 |

## Mechanism contrasts

Continuous minus masked advice measures how allowing the direct local route changed follower cash. Withdrawal minus continuous advice combines stopping follower orders with their subsequent local responses. Neither contrast is a general mediation fraction.

| Technical traders | Reserves/trader | Adoption | Sources | Contrast | Follower exit-cash change (pp; 95% interval) |
|---|---:|---:|---|---|---:|
| held | 1 | 10% | one shared | continuous_minus_mask | 8.387 [5.509, 11.067] |
| held | 1 | 10% | one shared | withdrawal_minus_continuous | 3.116 [-0.805, 7.231] |
| held | 1 | 10% | independent | continuous_minus_mask | 7.234 [6.424, 7.973] |
| held | 1 | 10% | independent | withdrawal_minus_continuous | -35.005 [-36.158, -33.753] |
| held | 1 | 40% | one shared | continuous_minus_mask | 7.434 [5.363, 9.554] |
| held | 1 | 40% | one shared | withdrawal_minus_continuous | 6.032 [2.731, 9.244] |
| held | 1 | 40% | independent | continuous_minus_mask | 4.769 [4.500, 5.036] |
| held | 1 | 40% | independent | withdrawal_minus_continuous | -18.022 [-18.623, -17.443] |
| active | 1 | 10% | one shared | continuous_minus_mask | -3.686 [-4.406, -2.988] |
| active | 1 | 10% | one shared | withdrawal_minus_continuous | 3.411 [2.458, 4.320] |
| active | 1 | 10% | independent | continuous_minus_mask | 0.955 [0.627, 1.325] |
| active | 1 | 10% | independent | withdrawal_minus_continuous | -32.807 [-34.109, -31.573] |
| active | 1 | 40% | one shared | continuous_minus_mask | -5.644 [-5.983, -5.359] |
| active | 1 | 40% | one shared | withdrawal_minus_continuous | 5.448 [4.744, 6.080] |
| active | 1 | 40% | independent | continuous_minus_mask | 3.807 [3.631, 4.008] |
| active | 1 | 40% | independent | withdrawal_minus_continuous | -22.099 [-22.871, -21.382] |
| held | 100 | 10% | one shared | continuous_minus_mask | 37.547 [34.756, 40.729] |
| held | 100 | 10% | one shared | withdrawal_minus_continuous | -29.822 [-33.156, -26.889] |
| held | 100 | 10% | independent | continuous_minus_mask | 0.570 [0.526, 0.613] |
| held | 100 | 10% | independent | withdrawal_minus_continuous | -6.854 [-6.977, -6.738] |
| held | 100 | 40% | one shared | continuous_minus_mask | 25.083 [22.032, 27.861] |
| held | 100 | 40% | one shared | withdrawal_minus_continuous | -15.770 [-18.865, -12.934] |
| held | 100 | 40% | independent | continuous_minus_mask | 0.670 [0.632, 0.708] |
| held | 100 | 40% | independent | withdrawal_minus_continuous | -4.616 [-4.659, -4.571] |
| active | 100 | 10% | one shared | continuous_minus_mask | 38.571 [35.311, 42.369] |
| active | 100 | 10% | one shared | withdrawal_minus_continuous | -27.947 [-31.443, -24.822] |
| active | 100 | 10% | independent | continuous_minus_mask | 0.066 [0.045, 0.087] |
| active | 100 | 10% | independent | withdrawal_minus_continuous | -6.834 [-6.990, -6.667] |
| active | 100 | 40% | one shared | continuous_minus_mask | 24.031 [21.267, 26.700] |
| active | 100 | 40% | one shared | withdrawal_minus_continuous | -10.647 [-13.606, -7.953] |
| active | 100 | 40% | independent | continuous_minus_mask | 0.532 [0.511, 0.552] |
| active | 100 | 40% | independent | withdrawal_minus_continuous | -4.596 [-4.659, -4.530] |

## Who funds the cash difference?

All trader shares were sold in both arms. Raw cash changes include the followers, every remaining trader (including technical traders and reserved leaders), and the dealer. Equal terminal share inventories and the reserve invariant fix equal terminal dealer cash, so cohort differences redistribute cash among traders.

Largest absolute paired dealer cash difference: 5.43892e-07 currency units. Largest absolute aggregate trader cash difference: 8.5216e-08.

| Technical traders | Reserve shares/trader | Intervention | Follower cash difference (units) | Remaining traders' difference (units) |
|---|---:|---|---:|---:|
| held | 1 | live | -454423.622 | 454423.622 |
| held | 1 | mask | -1022547.413 | 1022547.413 |
| held | 1 | withdrawal | 14189.641 | -14189.641 |
| active | 1 | live | -1328718.534 | 1328718.534 |
| active | 1 | mask | -927669.864 | 927669.864 |
| active | 1 | withdrawal | -940597.861 | 940597.861 |
| held | 100 | live | 916504.774 | -916504.774 |
| held | 100 | mask | 65137.295 | -65137.295 |
| held | 100 | withdrawal | 381370.536 | -381370.536 |
| active | 100 | live | 700279.687 | -700279.687 |
| active | 100 | mask | -115363.363 | 115363.363 |
| active | 100 | withdrawal | 339093.916 | -339093.916 |

`Grouped.csv`, `Contrasts.csv`, and `Source-contrasts.csv` contain every specified setting and outcome. Sell differences are percentage points of trader-time spent deciding to sell; the final window is the last 500 steps in the full campaign. Withdrawal occurs after 1,000 of the 3,000 intervention steps. These controls do not cover copying, fees, alternative reserve mechanisms, size/horizon sensitivity, or fresh-market confirmation. No real investment performance or journal-readiness claim follows.
