# Figure and Narrative Revision — Design Spec

**Date:** 2026-07-27
**Predecessor:** `22edc60` (seven-section style review; Background merged into
Methods, Results I + theory bridge + Results II collapsed into one flat
`\section{Results}`, zero section self-references, zero em dashes in prose).
**Trigger:** author review of `22edc60`. Two complaints: the figures are poor
quality, and the narrative arc is poor because the paragraphs are short and
choppy. Author named `/Users/jdv27/Desktop/papers/Kompala-Model-LP-Paper` as
the reference for their writing style.
**Scope:** figure quality and paper narrative only. No new simulations, no
changed results.

## Supersedes

Decision 7 of `2026-07-20-nucleation-spine-restructure-design.md` ("Results
and Discussion keep subsection headings in the arXiv version") was reversed on
2026-07-27 in `22edc60`. Results is now a single flat section with no
subsections, and stays that way.

## The measured gap

Against the Kompala exemplar:

| | Kompala | This paper (at `22edc60`) |
|---|---|---|
| Results paragraphs | 5, at 248-328 words | 21, median ~150 words, several under 60 |
| Discussion paragraphs | 5, at 137-447 words | 3, at 137-279 words |
| Introduction paragraphs | 3, at 197/248/235 words | 3, at 175/163/350 words |
| Figures | 8 | 13 plus a TikZ schematic (~45 panels) |
| Figure style | one deliberate house style | one script styled, eleven at Plots.jl defaults |

Seven of the thirteen figures are Model B nucleation diagnostics, one per
campaign. The paper is organized as a tour of experiments rather than as an
argument, which produces both the fragmented Results and the figure-per-result
inflation. The two complaints have one root cause.

## Decisions (settled during brainstorming, 2026-07-27)

1. **Depth:** re-arc and restyle. Rebuild the Results around load-bearing
   claims and regenerate every figure in the house style. Not a full rebuild:
   the file stays monolithic, no split into `sections/*.tex`.
2. **Spine:** nucleation. A crash is born in the bulk from a single-cell
   fluctuation and gated in its growth at the boundary; budgets move growth,
   not birth.
3. **Beats:** six, in the order below. One dense paragraph and one figure each.
4. **Displaced panels:** demoted to supplementary figures, not cut. Every
   figure gets the quality pass, main and supplementary alike.
5. **Palette:** adopt the Okabe-Ito set already defined in the paper preamble
   across all twelve plotting scripts, rather than importing a second palette
   from the Kompala repository. The schematic already uses it; the data
   figures use Plots.jl defaults. One palette for the whole paper, and
   Figure 1's legend then matches Figures 2 through 7.
6. **Source formatting:** one paragraph per unwrapped source line, as the
   Kompala section files are. Hard-wrapping at 90 characters is what let the
   fragmentation hide.

## Goal

A reader should be able to follow one argument through six figures. Each
Results paragraph opens with what was done and a generic statement of what was
observed, cites the whole figure, develops the specifics in the body, and
transitions explicitly to the next question. No paragraph under 250 words in
Results.

---

## Part 1: Figure system

### 1.1 Shared style module

New file `code/src/PaperStyle.jl`, included by every plotting script. Ported
from the Kompala scripts:

```julia
bg = :gray95
background_color_outside = :white
framestyle = :box
fg_legend = :transparent
lw = 4                    # 1.5 with alpha for per-seed overlays
```

Palette. The paper preamble already defines an Okabe-Ito colorblind-safe set
that only the TikZ schematic uses; the twelve Julia scripts specify no colors
at all and inherit the Plots.jl default cycle. The schematic and the data
figures therefore do not currently share a color language, which is a large
part of why the figures read as unrelated. The fix is to adopt the existing
definitions everywhere rather than import a second palette:

| Role | Color | Already defined as |
|---|---|---|
| Buy | `#0072B2` blue | `buyblue` |
| Hold | `#AAAAAA` gray | `holdgray` |
| Sell | `#D55E00` vermillion | `sellorange` |
| Edge / boundary | `#009E73` green | `edgegreen` |

Non-state series (cash levels, configurations, doses, arms) draw from the rest
of Okabe-Ito, so the whole paper stays on one palette: `#E69F00` orange,
`#56B4E9` sky blue, `#CC79A7` purple, `#F0E442` yellow, `#000000` black.

Conventions, all currently violated somewhere:

- Axis labels capitalized, carrying units, wrapped onto two lines where long.
  Current labels read `step` and `largest cluster / grid`.
- Legends inside the panel, transparent frame.
- **No titles inside the figure.** `ModelB-Nucleation-SeedSweep.pdf` currently
  burns "Nucleation probe across 20 seeds" into the image; that belongs in the
  caption.
- Panel letters (A, B, C, D) drawn in-figure at the top left of each panel, and
  referenced as `\textbf{(A)}` in captions. Captions currently say "(Top row)"
  and "(Bottom left)", which breaks whenever a panel moves.

### 1.2 Main figures

Seven, one per beat plus the schematic, each capped at four panels.

| Fig | Beat | Panels | Sourced from |
|---|---|---|---|
| 1 | — | schematic | TikZ, unchanged |
| 2 | 1 | A snapshot montage, B mean sell fraction, C crash frequency | `Fig2-Combined`, `Fig3-PhaseDiagram` |
| 3 | 2 | A conversion fraction vs f, B coefficient of variation, C median conversion time, D rescaled collapse | `Figs-ModelA-FiniteSize` |
| 4 | 3 | A Potts energy and entropy, B spectral radius, C cluster sizes | `Figs-ModelA-Theory` |
| 5 | 4 | A largest-cluster ratio at peak, B birth-site map, C pooled distance-from-boundary vs uniform null, D ring-attachment timing | `SeedSweep`, `BirthSites` |
| 6 | 5 | A Kaplan-Meier medians and fits, B dominance rate across six cells, C velocity vs suppression, D velocity by cash | `BarrierLaw`, `Seeding`, `VelocitySuppression` |
| 7 | 6 | A paired velocities under injection, B paired velocities under both withdrawals, C edge ring at toggle under injection, D edge ring under withdrawal | `BudgetToggle`, `EdgeTrace` |

### 1.3 Supplementary figures

Restyled to the same standard, referenced from the Results text.

| SI | Content | Displaced from |
|---|---|---|
| S1 | Model B regime exemplars (price, state fractions, suppressed orders) | currently a main figure |
| S2 | Per-seed cluster trajectories, three configurations; final cluster fraction | `SeedSweep` |
| S3 | Peak sell fraction vs f | `Fig3-PhaseDiagram` |
| S4 | Fitted `f_0` and `B` per cash level; onset fraction vs f | `BarrierLaw` |
| S5 | Full seeding design: onset per seed, growth trajectories | `Seeding` |
| S6 | Full budget-toggle cluster trajectories; full three-arm edge trace | `BudgetToggle`, `EdgeTrace` |

### 1.4 Data

Every figure regenerates from data already on disk. The CSVs are committed
(`.gitignore` un-ignores `ModelB-Nucleation-*`, `ModelA-FiniteSize*`,
`ModelA-Avrami*`, `ModelA-OnsetTime*`, `ModelB-Stage2-*`). The `.jld2` files
that back the grid snapshots, the phase sweep, and the Model B exemplars are
gitignored but present locally. No simulation is re-run and no value changes.

---

## Part 2: Prose

### 2.1 Results, six paragraphs

Each 300-400 words, opening with action plus a generic observation and a
whole-figure citation, specifics in the body, explicit transition out.

1. **The crossover and the front.** Local rules alone produce a sharp
   finite-horizon crossover between f = 0.14 and f = 0.15, and above it
   localized sell domains grow as spatially coherent fronts (Fig 2).
2. **The threshold is extrinsic.** It moves with lattice size, conversion time
   self-averages as N^(-1/2), and the conversion-curve exponent near 2
   identifies growth from regions fixed at setup rather than ignition at
   random times (Fig 3).
3. **The transition needs space.** Neither the mean-field map nor the pair
   closure reproduces the crossover; the mixed branch stays linearly stable at
   every f and the spatial mutual information vanishes (Fig 4).
4. **The nucleus is spatial and bulk-born.** Under budgets the crossover
   survives, above threshold the sell cells gather into one dominant domain,
   and the founding cell sits in the deep bulk rather than on the active-edge
   ring (Fig 5).
5. **Budgets gate growth, not birth.** Onset times are equivalent within a
   factor of two across a tenfold cash range, a stamped patch never founds the
   winning domain, and front velocity falls as realized suppression rises
   (Fig 6).
6. **The intervention is asymmetric.** Injection accelerates the front by
   flipping the contrarian boundary from buying to selling, while withdrawal is
   inert at both doses because the brake is already engaged and crashes
   self-finance their own dip-buyers (Fig 7).

### 2.2 Introduction, three paragraphs

Reshaped to the Kompala proportions, roughly 200 / 250 / 235 words. The
current third paragraph is 350 words and carries both the method description
and every result; split the load so the closing paragraph states what was done,
what was observed, and the interpretation without becoming a results dump.

### 2.3 Discussion, five paragraphs

Following the Kompala arc rather than the current three-paragraph shape:
an opening question, the mechanism developed at length, the interesting edge
case, the relation to the adjacent literature, and limitations. The current
limitations paragraph is the strongest in the section and stays largely intact.

### 2.4 Conclusion

Unchanged at three paragraphs. It was fixed in `22edc60` and matches the
exemplar's proportions already.

---

## What does not change

- No simulation re-run; every reported number is preserved exactly.
- No split into `sections/*.tex`; the file stays monolithic.
- Results stays one flat section with no subsections.
- Methods keeps its seven subsections; Related Work keeps its three.
- Buy/Hold/Sell state colors and the TikZ schematic itself. The data figures
  move onto the schematic's palette, not the reverse.
- The Acknowledgments and the 182-word abstract remain author-owned and
  untouched.

## Verification

- Build clean: zero LaTeX warnings, zero undefined citations or references.
- Every numeric claim in the revised prose re-derived from the committed CSVs
  and diffed against its value at `22edc60`. Any difference is a bug.
- No Results paragraph under 250 words; no figure carrying an in-figure title;
  every caption using `\textbf{(A)}` panel letters rather than positional
  language.
- The style checks from `22edc60` stay at zero: section self-references, em
  dashes in prose, bullets, subsubsections, figure-as-subject sentences.
