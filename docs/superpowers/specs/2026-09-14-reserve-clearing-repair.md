# Repair of settlement and dealer pricing

The standing-quote model permits profitable isolated round trips. The earlier
financial conclusions require revalidation. Source files from before this
repair are archived in `output/recovery/20260914-before-market-repair/`.
Existing campaigns remain records of the standing-quote model.

## Replacement mechanism

Use a cash-and-share dealer with positive reserves C and Q. Its reserve product
K = C Q remains fixed. The displayed marginal quote is P = C/Q. For a net
purchase of x integer shares by traders, the uniform execution price is

    F(x) = C / (Q - x),   Q - x >= 1.

The dealer changes to (C + x F(x), Q - x), preserving K. Negative x denotes
net sales to the dealer. Both matched trader orders and dealer orders settle
at F(x). The next displayed quote is the new reserve ratio. No additional
exponential repricing is applied. Agent cash, shares, and average cost are
updated using actual execution prices.

At each candidate net quantity x, determine which traders can supply a share,
afford F(x), and (if enabled) meet their cost-basis condition. Determine the
direction of excess demand at x=0. Search in that direction for the largest
integer net quantity supported by eligible orders at its execution price.
All eligible orders on the shorter side execute; the longer side is rationed
using the existing per-step, per-trader seeded priority. Discreteness can leave
unfilled orders even before reserves reach their boundary. Report these as
dealer/auction rejections, not exclusively as exhausted cash or inventory.
The two sides of an order cannot be evaluated at different assumed prices.

The dealer starts with H=round(h*N) shares and P0*H cash. h now means initial
reserve shares per trader. Finite positive H has no upper inventory band and
cannot borrow cash or sell its last reserve share. An empty dealer (h=0) is an
identity control: only matching trader orders can execute at the last quote.
Infinite h is rejected; large finite reserves provide the deep-liquidity
comparison. The old impact coefficient lambda is not a parameter of this
mechanism. Its local log-price slope is 2/H per share, so h=100 initially
matches lambda=0.02 in the old per-trader normalization. That slope changes
with reserves. Equal h values match initial dealer endowments across models,
not price-impact slopes. Each model has its own warm-up and no-switch control.

## Mathematical checks and scope

For an isolated closed order sequence, final Q equals initial Q, and the
invariant forces final C to equal initial C. The trader cannot extract net
cash. Intermediate holds and splitting an order into smaller fills do not
alter aggregate cost when no other trader intervenes. For independent traders,
gains at another trader's expense or from outside information are not ruled
out by this statement. No blanket claim of arbitrage-free real markets follows.

This is a constant-product dealer, a deliberately explicit alternative market
mechanism. It is not a calibrated equity exchange. Price is still linked to
dealer reserves, but not constrained by the old [0,2H] inventory band or its
exponential 3.92% drawdown ceiling. A finite dealer can keep buying shares at
decreasing positive prices while spending a bounded amount of cash. This
changes the economic meaning of liquidity and may reverse old conclusions.

Primary background: Angeris et al., *Constant Function Market Makers:
Multi-Asset Trades via Convex Optimization*,
https://web.stanford.edu/~boyd/papers/cfmm.html ; Uniswap v2 whitepaper,
https://docs.uniswap.org/whitepaper.pdf . The implementation here uses a
uniform batch auction and no fees, not the Uniswap transaction protocol.

## Validation and first survival campaign

Before research runs: test arbitrary closed signed order sequences, reversed
trips, splitting, mixed orders, actual-price affordability, scarcity, a zero
dealer, wealth/cash/share accounting, and rejection of unsupported parameters.
Verify held local-rule histories exactly match legacy histories, and verify
the intervention/control warm-up separately within each mechanism.

The first original-story campaign uses the original 50 seeds (1 through 50),
L=64, 1,000 warm-up and 3,000 post-intervention steps, rule fractions
0.15/0.175/0.20, reserves 0.1/1/10/100, and held/active technical traders.
It contains 1,200 treated and 400 no-switch simulations. Record all outcomes,
including weak responses. Resample starting markets for pointwise intervals.
These are retrospective mechanism checks, not a new independent confirmation.
Compare overlapping h values with the archived original summaries. h=100 is
a separate deep-reserve comparison; do not equate it to unlimited capacity.

After those checks, assess shared advice and copying in a separate small
pilot with paired no-following and identical liquidation conditions. Keep
all new outputs and checkpoints in versioned directories. Do not edit the
manuscript to claim survival before analyzing the new results.
