# Model B Implementation Plan

Model B should be rebuilt in small, verifiable stages while leaving Model A untouched.

## 1. Define the update order unambiguously

At time step $t$, the interior grid acts first. Its net order imbalance is

$$
\phi_t = \frac{N_{\mathrm{buy},t} - N_{\mathrm{sell},t}}
{N_{\mathrm{interior}}}.
$$

The imbalance generates the next price:

$$
P_{t+1} = P_t \exp(\lambda \phi_t).
$$

The edge cells then observe that newly generated price:

$$
e_{t+1} = \operatorname{BandState}
(P_{t+1}, \mu_{t+1}, \sigma_{t+1}, k).
$$

Finally, the cellular automaton updates the interior grid:

$$
X_{t+1} = F(X_t, e_{t+1}).
$$

Thus, each simulation step follows this sequence:

```text
interior grid
    |
    v
order imbalance
    |
    v
new price
    |
    v
edge-cell decision
    |
    v
next interior grid
```

The Model B simulation loop should be rewritten in exactly this order, removing the current indexing ambiguity.

## 2. Use a controlled initial condition

An all-Hold grid is an absorbing state, so Model B needs a small symmetry-breaking perturbation.

The proposed default initial condition is:

- 90% Hold;
- 5% Buy;
- 5% Sell;
- perturb interior cells only;
- keep passive boundary cells in the Hold state;
- use exactly equal numbers of Buy and Sell cells initially;
- use a fixed random seed for reproducibility.

Because the initial global imbalance is zero, subsequent price movement arises from spatial CA evolution rather than from an arbitrarily bullish or bearish initial grid.

The implementation should support at least three initialization modes:

- `:all_hold`, as a stationary null control;
- `:balanced_perturbation`, as the default experiment;
- a user-supplied initial grid for custom experiments.

## 3. Make the boundary match the paper

Use a fixed, seeded 25% sample of actual boundary cells as price-responsive agents.

The remaining boundary cells should stay in the Hold state. This gives the model three distinct populations:

- active edge cells, which respond to the endogenous price;
- passive boundary cells, which provide a neutral fixed boundary;
- interior cells, which update using their assigned Wolfram rules.

The active boundary coordinates should be stored with the simulation result so that every run is reproducible.

## 4. Track the complete trajectory

Grid snapshots are appropriate for figures, but they are insufficient for computing time-series statistics.

At every step, the simulation result should record:

- price;
- log return;
- net order imbalance;
- Buy fraction;
- Hold fraction;
- Sell fraction;
- edge state;
- EMA price;
- EMA volatility or absolute-deviation estimate;
- lower and upper price-band values.

Full grid frames can remain sparse snapshots to avoid excessive memory use.

Crash frequency, crash duration, and related statistics must be calculated from the complete Sell-fraction trajectory, not from the small set of saved grid snapshots.

## 5. Separate configuration from experiments

Introduce a Model B configuration that explicitly contains the simulation assumptions and parameters:

```julia
steps
seed
initial_buy_fraction
initial_sell_fraction
edge_fraction
alpha
k
lambda
minority_fraction
rule_major
rule_minor
```

The Julia implementation can retain Unicode field names such as `α` and `λ` where appropriate.

`Compute-ModelB.jl` should then act as an experiment driver rather than containing hidden model assumptions.

## 6. Add focused tests

Before running a large simulation, test the following properties:

1. Positive interior imbalance increases the price.
2. Negative interior imbalance decreases the price.
3. Edge cells respond to the newly generated price, not the previous price.
4. Edge cells are excluded from endogenous price formation.
5. Passive boundary cells remain Hold.
6. The all-Hold null control remains stationary.
7. A balanced perturbation activates spatial dynamics.
8. Repeating a run with the same seed gives identical output.
9. Full-trajectory statistics use every simulation step.

## 7. Run experiments progressively

### Stage 1: diagnostic run

Start with a cheap diagnostic simulation:

- grid: $32 \times 32$;
- duration: 200 steps;
- seeds: one;
- output: price, imbalance, edge state, and population-fraction plots.

The purpose is to verify the feedback loop visually and numerically.

### Stage 2: small ensemble

Once the diagnostic works, run a modest ensemble:

- grid: $64 \times 64$;
- duration: 2,000 steps;
- seeds: 10--20;
- varied parameters: $\lambda$, $k$, and minority fraction $f$.

This stage should establish whether the observed dynamics are robust to the random spatial assignment and initial perturbation.

### Stage 3: production sweep

Only after the feedback mechanism is demonstrably working should the expensive $256 \times 256$ phase sweep be run.

## First implementation pass

The first implementation pass should:

1. rewrite the closed-loop update order in `code/src/Simulate.jl`;
2. add initialization and boundary-construction helpers;
3. extend the simulation result to store complete aggregate trajectories;
4. add the focused Model B tests;
5. replace the inert default experiment in `code/model-b/Compute-ModelB.jl`;
6. run and inspect the $32 \times 32$, 200-step diagnostic.

## Current baseline and known issues

The existing repository already contains the structural components of Model B: interior imbalance generates an endogenous price, and band-based edge agents respond to the price. It should be treated as a prototype rather than discarded.

The current known issues are:

- the default all-Hold initialization produces zero imbalance, a constant price, and permanently Hold edge agents;
- Model B currently defaults to only three active edge cells, while the paper describes 25% of boundary cells;
- phase-sweep crash statistics are calculated from approximately eight saved snapshots rather than the complete trajectory;
- the closed-loop timing is implemented with an indexing convention that is harder to interpret than the explicit order above;
- previous Model B results were inert, with zero returns and undefined higher-order return statistics.

The recommended strategy is therefore to restart the Model B experiment from a clean, tested baseline while preserving Model A, the CA machinery, and the paper structure.
