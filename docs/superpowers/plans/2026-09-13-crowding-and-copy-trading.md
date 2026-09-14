# Shared advice, copy trading, and market instability

**Research and implementation plan, 13 September 2026.** This document proposes
new experiments. No results from these experiments exist yet. The immediate
deliverable is the plan; simulation development and manuscript integration are
subsequent work. The current manuscript and deposited campaigns remain the
reference for the existing findings.

## 1. The question and the contribution

**What happens when many investors obtain their trading decisions from a small
number of sources, and who benefits or loses when those decisions spread?**

Study two sources within the existing market: an external recommendation stream
and another trader's observed trades. Separate the number of followers, the
concentration of their sources, transmission to people who do not follow, and
the resources needed to complete trades. The central comparison is between
individual investment outcomes and market outcomes, measured in paired markets
with identical histories before following begins.

The existing paper already separates a change in decisions from the resulting
price decline. The new work should establish whether that separation explains
the consequences of shared advice and copy trading. Simply making followers
agree is imposed by the intervention. The scientific results concern what
happens beyond that agreement: propagation, persistence, execution, and the
distribution of gains and losses.

The present baseline assigns Rule 19280 to every interior trader. Changing a
fraction to Rule 19286 adds a second rule; it is not an experiment in increasing
rule uniformity. Retain the original results on their own terms. The new main
experiments start from Rule 19280 and do not simultaneously activate Rule 19286.

| Research question | Controlled comparison | Evidence needed |
|---|---|---|
| Does concentration matter independently of adoption? | Same follower fraction, different source assignments | Differences in desired orders and outcomes under matched individual source processes |
| Does following affect people who never follow? | Following versus no following, tracking the same people | Changes in non-follower decisions, wealth, and execution; a transmission control |
| Can copying help the follower while worsening market outcomes? | Same tagged followers in copying and no-copying markets | Paired wealth and portfolio-risk differences alongside market drawdown and rejected orders |
| Does liquidity change the information people copy? | Copy completed trades versus copy desired decisions, with technical traders held | Changes attributable to whether execution filters the observed signal |
| Does the effect survive after following stops? | Continuous following versus withdrawal after a fixed interval | Decision and price histories after all followers resume their local rules |
| Can dispersing attention or staggering reactions change the outcome? | Fixed adoption with different assignments or delays | Benefits and costs for followers and non-followers, without assuming improvement |

These are model questions. Synthetic advice does not establish what a particular
AI product recommends, and simulated wealth does not establish real investment
performance. The initial study concerns one asset, unit orders, and crowding in
trading decisions; multi-asset portfolio overlap and proportional portfolio
replication are outside this first extension.

## 2. Two interventions with one execution layer

Use `a` for the fraction of interior traders who follow a source. Keep `f` for
the existing rule-switch experiment so the two interventions cannot be confused.
Each follower has one fixed source in the principal experiments. Non-followers
retain their ordinary local rules. Following changes the follower's visible
Buy/Hold/Sell state, and that state generates its desired order and is visible
to neighboring traders. Cash and share limits still determine eligibility;
dealer resources and the existing rationing procedure still determine fills.

For `M` followers, let `n_k` follow source `k`, and let `w_k = n_k/M`. Record
source concentration and its effective number of sources:

\[
C = \sum_k w_k^2, \qquad K_{\mathrm{eff}} = 1/C.
\]

For the no-following control these quantities are undefined, not zero. Record
actual integer assignments, because rounding can make nominally equal groups
slightly unequal. Count source concentration separately from observed agreement:
different human leaders can make correlated trades.

**External advice.** A source issues one Buy/Hold/Sell recommendation per step.
Use stationary probabilities `(0.25, 0.50, 0.25)` for Buy, Hold, and Sell. Start
each stream from that distribution. At each subsequent step, retain its previous
recommendation with probability `eta = 0.8`; otherwise draw afresh from the same
distribution. This gives a precisely specified persistence process. Different
source streams use independent random draws, and all subscribers to a source
receive the same stream. All groups have the same individual recommendation
distribution and persistence in expectation; finite streams need not have
identical realized Buy and Sell counts.

Compare `K = 1, 4, 16` equally subscribed sources and an independent-stream
control with `K = M`. Couple comparisons using a common bank of generated source
streams and reproducible assignments. The independent-stream control is needed
because sixteen sources can still leave large groups acting together. Do not
change the Buy/Sell balance to manufacture a sell-off. Use `eta = 0` and a
Buy/Sell-reversed tape as targeted sensitivities. The baseline rule need not
respond symmetrically to the reversed tape.

For independent source streams with signed recommendations of variance
`sigma_z^2`, the variance of the sum of follower recommendations is
`sigma_z^2 * M^2 * C`. It is `sigma_z^2 * M` for independent followers and
`sigma_z^2 * M^2` for one common source. This is an input sanity check, not a
market result. It helps identify amplification beyond the correlation that the
experiment deliberately supplies.

**Copy trading.** Select a pool of sixteen potential leaders uniformly among
interior traders, independently of their subsequent performance. Leaders retain
their local rules and do not copy other traders in the principal experiments.
Reserve this pool before selecting followers. A follower copies its assigned
leader's completed unit order from exactly one step earlier. A buy becomes a
request to buy one share; a sell becomes a request to sell one share. If the
leader did not complete an order in that step, the follower chooses Hold. Do not
repeat the last nonzero trade indefinitely. A rejected or resource-suppressed
leader order produces no copy event.

Use a seeded permutation of the same leader pool to assign followers to `K = 1,
4, 16` leaders. Re-randomize identities across design replicates. Use a separate
seeded follower permutation, nested across adoption fractions, so comparisons
do not accidentally change leader identities or the initial cohort. All
potential followers are outside the reserved leader pool. This permits `a` to
be measured against all interior traders while preserving a common eligible
population across the tested fractions.

Use those same reserved sites and follower permutations for the advice
conditions in a block. The reserved sites have no advice-provider role, but
keeping them out of the follower set makes cohort comparisons consistent.
Round `a * N_interior` once using an explicit recorded convention. Assign source
groups in the follower-permutation order with group sizes differing by at most
one. Keep each independent-advice stream keyed to trader identity across
adoption fractions.

The concentration comparison deliberately changes whose trades are amplified.
Many independent leader assignments and a fixed-tape diagnostic below are
needed to distinguish concentration from an unusually influential leader.
Live copying cannot promise matched marginal advice: followers can affect the
market and thereby change the leaders' later actions. That endogenous response
is part of the live-copying treatment and must be measured.

**Timing contract.** Preserve an identical complete history through step 1,000.
At the top of step 1,001, before orders clear, enable the intervention and
overwrite follower states using the external recommendation or the recorded
leader action from step 1,000. Freeze all observed source records before applying
any follower override. At later steps use the same sequence:

1. Read the already available source records and set follower states.
2. Record desired orders; test eligibility; clear and settle orders.
3. Record each trader's fill and the new price; update wealth statistics.
4. Update technical traders and apply the ordinary local-rule update.
5. Retain history needed for the next step's copying.

The first treated execution price may diverge at step 1,001. The old persistent
rule-switch check that the first post-switch price is identical does not apply
to this order-changing intervention. No follower uses a same-step future fill.
The no-following path must reproduce the existing simulator exactly.

Measure decision fractions from the actual overlaid state immediately before
clearing. The ordinary update at the end of a step computes a provisional local
decision for a follower that will be overwritten next step. It is not that
follower's observed copied decision. Record separate per-step decision histories
in the following diagnostics and use them for majority events, source agreement,
and transmission outcomes; do not pass legacy post-update Sell histories into
the new analysis without reconciling their timing. Sample the no-following
comparison at the same pre-clearing time. Wealth uses the corresponding
post-settlement, post-price-update state.

## 3. What counts as a benefit, a loss, or an unresolved effect

Freeze cohort membership at intervention: followers, the reserved leader pool,
and remaining non-followers. Report actual subscribed leaders separately from
the full pool. Preserve those labels in the paired no-following path and after
withdrawal. For every trader, save intervention-time cash and shares. Its wealth
is `V_i(t) = cash_i(t) + shares_i(t) * P(t)`, with prices sampled after that
step's settlement and price update. Normalize subsequent wealth by its own
wealth at intervention.

**Primary outcomes and contrasts:**

| Outcome | Definition and primary contrast |
|---|---|
| Follower benefit | Within each paired market, mean follower terminal-return difference relative to the same tagged traders without following; then summarize across markets |
| Follower risk | Mean individual portfolio maximum-drawdown difference; also report the within-market lower decile of follower returns |
| Market price loss | Maximum price drawdown after intervention, including the intervention price as the initial peak |
| Uncompleted selling | Dealer-rejected sell orders divided by eligible sell orders, measured after intervention |
| Transmission to non-followers | Time-averaged Sell fraction among the same non-followers, excluding the leader pool, relative to their matched control |

For advice, the principal concentration contrast is one source versus independent
streams at the same adoption, capacity, and technical-trader condition. For
copying, it is one leader versus sixteen at those same settings. Compare each
following condition with its own no-following control to assess investor benefit
and market change. Cross-mechanism differences are descriptive unless source
streams and timing have been explicitly matched.

Also report Buy fractions, active-order fractions, signed desired and executed
imbalances, agreement between sources, and the concentration of completed
trades. These distinguish more activity from more synchronization and a sell
shift from a general tendency to agree. Agreement conditional on both sources
being active complements unconditional agreement, which can be dominated by
Hold. Do not divide by zero; report absent denominators as missing alongside
counts.

Secondary outcomes include Sell-majority probability and first-passage time,
non-follower wealth and drawdown, leader-follower return gaps, suppression due to
trader resources, rejected buys, fill rates, trader and dealer holdings, and
the persistence of changes after withdrawal. Preserve the paper's definition
of Sell majority as an interior Sell fraction of at least one half. Do not call
that event a price crash. Report a Buy majority separately. Unreached majority
times are right-censored; do not replace them with the endpoint when averaging
onset times.

The cohort comparison estimates the total effect of introducing following into
that market, including feedback on prices and leaders. Individual traders in
one simulation are not independent experimental replicates. A leader-follower
gap alone is not the causal benefit of copying: the paired no-following
comparison supplies that counterfactual.

The present model fills orders at one standing price within each step. It can
generate leader-follower differences from delays, resources, rationing, and
price feedback, but has no spread, fees, or separate execution prices within a
batch. Report gross simulated investment outcomes. Claims about net real-world
profitability require additional assumptions and evidence.

Use a benefit-versus-risk plot rather than one combined score. A positive mean
return with worse lower-tail outcomes is a trade-off, not an unconditional
benefit. If a descriptive label such as "little material change" is used, set
equivalence margins before confirmation. Proposed simulation-scale margins are
one percentage point of normalized wealth or drawdown and five percentage
points of rejection or non-follower Sell fraction. These are reporting choices,
not economically calibrated thresholds. Use confidence intervals to distinguish
supported differences, supported equivalence, and unresolved effects; failure
to detect a difference does not establish equivalence.

**Liquidity diagnostic.** Quoted wealth can rise while it becomes difficult to
sell. For preselected endpoint states, run a separate wind-down branch: stop
ordinary decisions and copying, request one-share sells from every trading
agent with shares at each step, retain the same dealer and rationing rule, and
permit no new trader buys or outside funding. End when all trader shares have
sold or a step completes no trades. Report cash recovered and unsold shares
separately for each cohort. This is a simultaneous-exit stress scenario, not
the main return measure or an estimate of fair value. Never value trapped
holdings at zero merely because the wind-down cannot sell them.

## 4. The experiments that identify the mechanism

The following controls are required for the corresponding claim. They should
use preselected conditions, including at least one weak-response condition;
they must not be limited to visually dramatic trajectories.

| Control | What it resolves | Interpretation limit |
|---|---|---|
| Technical traders held versus active | The added contribution of the technical-trader price channel | Holding them does not remove all financial feedback from executed-trade copying |
| Desired-decision copying versus completed-trade copying | Whether execution changes the signal followers observe | Both are explicit model variants; only the latter is the principal trade-copying model |
| Frozen source tapes versus live leaders | Effects of allowing leaders' signals to respond to followers | Replayed signals are an intervention, not a live platform model |
| Mask followers' influence on neighbors, with source tapes fixed | Whether imposed follower decisions transmit through local interactions | This deliberately changes observation and must be reported as a control |
| Following stops after 1,000 treated steps | Whether the induced behavior persists without continued following | Persistence over the remaining window does not establish permanent instability |
| Capacity zero and unlimited | Clearing identities and the endpoints of execution capacity | A flat price at zero capacity follows from the existing executed-imbalance price rule |

For replay controls, collect the sixteen leaders' action tapes in the matched
no-following run. Assign the same tapes to different numbers of followers,
holding each tape's complete time series fixed across capacity treatments when
the specific estimand requires it. Record the capacity and technical-trader
condition that generated each tape. The default common-source comparison uses
tapes generated at `h = 1` under the specified technical-trader condition; do
not quietly regenerate them for every tested capacity. Replay desired-decision
and completed-trade tapes as separately labeled source types.

For the local-transmission control, non-followers observe each follower's
matched no-following state when that follower enters their neighborhood sum.
They observe actual states at non-follower sites. Followers still place their
treated orders and sources remain fixed. This removes the direct local channel
from follower states while preserving the forcing and execution. First test
with the technical traders held. Under those conditions and fixed external
sources, non-follower decisions should reproduce their control trajectories;
their finances can still differ. With active technical traders, remaining
differences can also travel through price. Do not apply this attribution to
live leaders without first fixing their source tapes.

**Critical implementation distinction:** the existing `held_lattice` shortcut
omits finance because ordinary local decisions do not use it. Executed-trade
copying breaks that independence. Capacity affects leader fills, which affect
followers' next decisions. Price can also affect eligibility through the cash
needed to buy. Run the full financial simulator for the new campaigns, including
the held condition. For synthetic exogenous advice with technical traders held,
decision histories should still be invariant to capacity and holdings when
source tapes and initial grids are identical; use that as a separate test.

## 5. Staged campaign and replication budget

The default principal setting is `L = 64`, a 1,000-step warm-up and 3,000 treated
steps, `lambda = 0.02`, initial price 100, cash 1,000 and ten shares per trader,
the cost-basis restriction disabled, and the current technical-trader
configuration. Use the existing per-trader dealer-capacity definition.

| Factor | Core levels |
|---|---|
| Follower fraction `a` | 0.05, 0.10, 0.20, 0.40 |
| Equally subscribed sources `K` | 1, 4, 16 |
| Dealer capacity `h` | 0.1, 1, unlimited |
| Technical traders | Held, active |
| Source mechanism | Synthetic advice, completed-trade copying |
| Additional advice control | Independent stream for each follower at every `a`, `h`, and technical-trader condition |
| No-following controls | One per starting market, capacity, and technical-trader condition |

This is 144 treatment cells for the two mechanisms plus 24 independent-advice
cells, or 168 cells per design replicate. No-following controls are shared
where truly identical. Capacity is set from initialization in this campaign;
therefore each capacity has its own warm-up and its own paired control. Compare
treatment effects across capacities, not unmatched raw endpoints. A targeted
same-start capacity intervention can be added if a claim specifically requires
separating post-intervention capacity from its earlier effects on holdings.

**Stage A: specification and verification.** Implement the event and observation
contracts and run hand-checkable cases plus the existing regression suites.
Freeze the protocol version and generate a manifest enumerating every pilot
condition before simulations. Acceptance is correctness and reproducibility,
not a desired market response.

**Stage B: pilot.** Use ten starting markets and two independent assignment/tape
replicates per market: `168 * 10 * 2 = 3,360` treatment runs plus
`10 * 3 * 2 = 60` distinct no-following controls, or **3,420 runs**. Use market
seeds 610001 through 610010, with separate named random streams for assignments
and recommendations. Report every pilot cell, effects and uncertainty, source
activity, resource exhaustion, and the rate of missing denominators. Do not
declare a threshold from ten starting markets.

If signals are mostly absent, copying collapses into Hold, or resources exhaust
before the intervention can be studied, report that mechanism explicitly.
Instrument or revise the protocol for a documented reason, then version and
repeat the pilot. A null effect with adequate activity is an admissible finding;
it is not a reason to insert a stronger Sell bias or search indefinitely for a
crash. A pilot memo fixes the final grid, primary estimands, equivalence margins,
diagnostic conditions, and figure selection before confirmation data are read.

**Stage C: confirmation.** Default to fifty fresh starting markets and four
assignment/tape replicates per market, using market seeds 620001 through 620050.
The unchanged full grid requires `168 * 50 * 4 = 33,600` treatment runs and 300
distinct no-following controls, or **33,900 runs**. This is the full core budget,
excluding separately manifested diagnostic campaigns. These are fifty
independent starting-market clusters with four design replicates each, not two
hundred independent markets. Pilot data are exploratory and are not pooled into
the confirmatory estimates. Any change to the grid or sample size is recorded
before inspecting confirmation outcomes.

**Stage D: mechanism and sensitivity checks.** Freeze a diagnostic slice after
the pilot using both low and high adoption and concentration. Run the controls
in Section 4, extend those trajectories to 10,000 treated steps, and test
`L = 32, 128` and `lambda = 0.005, 0.05`. Record every diagnostic job and its
sample size in a separate manifest before launch. Longer horizons reuse the
same histories; they are not new replicates. Keep capacity per trader when
changing size and state that absolute dealer resources then grow with the
market. A claim of generality beyond the original rule also requires a
prespecified second rule environment; otherwise bound the conclusion to the
baseline used here.

The default diagnostic slice is `a = 0.10, 0.40`, `K = 1, 16`, `h = 1,
unlimited`, and both technical-trader conditions. Use the confirmation markets
and design replicates for matched controls and extensions. Vary one additional
mechanism at a time; do not multiply every sensitivity into a full factorial.
Use the same slice for wind-down branches. All diagnostic counts are additional
to the core budget and must be enumerated in the pilot memo before launching
confirmation. Revise this slice prospectively only if the pilot identifies a
specific design deficiency, documenting the reason and retaining a weak-response
comparison.

**Stage E: choices people and platforms can make.** After the main mechanisms
are understood, evaluate concentration and staggered copying delays of 1, 5,
and 20 steps, both common delays and fixed heterogeneous delays among followers.
A common delay does not itself diversify simultaneous reactions. At a fixed
source pool size, compare equal attention with a skewed follower allocation,
reporting actual `C` and realized action agreement. These experiments test
possible mitigations without assuming that any is beneficial.

Add a leader-selection experiment to address "copying winners": rank the
sixteen candidates using normalized return during the final 500 warm-up steps,
then freeze the chosen leaders at intervention. Compare top-ranked and randomly
chosen leaders with equal subscriber counts and identical follower resources.
Use only pre-intervention information and record pre-selection drawdown and
holdings. If warm-up rankings are degenerate, report ties and use predetermined
random tie-breaking; do not invent skill distinctions. Larger followings test
whether observed gains survive scale. Rolling re-selection, popularity-driven
attachment, and leader-to-leader copying are subsequent extensions because
they change the network and the source process simultaneously.

Stage E is secondary to the core confirmation. Stage D must support whichever
mechanistic or robustness claims enter the paper; Stage E is not a prerequisite
for reporting the primary comparisons, including null results.

## 6. Statistical analysis and presentation

Analyze treatment effects within a starting-market and design-replicate block.
Retain the same no-following cohort labels for each contrast. Estimate
concentration effects within those blocks, then summarize over starting markets.
Use 2,000 bootstrap resamples of complete starting-market clusters, keeping all
assignment/tape replicates, fractions, capacities, source conditions, and
technical-trader conditions together. Do not resample individual traders as if
they were independent markets, or duplicate shared controls as new observations.
Report sensitivity to the finite number of design replicates; expanding that
number needs a prospectively recorded sampling decision.

Report mean paired effects with 95% cluster-bootstrap intervals, medians and
interquartile ranges of run outcomes, and the full response curves. Majority
probabilities use the same clustered analysis; a binomial interval treating all
four design replicates as independent would overstate precision. An all-zero
event sample produces a degenerate ordinary bootstrap interval and needs a
separate bound. For that case, record whether any design replicate transitioned
within each independent market and use its exact one-sided 95% binomial upper
bound, `1 - 0.05^(1/G)` for `G` all-zero market clusters. This also conservatively
bounds the marginal per-replicate transition probability. Apply the analogous
failure bound for all-one samples. Zero events do not prove impossibility.
Avoid a fitted transition threshold unless the sampled curve brackets it;
never extrapolate an onset fraction or call it an asymptotic critical point.

The primary analysis is effect estimation. Mark intervals as pointwise when
they are pointwise. Any claim that an effect holds across the whole adoption
curve requires a simultaneous cluster-bootstrap band. Any collection of formal
significance tests must declare its family and correction before confirmation;
do not select significant parameter cells as the headline. If equivalence
labels are used, require the entire paired 95% interval to fall inside the
frozen equivalence margins. This is a conservative reporting rule; an interval
that merely crosses zero is an unresolved result, not demonstrated equivalence.

Use a deterministic example-selection rule fixed before confirmation: within
each displayed condition choose the run nearest the subgroup median primary
outcome, breaking ties by market seed and design replicate. Include a weak or
null-response example. Report all outcomes from all cells in tables even when
the narrative focuses on selected comparisons.

Proposed figures, with final manuscript numbers assigned only at integration:

| Figure | Panels and purpose |
|---|---|
| Shared decisions and their spread | Small intervention diagram; imposed recommendation/order agreement; paired non-follower Sell response; majority probability versus adoption |
| Who gains and who can trade | Follower benefit versus market drawdown; follower and non-follower return distributions; leader-follower gaps; rejected sales and wind-down cash/unsold shares |
| Mechanism and mitigation, supplementary by default | Live versus replayed sources; desired versus executed copying; withdrawal histories; diversified assignments and delays |

Use consistent cohort identities, post-intervention windows, and fraction units
throughout. Show uncertainty and zero reference lines. A synthetic-source
concentration plot and a live-copying plot should not suggest that their advice
quality or source marginals have been matched when they have not.

## 7. Implementation map

Build on the current Julia simulator and its counter-based rationing. Keep the
default configuration, existing result type, and old campaign behavior intact.
Do not fork a second financial simulator whose clearing logic can drift.

| File or directory | Proposed work |
|---|---|
| `code/src/Simulate.jl` | Optional typed decision override and observation hooks; optional per-agent fill buffer in `execute_orders!`; preserve the old return value and default path |
| `code/src/Types.jl` | Add separate following-protocol/diagnostic types without changing positional construction of existing result objects |
| `code/src/Following.jl` (new) | Source streams, leader/follower assignments, lag buffers, protocol validation, and the overlay contract |
| `code/src/FollowingMetrics.jl` (new) | Streaming cohort and individual wealth statistics, order outcomes, source agreement, and paired-analysis inputs |
| `code/src/Include.jl` | Load the new types and helpers in dependency order |
| `code/following/Following-Lib.jl` (new) | Campaign configs, manifests, unique control keys, checkpoint validation, and exact prehistory checks |
| `code/following/Compute-Following.jl` (new) | Explicit smoke/pilot/confirmation drivers with resume support |
| `code/following/Compute-Following-Controls.jl` (new) | Replay, transmission masking, withdrawal, delay, leader selection, and wind-down campaigns |
| `code/following/Analyze-Following.jl` (new) | Paired estimates and cluster-bootstrap intervals from saved run/cohort data |
| `code/following/Figs-Following.jl` (new) | Diagnostic and paper figures using `PaperStyle.jl`; draft outputs kept separate until integration |
| `code/following/Test-Following.jl` (new) | Behavioral, financial, timing, and reproducibility checks |
| `code/following/README.md` and `code/data/README.md` | Commands, definitions, data provenance, and campaign status |
| `code/run_all.sh` | Add explicit following-test/pilot/confirmation/figure modes without launching the new campaigns through existing figure-only commands |

`execute_orders!` currently exposes aggregate counts and the final simulation
result exposes final trader books, not complete individual histories. Add an
optional preallocated signed fill buffer, cleared each step, and populate it
where settlement actually occurs. Desired and eligible orders need distinct
records; do not infer every unfilled order to be a dealer rejection. Obtain
cohort suppression/rejection counts from eligibility and settlement, and verify
their sums against the existing aggregate counts.

Keep memory proportional to trader count plus a bounded history buffer for
ordinary runs. Maintain wealth peaks, individual drawdowns, cumulative fills,
and cohort statistics online. Save full individual trajectories and dense
source/baseline-state tapes only for manifested diagnostics; save endpoint
cohort distributions and required rank-window measurements for ordinary runs.
Majority crossing times and primary summaries must use every step, even when
displayed trajectories are thinned.

For each shared no-following run, evaluate every cohort mask needed by its
planned design replicates and adoption fractions, or save the individual
summaries needed to reconstruct those cohort statistics exactly. This keeps a
single control trajectory without losing the distinct matched populations.
Begin recording leader events during warm-up, retaining enough history for the
largest requested lag before the intervention starts.

Use distinct deterministic random namespaces for initial market, leader pool,
follower permutation, source assignment, source transitions, and diagnostic
choices. Adding advice randomness must not shift the established initialization
or rationing draws. Do not use a process-dependent language hash to seed the
streams. Threaded runs write into predetermined job slots; serialize checkpoint
and figure output. Network or provider APIs are not needed for the core study.

Save a versioned manifest plus run summaries, cohort summaries, selected
trajectories, source diagnostics, paired contrasts, and bootstrap summaries.
Each row carries market seed, design replicate, source type, adoption, nominal
and actual concentration, capacity, technical-trader condition, lag, source
parameters, protocol version, and the paired control identifier. Include code
revision and relevant source-file digests, environment lockfile digest, manifest
digest, and source-tape provenance. Resume must reject incompatible protocols
or code, not merely matching filenames. Validate completeness and uniqueness
before analysis. Existing production CSVs must not be overwritten.

## 8. Verification and completion checklist

- [ ] A zero-follower protocol reproduces the original simulator's prices,
  decisions, fills, books, and dealer histories exactly, with hooks both absent
  and enabled but inactive.
- [ ] All paired paths agree through the 1,000-step warm-up. Different design
  replicates do not change that warm-up.
- [ ] A hand-built leader sequence verifies one-step lag, sign-to-state mapping,
  no repeated stale event, and no copying of unexecuted trades. A desired-order
  variant demonstrably differs when the leader cannot execute.
- [ ] No follower observes a same-step future action. All simultaneous overrides
  read frozen histories. Withdrawal restores the local rule without resetting
  cash, shares, price, bands, or cohort labels.
- [ ] Reported decision fractions and majority times use the overlaid states
  that generated orders, not provisional local updates. Hand-built timing cases
  check the first treated step and the first step after withdrawal.
- [ ] Per-agent fills reconcile with aggregate fills; desired orders split into
  suppression, dealer rejection, and execution; total cash and shares are
  conserved, and finite trader/dealer limits hold.
- [ ] Capacity-zero and unlimited cases satisfy their clearing identities.
  Copied fills still pass through the follower's own constraints.
- [ ] Synthetic streams satisfy the specified marginal and persistence process
  and source sharing in seeded diagnostic ensembles. Deterministic extreme
  cases verify one common source and independent-source assignment without
  fragile single-sample statistical assertions.
- [ ] With fixed external tapes and technical traders held, changing finances
  leaves decision histories identical. A completed-copying example demonstrates
  why this identity is not expected for live executed sources.
- [ ] With fixed sources, held technical traders, and masked follower influence,
  non-follower decisions exactly match their no-following trajectories.
- [ ] Wealth and drawdown arithmetic passes hand-calculated portfolios, including
  identical wealth after a trade before repricing and changed marked wealth
  after repricing. Wind-down never silently discards unsold shares.
- [ ] Serial and threaded jobs produce identical summaries. Checkpoint resume
  neither duplicates jobs nor accepts an incompatible source/code version.
- [ ] Bootstrap blocks retain the experimental dependence structure; missing
  denominators and censored onsets remain explicitly represented. All-zero and
  all-one event samples receive the specified finite-sample bounds.
- [ ] Existing simulation suites pass with `bash code/run_all.sh tests`; the
  existing figure-helper suite passes with
  `julia --project=code code/test/runtests.jl`; the new following suite passes.
- [ ] Pilot memo, frozen confirmation manifest, complete confirmation data,
  mechanism controls supporting the stated claims, analysis tables, and reviewed
  figures are available before numerical manuscript claims are written.

The new suite verifies a behavioral and financial model change, rather than
adding tests merely for documentation or plotting edits. The commands above are
implementation acceptance checks; they have not been run to validate a simulator
extension that does not yet exist.

## 9. How this enters the paper

Aim for one coherent extension to the paper: shared decisions can affect people
outside the following group, and trading resources determine both execution
and the distribution of investment outcomes. The data may support amplification,
attenuation, or little change. Write the conclusion from the confirmed contrasts,
including mixed effects and null results.

Add contemporary motivation to the Introduction, the two source protocols and
new outcome definitions to Methods, and at most two focused main figures with
their Results paragraphs. Keep technical controls and wider sensitivity grids
in the supplement. If the investor-performance and leader-selection analyses
require a much larger model or narrative, develop them as a companion paper
rather than burying the existing decision/execution result. Decide that scope
from the pilot memo and the final experimental design, not from which results
look most favorable.

Follow `HOUSE_STYLE.md` during integration. The present six-paragraph Results
structure is a convention for the current paper; record an explicit revision
to that structure when adding new results. Preserve the decisions-versus-price
distinction, finite-horizon interpretation, and generated-file workflow. Do not
rename existing Sell-majority measurements as crash probabilities. Verify new
bibliography metadata against Crossref or the primary institutional record
before adding BibTeX. Build and visually inspect the changed manuscript pages
and figures using the established paper workflow.

Four verified starting sources, with deliberately limited roles:

- The [Financial Stability Board's 2024 report](https://www.fsb.org/uploads/P14112024.pdf)
  identifies common models/data and correlated trading as potential financial
  stability vulnerabilities. It motivates the concentration question; it does
  not supply an empirical calibration for our model.
- [Apesteguia, Oechssler, and Weidenholzer, *Copy Trading*, Management Science,
  2020](https://jose-apesteguia.github.io/CopyTrading.pdf),
  DOI `10.1287/mnsc.2019.3508`, reports increased risk-taking in its laboratory
  setting when participants could copy. It motivates separate investor-risk
  outcomes, not a claim that all copying is harmful.
- [Hansen and Lee, *Financial Stability Implications of Generative AI: Taming
  the Animal Spirits*, FEDS 2025-090](https://www.federalreserve.gov/econres/feds/financial-stability-implications-of-generative-ai-taming-the-animal-spirits.htm)
  finds behavior sensitive to the experimental setting and instructions. It
  supports leaving the direction of AI-related effects open.
- [Joseph et al., *When Influence Misleads*, 2025 preprint](https://arxiv.org/abs/2507.01817)
  studies the distinction between popularity and performance in social trading.
  It motivates the secondary leader-selection comparison; identify its
  preprint status when discussing it.

Before claiming novelty, compare the precise estimands and execution assumptions
against these papers and the imitation models already cited in the manuscript.
The proposed contribution is the paired separation of source concentration,
transmission, execution, and cohort outcomes, not the introduction of imitation
to agent-based finance.

Actual AI-generated recommendations are a later validation layer. If pursued,
fix the observable market information and action schema, save complete prompts,
model/version identifiers and outputs, measure recommendation agreement, and
replay those outputs through the already verified simulator. Keep that layer
separate from the synthetic mechanism experiment. It requires its own protocol
and does not turn the present plan into a claim about deployed AI systems.

**First implementation milestone:** reproducible source assignments, a verified
one-step copy mechanism, reconciled individual fills, and paired wealth
measurement. The first scientific milestone is the complete pilot report for
both mechanisms, with a frozen confirmation protocol and a decision about which
claims the evidence can support.
