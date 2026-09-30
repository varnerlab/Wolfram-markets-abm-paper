# Spoken pitch (about one minute)

In our simulated market, a trader can sell every share and still tell its
neighbors to sell. Does that assumption keep a selling cascade alive?

This project changes one thing: when a seller has no shares, its neighbors
see Hold instead of Sell. The trader keeps its own intention, and trades
still use the corrected dealer mechanism. The two diagrams show the same
empty seller under these two observation rules. They do not predict what
the neighbors will do.

The team will extend the Julia simulator and compare matched markets,
with and without the rule change that starts the cascade. We will measure
intentions, completed sales, and price drawdowns separately. We will also
hold technical traders inactive to see whether inventory now creates its
own route from financial resources to later decisions.

The deliverables are tested, reproducible Julia code and a paper in arXiv
format. A weaker cascade, a stronger cascade, or a well-measured small
difference would all answer an explicit open question in the manuscript.

## Likely questions

**Why not hide every order that fails?**
The core experiment isolates inventory exhaustion. Whether a buy can execute
depends on the endogenous batch price, and whether an eligible order fills
also depends on the counterparty. Those would change the question.

**Why substitute Hold?**
The existing rule table requires one of three states from each of four
neighbors. Hold is an explicit modeling choice for an inactive visible
signal. Deleting a neighbor or entering zero would have different meanings:
zero is Buy in this model.

**Does this remove an agent's intention or its order?**
No. The mask acts only on the state supplied to neighbors after settlement
and before the next interior update. The agent retains its raw intention.
Orders continue to face the existing resource and clearing constraints.

**Has the repository already studied signal transmission?**
Yes, in separate advice/following experiments. This project specifically tests
the inventory-dependent visibility of local Sell intentions in the persistent
rule-switch experiment. The manuscript explicitly identifies that gap.

**What result do you expect?**
The hypothesis is weaker spreading, but the lookup table is not monotone in
the neighbor sum. Replacing Sell with Hold can produce other responses, so
amplification is possible. The experiment measures the effect rather than
assuming its sign.

**What is the semester scope?**
The planning assumption is 3–4 students and 14 weeks. Benchmark a small pilot,
then execute a proposed 2,000-trajectory confirmation design. Preserve the
primary comparison if compute limits require fewer secondary conditions.

**Does the project predict real crashes?**
It tests a structural assumption in this simulator. Market calibration and
forecasting are outside its scope.

## Source notes

All paths are relative to the repository root, inspected September 28, 2026
at commit `81cfd17`.

- `paper-arxiv/sections/discussion.tex`: explicitly untested visibility assumption.
- `paper-arxiv/sections/methods.tex`: states, timing, switch, controls, outcomes.
- `code/src/Simulate.jl`: post-settlement update sequence and observation hooks.
- `code/src/ReserveClearing.jl`: integer inventory and uniform batch execution.
- `code/rebuild/README.md`: corrected-study source and reproduction.
- `code/repaired/README.md`: related advice/transmission studies and reserve tests.

The slide is a conceptual diagram. No new simulations were run to create it.
