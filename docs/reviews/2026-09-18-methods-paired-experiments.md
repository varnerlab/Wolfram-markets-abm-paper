# Methods: paired rule-switch experiments

Status: opening, study-design summary, parameter comparisons, trader-resource
interventions, and complete transaction-fee Methods paragraph accepted,
applied, and verified. The author clarified
the reference to investors assigned the new rule and accepted removing
the detailed first-step timing explanation. The market-outcomes opening
is the next proposed unit, recorded in `2026-09-18-methods-outcomes.md`.

## Scope and evidence

Replace the opening through the statement that the switched path began
with the same resources and neighbor configurations as its control. Keep
campaign counts, initial endowments, observation windows, parameter grids,
and resource interventions for the following unit. The proposed paragraph
concerns a rule-only switch, with other model conditions fixed within the
pair. It does not make the same first-price claim for resource interventions
or the supplementary Sell pulse.

The frozen `Simulate.jl:588–609` retains the selected traders' new rules
while assigning the original rule during the baseline. Lines 676–686
replace only their rule at the switch. Execution uses the existing
intentions before the technical and interior updates. Thus the first
post-switch trades and quote are identical within a rule-switch/control
pair; changed interior intentions can first occur at the end of that
step, with trading differences possible on the following step.

The executed `Compute-ModelB-RuleQuench.jl:40–46,100–127` uses 1,000
baseline steps and compares activation at step 1,001 with activation
beyond the observation window. It checks identical price history through
the first post-switch quote, Sell-fraction history before the switch,
selected grid frames, technical locations, and band multipliers.
`Compute-ModelB-ReservoirQuench.jl:103–137` and
`Compute-ModelB-FiniteSizeQuench.jl:81–110` share a newly executed control
across multiple fractions because the inactive target fraction does not
affect the baseline. The same comparison is preserved by fee-study
`Run.jl:58–74`. Sharing a control does not mean a pair has two different
baseline histories.

Resource interventions are different: the balance-sheet driver checks
common history only through the pre-intervention state; changing holdings
can affect the first subsequent execution. Preserve that distinction in
the next unit. The detailed reproducibility checks already appear in the
supplement, so the proposed opening explains the pairing rather than
repeating implementation-level equality checks.

## Earlier opening proposal, superseded by author revision

We isolated the effect of the rule change by comparing each changed-rule
simulation with a control that retained the original rule. Each pair
began from the same initial market and used Rule 19280 at every interior
site for 1,000 steps. At the start of step 1,001, we assigned Rule 19286
to the preselected fraction $f$ of interior traders in one simulation.
The control continued with Rule 19280. The assignment changed their rule
without changing current intentions or financial resources. Because
orders on that step came from existing intentions, both simulations
completed the same trades and produced the same quoted price. The first
possible difference was in the interior intentions updated at the end
of the step. Those intentions could then affect trading from the
following step.


## Author revision and applied opening

The author asked to identify the investors assigned the new rule and
questioned the scope of the identical-trades sentence. Clarified that the
implementation executes existing intentions before updating them, so the
first post-assignment trades remain identical. The author accepted a
simpler main-text opening that omits that timing detail. Its correct
technical statement remains in the supplement; no timing convention or
simulation behavior was changed.

Applied the following accepted opening within the existing developed
paragraph, before the unchanged study-design summary:

We isolated the effect of the rule change by comparing each changed-rule
simulation with a control that retained the original rule. Each pair
began from the same initial market and used Rule 19280 at every interior
site for 1,000 steps. At the start of step 1,001, we assigned Rule 19286
to a preselected fraction $f$ of investors in the interior of the grid.
The investors assigned the new rule retained their current intentions
and financial resources. The control continued with Rule 19280. The two
simulations therefore shared the same history up to the rule change.

Independent read-only reviewer `rule_construction_check` found no
substantive issue in the saved passage against the frozen paired drivers
and simulator. The revision remains distinct from separate resource
interventions. No numerical results or code changed. Normal and isolated
archive builds passed with identical PDF text and clean final logs. The
PDF remains 31 pages. Changed pages 6 and 7 and adjacent pages 5 and 8
were rendered and visually inspected. Refreshed output PDF SHA-256:
`e1764d50db24ddeb2388f2f51850a1694cc1ea1f34414455970e0d6cbc085a10`.

## Accepted proposal: simulation conditions and observation periods

Replace the remaining study-design summary in the opening paragraph:

Each condition in the four main comparisons used 50 starting markets
(Supplementary Table~\ref{tab:campaigns}). Every trader initially held
1,000 cash units and ten shares. Each simulation continued for 3,000
steps after the baseline. Additional comparisons tested other decision
rules and a one-time instruction to sell. We also kept technical traders'
band widths fixed after the rule change, tested additional dealer reserve
levels, and extended the observation period. The supplementary protocols
give the conditions and parameter values for these comparisons
(Appendix~\ref{app:revision-controls}).

Verified main-study counts and durations against the four frozen full-run
drivers: RuleQuench, ReservoirQuench, FiniteSizeQuench, and
BalanceSheetQuench. All use 50 seeds, 1,000 baseline steps, and 3,000
subsequent steps. Their configurations specify initial cash 1,000 and ten
shares. Table S1 identifies the four campaigns and 50 starting markets
per condition. This count does not apply to every supplementary screen;
for example, the alternative-rule screen uses twenty starting markets.
The initial cash is in model units, not a claim of currency calibration.

The saved supplementary controls describe the alternative rules, Sell
pulse, band widths fixed at their pre-switch values while the reference
mean continues to update, extra reserve levels, and longer windows.
The proposed wording does not imply that frozen widths are zero from
initialization or that every supplementary comparison uses the main
observation window. The next unit after this summary describes the main
parameter grids and then the separate resource interventions.


## Study summary applied and verified

Applied the accepted summary within the existing opening paragraph,
retaining both supplementary references. It names starting markets,
initial cash and shares, the main observation window, and the separate
supplementary comparisons. Independent read-only reviewer
`rule_construction_check` checked the saved passage against all four
frozen main drivers, Table S1, and the supplementary implementation and
protocols. No substantive findings remained. No equations, code,
parameters, or numerical outcomes changed.

Normal and isolated source-archive builds passed with identical extracted
PDF text and clean final logs. The PDF remains 31 pages. Changed pages 6
and 7 and adjacent pages 5 and 8 were rendered and visually inspected.
Refreshed output PDF SHA-256:
`40e7d59c3df85d7d132d0d60d8ea3d1146219a2367c1a8c5ad4fe0d300657a8f`.

## Accepted proposal: fractions, dealer reserves, and market sizes

Replace the start of the next paragraph through the explanation of dealer
resources increasing with market size. Leave resource interventions for
the following unit. Maintain the developed paragraph when that unit is
integrated.

We varied the fraction of traders given the new rule, market size, and
financial resources to compare the spread of Sell intentions with changes
in completed trades and prices. The rule-change comparison used a
$64\times64$ grid, active technical traders, and $h=100$ at
$f\in\{0.10,0.15,0.20,0.25\}$. The comparison of dealer reserves used
11 fractions between 0.10 and 0.25 at eight values of $h$ from 0 to 100,
with technical traders active or held. For the size comparison, we used
$L\in\{32,48,64,96,128\}$. At each size, technical traders were held at
$h=100$ or active at $h=1$ and $h=100$. At a fixed $h$, initial dealer cash
and share reserves increased in proportion to the number of traders.

Verified against the frozen full-run drivers and their canonical data:
`ModelB-RuleQuench-Full-Summary.csv` contains 200 changed-rule/control
summary rows with four fractions and L=64. The driver specifies active
technical traders and h=100. `ModelB-ReservoirQuench-Full-Summary.csv`
contains 8,800 treatment rows with eleven fractions, both technical
conditions, and h in {0,0.1,0.5,1,2,5,10,100}.
`ModelB-FiniteSizeQuench-Full-Summary.csv` contains 9,000 treatment rows
with five sizes and precisely three reserve/feedback combinations:
(100,held), (100,active), and (1,active). Those records contain twelve
fractions from 0.14 to 0.25; the proposed main-text summary leaves their
full list to the supplementary design. Counts above exclude separately
executed controls where the design shares a control across fractions.

`ReserveClearing.jl:3–9` initializes dealer shares as round(h*N_traders)
and cash as P0 times those shares. `Simulate.jl:612–616` counts interior
and selected technical traders, not every grid site. At the integer h
values used for size comparisons, both reserves scale exactly with that
count. This is a comparison with fixed dealer reserves per trader, not
fixed aggregate dealer resources. No new experiments are proposed.


## Parameter comparisons applied and verified

Applied the accepted fraction, dealer-reserve, and market-size description
within the existing developed paragraph. The supplementary design-table
reference remains in the preceding summary. Independent read-only
reviewer `rule_construction_check` verified the saved text against the
canonical run summaries, frozen drivers, and dealer initialization and
found no substantive issue. No code, equations, parameters, or results
changed.

Normal and isolated source-archive builds passed with identical extracted
PDF text and clean final logs. The PDF remains 31 pages. Changed pages 6
and 7 and adjacent pages 5 and 8 were rendered and visually inspected.
Refreshed output PDF SHA-256:
`1447c24e8cc671c5211fcdff7b75cfbae6228d16cd131b9d5ec9994b4f0e16e8`.

## Accepted proposal: changes to trader cash and shares

To test how trader resources affected the response to the rule change,
we independently multiplied each trader's current cash and shareholdings
by factors $g_w,g_q\in\{0.1,1,10\}$ at the switch. This gave nine
combinations, including unchanged holdings when both factors were 1.
Share counts were rounded to whole numbers. The intervention did not
rescale the dealer's reserves. With other settings fixed, all nine
simulations shared the same history before the intervention and assigned
the new rule to the same traders. When technical traders were held,
changing resources could alter completed trades and prices but could not
alter interior intentions, because neither cash nor shareholdings entered
the decision rule. The supplementary material gives the full parameter
combinations and verification checks (Appendix~\ref{app:supplement}).

Replace the existing resource-intervention portion through the closing
appendix sentence. Describe nine combinations rather than nine changes:
one is the unchanged-resource reference. All nine apply the same rule
switch; this reference is distinct from a no-rule-switch control. Scaling
is of each trader's holdings at the switch, not their original endowment.
It affects interior and technical traders, not the dealer's balance sheet.
Later trading can of course change dealer reserves.

Frozen `Compute-ModelB-BalanceSheetQuench.jl:63–71` applies the resource
change at step 1,001 and rounds shares. Lines 122–161 execute all nine
combinations, check common pre-intervention histories, and compare held
Sell-fraction histories and final grids against the unchanged-resource
run. Lines 271–300 construct paired contrasts with that reference.
Canonical `ModelB-BalanceSheetQuench-Full-Summary.csv` contains 10,800
rows: four fractions {0.17,0.175,0.18,0.185}, h in {0.1,1,100}, both
feedback conditions, 50 starting markets, and nine combinations, all on
L=64 grids with 1,000 baseline and 3,000 subsequent steps. These parameter
values agree with the saved supplementary simulation-design description.

The independent reviewer confirmed these semantics while checking the
parameter passage. The next proposal states structural independence of
held intentions from resources, rather than claiming all interior frames
were stored or compared at every step. Financial histories can differ
immediately at the resource intervention, unlike the first execution of
the rule-only switch. No new simulation is needed for this prose revision.


## Trader-resource passage applied and verified

Applied the accepted resource passage within the existing developed
comparison paragraph. It distinguishes nine combinations from nine
changes, identifies the unchanged-holdings reference, preserves current
holdings and intervention timing, and distinguishes trader resources from
dealer reserves. The appendix reference retains the detailed checks.
Independent read-only reviewer `rule_construction_check` verified the
saved text against the frozen driver and simulator and found no
substantive issue. No code, equations, parameters, or results changed.

Normal and isolated source-archive builds passed with identical extracted
PDF text and clean final logs. The PDF remains 31 pages. Changed pages
6–12 and adjacent pages 5 and 13 were rendered and visually inspected.
Refreshed output PDF SHA-256:
`0ad5cf51f7bb4286d9500619158170aebc77ea2f428efa8a828ad7d555c9d448`.

## Accepted proposal: transaction-fee design

The fee extension is already implemented, validated, and included in the
manuscript; this is its interactive prose review. Replace the opening of
`sections/transaction-fees-methods.tex` through the sentence about different
financial histories during the baseline. Leave the outcome measures,
separate fee income, and bootstrap sentences for the following unit.
This input is generated: apply an accepted revision to
`code/fees/WritePaper.py` and regenerate. Preserve frozen simulation and
analysis sources. Update the study's copied writer, its
`Postprocessing-Sources.json` hash, and the generation record when applying.

We tested fees of 0, 5, 10, and 25 basis points on each completed buy or
sell to determine whether trading costs changed the response to the rule
switch. One basis point was 0.01\% of the base execution price. The rates
were chosen for a sensitivity comparison and were not calibrated to a
particular market. Fees applied from initialization, so different rates
could produce different financial histories before the rule change.
Each condition used 50 starting markets on $64\times64$ grids, with
1,000 baseline steps and 3,000 subsequent steps. We tested all combinations
of $f\in\{0.10,0.15,0.175,0.185,0.20,0.25\}$,
$h\in\{0.1,1,100\}$, and technical traders active or held. For each fee
rate, reserve level, and technical-trader condition, one control per
starting market retained the original rule and served all six rule-change
fractions. Each rule-change simulation shared its history with this
control up to the switch. This comparison used 8,400 simulations.

Verified against fee-study Protocol.json, Manifest.csv, Validation.json,
and Run.jl. The manifest contains 1,200 groups with one control and six
rule-change runs each, for 8,400 full financial runs. Fees are set before
the call to simulate and applied throughout; paired histories are checked
within each fee rate. Different fee rates share initial conditions but
may diverge before activation. The numerical study's completed validation
already checked manifest completeness, pairing, and frozen-source hashes.
The proposed design prose omits the implementation-level first-post-switch
price assertion, consistent with the author's earlier timing simplification;
it remains in the validation material. No new experiments are proposed.


## Transaction-fee design applied and verified

Applied the accepted opening through the simulation count in
`code/fees/WritePaper.py` and regenerated the manuscript inputs. Updated
the study's copied writer, `Postprocessing-Sources.json`, and
`Manuscript-Generation.json`. Root and copied writers match. All frozen
source and postprocessing hashes pass. The protocol, run summary,
condition summary, paired effects, and validation record are unchanged.
The generated fee Results, table, and validation inputs are byte-identical
to their preceding versions. No simulation or numerical analysis was rerun.

Independent read-only reviewer `rule_construction_check` found no
substantive issue against the protocol, manifest, driver, and provenance
records. It confirmed 1,200 controls plus 7,200 rule-change runs, fees
from initialization, and the distinction between matched histories within
each rule-change/control pair and different histories across fee rates.

Normal and isolated source-archive builds passed with identical extracted
PDF text and clean final logs. The PDF remains 31 pages. Changed pages
6 and 7 and adjacent pages 5 and 8 were rendered and visually inspected.
Refreshed output PDF SHA-256:
`8dfa70b64b9e9e8688d60a4a6208e1b35f0d6bdecc48aedb75fd8d0a2f444622`.

## Accepted proposal: fee outcomes and uncertainty

Replace the remaining fee-methods sentences through the end of the input.
Retain this material within the developed fee paragraph. Applied using
the same writer and provenance workflow as the design opening, as recorded
below.

At each simulation step, we recorded the interior Sell fraction, the
dealer's quoted price, counts of completed orders and buy orders blocked
by insufficient cash, total trader cash, and cumulative dealer fee income.
We used these histories to identify Sell-majority formation and calculate
maximum drawdown after the rule change. Fee income remained separate from the dealer's trading
reserves. We compared each rule-change simulation with its control at the
same fee rate. We also compared each positive fee rate with zero fees
under the same rule change. Both comparisons matched simulations by
starting market and held other settings fixed. We used 2,000 bootstrap
resamples of the 50 matched starting markets to obtain percentile 95%
confidence intervals for these differences. Selected comparisons appear
in Supplementary Table S12.

Checked against `code/fees/Run.jl:16–34` and `Analyze.py:60–104`.
Recorded suppression is specifically the number of post-switch buys
blocked by insufficient cash; the summary reports the fraction of desired
buys suppressed. Fee income includes the baseline and subsequent window.
The two paired contrasts use identical starting-market seeds and fixed
remaining parameters. Fee comparisons use the zero-fee reference, rather
than every pair of positive rates. Bootstrap samples resample all 50
matched pairs with replacement 2,000 times. Interval bounds are the 2.5th
and 97.5th percentiles. Probability effects use the mean paired difference
in binary outcomes. Drawdown, completed orders, final total trader cash,
and cumulative fee income use median paired differences, not differences
between condition medians. The Table S12 caption states the estimators
for its selected probability and drawdown contrasts. It does not tabulate
every recorded outcome, hence the separate selected-comparisons sentence.

Author feedback, 18 September: add that measurements were recorded at each
turn of the simulation. Revised the proposed opening to use the existing
term "simulation step" and distinguish recorded histories from derived
outcomes. `Simulate.jl:628–759` retains per-step Sell fractions, quotes,
completed and suppressed order counts, and total trader cash.
`FeeSimulation.jl:7–9,27–29` records cumulative dealer fee revenue at each
step. `Run.jl:18–24` derives majority formation and maximum drawdown from
the post-switch histories after each run; it does not store per-step
maximum-drawdown estimates. These inspected sources match the frozen fee
study and its recorded hashes. The revised proposal preserves the author's
timing clarification without claiming that derived outcomes were recorded
at each step. Manuscript source and PDF remain unchanged during discussion.


## Fee outcomes and uncertainty applied and verified

The author accepted the per-step clarification and requested application
and the next unit. Applied the full pending outcome/uncertainty passage,
with the revised opening, in `code/fees/WritePaper.py` and regenerated.
Refreshed the study's copied writer, postprocessing hash, and manuscript
generation record. Numerical inputs and frozen sources remain unchanged.
The generated fee Results, table, and validation inputs are byte-identical
to their preceding versions. No simulation or numerical analysis was rerun.

Independent read-only reviewer `rule_construction_check` checked the saved
passage against the frozen simulator, fee observer, metric calculation,
paired contrasts, bootstrap, Table S12, and provenance. No substantive
issue was found. The per-step histories and subsequently calculated
outcomes are distinguished correctly.

Normal and isolated archive builds passed with identical extracted PDF
text and clean final logs. Changed pages 7–12 and adjacent pages 6 and 13
were rendered and visually inspected. The PDF remains 31 pages.
Refreshed output PDF SHA-256:
`94ae7d1a9bd804a7d907380ec891653aa4d4a18e5f5095f22392938e9aaafe5a`.
The next unit is the market-outcomes opening, with its proposed wording
and scope correction in `2026-09-18-methods-outcomes.md`.
