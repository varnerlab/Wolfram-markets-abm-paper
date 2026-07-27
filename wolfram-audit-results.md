# Wolfram Markets ABM: Manuscript and Code Audit

## Resolution update — July 23, 2026

The issues below were the findings from the initial audit. This revision addresses
the manuscript and workflow problems that can be corrected without running a new
research campaign:

- Recast the Potts quantity as an alignment diagnostic, corrected its
  normalization, and added a counterexample showing that it does not generate the
  CA rule.
- Replaced the claimed critical point with the observed \([0.14,0.15]\)
  finite-horizon bracket and identified \(0.145\) only as its midpoint.
- Recast the inverse-distance onset curve as an empirical fit, documented
  censoring and small-sample limits, and removed claims of absolute stability or
  parameter equivalence.
- Corrected inactive boundary behavior, the active-edge count, the \(c=1\)
  neighborhood, the QQQ date range, and the cash-intervention timing.
- Renamed Model B “feedback-closed,” documented the unmodeled market maker, and
  described the cash toggle as a uniform wealth shock rather than a real-market
  liquidity operation.
- Shortened the abstract, introduction, related work, Results II, discussion, and
  conclusion; removed visible submission placeholders and repeated signposting.
- Repaired the LaTeX and Julia runners, bibliography refresh, figure placement,
  data documentation, and Model A onset-data export.
- Regenerated the onset-time figure and manuscript PDF with the corrected
  terminology.

Verification completed after the revision:

- `paper-arxiv/Build.sh Paper_v1` succeeds with no undefined citations,
  references, or overfull boxes.
- The rendered 31-page PDF was inspected, including the title page, Results II
  figure sequence, discussion, references, and appendix transition.
- All four targeted Julia scripts pass:
  `Test-EdgeFraction.jl`, `Test-ModelB.jl`, `Test-EscapeTime.jl`, and
  `Test-BoundaryVsBulk.jl`.

Two research-level items remain intentionally unresolved. Establishing a
thermodynamic transition requires replicated disorder seeds, system-size scaling,
and preferably hysteresis or bimodality tests. Establishing budget equivalence
requires a powered difference or equivalence analysis; the paper now states only
that no large shift was resolved. The raw QQQ download is also absent, so its
timezone, missing-bar policy, license, and checksum must be recovered from the
original source record before archival.

## Overall assessment

At the time of the initial audit, the manuscript was not submission-ready. The
stored Model B results were internally consistent and the unit tests passed, but
several central claims were stronger than the model or experiments supported.
The resolution update above records how those issues were handled.

## Highest-priority technical issues

### 1. The Potts interpretation is not mathematically valid as written

`paper-arxiv/Paper_v1.tex:1157` describes Rule 19280 as zero-temperature three-state Potts dynamics that maximizes local alignment. It does not. The rule responds to the numerical sum of state labels, not the number of matching neighbors. For example, a neighborhood with three Holds and one Buy has sum \(c=3\), but Rule 19280 outputs Buy rather than the local majority, Hold.

The Potts energy can still be a useful alignment statistic, but it is not a Hamiltonian whose gradient generates the CA dynamics. Replace “Potts mapping,” “ground state,” and “free-energy barrier” with language such as “Potts-inspired alignment statistic” unless energy descent or detailed balance can be proved.

There is also a normalization error in Eq. 10. The code divides the number of aligned bonds by the number of distinct bonds, giving \(e=-1\) for perfect alignment. The manuscript writes an extra factor of \(1/2\):

\[
e=-\frac{1}{2N_{\rm bonds}}\sum_{\langle i,j\rangle}\delta(\sigma_i,\sigma_j).
\]

If the sum already runs over distinct bonds, this yields \(-1/2\), not \(-1\). Compare `paper-arxiv/Paper_v1.tex:1161` with `code/model-a/Compute-NucleationTheory.jl:62`.

### 2. Boundary conditions conflict with the implementation

The paper says inactive boundary cells follow the interior CA rule at `paper-arxiv/Paper_v1.tex:804`. The solvers never update any boundary cell; inactive cells remain Hold. See `code/src/Wolfram.jl:71`.

This is not a cosmetic discrepancy: an inert Hold frame and a dynamically updating boundary are different models.

The stated edge count is also wrong. A \(256\times256\) grid has 1,020 boundary cells, so 25% gives 255 active edge agents, not approximately 512 as claimed at `paper-arxiv/Paper_v1.tex:891`.

### 3. The QQQ data are not a full 2024 calendar year

The manuscript calls the 23,790 observations “2024 calendar year” data. The committed file runs from January 2 through March 28, 2024—exactly one quarter, not one year.

Correct the description to “2024 Q1” and document:

- Timezone
- Missing-bar policy
- Data vendor
- Data license
- File checksum

### 4. The first-order-transition claim needs stronger evidence

The Model A phase sweep has one fixed-seed realization per \(f\). Its fine spacing is 0.01, with no crash at 0.14 and a crash at 0.15. Therefore:

- \(f_c=0.145\) is the midpoint of a bracket, not an estimated critical point.
- “Transition width less than 0.01” is unsupported; the data only bracket the finite-horizon change within \([0.14,0.15]\).
- A sharp finite-size crossover in one realization is not enough to establish a thermodynamic first-order transition.

At minimum, add replicated seeds, uncertainty bands, system-size scaling, transition-probability curves, and preferably hysteresis or bimodality evidence.

Until then, use:

> A sharp finite-horizon crossover consistent with a discontinuous transition.

### 5. The Kramers interpretation is too strong

The fit

\[
\log\tau=A+\frac{B}{f-f_0}
\]

is phenomenological; it is not derived from this deterministic, quenched-disorder CA. A good \(R^2\) does not establish a Kramers mechanism or prove that the barrier is infinite below \(f_0\).

For Model A, the fit uses only values where every seed collapsed, thereby excluding censored low-\(f\) runs. For Model B, each three-parameter curve is fit to only five or six finite medians. Low-\(f\) cells with undefined Kaplan–Meier medians do not enter the fit, despite the manuscript saying censored runs “still inform the estimate.”

Recommended wording:

> Over the observed range, median onset times were well described by a three-parameter inverse-distance curve. We use this fit as a compact empirical summary, not as evidence of a literal thermal activation mechanism or absolute stability below \(f_0\).

Overlapping confidence intervals also do not demonstrate equivalence across budgets. Use a bootstrap distribution for the between-budget parameter differences or an equivalence test.

### 6. Model B is feedback-closed, not economically closed

Agents trade against an omitted infinite-inventory market maker. Cash and shares are therefore not conserved within the modeled population. Calling this a “closed market” invites objections. “Closed-feedback model” or “endogenous-price configuration” is more accurate.

This matters for the claim that crashes “finance their own dip-buyers”: selling transfers new cash from the unmodeled market maker into agent books. That mechanism should be described explicitly as a consequence of the execution convention.

Similarly, multiplying every trader’s cash by ten is a wealth injection, not conventional market liquidity provision. The policy interpretation should remain model-specific.

### 7. The intervention timing is one step earlier than the prose suggests

The control’s onset \(t_{\rm on}\) is detected after frame \(X_{t_{\rm on}}\) has been generated. In the counterfactual, cash is changed at the top of step \(t_{\rm on}\), before generating that frame. See `code/model-b/Compute-ModelB-BudgetToggle.jl:134`.

Thus, the intervention occurs immediately before the control’s detectable onset, not “at the moment of collapse.”

Either:

- Change the intervention time to \(t_{\rm on}+1\); or
- Describe it as a pre-onset intervention indexed by the control trajectory.

### 8. The description of \(c=1\) is incorrect

At `paper-arxiv/Paper_v1.tex:852`, the manuscript says \(c=1\) means exactly one neighbor is in a nonzero “Hold or Sell” state. Since Sell has value 2, \(c=1\) can only be three Buys and one Hold.

### 9. The financial-validation framing exceeds what is tested

Model A does not generate prices; QQQ prices drive its boundary. Feeding empirical data into a model is not empirical validation. Model B generates prices, but the paper does not systematically compare its returns with QQQ or benchmark stylized facts.

Avoid statements such as “validates the CA against empirical time series.” Say that QQQ data provide an empirical boundary forcing.

Either add a formal validation section or remove the broader claims about reproducing heavy tails, volatility clustering, and market behavior.

## Additional modeling qualifications

### Numeric state labels impose behavioral structure

The totalistic rule acts on the numeric sum of Buy \(=0\), Hold \(=1\), and Sell \(=2\). Relabeling these states changes the dynamics. The encoding therefore imposes an ordinal geometry on the actions and conflates different neighborhood compositions that share the same sum.

This is a valid modeling choice, but it should be justified explicitly. It also weakens the interpretation of Rule 19280 as a general “majority” rule.

### Deterministic escape differs from thermal activation

Within a run, the dynamics are deterministic. Variability in escape times comes from initial conditions and quenched rule placement across seeds. This is an ensemble of deterministic systems, not a single system exposed to thermal noise. “Kramers-like” should therefore be presented as a curve-shape analogy.

### The liquidity intervention is a strong wealth shock

The intervention scales every trader’s cash simultaneously. This is closer to a universal balance-sheet shock than an order-book liquidity operation, central-bank facility, or market-maker intervention. Applied policy claims should reflect that distinction.

## Reproducibility and build problems

### Manuscript build

- The committed PDF is stale: it has 15 pages and an older abstract.
- The current source compiles to 32 pages.
- The current build contains 11 missing bibliography keys, including the Kramers, Hänggi, Kyle, disposition-effect, Flash Crash, and liquidity-spiral references.
- `neurips_2026.sty` identifies itself internally as `neurips_2025`.
- Figures 9–12 float to pages 29–32, after the appendices.
- Page 28 is mostly empty because of float placement.
- The acknowledgments contain submission placeholders.
- `paper-arxiv/Build.sh` requires an undocumented positional argument and fails when invoked without one.

### Code execution

`code/run_all.sh` is obsolete:

- It references six scripts that no longer exist.
- It omits most current Model B campaigns.
- Its error handler turns failed commands into successful function returns, so the script can continue and finish after failures.

`code/data/README.md` is also incomplete. It does not describe most committed datasets, their schemas, their generating scripts, or whether they are raw, intermediate, or final artifacts.

The Model A lifetime results and fitted curve are not saved as a data artifact. Reproducing the headline fit requires rerunning an expensive simulation rather than inspecting a committed table.

Recommended reproducibility structure:

```text
code/
├── README.md
├── Project.toml
├── Manifest.toml
├── scripts/
│   ├── reproduce_model_a.jl
│   ├── reproduce_model_b.jl
│   └── reproduce_figures.jl
├── test/
│   └── runtests.jl
├── data/
│   ├── raw/
│   ├── derived/
│   └── README.md
└── figs/
```

Every headline table or figure should have one documented generating command.

## What checked out

All three substantive Model B test scripts passed:

- `code/model-b/Test-ModelB.jl`
- `code/model-b/Test-EscapeTime.jl`
- `code/model-b/Test-BoundaryVsBulk.jl`

The main stored results were recomputed from the committed files and agree with the manuscript:

- 10,800 Stage 2 runs: 6,589 oscillatory and 4,211 crash-prone.
- Between-configuration variance shares: 0.946–0.974.
- 897 crash-prone runs fell below 90; 451 fell below 80.
- 39 observed births, with 3 within distance 2 of the boundary.
- Cash injection accelerated 14 of 19 included pairs.
- The reported Model B fit parameters match the committed fit table.

The numerical transcription is therefore generally sound. The main problems are model interpretation, inferential strength, and incomplete reproducibility.

One smaller wording issue concerns the disposition-effect result. The reported \(2.40\times\) value is a ratio of marginal mean return standard deviations. It is not true “wherever” the switch was enabled: in 495 of 5,400 matched configurations, enabling the rule reduced return standard deviation. Use “increased return volatility by \(2.40\times\) on average.”

## Narrative and language

The manuscript has a compelling core story, but it is buried under repeated signposting and long, clause-heavy sentences. There are 58 explicit `Section~\ref{...}` references. Many Results paragraphs restate the question, method, result, and interpretation more than once.

### Recommended narrative spine

1. Define the CA and state exactly what Buy, Hold, and Sell mean.
2. Show the finite-horizon Model A crossover and spatial fronts.
3. Present mean-field and pair approximation as unsuccessful low-order descriptions.
4. Describe the onset-time fit as phenomenological evidence consistent with nucleation.
5. Introduce Model B and distinguish nucleation from post-onset growth.
6. End with the paired cash intervention and a restrained, model-specific interpretation.

### Specific editorial moves

- Cut Related Work by roughly half.
- Remove the paragraph that previews every section.
- Reduce repeated references to “three acts,” “five questions,” “spine,” “fate,” and “barrier.”
- Keep one principal result per sentence.
- Move qualifications next to the associated claim rather than several pages later.
- Replace “we settled,” “we interrogate,” and “the answer divided by stage” with direct verbs such as “we tested,” “we measured,” and “budgets affected growth but not detected onset.”
- Use Buy, Hold, and Sell consistently either as state labels or lowercase actions.
- Avoid restating figure captions in the main text.
- State the result first, then give the evidence.

### Example opening rewrite

Current style:

> Financial markets crash. They crash without proportionate external shocks, without advance warning from traditional risk metrics...

Suggested:

> Financial crashes can emerge without proportionate external shocks. We study whether a minimal spatial model can generate such events through local interactions alone. Traders occupy a two-dimensional grid and update one of three states—Buy, Hold, or Sell—from their four nearest neighbors. A fraction \(f\) follows a rule that differs from the majority rule at one neighborhood sum. We use \(f\) as the control parameter.

### Example abstract direction

> We study crash-like transitions in a deterministic, three-state cellular automaton on a two-dimensional grid. Interior agents update from their four nearest neighbors using one of two totalistic rules. Their mixture fraction \(f\) is the primary control parameter. In Model A, QQQ minute data drive a subset of boundary cells. The model shows a sharp finite-horizon crossover from a mixed state to a sell-dominated state, with sell domains that form locally and spread across the grid. Mean-field and pair approximations do not reproduce this behavior. Across random initial conditions and rule placements, onset times follow an inverse-distance empirical curve consistent with a nucleation interpretation. Model B replaces the external price with an endogenous feedback loop and filters orders through finite cash and share inventories. Budgets have little detectable association with onset in the present experiments, but they alter post-onset domain growth. A paired cash intervention supports a price-to-boundary feedback mechanism, although this result is specific to the model’s execution and market-maker assumptions.

## Recommended revision order

1. Correct the boundary conditions, edge count, data period, \(c=1\) description, and Potts normalization.
2. Decide whether to remove or substantially qualify the Potts and Kramers interpretations.
3. Reframe the transition as a finite-horizon crossover unless replicated finite-size evidence is added.
4. Rename Model B as a closed-feedback or endogenous-price model.
5. Repair the build, bibliography, run script, and data documentation.
6. Restructure the manuscript around the shorter narrative spine.
7. Perform sentence-level editing only after the scientific framing is stable.

The strongest recommendation is to revise the scientific framing before polishing individual sentences. Once “Potts,” “Kramers,” “first-order,” and “closed market” are stated at the appropriate level of confidence, the prose can become substantially shorter and clearer without losing the central result.
