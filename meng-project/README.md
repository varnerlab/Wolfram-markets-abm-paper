# When Traders Run Out of Shares

M.Eng. project proposal on an explicit open issue in the current manuscript:
whether traders with no shares should continue to communicate Sell to their
neighbors, and how this choice affects selling cascades and price declines.

## Deliverables

- [Four-page project description](output/pdf/inventory-project-description.pdf)
- [One-slide pitch PDF](output/pdf/inventory-pitch.pdf)
- [Editable PowerPoint pitch](output/pptx/inventory-pitch.pptx)
- [Description LaTeX source](project-description-doc/project-description.tex)
- [Pitch Beamer/TikZ source](pitch-slide/inventory-pitch.tex)
- [Speaker notes and likely questions](pitch-slide/speaker-notes.md)

The planning assumption is 3–4 students and a 14-week semester. The core study
tests one sell-side visibility rule with matched switched and no-switch
controls, retaining the corrected constant-product dealer. A proposed
2,000-trajectory confirmation campaign follows a separate runtime pilot.
No new model implementation or simulation campaign was performed to write
this proposal. The slide diagram illustrates observation rules, not results.

## Rebuild the PDFs

From the repository root:

```sh
make -C meng-project
```

Requires XeLaTeX, latexmk, Beamer, TikZ, textpos, fontspec, and TeX Gyre fonts.
The slide uses Helvetica Neue Light when installed and TeX Gyre Heros otherwise.
The documents build without network access or simulation data. Auxiliary files
go in the ignored `build/` directory. The PowerPoint uses Helvetica Neue and
has native editable text, circles, and lines, plus embedded speaker notes.

## Rebuild the PowerPoint

`pitch-slide/build-pptx.mjs` uses the supplied Codex `@oai/artifact-tool` runtime.
Set `RUNTIME_NODE_MODULES` to that runtime's `node_modules`, `RUNTIME_PYTHON`
to its Python executable, and `PRESENTATION_SKILL_DIR` to the installed
presentations skill directory. Run it with the runtime's Node executable:

```sh
node meng-project/pitch-slide/build-pptx.mjs /absolute/path/inside/meng-project/output/pptx/inventory-pitch-v2.pptx
```

Use a new output filename when rebuilding because the presentation finalizer
does not overwrite a validated file. The draft, preview, layout, and validation
receipt go in `build/pitch/`. The LaTeX slide and PowerPoint builder contain
parallel copies of the slide text; update both if revising the pitch.

## Basis for the project

The repository was inspected at commit `81cfd17` on September 28, 2026.

- `paper-arxiv/sections/discussion.tex` explicitly identifies visibility of
  resource-constrained intentions as untested.
- `paper-arxiv/sections/methods.tex` defines the original model and experiments.
- `code/src/Simulate.jl` gives the actual settlement and decision-update order.
- `code/src/ReserveClearing.jl` implements the corrected settlement mechanism.
- `code/rebuild/README.md` identifies the frozen corrected-study source.
- `code/repaired/README.md` and `code/src/Following.jl` document related
  transmission experiments. This project asks a separate question about
  inventory-dependent local Sell signals in the rule-switch study.

Design and scope reference: the neighboring `earnings_trade_project` directory,
particularly its LaTeX description and final Beamer pitch. Both artifacts here
are self-contained and need no files from that project to build.
