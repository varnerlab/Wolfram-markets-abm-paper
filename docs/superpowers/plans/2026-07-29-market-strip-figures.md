# Market-Strip Figure Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Anchor every Results figure on a "market strip" (the lattice evolving in time) so nucleation, growth gating, and the intervention are visible, demoting abstract statistical panels to the SI, and sync all captions and Results prose.

**Architecture:** A new shared tight-canvas strip renderer (`code/src/StripPanels.jl`, single-heatmap montage per the `Fig2-GridSnapshots.jl` precedent) is fed by small new compute scripts that re-run a handful of deterministic Model A/B configurations with `snapshot_steps` capture and persist selected frames to JLD2. Figure assembly scripts are reworked panel-by-panel; statistics CSVs stay authoritative and untouched. LaTeX captions and beat prose are updated last, then the paper is rebuilt and gate-checked.

**Tech Stack:** Julia 1.12 (Plots.jl 1.41 + GR, StatsPlots, JLD2 0.6, CSV/DataFrames), LaTeX (latexmk via `paper-arxiv/build.sh`), `pdftoppm` for visual verification.

## Global Constraints

- Palette and style are a CONTRACT: use only `_BUY_COLOR/_HOLD_COLOR/_SELL_COLOR/_EDGE_COLOR`, `_SERIES_COLORS`, `_panel_kw`, `_grid_cgrad()`, `_panel_letter!` from `code/src/PaperStyle.jl`. Never edit PaperStyle.jl itself; per-figure margins/legends go in the figure assemblies.
- No `title=` on paper panels (house rule; label via annotation rows as in `Fig2-Combined.jl`).
- `_panel_letter!` branches on yflip; heatmap tiles are yflip — letters for strip panels must use the blank-row/label-panel technique (`Fig2-Combined.jl:59-89`), not `_panel_letter!` on the tile.
- Figures save via `_save_figure` (writes `code/figs/` AND `paper-arxiv/figs/`).
- Run Julia from repo root: `julia --project=code code/<dir>/<script>.jl` (compute scripts: add `-t auto`).
- Do NOT regenerate existing campaign CSVs/JLD2 caches (`code/data/*`); new artifacts get NEW file names.
- The three `ModelA-*.jld2` snapshot caches are irreplaceable as-is (`Compute-ModelA.jl` lacks `snapshot_steps`; a rerun would produce fewer frames). Do not delete or overwrite them.
- LaTeX prose gates (zero tolerance): no section self-refs, no itemize, no em/en dashes in narrative, figure refs parenthetical and never sentence-subject, whole-figure refs in beat leads, panel refs in body sentences.
- Commit after every task; never amend; commit trailer:
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` + `Claude-Session: https://claude.ai/code/session_01WSePx8SXGESkPChNKs79Cc`.

---

### Task 1: Enlarge Figure 2 snapshots (assembly only)

**Files:**
- Modify: `code/model-a/Fig2-Combined.jl` (layout block :136-139 and panel-size constants)

**Interfaces:**
- Consumes: existing JLD2 frame caches (`ModelA-Homogeneous/-Critical/-Crash.jld2`), `_snap_panel` (:91), `_row_label`/`_col_label` (:103/:109).
- Produces: `Fig2-Crossover.pdf` with the 3×4 snapshot montage as a full-width hero (tile ≈ 2× current area) and panels B/C side by side beneath it. No data change.

- [ ] **Step 1: Read the current layout.** Read `code/model-a/Fig2-Combined.jl` fully, especially the design note at :59-89 and the `grid(4,5; widths=..., heights=...)` at :136-139 and the final combined layout near `_save_figure` (:167).
- [ ] **Step 2: Rework the layout.** Give the montage the full figure width and push B/C into a bottom row. Concretely: build the montage exactly as now, then assemble the final figure as
  ```julia
  fig = plot(montage, panelB, panelC;
      layout = @layout([a{0.62h}; b c]),
      size = (1160, 1160))
  ```
  Adjust `size` so each snapshot tile renders ≥ 300 px wide (current ≈ 165 px). Keep the label row/column technique unchanged.
- [ ] **Step 3: Regenerate and inspect.** Run `julia --project=code code/model-a/Fig2-Combined.jl`. Render: `pdftoppm -png -r 150 code/figs/Fig2-Crossover.pdf /tmp/f2 && open` (agent: Read the PNG). Check: tiles ≥ 2× previous size, wavefront at f=0.15/t=8236 clearly visible, no label collisions, B/C legible.
- [ ] **Step 4: Commit.**
  ```bash
  git add code/model-a/Fig2-Combined.jl code/figs/Fig2-Crossover.pdf paper-arxiv/figs/Fig2-Crossover.pdf
  git commit -m "Enlarge Fig 2 snapshot montage to full-width hero tiles"
  ```

---

### Task 2: Shared strip renderer + Model B config extraction

**Files:**
- Create: `code/src/StripPanels.jl`
- Create: `code/test/test_strippanels.jl`
- Create: `code/model-b/NucleationConfigs-Lib.jl`
- Modify: `code/model-b/Compute-ModelB-NucleationSeeds.jl` (:38-44), `code/model-b/Compute-ModelB-BudgetToggle.jl` (:58-72) — replace inline config builders with `include("NucleationConfigs-Lib.jl")`; pure move, zero behavior change.
- Modify: `code/model-a/Include.jl` and `code/model-b/Include.jl` — add `include(joinpath(_PATH_TO_SRC, "StripPanels.jl"))` after the PaperStyle include (match each file's existing path style).

**Interfaces:**
- Produces: `_strip_panel(frames::Vector{Matrix{Int64}}, labels::Vector{String}; gap::Int64=4, marks=nothing, rowlabel::String="") -> Plots.Plot` — one seamless heatmap montage, tile labels above each tile, optional per-tile `(tileindex => (row, col))` × marks, optional rotated row label at left. Also `_strip_canvas(frames; gap) -> Matrix{Float64}` (NaN gutters).
- Produces: `_probe_config(name, f, cash, seed)` and `_toggle_config(...)` importable from `NucleationConfigs-Lib.jl` with signatures IDENTICAL to the originals (copy verbatim, delete originals, include the lib).

- [ ] **Step 1: Write the failing test** in `code/test/test_strippanels.jl` (mirror the include pattern of `code/test/test_paperstyle.jl`):
  ```julia
  frames = [fill(2, 8, 8), fill(0, 8, 8), fill(1, 8, 8)]
  canvas = _strip_canvas(frames; gap = 4)
  @test size(canvas) == (8, 3*8 + 2*4)
  @test all(isnan, canvas[:, 9:12])          # first gutter
  @test canvas[1, 1] == 2.0 && canvas[1, 13] == 0.0
  plt = _strip_panel(frames, ["t = 1", "t = 2", "t = 3"]; marks = Dict(1 => (3, 3)))
  @test plt isa Plots.Plot
  ```
- [ ] **Step 2: Run it, verify it fails** (`_strip_canvas not defined`).
- [ ] **Step 3: Implement `code/src/StripPanels.jl`:**
  ```julia
  # StripPanels.jl -- seamless "market strip" montage: one heatmap, NaN gutters.
  # Requires PaperStyle.jl (for _grid_cgrad) to be included first.
  function _strip_canvas(frames::Vector{<:AbstractMatrix}; gap::Int64 = 4)
      n = length(frames); H, W = size(frames[1])
      canvas = fill(NaN, H, n*W + (n-1)*gap)
      for (i, F) in enumerate(frames)
          c0 = (i-1)*(W + gap)
          canvas[:, (c0+1):(c0+W)] .= Float64.(F)
      end
      return canvas
  end

  function _strip_panel(frames::Vector{<:AbstractMatrix}, labels::Vector{String};
                        gap::Int64 = 4, marks = nothing, rowlabel::String = "")
      canvas = _strip_canvas(frames; gap = gap)
      H, W = size(frames[1]); n = length(frames)
      plt = heatmap(canvas; c = _grid_cgrad(), clims = (0, 2), yflip = true,
                    aspect_ratio = :equal, axis = false, colorbar = false,
                    framestyle = :none, background_color_inside = :white,
                    ylims = (-0.14*H, H + 0.5), margin = 0Plots.mm)
      for (i, lab) in enumerate(labels)
          cx = (i - 1)*(W + gap) + W/2
          annotate!(plt, cx, -0.08*H, text(lab, :black, :center, 8, "helvetica"))
      end
      if marks !== nothing
          for (i, rc) in pairs(marks)
              rc === nothing && continue
              cx = (i - 1)*(W + gap) + rc[2]
              scatter!(plt, [cx], [rc[1]]; marker = :xcross, markersize = 6,
                       markercolor = :white, markerstrokecolor = :black,
                       markerstrokewidth = 1.4, label = "")
          end
      end
      isempty(rowlabel) || annotate!(plt, -0.05*(n*W + (n-1)*gap), H/2,
          text(rowlabel, :black, :center, 8, "helvetica"; rotation = 90))
      return plt
  end
  ```
- [ ] **Step 4: Run the test, verify pass.** `julia --project=code code/test/test_strippanels.jl` (wire it the same way the other test files are invoked — check `code/test/runtests.jl` first and add an include there if that is the pattern).
- [ ] **Step 5: Extract the config builders.** Create `code/model-b/NucleationConfigs-Lib.jl` containing `_probe_config` (moved verbatim from `Compute-ModelB-NucleationSeeds.jl:44`) and `_toggle_config` (from `Compute-ModelB-BudgetToggle.jl:72`), each with its surrounding constants ONLY if the function bodies reference them; otherwise leave constants in the campaign scripts and pass them as arguments exactly as the originals do. Replace the originals with `include("NucleationConfigs-Lib.jl")`. Verify pure-move: `git diff` shows deletion+include only; then `julia --project=code -e 'include("code/model-b/Include.jl"); include("code/model-b/NucleationConfigs-Lib.jl"); @show _probe_config("freeze", 0.20, 500.0, 1)'` runs without error (adjust the call to the real signature you moved).
- [ ] **Step 6: Run the existing test suite** (`code/test/`) to confirm nothing broke, then commit:
  ```bash
  git add code/src/StripPanels.jl code/test/test_strippanels.jl code/model-b/NucleationConfigs-Lib.jl \
          code/model-b/Compute-ModelB-NucleationSeeds.jl code/model-b/Compute-ModelB-BudgetToggle.jl \
          code/model-a/Include.jl code/model-b/Include.jl code/test/runtests.jl
  git commit -m "Add shared market-strip renderer and extract Model B config builders"
  ```

---

### Task 3: Capture Model B strip frames (one compute script, JLD2 out)

**Files:**
- Create: `code/model-b/Compute-ModelB-StripFrames.jl`
- Create (output): `code/data/ModelB-StripFrames.jld2`
- Modify: `code/run_all.sh` (add the script to the compute list, before `run_figures()`)

**Interfaces:**
- Consumes: `_probe_config`/`_toggle_config` from `NucleationConfigs-Lib.jl`; `simulate(config; snapshot_steps, intervention)` (`code/src/Simulate.jl:325`); CSVs `ModelB-Nucleation-BirthSites.csv`, `ModelB-Nucleation-SeedSweep.csv`, `ModelB-Nucleation-BudgetToggle.csv`.
- Produces: one JLD2 with keys `"fig5/frames"::Vector{Matrix{Int64}}`, `"fig5/steps"::Vector{Int64}`, `"fig5/birth"::Tuple{Int,Int}`, `"fig5/seed"`, `"fig6/<arm>/frames|steps|seed"` for arm ∈ {freeze, collapse}, `"fig7/<arm>/frames|steps|seed"` for arm ∈ {control, injection}. Frames are full 64×64 `Matrix{Int64}` at exactly the listed steps.

- [ ] **Step 1: Discover the CSV schemas.** `head -3 code/data/ModelB-Nucleation-BirthSites.csv code/data/ModelB-Nucleation-SeedSweep.csv code/data/ModelB-Nucleation-BudgetToggle.csv` and note the exact column names for: seed, configuration/arm label, onset step, birth row/col/step, front velocity. All seed/step selections below must use those real names.
- [ ] **Step 2: Write the script.** Data-driven, logged choices (no hand-picked seeds):
  - Fig 5 (collapse exemplar): among nucleated collapse rows of BirthSites **with `birth_dist >= 10`** (the exemplar must be typical in the dimension the panel is about — a comfortably interior birth; median birth_dist is 10-12), pick `seed* = argmin |onset_step - median(onset_step)|` (median over ALL nucleated collapse rows). Strip steps: `[birth_step, (birth_step+onset)÷2, onset, min(onset+200, 1500)]`.
  - **Cluster outlines (all three figures):** for every saved frame also save a `BitMatrix` mask of the cluster to outline, under `figX[/arm]/outlines`. Fig 5: the birth-lineage chain computed on the DENSE frame sequence (the probe pass already captures every step for onset detection) — start from the birth cell at birth_step and chain step-by-step: at each step t+1 the lineage mask is the `_sell_clusters` cluster with maximal cell-overlap against the step-t mask (all-false if it died); record the mask at each strip time. Chaining across only the four sparse strip snapshots is WRONG (clusters churn between distant times and the chain breaks — observed: a 4-cell mask at onset, where the onset cluster is by definition >= 0.05*GRIDN^2 cells). Sanity check to assert in the script: the onset-tile mask size must be >= 0.05*GRIDN^2. Figs 6/7: the largest sell cluster in that frame. These masks let the renderer outline the tracked domain against the busy above-threshold background, which visual inspection showed is essential at f = 0.20.
  - **StripPanels outline support (amendment to Task 2's renderer, delivered with this fix):** `_strip_panel(...; outlines = nothing)` — when given a `Vector{Union{Nothing,BitMatrix}}` aligned with `frames`, draw each mask's boundary as thin black line segments (`line width ~1.2px`, single series per tile using NaN-separated segment lists: for every masked cell and each of its 4 neighbors outside the mask, emit the shared edge in canvas coordinates). Also move tile labels fully clear of the tiles: label y at `-0.10*H` with `ylims = (-0.18*H, H + 0.5)` (the first render showed labels overlapping tile tops).
  - Fig 6 (freeze vs collapse, same seed): among seeds with finite onset in BOTH configs (SeedSweep), pick the seed minimizing the summed distance of both onsets to their per-config medians. Strip steps per arm: `[t_on, t_on+100, t_on+250, t_on+400]` (clamp at 1500... wait horizon: seed sweep ran 1000 steps but the strip re-run may use STEPS=1500 with the boundary-vs-bulk config; use the freeze/collapse `_probe_config` with `STEPS = 1500` and recompute `t_on` from the fresh run: first step where the largest sell cluster ≥ 0.05*64^2, using `_sell_clusters` logic copied from `Compute-ModelB-NucleationSeeds.jl:62`).
  - Fig 7 (control vs ×10 injection): among included injection pairs in BudgetToggle, pick the accelerating seed whose velocity change is closest to the median change. Rebuild the pair exactly as `_run_pair` does (`Compute-ModelB-BudgetToggle.jl:121-151`): control run finds `t_on`, toggled run uses `hook = (t, books) -> (t == t_on && (books.cash .*= 10.0); nothing)`. Strip steps for BOTH arms: `[t_on - 1, t_on+100, t_on+250, t_on+400]`. Assert `frames_control[t_on-1] == frames_toggled[t_on-1]` (bit-identity, mirrors :151).
  - Run each `simulate` with `snapshot_steps = <exactly the strip steps>` (plus whatever the onset scan needs: for onset detection use `snapshot_steps = collect(1:STEPS)` on the control/probe pass, then a second cheap pass capturing only the strip steps — 64² runs are seconds).
  - Save with JLD2 under the keys in **Interfaces**, plus a `"meta/created"` note string recording seeds and steps chosen.
- [ ] **Step 3: Run it.** `julia --project=code -t auto code/model-b/Compute-ModelB-StripFrames.jl`. Verify: script prints chosen seeds/steps; `julia --project=code -e 'using JLD2; d = load("code/data/ModelB-StripFrames.jld2"); @show sort(collect(keys(d)))'` lists all keys; every frames vector has length 4 and eltype Matrix.
- [ ] **Step 4: Commit** (include the JLD2 — data artifacts are tracked in this repo):
  ```bash
  git add code/model-b/Compute-ModelB-StripFrames.jl code/data/ModelB-StripFrames.jld2 code/run_all.sh
  git commit -m "Capture deterministic Model B grid frames for the market-strip panels"
  ```

---

### Task 4: Rebuild Figure 5 (nucleus) around the birth-to-engulfment strip

**Files:**
- Modify: `code/model-b/Figs-ModelB-BoundaryVsBulk.jl` first `let` block (:28-178)

**Interfaces:**
- Consumes: `_strip_panel`, `ModelB-StripFrames.jld2` keys `fig5/*`; existing panel builders for the birth map and distance histogram inside the same `let`.
- Produces: `Fig5-Nucleus.pdf` with (A) 4-tile strip, birth cell ×-marked on tile 1 and tile labels `"t = <step>"`; (B) birth-location map (old B unchanged); (C) distance histogram vs uniform null (old C unchanged). Old panels A (dot strips) and D (attach-timing scatter) deleted from this figure.

- [ ] **Step 1: Rework the `let` block.** Load the JLD2, build `stripA = _strip_panel(frames, ["t = $(s)" for s in steps]; marks = Dict(1 => birth))`. Assemble:
  ```julia
  fig = plot(stripA, panelB, panelC;
      layout = @layout([a{0.40h}; b c]), size = (1160, 900))
  ```
  Panel letters: strip gets its letter via a slim label row (Fig2 technique); B/C keep `_panel_letter!`.
- [ ] **Step 2: Regenerate + inspect.** Run the script; render the PDF; check the strip reads left-to-right from a single marked cell to a dominant orange domain, × mark visible, B/C unchanged.
- [ ] **Step 3: Commit** (`git add` script + both PDF copies; message: "Anchor Fig 5 on the birth-to-engulfment market strip").

---

### Task 5: Rebuild Figure 6 (growth gating) around the freeze-vs-collapse strip pair

**Files:**
- Modify: `code/model-b/Figs-ModelB-BarrierLaw.jl` main-figure `let` (Fig6 section, through :204) and its FigS4 `let` (:208-258)

**Interfaces:**
- Consumes: `fig6/freeze/*`, `fig6/collapse/*` from the JLD2; existing KM/fit panel code (old A) and velocity-suppression panel code (old C); old panel D (velocity-by-cash) code moves into FigS4.
- Produces: `Fig6-GrowthGating.pdf` with (A) two stacked onset-aligned strips, row labels "cash 500" / "cash 5,000", tile labels `"t_on"`, `"+100"`, `"+250"`, `"+400"`; (B) KM medians + fitted divergences (old A verbatim); (C) velocity vs suppression (old C verbatim). Old B (0/20 Wilson bars) deleted — the null lives in prose + FigS5. `FigS4-BarrierParameters.pdf` gains (D) = old Fig6 D (velocities by initial cash) unchanged.

- [ ] **Step 1: Build the strip pair.** Two `_strip_panel` calls (rowlabel = "cash 500" / "cash 5,000"), stacked via `@layout([a; b])` into one anchor, then `fig = plot(anchor, panelB, panelC; layout = @layout([a{0.46h}; b c]), size = (1160, 980))`.
- [ ] **Step 2: Move old D into FigS4** as panel (D): reuse the panel code verbatim inside the FigS4 `let`, switch its letter, extend that figure's layout to `(2, 2)`.
- [ ] **Step 3: Regenerate both PDFs + inspect.** The freeze row must visibly lag the collapse row at matched offsets; KM and scatter panels unchanged; FigS4 now 4 panels, no clipped axis titles.
- [ ] **Step 4: Commit** ("Anchor Fig 6 on the freeze-vs-collapse strip pair; move the cash-ladder panel to S4").

---

### Task 6: Rebuild Figure 7 (intervention) around the control-vs-injection strip pair

**Files:**
- Modify: `code/model-b/Figs-ModelB-BudgetToggle.jl` second `let` (Fig7, :238+); first `let` (FigS6) only if panel-letter bookkeeping requires.

**Interfaces:**
- Consumes: `fig7/control/*`, `fig7/injection/*` from the JLD2; the existing edge-ring trace panel (old C); `ModelB-Nucleation-BudgetToggle.csv` per-seed control/toggled velocities for the dumbbell.
- Produces: `Fig7-Intervention.pdf` with (A) two stacked strips (rows "control", "cash ×10"), identical first tile (pre-toggle bit-identity made visible), columns `t_on-1, +100, +250, +400`; (B) edge-ring Buy/Sell traces under injection (old C verbatim); (C) paired dumbbell: per-seed control→toggled front velocity, one short connecting line per seed, injection arm in `_SELL_COLOR`, mild/harsh withdrawal arms in `_HOLD_COLOR` grays, arms side by side on a categorical x-axis. Old A/B spaghetti panels and old D deleted (withdrawal ring detail stays in FigS6).

- [ ] **Step 1: Strip pair** exactly as Task 5 Step 1 with the fig7 arms.
- [ ] **Step 2: Dumbbell panel.** From the toggle CSV: for each arm and seed, `plot!([x_ctrl, x_tog], [v_ctrl, v_tog])` thin connecting segments plus endpoint scatters; group the three arms at x-offsets 1/2/3 with jitter; `_panel_kw...`; y label `front velocity x 1e4 (per step)`; annotate arm medians. No legend entry per seed (`label = ""`), one legend entry per arm.
- [ ] **Step 3: Regenerate + inspect.** Tile 1 of both rows must be pixel-identical; the injected row visibly ahead by +250; dumbbell shows 14/19 upward in the injection arm and flat gray withdrawal arms.
- [ ] **Step 4: Commit** ("Anchor Fig 7 on the control-vs-injection strip pair; replace spaghetti with paired dumbbells").

---

### Task 7: Figure 3 (finite size) — size-contrast strip + panel demotions

**Files:**
- Modify: `code/model-a/FiniteSize-Lib.jl` (new function; do not touch `run_cell`)
- Create: `code/model-a/Compute-FiniteSizeStrips.jl` → output `code/data/ModelA-FiniteSizeStrips.jld2`
- Modify: `code/model-a/Figs-ModelA-FiniteSize.jl`; Create: new SI figure output `FigS7-FiniteSizeDetail.pdf` (same script, second `let`)
- Modify: `code/test/` (extend the FiniteSize test), `code/run_all.sh`

**Interfaces:**
- Produces: `run_cell_frames(L, f, seed, t_max, capture_at::Vector{Int64}) -> Dict{Int64, Matrix}` in FiniteSize-Lib, reusing `ca_step!` (:26) and the same init as `run_cell` (:95); MUST leave `run_cell` byte-identical.
- Produces: `Fig-ModelA-FiniteSize.pdf` = (A) strip of L ∈ {64, 128, 512} at f = 0.15 and common absolute time t* (labels "L = 64" etc.), (B) conversion-fraction curves thinned to those 3 sizes with direct end-labels instead of a legend box, (C) rescaled-collapse panel (old D). `FigS7-FiniteSizeDetail.pdf` = old panels B (CV) and C (median time) verbatim, letters A/B.

- [ ] **Step 1: TDD the new lib function.** Test: for `(L=32, f=0.2, seed=1, t_max=500)`, `run_cell_frames(...; capture_at=[500])[500]` has size `(32,32)` and its sell fraction equals the sell fraction implied by `run_cell_trajectory` at t=500 (same seed). Run: fails. Implement by copying `run_cell`'s init + loop, inserting `t in capture_set && (out[t] = copy(grid))`. Run: passes. Existing FiniteSize tests still pass.
- [ ] **Step 2: Compute script.** Read `ModelA-FiniteSizeSummary.csv`, set `t* = 2 × median conversion time of L=512 at f=0.15` (print it); capture one frame per L ∈ {64,128,512} at t* with seed = 1 for each (log seeds; if the L=64 run happens to have converted by t*, iterate seeds 1..20 and take the first still-mixed one — the point of the panel is the contrast, and the summary CSV says conversion at 64² is rare at f=0.15). Save JLD2 keys `"L64" "L128" "L512"` + `"tstar"` + `"seeds"`.
- [ ] **Step 3: Reassemble the figures.** Strip tiles have different pixel counts (64² vs 512²) — render each as its OWN heatmap tile in a 1×3 layout (equal display size; do NOT use `_strip_canvas`, which assumes equal shapes), each with the Fig2 tile recipe (`c=_grid_cgrad(), clims=(0,2), yflip=true, axis=false, framestyle=:none`) and an annotation label. B: filter the plotted sizes to 64/128/512, delete the legend, `annotate!` each curve's right end with "L = <n>". C: old D code verbatim. New second `let` writes FigS7 with old B/C.
- [ ] **Step 4: Regenerate, inspect, commit** ("Fig 3: size-contrast market strip; CV and median-time panels move to S7").

---

### Task 8: Figure 4 panel C — multi-seed cluster band

**Files:**
- Modify: `code/model-a/Figs-ModelA-Theory.jl` (panel C block only; find the on-the-fly 128² cluster-size sampling in that script)

**Interfaces:**
- Produces: panel C showing, per f on the existing grid, the across-seed **median** of "largest cluster ever observed" and of "mean largest per snapshot" with a 25-75% ribbon over `seed in 1:20` (`fillalpha = 0.2`, series colors unchanged from the current panel). Log y-axis, dashed f_c marker, and axis labels unchanged.

- [ ] **Step 1: Wrap the existing sampling protocol** in `for seed in 1:20`, collecting both statistics per (f, seed); print elapsed time (guard: if > 10 min, subsample snapshots per the protocol comment in `Compute-NucleationTheory.jl` §3 and say so in the script comment).
- [ ] **Step 2: Plot median + ribbon;** delete the single-seed series and any dip-specific styling.
- [ ] **Step 3: Regenerate + inspect:** the f = 0.155 dip must be gone (absorbed into the band); curves monotone-ish rising toward the bracket.
- [ ] **Step 4: Commit** ("Fig 4C: replace the fixed-seed cluster curve with a 20-seed median and IQR band").

---

### Task 9: Captions, Results prose, SI wiring, paper build, gates

**Files:**
- Modify: `paper-arxiv/sections/results.tex` (captions of figs 3-7 + the four affected beats), `paper-arxiv/sections/appendix.tex` (FigS4 caption gains (D); add FigS7 figure env + caption after FigS6)

**Interfaces:**
- Consumes: final panel layouts from Tasks 4-8.
- Produces: a building paper in which every caption matches its figure's panels, every beat's panel references point at real panels, beat leads still cite whole figures, and all style gates pass.

- [ ] **Step 1: Caption rewrites.** For each rebuilt figure, rewrite the caption panel-by-panel in the established voice (declarative, quantitative, \textbf{(A)} style). Fig 4C's caption drops the dip sentence and states "median over 20 disorder seeds with interquartile band". Fig 6's caption loses the dominance-rate panel text; Fig 7's caption describes strip/ring/dumbbell.
- [ ] **Step 2: Beat prose sync** in results.tex (leads unchanged — they already cite whole figures): retarget panel-level references: finite-size beat (CV/median sentences now cite `Figure~\ref{fig:s7}`), nucleus beat (per-seed ratios cite `Figure~\ref{fig:s2}`, attach-timing numbers stay as prose without a panel ref), growth-gating beat (dominance 0/20 sentence cites `Figure~\ref{fig:s5}` only; U-shape sentence cites `Figure~\ref{fig:s4}`), intervention beat (spaghetti references become the dumbbell panel; ring-flip references move to the new panel letter). Add `\label{fig:s7}` with the new figure env.
- [ ] **Step 3: Build + gates.** `bash paper-arxiv/build.sh Paper_v1`; zero undefined refs (`grep -c 'undefined refer' paper-arxiv/Paper_v1.log` = 0); run the review-section detection greps (self-refs, itemize, dashes, figure-as-subject, intensifiers) on the two edited files — all clean; render the six figure pages + S4/S7 pages with `pdftoppm` and inspect each against its caption.
- [ ] **Step 4: Commit** ("Sync captions and Results prose to the market-strip figures; add FigS7").

---

## Verification (whole-campaign)

- `code/test/` suite green; `run_all.sh run_figures` regenerates all 13 PDFs without error.
- Paper builds clean; page structure: text → references → Figs 1-7 → Tabs 1-2 → appendices → S1-S7 → Tabs 3-4.
- Visual pass: every new strip reads at print size; no panel-letter collisions (yflip gotcha); palette untouched.
- Final: fresh `/review-section` pass on results.tex + appendix.tex.
