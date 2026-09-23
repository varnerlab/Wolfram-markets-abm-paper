# Methods: orders, trader resources, and completed trades

Status: opening paragraph, corresponding Discussion limitation, dealer
reserves/execution-price construction, and trade-quantity selection and
allocation accepted, applied, and verified. Settlement and the dealer's
quoted price were accepted and applied on 18 September with the subsequent
transaction-fee extension. The historical proposal at the end was superseded
by the common base price and separate dealer fee account now in the manuscript.
See `2026-09-18-transaction-fees.md` for implementation and verification. Earlier
proposal and feedback entries record the historical review sequence.

## Scope and findings

Source: `paper-arxiv/sections/methods.tex:63–77`, with the following dealer
paragraph read for context. Reserve clearing and its equations remain the
next review unit after the opening is accepted.

The existing financial rules agree with the implemented main experiments.
The revision is chiefly explanatory:

- State the permitted trades and resource requirements directly. Replace
  the description of a disabled software option with the substantive rule
  that sales below average purchase price were permitted. Preserve the
  existing average-purchase-price symbol and references.
- Explain agent suppression through insufficient cash or shares. An order
  supported by the trader's resources can still be unfilled because of
  dealer capacity; that distinct outcome is defined in the next passage.
- Clarify that failed execution does not itself replace an interior
  trader's intention with Hold. The original “stored decision persisted”
  could suggest that failure freezes a trader's state across later decision
  updates. The next interior update still applies the assigned rule.
- Keep the statement about resources out of the local decision rule scoped
  to their direct role. Prices can still affect interior intentions through
  technical traders; the later feedback subsection explains that route.

## Evidence checked

All code references are in the frozen executed snapshot
`output/rebuilt/manuscript-reserve-v1/`.

- `code/src/Compute.jl:214–222`: Buy requests one share, Sell offers one
  share, and Hold requests no order; the request recurs each step with
  the corresponding intention.
- `code/src/Factory.jl:369–386`: trader books contain cash, integer shares,
  and average purchase cost. Initial endowed shares use the starting price
  as their acquisition cost.
- `code/src/ReserveClearing.jl:40–60,72–101`: orders are collected from
  interior and technical traders. Affordability is evaluated at the
  candidate and finally selected execution prices. Sellers must own a
  share. Executed orders settle at the same selected price. Suppression
  is the requested count minus the resource-eligible count; dealer rejection
  is the eligible count minus the completed count.
- `code/model-b/Compute-ModelB-RuleQuench.jl:55–69`: the main driver sets
  `cost_basis_rule=false`. The unchanged supplementary algorithm states
  that the main persistent-rule experiments have no cost-basis restriction.
- `code/src/Simulate.jl:211–224`: settlement transfers cash and shares and
  updates average cost on purchases, without writing interior intentions.
- `code/src/Simulate.jl:697–752,101–135`: execution precedes the technical
  response and simultaneous interior update. Interior neighbors supply
  their previous intentions whether or not their orders completed; the
  four-neighbor rule does not read holdings.

No simulation was needed. This review did not add or reinterpret claims
about the existing disposition-effect references. Retain their citation
beside the description of the omitted below-cost selling restriction if
the proposal is applied.

## Proposed opening, not applied

A trader's intended action generated a desired order, but completing the
order required cash or shares and a counterparty. Each interior trader
and technical trader held cash $w_i$ and an integer number of shares $q_i$.
A Buy action requested one share, a Sell action offered one share, and a
Hold action generated no order. All completed trades within a time step
used the same execution price. A buy
required enough cash to pay the execution price, and a sale required at
least one share. We allowed sales below a trader's average purchase price
$\bar c_i$. We classified desired orders that could not be completed
because the trader lacked cash or shares as \emph{agent suppression}.
For interior traders, an unfilled order did not replace the intended
action with Hold. A trader without shares could still intend to Sell, and
its neighbors continued to use that intention when forming their next
decisions. Financial resources therefore constrained completed trades
without directly entering the interior decision rule.

The manuscript and PDF still contain the original orders paragraph. The
current build and visual record is in the preceding subsection's review;
this proposal will require its own saved-state and rendered checks when
accepted and applied.

## Author feedback: behavioral interpretation remains open

The author requested explicit “A Buy action ... a Sell action ...” wording
and rejected “determined together with the quantities that could trade”
as confusing. Those two changes are reflected in the proposal above. The
dealer-price calculation can be explained with its equations in the next
passage. The author also asked whether sales below purchase cost could be
described as irrational and whether Sell intentions without shares would
draw justified reviewer criticism. The remainder of the proposal remains
open pending that discussion.

Checked Odean (1998), *Are Investors Reluctant to Realize Their Losses?*,
including the disposition-effect, expected-return, and tax discussions:
https://onlinelibrary.wiley.com/doi/10.1111/0022-1082.00072 . The paper
documents reluctance to realize losses and discusses circumstances in which
realizing losses can be appropriate. A sale below acquisition cost alone
does not establish irrationality. The manuscript's fixed local rules also
do not provide an optimizing benchmark against which such a claim could be
tested. Keep the neutral statement that such sales are permitted. If the
existing disposition citations remain, connect them to the behavioral
restriction omitted from this model, not to a claim that loss realization
is irrational. The publisher's online date differs from the article's
1998 issue date; the existing bibliography year remains correct.

The Sell-state concern is substantive. Checked `_ca_step` in the frozen
`code/src/Simulate.jl:101–135`, resource eligibility in
`code/src/ReserveClearing.jl:55–76`, and the outcome definition in
`code/src/Compute.jl:203–210`. A trader with no shares cannot execute a
sale, but can continue to receive Sell from its neighbors, influence other
interior traders, and count toward the interior Sell fraction. Cash and
shares do not directly enter the local decision rule. This describes an
assumed separation of expressed intention and feasible trade; it is not
evidence that real influence is independent of holdings. A bearish stance
or recommendation is a possible interpretation for discussion with the
author, not an accepted relabeling of the model or an empirically verified
mechanism.

The current Discussion describes nonoptimizing traders and distinguishes a
Sell majority from executed sales, but does not explicitly explain the
continued influence of traders after they exhaust their shares. Add that
specific limitation during its review. Independence from trader resources
in the held rule-switch condition is built into the decision rules; it
must not be presented as an empirical finding about investor behavior.

Suggested replacement for the final explanation, pending author discussion:

“We allowed traders' Buy and Sell intentions to influence their neighbors
even when the traders lacked the resources to carry them out. Cash and
share holdings limited completed trades but did not determine which
intentions entered neighboring decisions.”

A comparison that conditions the communicated state on available resources
could test dependence on this assumption. It would change the decision
dynamics and requires a separate protocol and rerun; no such change or
simulation is authorized or performed in this prose discussion. Clear
wording and a limitation do not establish robustness to that alternative.

## Orders opening and Discussion limitation applied, 17 September

The author accepted the revised interpretation and wording and requested
“Update. Next.” Applied the orders opening in `methods.tex:63–77`, using
the accepted action and uniform-price sentences and the explicit assumption
about intentions without resources. Sales below average purchase price
remain permitted. Existing disposition-effect citations now support a
description of the reluctance to realize losses omitted from the model;
the text makes no claim that selling below cost establishes irrationality.

Added three sentences to the existing Discussion limitations paragraph:

> A trader that had sold all its shares could still influence neighboring
> decisions and count toward a Sell majority. We assumed that intentions
> remained observable and influential even when the trader could not act on
> them. We did not test how the results would change if a trader's resources
> also limited the intentions communicated to its neighbors.

This is a scoped limitation edit. It does not mark the complete Discussion
reviewed or imply authorization for the suggested model comparison.
All source outside the Methods opening and that addition is unchanged.

Independent read-only reviewer `rule_construction_check` found no material
issue in either passage. Checked unit orders, resource constraints, common
execution price, suppression/rejection distinction, holdings-independent
neighbor inputs, and Sell-fraction counting against the frozen code.
The reviewer confirmed the limitation does not assert persistence in Sell,
validated sentiment, or a known direction of change under another rule.

Normal build and isolated 25-file archive compilation passed. Extracted PDF
text matched between normal and isolated builds, and final LaTeX/BibTeX
logs had no warnings, undefined references, or overfull boxes. The PDF
remains 29 pages. Text changed on pages 4, 10, and 11; rendered and inspected
pages 3–5 and 9–12 at 85 dpi. No overlap, clipping, orphaned heading, or
isolated paragraph line was observed. Refreshed the output PDF.

Current root PDF, output PDF, and archive-validation manuscript SHA-256:
`726afef1d0aee8c0486a17b8a97e583644ac8c596500cc513aab76061ed01aa3`.

## Dealer reserves and execution price: next proposal, not applied

Scope: the next Methods passage from “The dealer supplied unmatched orders”
through `eq:execution-price`. Read quantity selection and settlement for
context; those later passages are not yet proposed for revision.

The formula agrees with the frozen reserve-clearing implementation. Improve
the explanation by defining the trader count, the dealer's reserve product,
the sign of the net trade, and the changes to both reserves before solving
for price. Avoid implying that the dealer guarantees every unmatched order.
The constant-product relation is an imposed mechanism, not an empirical
law of stock-market pricing. Distinguish the price paid in a batch from the
dealer's marginal quote after settlement, which is defined later.

Evidence and targeted checks:

- `code/src/Simulate.jl:613–616` in the frozen snapshot defines trader count
  as all interior traders plus selected technical traders, including when
  those technical traders are held. Passive edge cells are excluded.
- `code/src/ReserveClearing.jl:3–9` initializes dealer shares as
  `round(h*n_traders)`, cash as `P0*H`, and minimum remaining inventory as
  one share for positive reserves. Zero reserves use a separate fixed-price
  branch, retained for its later review.
- `code/src/ReserveClearing.jl:53–54,65–79,88–101` sets candidate price to
  cash divided by post-trade shares, chooses a supported integer net trade,
  settles at a uniform price, and sets final cash from the invariant.
- Exact rational arithmetic for positive and negative net trades and a
  one-share remaining reserve confirmed that
  `(W + F*x)*(Q-x) == W*Q` with `F=W/(Q-x)`. The case `x=0` deserves a
  precise statement: preservation alone does not identify a transaction
  price when reserves do not move. The implementation uses the continuous
  extension `F(0)=W/Q`, also used for matched opposing trader orders.
- Checked the existing Angeris et al. reference against the author-hosted
  full text at
  https://baincapitalcrypto.com/constant-function-market-makers-multi-asset-trades-via-convex-optimization/ .
  It describes trade acceptance by preserving a reserve function and the
  constant-product special case. The chapter metadata agrees with
  https://web.stanford.edu/~boyd/papers/cfmm.html . A direct PDF fetch failed;
  the HTML full text was available. The derivation and discrete batch rule
  below were checked against this manuscript's implementation, not attributed
  wholesale to the cited paper.

Proposed continuous passage (displays remain part of the explanation):

The dealer acted as market maker by using its own cash and shares to
complete trades that could not be matched between traders. Its finite
reserves could leave some orders unfilled. We denoted the total number
of interior and technical traders by $N_{\rm tr}$ and the initial dealer
shares per trader by $h$. At the initial price $P_0=100$, the dealer started
with $H=\operatorname{round}(hN_{\rm tr})$ shares and cash $P_0H$.
For positive reserves, we required trading to preserve the product of the
dealer's cash and shares, following a constant-product market-making
rule~\cite{angeris2022constant}. The dealer could not borrow cash or
shares and retained at least one share. At the start of step $t$, its
cash and share reserves were $W_{t-1}$ and $Q_{t-1}$, with product $K$.
We denoted a proposed net purchase from the dealer by $x$, positive when
traders bought shares from the dealer and negative when they sold shares
to it. At execution price $F_t(x)$, the dealer would hold $Q_{t-1}-x$
shares and cash $W_{t-1}+F_t(x)x$. Preserving the reserve product required:

```tex
\begin{gather*}
  K=W_{t-1}Q_{t-1},\\
  [W_{t-1}+F_t(x)x][Q_{t-1}-x]=K.
\end{gather*}
```

For a nonzero net trade, solving this balance for the execution price gave:

```tex
\begin{equation}
  F_t(x)=\frac{W_{t-1}}{Q_{t-1}-x},\qquad Q_{t-1}-x\geq1.
  \label{eq:execution-price}
\end{equation}
```

When $x=0$, we used $F_t(0)=W_{t-1}/Q_{t-1}$, so opposing trader orders
could still trade without changing the dealer's reserves.

The next passage will explain how the supported net quantity is selected
using trader affordability and the dealer's remaining shares. No new
simulation or model change is required by this prose and algebra review.

## Dealer and execution-price construction applied, 17 September

The author accepted the proposal and requested “Update. Next.” Applied
the proposed prose and balances, preserving `eq:execution-price` and
`angeris2022constant`. The derivation distinguishes nonzero net trading
from the chosen price at zero net trading. All Methods source before the
dealer passage and from “At this candidate price” onward is unchanged.
No Discussion edit, model change, or simulation was made in this turn.

Independent read-only reviewer `rule_construction_check` found no material
issue. Verified the trader count, reserve initialization, positive-reserve
constraints, signed net trade, product balance, uniform execution price,
and zero-net-trade case against the frozen implementation.

Normal build and isolated 25-file archive compilation passed with identical
extracted PDF text. Final LaTeX/BibTeX logs were clean, with no warnings,
undefined references, or overfull boxes. The PDF remains 29 pages. Text
changed on pages 4–11; rendered and visually inspected pages 3–12 at 85 dpi.
The new balance and price equation fit on page 4 with their lead-ins.
Checked reflowed equations, subsection headings, Results, Discussion,
Conclusion, and adjacent references. No overlap, clipping, orphaned heading,
or isolated paragraph line was observed. Refreshed the output PDF.

Current root PDF, output PDF, and archive-validation manuscript SHA-256:
`df6c77a9f90b735a801cd961a06ff241fc1c54c521bf30df4002393f2d4ea1c4`.

## Trade quantity and allocation: next proposal, not applied

Scope: “At this candidate price” through the end of the dealer-rejection
explanation, including `eq:dealer-buy-excess` and `eq:dealer-sell-excess`.
The following settlement and marginal-quote passage remains next.

The equations agree with the executed positive-reserve branch. The prose
needs to explain why resource eligibility is checked at the proposed
execution price, how the initial eligible imbalance chooses the direction,
and what the two constraints in the maximum mean. Define candidate size
`k`, direction `d_t`, and selected net purchase `x_t` before their displays.
Separate the direction, quantity, and completed-count equations with prose
that explains their relationship. Retain all existing equation labels.

Checked frozen `code/src/ReserveClearing.jl:53–101`, the rationing score
and ordering in `code/src/Simulate.jl:232–256`, and supplementary
Algorithm `alg:dealer-clearing`. Direction is determined at `F(0)`;
integer quantity selection uses the reserve floor and an eligible imbalance
of at least the candidate size in the selected direction. Eligible counts
are then recomputed at the selected price. The smaller eligible side fills
fully; counts on the larger side are limited and priorities select the
specific orders. With the cost-basis restriction disabled, seller eligibility
depends only on owning a share, although the shared notation remains `S_t(x)`.

Targeted exact-rational examples checked the equations and interpretation,
without running simulations or adding tests:

| Case | Dealer cash/shares | Desired buyers' cash; eligible sellers | Selected net quantity | Eligible buys/sells | Completed buys/sells |
|---|---|---|---|---|---|
| Affordability jump | 1000 / 10 | Four buyers with 120 each; one seller | 1 | 4 / 1 | 2 / 1 |
| Minimum inventory | 100 / 1 | Three buyers with 1000 each; no sellers | 0 | 3 / 0 | 0 / 0 |
| Net selling | 1000 / 10 | Three buyers with 75 each; four sellers | -3 | 0 / 4 | 0 / 3 |
| Balanced orders | 1000 / 10 | Two buyers with 100 each; two sellers | 0 | 2 / 2 | 2 / 2 |

The affordability example leaves two resource-eligible buys unfilled at
the chosen price. Increasing the proposed net purchase from one to two
raises the execution price from 1000/9 to 125, at which none of those buys
is affordable. The net-selling example likewise leaves a seller unfilled
despite positive dealer cash. These examples support explaining rejection
as a consequence of whole-share quantity selection and its associated price,
without describing it as exhaustion of the dealer's cash. They are review
calculations, not manuscript results.

Proposed continuous passage:

For each proposed net trade $x$, we counted Buy orders backed by enough
cash to pay $F_t(x)$ as $B_t(x)$ and Sell orders backed by at least one
share as $S_t(x)$. These were the eligible orders at that price. We first
compared eligible buys and sells at $F_t(0)$. Their difference determined
the direction $d_t$, with $+1$ denoting net purchases from the dealer,
$-1$ net sales to the dealer, and zero no net trade:

```tex
\begin{equation*}
  d_t=\operatorname{sign}\{B_t(0)-S_t(0)\}.
\end{equation*}
```

For $d_t\ne0$, we considered nonnegative integer trade sizes $k$ in the
selected direction. The dealer had to retain at least one share after
trading. At the proposed execution price, eligible orders in the selected
direction had to exceed orders on the opposite side by at least $k$.
We chose the largest size satisfying both requirements, giving the net
purchase $x_t$:

```tex
\begin{equation}
 x_t=d_t\max\left\{k\in\mathbb{Z}_{\geq0}:
 Q_{t-1}-d_tk\geq1,\quad
 d_t[B_t(d_tk)-S_t(d_tk)]\geq k\right\}.
 \label{eq:dealer-buy-excess}
\end{equation}
```

We set $x_t=0$ when $d_t=0$. At the selected price $F_t(x_t)$, we denoted
the eligible counts by $B_t$ and $S_t$. The numbers of completed trader
buys $n_t^B$ and sells $n_t^S$ were then given by:

```tex
\begin{equation}
 n_t^B=\min\{B_t,S_t+x_t\},\qquad n_t^S=n_t^B-x_t.
 \label{eq:dealer-sell-excess}
\end{equation}
```

All eligible orders on the smaller side completed. When orders on the
larger side could not all complete, reproducible priorities determined
which were filled. We called eligible orders left unfilled \emph{dealer
rejection}. A larger net trade could violate the dealer's minimum share
reserve or change the execution price so that the eligible orders no
longer supported the proposed quantity. Dealer rejection therefore did
not imply that the dealer had exhausted its cash.

## Trade quantity and allocation applied, 17 September

The author accepted the proposal and requested “Update. Next.” Applied
that passage, retaining both numbered equation labels and the unnumbered
direction equation. Source before the quantity-selection passage and from
“All executed trader orders settled” onward is unchanged. No simulation,
model change, or additional Discussion edit was made.

Independent read-only reviewer `rule_construction_check` found no
substantive issue in the saved passage. The review checked candidate
eligibility, direction at zero net trade, maximum feasible integer size,
minimum dealer inventory, completed counts, priority allocation, and the
interpretation of dealer rejection against the frozen code. The earlier
four exact-rational examples also agreed.

Normal build and isolated 25-file archive compilation passed with identical
extracted PDF text. Final LaTeX/BibTeX logs were clean, with no warnings,
undefined references, or overfull boxes. The PDF remains 29 pages. Text
changed on pages 4–11; rendered and visually inspected pages 3–12 at 85 dpi.
The direction equation stays with its lead-in on page 4. The maximum and
completed-count equations fit with their explanations on page 5. Reflowed
Methods, Results, Discussion, Conclusion, and adjacent references have no
observed clipping, overlap, orphaned headings, or isolated paragraph lines.
Refreshed the output PDF and checked the archive-validation hash against
both manuscript copies.

Current root PDF, output PDF, and archive-validation manuscript SHA-256:
`283f5e4eae6e926b95504e0439517655558289fc5ef6135db297a2ab8a82719a`.

## Settlement and quoted price: next proposal, not applied

Scope: “All executed trader orders settled” through the fixed-price control
at the end of this subsection. Preserve `eq:dealer-ledger`,
`eq:price-update`, and the reference to `alg:dealer-clearing`.

The balances and squared quote update agree with the implementation.
Introduce the remaining dealer shares and cash before the ledger equation,
then define the quoted price from the updated reserves. Explain the quote's
role as the signal observed by technical traders. Keep it distinct from the
uniform price paid by this step's completed orders. Replace “books” and the
unexplained “next marginal quote” with the specific reserves and quoted
price. Remove the legacy aside about an additional exponential adjustment;
the positive statement defining the quote is sufficient.

Retain conservation outside scheduled resource changes, the exact-arithmetic
isolated-round-trip result with its limited scope, reserve depth's two roles,
the comparison at `h=100`, and the separate zero-reserve fixed-price control.
No general claim of no arbitrage or economic realism follows from the
isolated-round-trip identity.

Evidence:

- Frozen `code/src/ReserveClearing.jl:88–103` settles completed trader orders
  at one price, updates dealer shares, evaluates cash using the invariant,
  and returns the remaining reserve ratio as the next quote. The invariant
  cash update is algebraically identical to the stated cash transfer.
- Frozen `code/src/Simulate.jl:213–228` implements trader cash/share
  transfers; lines 697–742 use the reserve quote as the stored price and the
  signal for technical traders. The historical exponential branch is not
  selected by reserve clearing.
- Frozen `code/src/ReserveClearing.jl:20–30` handles zero dealer reserves
  separately and preserves the previous price. Supplementary Algorithm S2
  and the conservation/limiting-cases subsection describe the same rule.
- Exact rational checks with dealer cash 10,000 and 100 shares gave
  execution/quoted prices of 83.333333/69.444444 for a net sale of 20,
  100/100 for zero net trade, and 125/156.25 for a net purchase of 20.
  Each reverse trade restored both dealer reserves exactly. A three-step
  sequence of net quantities 10, -3, -7 also restored both reserves.
  These are algebra checks, not simulation findings.

Proposed continuous passage:

All completed trader orders settled at $F_t=F_t(x_t)$, including orders
matched between traders. The dealer's remaining shares $Q_t$ and cash
$W_t$ were therefore:

```tex
\begin{equation}
 Q_t=Q_{t-1}-x_t,\qquad W_t=W_{t-1}+F_tx_t.
 \label{eq:dealer-ledger}
\end{equation}
```

After settlement, we set the dealer's quoted price $P_t$ equal to its
remaining cash divided by its remaining shares. Substituting the execution
price into these balances gave:

```tex
\begin{equation}
 P_t=\frac{W_t}{Q_t}
     =P_{t-1}\left(\frac{Q_{t-1}}{Q_{t-1}-x_t}\right)^2.
 \label{eq:price-update}
\end{equation}
```

This quote supplied the price signal used by technical traders. It differed
from the execution price whenever $x_t\ne0$. Cash and shares were conserved
across traders and the dealer, except at scheduled changes in trader
resources. In exact arithmetic, the constant reserve product $W_tQ_t=K$
meant that an isolated sequence of trades returning the dealer to its
initial share reserve also restored its initial cash reserve. Such a round
trip could not extract net cash from the dealer. This result did not rule
out gains from trading with other traders. Dealer reserves determined both
the funding available for trades and the response of the quoted price to
net trading. The comparison with large reserves used $h=100$. At $h=0$,
the dealer held no cash or shares. Only opposing trader orders backed by
sufficient resources could be matched, and the price remained at $P_0$.
This separate case provided a fixed-price control
(Algorithm~\ref{alg:dealer-clearing}).
