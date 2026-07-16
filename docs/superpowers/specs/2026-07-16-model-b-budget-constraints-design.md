# Model B Budget Constraints — Design Spec

**Date:** 2026-07-16
**Predecessor:** `docs/superpowers/specs/2026-07-15-model-b-rebuild-design.md`
(Stage 1 rebuild, committed through `143f9b8`).
**Scope:** Add per-agent budget/inventory constraints to Model B and rerun the
Stage 1 diagnostic. Stage 2 (64×64 ensemble) remains deferred; this variant
becomes the definitive Model B on which Stage 2 runs.

## Goal

The rebuilt Model B assumes every agent trades one share per step with
unlimited cash, unlimited inventory, and guaranteed fills — the implicit
market-maker/price-impact tradition (Cont–Bouchaud, Bornholdt). This pass adds
agent-level reality: each trading cell carries a balance sheet (`cash`,
`shares`, `avg_cost`), only funded orders reach the market, and an optional
behavioral rule (the disposition effect) forbids selling below acquisition
cost. The Stage 1 diagnostic exposed a monotone one-sided price drift (φ > 0
for all 200 steps, edge agents pinned at Sell with no price-turning power);
finite budgets are the mechanism expected to make such runs self-limiting.

## Decisions (agreed 2026-07-16)

1. **Purpose** — constrained variant is the definitive Model B, built before
   Stage 2, not a robustness appendix and not a separate Model C.
2. **Trade semantics: flow.** A Buy-state cell attempts to buy 1 share every
   step it remains in Buy; a Sell-state cell attempts to sell 1 share.
   Rejected alternatives: trade-on-state-change (redefines φ; a static
   majority produces zero flow) and target-portfolio weights (adds a
   per-cell optimization layer).
3. **Constraint binds orders, never states.** An unfundable cell keeps its CA
   state — sentiment is free; you can want to buy while broke — but its order
   is not submitted and drops out of φ. The CA layer is completely untouched:
   rule tables, attractors, and all Model A results carry over verbatim.
   Rejected alternative: forcing unfundable cells to Hold (couples wealth
   into the contagion dynamics; invalidates the verified CA results for
   Model B's interior).
4. **Sell-side rule: inventory baseline + cost-basis toggle.** Baseline: a
   sell requires `shares ≥ 1`. With `cost_basis_rule = true`, a sell
   additionally requires the current price to exceed the cell's average
   acquisition cost. The toggle gives Stage 2 a clean ablation: mechanical
   budgets alone vs. budgets + behavioral asymmetry. The paper must name
   this rule as the *disposition effect* (Shefrin–Statman; Odean) — a
   documented behavioral bias, not rationality.
5. **Edge agents are full market participants.** Their band-dictated state
   proposes orders exactly like interior states; executed edge orders count
   in φ. This gives edge sell pressure direct price impact (attacking the
   Stage 1 pathology) and supersedes the 2026-07-15 rule that φ is strictly
   interior. Rejected alternatives: filtering the edge *displayed* state
   (inconsistent with decision 3) and leaving edges unconstrained
   (contradicts the premise).
6. **Counterparty: market maker with infinite inventory** (Farmer/Kyle
   batch-fill). Agents are constrained on their side; global share
   conservation is NOT enforced, because strict conservation requires a
   rationing/matching mechanism (who fills when buys ≠ sells) — large
   machinery for a second-order effect. The market maker's inventory is the
   slack variable. Out of scope, explicitly: order books, partial fills,
   bid-ask spreads, transaction costs, dividends/fundamental anchor,
   state-dependent λ, wealth-proportional order sizes.
7. **Execution price: the known price.** All affordability checks and fills
   at step t use P_{t-1} (the standing quote); the executed imbalance then
   moves the quote to P_t. Executing at the post-impact price would make
   affordability circular (fill price depends on who can afford to fill).

## 1. Updated step order (`code/src/Simulate.jl`)

Step `t` (for `t = 1..steps`) transforms `X_{t-1} → X_t`:

```
o_i     = desired order of trading cell i     # from X_{t-1} interior states
                                              # and e_{t-1} for active edges
                                              # (Buy → +1, Sell → −1, Hold → 0)
x_i     = execution filter at price P_{t-1}:  # x_i = o_i if funded, else 0
            buy  executes iff cash_i ≥ P_{t-1}
            sell executes iff shares_i ≥ 1
                 and (¬cost_basis_rule or P_{t-1} > avg_cost_i)
φ_{t-1} = Σ x_i / N_traders                   # EXECUTED imbalance
P_t     = P_{t-1} · exp(λ · φ_{t-1})          # log_return[t] = λ·φ_{t-1} exactly
settle  (executed orders only):
          buyer  cash −= P_{t-1}, shares += 1,
          avg_cost ← (avg_cost·shares_old + P_{t-1})/(shares_old + 1)
          seller cash += P_{t-1}, shares −= 1, avg_cost unchanged
μ_t, σ_t = EMA updates on P_t                 # unchanged from 2026-07-15 spec
e_t     = BandState(P_t, μ_t, σ_t, k)         # written into active edge cells
X_t     = CA step on interior of X_{t-1}      # unchanged
```

`N_traders = N_interior + N_active_edge`, fixed for the run. Passive boundary
cells never trade. The depth interpretation from the 2026-07-15 spec becomes
`Λ = N_traders/λ`. The identity `log_returns[t] = λ·net_imbalance[t]` is
preserved, with `net_imbalance` now holding the executed imbalance.

At t = 1 the edge desired order comes from the initial edge state (Hold), so
edges submit nothing on the first step — consistent with the previous spec's
zero-width initial band.

**Note:** all active edge cells hold identical books and display an identical
state, so they execute in lockstep (all or none). This is a consequence of
the shared band state, not a bug; heterogeneous edge endowments are a
possible Stage 2+ extension.

## 2. Balance sheets

Three full `nrows × ncols` matrices allocated per run: `cash::Float64`,
`shares::Int64`, `avg_cost::Float64`. Every cell is initialized to
(`initial_cash`, `initial_shares`, `P0`); only trading cells' entries ever
change. Average-cost accounting: basis updates on buys per the formula above
and is unchanged by sells (standard average-cost method); a cell whose
`shares` reaches 0 keeps its last `avg_cost` (harmless — the basis is only
consulted when `shares ≥ 1`).

## 3. Configuration (`Types.jl`, `Factory.jl`)

Three new `MyModelBConfiguration` fields, validated in the factory:

```julia
initial_cash::Float64      # ≥ 0; default 1000.0 (= 10·P0)
initial_shares::Int64      # ≥ 0; default 10
cost_basis_rule::Bool      # default true
```

Defaults give each cell symmetric capacity of ~10 steps of sustained
one-sided trading at P0, so constraints bind well inside a 200-step
diagnostic without binding at t = 1. Setting both endowments effectively
infinite (e.g. `1e12`) must recover φ_exec ≡ φ_desired.

## 4. Result (`Types.jl`)

`MyModelBSimulationResult` gains, following the existing indexing convention
(transition-like = length `steps`, state-like = length `steps+1`):

- transition-like `Vector{Int64}`: `executed_buys`, `executed_sells`,
  `suppressed_buys`, `suppressed_sells`. (Desired imbalance is derivable:
  φ_des = (exec_b + supp_b − exec_s − supp_s)/N_traders — no separate field.)
- state-like: `total_cash::Vector{Float64}`, `total_shares::Vector{Int64}`
  (sums over trading cells).
- final books: the three matrices at t = steps, stored in the result.

Crash statistics (`Compute.jl`) are unchanged — still computed from the full
`sell_fraction` trajectory.

## 5. Tests (`code/model-b/Test-ModelB.jl`)

1. A cell with `cash < P` in Buy state: order suppressed, CA state untouched,
   books unchanged.
2. A cell with `shares = 0` in Sell state: order suppressed.
3. Cost-basis toggle: with `shares ≥ 1`, sale blocked at `P ≤ avg_cost` when
   on, permitted when off; permitted at `P > avg_cost` either way.
4. Per-step accounting identity: Δ(total_cash) = −(exec_b − exec_s)·P_fill and
   Δ(total_shares) = exec_b − exec_s.
5. Average-cost update correct on a scripted buy/sell sequence.
6. Infinite-endowment limit: φ_exec == φ_des at every step.
7. Edge participation: all-Hold interior + edge forced to Sell with inventory
   ⇒ φ_exec < 0 (replaces the 2026-07-15 test asserting edges are excluded
   from φ, which is updated, not deleted).
8. Seeded reproducibility including books.
9. All-Hold null control: no trades ever execute, price constant.

## 6. Stage 1 diagnostic rerun (`code/model-b/Compute-ModelB.jl`)

Same run (32×32, 200 steps, seed 42), figure extended to 3×2 panels: price +
band, executed imbalance φ_exec, edge state, populations, executed vs. desired
volume, suppressed-order counts. Run twice — `cost_basis_rule` on (default)
and off — and log both summaries. Success criteria: the non-inertness
criteria from the 2026-07-15 spec still pass, suppressed-order counts are
nonzero (constraints demonstrably bind), and the working hypothesis is that
cash exhaustion around steps 10–20 breaks the monotone price climb. Whether
the price then reverses, plateaus, or oscillates is the empirical question —
any of those is acceptable for Stage 1; a still-monotone unbounded climb is
not, and would send us back to the endowment defaults.

## Implementation surface

| File | Change |
|---|---|
| `code/src/Types.jl` | 3 config fields; result fields (volumes, totals, final books) |
| `code/src/Factory.jl` | validation + defaults for the new fields |
| `code/src/Simulate.jl` | execution filter, settlement, φ over N_traders |
| `code/model-b/Test-ModelB.jl` | tests §5 (one updated, eight new) |
| `code/model-b/Compute-ModelB.jl` | 3×2 diagnostic, on/off comparison |

Model A (`code/model-a/`, `simulate(::MySimulationModel)`) is untouched.

## Paper implications (follow-up, out of implementation scope)

The Model B methods section must state: flow semantics (one share per step),
the execution filter, the market-maker counterparty with `Λ = N_traders/λ`,
edge participation in φ, and the cost-basis rule named as the disposition
effect with citations (Shefrin & Statman 1985; Odean 1998).
