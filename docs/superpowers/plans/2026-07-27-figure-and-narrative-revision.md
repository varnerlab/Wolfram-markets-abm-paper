# Figure and Narrative Revision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the paper's thirteen figures onto one deliberate house style consolidated into seven main plus six supplementary, and rebuild Results as six dense paragraphs so the paper reads as an argument rather than a tour of experiments.

**Architecture:** A single shared style module in `code/src/PaperStyle.jl` replaces the palette blocks currently triplicated across three `Include.jl` files and the ad-hoc `_panel_kw` living inside one script. Three figures that are currently side effects of compute scripts are first made standalone-reproducible by persisting their trajectory data, then all figures are regenerated through `Figs-*` scripts driven by `run_all.sh figures`. Prose is rewritten last, against final figures, so panel letters and figure numbers are only written once.

**Tech Stack:** Julia 1.x with Plots.jl (GR backend), DataFrames, CSV, JLD2; LaTeX (pdflatex + bibtex) via `paper-arxiv/build.sh`.

## Global Constraints

- **Spec:** `docs/superpowers/specs/2026-07-27-figure-and-narrative-revision-design.md`. Read it before starting.
- **No reported value may change.** Every number in the prose must still match the committed CSVs and its value at `22edc60`. Any difference is a bug, not a result.
- **Palette is Okabe-Ito, already defined in the paper preamble:** Buy `#0072B2`, Hold `#AAAAAA`, Sell `#D55E00`, edge `#009E73`. Non-state series draw from `#E69F00`, `#56B4E9`, `#CC79A7`, `#F0E442`, `#000000`.
- **No titles inside any figure.** The caption does that work.
- **Panel letters** are drawn in-figure at the top left and referenced in captions as `\textbf{(A)}`, never as "(Top row)" or "(Bottom left)".
- **Results stays one flat `\section{Results}` with no subsections.** Do not reintroduce subsection headings.
- **No Results paragraph under 250 words.**
- **Style gates from `22edc60` stay at zero:** section self-references (including soft prose pointers such as "Results II" used as a pointer), em dashes in prose, `itemize`/`enumerate`, `\subsubsection`, figure-as-subject sentences.
- **Do not touch** the Acknowledgments or the abstract. Both are author-owned.
- Run Julia from the repo root as `julia --project=code code/<dir>/<script>.jl`.
- Build the paper with `cd paper-arxiv && bash build.sh Paper_v1`.

---

## File Structure

**Created:**
- `code/src/PaperStyle.jl` — the single source of truth for palette, panel keywords, and panel-letter annotation. Included by all three `Include.jl` files.
- `code/model-b/Figs-ModelB-SeedSweep.jl` — standalone plotting for the seed sweep, replacing the side-effect emission inside `Compute-ModelB-NucleationSeeds.jl`.
- `code/model-b/Figs-ModelB-BudgetToggle.jl` — standalone plotting for the toggle and edge trace, replacing the side-effect emission inside `Compute-ModelB-BudgetToggle.jl`.
- `code/data/ModelB-Nucleation-SeedSweep-Trajectories.csv` — per-step largest-cluster traces, 3 configs x 20 seeds x 1000 steps.
- `code/data/ModelB-Nucleation-BudgetToggle-Trajectories.csv` — per-step cluster fraction and edge-ring Buy/Sell fractions, 3 arms x 19 seed pairs x 2 conditions, onset-aligned.

**Modified:**
- `code/model-a/Include.jl`, `code/model-b/Include.jl`, `code/comparison/Include.jl` — drop the local palette blocks, include `PaperStyle.jl`.
- `code/model-b/Compute-ModelB-NucleationSeeds.jl`, `code/model-b/Compute-ModelB-BudgetToggle.jl` — emit trajectory CSVs, stop emitting figures.
- All eight `Figs-*`/`Fig*` plotting scripts — adopt shared style, merge panels, drop in-figure titles, add panel letters.
- `code/run_all.sh` — add the two new figure scripts.
- `paper-arxiv/Paper_v1.tex` — Results, Introduction, Discussion prose; all figure blocks and captions.

**Deleted:** none. `Fig-EdgeAgentDiagnostic*.jl`, `Fig-RuleExplore.jl`, and `Fig2b-*.jl` produce figures the paper does not use; leave them alone rather than expanding scope.

---

## Task 1: Shared style module

**Files:**
- Create: `code/src/PaperStyle.jl`
- Modify: `code/model-a/Include.jl:29-37`, `code/model-b/Include.jl:32-40`, `code/comparison/Include.jl:24-32`
- Verify: `code/model-a/Figs-ModelA-Theory.jl`

**Interfaces:**
- Produces: `_BUY_COLOR`, `_HOLD_COLOR`, `_SELL_COLOR`, `_EDGE_COLOR` (all `String` hex); `_SERIES_COLORS::Vector{String}`; `_panel_kw::NamedTuple`; `_panel_letter!(plt, letter::String)`; `_grid_cgrad()`. All later tasks use these names.

Note the bug this fixes: `model-a/Include.jl` defines `_HOLD_COLOR = "#AAAAAA"` while `model-b` and `comparison` define `"#DDDDDD"`, so Model B figures currently render Hold cells lighter than the TikZ schematic's `holdgray`.

- [ ] **Step 1: Write the failing check**

Create `code/test/test_paperstyle.jl`:

```julia
include(joinpath(@__DIR__, "..", "src", "PaperStyle.jl"))

@assert _BUY_COLOR  == "#0072B2" "Buy color must match \\definecolor{buyblue}"
@assert _HOLD_COLOR == "#AAAAAA" "Hold color must match \\definecolor{holdgray}"
@assert _SELL_COLOR == "#D55E00" "Sell color must match \\definecolor{sellorange}"
@assert _EDGE_COLOR == "#009E73" "Edge color must match \\definecolor{edgegreen}"
@assert length(_SERIES_COLORS) >= 4 "need at least four non-state series colors"
@assert !(_BUY_COLOR in _SERIES_COLORS) "series colors must not collide with state colors"
@assert haskey(pairs(_panel_kw), :framestyle) "_panel_kw must set framestyle"
@assert _panel_kw.framestyle == :box
println("PaperStyle OK")
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `julia --project=code code/test/test_paperstyle.jl`
Expected: FAIL, `SystemError: opened file .../src/PaperStyle.jl` (file does not exist yet).

- [ ] **Step 3: Write `code/src/PaperStyle.jl`**

```julia
# PaperStyle.jl
# Single source of truth for figure style. The state colors are the Okabe-Ito
# values already declared in paper-arxiv/Paper_v1.tex via \definecolor, so the
# TikZ schematic (Figure 1) and every data figure share one color language.
# Changing a value here changes it in the paper only if the \definecolor block
# is changed to match.

using Colors
using Plots

const _BUY_COLOR  = "#0072B2"   # \definecolor{buyblue}
const _HOLD_COLOR = "#AAAAAA"   # \definecolor{holdgray}
const _SELL_COLOR = "#D55E00"   # \definecolor{sellorange}
const _EDGE_COLOR = "#009E73"   # \definecolor{edgegreen}

# Non-state series: cash levels, configurations, doses, arms. Rest of Okabe-Ito.
const _SERIES_COLORS = ["#E69F00", "#56B4E9", "#CC79A7", "#F0E442", "#000000"]

const _panel_kw = (
    background_color_inside = RGB(0.94, 0.94, 0.94),
    background_color_outside = :white,
    foreground_color_grid = RGB(1.0, 1.0, 1.0),
    gridalpha = 0.8,
    gridlinewidth = 0.5,
    framestyle = :box,
    fg_legend = :transparent,
    tickfontsize = 9,
    guidefontsize = 10,
    legendfontsize = 8,
    titlefontsize = 11,
    margin = 5Plots.mm,
)

_grid_cgrad() = cgrad([_BUY_COLOR, _HOLD_COLOR, _SELL_COLOR], [0.0, 0.5, 1.0])

"""
    _panel_letter!(plt, letter)

Draw a bold panel letter at the top left of `plt`. Captions reference these as
\\textbf{(A)}; never use positional language like "top row" in a caption.
"""
function _panel_letter!(plt, letter::String)
    annotate!(plt, (0.02, 1.06), text(letter, :black, :left, 12, :bold))
    return plt
end
```

- [ ] **Step 4: Run the check and confirm it passes**

Run: `julia --project=code code/test/test_paperstyle.jl`
Expected: `PaperStyle OK`

- [ ] **Step 5: Wire it into the three Include.jl files**

In each of `code/model-a/Include.jl`, `code/model-b/Include.jl`, `code/comparison/Include.jl`, delete the local `const _PALETTE = ...` block through the `_grid_cgrad` definition and replace with:

```julia
include(joinpath(_PATH_TO_SRC, "PaperStyle.jl"))
```

placed after the existing `include(joinpath(_PATH_TO_SRC, "Simulate.jl"))` line (or after the last `src` include in that file). Keep the `gr()` call that follows in `model-a/Include.jl`.

- [ ] **Step 6: Confirm nothing regressed**

Run: `bash code/run_all.sh figures`
Expected: all eight scripts complete without error. The figures will still look mostly unstyled; only the Hold gray in Model B figures should change. That is the point of this task.

- [ ] **Step 7: Commit**

```bash
git add code/src/PaperStyle.jl code/test/test_paperstyle.jl code/model-a/Include.jl code/model-b/Include.jl code/comparison/Include.jl
git commit -m "Put the figure palette in one place, and fix the Hold gray mismatch"
```

---

## Task 2: Make the seed sweep standalone-reproducible

**Files:**
- Modify: `code/model-b/Compute-ModelB-NucleationSeeds.jl`
- Create: `code/model-b/Figs-ModelB-SeedSweep.jl`
- Create: `code/data/ModelB-Nucleation-SeedSweep-Trajectories.csv`
- Modify: `code/run_all.sh:47-54`, `.gitignore`

**Interfaces:**
- Consumes: `_panel_kw`, `_SELL_COLOR`, `_SERIES_COLORS`, `_panel_letter!`, `_save_figure` from Task 1 and the existing `Include.jl`.
- Produces: `ModelB-Nucleation-SeedSweep-Trajectories.csv` with columns `config,seed,step,maxcluster_frac`. Task 7 reads this file.

The seed sweep figure is currently emitted inside the compute script and its trajectory panels cannot be replotted, because `ModelB-Nucleation-SeedSweep.csv` holds only 60 per-seed summary rows. This task pays that debt using the pattern from `a477211`.

- [ ] **Step 1: Record the current summary CSV checksum**

```bash
shasum -a 256 code/data/ModelB-Nucleation-SeedSweep.csv | tee /tmp/seedsweep-before.sha
```

This is the regression test for the whole task: the campaign is deterministically seeded, so re-running must reproduce this file byte-for-byte.

- [ ] **Step 2: Add trajectory persistence to the compute script**

In `code/model-b/Compute-ModelB-NucleationSeeds.jl`, find the loop that accumulates per-seed results and the `maxcl` vector it already computes per run. Immediately before the existing summary-CSV write, add:

```julia
# Persist the per-step traces so the figure can be rebuilt without re-running
# the campaign. Columns: config, seed, step, maxcluster_frac.
traj_rows = NamedTuple[]
for (cfg, seed, maxcl) in _trajectory_log      # populated in the run loop below
    for (i, v) in enumerate(maxcl)
        push!(traj_rows, (config = cfg, seed = seed, step = i, maxcluster_frac = v))
    end
end
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep-Trajectories.csv"),
          DataFrame(traj_rows))
```

and in the run loop, where each run's `maxcl` trace is available, append it:

```julia
push!(_trajectory_log, (cfg_name, seed, copy(r.maxcl)))
```

declaring `_trajectory_log = Tuple{String,Int,Vector{Float64}}[]` before the loop.

- [ ] **Step 3: Re-run the campaign and verify byte-identity**

```bash
julia --project=code code/model-b/Compute-ModelB-NucleationSeeds.jl
shasum -a 256 code/data/ModelB-Nucleation-SeedSweep.csv | diff - /tmp/seedsweep-before.sha
```

Expected: `diff` prints nothing. If it prints a difference, STOP: the campaign is not deterministic and that is a bug to report, not to work around.

- [ ] **Step 4: Confirm the trajectory file has the expected shape**

```bash
julia --project=code -e '
using CSV, DataFrames
df = CSV.read("code/data/ModelB-Nucleation-SeedSweep-Trajectories.csv", DataFrame)
@assert nrow(df) == 3*20*1000 "expected 60,000 rows, got $(nrow(df))"
@assert Set(df.config) == Set(["stable","freeze","collapse"])
@assert length(unique(df.seed)) == 20
println("trajectories OK: ", nrow(df), " rows")'
```

Expected: `trajectories OK: 60000 rows`

- [ ] **Step 5: Un-ignore the new CSV**

In `.gitignore`, the existing `!code/data/ModelB-Nucleation-*.csv` rule already covers this filename. Confirm:

```bash
git check-ignore -v code/data/ModelB-Nucleation-SeedSweep-Trajectories.csv || echo "NOT IGNORED (correct)"
```

Expected: `NOT IGNORED (correct)`

- [ ] **Step 6: Move plotting out of the compute script**

Delete the figure-building and `_save_figure` block for `ModelB-Nucleation-SeedSweep.pdf` from `Compute-ModelB-NucleationSeeds.jl`. Create `code/model-b/Figs-ModelB-SeedSweep.jl` that reads both CSVs and reproduces the same six panels for now (restyling happens in Task 7):

```julia
# Figs-ModelB-SeedSweep.jl
# Rebuilds the seed-sweep figure from committed CSVs. No simulation.
# Run: julia --project=code code/model-b/Figs-ModelB-SeedSweep.jl
include(joinpath(@__DIR__, "Include.jl"))
using CSV, DataFrames, Statistics

summ = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep.csv"), DataFrame)
traj = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-SeedSweep-Trajectories.csv"), DataFrame)

# Verify the values the paper cites before plotting anything.
med(c) = median(summ[summ.config .== c, :ratio_at_peak])
@assert isapprox(med("stable"),   0.022; atol = 0.001) "stable median ratio does not reproduce"
@assert isapprox(med("freeze"),   0.26;  atol = 0.01)  "freeze median ratio does not reproduce"
@assert isapprox(med("collapse"), 0.44;  atol = 0.01)  "collapse median ratio does not reproduce"
@assert maximum(summ[summ.config .== "stable", :ratio_at_peak]) <
        minimum(summ[summ.config .!= "stable", :ratio_at_peak]) "stable band must not overlap"

# ... panels assembled from `traj` and `summ`, saved with _save_figure ...
```

- [ ] **Step 7: Register the new script**

In `code/run_all.sh`, inside `run_figures()`, add after the `Figs-ModelB-Exemplars.jl` line:

```sh
    run_julia model-b/Figs-ModelB-SeedSweep.jl
```

- [ ] **Step 8: Verify the figure rebuilds without the campaign**

```bash
julia --project=code code/model-b/Figs-ModelB-SeedSweep.jl
```

Expected: the assertions print nothing (they pass) and `Saved (paper): .../ModelB-Nucleation-SeedSweep.pdf` appears.

- [ ] **Step 9: Commit**

```bash
git add code/model-b/Compute-ModelB-NucleationSeeds.jl code/model-b/Figs-ModelB-SeedSweep.jl code/data/ModelB-Nucleation-SeedSweep-Trajectories.csv code/run_all.sh
git commit -m "Make the seed-sweep figure rebuildable without re-running the campaign"
```

---

## Task 3: Make the budget toggle and edge trace standalone-reproducible

**Files:**
- Modify: `code/model-b/Compute-ModelB-BudgetToggle.jl` (figure emission at lines ~295-301)
- Create: `code/model-b/Figs-ModelB-BudgetToggle.jl`
- Create: `code/data/ModelB-Nucleation-BudgetToggle-Trajectories.csv`
- Modify: `code/run_all.sh`

**Interfaces:**
- Produces: `ModelB-Nucleation-BudgetToggle-Trajectories.csv` with columns `arm,seed,condition,step_since_onset,cluster_frac,edge_buy_frac,edge_sell_frac`, where `arm` is one of `injection`, `withdraw_mild`, `withdraw_harsh` and `condition` is `control` or `toggled`. Task 9 reads this file.

Same debt as Task 2. The committed `ModelB-Nucleation-BudgetToggle.csv` holds window-averaged scalars (`edgebuy_ctrl_W`, `edgesell_toggle_W`), not the per-step ring traces the edge-trace figure plots.

- [ ] **Step 1: Record the current summary CSV checksum**

```bash
shasum -a 256 code/data/ModelB-Nucleation-BudgetToggle.csv | tee /tmp/toggle-before.sha
```

- [ ] **Step 2: Add trajectory persistence**

In `Compute-ModelB-BudgetToggle.jl`, in the paired-run loop where the control and toggled histories are both in scope, accumulate onset-aligned traces:

```julia
for (i, s) in enumerate(steps_since_onset)
    push!(traj_rows, (arm = arm_name, seed = seed, condition = "control",
                      step_since_onset = s, cluster_frac = ctrl_maxcl[i],
                      edge_buy_frac = ctrl_edgebuy[i], edge_sell_frac = ctrl_edgesell[i]))
    push!(traj_rows, (arm = arm_name, seed = seed, condition = "toggled",
                      step_since_onset = s, cluster_frac = tog_maxcl[i],
                      edge_buy_frac = tog_edgebuy[i], edge_sell_frac = tog_edgesell[i]))
end
```

with `traj_rows = NamedTuple[]` declared before the loop, and after the loop:

```julia
CSV.write(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BudgetToggle-Trajectories.csv"),
          DataFrame(traj_rows))
```

- [ ] **Step 3: Re-run and verify byte-identity**

```bash
julia --project=code code/model-b/Compute-ModelB-BudgetToggle.jl
shasum -a 256 code/data/ModelB-Nucleation-BudgetToggle.csv | diff - /tmp/toggle-before.sha
```

Expected: no output from `diff`. If it differs, STOP and report.

- [ ] **Step 4: Verify the trajectory file**

```bash
julia --project=code -e '
using CSV, DataFrames
df = CSV.read("code/data/ModelB-Nucleation-BudgetToggle-Trajectories.csv", DataFrame)
@assert Set(df.arm) == Set(["injection","withdraw_mild","withdraw_harsh"])
@assert Set(df.condition) == Set(["control","toggled"])
@assert length(unique(df.seed)) == 19 "expected 19 included seed pairs per arm"
println("toggle trajectories OK: ", nrow(df), " rows")'
```

- [ ] **Step 5: Move plotting into a standalone script**

Delete the two `_save_figure` blocks (`ModelB-Nucleation-BudgetToggle.pdf` and `...-EdgeTrace.pdf`) from the compute script. Create `code/model-b/Figs-ModelB-BudgetToggle.jl` reading both CSVs, opening with the paper's cited values as assertions:

```julia
include(joinpath(@__DIR__, "Include.jl"))
using CSV, DataFrames, Statistics

summ = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BudgetToggle.csv"), DataFrame)
traj = CSV.read(joinpath(_PATH_TO_DATA, "ModelB-Nucleation-BudgetToggle-Trajectories.csv"), DataFrame)

inj = summ[(summ.direction .== "injection") .& summ.included, :]
@assert sum(inj.v_toggle .> inj.v_ctrl) == 14 "injection must accelerate in 14 of 19 pairs"
@assert nrow(inj) == 19 "expected 19 included injection pairs"
@assert isapprox(median(inj.v_ctrl),   1.39e-4; rtol = 0.02) "control median velocity does not reproduce"
@assert isapprox(median(inj.v_toggle), 3.55e-4; rtol = 0.02) "toggled median velocity does not reproduce"

# ... panels ...
```

- [ ] **Step 6: Register in run_all.sh**

```sh
    run_julia model-b/Figs-ModelB-BudgetToggle.jl
```

- [ ] **Step 7: Verify and commit**

```bash
julia --project=code code/model-b/Figs-ModelB-BudgetToggle.jl
git add code/model-b/Compute-ModelB-BudgetToggle.jl code/model-b/Figs-ModelB-BudgetToggle.jl code/data/ModelB-Nucleation-BudgetToggle-Trajectories.csv code/run_all.sh
git commit -m "Make the budget-toggle and edge-trace figures rebuildable from committed data"
```

---

## Task 4: Figure 2 — crossover and front

**Files:**
- Modify: `code/model-a/Fig2-Combined.jl`, `code/model-a/Fig3-PhaseDiagram.jl`
- Output: `paper-arxiv/figs/Fig2-Crossover.pdf`

**Interfaces:**
- Consumes: `_panel_kw`, `_panel_letter!`, `_grid_cgrad`, `_SELL_COLOR`, `_save_figure`.
- Produces: `Fig2-Crossover.pdf` with three panels: **A** snapshot montage, **B** mean sell fraction vs f, **C** crash frequency vs f.

Peak sell fraction moves to supplementary figure S3 in Task 10.

- [ ] **Step 1: Assert the cited values before plotting**

Add to the top of the merged script, after loading the phase sweep:

```julia
i14 = findfirst(≈(0.14), fs); i15 = findfirst(≈(0.15), fs); i20 = findfirst(≈(0.20), fs)
@assert mean_sell[i14] < 0.30 "at f=0.14 mean sell must stay near 0.26"
@assert mean_sell[i15] > 0.45 "at f=0.15 mean sell must jump to ~0.50"
@assert isapprox(mean_sell[i20], 0.91; atol = 0.03) "f=0.20 saturation does not reproduce"
@assert crash_freq[i15] > 0.95 "crash frequency above the bracket must exceed 95%"
@assert crash_freq[i14] == 0.0 "no crashes may occur at or below f=0.14"
```

- [ ] **Step 2: Run and confirm the assertions pass**

Run: `julia --project=code code/model-a/Fig2-Combined.jl`
Expected: no assertion error.

- [ ] **Step 3: Build the merged three-panel figure**

Combine the snapshot montage (currently the whole of `Fig2-Combined`) as panel A with the two phase-diagram panels, applying `_panel_kw...` to every `plot`/`heatmap` call, calling `_panel_letter!(pA, "A")` and so on, and removing any `title=` argument that names the panel content. Axis labels become `"Minority fraction f"`, `"Mean sell fraction"`, `"Crash frequency"`.

```julia
fig = plot(pA, plot(pB, pC, layout = (1, 2)), layout = grid(2, 1, heights = [0.6, 0.4]), size = (1000, 900))
_save_figure(fig, "Fig2-Crossover.pdf")
```

- [ ] **Step 4: Render and inspect**

```bash
pdftoppm -png -r 110 -f 1 -l 1 paper-arxiv/figs/Fig2-Crossover.pdf /tmp/fig2 && echo written
```

Open `/tmp/fig2-1.png`. Confirm: gray panel backgrounds, white gridlines, no title inside the image, panel letters A/B/C present, Sell rendered in `#D55E00`.

- [ ] **Step 5: Commit**

```bash
git add code/model-a/Fig2-Combined.jl code/model-a/Fig3-PhaseDiagram.jl paper-arxiv/figs/Fig2-Crossover.pdf
git commit -m "Merge the snapshots and phase diagram into one crossover figure"
```

---

## Task 5: Figure 3 — finite-size scaling

**Files:**
- Modify: `code/model-a/Figs-ModelA-FiniteSize.jl`
- Output: `paper-arxiv/figs/Fig-ModelA-FiniteSize.pdf` (name unchanged)

Four panels already exist and the structure is right; this task is style plus panel letters plus label wording.

- [ ] **Step 1: Assert the cited values**

```julia
@assert isapprox(cov_32,  0.66;  atol = 0.02) "CoV at 32x32 does not reproduce"
@assert isapprox(cov_512, 0.035; atol = 0.005) "CoV at 512x512 does not reproduce"
@assert isapprox(n_f016, 2.54; atol = 0.05) "Avrami n at f=0.16 does not reproduce"
@assert isapprox(n_f020, 1.91; atol = 0.05) "Avrami n at f=0.20 does not reproduce"
@assert all(isapprox.(inv_K_f018, [1445, 1363, 1367, 1358]; rtol = 0.02)) "1/K spread does not reproduce"
```

- [ ] **Step 2: Run and confirm they pass**

Run: `julia --project=code code/model-a/Figs-ModelA-FiniteSize.jl`

- [ ] **Step 3: Apply the shared style**

Add `_panel_kw...` to all four `plot` calls, call `_panel_letter!` with "A" through "D", delete any `title=` naming panel content, and set axis labels to `"Minority fraction f"` / `"Fraction of seeds converting"`, `"Lattice size L"` / `"Coefficient of variation"`, `"Lattice size L"` / `"Median conversion time (steps)"`, `"Rescaled time Kt"` / `"Converted fraction"`. Size `(1000, 800)`.

- [ ] **Step 4: Render and inspect**

```bash
pdftoppm -png -r 110 -f 1 -l 1 paper-arxiv/figs/Fig-ModelA-FiniteSize.pdf /tmp/fig3 && echo written
```

- [ ] **Step 5: Commit**

```bash
git add code/model-a/Figs-ModelA-FiniteSize.jl paper-arxiv/figs/Fig-ModelA-FiniteSize.pdf
git commit -m "Restyle the finite-size figure"
```

---

## Task 6: Figure 4 — theory overview

**Files:**
- Modify: `code/model-a/Figs-ModelA-Theory.jl:200-230`
- Output: `paper-arxiv/figs/Fig-ModelA-Theory.pdf` (name unchanged)

This script already asserts its cited values and already has a local `_panel_kw`. The work is to delete the local block in favor of the shared one and convert `title = "A"` into `_panel_letter!`.

- [ ] **Step 1: Delete the local style block**

Remove lines defining `_bg`, `_grid_col`, and the local `_panel_kw` tuple (the block beginning `# Shared style — slick gray background`). The shared module now supplies `_panel_kw`.

- [ ] **Step 2: Replace panel titles with panel letters**

Change `title = "A"` to nothing in the `plot` call and add `_panel_letter!(pA, "A")` after it. Repeat for B and C. Also bump `tickfontsize`/`guidefontsize` reliance onto the shared values by removing any local overrides.

- [ ] **Step 3: Run and confirm the existing assertions still pass**

Run: `julia --project=code code/model-a/Figs-ModelA-Theory.jl`
Expected: the script's own `@assert` guards on the Potts energies, the spectral radius range, and the cluster sizes all pass.

- [ ] **Step 4: Render and inspect**

```bash
pdftoppm -png -r 110 -f 1 -l 1 paper-arxiv/figs/Fig-ModelA-Theory.pdf /tmp/fig4 && echo written
```

- [ ] **Step 5: Commit**

```bash
git add code/model-a/Figs-ModelA-Theory.jl paper-arxiv/figs/Fig-ModelA-Theory.pdf
git commit -m "Move the theory figure onto the shared style"
```

---

## Task 7: Figure 5 — the nucleus is spatial and bulk-born

**Files:**
- Modify: `code/model-b/Figs-ModelB-SeedSweep.jl` (from Task 2), `code/model-b/Figs-ModelB-BoundaryVsBulk.jl`
- Output: `paper-arxiv/figs/Fig5-Nucleus.pdf`

**Interfaces:**
- Consumes: `ModelB-Nucleation-SeedSweep-Trajectories.csv` (Task 2), `ModelB-Nucleation-BirthSites.csv`.
- Produces: `Fig5-Nucleus.pdf`, panels **A** largest-cluster ratio at peak by configuration, **B** birth-site map, **C** pooled distance-from-boundary against the uniform null, **D** ring-attachment timing.

- [ ] **Step 1: Assert the cited values**

```julia
@assert isapprox(pooled_boundary_frac, 0.077; atol = 0.005) "pooled boundary fraction does not reproduce"
@assert isapprox(binom_p, 0.47; atol = 0.02) "binomial p does not reproduce"
@assert median_birth_distance == 12 "median founding distance must be 12 cells"
@assert median_birth_size == 1 "median birth size must be a single cell"
@assert n_nucleated == 39 "39 of 40 runs must nucleate within the horizon"
@assert ring_attach_collapse == 6 && ring_attach_freeze == 0 "ring attachment counts do not reproduce"
```

- [ ] **Step 2: Run and confirm they pass**

Run: `julia --project=code code/model-b/Figs-ModelB-BoundaryVsBulk.jl`

- [ ] **Step 3: Assemble the four panels**

Panel A is the per-seed ratio-at-peak strip with the three configuration medians marked, using `_SERIES_COLORS[1]` for freeze and `_SELL_COLOR` for collapse, gray for stable. Panel C overlays the uniform-null expectation as a dashed reference line at 0.125. Every panel takes `_panel_kw...` and a `_panel_letter!` call. No in-figure titles.

```julia
fig = plot(pA, pB, pC, pD, layout = (2, 2), size = (1100, 850))
_save_figure(fig, "Fig5-Nucleus.pdf")
```

- [ ] **Step 4: Render and inspect**

```bash
pdftoppm -png -r 110 -f 1 -l 1 paper-arxiv/figs/Fig5-Nucleus.pdf /tmp/fig5 && echo written
```

Confirm the "Nucleation probe across 20 seeds" title is gone.

- [ ] **Step 5: Commit**

```bash
git add code/model-b/Figs-ModelB-SeedSweep.jl code/model-b/Figs-ModelB-BoundaryVsBulk.jl paper-arxiv/figs/Fig5-Nucleus.pdf
git commit -m "Build the bulk-born nucleus figure from the seed sweep and birth sites"
```

---

## Task 8: Figure 6 — budgets gate growth, not birth

**Files:**
- Modify: `code/model-b/Figs-ModelB-BarrierLaw.jl`, `code/model-b/Figs-ModelB-VelocitySuppression.jl`, `code/model-b/Figs-ModelB-BoundaryVsBulk.jl`
- Output: `paper-arxiv/figs/Fig6-GrowthGating.pdf`

**Interfaces:**
- Produces: `Fig6-GrowthGating.pdf`, panels **A** Kaplan-Meier medians with fitted curves at three cash levels, **B** dominance rate across the six configuration-by-placement cells, **C** front velocity against absolute suppression, **D** velocity by initial cash.

- [ ] **Step 1: Assert the cited values**

```julia
@assert all(isapprox.(r2_by_cash, [0.978, 0.990, 0.980]; atol = 0.002)) "barrier-law R^2 does not reproduce"
@assert n_fit_points == [5, 6, 6] "fit point counts do not reproduce"
@assert all(dominance_rate .== 0.0) "the stamped patch must never found the winning domain"
@assert isapprox(spearman_rho, -0.372; atol = 0.005) "velocity-suppression rho does not reproduce"
@assert perm_p <= 0.0005 "permutation p does not reproduce"
@assert n_included == 97 "97 runs must be included, 3 excluded by the window rule"
```

- [ ] **Step 2: Run and confirm**

Run each of the three scripts and confirm no assertion fires.

- [ ] **Step 3: Assemble**

Cash levels use `_SERIES_COLORS[1..3]` consistently in panels A and D so the reader can track a budget across panels. Panel C colors points by dose using the same three. `_panel_kw...` and `_panel_letter!` throughout, no in-figure titles.

- [ ] **Step 4: Render and inspect**

```bash
pdftoppm -png -r 110 -f 1 -l 1 paper-arxiv/figs/Fig6-GrowthGating.pdf /tmp/fig6 && echo written
```

- [ ] **Step 5: Commit**

```bash
git add code/model-b/Figs-ModelB-BarrierLaw.jl code/model-b/Figs-ModelB-VelocitySuppression.jl code/model-b/Figs-ModelB-BoundaryVsBulk.jl paper-arxiv/figs/Fig6-GrowthGating.pdf
git commit -m "Build the growth-gating figure from the barrier law, seeding, and dose-response"
```

---

## Task 9: Figure 7 — the intervention asymmetry

**Files:**
- Modify: `code/model-b/Figs-ModelB-BudgetToggle.jl` (from Task 3)
- Output: `paper-arxiv/figs/Fig7-Intervention.pdf`

**Interfaces:**
- Consumes: `ModelB-Nucleation-BudgetToggle-Trajectories.csv` (Task 3).
- Produces: `Fig7-Intervention.pdf`, panels **A** paired front velocities under injection, **B** paired velocities under both withdrawal doses, **C** edge-ring Buy and Sell fractions around the toggle under injection, **D** the same under withdrawal.

- [ ] **Step 1: Assert the cited values**

```julia
@assert sum(inj.v_toggle .> inj.v_ctrl) == 14 "injection accelerates in 14 of 19"
@assert isapprox(sign_test_p, 0.064; atol = 0.002) "sign-test p does not reproduce"
@assert isapprox(mild_p, 0.67; atol = 0.02) && isapprox(harsh_p, 0.29; atol = 0.02) "withdrawal nulls do not reproduce"
@assert isapprox(median(harsh.v_ctrl),   2.23e-4; rtol = 0.02)
@assert isapprox(median(harsh.v_toggle), 2.38e-4; rtol = 0.02)
```

- [ ] **Step 2: Run and confirm**

Run: `julia --project=code code/model-b/Figs-ModelB-BudgetToggle.jl`

- [ ] **Step 3: Assemble**

Panels C and D plot Buy in `_BUY_COLOR` and Sell in `_SELL_COLOR`, control as a gray dashed line and toggled as a solid colored line, with a vertical dashed rule at the toggle step. This is the panel pair carrying the paper's sign-reversal claim, so the flip from ~0.5 Buy to ~1.0 Sell must be legible at print size.

- [ ] **Step 4: Render and inspect**

```bash
pdftoppm -png -r 110 -f 1 -l 1 paper-arxiv/figs/Fig7-Intervention.pdf /tmp/fig7 && echo written
```

- [ ] **Step 5: Commit**

```bash
git add code/model-b/Figs-ModelB-BudgetToggle.jl paper-arxiv/figs/Fig7-Intervention.pdf
git commit -m "Build the intervention-asymmetry figure from the toggle and edge trace"
```

---

## Task 10: Supplementary figures

**Files:**
- Modify: the same scripts, adding a second `_save_figure` call each
- Output: `paper-arxiv/figs/FigS1-Exemplars.pdf` through `FigS6-ToggleDetail.pdf`

**Interfaces:**
- Produces six supplementary figures, all on the shared style, all referenced from the Results text in Task 12.

| File | Content | From |
|---|---|---|
| `FigS1-Exemplars.pdf` | Model B regime exemplars: price, state fractions, suppressed orders | `Figs-ModelB-Exemplars.jl` |
| `FigS2-SeedTrajectories.pdf` | Per-seed cluster traces for the three configurations; final cluster fraction | `Figs-ModelB-SeedSweep.jl` |
| `FigS3-PeakSell.pdf` | Peak sell fraction vs f | `Fig3-PhaseDiagram.jl` |
| `FigS4-BarrierParameters.pdf` | Fitted `f_0` and `B` per cash level; onset fraction vs f | `Figs-ModelB-BarrierLaw.jl` |
| `FigS5-SeedingDetail.pdf` | Onset per seed under each placement; patch growth trajectories | `Figs-ModelB-BoundaryVsBulk.jl` |
| `FigS6-ToggleDetail.pdf` | Full cluster trajectories per arm; full three-arm edge trace | `Figs-ModelB-BudgetToggle.jl` |

- [ ] **Step 1: Emit each supplementary figure**

In each listed script, after the main-figure `_save_figure` call, assemble the displaced panels and save under the `FigS*` name. Apply `_panel_kw...` and `_panel_letter!` exactly as for the main figures. These are not second-class figures; the author asked for the quality pass on all of them.

- [ ] **Step 2: Regenerate everything**

```bash
bash code/run_all.sh figures
```

Expected: ten scripts complete; thirteen PDFs land in `paper-arxiv/figs/`.

- [ ] **Step 3: Inspect every figure at once**

```bash
for f in paper-arxiv/figs/Fig2-Crossover.pdf paper-arxiv/figs/Fig-ModelA-FiniteSize.pdf \
         paper-arxiv/figs/Fig-ModelA-Theory.pdf paper-arxiv/figs/Fig5-Nucleus.pdf \
         paper-arxiv/figs/Fig6-GrowthGating.pdf paper-arxiv/figs/Fig7-Intervention.pdf \
         paper-arxiv/figs/FigS*.pdf; do
  pdftoppm -png -r 90 -f 1 -l 1 "$f" "/tmp/check-$(basename $f .pdf)"
done
ls /tmp/check-*.png
```

Open each. Reject any that still shows an in-figure title, a missing panel letter, a white panel background, or a Plots.jl default color.

- [ ] **Step 4: Commit**

```bash
git add code/model-b/Figs-*.jl code/model-a/Fig3-PhaseDiagram.jl paper-arxiv/figs/FigS*.pdf
git commit -m "Add the supplementary figures, on the same style as the main set"
```

---

## Task 11: Rewrite Results, beats 1 to 3

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex`, the Model A portion of `\section{Results}`

The current Results has 21 paragraphs at a median of ~150 words. Beats 1 to 3 replace roughly the first twelve of them with three paragraphs of 300 to 400 words.

- [ ] **Step 1: Record the numbers that must survive**

```bash
grep -oE '[0-9]+\.[0-9]+|[0-9]{1,3}(,[0-9]{3})+' paper-arxiv/Paper_v1.tex | sort -u > /tmp/numbers-before.txt
wc -l < /tmp/numbers-before.txt
```

- [ ] **Step 2: Write beat 1**

One paragraph, 300 to 400 words, opening: "We simulated the $256 \times 256$ agent grid under Model~A across the minority fraction and observed a sharp finite-horizon crossover with spatially coherent front growth above it (Figure~\ref{fig:crossover})." Then the three-value snapshot description, then the phase-sweep specifics ($f = 0.14$ stable at mean sell $0.26$, $f = 0.15$ jumping to $0.50$, saturating near $0.91$ by $f = 0.20$, crash frequency above 95\%), then the economic reading, then a transition into beat 2.

- [ ] **Step 3: Write beat 2**

Opening: "Having located the crossover, we next asked whether it sits at a fixed value of~$f$ (Figure~\ref{fig:finite-size})." Carries the five-lattice sweep, the brittle-fracture direction argument, the $N^{-1/2}$ self-averaging with CoV from $0.66$ to $0.035$, the size-independent median above $f \approx 0.17$, the Avrami exponent from $2.54$ to $1.91$, the $1/K$ spread of 6\%, and both instrument limits.

- [ ] **Step 4: Write beat 3**

Opening: "We next compared the lattice against two low-order closures and found that neither reproduced the crossover (Figure~\ref{fig:theory})." Carries the Potts statistic, the mean-field map with no transition, the pair approximation with spectral radius from $0.95$ to $0.71$, the vanishing mutual information, and the nucleation reading with the inverse-distance fit stated as phenomenological.

- [ ] **Step 5: Check paragraph lengths**

```bash
python3 - <<'PY'
import re
L=open('paper-arxiv/Paper_v1.tex').read().split('\n')
s=L.index('\\section{Results}')
buf=[];st=None
for i in range(s,len(L)):
    l=L[i]
    if l.strip().startswith('\\section') and i>s: break
    if l.strip()=='' or re.match(r'\\(begin|end|label|section)',l.strip()) or l.startswith('%'):
        if buf:
            c=re.sub(r'~?\\cite\{[^}]*\}','',' '.join(buf)); c=re.sub(r'\\[a-zA-Z]+|[{}$~\\]','',c)
            if len(c.split())>40: print(f"L{st}: {len(c.split())}w")
            buf=[];st=None
        continue
    if st is None: st=i+1
    buf.append(l)
PY
```

Expected: the first three paragraphs each report 300 or more words. Any under 250 fails the global constraint.

- [ ] **Step 6: Build and check no number was lost**

```bash
cd paper-arxiv && bash build.sh Paper_v1 >/dev/null 2>&1 && cd ..
grep -oE '[0-9]+\.[0-9]+|[0-9]{1,3}(,[0-9]{3})+' paper-arxiv/Paper_v1.tex | sort -u > /tmp/numbers-after.txt
diff /tmp/numbers-before.txt /tmp/numbers-after.txt
```

Expected: differences only where a number was deliberately removed with a demoted panel. Investigate every line of the diff; do not accept it wholesale.

- [ ] **Step 7: Commit**

```bash
git add paper-arxiv/Paper_v1.tex
git commit -m "Rewrite the Model A results as three dense paragraphs"
```

---

## Task 12: Rewrite Results, beats 4 to 6

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex`, the Model B portion of `\section{Results}`

- [ ] **Step 1: Write beat 4**

Opening: "We next asked whether the crossover survived finite budgets and where on the grid the winning domain was born (Figure~\ref{fig:nucleus})." Carries the factorial sweep, the 94 to 97\% variance attribution, the two realized regimes, the freeze phenotype, the stable-versus-above-threshold cluster ratios ($0.022$ against $0.26$ and $0.44$ with zero overlap), the bulk birth statistics (pooled $0.077$ against the $0.125$ null, $p = 0.47$, median distance 12, median birth size one cell), and the ring-attachment asymmetry. References `FigS1-Exemplars.pdf` and `FigS2-SeedTrajectories.pdf`.

- [ ] **Step 2: Write beat 5**

Opening: "Having established a bulk-born nucleus, we next tested whether budgets act on its birth or on its growth (Figure~\ref{fig:growth-gating})." Carries the equivalence result (factor of two across tenfold cash, largest difference $1.42\times$, the flagged-not-promoted lead at $f = 0.177$ and $0.18$), the seeding null ($0/20$ in all six cells, lineages dying at 9 to 15 cells), and the dose-response ($\rho = -0.372$, $p = 0.0003$, within-dose $\rho$ from $-0.38$ to $-0.52$, the U-shaped median velocity). References `FigS4` and `FigS5`.

- [ ] **Step 3: Write beat 6**

Opening: "We finally used the budget toggle as a paired intervention to test how a cash shock reaches the front (Figure~\ref{fig:intervention})." Carries the injection acceleration (14 of 19, $p = 0.064$, velocity $1.39$ to $3.55 \times 10^{-4}$, suppressed buys down 29\%), the conduit argument, the ring flip, the withdrawal nulls at both doses, and the two mechanisms behind the asymmetry. References `FigS6`.

- [ ] **Step 4: Verify structure and style gates**

```bash
grep -c '\\subsection' <(sed -n '/\\section{Results}/,/\\section{Discussion}/p' paper-arxiv/Paper_v1.tex)
sed -n '/\\section{Results}/,/\\section{Discussion}/p' paper-arxiv/Paper_v1.tex | grep -c -- '---'
grep -cE '\\(ref|Cref|cref|autoref|nameref)\{sec:' paper-arxiv/Paper_v1.tex
grep -nE '(Figure|Table)~\\ref\{[^}]*\}[A-D]? +(shows|lists|collects|draws|lays)' paper-arxiv/Paper_v1.tex
```

Expected: `0`, `0`, `0`, and no output.

- [ ] **Step 5: Re-run the paragraph length check from Task 11 Step 5**

Expected: exactly six paragraphs in Results above 250 words, plus the short preamble.

- [ ] **Step 6: Commit**

```bash
git add paper-arxiv/Paper_v1.tex
git commit -m "Rewrite the Model B results as three dense paragraphs"
```

---

## Task 13: Rewrite every figure block and caption

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex`, all `\begin{figure}` blocks

- [ ] **Step 1: Update filenames and labels**

Point each `\includegraphics` at its new file (`Fig2-Crossover.pdf`, `Fig5-Nucleus.pdf`, `Fig6-GrowthGating.pdf`, `Fig7-Intervention.pdf`) and rename labels to `fig:crossover`, `fig:finite-size`, `fig:theory`, `fig:nucleus`, `fig:growth-gating`, `fig:intervention`, `fig:s1` through `fig:s6`.

- [ ] **Step 2: Convert every caption to panel letters**

Replace all positional language. Every caption sentence describing a panel begins `\textbf{(A)}`, `\textbf{(B)}`, and so on. Search for the offenders:

```bash
grep -nE '\(Top (row|left|right)\)|\(Bottom (row|left|right)\)|\(Left column\)|\(Right column\)' paper-arxiv/Paper_v1.tex
```

Expected after the edit: no output.

- [ ] **Step 3: Place the supplementary figures**

Add the six `FigS*` figure blocks after `\appendix`, each with a caption in the same style.

- [ ] **Step 4: Build and confirm no undefined references**

```bash
cd paper-arxiv && bash build.sh Paper_v1 >/dev/null 2>&1
grep -icE 'undefined|multiply.defined' Paper_v1.log
grep -oE 'Output written.*' Paper_v1.log
cd ..
```

Expected: `0`, and a page count.

- [ ] **Step 5: Commit**

```bash
git add paper-arxiv/Paper_v1.tex
git commit -m "Repoint the figure blocks and rewrite the captions with panel letters"
```

---

## Task 14: Reshape the Introduction

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex:87-145`

Current shape is 175 / 163 / 350 words. Target is roughly 200 / 250 / 235, matching the exemplar. The third paragraph currently carries both the model description and every result and needs the load redistributed, not merely trimmed.

- [ ] **Step 1: Expand paragraphs 1 and 2**

Paragraph 1 keeps the crash-without-news motivation and gains room for the empirical regularities. Paragraph 2 keeps the two-sided gap argument (agent-based models on one side, lattice and spin models on the other, cellular automata applied only with hand-picked rules).

- [ ] **Step 2: Split the load out of paragraph 3**

The closing paragraph states what was done, what was observed, and the interpretation, without becoming a results dump. Move mechanism detail up into paragraph 2 where it belongs.

- [ ] **Step 3: Check the shape**

Run the paragraph-length script from Task 11 Step 5, scoped to lines 87 to 150. Expected: three paragraphs near 200, 250, and 235 words.

- [ ] **Step 4: Commit**

```bash
git add paper-arxiv/Paper_v1.tex
git commit -m "Rebalance the Introduction to the exemplar proportions"
```

---

## Task 15: Expand the Discussion to five paragraphs

**Files:**
- Modify: `paper-arxiv/Paper_v1.tex`, `\section{Discussion}`

Current shape is three paragraphs at 235 / 279 / 137 words. Target follows the exemplar arc: opening question, mechanism at length, the interesting edge case, relation to the adjacent literature, limitations.

- [ ] **Step 1: Split and develop**

Paragraph 1 opens on the question the paper answers. Paragraph 2 develops the mechanism (bulk birth, boundary gating, the price-to-boundary conduit) at 400 or more words. Paragraph 3 takes the edge case: the near-degenerate withdrawal null and why crashes self-finance their dip-buyers. Paragraph 4 relates the result to the funding-liquidity and circuit-breaker literature already cited. Paragraph 5 is the existing limitations paragraph, which is the strongest in the section and needs only light edits.

- [ ] **Step 2: Verify citation density**

```bash
sed -n '/\\section{Discussion}/,/\\section{Conclusion}/p' paper-arxiv/Paper_v1.tex | grep -c '\\cite{'
```

Expected: at least 6. The convention wants the Discussion citation-dense, and paragraphs 4 and 5 currently carry one citation between them.

- [ ] **Step 3: Check the shape**

Run the paragraph-length script. Expected: five paragraphs, none under 137 words, at least one above 400.

- [ ] **Step 4: Commit**

```bash
git add paper-arxiv/Paper_v1.tex
git commit -m "Expand the Discussion to the five-paragraph arc"
```

---

## Task 16: Final verification

**Files:** none modified unless a check fails.

- [ ] **Step 1: Full rebuild from clean**

```bash
cd paper-arxiv && rm -f Paper_v1.aux Paper_v1.bbl Paper_v1.out && bash build.sh Paper_v1
grep -iE '^(!|LaTeX Warning|Package .* Warning)' Paper_v1.log | grep -viE 'Font shape' | sort -u
grep -icE 'undefined|multiply.defined' Paper_v1.log
cd ..
```

Expected: no warnings, `0` undefined.

- [ ] **Step 2: Full figure regeneration from committed data**

```bash
bash code/run_all.sh figures
git status --short paper-arxiv/figs/
```

Expected: every script passes its assertions. Any figure that changes byte-for-byte on a second run without a code change is non-deterministic and must be reported.

- [ ] **Step 3: Style gates**

```bash
grep -cE '\\(ref|Cref|cref|autoref|nameref)\{sec:' paper-arxiv/Paper_v1.tex
grep -cE 'Section~\\ref|Sec\.~\\ref' paper-arxiv/Paper_v1.tex
grep -nEi '(this section|Results~?I{1,2}\b|the (results|methods|background) section)' paper-arxiv/Paper_v1.tex
grep -v '^ *%' paper-arxiv/Paper_v1.tex | grep -c -- '---'
grep -cE '\\begin\{(itemize|enumerate)\}|\\subsubsection' paper-arxiv/Paper_v1.tex
grep -nE '\(Top (row|left|right)\)|\(Bottom (row|left|right)\)' paper-arxiv/Paper_v1.tex
```

Expected: `0`, `0`, no output, `0`, `0`, no output.

- [ ] **Step 4: Number diff against the pre-revision baseline**

```bash
git show 22edc60:paper-arxiv/Paper_v1.tex | grep -oE '[0-9]+\.[0-9]+|[0-9]{1,3}(,[0-9]{3})+' | sort -u > /tmp/nums-22edc60.txt
grep -oE '[0-9]+\.[0-9]+|[0-9]{1,3}(,[0-9]{3})+' paper-arxiv/Paper_v1.tex | sort -u > /tmp/nums-now.txt
diff /tmp/nums-22edc60.txt /tmp/nums-now.txt
```

Expected: every line of the diff is explainable as a number that left with a demoted panel. A changed value is a bug.

- [ ] **Step 5: Visual pass over all thirteen figures**

Render each to PNG at 90 dpi and open them together. Every figure must show gray panel backgrounds, white gridlines, panel letters, no in-figure title, and Buy/Sell in `#0072B2` and `#D55E00`.

- [ ] **Step 6: Commit and report**

```bash
git add -A paper-arxiv code
git commit -m "Verify the revised figures and narrative"
```

Report the final page count, the paragraph-length distribution for Results, and any line of the number diff that was accepted, with its reason.

---

## Self-Review

**Spec coverage.** Style module, Task 1. Okabe-Ito adoption, Task 1. Seven main figures, Tasks 4 to 9. Six supplementary figures, Task 10. The reproducibility debt the spec added in section 1.4, Tasks 2 and 3. Results as six beats, Tasks 11 and 12. Captions with panel letters, Task 13. Introduction, Task 14. Discussion, Task 15. Conclusion unchanged, correctly no task. Verification criteria, Task 16.

**Placeholders.** None. Every code step carries the code; every check step carries the command and its expected output. Tasks 4 through 10 give assertion values copied from the paper rather than told to "verify the numbers".

**Type consistency.** `_panel_kw`, `_panel_letter!`, `_SERIES_COLORS`, `_BUY_COLOR`, `_SELL_COLOR`, `_grid_cgrad`, and `_save_figure` are defined in Task 1 (or already exist in `Include.jl`) and used under those exact names in Tasks 4 through 10. The two trajectory CSV schemas are declared in Tasks 2 and 3 and consumed under the same column names in Tasks 7 and 9.

**Known risk.** Tasks 2 and 3 depend on the two Model B campaigns being deterministic. Memory records byte-identical reruns for the boundary-versus-bulk campaign, but these two have not been rerun since they were written. If either summary CSV fails to reproduce, stop and report rather than regenerating the figure from fresh numbers, because the paper's cited values come from the committed CSVs.
