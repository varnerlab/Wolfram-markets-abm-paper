# Cold external read for a Physical Review E submission

Date: 2026-08-05

## Bottom line

I would not submit the present version yet. The paper contains a potentially interesting PRE story—a deterministic cellular automaton with quenched heterogeneity, rare-region escape, and spatial domain growth—but several of the strongest physical conclusions currently outrun the experiments or the analysis. A skeptical referee could reasonably argue that the paper has demonstrated a striking sell-domain phenomenology without yet establishing the proposed nucleation mechanism, the Avrami interpretation, a finite-size scaling law, or the claimed separation between birth and budget-gated growth.

The paper is unusually candid about many limitations, which helps. The remaining problems are not mainly missing caveat sentences. The highest-risk ones require either new controls/reanalysis or a narrower central claim.

My expected outcome if this exact manuscript went to PRE is major revision at best, with meaningful risk of a negative report or editorial rejection on physics significance. The fastest route to a defensible PRE paper is to center the contribution on quenched-disorder CA dynamics and rare-region conversion, make the market language explicitly an interpretation, and treat the endogenous budget/intervention section as a model-specific mechanism rather than a liquidity-policy result.

### The three already-known issues

I treated these as known rather than rediscovering them:

- Endogenous-model grid-size robustness.
- Genericity beyond one rule pair.
- The cash-injection result at \(p=0.064\).

They still need resolution, but the findings below are independent of them. In particular, even a significant injection result would not repair the baseline confound or the current “front velocity” metric.

## Submission gate: the issues I would resolve before sending this to PRE

| Priority | Issue | Minimum defensible response |
|---|---|---|
| P0 | Important initial conditions and campaign differences are omitted | Disclose them in a model/campaign table and run targeted initial-condition robustness checks |
| P0 | The analytical closures anneal the rule labels, unlike the quenched simulations | Carry rule type through the closure, or sharply narrow what the present negative theory result means |
| P0 | The Avrami exponent is being used as mechanistic proof without establishing KJMA assumptions | Add time-origin/window sensitivity and direct nucleation/growth measurements, or make the Avrami fit descriptive only |
| P0 | The finite-size section is system-size dependence, not finite-size scaling, and the \(L=32\) anomaly is not explained | Analyze pseudo-threshold/horizon scaling and rare-region hazards; do not dismiss \(L=32\) using a cluster threshold absent from the conversion metric |
| P0 | The escape-time curves discard much of the censored information and fit 3 parameters to 5–6 medians | Fit individual event/censor records, compare alternative laws, and resample the shared seed structure correctly |
| P0 | Birth-site and seeding evidence does not establish “birth is cheap” | Use a simulation-based spatial null, acknowledge paired disorder landscapes, and establish a working positive-control seed dose |
| P0 | Injection and withdrawal are run from different baseline regimes | Run both directions from matched baselines and separate boundary mediation from the direct boundary cells counted in the outcome |
| P0 | “Crash” is usually a grid-state label rather than a price crash | Reframe the central observable as a sell-domain transition and reserve “price crash” for trajectories that actually fall |
| P1 | Rule, volatility-band, population, and denominator definitions do not match the implementation precisely | Correct the specification and add a denominator/update-order table |
| P1 | PRE positioning and reproducibility packaging are incomplete | Convert to a referee-friendly APS layout, add a formal data/software statement, archive a versioned release, and repair the literature positioning |

## P0 scientific issues

### 1. The campaigns do not share the initial conditions the narrative suggests

This is the clearest reproducibility omission I found.

The endogenous model does **not** start all-Hold. Its default is `:balanced_perturbation`: exactly 5% of interior cells start Buy and another 5% start Sell, with the boundary Hold. This is set in `code/src/Factory.jl:214-246` and constructed in `code/src/Factory.jl:310-360`. The targeted nucleation, escape-time, seeding, and cash-toggle configurations inherit those defaults through `code/model-b/NucleationConfigs-Lib.jl` and `code/model-b/Compute-ModelB-Nucleation-EscapeTime.jl`. The manuscript never states this 10% initial perturbation.

The finite-size campaign uses a third initial condition: every cell is drawn uniformly from \(\{0,1,2\}\), then evolved for a 200-step burn-in before the recorded clock starts (`code/model-a/FiniteSize-Lib.jl:13,98-112,173-182`). That differs from both the all-Hold, QQQ-forced Model A illustration and the 5%/5% Model B initialization. On periodic boundaries with no forcing, all-Hold is a stationary configuration, so the random initial mixture is not a cosmetic detail—it supplies the activity from which the reported conversion can occur.

This weakens several cross-section statements. The paper currently reads as if the QQQ crossover, the periodic finite-size campaign, and the endogenous runs are comparable realizations of the same interior mechanism with only boundary/price closure changed. They actually change forcing, boundary conditions, initial state distribution, burn-in, lattice size, horizon, and cluster denominator at the same time.

What to do:

- Add a compact campaign table with lattice size, boundary condition, forcing, initial state distribution, burn-in, horizon, rule assignment, state-fraction denominator, cluster region, onset threshold, and number of independent disorder landscapes.
- State the 5% Buy + 5% Sell Model B initialization in Methods and every targeted campaign caption where it matters.
- State the uniform-three-state initialization and 200-step burn-in in the finite-size Methods and Figure 3 caption.
- Run at least a small robustness grid for the finite-size and endogenous headline results: lower/higher balanced perturbations, alternative state proportions, and more than one burn-in/time origin. If the transition requires a particular initial mixture, make that basin dependence part of the result.
- Do not describe the two models as “directly comparable” without listing the dimensions on which they differ.

### 2. The negative theory result does not isolate geometry

The mean-field and pair calculations explicitly replace the quenched rule assignment by an annealed stochastic rule: at every relevant update, rule type is effectively redrawn with probability \(f\) (`paper-arxiv/sections/appendix.tex:7-19`). The simulations instead assign a permanent rule label to each location. This is not a minor approximation when the proposed mechanism is a favorable *quenched cluster* of contrarian sites.

The present closure loses two things at once:

1. spatial state correlations; and
2. correlations between a site’s fixed rule type, its state, and neighboring rule types.

Therefore, the closure’s failure cannot support the sentence that pair correlations “erase exactly what the lattice supplies,” nor can it show that correlations beyond pairs or domain geometry are the missing ingredient. The missing ingredient may already be the rule label that the closure annealed away.

A quenched one-site closure should at least track \(p_s^{(M)}\) and \(p_s^{(C)}\), the state distribution conditional on majority/baseline versus contrarian rule type. A corresponding pair closure should track state × rule-type pairs (a 6-state pair object, reducible by symmetry). Even if that model still fails, it would be an informative failure because it preserves the disorder/state correlation central to the mechanism.

There is a second overreach. The pair appendix establishes local stability of one product fixed point and iterates a small family of correlated initial conditions: three same-state-correlation strengths on a few marginal distributions and 13 values of \(f\) (`paper-arxiv/sections/appendix.tex:91-119`). That is not a global fixed-point search and does not exclude saddle-node branches, other basins, cycles, or more complicated attractors in a synchronous nonlinear map. The sentence “the pair approximation therefore supports no correlated fixed point, the negative result on which the nucleation argument rests” is much stronger than the calculation.

One suspected problem did *not* survive checking: the product state constructed from the mean-field branch is a fixed point of the implemented pair map to numerical precision. Do not spend time “fixing” that part.

What to do:

- Preferred: implement the rule-type-resolved mean-field and pair closures, then perform numerical continuation or a broad simplex/basin search, including cycles.
- At minimum: rename the present theory “annealed mean-field and annealed pair closures” everywhere and say only that no instability or correlated fixed point was found in the tested closure and initial-condition family.
- Report the Jacobian on the normalization-constrained tangent space. Six symmetric entries have one normalization constraint, so the intrinsic simplex is five-dimensional even if six stored coordinates are used.
- Remove the claim that the calculation proves geometry beyond pairs is necessary unless the quenched pair closure also fails.

### 3. The finite-size section is not yet a finite-size scaling analysis

The current campaign demonstrates system-size dependence over a fixed horizon. It does not estimate a thermodynamic threshold, a scaling exponent for a pseudo-critical point, or a common finite-size scaling function. Calling it “finite-size scaling” invites a statistical-physics referee to ask for exactly those objects.

The most direct internal problem is \(L=32\). In the committed summary:

- At \(f=0.13\), conversion counts are 15/20, 0/20, 0/20, 2/20, and 5/20 for \(L=32,64,128,256,512\).
- At \(f=0.14\), they are 19/20, 0/20, 10/20, 20/20, and 20/20.

Thus, “larger lattices crashed at lower contrarian fractions” is not monotone over all five stated sizes. The text calls \(L=32\) anomalous because a fixed 100-cell cluster occupies a large fraction of that lattice, then excludes it from the Avrami conversion-curve fits. But the conversion observable and the Avrami fit do not use the 100-cell cluster threshold. That threshold cannot explain why the \(L=32\) *conversion probability* is anomalous or justify excluding its transformation curves. This will be obvious to a careful referee.

The statement that every lattice above a spreading threshold “converts eventually” is also unproved. A finite deterministic CA eventually reaches a fixed point or cycle; finiteness alone does not put every realization in the all-Sell basin. The data establish conversion within \(10^5\) steps for sampled cells, not eventual conversion with probability one.

The rare-region explanation is plausible and gives a better test than the current brittle-fracture analogy. If approximately independent regions nucleate at an areal hazard \(h(f)\), a first approximation is

\[
P_{L,T}(\text{conversion}) \simeq 1-\exp[-L^2 H(f,T)],
\]

with corrections for growth time, correlations, and periodic geometry. That prediction can be tested across both \(L\) and observation horizon \(T\). It would turn the size effect from a visual analogy into a physical result.

What to do:

- Call the present result “system-size and observation-window dependence” until an actual scaling analysis exists.
- Estimate a pseudo-threshold \(f_{1/2}(L,T)\), with intervals, over multiple horizons rather than one \(T=10^5\).
- Test a per-area escape hazard or survival collapse and report departures from independent-region scaling.
- Include \(L=32\) in the scientific account. Explain its basin structure or small-system dynamics rather than attributing it to an unused cluster threshold.
- Fit the CV scaling rather than drawing an anchored \(N^{-1/2}\) guide. The log-log slopes are close to \(-1/2\) in \(N\) over the five sizes for the fully converted cells, but uncertainty with only 20 seeds and the all-converted selection rule should be shown.
- Do not use “critical,” “phase boundary,” “discontinuous transition,” or “every lattice eventually” unless supported by the corresponding scaling/bifurcation evidence.

This is separate from the already-known need to repeat the **endogenous** budget campaigns across grid sizes.

### 4. The Avrami exponent does not currently prove site-saturated nucleation

The argument “\(n\approx2\) says vulnerable regions were fixed before the clock started” is too strong. Classical KJMA/Avrami identifications such as \(n=d\) for site saturation and \(n=d+1\) for continuous nucleation require assumptions about homogeneous nucleation, time-independent rates, isotropic growth, approximately constant front speed, and how impingement is handled. The model has a square-lattice anisotropy, quenched heterogeneous rules, synchronous deterministic dynamics, an arbitrary post-burn-in time origin, irregular clusters that merge and split, and no direct demonstration of constant interface velocity.

More basically, a fixed contrarian arrangement is a fixed landscape of *potentially vulnerable regions*, not a set of transformed supercritical nuclei already present at \(t=0\). Actual successful nuclei can still be born throughout the transient. The exponent alone cannot distinguish those concepts.

The fitting code adds several sensitivities that the paper does not discuss (`code/model-a/FiniteSize-Lib.jl:230-260`):

- The metastable baseline is the median of the first 10% of the *observed record*. Records stop early after sell fraction exceeds 0.95, so the baseline window length depends on the run’s conversion time.
- There is no fitted incubation/time-origin parameter \(t_0\), although the clock starts after an arbitrary 200-step burn-in.
- The regression uses only transformed fractions \(0.05\le X\le0.90\) and a log-log linearization. Window choice can materially change \(n\).
- High \(R^2\) for a monotone sigmoid after transformation is not mechanistic validation.
- Rescaling every trajectory by its *own fitted* \(K\) makes the collapse partly a consequence of fitting. It is not an independent test of universality or size invariance.

The committed fit table also contains important heterogeneity hidden by Figure 3’s pooled collapse. On \(L=512\), mean \(n\) changes systematically from 2.541 at \(f=0.16\) to 2.316, 2.122, and 1.914 at \(f=0.17,0.18,0.20\). On \(L=64, f=0.16\), the fitted values range from 0.353 to 4.699 and mean \(R^2\) is only 0.649. At \(L=128, f=0.16\), mean \(n=3.249\) with a standard deviation of 1.655 and a maximum of 8.716. The largest lattice is much cleaner, but the data support a parameter- and size-dependent effective sigmoid exponent, not a universal \(n=2\) law.

There is published precedent warning that excellent Avrami fits can yield erroneous kinetic interpretations: Erukhimovitch and Baram, “Nucleation and growth transformation kinetics,” *Physical Review B* 51, 6221 (1995), [doi:10.1103/PhysRevB.51.6221](https://doi.org/10.1103/PhysRevB.51.6221).

What to do:

- Fit a generalized form with \(t_0\), and report sensitivity to the baseline definition, fit window, burn-in, and stopping rule.
- Report distributions/intervals of \(n\) and \(K\) by both \(L\) and \(f\), not just largest-lattice means and a pooled visual collapse.
- Test a held-out collapse: estimate \(K\) or the scaling function from one size/subset and predict other sizes, rather than rescaling each run by its own fitted parameter.
- Directly measure the birth-time distribution of successful domains and an interface-based growth rate. Those are the quantities the \(n=2\) versus \(n=3\) interpretation is standing in for.
- If those additions are not feasible, say the trajectories are well summarized by a compressed-exponential/Avrami form with an effective exponent near 2 on the largest lattices. Remove the inference that this proves all nuclei were present at the outset or that “birth is cheap.”

### 5. “Kramers-type” and “stochastic waiting time” are misleading for this deterministic ensemble

Within a run, there is no dynamical noise. The random seed selects an initial condition, edge parameters, and a quenched rule landscape; the subsequent trajectory is deterministic. Across seeds, the paper observes a distribution of deterministic hitting times over disorder realizations. Figure S2’s phrase “stochastic nucleation waiting times” should be replaced by “disorder-induced variation in deterministic escape times” or similar.

Kramers theory says that an escape time is exponential in a barrier-to-noise ratio. It does not, by itself, derive

\[
\log\tau=A+B/(f-f_0)
\]

for this CA. The current manuscript now calls the curve phenomenological in several places, but “inverse-distance form of Kramers-type escape problems,” “barrier law,” and the repeated \(f_0\) language continue to import a mechanism that was not derived. A high \(R^2\) among a few selected points does not distinguish this essential-singularity form from alternatives.

Use “empirical inverse-distance curve” consistently unless a coarse-grained stochastic theory produces it. Define metastability operationally as a long-lived ensemble plateau or basin, not as thermal fluctuation around an equilibrium.

### 6. The censoring analysis uses only part of the censored information

The appendix correctly records all cell-level censoring counts, and a Kaplan–Meier median under a common administrative horizon is valid when it exists. The problem occurs in the next stage.

For Model B, the inverse-distance regressions use only the 5, 6, and 6 \(f\)-values whose onset rate reached 0.5, then fit three parameters. Low-\(f\) cells with 60–100% censoring determine that their median is undefined, but none of their event times or censoring contributions enter the regression. “Censored runs were never dropped” is therefore true inside each cell’s KM calculation but misleading for the fitted onset law.

For Model A, the problem is stronger: the mean-lifetime fit discards every \(f\) at which even one seed did not convert within the horizon. That is a complete-cell analysis, not a censored escape-time fit.

Other concerns:

- Three-parameter curves fit to 5–6 median points have little residual information; the high \(R^2\) and parameter confidence intervals can look much more decisive than they are.
- The same seed numbers are reused across \(f\), and lower/higher \(f\) rule layouts share the same random stream and are effectively nested. The single-cash bootstrap resamples seeds independently within each \(f\), breaking that cross-\(f\) dependence. The equivalence script correctly pairs cash arms *within* an \(f\), but still draws a different seed index vector at each \(f\).
- The refinement grid was chosen after the pilot and extended again to obtain enough finite medians. This is reasonable exploratory design, but it should not be presented as a confirmatory fit.
- A factor-of-two equivalence margin is broad and needs a scientific justification. “Fixed in advance” should be used only if there is a dated protocol established before examining the relevant outcome; an analysis-script comment is not external preregistration.
- The equivalence result applies to predicted medians from the assumed inverse-distance curves at shared finite-median \(f\)-values. It does not establish cash indifference below that region, and it inherits any misspecification of the curve.

What to do:

- Fit the individual `(time, event)` records with a discrete-time hazard, parametric survival/AFT model, or a likelihood tailored to the deterministic-disorder ensemble.
- Compare inverse-distance, power-law, exponential, and flexible monotone alternatives using held-out or information-criterion performance. Do not select by \(R^2\) alone.
- Resample the complete seed trajectory across \(f\) as a cluster where the same random seed/landscape construction is reused. Preserve the cash pairing.
- Show raw KM survival curves with uncertainty and risk counts, not only fitted medians.
- Justify the factor-two margin physically, and state the tested range exactly. If the result remains model-dependent, say “no difference larger than the prespecified factor-two margin was resolved over the shared tested range,” not “onset proved indifferent.”

### 7. The birth-site test cannot establish a uniform birth process

The statement “bulk-dominated and consistent with a uniform distribution” currently rests on 3 of 39 founders lying within distance 2 of the boundary, versus a uniform-interior probability of 0.125, with a binomial \(p=0.47\). There are three problems.

First, failure to reject this one-bin null is not evidence of uniformity. It only says the small sample does not resolve enrichment or depletion in that shell. The full distance distribution is visibly structured and should be tested as such, with uncertainty.

Second, a uniform-cell null is not the relevant physical null. Even if the active boundary does not template births, local rule composition, the initial-state field, lattice geometry, and the evolving background make candidate cells have unequal hazard. The relevant comparison is a simulated or risk-set null conditional on those fields—e.g., founders under a frozen/neutral boundary, or each founder compared with cells at risk in the same disorder landscape and time.

Third, the 39 observations are not 39 independent disorder landscapes. Freeze and collapse runs reuse the same 20 seed numbers at the same \(f\), hence share initial fields, edge locations/bands, and rule layouts; cash changes the subsequent path. Treating the pooled 39 births as independent binomial trials understates dependence. Analyze the two cash arms as paired outcomes on 20 landscapes or cluster uncertainty by seed.

The founder genealogy is also algorithm-dependent. It follows a maximum-overlap chain backward through merge/split events with a gap tolerance. The strip-generation code documents that, among 11 deep-birth collapse candidates, the dense forward lineage from the reported founding cell died before onset in 9 cases; only 2 met the “lineage survives to onset” filter, and the displayed seed is the one of those closest to the overall median onset (`code/model-b/Compute-ModelB-StripFrames.jl:27-44,180-220`). That is a valid way to choose an illustration of a surviving lineage, but the filtering is not disclosed in the manuscript and it shows that the identity of a unique founding cell is not robust in most candidates.

What to do:

- Analyze all distance shells or the continuous distance distribution, with a paired/clustered uncertainty calculation by seed.
- Replace the uniform-cell null with a matched simulation null that retains the quenched fields and changes only the boundary mechanism being tested.
- Report founder sensitivity to lineage rules, merge/split handling, and one-step gaps. Consider an all-ancestor graph rather than one maximum-overlap path.
- Disclose the Figure 5 exemplar filter. Better, show several prespecified/random examples or an aggregate survival-of-lineage statistic.
- Replace “the winning nucleus was an interior single-cell fluctuation that happened to survive and grow” with a statement that does not assume a unique robust ancestor unless the genealogy analysis supports it.

### 8. The stamped-patch experiment lacks a working positive control

A 3×3 Sell patch placed at one fixed edge, mid, or center location dies in every run and never becomes the largest onset cluster. That shows those particular patches are subcritical under those placements and initial times. It does not show that birth is abundant, that position is irrelevant, or that the model would respond to a viable nucleus.

The statement “the experiment that settled the point is a null with a working lever, since the stamped patches did grow for a while” is referee bait. Growth from 9 to 15 cells before extinction is not a positive control that the intervention can create a supercritical nucleus. With 0/20 successes, the upper uncertainty bound is not zero.

The patch is also always stamped at \(t=0\), before the mixed attractor/background has developed, and each distance category uses one deterministic location. Local contrarian composition around the patch is uncontrolled. Figure S5’s literal phrase “no placement advanced onset” is contradicted by many individual paired lines; what is true is that no placement produced a consistent or multiplicity-adjusted advancement.

What to do:

- Run a seed-size dose response until at least one size is a reliable positive control.
- Randomize multiple positions within each distance stratum and condition on the local rule composition.
- Stamp after a common mixed-state burn-in as well as at \(t=0\).
- Report success probabilities and intervals, not only 0/20 counts.
- Say “no consistent/statistically resolved onset advancement” rather than “no placement advanced onset.”

### 9. The injection/withdrawal “asymmetry” is confounded by baseline configuration

Leaving the known \(p=0.064\) issue aside, the directional comparison is not symmetric:

- Injection is cash ×10 from the tight cash-500 **freeze** baseline.
- Mild and harsh withdrawals are cash ×0.1 and ×0.01 from the loose cash-5000 **collapse** baseline.

Those controls already have different price paths, boundary states, suppression, cluster growth, and onset behavior. Direction is therefore inseparable from baseline regime. Two withdrawal doses on the same loose baseline rule out only a narrow under-dosing explanation; they do not establish a general injection/withdrawal asymmetry.

Run a crossed design with both injection and withdrawal from both baselines (or a common intermediate baseline), including matched absolute post-toggle cash levels where possible. The estimand should include a direction × baseline interaction.

The intervention is also timed using the counterfactual control’s future onset. That is a legitimate in-silico paired mechanism test, but it is an oracle-timed counterfactual rather than an implementable policy. Keep that distinction explicit.

### 10. “Front velocity” is not what the code measures

The main dose-response metric is the OLS slope of the largest Sell-cluster **area fraction** over an onset-aligned window. The toggle metric is an endpoint difference quotient of that fraction. These quantities have units of area fraction per step, not length per step, and can change when clusters merge, split, disappear, or exchange which cluster is largest. They do not necessarily follow the same physical interface.

This matters most in the injection result. The toggle cluster calculation scans the full grid, including boundary cells. Injection directly flips the active boundary ring to Sell—the proposed mediator—and then the outcome counts those directly manipulated Sell cells if they connect to the largest cluster. Part of the measured “faster front” can therefore be a direct consequence of counting the treatment region, not propagation through the interior.

What to do:

- Rename the present quantity “largest-domain areal growth rate.”
- Track the same lineage from just before the toggle, rather than taking the largest cluster independently at every time.
- Recalculate outcomes on strictly interior cells and, preferably, with a buffer excluding the forced edge.
- Measure an equivalent radius, perimeter, or interface-normal velocity if a physical front speed is central.
- Report sensitivity to the 5% onset threshold and the 50–400/400-step windows.

### 11. The boundary mechanism is consistent with the data, not isolated by them

The paper says the paired intervention “traced” growth gating to the boundary ring. The observed sequence—cash changes fills, fills change price, price changes band state, band cells become Sell, and the Sell domain grows—is consistent with that mechanism. It is not a mediation experiment because price, bands, boundary state, and full-grid cluster outcome all move together.

The clean tests are already suggested in the Discussion and should be performed rather than left as future predictions:

- Freeze the boundary state through onset and compare growth.
- Apply a matched price shift while shifting the EMA/bands with it, preventing classification changes.
- Force the edge-state flip without changing books or price.
- Clamp the boundary in Buy, Hold, and Sell states after onset.
- Recompute interior-only domain growth.

Without at least one of these, use “consistent with boundary mediation” rather than “traced to” or “exactly one channel.”

### 12. Suppression is an endogenous post-onset variable, not an identified causal dose

The negative correlation between suppressed buys and largest-domain areal growth is calculated over the same post-onset window. Both variables respond to the evolving grid, price, inventory, boundary state, and domain geometry. A larger/slower/differently located domain can itself change order demand and suppression. This makes reverse causality and common-cause confounding unavoidable.

The within-cash correlations and leave-one-dose-out checks show that the pooled sign is not solely a between-dose artifact. They do not make realized suppression “the causal variable,” as the Discussion calls it. Treat the result as a robust descriptive association unless suppression is independently randomized or instrumented.

An intervention on book constraints that changes suppression while holding boundary classification fixed would be much closer to the desired causal test.

## P1 interpretation and specification issues

### 13. The paper’s “crash” variable is usually not a market crash

The paper is admirably explicit in Results that “crash-prone” means Sell fraction ≥0.5 for at least 1% of steps, not a price drawdown. But the title, abstract, discussion, and physical language repeatedly convert that grid label back into “market crash.” In the modal crash-prone run, the median drawdown is about 5% and the median minimum price is 100; in the named collapse configuration, median final price is 119.54 after an earlier peak. A sell-state lock-in can coexist with a rising final price because inventories run out and the unmodeled market maker absorbs flow.

A PRE referee may accept the market analogy but will object if a “market crash” is defined by agent states rather than a price fall.

Recommended framing:

- Title/abstract: “sell-domain transitions” or “sell-state cascades” in a market-motivated CA.
- Use “price crash/collapse” only when a declared price-drawdown criterion is met.
- Separate the physical order parameter (Sell fraction/largest domain) from the financial observable (price/drawdown/return).
- If retaining “market crashes” in the title, define and validate the mapping much more strongly.

This reframing would also improve PRE fit: the physics contribution is the quenched-disorder spatial transition, while the market is the motivating interpretation.

### 14. Rule 19280 is not a majority rule in the ordinary sense

The rule acts on the numerical sum of labels, not counts of matching neighbors. Four Buy neighbors have sum 0 and cause Rule 19280 to output Sell. Three Holds plus one Buy have sum 3 and cause it to output Buy rather than the local majority Hold. The manuscript eventually discloses the all-Buy counterexample, but still calls the rule “majority/herding” throughout and says it adopts the dominant state.

This name biases the mechanism before it is demonstrated. Call it the “baseline sum-threshold rule” or simply Rule 19280. If keeping “herding-like,” quantify how often it agrees with the local modal state over all neighborhood compositions.

Also state clearly that Buy=0, Hold=1, Sell=2 is not a neutral label choice. Permuting the labels changes the dynamics because only the sum is used, and distinct neighbor compositions with the same sum are deliberately conflated. The \(3^9\) space is complete only for deterministic, translation-invariant, outer-totalistic maps of that encoded neighbor sum. It is not a complete behavioral-rule space in a broader CA or market sense.

### 15. The “volatility” band is an exponentially weighted mean absolute deviation

Equation (5) updates an EMA of \(|P_t-\hat S_t|\). That is not a standard deviation and the resulting classifier is not a standard Bollinger Band. The statements “\(k\) standard deviations,” “Bollinger Band filter,” and variable name \(\hat\sigma\) are technically wrong.

Also, \(\alpha=1/60\) is not uniquely “a 60-minute window.” An EMA has several window conventions: its mean age is about 59 steps, its half-life is about 41 steps, and its common span-equivalent is about 119. State the smoothing coefficient and one clearly defined effective-timescale convention.

Either implement an exponentially weighted variance/standard deviation or rename the quantity EWMAD and the classifier a custom EMA-deviation band.

### 16. The 61 QQQ sessions are concatenated for forcing but not for the benchmark

The Model A price series is processed as one continuous 23,790-step sequence, so the EMA and band carry across each overnight jump as if the next day’s 09:30 bar followed the previous 15:59 bar by one minute. The return benchmark later removes the 60 overnight joins and standardizes within session. These are different treatments of the same data.

State the concatenation explicitly and run a reset-at-session-open robustness check for the external forcing. Also justify the use of typical-price returns rather than close-to-close minute returns. The QQQ lag-one return autocorrelation of 0.30 is high enough that a referee may question whether bar construction/session handling contributes.

### 17. Rule fractions and outcome denominators vary across analyses

The paper says \(f\) is a fraction of interior agents. In both Model A and Model B implementation, minority rules are assigned among all \(L^2\) sites (`code/model-a/Compute-ModelA.jl:152-158`, `code/src/Simulate.jl:45-66`), including boundary sites that are overwritten or never updated. The expected interior fraction is still approximately \(f\), but its realized value is random rather than the exact stated fraction, especially at small \(L\).

The observable populations also change:

- Model A sweep fractions count the full grid, including active/passive boundary cells.
- Periodic finite-size fractions count all sites.
- Model B state fractions count strictly interior cells.
- Model B price imbalance divides by interior plus active edge traders.
- Most Model B onset/toggle clusters scan the full grid and divide by \(L^2\).
- The birth analysis labels only interior clusters but still uses a 5% threshold of the full \(L^2\) grid.

None of these choices is automatically wrong, but the paper moves among them without a single specification. At \(L=64\), the boundary is not negligible.

What to do:

- Assign rule types exactly among strictly interior sites in fixed-boundary models, or call \(f\) a nominal all-site assignment fraction and report realized interior \(f\).
- Add a denominator table and make the primary onset/domain measure consistent.
- Repeat headline cluster results with interior-only numerators/denominators and a boundary buffer.

### 18. Synchronous updating and boundary architecture are untested structural assumptions

All headline dynamics use synchronous updates, a Von Neumann neighborhood, and either periodic boundaries or a one-cell fixed/active frame. Synchronous CA can create fronts and cycles that change materially under random sequential or asynchronous updates. The claimed mechanism is also explicitly carried by a one-cell-deep boundary, which is an architectural choice rather than a generic market topology.

A full robustness program is large, but PRE reviewers are likely to want at least one alternative update scheme and one boundary topology. If these change the result, present the mechanism as architecture-specific rather than universal.

### 19. The Stage 2 regime classification is ordered and threshold-dependent

The classifier tests “crash-prone” before “oscillatory,” so the classes need not be mutually exclusive properties of the trajectories. A run satisfying both is always called crash-prone. The emptiness of inert, plateau, and drift categories therefore does not establish that the model intrinsically has only two regimes.

The 1% Sell-majority duration, 20 sign flips, and 10% price-range thresholds are ad hoc and have no sensitivity analysis. Report the overlap matrix of all predicates before applying priority, repeat the map over reasonable thresholds, and show continuous outcomes alongside class labels.

The 94–97% between-configuration variance statement is descriptive grouping by all 1,080 parameter combinations. The within-cell residual includes seed × configuration interactions and deterministic disorder effects; it is not a clean “seed contributes only 5.4%” causal partition. Keep the more careful “between-configuration share” language and report factor/main-interaction effects if the factorial design is meant to support parameter claims.

## Referee-bait phrasing to replace

| Current idea/phrase | Why it attracts an objection | Safer replacement |
|---|---|---|
| “majority/herding rule” | The rule is not a modal-state majority rule | “baseline sum-threshold Rule 19280” |
| “the only control parameter” | Many fixed parameters and six Stage 2 factors matter | “the focal heterogeneity parameter in this specified slice” |
| “nucleation and growth in the classical sense” | Classical KJMA assumptions are untested | “localized domain emergence and expansion consistent with a nucleation-and-growth analogy” |
| “every lattice above the spreading threshold converts eventually” | Not proved for a deterministic finite CA | “conversion probability increased within the tested horizon” |
| “size effect of brittle fracture” | Analogy is asserted before rare-region scaling is tested | “consistent with a rare-region/extreme-value mechanism” |
| “an exponent near 2 says…” | Effective Avrami exponent is not diagnostic here | “is compatible with, but does not establish, site-saturated kinetics” |
| “supports no correlated fixed point” | Limited annealed closure and initial-condition search | “no correlated fixed point was found in the tested annealed pair closure” |
| “stochastic nucleation waiting times” | Each run is deterministic | “disorder-induced distribution of deterministic escape times” |
| “birth is cheap” / “experiment settled the point” | Null result lacks a positive control and adequate spatial null | “the present tests did not identify seed availability as rate-limiting” |
| “rate indistinguishable from uniform” | Failure to reject is not equivalence | “no evidence against the specified uniform-shell null was resolved” |
| “front velocity” | Measured quantity is largest-cluster area slope | “largest-domain areal growth rate” |
| “no placement advanced onset” | Individual paired runs do advance | “no consistent or multiplicity-adjusted advancement was resolved” |
| “traced gating to the boundary” | Mediator not isolated; boundary is counted in outcome | “produced changes consistent with boundary mediation” |
| “causal suppression” | Suppression is a post-onset endogenous variable | “realized suppression was associated with growth” |
| “discontinuous transition” / “phase boundary” | No thermodynamic FSS, hysteresis, or bimodality result | “sharp finite-horizon crossover” |
| “same analysis extends to every rule” | Applicability is not demonstrated generality | “the finite rule set is amenable in principle to systematic enumeration” |
| “Bollinger Band” / “standard deviations” | Implemented width is EWMAD | “custom EMA–mean-absolute-deviation band” |
| “market crash” for Sell-majority | Price often does not crash | “sell-domain transition,” with price outcome reported separately |

The Discussion is the main rhetorical risk. Phrases such as “the lattice answered yes,” “birth is cheap,” “the experiment that settled the point,” “exactly one channel,” and “draws that line cleanly” read confidently but make the evidentiary gaps easier for a referee to attack. A more physical, less prosecutorial tone would help.

## Literature and PRE positioning

### 20. The most direct PRE precedents are missing

The paper claims awareness of three financial CA studies but omits at least two directly relevant papers already published in PRE:

- M. Bartolozzi and A. W. Thomas, “Stochastic cellular automata model for stock market dynamics,” *Physical Review E* 69, 046112 (2004), [doi:10.1103/PhysRevE.69.046112](https://doi.org/10.1103/PhysRevE.69.046112).
- G. Qiu, D. Kandhai, and P. M. A. Sloot, “Understanding the complex dynamics of stock markets through cellular automata,” *Physical Review E* 75, 046116 (2007), [doi:10.1103/PhysRevE.75.046116](https://doi.org/10.1103/PhysRevE.75.046116).

The bibliography cites a different Qiu et al. article in *Advances in Complex Systems*. The PRE paper is the venue-specific precedent a PRE editor/referee is most likely to know: it also uses a two-dimensional trader lattice, local rules, and price updating. The related-work section should cite both PRE papers and distinguish this manuscript by quenched deterministic totalistic-rule heterogeneity, spatial founder/front measurement, and budget feedback—not by implying CA finance is nearly absent.

Before submission, do a systematic literature search around cellular automata, kinetic spin/opinion models, quenched disorder, rare-region/Griffiths effects, first-passage scaling, and KJMA fits in deterministic lattice systems. “We are aware of three” is fragile phrasing unless the search is demonstrably complete.

### 21. The physics contribution needs to lead

PRE’s current scope explicitly includes collective/emergent phenomena, statistical and nonlinear physics, computational physics, and complex systems. Its author guidance also asks that the key results be contextualized for a broad physics readership ([PRE Information for Authors](https://journals.aps.org/pre/authors)).

The manuscript will fit PRE better if its hierarchy is:

1. A deterministic, three-state, quenched-disorder CA exhibits a finite-horizon rare-region crossover and spatial domain conversion.
2. The failure/success of type-resolved closures and the size/horizon scaling reveal what spatial information is required.
3. A market-motivated boundary and finite books provide one application-specific feedback architecture.

The current hierarchy often reverses this, making “market crash” and liquidity intervention the headline while the actual price process is intentionally uncalibrated. That increases desk-rejection risk because the economic interpretation is not strong enough to substitute for the still-incomplete statistical-physics analysis.

## PRE submission and reproducibility issues

### 22. Formatting is not a scientific blocker, but the present PDF is hard to referee

The compiled manuscript is 40 pages in NeurIPS preprint style with all figures and tables end-floated after the references. PRE regular articles currently have no length limit, and APS only requires a PDF for initial peer review, although REVTeX source is preferred ([PRE Information for Authors](https://journals.aps.org/pre/authors)). The issue is usability, not a formal page limit.

The rendered figures are generally clean, but Figures 4, S6, and S7 are small relative to the page, and many figure/table pages contain large empty regions. Separating every figure from its discussion makes an already technical causal chain difficult to audit. Figure S6’s nine panels are especially small.

Before submission:

- Convert to REVTeX 4.2 with the PRE option, or at least render a close approximation to the APS layout.
- Place figures near first discussion; do not use `endfloat` for the referee PDF.
- Enlarge small multi-panel figures and reduce caption density by moving methods into the text/appendix.
- Ensure every claim-critical result is in the main article or appendix. APS states that a paper must stand on its own without Supplemental Material.
- Add the contact-author footnote, acknowledgments, and funding information; the source still contains an internal “Add acknowledgments…” comment.

### 23. A formal data/software availability package is required

APS requires a Data Availability Statement and requires publicly shared data/software to be cited, preferably with a persistent identifier. Its guidance recommends established repositories rather than a mutable personal repository ([APS Data Availability Statements](https://journals.aps.org/authors/data-availability-statements)).

The current title footnote links a live GitHub repository but no release, DOI, or immutable commit. The top-level README is only two lines. `code/Manifest.toml` exists locally but is not tracked, while the instructions allow any Julia 1.9+ environment. The expensive campaign artifacts are committed, but the exact software environment and provenance of a publication snapshot are not yet archival.

The QQQ file is a specific risk: `code/data/README.md` says the vendor went offline and its license terms cannot be recovered, yet the raw data are committed under the repository’s MIT license. Determine whether redistribution is permitted. If rights cannot be established, do not silently distribute the file as MIT-licensed content; use an APS-compliant statement explaining third-party restrictions, provide checksums/derived data where allowed, and arrange private editor/referee access if necessary.

Before submission:

- Create a versioned Zenodo/OSF release with a DOI, exact commit, license boundaries, Julia version, locked Manifest, data dictionary, and one-command figure reproduction.
- Cite the data/software release in the reference list and Data Availability Statement.
- Expand the root README into a reviewer entry point: manuscript build, quick tests, figure rebuild, full expensive pipeline, expected runtimes/resources, and map from each figure/table to source data and script.
- Record which outputs came from which commit and whether any campaign was rerun after analysis decisions.
- Separate third-party raw QQQ data licensing from the license on code and author-generated outputs.

## Recommended revision sequence

### Phase 1: fix the specification before running anything expensive

1. Build the one-page campaign/specification table.
2. Correct the omitted initial conditions, burn-in, rule-assignment population, denominators, EWMAD terminology, and session handling.
3. Rename the core observables: sell-domain transition, empirical inverse-distance curve, largest-domain areal growth.
4. Remove or soften the referee-bait claims listed above.
5. Reframe the abstract/introduction around a quenched-disorder CA rather than a validated market-crash model.

### Phase 2: run the analyses most likely to change the paper’s central claims

1. **Quenched theory:** state × rule-type mean-field and pair closures, with broader bifurcation/basin analysis.
2. **Size/horizon:** multiple \(T\), explicit \(f_{1/2}(L,T)\), rare-region hazard scaling, and an explanation of \(L=32\).
3. **Avrami robustness:** \(t_0\), baseline/window/burn-in sensitivity, full \(L\times f\) uncertainty, held-out collapse, direct birth-rate and interface-growth measurements.
4. **Initial-condition/update robustness:** perturbation density/composition, synchronous versus at least one asynchronous scheme, and one alternate boundary construction.
5. **Intervention controls:** crossed direction × baseline design, interior-only lineage growth, and at least one direct boundary-mediation ablation.
6. **Birth controls:** paired simulation null, multiple randomized positions, seed-size dose response, and genealogy sensitivity.

### Phase 3: reanalyze statistics

1. Fit individual censored event records and compare onset-time models.
2. Cluster bootstrap by shared seed across \(f\), preserving cash pairing.
3. Justify or revise the equivalence margin and state its tested domain narrowly.
4. Treat suppression-growth as observational unless independently manipulated.
5. Report regime-predicate overlap and threshold sensitivity.

### Phase 4: make the PRE package

1. Add the direct PRE precedents and a broader targeted literature review.
2. Convert to REVTeX/referee-friendly figure placement.
3. Add acknowledgments, funding, contact-author metadata, and the APS Data Availability Statement.
4. Archive code/data with a DOI and resolve QQQ redistribution rights.
5. Have one final cold reader review only the abstract, figure captions, and conclusion; those are where the present claims are strongest relative to the evidence.

## A defensible reduced-scope paper if new campaigns are limited

If there is not time for all of the new work, I would reduce scope rather than defend every current claim. The most coherent reduced paper would:

- Present the sell-domain crossover as finite-horizon phenomenology in one deterministic rule pair.
- Report system-size dependence without calling it finite-size scaling or eventual instability.
- Use the Avrami and inverse-distance curves as descriptive summaries only.
- Say the present annealed closures do not reproduce the lattice phenomenology, without claiming pair correlations are insufficient.
- Report bulk founder locations, patch failures, budget equivalence, suppression association, and the cash toggle as model-specific exploratory evidence.
- Remove “birth is cheap,” the directional intervention asymmetry, causal suppression, and strong boundary-mediation language.
- Make the market-crash interpretation secondary to the physical sell-domain process.

That version would be less ambitious, but much harder for a referee to puncture. The full ambitious version needs the quenched theory, direct kinetic measurements, matched intervention controls, and genuine size/horizon scaling.

## Audit scope

This review used the current 40-page `paper-arxiv/Paper_v1.pdf`, all TeX sections, the analysis/figure code, and the committed summary CSVs. I visually inspected the rendered main and supplementary figure pages and numerically spot-checked the pair fixed point, Avrami summaries, conversion probabilities/CVs, equivalence output, and birth/intervention design. I did not rerun the 10,800-run factorial or the full expensive simulation pipeline. The journal-policy and precedent checks above were current on the review date; they should be rechecked at actual submission.
