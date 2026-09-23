# Methods: market outcomes, statistical analysis, and examples

Status: opening, susceptibility definition, interpolated midpoints and
widths, Wilson/interquartile summaries, the financial-outcomes opening,
unfilled-order classifications, the dealer-rejection fraction, and closing
financial-summary sentence accepted, applied, and verified, as is adaptive
selection of additional tested fractions and the clarified bootstrap
uncertainty explanation and logistic-curve comparison. The scope and limits
of the uncertainty estimates are under discussion.
The paired-experiment subsection,
including the fee methods, is also accepted, applied, and verified.

## Accepted proposal: Sell-majority formation and onset

Replace the opening through the final-500-step average, before the
susceptibility explanation. Keep the replacement within the developed
paragraph; reviewing a passage does not create a new manuscript paragraph.

We measured the spread of Sell intentions using $m(t)$, the fraction of
interior traders in Sell at step $t$. We recorded a Sell majority if
$m(t)\geq0.5$ at least once during the observation period after the rule
change. Onset time was the first step after the rule change at which this
threshold was reached. For each condition, we estimated majority
probability as the fraction of runs that reached the threshold. We
summarized onset times only for those runs. In the comparisons of dealer
reserves, market size, and trader resources, we also averaged $m(t)$ over
the final 500 steps to describe intentions near the end of each run.

## Evidence and scope correction

The executed original study under `output/rebuilt/manuscript-reserve-v1/`
defines the interior fraction in `code/src/Compute.jl:198–212`, excluding
technical and inactive perimeter sites. Its RuleQuench, ReservoirQuench,
FiniteSizeQuench, and BalanceSheetQuench drivers find the first value at
or above 0.5 starting with the first updated interior state after the rule
change. The resulting onset index counts post-switch steps from one.
The reservoir and resource grouped summaries calculate probability as the
mean of the Boolean crossing flag and onset medians from positive onsets
only. Fee-study `Run.jl:14–24` and `Analyze.py:60–65` use the same detection
and probability conventions.

The former wording described the final-500-step average as applying to
each market. Its scope needs qualification. ReservoirQuench (FINAL_WINDOW
at line 35, final_states at line 66), FiniteSizeQuench (lines 34,60), and
BalanceSheetQuench (lines 39,87) use the last 500 states in their full
campaigns. RuleQuench records a whole-post-period mean and final value;
the fee study records the final Sell fraction. The proposed wording names
the three comparisons that use the final-window mean and leads directly
into the existing susceptibility definition. This is a reporting scope
correction; no experiment or summary statistic is changed.

The independent reviewer confirmed this scope issue while checking the
preceding fee edit. It also confirmed the remaining majority, onset, and
probability definitions. The original "sign of market instability" phrase
is consistent with the project's finite-time change in intentions, but
does not establish formal instability, persistent selling, or a price
crash. The proposed opening defines the measured intentions directly;
the subsequent drawdown passage treats financial declines separately.

Susceptibility, interpolated thresholds and widths, uncertainty, financial
outcomes, adaptive sampling, logistic fits, and example selection remain
subsequent review units. Existing citations and equation labels are to be
preserved during their review.

## Opening applied and verified

Applied the accepted opening in `paper-arxiv/sections/methods.tex`, keeping
it within the developed paragraph before the unchanged susceptibility
definition. The saved wording scopes final-window averaging to the three
named comparisons and preserves equality at the majority threshold,
post-switch detection, and conditional onset summaries.

Independent read-only reviewer `rule_construction_check` checked the saved
passage against the executed sources and found no substantive issue.
Normal and isolated source-archive builds passed with identical extracted
PDF text and clean final logs. The PDF remains 31 pages. Changed page 7
and neighboring pages 6 and 8 were rendered and visually inspected.
The fee manuscript inputs and numerical records remain unchanged. No
simulation, analysis code, or numerical output changed.
Refreshed output PDF SHA-256:
`7ffdb46d3893b4e0224847160a645e6e6fadab913baff816a3edacf83b4c4a90`.

## Accepted proposal: susceptibility

Replace the susceptibility explanation, its unchanged equation, and the
following interpretation sentence, stopping before linear interpolation.
Preserve the equation label, existing citations, and paragraph structure.
The accepted proposal is now applied and verified, as recorded below.

For the market-size comparison, we denoted each run's mean Sell fraction
over the final 500 steps by $\bar m$. We measured variation between
starting markets using the susceptibility $\chi_L$, defined as the variance
of $\bar m$ multiplied by the number of interior traders,
$(L-2)^2$~\cite{binder1981finite,landau2021guide}. With angle brackets
denoting averages over the 50 starting markets at a fixed grid size and
parameter combination, we calculated:
\begin{equation}
 \chi_L=(L-2)^2\left[\langle\bar m^2\rangle-
                         \langle\bar m\rangle^2\right].
 \label{eq:susceptibility}
\end{equation}
At a fixed grid size, a larger $\chi_L$ indicated greater variation in
the final mean Sell fraction between starting markets
(Eq.~\ref{eq:susceptibility}).

## Susceptibility evidence

The executed `Compute-ModelB-FiniteSizeQuench.jl:201–223` groups by
technical-trader condition, dealer reserves, grid size, and rule fraction.
It computes the second moment minus the squared mean of per-run
`final_sell_mean`, multiplied by $(L-2)^2$. The refined
`revision/Analyze-Revision.py:47–56` pivots the same quantity by starting
market and fraction and uses NumPy variance with denominator 50.
Neither implementation uses the unbiased sample-variance denominator 49.
The equation preserves that convention without adding implementation
detail to the main text.

A targeted read-only calculation grouped the canonical refined per-run
summary by those four parameters, verified exactly 50 markets in each
of 230 cells, and recomputed $(L-2)^2\operatorname{var}(\bar m)$.
Every value matched `ModelB-Revision-FiniteSize-Grouped.csv` within
roundoff; maximum absolute discrepancy was $2.8422\times10^{-14}$.
The calculation did not rerun the bootstrap or write any numerical files.

The independent reviewer confirmed the equation and fixed-condition
averaging. Naming the market-size comparison distinguishes this quantity
from other archived fields also called susceptibility, which measure
temporal fluctuations within individual runs. The finite final-window
mean does not require or establish equilibrium or stationarity. Retain
the existing statistical-physics citations without broadening their
claims or introducing a response-function interpretation.

## Susceptibility applied and verified

Applied the accepted susceptibility passage within the existing developed
paragraph in `paper-arxiv/sections/methods.tex`. Preserved the equation,
label, existing references, and the following interpolation passage.
Independent read-only reviewer `rule_construction_check` confirmed the
saved text against the frozen finite-size driver and refined analysis.
No substantive issue was found.

Normal and isolated archive builds passed with identical extracted PDF
text and clean final logs. The PDF remains 31 pages. Changed page 7 and
neighbors 6 and 8 were rendered and visually inspected. Numerical records
and generated fee manuscript inputs remain unchanged. No code, simulation,
or numerical output changed. Refreshed output PDF SHA-256:
`3ceaf5d6bb45490b7447bb39ff4c5af840131390c0668edb6a0275ab9c3ddc84`.

## Accepted proposal: interpolated midpoint and width

Replace the passage beginning with linear interpolation through the
sentence about monotonicity. Retain it within the developed paragraph.
Leave Wilson intervals and interquartile summaries for the next unit.
The accepted proposal is now applied and verified, as recorded below.

For each market size $L$ and condition, we estimated the fraction of
traders assigned the new rule at which a Sell majority formed in 25%,
50%, or 75% of simulations within the observation period. We denoted
these fractions by $f_{25}(L)$, $f_{50}(L)$, and $f_{75}(L)$. We used
straight lines between the measured probabilities at adjacent tested
fractions to estimate these values (linear interpolation).
The midpoint $f_{50}(L)$ corresponded to a majority forming in half of
the starting markets within the observation period. The width
$f_{75}(L)-f_{25}(L)$ measured the increase in $f$ between majority
probabilities of 0.25 and 0.75. A smaller width indicated a sharper
response. We used the first upward crossing of each probability level
and retained any decreases in the sampled probabilities.

## Interpolation evidence

The authoritative refined `revision/Analyze-Revision.py:17–22,47–64`
sorts fractions, computes Sell-majority probabilities across 50 starting
markets at fixed size/reserves/technical-trader condition, and calculates
crossings at probabilities 0.25, 0.50, and 0.75. Its first-crossing routine
accepts an exact sampled hit or the first adjacent upward bracket. It
does not impose a monotone curve. It returns an undefined value when no
crossing is available, rather than extrapolating. This handling is already
covered in the later sampling paragraph and will be retained there.

The original finite-size driver's interpolation could also accept a
downward crossing. It is not the authority for the refined manuscript
estimates, which come from `ModelB-Revision-FiniteSize-Scaling.csv` via
the manuscript generator. The independent reviewer confirmed this
distinction and the scope of the midpoint/width definitions.

A targeted read-only calculation from the canonical refined per-run
summary reproduced all three crossings and widths for all 15 curves.
The maximum discrepancy from the saved scaling table was
$9.1941\times10^{-17}$. All 45 point crossings were defined. Five curves
contained a decrease in probability between adjacent tested fractions,
so retaining local decreases describes an observed feature of the actual
calculation. No bootstrap or simulation was rerun and no data were written.

The proposed wording identifies an estimated fraction assigned the new
rule and Sell-majority probability. The midpoint concerns formation
within the observation period, not persistence or a price threshold.

Author feedback, 19 September: the generic $f_q(L)$ and $q/100$ sentence
was unclear. Revised the pending opening to separate the fraction of
traders assigned the rule from the proportion of runs forming a majority,
name the three probability levels directly, and explain interpolation as
a straight line between measured probabilities. A hypothetical example
for discussion uses 18% of traders yielding 40% majority runs and 20%
yielding 60%, giving an interpolated $f_{50}$ of 19%. These numbers are
illustrative, not results from the study, and are not proposed for the
manuscript. The remaining midpoint/width sentences are retained. No
manuscript source, numerical file, or PDF changed during this discussion.

## Interpolation passage applied and verified

Applied the accepted revised opening and the remaining pending midpoint,
width, first-upward-crossing, and local-decrease sentences in
`paper-arxiv/sections/methods.tex`. Escaped percent signs for LaTeX and
retained the developed paragraph. The illustrative numerical example was
not inserted. The following Wilson/interquartile sentence remains for
discussion.

Independent read-only reviewer `rule_construction_check` checked the saved
passage against the refined analysis. It confirmed fixed-condition curves,
the three probability levels, exact sampled hits and upward brackets,
retention of local decreases, and the finite observation period. No
substantive issue was found. Numerical records and generated fee inputs
remain unchanged; no code, simulation, or numerical analysis was changed.

Normal and isolated archive builds passed with identical extracted PDF
text and clean final logs. The PDF remains 31 pages. Changed pages 7–12
and neighboring pages 6 and 13 were rendered and visually inspected.
Refreshed output PDF SHA-256:
`ea918ef3c9e1df296e0ce10e255efd30b7abc2e074158bd42fac5052c4941c92`.

## Accepted proposal: probability uncertainty and variation between runs

Replace the closing sentence about binomial proportions and continuous
summaries, retaining the Wilson citation and existing paragraph structure.
The accepted proposal is now applied and verified, as recorded below.

We used 95\% Wilson confidence intervals to describe uncertainty in
estimated Sell-majority probabilities~\cite{wilson1927probable}. Where
shown, interquartile bands extended from the 25th to the 75th percentile
of outcomes across starting markets under the same conditions. These
bands described variation between runs.

## Wilson and quartile evidence

The frozen `Figs-ModelB-ReservoirQuench.jl:13–46` groups by technical
condition, dealer reserves, and rule fraction. It computes Wilson limits
for each majority probability with z = 1.959963984540054. Drawdown and
rejection summaries use medians and the 25th and 75th percentiles across
starting markets. Current Figure 2 captions explicitly identify these
interquartile bands. Figure 3 and the supplementary control tables also
identify Wilson probability intervals.

The frozen refined `Analyze-Revision.py:99–108` and fee
`Analyze.py:17–25,60–76` use Wilson probability intervals. The fee analysis
separately stores medians and quartiles for several outcomes; Table S12
shows selected medians without displaying their quartiles. Resource
figures and summaries also include medians without interquartile bands.
Thus the existing generic claim that continuous summaries use
interquartile ranges needs a narrower description of what is shown.

The independent reviewer confirmed the scope correction. Wilson limits
describe uncertainty in individual-condition probabilities; paired
probability differences and interpolated crossing estimates instead use
the bootstrap procedures described elsewhere. The proposed interquartile
bands describe spread among run outcomes, not confidence intervals for
a mean or median. The 25th and 75th percentiles are the band limits;
their difference is the interquartile range.

The subsequent financial-outcomes paragraph again mentions medians and
interquartile ranges. Reconcile that wording when reviewing that unit,
without expanding this accepted edit into the unreviewed paragraph.

## Wilson and interquartile wording applied and verified

Applied the accepted sentences in `paper-arxiv/sections/methods.tex`,
preserving the Wilson citation and paragraph structure. Independent
read-only reviewer `rule_construction_check` checked the saved wording
against the original and fee summaries and the displayed Figure 2 bands.
No substantive issue was found. The scoped bands do not imply that every
median is accompanied by quartiles or that these bands are confidence
intervals for a summary statistic.

Normal and isolated archive builds passed with identical extracted PDF
text and clean final logs. The PDF remains 31 pages. Changed pages 7–12
and neighbors 6 and 13 were rendered and visually inspected. Numerical
records and generated fee inputs remain unchanged; no code or numerical
analysis changed. Refreshed output PDF SHA-256:
`16081331f335b8628e31276ffdb214280ac45225f1b80b6f18c894d7ca035f80`.

## Accepted proposal: price declines and maximum drawdown

Replace the financial-outcomes opening through the sentence ending
"classifying runs as crashes." Keep it within the developed paragraph.
Move the existing price-window definition from later in that paragraph
into this opening. When applying, remove the duplicate later clause and
start its remaining sentence "Majority detection began with the first
updated interior state after the rule change." Leave the remaining order,
onset, and summary wording for its subsequent review. The accepted proposal
is now applied and verified, as recorded below.

A high Sell fraction did not necessarily produce a large price decline,
because the price response depended on completed trades and the dealer's
trading reserves. We measured price declines using maximum drawdown, the
largest proportional fall from the highest quoted price reached so far
within the observation window. The calculation included the quote
immediately before the rule change and all subsequent quotes within the
observation period. We used price crash to describe a large simulated
decline, without defining a threshold for classifying runs as crashes.

## Drawdown evidence and scope

The frozen `Compute.jl:283–291` initializes the running peak to the first
supplied quote, updates it with each successive quote, and retains the
largest value of one minus the current quote divided by that running peak.
It therefore measures a proportional decline within the supplied window.
The four main drivers pass prices beginning at index T_PRE+1, representing
the quote immediately before the first changed-rule step. Fee
`Run.jl:24` uses the same starting index. Subsequent quoted prices are
included through the chosen observation period, and earlier baseline
peaks are excluded. This uses the dealer's quoted price, not the base
execution price or a fee-inclusive trader payment.

The independent reviewer confirmed the metric and window against all four
main drivers and the fee driver. It recommended placing the endpoint next
to the definition. The proposal brings forward existing information and
does not change the measured window. Wording uses the observation period
rather than the final simulated step so it also accommodates summaries
at different horizons of longer trajectories.

`HOUSE_STYLE.md:106–115` explicitly permits price crash as a large
simulated decline measured by drawdown. It prohibits treating majority
probability as crash probability or introducing an unmeasured crash
threshold. The proposal retains that scope. Completed orders and the
dealer's trading reserves determine the quoted price, so a high intention
fraction alone does not specify the magnitude of the financial decline.
No new classification, experiment, or numerical calculation is proposed.

## Drawdown opening applied and verified

Applied the accepted opening in `paper-arxiv/sections/methods.tex`, within
the existing developed paragraph. Moved the quote-window definition next
to maximum drawdown and removed its duplicate later clause. Retained the
remaining majority-detection sentence with an explicit rule-change
referent. No metric, price window, or crash classification changed.

Independent read-only reviewer `rule_construction_check` verified the
saved running-peak definition, pre-switch quote endpoint, dependence on
completed trades and trading reserves, and descriptive crash terminology
against the implementation and house style. No substantive issue was
found. Normal and isolated archive builds passed with identical extracted
PDF text and clean final logs. The PDF remains 31 pages. Changed pages
7–12 and neighbors 6 and 13 were rendered and visually inspected.
Numerical records and generated fee inputs remain unchanged.
Refreshed output PDF SHA-256:
`75b1271152f686faa3873c5d9157d5a84ca3e0b1a7c1da13d13eb6da866b2a19`.

## Accepted proposal: unfilled orders and dealer rejection

Replace the passage from "We recorded unfilled orders" through "used the
same window," stopping before majority detection. Keep it within the
existing financial-outcomes paragraph. Applied and verified on 19 September.

A Buy order was eligible if the trader had enough cash to pay the
selected execution price and any fee. A Sell order was eligible if the
trader held at least one share. We counted ineligible orders as agent
suppression and eligible orders left unfilled as dealer rejection. Where
reported, we calculated the dealer-rejection fraction as rejected orders
divided by eligible orders, using each run's totals over the observation
period after the rule change. We assigned zero when no orders were
eligible. Suppressed and completed order counts covered the same period.

## Unfilled-order evidence and scope

The frozen `ReserveClearing.jl:75–103` filters desired orders using cash
at the selected base execution price and ownership of one share. Its
returned counts separate desired-minus-eligible orders (suppression)
from eligible-minus-filled orders (dealer rejection). The studied
configurations disable the optional cost-basis restriction. Fee
`FeeClearing.jl:60–109` includes the buyer fee in the affordability test
and preserves those two count definitions. Sale fees are deducted from
proceeds and do not introduce a separate seller cash requirement.

Dealer rejection identifies unfilled eligible orders. It does not imply
that the dealer exhausted its trading reserves: integer trade quantities
and affordability changes can also leave eligible orders unfilled. The
proposed wording avoids assigning every rejection that causal explanation.

The original reservoir, finite-size, resource, and revision financial
metrics pool rejected buys and sells over post-switch order steps and
divide by pooled eligible orders, equal to completed plus rejected
orders. They divide by max(1, eligible total), giving zero when no orders
were eligible. The proposal states this convention without exposing the
implementation. It also identifies a per-run fraction, not a mean of
per-step fractions or a ratio pooled across all starting markets.

The independent reviewer confirmed these definitions and the post-switch
window. Fee `Run.jl:14–30` records completed orders, suppressed buys,
desired orders, and dealer rejections over the same order window. Its
analysis does not report a dealer-rejection fraction. The original
"In every campaign" claim is therefore narrowed to "Where reported."
No underlying metric or output is being changed. The remaining majority
timing, financial-summary wording, and closing interpretation are the
subsequent review unit.

Author feedback, 19 September: requested a revision of the proposed
passage. Reordered it to define Buy and Sell eligibility first, then
name the two categories of unfilled orders. Retained fee-inclusive cash
requirements, share ownership, per-run pooled counts, reporting scope,
the zero-eligible convention, and the common observation period. The
proposal remains under discussion; manuscript source and PDF are unchanged.

## Unfilled-order wording applied and verified

The author accepted the revised eligibility-first proposal on 19 September.
Applied it exactly in `paper-arxiv/sections/methods.tex`, retaining the
developed financial-outcomes paragraph and leaving its remaining timing,
summary, and interpretation sentences for the next review unit.

Independent read-only reviewer `rule_construction_check` verified the saved
Buy and Sell eligibility requirements, fee treatment, suppression and
rejection definitions, per-run pooled fraction, zero-eligible convention,
and post-switch order window against the original and fee implementations.
No substantive issue was found. Normal and isolated archive builds passed
with identical extracted PDF text and clean final logs. The PDF remains
31 pages. Changed pages 7–12 and neighbors 6 and 13 were rendered and
visually inspected. Generated fee inputs and archived numerical records
remain unchanged. Refreshed output PDF SHA-256:
`4b8c022ff4879644872a604530cf40e11807f2d78bb31735d5d566a82c43ccd8`.

## Accepted proposal: financial-summary sentence and repeated definitions

Replace the tail from "Majority detection began" through "could not
complete" with the following sentence, within the existing paragraph.
Applied and verified on 19 September.

We summarized maximum drawdown and dealer-rejection fractions using
medians across starting markets under the same conditions.

The accepted subsection opening already defines onset from the first
post-switch step and restricts its summaries to runs reaching a majority.
The earlier trading-step description explains when intentions update.
The preceding accepted sentences define drawdown, suppression, rejection,
and their measurement windows. Repeating those points here adds no
essential method detail. The independent reviewer also recommended
removing these repeated sentences.

The frozen reservoir figure writer calculates median drawdown and
rejection fractions with quartiles (`Figs-ModelB-ReservoirQuench.jl:41–46`),
whereas the resource writer reports medians without quartile bands
(`Figs-ModelB-BalanceSheetQuench.jl:49–52`). The revision analysis and
fee drawdown analysis also use medians. Existing "Where shown" wording
already explains interquartile bands; the paired-comparison passages
separately describe bootstrap intervals. Naming drawdown and rejection
here avoids implying that every financial statistic in the manuscript
uses medians and quartiles. Baseline diagnostics also report means, and
longer-window comparisons include largest observed drawdowns. Removing
the closing causal phrasing also avoids confusing total drawdown with
the paired effect of the rule change. No statistic or window changes.

## Financial-summary sentence applied and verified

Applied the accepted median sentence exactly, replacing the remaining
financial-outcomes tail. Independent read-only reviewer
`rule_construction_check` verified its scope against the original grouped
summaries and confirmed that the accepted onset definition and measurement
windows retain the necessary timing information. No substantive issue
was found. Normal and isolated archive builds passed with identical
extracted PDF text and clean final logs. The PDF remains 31 pages.
Changed pages 7–12 and neighbors 6 and 13 were rendered and visually
inspected. Generated fee inputs and archived numerical records remain
unchanged. Refreshed output PDF SHA-256:
`0493f3e8328ced52e2a0771787c40b2dd2f6a2e5e3d171e4b934c71011c89bc8`.

## Accepted proposal: adaptive selection of tested fractions

Replace the opening of the next paragraph from "Testing too few fractions"
through "the original 50 seeds," stopping before the bootstrap description.
Keep it within the existing paragraph. Applied and verified on 19 September.

For the market-size comparison, we tested additional fractions of traders
assigned the new rule to locate the rise in Sell-majority probability
more precisely. For each size and condition, we aimed to obtain at least
five tested fractions with estimated majority probabilities strictly
between 5\% and 95\%. Until this criterion was met, we added a fraction
halfway between adjacent tested values when the lower fraction had a
probability below 95\% and the higher fraction had a probability above
5\%. We allowed up to ten rounds and used the same 50 starting markets
at each added fraction. Supplementary Table~\ref{tab:finite-size-scaling}
reports the number of fractions meeting the criterion.

## Adaptive fraction-selection evidence and scope

The executed frozen driver is
`output/rebuilt/manuscript-reserve-v1/code/revision/Compute-Refinement.jl`.
Lines 22–43 group market-size curves by technical-trader mode, dealer
reserves, and grid size; skip curves already having five qualifying
fractions; apply the directional probability test at adjacent fractions;
and add each midpoint for seeds 1–50. The limit is ten rounds. The
probability target is strictly between 0.05 and 0.95; it is not a target
range for the fraction of traders assigned the rule.

A read-only reconstruction from the original finite-size records and each
successive refinement CSV reproduced both archived job manifests exactly:
1,900 runs across 38 added condition/fraction combinations in round one,
and 600 runs across 12 combinations in round two. All fractions have the
same 50 starting markets. All 15 curves finished with five to nine
qualifying fractions; these counts match the archived scaling CSV and
Supplementary Table S3. All point estimates of f25, f50, and f75 are
defined. No simulations or stored analysis records were changed.

The independent reviewer confirmed the driver behavior and scope. The
directional endpoint test is more precise than "intervals intersecting"
when sampled probabilities decrease. "Observed outcomes were not used as
pass conditions" is removed because outcomes did determine refinement;
the intended absence of result-based verification assertions need not be
described in the Methods. The actual number of qualifying fractions
remains reported, so unresolved sampling would remain visible. Undefined
crossing handling remains explicit in the existing Supplementary Table S3
caption, which also states that intervals use available bracketed samples.
No missing crossing or unresolved curve occurred in the point estimates
of this refined market-size analysis. The next review unit is the
whole-market bootstrap description, followed by the logistic comparison.

## Adaptive fraction-selection passage applied and verified

Applied the accepted passage exactly in `paper-arxiv/sections/methods.tex`,
retaining the developed paragraph and the subsequent bootstrap and logistic
material for later review. Independent read-only reviewer
`rule_construction_check` verified its scope, strict probability criterion,
directional midpoint rule, round limit, shared starting markets, and
Table S3 reference against the frozen driver and archived records.
No substantive issue was found. Normal and isolated archive builds passed
with identical extracted PDF text and clean final logs. The PDF remains
31 pages. Changed pages 7–12 and neighbors 6 and 13 were rendered and
visually inspected. Generated fee inputs and archived numerical records
remain unchanged. Refreshed output PDF SHA-256:
`d8734fc0b589dccf84a14a8a01afdcfb8310082858cf5d67f9987fd0ca10ce6e`.

## Accepted proposal: bootstrap uncertainty

Replace "We then resampled whole seeds" through "reselection of the
susceptibility peak," stopping before the logistic description. Keep the
replacement within the existing paragraph. Applied and verified on 19 September.

For each market size and condition, we drew 2,000 bootstrap samples of
50 starting markets with replacement. Within each bootstrap sample, we
used the same selection of starting markets at every tested fraction.
In each sample, we
recalculated $f_{25}$, $f_{50}$, $f_{75}$, the width $f_{75}-f_{25}$,
and the maximum susceptibility over the tested fractions. The 2.5th and
97.5th percentiles of these estimates defined the 95\% confidence intervals.

## Bootstrap evidence and scope

The frozen `code/revision/Analyze-Revision.py:47–76` constructs matrices
whose rows are the 50 starting markets and whose columns are tested
fractions. For each size and condition, it draws a 2,000-by-50 matrix of
market indices with replacement and uses the same indices for all fractions
and for both majority outcomes and final-window Sell fractions. Thus the
resampling unit is a starting market's complete collection of outcomes,
not a time step, individual trader, or independently selected run at each
fraction. No new simulation is part of this calculation.

Each resample recomputes first-upward crossings at 0.25, 0.50, and 0.75,
the difference between the outer crossings, and the susceptibility curve.
The peak is selected anew over tested fractions, rather than evaluated
only at the original peak location. Percentile limits use 0.025 and
0.975 quantiles. Undefined estimates are omitted separately for each
reported interval, and a width requires both outer crossings. The
Supplementary Table S3 caption already states that intervals use available
bracketed samples. All 15 archived curves report 2,000 replicates and
`bootstrap_crossing_valid = 1`; no crossing samples were excluded in this
analysis. Read-only checks also confirmed complete per-market results
across every curve's tested fractions.

The independent reviewer confirmed these implementation details and the
proposed scope. The later sentences about conditional uncertainty,
interpolation, selected fractions, and observation duration remain for
review after the logistic comparison. This proposal introduces no new
statistic, analysis, or numerical result.

Author feedback, 19 September: "We kept each selected market's outcomes
together across all tested fractions" was unclear. Revised the pending
sentence to say explicitly that each bootstrap sample uses the same
selection of starting markets at every fraction. A selected market
contributes its recorded outcome at each fraction; if selected twice,
its outcome counts twice at every fraction. This preserves the matched
comparison across fractions. The manuscript and PDF remain unchanged
while this proposal is under discussion.

## Clarified bootstrap passage applied and verified

Applied the accepted passage in `paper-arxiv/sections/methods.tex`, including
the author's clarification that the same selected starting markets were
used at every fraction within a bootstrap sample. Independent read-only
reviewer `rule_construction_check` verified the saved sampling unit,
replacement, sample size and count, recomputed estimates, reselection of
the susceptibility maximum, and percentile confidence limits against the
frozen analysis. No substantive issue was found. Normal and isolated
archive builds passed with identical extracted PDF text and clean final
logs. The PDF remains 31 pages. Changed pages 7–12 and neighbors 6 and
13 were rendered and visually inspected. Generated fee inputs and archived
numerical records remain unchanged. Refreshed output PDF SHA-256:
`8de74b6b502b390658c42482e34c9544c41e05f9972f29288629288eeabfc9ab`.

## Accepted proposal: logistic comparison and fitting

Replace the passage from "We also fitted a logistic curve" through
"Fitted standard errors were bootstrap standard deviations," retaining
the displayed equation exactly. Stop before "Both analyses measured
uncertainty." Keep it within the existing developed paragraph. Applied
and verified on 21 September.

We also fitted a smooth, increasing logistic probability curve for each
market size and condition. We compared the midpoint and width of this
probability curve with the estimates from linear interpolation. We
modeled the Sell-majority probability as:
\begin{equation*}
p_L(f)=\left\{1+\exp\left[-a_L-b_L(f-0.18)/0.01\right]\right\}^{-1},
\qquad b_L>0.
\end{equation*}
The fitted parameters $a_L$ and $b_L$ controlled the probability curve's
position and steepness. The constants 0.18 and 0.01 centered and scaled
$f$ for fitting. We estimated the parameters by maximizing the binomial
likelihood of the observed majority counts. We refitted the probability
curve in each of the same 2,000 bootstrap samples. We calculated standard
errors for the midpoint and width of the Sell-majority probability curve
from the standard deviations of their bootstrap estimates
(Supplementary Table~\ref{tab:revision-fits}).

## Logistic evidence and scope

The frozen `code/revision/Analyze-Revision.py:25–38` transforms the
assigned fraction as `(f-0.18)/0.01` and fits an intercept and positive
slope by minimizing the negative binomial log likelihood of majority
counts. The existing displayed formula is correct. Its constants are
fixed centering and scaling choices, not inferred thresholds. The
positive slope constrains the fitted curve to increase smoothly; the
empirical crossing analysis permits local decreases in probability.
The proposal describes comparison of assumptions about curve shape,
without claiming agreement or robustness as a Methods result.

Lines 60–69 refit the curve using the same bootstrap market selections
used for interpolated crossings and susceptibility. They calculate midpoint
and width in each sample, then report their sample standard deviations
as standard errors. These are errors on midpoint and width, not on the
fitted intercept and slope or residuals. Supplementary Table S10 reports
the logistic midpoint and width with those standard errors.

A read-only check verified positive fitted slopes for all 15 archived
curves and reproduced their midpoint as `0.18-0.01*a/b` and width as
`0.02*log(3)/b`, with maximum absolute discrepancies below 9e-17.
Every curve records 2,000 bootstrap samples. The independent reviewer
confirmed the equation, parameter roles, fixed constants, fitting
objective, and bootstrap standard-error calculation. No simulations,
fits, or stored numerical results were changed. The following uncertainty
limitations remain the next review unit.

Author feedback, 21 September: make explicit what midpoint and width
refer to, replace "wrote" with "modeled," and use "probability curve"
consistently for position and refitting. Revised the pending proposal to
name the probability curve when describing its midpoint and width and to
state the comparison with estimates from linear interpolation directly.
The quantities retain the accepted definitions: midpoint is the fraction
assigned the new rule at which Sell-majority probability reaches 50%,
and width is the increase in that fraction between majority probabilities
of 25% and 75%. The revised closing sentence explicitly identifies
standard errors for the midpoint and width of the Sell-majority probability
curve. Manuscript source and PDF remain unchanged pending acceptance.

## Logistic comparison applied and verified

Applied the accepted revised passage in `paper-arxiv/sections/methods.tex`,
including explicit probability-curve references and "modeled" for its
mathematical description. Verified that the displayed equation is unchanged.
Independent read-only reviewer `rule_construction_check` confirmed the
saved comparison, centering and scaling, likelihood, bootstrap refitting,
and standard errors specifically for midpoint and width against the frozen
analysis. No substantive issue was found. Normal and isolated archive
builds passed with identical extracted PDF text and clean final logs.
The PDF remains 31 pages. Changed pages 7–12 and neighbors 6 and 13 were
rendered and visually inspected. Generated fee inputs and archived
numerical records remain unchanged. Refreshed output PDF SHA-256:
`b6b4e4e1fd1fb27b48d09b76ed0bac3be533f8a61a98b91a65336789653b0dbd`.

## Next proposal: scope of uncertainty estimates

Replace the two sentences from "Both analyses measured uncertainty" through
"observing the market for longer," stopping before selection of examples.
Retain the existing paragraph boundary. This proposal is not yet applied.

The bootstrap confidence intervals and standard errors described uncertainty
from sampling starting markets, with the tested fractions and observation
period held fixed. They did not include uncertainty from selecting
additional fractions. For the interpolated crossings and widths, the
intervals also excluded error from approximating the probability curve
with straight lines. These uncertainty estimates did not quantify how the
Sell-majority probability curve would change over a longer observation
period.

## Uncertainty-scope evidence

The frozen `code/revision/Analyze-Revision.py:44–83` constructs the tested
fraction vector and fixed-horizon outcome matrices before drawing bootstrap
market indices. Resampling changes the weights of starting markets; it
neither selects a new fraction grid nor extends the simulation duration.
The refinement driver chooses additional fractions before analysis, and
its selection is not repeated inside the bootstrap. Thus uncertainty
estimates condition on the observed refined grid and chosen horizon.

The interpolated crossing function uses straight lines between adjacent
tested probabilities. Its bootstrap intervals quantify sampling variation
in that calculation and do not incorporate approximation error relative
to an unknown probability curve between those fractions. The proposed
wording scopes this exclusion to interpolated crossings and widths rather
than implying that the logistic model performs linear interpolation.

Longer observation may change which markets reach a Sell majority and
therefore the probability curve. This is a different measured outcome,
not an error caused by observing longer. The separate horizon experiment
compares specified longer windows; the present bootstrap does not propagate
those changes into its confidence intervals or standard errors. The
independent reviewer confirmed these distinctions and recommended retaining
all three scope qualifications in plain language. No analysis or numerical
result changes. Selection of spatial examples is the next review unit.
