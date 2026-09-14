# Does local transmission raise follower cash gains?

Completed 52 runs across 1 starting markets. The full campaign follows up the same ten-market repaired pilot; it is exploratory. Every arm has a matched no-following prehistory and identical liquidation rules. 0 continuous-advice rows reproduce the earlier pilot exactly.

All 8 held masking runs restored every non-follower's decision history exactly, while keeping follower submitted orders identical to continuous advice. Active technical traders retain the route through prices, so masking removes only the direct local influence in that condition. Withdrawal agrees with continuous advice through the last advised step, then stops advice without resetting the market.

## Primary setting and reserve comparison

The primary setting is 40% adoption of one shared source, h=100, technical traders held. The following table also displays h=1 and active technical traders. Values are mean differences in normalized follower cash against the same cohort's no-following control, after all traders liquidate. Intervals are pointwise 95% intervals from 2,000 whole-market bootstrap resamples.

| Technical traders | Reserve shares/trader | Intervention | Follower exit-cash difference (pp; 95% interval) | Non-follower Sell difference (pp) | Final-window Sell difference (pp) |
|---|---:|---|---:|---:|---:|
| held | 1 | live | 17.771 [17.771, 17.771] | 28.665 | 28.665 |
| held | 1 | mask | 2.005 [2.005, 2.005] | 0.000 | 0.000 |
| held | 1 | withdrawal | 4.435 [4.435, 4.435] | 8.068 | 8.068 |
| active | 1 | live | -3.106 [-3.106, -3.106] | 27.074 | 27.074 |
| active | 1 | mask | -3.440 [-3.440, -3.440] | 0.511 | 0.511 |
| active | 1 | withdrawal | -4.140 [-4.140, -4.140] | 5.142 | 5.142 |
| held | 100 | live | 3.869 [3.869, 3.869] | 28.665 | 28.665 |
| held | 100 | mask | 7.496 [7.496, 7.496] | 0.000 | 0.000 |
| held | 100 | withdrawal | 1.071 [1.071, 1.071] | 8.068 | 8.068 |
| active | 100 | live | 2.440 [2.440, 2.440] | 30.312 | 30.312 |
| active | 100 | mask | 7.428 [7.428, 7.428] | 0.312 | 0.312 |
| active | 100 | withdrawal | 0.045 [0.045, 0.045] | 12.188 | 12.188 |

## Mechanism contrasts

Continuous minus masked advice measures how allowing the direct local route changed follower cash. Withdrawal minus continuous advice combines stopping follower orders with their subsequent local responses. Neither contrast is a general mediation fraction.

| Technical traders | Reserves/trader | Adoption | Sources | Contrast | Follower exit-cash change (pp; 95% interval) |
|---|---:|---:|---|---|---:|
| held | 1 | 10% | one shared | continuous_minus_mask | 30.186 [30.186, 30.186] |
| held | 1 | 10% | one shared | withdrawal_minus_continuous | -38.775 [-38.775, -38.775] |
| held | 1 | 10% | independent | continuous_minus_mask | 27.855 [27.855, 27.855] |
| held | 1 | 10% | independent | withdrawal_minus_continuous | -30.901 [-30.901, -30.901] |
| held | 1 | 40% | one shared | continuous_minus_mask | 15.766 [15.766, 15.766] |
| held | 1 | 40% | one shared | withdrawal_minus_continuous | -13.336 [-13.336, -13.336] |
| held | 1 | 40% | independent | continuous_minus_mask | 13.139 [13.139, 13.139] |
| held | 1 | 40% | independent | withdrawal_minus_continuous | -19.817 [-19.817, -19.817] |
| active | 1 | 10% | one shared | continuous_minus_mask | 3.340 [3.340, 3.340] |
| active | 1 | 10% | one shared | withdrawal_minus_continuous | -25.666 [-25.666, -25.666] |
| active | 1 | 10% | independent | continuous_minus_mask | 0.188 [0.188, 0.188] |
| active | 1 | 10% | independent | withdrawal_minus_continuous | -26.523 [-26.523, -26.523] |
| active | 1 | 40% | one shared | continuous_minus_mask | 0.334 [0.334, 0.334] |
| active | 1 | 40% | one shared | withdrawal_minus_continuous | -1.034 [-1.034, -1.034] |
| active | 1 | 40% | independent | continuous_minus_mask | 1.166 [1.166, 1.166] |
| active | 1 | 40% | independent | withdrawal_minus_continuous | -10.445 [-10.445, -10.445] |
| held | 100 | 10% | one shared | continuous_minus_mask | -0.123 [-0.123, -0.123] |
| held | 100 | 10% | one shared | withdrawal_minus_continuous | -11.866 [-11.866, -11.866] |
| held | 100 | 10% | independent | continuous_minus_mask | 1.195 [1.195, 1.195] |
| held | 100 | 10% | independent | withdrawal_minus_continuous | -6.391 [-6.391, -6.391] |
| held | 100 | 40% | one shared | continuous_minus_mask | -3.627 [-3.627, -3.627] |
| held | 100 | 40% | one shared | withdrawal_minus_continuous | -2.798 [-2.798, -2.798] |
| held | 100 | 40% | independent | continuous_minus_mask | 0.844 [0.844, 0.844] |
| held | 100 | 40% | independent | withdrawal_minus_continuous | -4.774 [-4.774, -4.774] |
| active | 100 | 10% | one shared | continuous_minus_mask | -1.604 [-1.604, -1.604] |
| active | 100 | 10% | one shared | withdrawal_minus_continuous | -8.743 [-8.743, -8.743] |
| active | 100 | 10% | independent | continuous_minus_mask | -0.069 [-0.069, -0.069] |
| active | 100 | 10% | independent | withdrawal_minus_continuous | -7.565 [-7.565, -7.565] |
| active | 100 | 40% | one shared | continuous_minus_mask | -4.987 [-4.987, -4.987] |
| active | 100 | 40% | one shared | withdrawal_minus_continuous | -2.396 [-2.396, -2.396] |
| active | 100 | 40% | independent | continuous_minus_mask | -0.247 [-0.247, -0.247] |
| active | 100 | 40% | independent | withdrawal_minus_continuous | -4.024 [-4.024, -4.024] |

## Who funds the cash difference?

All trader shares were sold in both arms. Raw cash changes include the followers, every remaining trader (including technical traders and reserved leaders), and the dealer. Equal terminal share inventories and the reserve invariant fix equal terminal dealer cash, so cohort differences redistribute cash among traders.

Largest absolute paired dealer cash difference: 2.09548e-09 currency units. Largest absolute aggregate trader cash difference: 3.81988e-10.

| Technical traders | Reserve shares/trader | Intervention | Follower cash difference (units) | Remaining traders' difference (units) |
|---|---:|---|---:|---:|
| held | 1 | live | 40027.951 | -40027.951 |
| held | 1 | mask | 2414.539 | -2414.539 |
| held | 1 | withdrawal | 8965.291 | -8965.291 |
| active | 1 | live | -8254.205 | 8254.205 |
| active | 1 | mask | -9064.161 | 9064.161 |
| active | 1 | withdrawal | -11112.189 | 11112.189 |
| held | 100 | live | 3315.598 | -3315.598 |
| held | 100 | mask | 6441.256 | -6441.256 |
| held | 100 | withdrawal | 919.409 | -919.409 |
| active | 100 | live | 2078.665 | -2078.665 |
| active | 100 | mask | 6362.194 | -6362.194 |
| active | 100 | withdrawal | 28.796 | -28.796 |

`Grouped.csv`, `Contrasts.csv`, and `Source-contrasts.csv` contain every specified setting and outcome. Sell differences are percentage points of trader-time spent deciding to sell; the final window is the last 500 steps in the full campaign. Withdrawal occurs after 1,000 of the 3,000 intervention steps. These controls do not cover copying, fees, alternative reserve mechanisms, size/horizon sensitivity, or fresh-market confirmation. No real investment performance or journal-readiness claim follows.
