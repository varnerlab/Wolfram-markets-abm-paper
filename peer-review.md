# Simulated Peer Review

**Manuscript:** A local rule switch destabilizes a cellular automaton market model with finite dealer capacity
**Author:** Jeffrey D. Varner (Cornell University)
**Reviewed against:** `paper-arxiv/Paper_v1.tex` at commit `0870d82` (26 pp., 6 figures, 4 supplementary tables, 164 bib entries)
**Assumed venue tier:** mid-to-high-tier computational/complexity outlet (*Journal of Economic Dynamics and Control*, *Quantitative Finance*, *Physica A*, *JASSS*, *Physical Review E*)

> **Note on reviewer selection.** The reviewer personas supplied with the `/peer-review` skill are
> written for a metabolic-engineering manuscript (FBA/FVA/sampling, CFPS, Hopfield networks) and
> name *Metabolic Engineering* / *PLoS Comput Biol* as the target venues. Those personas cannot
> produce accurate critique of a cellular-automaton market model, and the skill's own domain-accuracy
> rule forbids inventing claims outside the reviewer's competence. The three-tier severity structure,
> the review format, and the 95%-confidence rule are preserved exactly; the expertise has been
> mapped to this paper's field.

---

## Reviewer 1 (Moderate) — Agent-based computational economics / complex systems

### Summary

The paper asks whether switching one entry of a local update rule, mid-run, can destabilize a market
model that was stable immediately beforehand, and separates that spatial question from the financial
constraints that translate it into a price move. The paired design, in which a switched path and a
matched no-switch path evolve from a bit-identical realized state, is the paper's main methodological
contribution and it is executed carefully. I am broadly positive: the central experiment is sound and
unusually well controlled, but the generality of the result rests on a single rule pair, and several
reported quantities are quoted more precisely than the sampling design supports.

### Strengths

1. **The paired mid-run intervention is genuinely well controlled.** Both paths share the lattice,
   trader books, dealer ledger, quote, adaptive bands, and target sites through step 1,000, and the
   appendix reports that pre-switch equality was asserted bit-for-bit for every pair, including the
   Sell-fraction history, edge coordinates, band widths, and the price history through the first
   post-switch quote. Most ABM papers that claim a counterfactual do far less than this.

2. **The held-boundary control yields an exact null, not a statistical one.** The finding that the
   held-boundary lattice path is bit-identical across all dealer capacities and across all nine
   cash-share interventions within a cell is a much stronger statement than "no significant
   difference," and it cleanly licenses the claim that financial variables reach the lattice only
   through price feedback.

3. **Prespecified selection of displayed runs.** Choosing the time-sliced panels from ensemble
   summaries *before* inspecting any lattice image, with a stated tie-break rule (nearest the subgroup
   median onset for crossing runs, nearest median final Sell fraction otherwise), removes the usual
   worry that the pretty lattice pictures were cherry-picked. This deserves to be highlighted rather
   than buried in the Methods.

4. **The separation of agent suppression from dealer rejection is a real contribution.** Distinguishing
   an order that never enters the market (trader lacks cash or shares) from an eligible order the
   dealer cannot absorb is the paper's most transferable idea, and the appendix is right that collapsing
   them would let a financial constraint silently rewrite a behavioral state.

5. **Honest disclaimers.** The paper explicitly declines to claim classical nucleation (no free-energy
   barrier, activation rate, surface tension, or critical droplet) and explicitly declines to claim an
   equilibrium critical point from five sizes at a fixed horizon. This restraint is welcome and I would
   not want it weakened in revision.

### Weaknesses

1. **One rule pair supports the entire generality claim.** The results rest on Rule 19280 to Rule 19286,
   differing at the single sum c=1. The Discussion acknowledges this and even proposes the fix, but the
   paper as written cannot distinguish "single-entry rule switches destabilize this model" from "this
   particular entry does." Since c=1 is reached only by the unique neighborhood of three Buy cells and
   one Hold cell, the switched entry is also the least ambiguous entry in the whole table, which may make
   it unrepresentative. *Fix:* screen the single-entry neighbors of the baseline systematically (see
   Requested Analyses 1); this is a small amount of compute and would convert the central claim from an
   instance to a class.

2. **Four-decimal midpoints and widths are quoted from a coarse grid.** The interpolated midpoints
   (0.2181, 0.1926, 0.1777, 0.1681, 0.1665) and widths (0.0275 down to 0.0082) carry four decimals with
   no uncertainty attached, but each underlying probability is a binomial estimate on 50 seeds whose
   standard error near p=0.5 is about 0.07. *Fix:* bootstrap over seeds and report the midpoint and
   width with intervals, or reduce the reported precision to what 50 seeds supports.

3. **The transition threshold is never varied.** A run counts as transitioned when the interior Sell
   fraction reaches 0.5 at least once. Since crossing runs end with final-window means of 0.81 to 0.87,
   I expect the results are robust, but the paper should demonstrate rather than assume this. *Fix:* a
   one-paragraph sensitivity check at thresholds 0.4 and 0.6, reported in the appendix.

4. **The economic reading of the rule table is left to the reader.** The paper states that the numerical
   state labels enter the dynamics through both the neighborhood sum and the rule table, but never
   argues why a trader's next action should depend on the arithmetic sum of neighbor labels. A reader
   from economics will want one or two sentences connecting the totalistic form to an interpretable
   behavioral story, even if the answer is that it is a deliberately minimal abstraction.

5. **Reproducibility gap in the deposited artifact.** `code/data/*.csv` is excluded by `.gitignore`,
   and while roughly forty derived files were force-added, `ModelB-RuleQuench-Full-Summary.csv` was
   not. That is the source for Table S2, so the median onsets and the paired-switch probabilities
   cannot be regenerated from a fresh clone. *Fix:* add the file, or state in the appendix which
   campaign script regenerates it.

### Questions for Authors

1. Is the activation window a property of the c=1 entry specifically, or of single-entry perturbations
   to this baseline generally? Have you looked at any other entry, even informally?
2. Rule 19280 sends c=0 to Sell, so an all-Buy lattice is unstable while all-Sell is absorbing. How
   close is the baseline steady state (interior Sell fraction near 0.25) to the basin boundary, and does
   the switch move the system across a boundary that was already nearby?
3. The no-switch controls never transition in 3,000 steps. Do they ever transition at much longer
   horizons, or is the baseline genuinely metastable on all reachable timescales?
4. Why 1,000 baseline steps? Is the pre-switch state stationary by then, and how was that checked?

### Requested Experiments / Analyses

1. **Single-entry rule screen.** Hold the baseline fixed and, for each of the eight other neighborhood
   sums, switch that entry to each of the two alternative outputs, running the same paired protocol at
   a few fractions on L=64. This is on the order of a few hundred additional runs and directly answers
   the generality question the Discussion raises.
2. **Threshold and horizon sensitivity.** Report transition probability at majority thresholds of 0.4,
   0.5, and 0.6, and report how the L=64 transition curve moves between horizons of 3,000 and, say,
   9,000 post-activation steps.
3. **Bootstrap intervals on the interpolated quantities.** Resample seeds with replacement, recompute
   the midpoint and width per resample, and report percentile intervals in Table S3.

### Minor Comments

1. The Results state that capacity h=10 reproduced the unlimited path, and Fig. 2's caption says the
   series is omitted for that reason. Consider plotting it as a dashed overlay so the reader sees the
   coincidence rather than being told about it.
2. "Dealer capacity had a larger effect on drawdown and rejected orders than on the spatial transition"
   is the paper's summary of a result that includes a factor of 2.4 in transition probability at
   f=0.175. Consider softening or quantifying the comparison.
3. Table S3 reports the fraction at the susceptibility peak, but that fraction is a sampled grid point,
   so its resolution is the grid spacing. Worth a footnote.
4. The Conclusion is a single short paragraph; for this venue a slightly fuller close, naming the two
   questions and their answers, would serve the reader better.

### Recommendation

**Minor Revision.** The core experiment is sound and the controls are strong. The rule screen and the
uncertainty quantification are the two things I would want before publication, and both are inexpensive.

---

## Reviewer 2 (Hard) — Nonequilibrium statistical mechanics, lattice models, finite-size analysis

### Summary

The paper reports a finite-time crossover in a three-state totalistic cellular automaton subjected to a
mid-run single-entry rule switch, and claims the crossover sharpens with system size while explicitly
declining to claim an equilibrium critical point. The paired protocol and the exact held-boundary
invariance are done properly. My concerns are quantitative: the headline finite-size numbers are
reported at a precision the sampling grid cannot resolve, the fixed observation horizon is confounded
with system size, and several structural parameters that determine the reported price magnitudes are
never varied.

### Strengths

1. The exact invariance of the held-boundary lattice to dealer capacity, and to all nine balance-sheet
   interventions, is a genuine exact null and is the strongest single piece of evidence in the paper.
2. The rationing scheme is well designed for a paired study: a SplitMix64 score keyed by seed, step,
   trader, and side gives reproducible priority without consuming draws from the generator that built
   the lattice, and including the step prevents a trader from holding permanent priority.
3. Reporting the ensemble susceptibility with an explicit definition, and refusing to fit a critical
   exponent to five sizes, is the correct call and I would resist any reviewer pressure to reverse it.
4. Conservation of cash and shares is checked separately before and after the intervention jump, with
   the residual reported.

### Weaknesses

1. **The reported transition widths are at or below the local grid resolution, and the grid resolution
   differs systematically between the two ends of the size series.** This is my central objection. At
   L=32 the held-boundary curve has six sampled fractions strictly between 0 and 1, at local spacing
   0.010 to 0.025, and the quoted width is 0.0275. At L=128 there are only **three** interior points
   (f=0.160 at p=0.10, f=0.170 at p=0.72, f=0.175 at p=0.98) at local spacing 0.005 to 0.010, and the
   quoted width is 0.0082. Both widths are comparable to or smaller than the spacing that produced
   them, and f25 and f50 at L=128 are both obtained by linear interpolation inside the *single*
   interval [0.160, 0.170]. The reported narrowing by a factor of 3.4 is therefore confounded with the
   grid being two to three times finer, in absolute terms, where the L=128 transition happens to fall.
   I believe the qualitative sharpening is real, because the susceptibility peak grows independently,
   but the quoted magnitudes are not supported. *Fix:* adaptively refine each size's grid until a fixed
   number of points (at least five) lie strictly between p=0.05 and p=0.95, then recompute widths and
   attach bootstrap intervals.

2. **Linear interpolation of a sigmoid across a 0.10-to-0.72 probability jump is a strong shape
   assumption.** The Methods state the interpolation is linear. Across an interval where the
   probability rises by 0.62, the true curve is markedly convex, so the quartile crossings are
   systematically misplaced by an amount that is not estimated. *Fix:* fit a monotone parametric form
   (probit or logistic in f) per size, report the fitted midpoint and width with standard errors, and
   show the fit against the sampled points.

3. **The observation horizon is fixed at 3,000 post-activation steps for every lattice size.** Domain
   growth to a majority is a coarsening process whose time to span the system grows with L, yet the
   window in which a run may cross is held constant. The measured midpoint therefore mixes a genuine
   size dependence of the threshold with a size-dependent probability of *finishing in time*. The
   Discussion lists size-scaled horizons as future work, but the finite-size midpoints are presented as
   a result in the present tense. *Fix:* rerun at least L=32 and L=128 with horizons scaled as L^z for
   two values of z, and show that the midpoint ordering is preserved.

4. **The price-impact coefficient is fixed at a single value and drives every reported price
   magnitude.** The Methods give lambda = 0.02 with no sensitivity analysis, and none of the four
   campaigns varies it. Every drawdown number in the paper, including the 0.40% to 25.3% span that the
   abstract and Discussion lean on, scales with this choice. *Fix:* a one-dimensional sweep in lambda
   at f=0.20 across three dealer capacities, reported in the appendix, showing whether the *ordering*
   in h is invariant even though the magnitudes are not.

5. **The susceptibility is plotted on logarithmic axes while a scaling fit is declined.** Fig. 3D shows
   peak susceptibility against lattice size on log axes, which invites the reader to extract a slope
   (the sampled values imply roughly L^1.7), while the caption states that no asymptotic scaling law
   was fitted. This is somewhat having it both ways. *Fix:* either attach the apparent slope with an
   honest uncertainty and an explicit statement that it is a finite-size effective exponent, or plot on
   linear axes.

6. **No uncertainty is propagated into any interpolated quantity.** Wilson intervals are computed for
   the raw probabilities, which is correct, but f50, the width, and the susceptibility peak are all
   reported as point values. Given 50 seeds this is the dominant unreported uncertainty in the paper.

### Questions for Authors

1. What is the standard error on the peak susceptibility? A variance estimated from 50 seeds carries a
   relative error near 20%, which is comparable to some of the differences between adjacent sizes.
2. Is the susceptibility computed on the final 500-step window mean for every size, and if so, has the
   final window equilibrated at L=128 within a 3,000-step horizon?
3. Does the transition curve at fixed L converge as the horizon grows, and if so at what horizon?
4. Why 50 seeds? Was this chosen from a power calculation, or by compute budget?
5. The finite-size campaign uses per-trader dealer capacity, so absolute capacity scales as L^2. Was a
   fixed-absolute-capacity series also run, and does it change the size trend?

### Requested Experiments / Analyses

1. **Adaptive grid refinement near the transition, per size,** to at least five interior points per
   curve, followed by recomputation of all midpoints and widths with bootstrap intervals. This is the
   single most important addition.
2. **Horizon-scaling check** at L=32 and L=128 with horizons proportional to L and to L^2, to separate
   threshold drift from a finishing-in-time artifact.
3. **Sweep in the price-impact coefficient** at f=0.20 over at least three values spanning a decade,
   for h in {0.1, 1, infinity}, reporting whether the ordering of drawdowns in h is preserved.
4. **Parametric fit of the transition curves** with reported standard errors, replacing or supplementing
   the linear interpolation.

### Minor Comments

1. The susceptibility definition uses the prefactor (L-2)^2, the interior site count, which is correct
   and should be stated as such in words next to the equation.
2. Table S3 mixes conditions with different dealer capacities in one block; a horizontal rule between
   condition groups is already present, but a column giving the number of interior points behind each
   width would make the resolution issue visible to the reader.
3. "Peak ensemble susceptibility increased from 21.2 to 232.7 while moving from f=0.225 to f=0.170"
   compresses two distinct findings into one clause; consider splitting.
4. State explicitly whether the 3,000-step horizon was fixed before the campaigns were run.

### Recommendation

**Major Revision.** The physics is plausible and the controls are sound, but the quantitative
finite-size claims as written are not resolvable by the design that produced them. Items 1 and 2 in
Requested Analyses must be addressed before I could support publication.

---

## Reviewer 3 (Very Hard) — Market microstructure and agent-based finance; author of competing models

### Summary

The paper claims a causal, within-model demonstration that activating one local behavior destabilizes a
market path, and that dealer capacity governs the price consequence rather than the spatial instability.
The engineering is careful. My difficulty is with what the design actually establishes: in a
deterministic model whose two arms differ only in the intervention, divergence is guaranteed by
construction, so the counterfactual apparatus proves less than the framing implies. Several results that
complicate the headline narrative are reported but not confronted, and one modeling choice at the core
of the model is left undefended.

### Strengths

1. The bit-identical pre-switch verification is real and is more than most comparable papers provide.
2. Distinguishing agent-suppressed from dealer-rejected orders is a contribution I would use, and the
   claim that an unlimited counterparty is a consequential rather than neutral assumption is well made.
3. The paper resists the two overclaims most available to it, classical nucleation and an equilibrium
   critical point, and says plainly what its evidence does not establish.

### Weaknesses

1. **The counterfactual framing is over-dressed for a deterministic model.** The paper invokes
   potential-outcome methods, common random numbers, and damage spreading to justify a paired design in
   which the two arms differ *only* in the rule at the target sites, and everything downstream is
   deterministic. Under those conditions any divergence is attributable to the intervention by
   construction; no inference is required. What the design genuinely delivers is the *dose-response
   relation* between the switched fraction and the outcome, and the magnitude of the effect, which is
   valuable and does not need the causal-inference scaffolding. *Fix:* recast the contribution around
   the threshold in f and the separation of stages, and reduce the potential-outcomes framing to a
   sentence.

2. **The critical missing control is a behaviorally neutral perturbation of the same size.** The paper
   controls against *no* perturbation (no-switch) and against *no price feedback* (held boundary), but
   never against *a different perturbation of equal magnitude*. Without that, the reader cannot tell
   whether the cascade is specific to what Rule 19286 does at c=1 or whether pushing any fraction f of
   sites toward Sell, by any means, produces the same window. *Fix:* run at least two null
   interventions at matched f: a one-time forcing of f sites into the Sell state with no rule change,
   and a switch of f sites to a single-entry variant at a different neighborhood sum. If the activation
   window survives both, the claim is much stronger; if the one-time forcing reproduces it, the paper's
   central story changes materially.

3. **The non-monotone dealer effect is reported and then set aside.** At f=0.175 under the endogenous
   boundary, transition probability runs 0.34 at h=0, rises to a peak of 0.66 at h=0.1, and then falls
   monotonically through 0.56, 0.48, 0.30, 0.30, 0.28 to 0.28 at h=infinity. A *small* dealer therefore
   roughly doubles the transition probability relative to both no dealer and an unlimited one. That is
   the most surprising result in the paper and it is disposed of in one clause ("The response was not
   monotone in dealer capacity"). It also sits awkwardly with the summary claim that dealer capacity had
   a larger effect on drawdown than on the transition, since a factor of 2.4 in transition probability
   is not a small effect. My suspicion, which the authors are better placed to test, is that the
   adaptive band is responsible: an unlimited dealer produces large sustained price moves that inflate
   the moving absolute deviation, widening the band and returning boundary traders to Hold, whereas a
   small dealer produces moves that stay large *relative* to a small deviation. *Fix:* rerun the
   capacity sweep with the band half-width frozen at a constant, and report whether the peak survives.

4. **The totalistic form conflates economically distinct neighborhoods.** With Buy=0, Hold=1, Sell=2 and
   a four-neighbor sum, a site surrounded by two Holds and two Buys sees the same c=2 as a site
   surrounded by one Sell and three Buys, and must respond identically. These are very different local
   market conditions. I note that the switched entry itself is exempt, since c=1 is reached only by
   three Buys and one Hold, and the authors correctly say so; but the baseline dynamics within which the
   switch acts are built on the conflated entries. The paper needs either a defense of the totalistic
   restriction or a demonstration that a non-totalistic rule with the same c=1 behavior gives the same
   result.

5. **No comparison to any existing model, and the scope disclaimer is doing heavy lifting.** The paper
   cites Lux-Marchesi, Bornholdt's Ising market, Kirman, and prior cellular-automaton market models, and
   then declines comparison on the grounds that its question is narrower than reproducing stylized
   facts. That is a legitimate scoping move, but it means no reader can situate the magnitude of the
   effect against anything. At minimum, the paper should state what the baseline rule's stationary
   interior Sell fraction is, what the unconditional return distribution looks like before activation,
   and whether the pre-switch dynamics resemble any published model's calm regime.

6. **"None of the matched no-switch controls reached a Sell majority" is a bounded statement presented
   as an unbounded one.** It holds over 3,000 post-activation steps. Since all-Sell is absorbing and
   c=0 maps to Sell, the reader needs to know whether the baseline is genuinely stable or merely slow.
   *Fix:* run a small number of no-switch controls to 10^5 steps and report the outcome.

### Questions for Authors

1. What happens if you force f sites into the Sell state once, without changing any rule? If the
   lattice converts, what remains of the claim that the *rule* is the operative change?
2. What is the mechanism of the non-monotone peak at h=0.1, and does it survive a fixed band width?
3. Is Rule 19286's only attractor the all-Sell absorbing state, and if so, does f control whether the
   system reaches it or merely how fast?
4. Why should the response depend on the arithmetic sum of neighbor labels rather than on the counts of
   each state? Would a rule defined on the (n_Buy, n_Hold, n_Sell) composition change the conclusions?
5. The abstract claims the work shows an unlimited counterparty is a consequential modeling assumption.
   Consequential for what class of models, and what would a reader of a standard price-impact model
   change on the strength of this evidence?

### Requested Experiments / Analyses

1. **Matched null interventions** at the same f: one-time forced Sell seeding without a rule change,
   and a single-entry switch at a different neighborhood sum. This is the experiment I most want to see
   and it is inexpensive.
2. **Fixed-band control** for the dealer-capacity sweep, to test whether the non-monotone peak is an
   artifact of the adaptive normalization.
3. **Long-horizon no-switch controls** at L=64 to establish whether the baseline is stable or merely
   metastable on the studied timescale.
4. **A composition-based rule variant** reproducing the same c=1 behavior but defined on state counts,
   run at three fractions, to test the totalistic restriction.

### Minor Comments

1. The abstract says "switched paths converted the lattice above a narrow band of activated fractions."
   Given the non-monotone dealer result, "narrow band" is doing more work than the data supports under
   the endogenous boundary; consider qualifying.
2. The title asserts that a local rule switch destabilizes "a cellular automaton market model." Given a
   single rule pair, "a" is carrying an implicit generality the paper does not yet establish.
3. Fig. 5 shows four conditions for one seed. One seed is an illustration, not evidence; the caption
   should say so explicitly.
4. The claim that h=10 reproduced the unlimited path is stated for "the stated endowments and horizon";
   good, but the appendix should say what would break it.

### Recommendation

**Major Revision.** The paper is careful and honest about several things it cannot claim, which I
respect. But without a matched null intervention (Requested Analysis 1) I do not think the central
claim is established as being about the *rule* rather than about any perturbation of that size, and
the non-monotone dealer result needs an explanation rather than a mention.

---

## Summary of Actionable Items

Consolidated across all three reviews, deduplicated, ordered by priority. Reviewer attribution in
brackets.

### Tier 1 — Required before publication

1. **Matched null interventions at equal f.** One-time forced Sell seeding with no rule change, plus a
   single-entry switch at a different neighborhood sum. Establishes that the effect is about the rule
   rather than about any perturbation of that magnitude. [R3-2, R3-Exp1; overlaps R1-1]
2. **Single-entry rule screen** over the eight other neighborhood sums and both alternative outputs,
   paired protocol at a few fractions on L=64. Converts the central claim from an instance to a class,
   and is the experiment the Discussion already proposes. [R1-1, R1-Exp1]
3. **Adaptive grid refinement per lattice size** until at least five sampled fractions lie strictly
   between p=0.05 and p=0.95, then recompute every midpoint and width. As it stands, L=128 has three
   interior points and its width is derived largely from a single grid interval, while L=32 has six at
   two-to-three-times coarser absolute spacing, so the reported narrowing is partly a resolution
   artifact. [R2-1, R2-Exp1]
4. **Bootstrap intervals on all interpolated quantities** (midpoint, width, susceptibility peak), and
   reduce reported precision to match. [R1-2, R2-6, R1-Exp3]
5. **Explain or diagnose the non-monotone dealer effect** (transition probability peaking at h=0.1 with
   0.66 against 0.28 at h=infinity, at f=0.175), including a fixed-band control to test whether the
   adaptive normalization produces it. [R3-3, R3-Exp2]

### Tier 2 — Strongly recommended

6. **Horizon-scaling check** at L=32 and L=128 with horizons growing with L, separating threshold drift
   from a finishing-in-time artifact under the fixed 3,000-step window. [R2-3, R2-Exp2]
7. **Price-impact coefficient sweep** at f=0.20 across three dealer capacities, showing whether the
   ordering in h survives even though magnitudes do not. [R2-4, R2-Exp3]
8. **Long-horizon no-switch controls** to establish whether the baseline is stable or merely metastable,
   given that all-Sell is absorbing. [R3-6, R3-Exp3]
9. **Parametric (probit or logistic) fits of the transition curves** with standard errors, replacing or
   supplementing linear interpolation across a probability jump of 0.62. [R2-2, R2-Exp4]
10. **Defend or test the totalistic restriction**, which forces identical responses to economically
    distinct neighborhoods at every entry except the switched one. [R3-4, R3-Exp4]

### Tier 3 — Framing and presentation

11. **Recast the causal framing.** In a deterministic two-arm design the divergence is attributable by
    construction; lead with the dose-response threshold and the stage separation instead. [R3-1]
12. **Quantify or soften the "dealer capacity affects price more than transition" summary**, which
    coexists with a factor of 2.4 in transition probability at f=0.175. [R1-Minor2, R3-3]
13. **Report pre-switch baseline characterization** (stationary interior Sell fraction, pre-activation
    return distribution) so the calm regime can be situated against published models. [R3-5]
14. **Threshold sensitivity** at 0.4 and 0.6 alongside the 0.5 majority criterion. [R1-3, R1-Exp2]
15. **Add one or two sentences of behavioral interpretation** for the totalistic rule form. [R1-4]
16. **Reconsider the title's implicit generality** given a single rule pair. [R3-Minor2]

### Tier 4 — Housekeeping

17. Force-add `ModelB-RuleQuench-Full-Summary.csv` so Table S2 is regenerable from a clean clone.
    [R1-5]
18. Plot h=10 as a dashed overlay in Fig. 2 rather than omitting it with an explanatory caption.
    [R1-Minor1]
19. Add a column to Table S3 giving the number of interior points behind each width. [R2-Minor2]
20. State explicitly in Methods that the 3,000-step horizon and the 50-seed count were fixed in advance.
    [R2-Minor4, R2-Q4]
21. Note in Fig. 5's caption that a single seed is an illustration rather than evidence. [R3-Minor3]
