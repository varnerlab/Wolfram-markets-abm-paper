# Analysis and presentation notes

The original seed-block finite-size and horizon analysis is frozen and
runs unchanged on the corrected data. Source and parameter checks remain
in `Protocol.json` and `Manifest.csv`.

Additional manuscript postprocessing is implemented in root
`code/rebuild/WriteManuscriptTables.py`, `WriteResults.py`, and
`WriteCaptions.py`. Those scripts were written after the computation
source freeze and will be archived and hashed with the completed study.
They read only this rebuild's data directory.

The completed dealer campaign showed substantial drawdowns even in
no-switch markets at shallow positive depth. Table S2 therefore includes
a descriptive financial comparison across **all eight** dealer depths
at the retained fraction f=.20 with active technical traders: median
no-switch drawdown, median switched drawdown, and the median of paired
within-starting-market drawdown differences. The intervals use 2,000
whole-market bootstrap samples, with random seed 20260914 and the same
sample indices across depths. They are pointwise descriptive intervals,
not predeclared confirmatory tests. Both feedback conditions are saved
in `code/data/Rebuild-Dealer-Paired-Drawdown.csv`.

This comparison is necessary to avoid attributing the entire switched
market drawdown to the rule switch. Total treated drawdown and the paired
increment answer different questions. The figure retains the total
financial outcomes, and the caption points to the paired table.

`presentation-v2/` records plotting-only revisions relative to the frozen
figure scripts. For Figure 2, the probability-difference label is moved
away from color-bar ticks and positive rejection rates use a logarithmic
axis. Every displayed lower quartile is checked to be positive. Figure 6
uses the full probability range, a logarithmic rejection axis, and a
logarithmic drawdown axis spanning all observed medians. All 27 displayed
rejection and drawdown medians are positive; there are no zero markers.
Bounds are asserted in the revised plotting script. Extra top margin
keeps the panel letters within the page.
Presentation changes do not alter simulations or metric definitions.
