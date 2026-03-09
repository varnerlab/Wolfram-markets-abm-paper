# Project Memory: Wolfram Markets ABM Paper

## Project Overview
Agent-based model of financial markets using 2D Wolfram cellular automaton (CA) rules to simulate 3-state (buy/hold/sell) agent behavior. Based on CHEME-5660 week-15/L15a lecture.

## Key Files
- `paper/Paper_v1.tex` — main LaTeX document (NeurIPS 2026 preprint style)
- `paper/neurips_2026.sty` — NeurIPS style file
- `paper/Build.sh` — pdflatex + bibtex build script
- `paper/sections/` — introduction, relatedwork, background, method, results, conclusion, appendix (all stubs)
- `paper/References_v1.bib` — bibliography
- `code/model-a/` — Julia simulation code
- `code/src/Simulate.jl` — Model A + B simulation loops
- `code/data/` — JLD2 simulation outputs, CSVs

## Current Rules — Original Course Pair (as of 2026-03-09)

Decision: went with **option 2** — original course rules 19280 + 19286.

### Current Compute-ModelA.jl
- Major rule: **19280** — stable majority/herding rule
- Minor rule: **19286** — contrarian/destabilizer (interprets all-buy as sell signal)
- Edge agents: 25% of boundary cells, fixed seed 1234, α=1/60, k=1.0
- Grid: 256×256 (homogeneous + crash), 128×128 (phase sweep)

### Phase Sweep Results (Rule 19280 + 19286, 128×128, full QQQ series)

**Coarse sweep:**
| f    | mean_sell | max_sell | crash_freq |
|------|-----------|----------|------------|
| 0.00 | 0.250     | 0.274    | 0.0        |
| 0.05 | 0.254     | 0.277    | 0.0        |
| 0.10 | 0.258     | 0.283    | 0.0        |
| 0.15 | 0.506     | 0.932    | 0.404      |
| 0.20 | 0.891     | 0.933    | 0.958      |
| 0.25 | 0.904     | 0.924    | 0.987      |
| 0.30+ | ~0.91    | ~0.93    | ~0.99      |

**Fine sweep (f = 0.08–0.22, step 0.01):**
| f    | mean_sell | max_sell | crash_freq |
|------|-----------|----------|------------|
| 0.12 | 0.261     | 0.289    | 0.0        |
| 0.13 | 0.265     | 0.297    | 0.0        |
| 0.14 | 0.266     | 0.302    | 0.0        |
| 0.15 | 0.506     | 0.932    | 0.404      |
| 0.16 | 0.764     | 0.938    | 0.862      |
| 0.17 | 0.815     | 0.935    | 0.850      |
| 0.20 | 0.891     | 0.933    | 0.958      |

### KEY FINDING: Sharp first-order phase transition
- **Critical fraction f_c ≈ 0.145** — discontinuous jump from stable to crash-dominated
- No intermediate "intermittent crashes" regime — system snaps from ~26% sell to ~50% sell
- Above f_c, saturation is fast (96% crashed by f=0.20)
- Homogeneous model (f=0): stable, φ ≈ +0.23, std 0.009, no crashes
- Crash model (f=0.20, 256×256): sell-dominated, φ ≈ −0.89, permanently crashed
- Most interesting dynamics at f=0.15 (intermittent crash cascades)

### Previous Rule Screen (archived — superseded by course rules)
- Screened rules 16014/2465 had contrarian pre-filter bug (digit[8]=0 = crash damper)
- Screen files still in `code/data/`: RuleScreen-v3-Pass1.csv, RuleScreen-v3-Pass2.csv

## User Preferences
- Julia for simulation code
- NeurIPS style for paper
- Paper template modeled on varnerlab/stochastic-attention-study-paper
