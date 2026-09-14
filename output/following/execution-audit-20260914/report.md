# Execution-price diagnostic, 14 September 2026

The current simulator produces positive cash profits from prescribed, fully filled buy–sell and sell–buy cycles when price impact is positive. The dealer loses the same cash. No advice, copying, or transmission is required. Prices and every trader's share holdings return to their initial values.

All 35 deterministic cases passed checks for prescribed fills, cash/share conservation, unchanged holdings of other traders, return to the initial price and dealer inventory, and agreement with the analytical profit. These cases are implementation diagnostics, not independent market samples.

## Selected results

All cases use a 64 by 64 grid, initial price 100, cash 1,000 and ten shares per trader. Selected technical traders remain in Hold but count in the simulator's price-impact denominator. The synchronized group contains 40% of interior traders, rounded using the campaign convention. Values below are simulation currency units.

| Orders | Capacity | Impact | Participants | Cycles | Cash gain per participant | Group cash gain | Dealer cash change |
|---|---:|---:|---:|---:|---:|---:|---:|
| hold | 1 | 0.02 | 0 | 1 | 0.00000000 | 0.000000 | 0.000000 |
| buy_sell | 0 | 0.02 | 1538 | 1 | 0.00000000 | 0.000000 | 0.000000 |
| buy_sell | 1 | 0 | 1538 | 1 | 0.00000000 | 0.000000 | 0.000000 |
| buy_sell | 1 | 0.02 | 1 | 1 | 0.00051190 | 0.000512 | -0.000512 |
| sell_buy | 1 | 0.02 | 1 | 1 | 0.00051190 | 0.000512 | -0.000512 |
| buy_sell | 1 | 0.02 | 1538 | 1 | 0.79041223 | 1215.654012 | -1215.654012 |
| sell_buy | 1 | 0.02 | 1538 | 1 | 0.78421371 | 1206.120687 | -1206.120687 |
| repeated | 1 | 0.02 | 1538 | 100 | 79.04122315 | 121565.401211 | -121565.401211 |

`Summary.csv` contains all cases, including unlimited capacity, reversed order, five intervening Hold steps, and repeated cycles. `Steps.csv` records every execution and dealer ledger.

## Why the gain appears

For a group of $M$ traders each buying one share at $P_0$, the new quote is $P_1=P_0\exp(\lambda M/N)$, where $N$ is the simulator's fixed number of traders. Selling those shares next settles at $P_1$ and returns the quote to $P_0$. The group earns $MP_0[\exp(\lambda M/N)-1]$. Selling endowed shares first and buying them back gives $MP_0[1-\exp(-\lambda M/N)]$. With idle traders between legs, the gain is unchanged. No gain occurs at zero impact, with all traders holding, or when zero capacity prevents both legs from filling.

The supplied analytical benchmark integrates the marginal quote along each one-sided execution path. Outward and return legs then have the same average execution price and zero cash profit before costs. The benchmark does not implement eligibility, mixed orders, or rationing for a new market model.

## Interpretation and next experiment

The current convention permits profitable round trips without an informative signal. This establishes a competing explanation for follower gains; it does not measure how much of the confirmation returns comes from that convention. The completed confirmation campaigns remain results for their recorded model.

Next, specify a separate execution variant that accounts for price impact in fill prices and tests eligibility at those prices. It must handle offsetting orders and dealer constraints, conserve cash/shares, and remove the profitable isolated round trip before adding transaction costs. Then run a small paired advice/copying/no-following pilot with matched exit tests and dealer profit/loss. Freeze its design and use new confirmation markets only after the execution checks pass. Do not overwrite the existing campaign files or reuse their checkpoints under changed code.
