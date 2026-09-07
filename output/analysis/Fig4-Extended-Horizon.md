# Extension of the Fig. 4 markets to 10,000 steps

The five displayed starting markets were extended using the original decision rules, resources, and price response. All 50 original starting markets at f = 0.150 were also extended. Every changed-rule run had a matched run that retained Rule 19280. These are extensions of existing simulations, not independent replications. The original 3,000-step statistics were checked against the archived results for all 54 pairs. The complete price and Sell-fraction histories through step 3,000 were also reproduced exactly for the five illustrated changed-rule runs.

All times below are steps **after** the rule change, following 1,000 initial steps. A price change is relative to the price when the rule changed. Maximum drawdown is the largest fall from a preceding peak in the stated period. A Sell majority means at least half of interior states were Sell at least once; it is not a definition of a price crash.

| Fraction | Seed | Price change at 3,000 | Price change at 10,000 | Maximum drawdown through 10,000 | First Sell majority |
|---|---:|---:|---:|---:|---:|
| 0.150 | 8 | -3.51% | -3.02% | 5.41% | None by 10,000 |
| 0.175 | 5 | -9.57% | -25.53% | 25.58% | 4,117 |
| 0.175 | 22 | -17.62% | -26.43% | 26.50% | 2,186 |
| 0.185 | 46 | -23.64% | -26.26% | 26.31% | 1,779 |
| 0.200 | 21 | -25.60% | -26.34% | 26.37% | 1,030 |

For the displayed f = 0.150 market (seed 8), the price did not continue declining: it rose 0.50% between steps 3,000 and 10,000. The mean Sell fraction over the final 500 steps was 26.96%, compared with 26.82% at the original endpoint. Its maximum drawdown increased only from 5.33% to 5.41%. This supports persistence over these 10,000 steps, not stability for arbitrary time.

Across the 50 f = 0.150 starting markets, no run reached a Sell majority by 3,000 or 5,000 steps. Two did by 10,000: seed 7 at step 6,144 and seed 46 at step 8,417. Their prices ended 24.48% and 22.52% below their values when the rule changed. All 50 matched original-rule runs remained below a Sell majority. The median price change across the changed-rule runs was -3.30% at 3,000 and -3.39% at 10,000. Median maximum drawdown rose from 4.88% to 5.48%; the worst rose from 9.32% to 24.53%.

The Fig. 4 f = 0.175 example without a majority at 3,000 (seed 5) developed one at step 4,117 and ended 25.53% below its price when the rule changed. The other three examples already had majorities at 3,000 and continued toward mean Sell fractions near 90% by 10,000. Thus, a run without a majority at the original endpoint cannot be labeled indefinitely stable.

Previous horizon checks used edge traders kept in Hold and omitted finances. They also found 2/50 majorities at f = 0.150 by 9,000 steps, but do not answer the price-stability question for the active-price markets in Fig. 4.

The manuscript Fig. 4 uses these extended histories with the same five originally selected markets.

## Reproduction

```sh
julia --project=code --threads=4 code/revision/Compute-MarketPanel-Horizons.jl
/opt/homebrew/bin/python3 code/revision/Plot-MarketPanel-Horizons.py
```

Summary and trajectories: `code/data/ModelB-Revision-MarketPanel-Horizons*.csv`.
