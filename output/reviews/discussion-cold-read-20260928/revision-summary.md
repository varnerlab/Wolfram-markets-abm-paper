# Discussion cleanup completed

Revised `paper-arxiv/sections/discussion.tex` after the user authorized cleanup of the substantive audit issues. Eleven paired reader rounds include the original review-only audit. Every round used fresh independent readers, with either the full preceding manuscript or just Abstract/Introduction context. Final raw counts: full 0 severe, 0 substantive, 1 minor; skim 0 severe, 0 substantive, 1 minor. No substantive issues remain. The two minor notes concern the specificity of the population-spread analogy and the unexpanded intention-code sum in the limitations paragraph; see round 11 disposition.

## Reader counts

Severity 3 was zero in every report. “Substantive” below is raw severity 2, including any flags later triaged as optional detail. Reports are not necessarily unique concerns across readers.

| Round | Full: substantive / minor | Skim: substantive / minor |
|---|---:|---:|
| 1 (original audit) | 4 / 1 | 3 / 0 |
| 2 | 2 / 0 | 0 / 2 |
| 3 | 1 / 0 | 1 / 1 |
| 4 | 0 / 1 | 2 / 0 |
| 5 | 1 / 0 | 2 / 0 |
| 6 | 1 / 0 | 1 / 1 |
| 7 | 0 / 0 | 1 / 0 |
| 8 | 0 / 1 | 0 / 1 |
| 9 | 0 / 0 | 1 / 0 |
| 10 | 0 / 2 | 1 / 1 |
| 11 | 0 / 1 | 0 / 1 |

## Changes and scope

Clarified that selling intentions spread while rule changes remain assigned. Narrowed the pulse/switch contrast to what the tested interventions establish. Distinguished displayed active-trader examples from evidence with traders in Hold. Made the fixed-versus-adapting threshold comparison and its uncertainty understandable without Methods. Corrected the attribution of other price mechanisms to dealer inference and order-book dynamics. Removed dispensable literature earnings details while preserving every citation, and made the contribution include both intention spread and financial price consequences. Explained the existing isolated-round-trip property in plain language. These are interpretive and prose corrections; no numerical results, equations, references or citations changed.

## Preserved structure and checks

Six original paragraphs remain six, in the same order and with their original purposes. Prose count fell from 1586 to 1491 words. Structure, invariants, citation/mathematical multiplicities, voice and whitespace checks pass. `make -C paper-arxiv` succeeds with no final log warnings. The 31-page main PDF has the Discussion on pages 10–12; affected rendered pages and the redline were visually checked. No explicit page limit was imposed.

Source: `paper-arxiv/sections/discussion.tex`

Clean PDF: `paper-arxiv/Paper_v1.pdf`, pages 10–12.

Markup PDF: `output/pdf/Discussion-cold-read-markup.pdf`, changes on pages 10–12.

`rounds.md` records individual flags, evidence, repairs and residual minor notes. The original `audit.md`, baseline and first-round reports remain intact. This is a cold-read prose revision, not a full technical audit.
