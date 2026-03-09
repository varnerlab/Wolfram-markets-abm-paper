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

## Current Rule Status (as of 2026-03-09) — see rules.md for full notes

### Rule Screening
- Screen: `Compute-RuleScreen-v3.jl` — 25% boundary edge agents, QQQ-coupled
- Pass1 CSV: `RuleScreen-v3-Pass1.csv` — 2187 herding + 2187 contrarian rules at 64×64
- Pass2 CSV: `RuleScreen-v3-Pass2.csv` — 2500 pairs (top-50 herding × top-50 contrarian) at 128×128

### Current Compute-ModelA.jl (as of session end)
- Major rule: **16014** (herding, Pass1: buy=0.681, sell=0.260, has_all=true)
- Minor rule: **2465** (contrarian, Pass2 rank with 16014: crash_size=0.738, phi_mean=+0.461)
- Edge agents: 25% of boundary cells, fixed seed 1234, α=1/60, k=1.0

### Phase Sweep Results (Rule 16014 + 2465, 128×128, full QQQ series)
| f    | mean_sell | max_sell | crash_freq |
|------|-----------|----------|------------|
| 0.00 | 0.205     | 0.969    | 0.0014     |
| 0.05 | 0.159     | 0.921    | 0.0002     |
| 0.10 | 0.168     | 0.873    | 0.0001     |
| 0.15 | 0.192     | 0.824    | 0.0001     |
| 0.20 | 0.239     | 0.775    | 0.0        |
| 0.30 | 0.352     | 0.679    | 0.0        |
| 0.40 | 0.357     | 0.581    | 0.0        |
| 0.50 | 0.331     | 0.484    | 0.0        |

### KEY FINDING: Contrarian pre-filter bug
- All contrarian rules in screen have `digit[8]=0` (buy when all neighbors sell)
- This makes every screened contrarian a CRASH DAMPER, not crash amplifier
- Rule 2465 stabilizes cascades — crash_freq DECREASES as f increases
- Homogeneous model (f=0) has the MOST crashes (rare but extreme: max_sell=0.969)

## Three Paths Forward (decision pending — user moving to new machine)
1. **Re-screen with `digit[8]=2` contrarians** — find minority rules that amplify sell cascades (new Compute-RuleScreen-v4.jl, ~1-2 hours)
2. **Use original course rules (19280 + 19286)** — purpose-built for crash; test directly at 256×256 without full screen (fastest)
3. **Reframe as "diversity dampens crashes"** — f=0 crashes, heterogeneity stabilizes; valid science, no new computation needed

## Phase Sweep Fix (done)
- Old sweep sampled only 8 log-spaced frames → crash_freq always 0.0
- New sweep in `Compute-ModelA.jl` uses inline lean loop at 128×128, tracks sell_frac at EVERY step

## User Preferences
- Julia for simulation code
- NeurIPS style for paper
- Paper template modeled on varnerlab/stochastic-attention-study-paper
