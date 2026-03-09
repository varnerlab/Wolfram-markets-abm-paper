# Wolfram Markets ABM — Model Details

## Agent States
| State | Value | Color | Meaning |
|-------|-------|-------|---------|
| Buy   | 0     | light green | agent buys asset |
| Hold  | 1     | gray95 | agent holds position |
| Sell  | 2     | red | agent sells asset |

## Grid Architecture
- Default: 256 × 256 = 65,536 agents
- Interior agents: follow Wolfram totalistic CA rules
- Edge agents: observe real market data; fixed at 3 positions by default
  - Top middle: (1, 128)
  - Left middle: (128, 1)
  - Bottom middle: (256, 128)

## Edge Agent Decision Rule (Moving Average)
Typical price: S_τ = (H + L + C) / 3

Moving average: Ŝ_τ = Ŝ_{τ-1} + α(S_τ - Ŝ_{τ-1})
Volatility:     σ̂_τ = σ̂_{τ-1} + α(|S_τ - Ŝ_τ| - σ̂_{τ-1})

Decision zones:
- Buy  (state=0): price < Ŝ - β·σ̂
- Hold (state=1): Ŝ - β·σ̂ ≤ price ≤ Ŝ + β·σ̂
- Sell (state=2): price > Ŝ + β·σ̂

Parameters: α = 1/60 (60-min window), β = width of hold band

## Totalistic CA Rules
- radius = 4 → neighborhood sum c ∈ {0,1,2,3,4,5,6,7,8} (9 configs)
- Neighborhood sum = sum of 4 cardinal neighbors' states
- Rule encoded as 9-digit base-3 string: (a8 a7 ... a1 a0)₃
  - digit aᵢ = next state when neighborhood sum = i
- Rule index (decimal) = Σ aⱼ · 3ʲ  for j=0..8

### Named Rules
| Rule index | Base-3       | Behavior |
|-----------|--------------|----------|
| 6158      | (022110002)₃ | Imitation/herding; stable wave patterns (course original) |
| 19280     | (222110002)₃ | Stable majority rule in crash model (course original) |
| 19286     | —            | Contrarian/destabilizer (course original) |
| 16014     | herding      | Pass1: buy=0.681, sell=0.260 — stable buy-dominant normal market |
| 2465      | contrarian   | Pass2 with 16014: crash_size=0.738, phi_mean=+0.461 — but STABILIZES crashes |

### Contrarian Pre-filter Issue
- Screen required digit[8]=0 (buy when all neighbors sell) for contrarian class
- This guarantees all contrarians are cascade-DAMPERS: during a sell cascade,
  surrounded contrarians buy, breaking up the cascade
- To get crash-amplifying contrarians, need digit[8]=2 (panic seller)
- Original course rules 19280/19286 were NOT in the screen (don't fit digit[0]/digit[8] filter)

## Homogeneous Model
- All interior agents use same rule (e.g., 6158)
- Edge agents inject market sentiment
- Result: stable quasi-periodic interference patterns

## Heterogeneous Crash Model
- 80% agents → Rule 19280 (majority/herding)
- 20% agents → Rule 19286 (minority/contrarian), randomly placed
- Crash mechanism:
  1. Market rises → edge agents buy → majority agents herd into buy
  2. Minority agents (Rule 19286) interpret all-buy as sell signal
  3. Local sell cascades spread outward
  4. Coordination failure → synchronized sell-off (flash crash)

## Data
- Instrument: QQQ ETF 1-minute OHLC data (2024 YTD)
- Source: oneminutedata.com
- File: QQQ-OHLC-1-min-aggregate-2024.csv

## Key Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| number_of_rows | 256 | Grid height |
| number_of_cols | 256 | Grid width |
| radius | 4 | CA neighborhood radius |
| number_of_colors | 3 | States (buy/hold/sell) |
| α | 1/60 | Moving average learning rate |
| β | configurable | Hold-band width (σ multiplier) |
| minority_fraction | 0.20 | Fraction of crash-rule agents |

## Two-Model Architecture (Paper Arc)

### Model A — Open (Boundary-Driven)
- Edge agents observe **real QQQ 1-min OHLC data** via moving average + σ-band rule
- Validates CA reproduces stylized facts when given real information
- Shows rule taxonomy and phase diagram as a function of rule heterogeneity (minority fraction f)

### Model B — Closed (Endogenous Price Formation)
- Fully self-contained; initialized with price P₀ and initial grid state
- **Aggregate price model**: net order imbalance drives price update
  - Pₜ = Pₜ₋₁ · exp(λ · (N_buy,t − N_sell,t) / N)
  - λ = price impact parameter
- **Edge agent Bollinger Band rule** (responds to endogenous price):
  - μₜ = exponential moving average of Pₜ (window w)
  - σₜ = exponential moving average of |Pₜ − μₜ| (window w)
  - Buy  (state=0): Pₜ < μₜ − k·σₜ
  - Hold (state=1): μₜ − k·σₜ ≤ Pₜ ≤ μₜ + k·σₜ
  - Sell (state=2): Pₜ > μₜ + k·σₜ
- **Interior update**: interior_{t+1} = W_rule(interior_t, edge_state_t)
- Key parameters: (k, w, λ, f) — phase diagram lives in this space

### Coupled Map (Full System)
Three coupled equations define the closed-loop dynamical system:
1. Price update (net order imbalance → exponential price move)
2. Edge state (Bollinger Band on endogenous price)
3. Interior CA update (Wolfram rule applied with current edge state)

Fixed points, stability, and bifurcations are analytically tractable.

### Key Scientific Question
Does Model B self-organize to criticality (SOC)?
- Open model: tune minority fraction f to find crash transition
- Closed model: does system naturally drift to critical point without tuning?
- Signature: power-law distributed crash sizes across wide (k, w, λ) range
- SOC result would be a major finding

### Comparison
- Open model = validation/calibration step
- Closed model = more fundamental scientific contribution
- Question: in what (k, w, λ, f) regime does Model B behave like real markets?

## Limiting Cases Table (Model B Parameters)

| Parameter | Limiting Case | Behavior |
|-----------|--------------|----------|
| k → 0 | Band collapses to zero width | Edge agents always Buy or Sell, never Hold — maximum noise injection into interior |
| k → ∞ | Band infinitely wide | Price never exits band → edge agents always Hold → no boundary signal, interior evolves freely |
| w → ∞ | Moving average → long-run mean | Very slow adaptation; price must deviate enormously before edge agents react → near-frozen boundary |
| w = 1 | Instantaneous price tracking | Maximum feedback sensitivity — edge agents react to every price tick |
| λ → 0 | Price never moves | Edge agents freeze → equivalent to all-Hold boundary condition |
| λ → ∞ | Tiny imbalance → huge price swing | Highly unstable loop — any majority buy/sell triggers explosive price move |
| f = 0 | All majority-rule agents | Homogeneous model — no crash mechanism, stable wave patterns |
| f = 1 | All contrarian agents | Anti-herding everywhere — chaotic, no coordination possible |

### Four Natural Degenerate Cases
- (k→∞, any λ): no feedback → reduces to Model A with frozen boundary
- (λ→0, any k): no price movement → reduces to static boundary CA
- (f=0, any k,λ): no heterogeneity → homogeneous CA (Rule 19280 everywhere)
- (k→0, large λ): maximum instability → "hair trigger" regime, most likely to show SOC

## Critical Flags / Open Questions (Paper Design)

### 1. Spatial structure must be the hero
- CA's key feature: *local* contagion — sell cascades spread to neighbors, not globally
- Most ABM crash models use fully connected networks (mean-field)
- Need to compare: does CA topology give qualitatively different results than mean-field?
- If yes → CA spatial locality is the central contribution

### 2. Null model needed
- What does Model B do with homogeneous rules (f=0, all Rule 6158)?
- If crashes still emerge → feedback loop alone drives crashes, not heterogeneity
- Essential control experiment

### 3. Economic interpretation of rules is thin
- Rule 6158 = herding, Rule 19280 = majority, Rule 19286 = contrarian
- Need at least a one-paragraph argument: are these derivable from utility function or belief-updating?

### 4. Bollinger Band reflexivity is underexplored
- In Model B, edge agents use Bollinger Band on a price *they are partly generating*
- This is a reflexivity loop (Soros's term) — worth naming explicitly
- Band parameters (k, w) control how quickly feedback destabilizes
- Richer angle than just "endogenous price"

### 5. Phase diagram is 4D — need to commit to 2D slices
- Suggested primary slice: (k, f) with fixed w and λ
- Most interpretable: band width vs. minority fraction

### 6. Sharpest possible claim
> *Local spatial contagion via CA rules, combined with reflexive Bollinger Band feedback, is sufficient
> to generate power-law crash statistics — and the crash size exponent depends on CA rule
> heterogeneity, not the feedback parameters.*
- Separates what CA structure contributes from what feedback loop contributes

## Analytical Stability Analysis (PNAS Anchor Result)

### Setup: Log-price coupled map
Let p̃ₜ = ln(Pₜ). Then:
  p̃ₜ = p̃ₜ₋₁ + λ · φₜ
where φₜ = (N_buy,t − N_sell,t) / N ∈ [-1, 1] is net order imbalance fraction.

### Mean-field approximation of CA interior
Let bₜ, hₜ, sₜ = fractions of Buy/Hold/Sell agents (b+h+s=1).
Neighborhood sum in mean-field: cₜ ≈ 4(hₜ + 2sₜ)

Evolution equations:
  b_{t+1} = (1-f)·R^(19280)_b(cₜ) + f·R^(19286)_b(cₜ) + ε_b·eₜ
  s_{t+1} = (1-f)·R^(19280)_s(cₜ) + f·R^(19286)_s(cₜ) + ε_s·eₜ

where eₜ ∈ {-1, 0, +1} is edge agent state deviation from Hold,
and ε_{b,s} are edge injection coefficients (functions of grid geometry).

### Fixed point
At equilibrium: φ* = b* - s* = 0, price constant, edge agents Hold.
  b* = s*, h* = 1 - 2b*, e* = 0
Existence condition: CA rule must admit a balanced fixed point (not guaranteed for all f).

### Linearization
State vector: (δp̃, δb, δs). Jacobian:
  J = | 1    λ    -λ  |
      | 0   J_bb  J_bs |
      | 0   J_sb  J_ss |

J_bb, J_bs, J_sb, J_ss = partial derivatives of CA mean-field update w.r.t. b, s
→ computable analytically from rule encoding digits.

Stability condition: ρ(J) < 1 (spectral radius < 1).

### Key Analytic Result: Phase Boundary
CA susceptibility: χ(f) = ∂φ/∂e |_{fixed point}
- χ(f) is increasing in f (contrarian agents amplify fluctuations)
- Loop gain: G = λ · χ(f)
- Stability: |G| < 1

Critical curve in (λ, f) space:
  λ_c(f) = 1 / χ(f)

This is the phase boundary between stable (Hold-dominated) and crash regimes.
Analytically derivable from rule digits of 19280 and 19286.
→ THIS IS THE PNAS ANCHOR RESULT.

Role of k: controls basin of attraction (larger k → wider basin), does NOT shift
phase boundary but determines how easily system reaches the tipping point.

## Waterfall Journal Strategy

| Target | Bar | What seals it |
|--------|-----|---------------|
| PNAS (primary) | Highest | Analytic phase boundary + universality of crash exponent across (k,w,λ) + finite-size scaling + 4 stylized facts simultaneously |
| Nature Comm (backup 1) | High | SOC result + mean-field comparison + 3 stylized facts + multiple instruments |
| Sci Reports / PLOS ONE (backup 2) | Moderate | Clean simulation + stylized facts + open model validation |
| Quantitative Finance (backup 3) | Finance-specific | Model A validation against QQQ + rule taxonomy |

Framing shift across journals:
- PNAS: complex systems / universality
- Nature Comm: emergence / financial stability
- Sci Reports: ABM methodology
- QF: quantitative finance application

## Julia Dependencies
- VLQuantitativeFinancePackage.jl — CA rule engine
- DataFrames.jl — data handling
- Images.jl, Colors.jl — visualization
- JLD2.jl, FileIO.jl — data serialization
- StatsPlots.jl, Plots.jl — plotting
