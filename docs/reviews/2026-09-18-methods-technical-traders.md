# Methods: technical traders and price feedback

Status: subsection accepted, applied, and verified on 18 September,
including opening, bands, step order, and held/active comparison. The
author asked to retain the Bollinger-band-type description. The next
unit is the paired rule-switch opening, recorded separately.

The earlier opening said technical traders bought below and sold above
bands, which can suggest completed trades. Their immediate output is an
intended Buy, Hold, or Sell action; affordability and the fee are applied
when that intention generates an order on the following step. Preserve
that distinction. Explain the placement and band response before the
moving-average symbols and equations. The opening revision need not repeat
the financial settlement details.

Verified against the frozen `Factory.jl:291–315,427–431`,
`Compute.jl:55–70`, and `Simulate.jl:658–670,724–752`: one quarter of the
perimeter is sampled without replacement, remaining sites stay Hold, band
multipliers are sampled once on [0.5,1.5], the new quote first updates the
mean and absolute-deviation measure, and the new technical intentions enter
the subsequent simultaneous interior update. Equality at a band boundary
produces Hold. The deviation is a smoothed absolute departure, not a sample
standard deviation. Mean and deviation initialize at P0 and zero.

Proposed opening only:

Technical traders brought changes in the dealer's quoted price into
neighboring decisions. We placed these traders at one quarter of the
sites along the edge of the grid. The remaining edge sites stayed in
Hold. Each technical trader compared the quoted price with a band around
a recent price average. A price below the lower limit generated a Buy
intention, and a price above the upper limit generated a Sell intention.
Prices within the band, including its limits, generated Hold. These
intentions influenced neighboring interior traders and supplied orders
for the next trading step.

The subsequent definition of the reference mean, smoothed absolute
deviation, fixed individual band multipliers, and normalized net quantity
remains for the following review unit. The existing Brock et al. citation
and contrarian/trend-following comparison have not been edited in this
opening proposal. The publisher record confirms that Brock et al. tested
moving-average and trading-range-break rules. Attempts to fetch two full
text copies timed out; do not treat this as a completed review of the
paper's precise rule definitions.


## Applied opening and naming clarification

The author accepted the opening and asked whether the rule was a
Bollinger-band-type strategy. Applied the agreed placement, intention, and
timing description, retaining “contrarian strategy of the Bollinger-band
type.” Removed the repeated perimeter-placement sentence. Preserved the
existing Brock citation and contrarian comparison. The subsequent
mathematical introduction now explicitly identifies the band-width measure
as an exponentially smoothed absolute departure rather than standard
deviation. No equations, simulation code, parameters, or numerical results
changed.

Checked [John Bollinger's own rules](https://www.bollingerbands.com/bollinger-band-rules),
especially rules 9, 12, and 13 on conventional and exponential bands and
standard deviation. Rule 6 distinguishes a band contact from an automatic
trading signal. Thus “of the Bollinger-band type” accurately qualifies the
modified width, and “contrarian strategy” identifies our model's chosen
response. This check does not newly verify the precise Brock rule definitions;
that existing citation comparison was retained.

Independent read-only reviewer `rule_construction_check` verified the
saved passage against the frozen implementation: quarter-perimeter
placement, strict inequalities and equality/Hold behavior, current
interior-update versus next-order timing, fixed multiplier distribution,
and smoothed absolute departures from the updated average. No substantive
findings remained. Normal and isolated archive builds passed with identical
extracted PDF text and clean final LaTeX/BibTeX logs. The PDF remains 31
pages. Pages 5–12 changed; those and adjacent pages 4 and 13 were rendered
and visually inspected. The output PDF and source archive were refreshed.
PDF SHA-256:
`193652994b614b124526d02613fb30f12dba5d7ff77acd93478fba2f6a644487`.

## Accepted proposal: band calculation and initialization

The reference price $\mu_t$ was an exponentially weighted moving average
of the dealer's quoted price. The band width used $\sigma_t$, an
exponentially smoothed absolute departure from this average. Both quantities
used the smoothing parameter $\alpha=1/60$. After settlement, we first
updated the average using the new quote $P_t$ and then updated the departure:

```tex
\begin{equation}
 \mu_t=\mu_{t-1}+\alpha(P_t-\mu_{t-1}),\qquad
 \sigma_t=\sigma_{t-1}+\alpha(|P_t-\mu_t|-\sigma_{t-1}).
 \label{eq:adaptive-band}
\end{equation}
```

We initialized the average at $\mu_0=P_0$ and the departure at
$\sigma_0=0$. Each technical trader received a fixed multiplier
$k_j\sim U[0.5,1.5]$, giving lower and upper limits
$\mu_t-k_j\sigma_t$ and $\mu_t+k_j\sigma_t$.

The recorded normalized net purchase $\phi_t$ and its existing equation
label remain to be integrated immediately after this band definition, as a
separate reported quantity. Preserve the distinction that it records
completed trades and does not provide a second price-update mechanism.
The step sequence and held/active comparison remain a subsequent unit.


## Band calculation applied and verified

Applied the accepted explanation and aligned equations, initialization at
$\mu_0=P_0$ and $\sigma_0=0$, and fixed individual multiplier distribution.
Retained the explicit distinction from standard deviation. Moved the
unchanged normalized net purchase definition immediately after the band
calculation. Both equation labels remain intact; the displayed equation
numbers changed order, and the supplementary references updated correctly.
The scalar recurrences, simulation parameters, code, and results are
unchanged.

Independent read-only reviewer `rule_construction_check` verified the
saved text and equations against the frozen implementation, including
initialization, the new-mean dependency in the departure, the uniform
multiplier distribution, and the recorded normalized completed quantity.
No substantive findings remained. No affected hard-coded equation numbers
were found. Normal and isolated source-archive builds passed with identical
extracted PDF text and clean final logs. The PDF remains 31 pages. Changed
pages 5, 6, and 27 and adjacent pages 4, 7, 26, and 28 were rendered and
visually checked. Refreshed output PDF SHA-256:
`184dee0ae101313781d70cd5bd7b47afc0751f8d4aaba908c64e45bd93d67f46`.

## Accepted proposal: order within each trading step

Replace the step-order paragraph and repeated arrow sequence with the
following continuous explanation. Retain the held/active comparison for
the next review unit.

At the start of each step, we applied any scheduled changes to decision
rules or trader resources. Traders then submitted orders from their
existing intentions. After settlement, technical traders updated their
bands and intentions using the dealer's new quote. Interior traders then
updated simultaneously, using the previous intentions of neighboring
interior traders and the new intentions of adjacent technical traders.
The resulting intentions supplied orders for the following step
(Algorithm~\ref{alg:model-step}).

Verified against frozen `Simulate.jl:672–755` and the saved Algorithm S1:
rule assignment and resource interventions occur before execution; the
settled reserve quote supplies the band update; technical decisions are
written before the simultaneous interior step. The persistent rule switch
does not itself replace the current intentions. The supplementary Sell
pulse is a separate intervention already distinguished in the supplement.
This proposal does not alter the step order or the held comparison.


## Step-order paragraph applied and verified

Applied the accepted step-order paragraph and removed the repeated arrow
sequence. The prose preserves scheduled interventions before orders,
settlement before the technical response, old interior/new technical
intentions in the simultaneous interior update, and orders from the
resulting intentions at the following step. The Algorithm S1 reference is
preserved. No equations, code, parameters, or results changed.

Independent read-only reviewer `rule_construction_check` found no
substantive issue in the saved passage against the frozen simulator and
Algorithm S1. Normal and isolated source-archive builds passed with
identical extracted PDF text and clean final LaTeX/BibTeX logs. The PDF
remains 31 pages. Changed page 6 and adjacent pages 5 and 7 were rendered
and visually inspected. Refreshed output PDF SHA-256:
`dc87cdd333f07b7222a9c59fde2607fe6c0197b197950a3ed98cf773c1e3e0a0`.

## Accepted proposal: held and active technical traders

To remove price feedback, we kept every technical trader in Hold from
initialization. These traders submitted no orders and communicated Hold
to their neighbors. Interior traders could still trade, so cash,
shareholdings, and the dealer's quoted price could change. Those changes
could no longer influence interior intentions through the technical
traders. We compared this condition, \emph{technical traders held}, with
\emph{technical traders active}, in which they followed the band rule.
Both conditions began with the same initial market and used the same
interior traders selected for the rule change. The comparison tested
whether a Sell majority could develop from responses to neighbors without
feedback from prices. Figure legends abbreviate these conditions as held
and active.

Evidence: frozen `Simulate.jl:579–621` initializes the grid, technical
locations/bands, target rules, and financial books before the feedback
mode affects any step. Technical intentions begin in Hold (`:658`) and
remain Hold in the held branch (`:736–748`); execution and financial
updates occur on every step before that branch. The main drivers use the
same seeds and non-feedback parameters in matched held/active conditions.
`RebuildRuntime.jl:50–57` executes the full financial simulator even for
held conditions. The independent reviewer confirmed these control
semantics during the saved step-order check.

Holding the technical traders removes their orders as well as their
price-dependent influence, so the proposal states both effects. It does
not claim that held and active paths share a pre-switch history: they
share initialization and can diverge during the baseline. The exact
common-history claim belongs to rule-switch/no-switch pairs within each
feedback condition, reviewed in the following subsection.


## Held/active paragraph applied and verified

Applied the accepted paragraph. It now states that held technical traders
remain in Hold from initialization, submit no orders, and communicate Hold
to their neighbors. Interior trading and financial updates continue. The
comparison shares initialization and selected rule-change targets, without
claiming common pre-switch trajectories across feedback modes. No code,
equations, parameters, or results changed.

Independent read-only reviewer `rule_construction_check` checked the saved
paragraph against the frozen simulator and main drivers and found no
substantive issue. Normal and isolated source-archive builds passed with
identical extracted PDF text and clean final logs. The PDF remains 31
pages. Changed page 6 and adjacent pages 5 and 7 were rendered and visually
inspected. Refreshed output PDF SHA-256:
`a328db71c0f3d5e037e8eee45e0c21b6284888e867320e2f260a4466920029bc`.

The next unit is the paired rule-switch opening, proposed but not applied
in `2026-09-18-methods-paired-experiments.md`. That comparison shares the
full pre-switch history within a feedback condition, which differs from
the shared initialization of held and active simulations.
