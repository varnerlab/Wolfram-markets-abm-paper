# Simulated Peer Review

**Manuscript:** When Selling Spreads: Local Decisions, Limited Resources, and Market Crashes in a Simulated Market
**Author:** Jeffrey D. Varner (Cornell University)
**Reviewed against:** `paper-arxiv/Paper_v1.tex` and `paper-arxiv/sections/*.tex` at HEAD `1e6a543` (37 pp., 6 figures, Supplementary Tables S1–S14, Algorithms S1–S2)
**Assumed venue tier:** mid-to-high-tier computational economics / complex-systems journal (e.g., *Journal of Economic Dynamics and Control*, *Journal of Economic Interaction and Coordination*, *Physical Review E*)
**Date:** 2026-10-02

> **Note on reviewer selection.** The `/peer-review` skill's personas are written for a
> metabolic-engineering manuscript (FBA/FVA, CFPS, MCMC). They cannot give accurate critique of a
> cellular-automaton market model, and the skill's domain-accuracy rule forbids critique outside the
> reviewer's competence. The three severity tiers, the review format, and the 95%-confidence rule are
> kept; the expertise is mapped to this paper's field.
>
> **Note on verification.** Every numerical statement below was checked against the manuscript
> source, the archived run summaries in `output/rebuilt/manuscript-reserve-v1/code/data/`, or a short
> independent calculation. The appendix lists what was checked and how.

---

## Reviewer 1 — Moderate

*Senior researcher in agent-based computational finance; generally supportive of new simulation
methods; evaluates soundness, clarity, and fit.*

### Summary

The manuscript builds a three-state cellular-automaton market in which interior traders respond to
their four neighbors, edge "technical traders" respond to a quoted price, and orders clear against a
constant-product dealer with finite reserves. Paired experiments switch a single lookup-table entry
(Rule 19280 → 19286) for a fraction *f* of traders and show that a Sell majority forms above a
size- and time-dependent crossover even when no decision responds to price. The paper then shows
that dealer depth and trader holdings, not the majority itself, set the price decline. The work is
carefully controlled and unusually transparent about its limits. My concerns are mostly about
reporting quantities the model already records and explaining mechanisms the reader currently has
to infer.

### Strengths

1. **Paired design with shared history.** Each switched market shares its full pre-switch history
   with a no-switch control, and post-switch dynamics are deterministic apart from hash-based
   rationing (Appendix A.2). Each paired difference is therefore an exact effect for that starting
   market (Table S2), which is cleaner than comparing independent ensembles.
2. **A clean manipulation of price feedback.** The held/active contrast for technical traders,
   together with the exact invariance checks (Appendix A.3–A.4, and an independent test oracle for
   held updates), cleanly separates spread through neighbor responses from spread through price.
3. **Intentions are separated from executions.** The model distinguishes desired orders, trader
   suppression, and dealer rejection (Eqs. 3–5, Algorithm S2), and the authors draw the right
   conclusion from it: a Sell majority and a price decline are separate outcomes.
4. **Honest scoping of the crossover.** The authors decline to claim a threshold. They show that
   $f_{50}$ moves with observation period and with the majority criterion (Table S10), and they
   extend five example markets and all 50 markets at $f=0.15$ to 10,000 steps (Table S12).
5. **Reproducibility and pre-specification.** A hash-verified rebuild, conservation checks after
   every simulation, and two pre-specified, Bonferroni-adjusted endpoints for the following
   experiments (Methods, "Following shared advice") are well above the norm for agent-based models
   (ABMs).

### Weaknesses

1. **Trader suppression is defined but never reported, although it is the dominant execution
   channel.** Methods defines trader suppression as orders blocked by missing cash or shares and
   says suppressed counts were recorded. Results, Discussion, and the figures report only dealer
   rejection, at 0.6–226 per million eligible orders (Fig. 2D, Fig. 6C). The archived summaries show
   a median sell-suppression fraction of about 0.40 in majority-reaching runs at $f=0.18$
   (unchanged resources, all three depths, both conditions), against about 0.12–0.16 in runs without
   a majority. Buy suppression is 0.39–0.46 in every condition. So a large share of the "Sell
   majority" consists of traders who cannot sell, and about 40% of buy orders fail for lack of cash
   even in controls. *Fix:* report suppression next to rejection (one panel or one table column),
   and add a sentence in Results on what fraction of Sell intentions could be executed after onset.
2. **The price plateau in Fig. 4B is unexplained.** All four majority markets in Fig. 4B level off
   at almost the same relative price, 0.735–0.745 of the switch price (Table S12A price changes of −25.49% to −26.48%). This holds whatever the
   fraction (0.175–0.20) and onset time (1,028–4,073 steps), and Table S12A gives 10,000-step
   drawdowns of 25.51–26.50% for all four. Readers will want to know why a majority always ends at
   the same price. Reviewer 2 gives the explanation, a conservation bound. *Fix:* state the
   mechanism in Results where Fig. 4B is first discussed.
3. **The mechanism behind follower gains is asserted, not shown.** The masked comparison
   establishes that influence on neighbors accounts for most of the gain (23.82 pp, Table S14A).
   It does not show how influence becomes cash: who buys from whom, and at what prices. Two
   entries in Table S14A also need explanation. Followers lose 12.52 pp at $h=1$ with technical
   traders held even when masked, and their loss at $h=1$ with technical traders active is larger
   with influence (−18.08) than without it (−12.71). *Fix:* decompose follower and non-follower
   outcomes into mean purchase price, mean sale price, completed-trade counts, and holdings at the
   end of the following period.
4. **The choice of Rule 19286 is not justified, and the screen shows it is the weakest effective
   change.** In Table S7, four single-entry changes (19307, 19334, 19361, 19523) reach a majority in
   every market already at $f=0.15$, and 19298 does so in 95%. Only 19286 needs $f\ge0.20$. The
   headline crossover near $f\approx0.18$ is therefore specific to the least potent of the six
   changes that work. *Fix:* say why 19286 was chosen (for example, that its crossover falls inside
   the tested range), and state in the Discussion that the crossover location is rule-specific.
5. **The abstract's fee claim rests on "selected" comparisons.** Table S13B lists three "selected
   paired comparisons" and gives no rule for selecting them. The caption says the full set is
   archived but not shown. *Fix:* include all paired differences (6 fractions × 3 depths × 2
   conditions × 3 rates) as a supplementary table or a compact heat map, so the reader can see how
   often fees deepen rather than reduce declines.

### Questions for Authors

1. Why was Rule 19280 chosen as the baseline? Is it typical among rules with a stable mixed state
   near 25% Sell, or was it selected for some other property?
2. When a majority first forms, what fraction of the traders in Sell hold zero shares? How long
   after onset do most Sell intentions become unexecutable?
3. With unchanged shares at $h=100$, raising cash tenfold raised the median drawdown from 20.18% to
   28.48% (Results, resource paragraph). Is this because extra buying pushes the running peak
   higher before the decline, rather than deepening the trough?
4. What real-world situation do you have in mind for random, information-free advice shared by 40%
   of traders, and does the 0.8 persistence probability correspond to anything observable?

### Requested Experiments/Analyses

1. A time series of sell- and buy-suppression fractions around majority onset, averaged over runs
   aligned at onset, for $h=0.1$, 1, and 100. This uses existing data.
2. The trade-level decomposition of follower and non-follower cash outcomes described in
   Weakness 3, for the pre-specified condition (40%, one source, $h=100$, held) and for $h=1$.

### Minor Comments

1. Figure labels use different words from the text. Fig. 4 titles and legends say "seed 2" and
   "Steps after rule change", and Fig. 1C says "Rule assigned". The text and captions say
   "starting market" and "rule switch". Use one set of terms throughout.
2. Drawdown units are inconsistent. Fig. 2C plots maximum drawdown as a fraction (0–1), while
   Fig. 6B, the text, and every table use percent. The Fig. 2C y-label also omits "Median", which
   the caption specifies.
3. Fig. 2C (and 2D) connect $h=0$ to $h=0.1$ with a line on a categorical axis. The text treats
   $h=0$ as a separate fixed-price case, so plot it as an unconnected point.
4. In Table S5, the "0.175–0.195" average rows exclude 0.180, although 0.180 lies inside the
   stated range. At $h=100$, for example, "Only active" = 31 = 13 + 13 + 4 + 1, which omits the
   12 at 0.180. Relabel these rows "0.175, 0.185–0.195" or list the fractions.
5. In the legends of Figs. 2A, 3A, and 6A, every series has the same black marker, so series can be
   told apart only by line color. Color the legend markers to match.

### Recommendation

**Minor Revision.**

---

## Reviewer 2 — Hard

*Expert in market microstructure, automated market makers, and the statistics of stochastic
simulation; scrutinizes formulation, estimands, and controls.*

### Summary

The dealer mechanism is correctly formulated: Eq. 8 follows from Eqs. 3 and 7, and the clearing rule
is fully specified. The paired design is sound. However, several of the paper's financial findings
are direct consequences of the constant-product invariant combined with share conservation, and the
paper does not derive them. Presenting them as simulation outcomes overstates what the simulations
add and hides a simple, quantitative explanation that would strengthen the paper. On the decision
side, the main estimand (majority probability within a fixed horizon) depends on the horizon about
as much as on grid size, and the paper's own data suggest a better one.

### Strengths

1. **A fully specified clearing rule.** Uniform-price batch clearing selects the largest supported
   net trade in the direction of initial excess demand (Eq. 4, Algorithm S2). The quoted-price
   update $P_t=P_{t-1}[Q_{t-1}/(Q_{t-1}-x_t)]^2$ (Eq. 8) is algebraically correct given
   $W_tQ_t=K$. Execution price and quoted price are kept distinct, which many ABMs blur.
2. **Invariants enforced in code.** Cash, share, and reserve-product checks run after every
   simulation, with stated tolerances (Appendix A.3), and the largest observed cash discrepancy is
   reported (Appendix A.4).
3. **Appropriate uncertainty quantification.** The bootstrap resamples whole starting markets and
   keeps the pairing across fractions. Wilson intervals are used for proportions, and a logistic fit
   checks the sensitivity of the interpolated midpoints. Methods also states plainly what the
   intervals exclude (refinement-grid selection, interpolation error, horizon).
4. **Confirmatory discipline in the following experiments.** Two endpoints were fixed before
   simulation, with Bonferroni-adjusted intervals, and exploratory comparisons are labelled as such
   and run on separate starting markets.

### Weaknesses

1. **Drawdown magnitudes are largely fixed by a closed-form price floor that the paper never
   states.** From Eqs. 7–8, $P_t=K/Q_t^2$ with $K=P_0H^2$. Shares are conserved (Appendix A.3), so
   $Q_t\le H+\sum_i q_i(0)$, and with ten initial shares per trader:

   $$P_t \;\ge\; P_0\left(\frac{h}{h+10}\right)^2 .$$

   This bound is $0.826P_0$ at $h=100$, $0.25P_0$ at $h=10$, $0.0083P_0$ at $h=1$, and
   $9.8\times10^{-5}P_0$ at $h=0.1$. A switched market that reaches a majority eventually sells most
   trader shares into the dealer and approaches this floor. In the archived dealer-depth summaries
   at $f=0.20$ with active technical traders, the dealer's median final inventory at $h=100$ is
   107.7 shares per trader out of a possible 110. That implies a final price of about $0.86P_0$,
   close to the $0.826P_0$ floor. The same bound explains:
   - the near-identical plateau of the four majority markets in Fig. 4B (Reviewer 1, W2);
   - the ordering of the $h=40$/100/400 drawdowns in Table S9 (48.62%, 25.15%, 7.08%), which follows
     the corresponding floors of $0.64P_0$, $0.83P_0$, and $0.95P_0$. The drawdowns exceed
     $1-P_{\rm floor}/P_0$ because they are measured from a running peak above $P_0$;
   - the share-multiplier ordering in Fig. 6B (3.17% < 20.18% < 77.55% at $h=100$), because scaling
     trader shares moves the floor;
   - "a constant-product dealer never ran out of cash for buying" ($P>0$ for every finite $Q$).

   This does not invalidate the results, but it changes their interpretation. In a majority market,
   maximum drawdown mainly measures *how completely traders liquidate into the dealer* relative to
   the pre-switch peak, and the dealer's reserves set the decline through an identity, not through
   the dynamics. *Fix:* derive the bound in Methods. Plot observed drawdown against the bound
   $1-P_{\rm floor}/P_{\rm peak}$ for the depth and resource campaigns. Report the fraction of
   trader shares transferred to the dealer by onset and by the end of observation.

2. **The "transfer, not new wealth" result in the following experiments is an identity, and the
   reported gain depends on an unexamined liquidation protocol.** With $\tau=0$ and full
   liquidation, the dealer's final inventory $H+\sum_iq_i(0)$ is the same in every path, so its
   final cash $K/(H+\sum_iq_i(0))$ is path-independent. Cash conservation then fixes total trader
   cash. Any follower gain is therefore exactly other traders' loss in *every* run, by construction.
   Results and Discussion present this as an observed outcome ("after every trader sold its
   shares, the dealer's cash and the traders' total cash matched the no-following control"). The
   distribution also depends on the liquidation rule. Every holder sells one share per step, with no
   buyers, into a falling price, so a trader holding more shares at the end of following receives a
   lower average price. At $h=1$, where the dealer holds about one share per trader against the
   traders' ten, this penalty is severe. *Fix:* state the identity as a property of the mechanism.
   Then report the follower outcome under at least one alternative valuation (mark-to-market at the
   last quoted price before liquidation, or liquidation in random trader order) to show that the
   sign and size of the 26.71 pp gain and the shallow-depth loss do not depend on the protocol.

3. **Dealer depth is confounded with trader holdings; the natural control parameter is their
   ratio.** The floor above depends on $h$ only through $h/(h+\bar q)$, where $\bar q$ is shares
   per trader. The share-multiplier ×10 run at $h=100$ (median drawdown 77.55%, $f=0.18$) therefore
   sits near the unchanged-holdings run at $h=10$ (85.68%, $f=0.20$), which has a similar ratio. The
   Discussion correctly notes that depth changes funding and price sensitivity together, but the
   paper offers no way to separate them. *Fix:* (a) plot drawdown and paired drawdown increase
   against $h/\bar q$ across the depth and resource campaigns and test for a collapse onto one
   curve. (b) To separate sensitivity from funding, add a variant with virtual reserves,
   $(W+W_v)(Q+Q_v)=K$, the form used by concentrated-liquidity AMMs. Its price sensitivity can be
   changed while the real reserves available for trading stay fixed.

4. **The main estimand depends on an arbitrary horizon, and the data point to a horizon-free one.**
   Results states that $f_{50}$ "depended on observation time about as much as on grid size". Table
   S10 suggests why: across all eight size–horizon combinations, $f_{50}$ never increases with
   the space–time volume $(L-2)^2T$ (criterion 0.5, technical traders held):

   | $L$ | $T$ | $(L-2)^2T$ | $f_{50}$ |
   |---:|---:|---:|---:|
   | 32 | 750 | 6.8×10⁵ | 0.249 |
   | 32 | 1,500 | 1.4×10⁶ | 0.230 |
   | 32 | 3,000 | 2.7×10⁶ | 0.219 |
   | 64 | 3,000 | 1.2×10⁷ | 0.178 |
   | 64 | 9,000 | 3.5×10⁷ | 0.167 |
   | 128 | 3,000 | 4.8×10⁷ | 0.167 |
   | 128 | 6,000 | 9.5×10⁷ | 0.157 |
   | 128 | 12,000 | 1.9×10⁸ | 0.152 |

   This ordering is what one expects if majorities start from rare local events whose rate scales
   with area, so that grid size and horizon enter only through their product. *Fix:* analyze the
   recorded onset times as time-to-event data. Report Kaplan–Meier survival curves by $f$ and $L$,
   estimate the onset rate per unit time, and test whether it scales with $(L-2)^2$. If it does, a
   per-site rate as a function of $f$ replaces a horizon-dependent probability, and it directly
   addresses the open question in the Results of whether a limiting fraction exists.

5. **The resource comparison has no no-switch controls, yet controls at shallow depth already
   crash.** Table S2B shows median control drawdowns of 77.04% at $h=0.1$ and 32.92% at $h=1$. Most
   of the Fig. 6B drawdowns at $h\le1$ therefore reflect baseline volatility rather than the switch,
   and the paper's caveat ("its drawdowns describe switched markets rather than effects of the
   switch") leaves the reader without an effect estimate. *Fix:* add the controls. That is 9
   resource combinations × 3 depths × 2 conditions × 50 markets = 2,700 runs, a quarter of the
   resource campaign's 10,800. Then report paired increases as in Table S2B.

6. **The price-feedback effect is summarized with a fraction-dependent estimand.** The active-minus-
   held difference at $h=100$ is 0.09 [0.02, 0.15] averaged over 0.175, 0.185, 0.19, and 0.195, and
   0.04 [−0.02, 0.10] once 0.17 and 0.18 are added (Table S5). A conclusion that flips significance
   when two fractions are added needs a fraction-independent estimand. The paper already has one:
   the paired shift in $f_{50}$ between active and held. Tables S3 and S11 give 0.175–0.177 active
   against 0.178 held at $L=64$. *Fix:* report the bootstrapped paired $f_{50}$ difference (same
   starting markets in both arms) as the primary price-feedback estimand.

7. **The fee results imply very high turnover that the paper does not report.** At 25 bp, $h=100$,
   $f=0.20$, cumulative fee income is 36.19% of initial trader cash (Table S13A). That is about 362
   cash units per trader, or roughly 1,500 completed one-share orders per trader at a per-order fee
   near 0.25. In other words, traders trade on roughly a third of all steps and turn over their
   10-share holding more than a hundred times. In this regime a "25 bp" fee is a large cumulative
   cost. *Fix:* report turnover per trader per 1,000 steps for each condition, so readers can relate
   the fee rates to effective trading costs.

### Questions for Authors

1. What fraction of initial trader shares had been transferred to the dealer at onset and at 3,000
   steps, as a function of $f$ and $h$?
2. Fees accrue to a separate account here, whereas in Uniswap-v2-style pools they stay in the
   reserves and raise $K$. Would accruing fees to reserves change the sign of the $h=1$,
   $f=0.175$ fee effect?
3. In the following experiments, how many shares do followers and non-followers hold, on average,
   when liquidation begins?
4. $N_{\rm tr}$ in $H=\operatorname{round}(hN_{\rm tr})$ includes technical traders, who never trade
   when held. Is the dealer depth per *trading* trader therefore slightly different between the
   held and active conditions, and does it matter at $h=0.1$?

### Requested Experiments/Analyses

1. **Price-floor analysis.** Derive the bound, plot drawdown against $1-P_{\rm floor}/P_{\rm peak}$,
   and report fractions of shares transferred to the dealer. This needs no new simulations.
2. **Time-to-event analysis of onset.** Survival curves, onset rate per unit time, and a test of
   scaling with $(L-2)^2$, using the size and horizon campaigns already run.
3. **Liquidation-protocol robustness** for the pre-specified following endpoints: mark-to-market
   and random-order liquidation.
4. **No-switch controls for the resource campaign** (2,700 runs), plus the $h/\bar q$ collapse plot.

### Minor Comments

1. $\phi_t$ (Eq. 6) is defined and cited in Appendix A.1 but used in no result. Remove it or use it.
2. Table S13B is labelled "Selected paired comparisons" but gives no selection rule.
3. Methods defines a "price crash" as "a large simulated decline, without a threshold", while the
   title promises "Market Crashes". At $h=100$, the condition the paper treats as deep reserves, the
   switch-induced decline is about 25% and cannot exceed about 17% below $P_0$ (Weakness 1). Make
   the terminology match the magnitudes.
4. Table S9 states the initial slope $2/h$. Note in the caption that it is the slope with respect
   to net purchases *per trader*, with $N_{\rm tr}$ including technical traders.

### Recommendation

**Major Revision.**

---

## Reviewer 3 — Very Hard

*Statistical physicist working on lattice opinion dynamics and cellular-automaton markets; has
published competing lattice models; reads for artifacts, overclaims, and missing comparisons.*

### Summary

The paper claims that a persistent single-entry rule change, given to a fraction of traders, drives
a lattice market to a Sell majority without price feedback, and that execution, not the majority,
sets the crash. I have four substantive objections. (1) The synchronous, center-excluded update
splits the lattice into two non-interacting halves, and this visibly shapes the reported patterns.
(2) Price feedback enters only through about 1–2% of interior sites by construction, so its "small
net effect" is a consequence of the geometry. (3) Several abstract-level findings are true by
construction. (4) The core result is a committed-minority tipping result whose literature the paper
does not engage, and whose established prediction (critical fraction falling to zero with size) the
paper does not test.

### Strengths

1. **An exhaustive single-entry rule screen.** Table S7 tests all eighteen single-response changes
   to Rule 19280. Lattice-market papers rarely examine their rule choice this systematically.
2. **The persistent-versus-pulse control (Table S6)** separates a lasting change in response from a
   one-time perturbation of the state, which is the right contrast.
3. **Restraint in interpretation.** No critical exponents or infinite-size limits are fitted, the
   majority criterion is varied (0.4/0.5/0.6), and the crossover is explicitly called
   horizon-dependent.

### Weaknesses

1. **The update rule splits the lattice into two independent halves.** Each trader's next state
   depends only on its four neighbors' current states, not on its own (Fig. 1A caption: "current
   state is not an input"), and all interior traders update together (Methods; `_ca_step` in
   `code/src/Simulate.jl:120–131`). On a square lattice every neighbor of a site has the opposite
   checkerboard color. The set {black sites at even steps, white sites at odd steps} therefore
   evolves using only its own members, and so does its complement. With technical traders held, each
   market is *exactly* two non-interacting copies of $(L-2)^2/2$ traders that never influence each
   other. With technical traders active, the copies interact only through about 63 edge traders and
   the price. Consequences:
   - **It is visible in the paper's own figures.** In Fig. 4A, starting markets 41 and 15
     ($f=0.175$) show large regions at 3,000–10,000 steps where Sell and Hold alternate cell by cell.
     In these regions one half of the lattice is in Sell and the other is not. Market 41 ends at a
     Sell fraction of 0.594 (Table S12A).
   - **The two halves can end in very different states.** I re-implemented the held interior update from the
     Methods description (20 markets per fraction, $L=64$; different random draws from the authors'
     code). It reproduces the held majority probabilities roughly: 7/20, 15/20, and 20/20 at
     $f=0.175$, 0.185, and 0.20, against 0.34, 0.70, and 1.00 reported. Near the crossover, the two
     halves frequently end in different states. At $f=0.175$, 6 of 20 markets had final Sell
     fractions differing by more than 0.3 between halves (e.g., 0.65 against 0.27).
   - **Finite-size analysis.** Each run contains two independent sub-systems of half the stated
     size. This changes the meaning of $\chi_L$, the effective system size in Fig. 3, and the
     sampling unit behind the bootstrap.
   - **"Sell-rich domains"** in the Discussion, compared with domain growth, include these
     half-lattice checkerboard regions, which come from the update scheme, not from trader behavior.

   *Fix:* state the split in Methods, and report each half's Sell fraction for the main campaigns.
   Rerun the core held/active comparison (Fig. 2A) and the size comparison (Fig. 3A) under an update
   that does not split: random-sequential updating, or a rule whose input includes the trader's own
   state. Then show whether the crossover and its size dependence survive.

2. **The test of price feedback is weak by design.** Technical traders occupy a quarter of the
   edge, which is 63 of 252 edge positions at $L=64$. Each touches at most one interior trader, so
   price information reaches at most 63 of 3,844 interior traders (1.6%), and 127 of 15,876 (0.8%)
   at $L=128$. Price feedback is therefore a boundary perturbation whose weight falls as $1/L$. The
   finding that active and held midpoints agree "within 0.001" at $L=128$ (Results; Table S3) is
   what this geometry predicts, not evidence about how markets respond to prices. The *sufficiency*
   claim (majorities form with no price feedback) is valid. The claims that feedback's "net effect
   ... was small" (Results) and that financial conditions affect decisions only through technical
   traders (abstract, Discussion) are statements about this placement. *Fix:* place price-responsive
   traders in the interior at several densities (e.g., 1%, 5%, 20%), or add a price term to
   interior rules, and report the active-minus-held shift in $f_{50}$. Otherwise, qualify every
   "small effect" statement with "when only edge traders respond to price".

3. **Several abstract-level findings hold by construction.** Each of the following follows from
   the model's definitions, not from simulation:
   - "Changing trader cash and shares altered later decisions only when technical traders could
     respond to the resulting prices" (abstract). Holdings never enter a decision rule, as the
     Results itself says.
   - Held decisions are identical across depths and fee rates.
   - Zero depth gives zero drawdown.
   - A constant-product dealer cannot run out of cash.
   - The following gain is a transfer (Reviewer 2, W2), and fewer shares mean a smaller decline
     (Reviewer 2, W1).

   The text usually gives the reason ("because"), but the abstract presents several of them as
   results: the sentence beginning "Changing trader cash and shares...", "rejecting few
   orders", and "at the other traders' expense". *Fix:* present them in Methods as model properties and
   verification checks, and use the abstract for the non-trivial findings.

4. **The paper misses the closest literature, and its central prediction goes untested.** A
   persistent minority above a critical fraction flipping a population's majority is the
   committed-minority (zealot) result in opinion dynamics. Examples are Xie et al., "Social
   consensus through the influence of committed minorities", *Phys. Rev. E* 84, 011130 (2011), and
   the experimental tipping-point study of Centola et al., *Science* 360, 1116–1119 (2018). The
   pulse-versus-persistent contrast (Table S6) is the standard initial-condition-versus-zealot
   contrast in that literature. The paper cites bootstrap-percolation results (Aizenman–Lebowitz;
   Holroyd) only to say the rise "resembles" threshold models. Those results show that, on finite
   grids, the critical density falls to zero as grid size grows, decaying like $1/\log L$. The
   paper's own $f_{50}$ falls with both $L$ and $T$ (Reviewer 2's table), yet it concludes only
   that the runs "did not determine whether such a fraction exists". *Fix:* position the work
   against the committed-minority literature and say what is new relative to it. Test whether the
   data are consistent with $f_{50}\to0$, for example $f_{50}$ against $1/\log L$ and against
   $\log[(L-2)^2T]$. Note that the dynamics here are not monotone (Sell can revert to Hold), so the
   bootstrap-percolation prediction need not hold. Showing whether it does would be a real result.

5. **The susceptibility benchmark is a weak null.** The Results compares peak $\chi_L$ with 0.25,
   the maximum for independent traders, to conclude that Sell activity is "strongly correlated".
   But at a crossover where outcomes are close to all-or-none, the between-market variance of
   $\bar m$ stays of order $10^{-2}$, so $\chi_L$ grows roughly in proportion to $(L-2)^2$ for that reason
   alone. The
   paper's own peaks give $\mathrm{Var}(\bar m)=21.2/900=0.024$ at $L=32$ and
   $241.2/15{,}876=0.015$ at $L=128$. The comparison restates what the probability curves already
   show, and with two independent halves per run (W1) the variance is a mixture of two sub-systems.
   *Fix:* show the distribution of $\bar m$ across markets at each size near $f_{50}$, which shows
   whether outcomes are bimodal, or drop the susceptibility.

6. **The claim that fees "deepened" declines rests on one selected contrast, where fees also change
   whether a majority forms.** The only positive drawdown effect shown (+9.04 pp at $h=1$,
   $f=0.175$, active) sits at a fraction where majority probability is 0.36 without the fee and 0.40
   with it (Table S13A). Individual markets can therefore change majority status between arms, and
   the paired drawdown difference mixes a change in severity with a change in occurrence. Of the
   108 positive-fee-versus-zero conditions per outcome, the paper shows three, without a selection rule or a
   multiplicity statement. *Fix:* (a) report the same contrast with technical traders held, where
   decisions are identical across fees, which isolates the financial channel. (b) Split the
   active-condition contrast by whether both arms, one arm, or neither reached a majority.
   (c) Show the full table (see Reviewer 1, W5).

### Questions for Authors

1. In how many majority-reaching runs did only one half of the lattice exceed a Sell fraction of 0.5
   at onset?
2. With technical traders held, an all-Sell interior is a fixed point of both rules (neighbor sums
   6–8 map to Sell, including next to the Hold edge). Is it reachable from the mixed state, and
   if so, does the probability of a majority by time $T$ approach one as $T$ grows for every $f>0$?
   What does the 100,000-step control extension (0/10 in each condition) imply about the rate at
   $f=0$?
3. Four single-entry changes tip every market already at $f=0.15$ (Table S7). Do they have a
   crossover at all within $0<f<0.15$, and does it also move with $L$ and $T$?
4. Do the conclusions survive random-sequential (asynchronous) updating?

### Requested Experiments/Analyses

1. **Update-scheme robustness.** Rerun Fig. 2A (held and active, $h=100$) and the size comparison
   (Fig. 3A, held) under random-sequential updating or a rule whose input includes the trader's own
   state, and report each half's Sell fraction for the existing campaigns.
2. **Interior price-responsive traders** at densities of 1%, 5%, and 20%, reporting the
   active-minus-held shift in $f_{50}$ and in the paired drawdown increase.
3. **An extended rule screen.** The six effective single-entry changes at $f\in\{0.02, 0.05, 0.08,
   0.10, 0.12, 0.15\}$ and two grid sizes, to locate each rule's crossover and its size dependence.
4. **A test of the vanishing-threshold prediction.** $f_{50}$ against $1/\log L$ and against
   $\log[(L-2)^2T]$ using the size and horizon campaigns, with an extra $L=256$ point if feasible
   for held technical traders (decisions only).

### Minor Comments

1. Fig. 3C plots $f_{50}$ against $1/L$, whereas the interior has $(L-2)^2$ traders and $\chi_L$ is
   normalized by $(L-2)^2$. Use $1/(L-2)$, or say why $L$ is the relevant length.
2. Discussion, domain-growth paragraph: the analogy to domain growth (Bray 1994) is asserted, not
   measured. Either measure a growth law or interface speed, or drop it. Note too that the domains
   in Figs. 1C and 4A have straight, lattice-aligned edges, unlike the rounded domains of standard
   coarsening.
3. "Susceptibility" suggests a response function. Here it is a scaled between-market variance of a
   time-limited observable; call it that, or justify the term.
4. Rule-switch paragraph of the Results: the "sixth" effective rule (19307, Buy→Hold at sum 3)
   adds no Sell response. Draw out what follows from it: removing a Buy response is enough to tip
   the market, which says more about the baseline rule than the five Sell substitutions do.

### Recommendation

**Major Revision.**

---

## Summary of Actionable Items

Deduplicated across the three reviews and ordered by how strongly each affects the paper's main
claims. Reviewer tags: R1, R2, R3.

### Priority 1 — affects the validity or interpretation of headline claims

1. **Address the two-halves split from synchronous, center-excluded updating** (R3 W1). State it in
   Methods, report each half's Sell fraction, and rerun the core held/active and size comparisons
   under an update that does not split the lattice. If the crossover survives, the paper is
   stronger. If not, the main result needs reframing.
2. **Derive the constant-product price floor $P\ge P_0[h/(h+\bar q)]^2$** and recast the drawdown
   results around it (R2 W1, R1 W2). Plot drawdown against the bound, report shares transferred to
   the dealer, and explain the Fig. 4B plateau and the Fig. 6B share-multiplier ordering with it.
   No new simulations are needed.
3. **Recast the following "transfer" result as an identity and test liquidation-protocol
   robustness** (R2 W2, R1 W3). Use mark-to-market and random-order liquidation for the
   pre-specified endpoints, and add a trade-level decomposition of where follower gains come from.
4. **Qualify or test the price-feedback conclusions given edge-only placement** (R3 W2, R2 W6).
   Either add interior price-responsive traders at several densities, or limit every
   "small effect" statement to edge placement. Use the paired $f_{50}$ shift as the primary
   estimand rather than an average over hand-picked fractions.
5. **Move by-construction properties out of the abstract's findings** (R3 W3): held invariance,
   zero depth giving zero drawdown, a dealer that cannot run out of cash, zero-sum following, and
   fewer shares giving a smaller decline.

### Priority 2 — strengthens the evidence, mostly from existing data

6. **Time-to-event analysis of onset** (R2 W4, R3 W4). Survival curves and the onset rate per unit
   time, a test of whether the rate scales with $(L-2)^2$ (Table S10 already shows $f_{50}$ falling
   without ever increasing as $(L-2)^2T$ grows), and $f_{50}$ against $1/\log L$.
7. **Engage the committed-minority literature** (Xie et al. 2011, *PRE* 84:011130; Centola et al.
   2018, *Science* 360:1116) and the bootstrap-percolation prediction already cited (R3 W4).
   *Verify both references through Crossref before adding them, per the bib rule.*
8. **Report trader suppression** next to dealer rejection (R1 W1). It is about 0.40 of Sell
   orders in majority runs, against dealer rejection below $5\times10^{-3}$.
9. **No-switch controls for the resource campaign** (about 2,700 runs) and an $h/\bar q$
   collapse plot (R2 W3, W5). Optionally, a virtual-reserve variant to separate price sensitivity
   from funding.
10. **Fee analysis** (R1 W5, R2 W7, R3 W6). Show the full contrast table, add the held-condition
    contrast at $h=1$, $f=0.175$, split by whether arms agree on majority status, report turnover
    per trader, and give a selection rule for Table S13B.
11. **Rule choice and an extended screen** (R1 W4, R3 Q3). Justify 19286, note that it is the
    weakest of the six effective changes, and screen the six at $f<0.15$.
12. **Replace the 0.25 susceptibility null** with the distribution of $\bar m$ across markets near
    $f_{50}$ (R3 W5).

### Priority 3 — presentation and minor fixes

13. Use one set of terms in figures and text: "seed" vs "starting market", "rule change" vs
    "rule switch" (Fig. 4; Fig. 1C "Rule assigned") (R1 m1).
14. Use percent for drawdown in Fig. 2C, add "Median" to its y-label, and plot $h=0$ as an
    unconnected point in Figs. 2C–D (R1 m2–m3).
15. Relabel the Table S5 average rows "0.175–0.195", since they exclude 0.180 (R1 m4).
16. Color the legend markers in Figs. 2A, 3A, and 6A (R1 m5).
17. Remove or use $\phi_t$ (Eq. 6) (R2 m1). Match "crash" in the title to the reported magnitudes
    (R2 m3). Clarify that $N_{\rm tr}$ includes technical traders (R2 Q4, m4).
18. Fig. 3C abscissa: use $1/(L-2)$ or justify $1/L$. Rename or justify "susceptibility". Measure
    or drop the domain-growth analogy. Draw out what Rule 19307 (no added Sell response) implies (R3 m1–m4).

---

## Appendix — Verification notes for the author

These notes are not part of the simulated reviews. They record how the reviews' factual claims were
checked, so they can be traced before acting on them.

1. **Two-halves split.** `code/src/Simulate.jl:120–131` computes
   `configuration = grid[r,c-1] + grid[r,c+1] + grid[r-1,c] + grid[r+1,c]` into a copy (`next`), so
   the update is synchronous and excludes the trader's own state. The split follows from this and
   needs no simulation. The supporting re-implementation was a numpy script modelling only the held
   interior: edge fixed at Hold, initial 5% Buy and 5% Sell, 1,000 baseline steps, then 3,000 steps
   with Rule 19286 at a random fraction *f*. It ran 20 markets per fraction at $L=64$, and its
   random draws differ from the authors' code. Results: majorities 7/20, 15/20, and 20/20 at
   $f=0.175$, 0.185, and 0.20. Final 500-step Sell fractions differed by more than 0.3 between the
   two halves in 6/20, 3/20, and 1/20 markets. The script is in this session's scratchpad
   (`parity.py`), which is temporary; rerun it with the project's own engine if you pursue this.
2. **Price floor.** Algebra: $K=W_0Q_0=P_0H^2$, $P_t=W_t/Q_t=K/Q_t^2$, and
   $Q_t\le H+\sum_iq_i(0)$. Data: `ModelB-ReservoirQuench-Full-Summary.csv`, switched runs at
   $f=0.20$, median `treated_maker_inventory_per_trader` with active technical traders = 3.58
   ($h=0.1$), 7.13 ($h=1$), 12.44 ($h=5$), 17.69 ($h=10$), and 107.73 ($h=100$). The upper limits
   are $h+10$.
3. **Suppression.** `ModelB-BalanceSheetQuench-Full-Summary.csv`, $f=0.18$, unchanged resources,
   median `sell_suppression_fraction`: 0.40–0.43 in majority runs and 0.12–0.16 in non-majority
   runs, across $h\in\{0.1,1,100\}$ and both conditions. Median `buy_suppression_fraction` is
   0.39–0.46 throughout.
4. **Zero-sum identity.** It follows from the invariant $K$, share conservation, full liquidation
   to the dealer (which can always buy), $\tau=0$, and no resource interventions in the following
   runs.
5. **Claims in the manuscript that were checked and hold.**
   - Eq. 8.
   - The Table S5 average rows: the $h=100$, 0.175–0.195 mean is 0.09, and its counts exclude
     0.180.
   - Logistic versus interpolated midpoints, "at most 0.0035": the largest difference is 0.00345, at
     $L=48$ held (`ModelB-Revision-FiniteSize-Scaling.csv`).
   - The width narrowing "about threefold": 0.023 to 0.008.
   - Active midpoints "within 0.007" of held.
   - The 11 dealer-depth fractions exclude 0.17 and 0.18 (Appendix A.4), consistent with the
     "22 of 24" sentence.
6. **Earlier review.** The previous simulated review (tracked in git at HEAD as `peer-review.md`,
   written against commit `0870d82`) is superseded by this file and can be recovered with
   `git show HEAD:peer-review.md`.
