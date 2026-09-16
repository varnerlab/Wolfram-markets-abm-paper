# Introduction: interactive review

Status: still in discussion. The author clarified that the Introduction
review had not ended. The closing “In this study,” paragraph is the active
passage. Earlier accepted corrections remain saved. The four-paragraph
structure is retained, and Methods remains pending with an unapplied proposal.
Earlier statements that the entire Introduction was accepted and complete
were an incorrect interpretation of “Next.” Final manuscript-wide consistency
review also remains pending.

## Argument and paragraph roles

At most four developed paragraphs. The current sequence is:

1. Markets as the collective outcome of human interactions, including human
   ingenuity and failings. Introduce the scientific question before the
   detailed literature and experiments.
2. How agent-based models connect traders through shared prices, trading
   mechanisms, and local influence. Integrate the grid and Ising examples
   into that explanation, ending with the distinction between connections
   and responses.
3. Cellular automata and the current model: two interior trader types,
   technical traders, resource constraints, and a dealer acting as market
   maker. Develop the link from decisions to completed trades, reserves,
   prices, and later decisions within this one paragraph.
4. The study's comparisons: shared history, mixture, grid size, duration,
   removal of price feedback, and separate changes to financial resources.
   Explain what these comparisons test without previewing their results.

The main prose issues are crowded literature summaries, long sentences
containing several distinct claims, and repeated descriptions of the study.
Preserve paragraph development while simplifying the sentences. Let the
literature explain different ways traders interact rather than read as a
catalogue of models.

## Findings and evidence

Locations below refer to the Introduction before the opening was replaced.
The historical crash examples in finding 1 were removed with that opening.
Findings 2–3 concerned descriptions now removed from the Introduction.
Related Discussion prose remains pending. Finding 4 was addressed in the
applied model overview. Findings 5–6 were addressed in the subsequent
four-paragraph consolidation, whose wording remains open for author review.

### 1. Qualify the explanation of August 2007

Location: `paper-arxiv/sections/introduction.tex:6`.

The sentence presents forced sales as an established explanation for the
losses. Khandani and Lo report evidence consistent with portfolio
deleveraging and a temporary withdrawal of market-making capital. Their
causal account is an inference from factor portfolios and transactions.
Use "found evidence linking" or an equivalent qualification, and acknowledge
both elements when summarizing their explanation. This is an evidence-scope
correction, not a claim that the proposed mechanism was disproved.
[Primary study and published-version record](https://www.nber.org/papers/w14465).

The October 1987 example can stay. Shiller discusses portfolio-insurance
selling while questioning whether that explanation alone accounts for the
crash. Describe the selling response without attributing the entire crash
to it. Neither historical example establishes the persistent rule-switch
mechanism tested in the present paper.
[Shiller chapter](https://www.nber.org/system/files/chapters/c10958/c10958.pdf).

### 2. Scope the minority-game description

Location: `paper-arxiv/sections/introduction.tex:13`.

The original model uses strategies based on a shared record of outcomes.
The later cited paper also considers agents with a fixed strategy and noise
traders. "Every trader ... switches" is therefore too broad for both cited
papers together. Describe the basic version or the adaptive traders, rather
than treating all versions and agent types as identical.
[Original model](https://arxiv.org/abs/adap-org/9708006),
[extended model](https://arxiv.org/pdf/cond-mat/9909265).

### 3. Separate individual and collective effects of technical trading

Location: `paper-arxiv/sections/introduction.tex:16`.

The current semicolon-linked sentence compresses three studies and makes
the individual benefit and collective cost hard to distinguish. In the
Joshi experiments, adding technical rules benefited an individual given
the other traders' choices. When all traders used them, wealth was lower
and volatility higher than when all used fundamental rules alone. State
these comparisons separately. Scope the finding to their experiments.
[Joshi, Parker, and Bedau](https://sfi-edu.s3.amazonaws.com/sfi-edu/production/uploads/sfi-com/dev/uploads/filer/4d/a0/4da03e0d-f3ad-4e63-a884-cdb1029659cc/98-12-115.pdf).

Ehrentreich's paper supports retaining the dependence on learning-algorithm
details. It does not support saying that technical trading disappeared
under every corrected learning rule.
[Author's abstract](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=887848).

### 4. Distinguish the model family from this implementation

Locations: `paper-arxiv/sections/introduction.tex:39`, `:50`, and `:64`.

The opening description of a square grid with four neighbors is specific
to this model, not a definition of every cellular-automaton market. Its
interior traders use that update, while selected perimeter traders use
price. Introduce the model family generally, then identify the choices made
here. Replace the broad statement about two-dimensional models with
"Several two-dimensional models ..." and retain the distinction between
local and market-wide inputs.

Wolfram describes the cumulative difference in buying and selling states
as a rough price analogue. Valsan and colleagues report selected statistical
similarities between generated and real price series. Prefer "a price
analogue" and "selected statistical properties" to implying an execution
mechanism or complete statistical equivalence.
[Wolfram, page 432](https://www.wolframscience.com/nks/p432--financial-systems/),
[Valsan and colleagues](https://mdpi-res.com/d_attachment/algorithms/algorithms-15-00475/article_deploy/algorithms-15-00475.pdf?version=1671110242).

The technical traders are the only traders who respond **directly** to price.
Interior decisions can respond indirectly through their neighbors. After
trades set a new price, technical traders update their decisions. Interior
traders then respond to their neighbors. Keeping technical traders in Hold
removes that path while retaining financial execution.
Evidence: `output/rebuilt/manuscript-reserve-v1/code/src/Simulate.jl:101`
and `:697`–`:754`; `code/src/Compute.jl:59` within that same executed snapshot.

### 5. Keep the execution argument at Introduction depth

Location: `paper-arxiv/sections/introduction.tex:74`.

The distinction between decisions and completed sales is useful and agrees
with the implementation. Keep it. The constant-product construction also
agrees with the executed reserve-clearing code and Methods. In exact
arithmetic, restoring dealer inventory at fixed cash-times-inventory restores
dealer cash. That argument is correctly scoped to an isolated round trip.

The detailed batch-price, marginal-quote, and round-trip explanation makes
this paragraph read like Methods and recalls the history of the model
repair. Retain the reason for reserve-based pricing and its two consequences
for the design: reserves determine available trading resources and price
sensitivity. Keep the detailed construction and validation in Methods.
Explain the causal chain with concrete subjects: completed trades change
price, technical traders respond, and their neighbors receive new decisions.

Evidence: `output/rebuilt/manuscript-reserve-v1/code/src/ReserveClearing.jl`,
especially the candidate price, resource filters, settlement, and next quote;
`paper-arxiv/sections/methods.tex:57` and `:137`.
[Constant-function market-making framework](https://arxiv.org/pdf/2107.12484).

### 6. Make the final paragraph state questions and comparisons

Location: `paper-arxiv/sections/introduction.tex:101`.

Preserve "In this study," and the paired design. Use "examined whether"
or "examined how ... could" where the current wording anticipates a result.
Reduce repeated explanations of the rule switch and held control. State
what varying grid size, observation time, and resources tests. Keep all
numerical findings for Results. This is a narrative recommendation.

## Author feedback and revised opening

The author requested a broader opening about markets as the collective
outcome of human interactions, with human brilliance and failings. The
previous opening moved into historical episodes and model comparisons too
quickly. The author also removed the assistant's verification aside from
the explanation of direct and indirect price responses. State that behavior
directly in reader-facing prose; keep the supporting checks in the evidence
record.

The quotation is verified in the Financial Crisis Inquiry Commission's
*The Financial Crisis Inquiry Report*, January 2011, printed page xvii
(PDF page 17). The report concerns the 2008 crisis; it was not published in
2008. The line is the Commission's paraphrase of Shakespeare. Attribute it
to the report rather than present it as Shakespeare's exact wording.
[Official government edition, archived by Stanford](https://fcic-static.law.stanford.edu/cdn_media/fcic-reports/fcic_final_report_full.pdf#page=17).

Accepted opening, applied 16 September:

Financial markets are the collective outcome of human interactions. They reflect both our ingenuity and our failings. In its 2011 report on the 2008 financial crisis, the Financial Crisis Inquiry Commission paraphrased Shakespeare: “the fault lies not in the stars, but in us” [Financial Crisis Inquiry Report, p. xvii](https://fcic-static.law.stanford.edu/cdn_media/fcic-reports/fcic_final_report_full.pdf#page=17). In markets for traded financial assets such as stocks, investors make decisions with different information, expectations, and financial resources. They respond to prices and to the actions of others when deciding whether to buy, hold, or sell. An investor’s decision to sell can prompt others to do the same. Sellers need buyers who are willing and able to purchase their assets. The prices buyers will pay reflect their views of the assets’ value and the funds they can commit to the purchase. If sellers cannot find buyers at the current price, they may accept lower prices to complete their sales. The resulting price changes can then influence investors’ later decisions. Under what conditions can a change in the behavior of some investors lead to widespread selling, and when does that selling produce a market crash?

The author accepted the complete opening and its explanation of trade.
It names sellers and buyers, distinguishes willingness to pay from available
funds, and includes buyers' perceptions of asset value. These are general market
considerations; the current model does not explicitly estimate fundamental
asset values or simulate investors' valuation beliefs.

The author asked whether the opening should specify liquid assets and
accepted “traded financial assets such as stocks.” Avoid assuming
liquidity remains available throughout a market decline. Liquidity concerns
the ease, cost, and price impact of trading, and it can deteriorate under
stress. The opening does not impose a separate liquidity assumption on the model.
[Bank for International Settlements](https://www.bis.org/publications/shifting-tides-market-liquidity-and-market-making-fixed-income-instruments).

The report quotation motivates the study. It is not evidence that the
present model reproduces the 2008 crisis or represents every human or
institutional factor discussed by the Commission. The verified report
reference was added as `fcic2011financial`. The historical crash examples
were replaced by the approved opening. The detailed model comparisons now
form a separate paragraph awaiting revision.

## Scope of verification and open work

- Read the full Introduction, the relevant Methods, historical final-review
  notes, and the executed decision-update and reserve-clearing code.
- Checked the primary-source statements identified above. Also consulted
  the Bartolozzi, Qiu, Cont–Bouchaud, Bornholdt, and Raberto source records
  for the model-family comparisons. The broad literature synthesis remains
  an argument to assess, not an exhaustive novelty proof.
- Additional primary sources used for the proposed opening:
  [Samanidou and colleagues](https://arxiv.org/abs/physics/0701140),
  [Cont and Bouchaud](https://arxiv.org/abs/cond-mat/9712318),
  [Bornholdt](https://arxiv.org/abs/cond-mat/0105224),
  [Bartolozzi and Thomas](https://arxiv.org/abs/cond-mat/0311372),
  [Qiu and colleagues](https://journals.aps.org/pre/abstract/10.1103/PhysRevE.75.046116).
- Before editing, inspected the rendered Introduction on PDF pages 2–3 and its
  transition into Methods. No clipping, overlap, or broken citation display
  was apparent. The page break within paragraph 3 is an ordinary continuation.
- Not every reference in each existing citation cluster has been read in
  full. This pass does not certify every citation or establish that no
  earlier study asked a related intervention question.
- No simulation rerun occurred. The opening is general motivation and did
  not change the experiment, generated Results, or executed study snapshot.
- Pending: discussion of the literature paragraph and proposals for the
  rest of the Introduction. Their technical findings remain open until the
  corresponding prose is revised and checked.

## Applied opening: verification

- Scope: the first paragraph of `paper-arxiv/sections/introduction.tex` and
  the new report reference in `paper-arxiv/References_v1.bib`. Existing
  model-literature prose was retained as the next paragraph for review.
- `make -C paper-arxiv` passed. The final LaTeX log contained no warnings,
  undefined references, or overfull boxes. BibTeX reported no warnings.
- `pdfinfo` reported 30 pages, compared with 29 before the opening changed.
  Main-text pagination moved; the Conclusion now starts on its own page.
- Visually inspected PDF pages 2–17 and 26–30 after rendering with Poppler.
  Checked the new quote and citation, paragraph and section breaks,
  reflowed equations, references, adjacent tables, and supplementary pages.
  No clipping, overlap, broken citations, or stranded headings were seen.
- `python3 paper-arxiv/package_arxiv.py --verify` passed. The archive contains
  25 source/dependency files and compiles cleanly with identical extracted
  PDF text. The current output copy is `output/pdf/Wolfram-markets-revised.pdf`.
- Independent read-only reviewer `opening_technical_check` found no material
  technical issue in the saved first paragraph or report reference. It
  confirmed the general scope and checked the report's metadata against the
  official edition. It did not review the unchanged later paragraphs.
- Historical review and hash records in `output/rebuilt/manuscript-reserve-v1/`
  describe the frozen study snapshot. They do not certify this new PDF.

Checked PDF SHA-256: `5cdf0ab74ef84ecc004d7499c605bd383e9da4f0cc798811419d945fcb9ed59e`. The output copy has the same hash.

## Next paragraph: initial proposal, awaiting revision for literature coverage

Agent-based models study how individual trading decisions combine to produce market behavior. Traders can respond to shared market information or to the actions of other traders. In the basic minority game, traders use a shared history of outcomes to choose among competing strategies. Their choices determine the next outcome and therefore influence later decisions. In the Santa Fe artificial stock market, traders learn rules for forecasting prices and dividends. Studies of this market found that an individual trader could benefit from adding technical rules based on price patterns. When all traders used these rules, wealth was lower and price volatility was higher than when all used fundamental rules alone. The amount of technical trading also depended on the learning algorithm. Herding models describe how traders adopt the behavior of others. Models that arrange traders on a grid can make these interactions local, so that each trader responds to nearby traders. Some also include signals from the wider market. Such interactions can produce large price changes and periods of sustained volatility. These features alone do not distinguish the effects of a lasting change in how traders respond to their neighbors from the effects of feedback through prices. A temporary increase in selling and a lasting change in the rules used to make decisions need not produce the same market outcome.

Citation mapping for application after discussion: introductory model
description uses `lebaron2006agent,hommes2006heterogeneous,samanidou2007agent,axtell2025agent`;
basic minority game uses `challet1997minority,challet2000modeling`; Santa Fe
learning uses `lebaron1999time`; individual and collective technical-trading
comparisons use `joshi1999technical,joshi2002financial`; learning-algorithm
dependence uses `ehrentreich2006technical`; herding uses
`kirman1993ants,cont2000herd,lux1999scaling`; grid interactions use
`bornholdt2001ising,iori2002microsimulation,bartolozzi2004stochastic,qiu2007cellular,sornette2006importance`;
the observed-return features use `cont2001empirical` alongside the model
sources. The final distinction states the question addressed here, not a
claim that no previous model has studied related effects.

## Literature coverage: author feedback and checked sources

The author found the proposed paragraph generally acceptable but noted that
it omitted many agent-based market studies, including Farmer and Joshi.
The initial proposal above is retained as discussion history, not approved
prose. No manuscript edit was made in response to this question.

Recommended revision: establish the breadth of the field with reviews,
then explain a selection of primary models through the mechanisms relevant
to this paper. Reduce the detailed Santa Fe subdiscussion to make room for
other approaches. Farmer and Joshi's `farmer2002price` entry already exists
in the bibliography but is not cited in the current Introduction.

Verified Farmer and Joshi's primary paper, *The price dynamics of common
trading strategies*. The model considers value investors, trend followers,
and a market maker. Traders' orders affect prices, and prices enter later
trading decisions. The paper studies individual strategies and their joint
price dynamics, including noise amplification and volatility. Its market
maker absorbs net orders and adjusts prices without an inventory-dependent
risk constraint. Use it as an example of trading-rule and price feedback,
not as evidence that earlier models only matched aggregate statistics.
[Primary preprint](https://arxiv.org/pdf/cond-mat/0012419), especially pages 2–4;
[published record](https://www.sciencedirect.com/science/article/abs/pii/S0167268102000653).

Broad coverage can use existing reviews: LeBaron (2006), Hommes (2006),
Samanidou and colleagues (2007), and Axtell and Farmer (2025), selected for
the claim each supports. Rechecked the abstracts and records for
[Samanidou and colleagues](https://arxiv.org/abs/physics/0701140) and
[Axtell and Farmer](https://www.aeaweb.org/articles?id=10.1257%2Fjel.20221319).
These reviews establish the broader literature context; they do not by
themselves establish novelty for the current intervention design.

State the contribution as the specific controlled comparison: a persistent
change in a local decision rule, compared with continued use of the original
rule, with and without price feedback. Closest related cellular-automaton
and execution models require their own discussion in the following
paragraphs. Do not assert that the field has not separated related effects
without a targeted search supporting that claim.

## Prior work supplied by the author: Wheeler and Varner

Verified [arXiv:2312.14903](https://arxiv.org/abs/2312.14903), Aaron Wheeler
and Jeffrey D. Varner, *Scalable Agent-Based Modeling for Complex Financial
Market Simulations*. First submitted 22 December 2023; version 2 dated
31 January 2024. DOI: `10.48550/arXiv.2312.14903`. No matching entry was found
in the current manuscript bibliography.

Read the [version 2 text](https://arxiv.org/html/2312.14903v2), especially
Methods 2.1–2.2 and the conclusions. The framework supports multiple assets,
parallel decisions, asynchronous orders, explicit order books, and continuous
double-auction matching. Adaptive market making was tested in single-asset
runs; the intelligent agent was excluded from the multiple-asset trials.
Do not imply every supported feature appeared together in those trials.

Editorial role: an example of explicit order matching in the literature
discussion. Develop the connection to this paper's execution assumptions in
the later paragraph on trading resources and prices. The source documents
a different simulator; it does not establish that this paper extends its
implementation or uses the same trading mechanism.

Proposed wording, not applied:

> In previous work, we developed an agent-based market that supported trading
> in multiple assets. Agents submitted orders to a continuous double auction,
> which matched compatible buy and sell orders as they arrived. The framework
> allowed traders with different decision rules to interact through a common
> trading mechanism.

The verified reference was added when applying the agreed literature revision.

## Applied literature and grid paragraphs

The author approved application with “Agree. Update. next” after clarifying
Bornholdt's decision process. The broader model examples and the developed
grid explanation form separate paragraphs. Wheeler and Varner precedes the
grid discussion so that the combined grid/rule sentence leads directly into
the cellular-automaton passage. The following is the saved manuscript text:

```tex
Agent-based models study how individual trading decisions and interactions
among investors produce market behavior. This literature includes many
approaches to learning, imitation, and price
formation~\cite{samanidou2007agent,axtell2025agent}. Several examples
illustrate connections relevant to this study. Farmer and Joshi studied
traders who followed price trends or compared prices with their estimates
of asset value. A market maker absorbed their net orders and adjusted the
price. The resulting price changes then influenced later trading
decisions~\cite{farmer2002price}. In the Santa Fe artificial stock market,
traders learned forecasting rules from market prices and dividends and
used those forecasts to guide their trades~\cite{lebaron1999time}.
In previous work, we developed an agent-based market that supported trading
in multiple assets. Agents submitted orders to a continuous double auction,
which matched compatible buy and sell orders as they arrived. The framework
allowed traders with different decision rules to interact through a common
trading mechanism~\cite{wheeler2023scalable}. We therefore ask how a change
in some traders' decision rules affects the decisions of others and how the
trades they can complete affect prices.

Herding models describe how traders' decisions are influenced by the
behavior of others~\cite{kirman1993ants,cont2000herd,lux1999scaling}.
A grid provides a simple representation of the connections through which
this influence operates. Each site represents a trader, and neighboring
sites identify the traders whose decisions it can observe. The information
passed through these connections can be as simple as a trader's current
decision to buy or sell~\cite{iori2002microsimulation}. A change in one
trader's decision can affect its neighbors. Their responses can then
influence other traders, allowing a local change to spread through the
group. Models inspired by the Ising model use interactions between
neighboring traders to represent imitation. In Bornholdt's simplified
model, each trader's decision depended on its neighbors' decisions and
the balance of buyers and sellers across the market. Traders tended to
follow their neighbors. A growing imbalance between buyers and sellers
increased their tendency to reverse their current
decisions~\cite{bornholdt2001ising}. Iori used a related model in which
traders could buy, sell, or remain inactive. Traders repeatedly exchanged
their current decisions with their neighbors and used the resulting signals
to revise their own choices~\cite{iori2002microsimulation}. These models
used similar grids but different rules for responding to neighboring
decisions. The grid specifies who can influence whom, while the decision
rule specifies how each trader responds.
```

Added `wheeler2023scalable` with verified arXiv metadata. The review citations
establish breadth; the primary examples explain the mechanisms selected for
this question. The minority-game description and the detailed Santa Fe
technical-trading subdiscussion were removed from this Introduction passage.
Their existing bibliography entries remain available for Discussion review.

Checked the Santa Fe description against the
[published article preview](https://www.sciencedirect.com/science/article/pii/S0165188998000815)
and the authors' [Santa Fe Institute record](https://santafe.edu/research/results/papers/1388-time-series-properties-of-an-artificial-stock).

## Grid interpretation and Ising models: discussion and accepted wording

The author requested a fuller account of the grid as a way to model
influence and information flow, and asked whether Ising models belong here.
The accepted expansion is now the paragraph following the broader model
examples. Its explanation of connections and responses leads into the
cellular-automaton passage still awaiting revision.

Checked [Iori's primary manuscript](https://arxiv.org/pdf/adap-org/9905005),
pages 3–6. The lattice is explicitly a communication structure. Traders
exchange temporary decision signals with four neighbors during consultation
rounds. The model modifies a random-field Ising formulation and allows
buying, selling, and inactivity. Its resource limits and price feedback also
make it relevant to the later execution discussion.

Checked [Bornholdt's primary manuscript](https://arxiv.org/pdf/cond-mat/0105224),
pages 2–3. Local couplings favor alignment; another term responds to total
magnetization, interpreted through the balance of buying and selling. This
is a concrete Ising example, not a definition of every lattice market.

Interpretive scope: the grid is an idealized network specifying possible
influence, not an empirically fitted social network. Information here may
be a neighboring decision; the present model does not simulate messages,
valuation learning, or diffusion of an external news item. Distinguish the
connection structure from the response rule. An Ising comparison does not
make the present deterministic three-state automaton a two-state Ising
system or imply equilibrium critical behavior. Decisions can spread while
traders retain their own assigned rules.

**Clarity revision:** the author found the two-state and market-balance
sentences unclear and requested a smoother transition to a combined closing
sentence. The current draft now describes buying, selling, local imitation,
and the response to a growing market imbalance in separate sentences.
"Bornholdt's simplified model" refers to the version in Eq. (4), obtained
when strategy adjustment is instantaneous. Its local term favors alignment;
the global term increases the tendency to reverse the current state as
the absolute market imbalance increases. This is not a claim that only
majority traders can switch or that everyone must switch. The comparison
with Iori's decision rule leads into the combined sentence distinguishing
local connections from responses. The author then requested clarification
of “The rule.” The final accepted wording names the two influences directly
and is reproduced in the applied text above.

## Applied literature revision: verification

- Scope: Introduction paragraphs 2–3 and the Wheeler–Varner reference. The
  approved first paragraph and the later manuscript passages were preserved.
- Normal LaTeX build passed. No LaTeX or BibTeX warnings, undefined references,
  or overfull boxes. `pdfinfo` reports 29 pages, compared with 30 before this
  pass; bibliography pagination changed as the cited sources changed.
- Inspected rendered PDF pages 2–15 and 25–29, covering reflowed main text,
  bibliography, adjacent tables, and supplementary pages with renumbered
  citations. No clipping, overlap, broken citation display, or stranded
  headings was seen. Unchanged figure layouts were not reinspected.
- The source archive contains 25 source/dependency files. Its isolated compile
  passed and the extracted PDF text matched the root manuscript exactly.
- Refreshed `output/pdf/Wolfram-markets-revised.pdf`; its hash matches the root
  PDF. `git diff --check` passed. No simulation or generator was rerun.
- Independent read-only reviewer `literature_technical_check` found no
  material scientific issue in the saved paragraphs or new reference. It
  checked the Farmer–Joshi, Santa Fe, Bornholdt, Iori, and Wheeler–Varner
  descriptions and the new entry's metadata. Later paragraphs were excluded.
- Prior hashes above and the frozen study's historical verification records
  apply only to their corresponding earlier artifacts.

Checked PDF SHA-256: `877d1262930cb8fd3fa009276179c33de10282054033a14aa590bc7d36870e07`.

## Applied cellular-automaton overview

Cellular automata provide a way to study how local decision rules produce collective behavior. Traders occupy sites on a grid and update their decisions at discrete time steps. Wolfram illustrated this approach with traders arranged on a line. Each trader responded to its two neighbors, and the cumulative difference between buying and selling served as a price analogue. Valsan and colleagues later combined cellular automata with trader balance sheets and generated price series with selected statistical properties of observed markets. Other studies used two-dimensional grids with stochastic rules for trader interactions. Our model combines two types of traders inside a square grid. Both types decide whether to buy, hold, or sell from the decisions of their four neighbors. Their rules differ in a single response to those neighboring decisions. We vary the relative numbers of the two types to study how the mixture affects the spread of selling. Technical traders along the edge of the grid base their decisions on prices. Their choices provide a path through which price changes can influence traders inside the grid. A dealer acts as the market maker. It can use its finite cash and share reserves to complete trades that cannot be matched between traders. Its remaining cash and shares determine the next quoted price. That price then informs the technical traders' next decisions. The market therefore connects local interactions among traders with the financial resources and completed trades that determine prices.

Citation mapping: `wolfram1984universality,packard1985two` for the general
cellular-automaton formulation; `wolfram2002new` for the line model;
`valsan2022on` for balance sheets and selected statistical similarities;
`wei2003cellular,bartolozzi2004stochastic,qiu2007cellular,fan2009effect,atman2012influence`
for selected stochastic two-dimensional models. Existing source evidence is
recorded in finding 4. Pairing references belong with the later study-design
passage or Methods when that comparison is explained.
The implementation-specific description agrees with the current Methods and
previously checked executed update logic. The sum-based (totalistic) table
construction remains defined in Methods; this Introduction overview does
not claim a distinct response for every arrangement of neighboring states.
The author approved this paragraph with “Agree. Next.” It is now applied
with the citations above. Its independent review is recorded below.

## Model overview: author correction

The author requested a general description of a mixture of two interior
trader types whose rules differ in one response. The table-entry operation,
one-time Sell instruction, and shared-history comparison obscured that
idea. The author also noted the missing market maker. The accepted overview
above now introduces the interior types, technical traders, and market maker
before procedural controls. The pulse and paired experiments remain in
Methods and can be summarized in the closing study paragraph.

The two interior types are additional to the technical traders. The mixture
is the post-activation composition; this overview does not change the common
single-rule history or imply that rules spread between traders. Mixing
trader types is a description of the existing experiment, not a redesign.
The market maker is the same intermediary called the dealer in the current
Methods. It absorbs feasible unmatched orders from finite reserves and its
post-trade cash/share ratio determines the next marginal quote. Matched
trader trades can occur without a net dealer transfer. This proposal does
not claim that every desired order is filled or that the dealer is an
additional site following a cellular-automaton rule.

Rechecked the model description against current Methods (three-state
cellular automaton; orders, resources, and completed trades; technical
traders; paired experiments) and the executed reserve-clearing routine.
The initial discussion changed no manuscript source or build output. The
subsequent approval and application are recorded below.

## Applied model overview: verification

- Scope: Introduction paragraph beginning “Cellular automata provide” and
  ending “determine prices.” Earlier accepted paragraphs and the later
  resources and study-design paragraphs were preserved.
- Normal LaTeX build passed without LaTeX/BibTeX warnings, undefined
  references, or overfull boxes. The PDF remains 29 pages.
- Compared extracted text page by page with the preceding PDF. Changes
  occurred on pages 2–6, 9–10, and 13–14. Rendered and visually inspected
  pages 2–15, including neighboring pages. No clipping, overlap, broken
  citations, or stranded headings was seen. Unchanged figures and appendix
  pages were not reinspected in this pass.
- Source archive verification passed: 25 source/dependency files, clean
  isolated compile, and identical extracted PDF text. Refreshed the output
  PDF copy. No simulation, model source, or manuscript generator was rerun.
- Independent read-only reviewer `model_overview_check` found no material
  findings in the saved paragraph. It checked fixed assigned rules, the
  post-activation mixture, and the order-to-price-to-decision sequence
  against the executed `Simulate.jl:697–754` and finite reserve clearing
  against `ReserveClearing.jl:45–103`. Literature wording was checked
  against the source evidence recorded above. Its scope did not include
  later paragraphs or layout.
- The earlier hashes and frozen simulation review records certify their
  respective earlier artifacts, not this revised PDF.

Checked PDF SHA-256: `1a316b82e0f810d46cfbce80c3c6b02ddc2c0dc129200d803ed3ac06c20e7035`.
The root PDF and `output/pdf/Wolfram-markets-revised.pdf` have the same hash.

## Next paragraph: trading resources and prices — proposal only

A market in which most traders decide to sell need not experience a large price decline. The connection depends partly on the resources available to complete trades. Earlier agent-based models have examined limits on traders' cash and asset holdings and on their ability to borrow. In our model, a trader needs shares to sell and cash to buy. A trader that has exhausted its shares can still decide to sell, and its neighbors can still respond to that decision. Selling decisions can therefore spread without a corresponding increase in completed sales. We connect completed trades to prices by keeping the product of the dealer's cash and share reserves constant. When the dealer buys shares from traders, it gains shares and spends cash. Its ratio of cash to shares falls, lowering the next quoted price. The size of the dealer's reserves determines both which trades can be completed and how much a given net trade changes the price. Trader holdings and dealer reserves can therefore change the price response to a given pattern of selling decisions. When technical traders are active, the resulting price changes can also influence later decisions across the grid.

Citation mapping: `raberto2001agent,thurner2012leverage` for the prior models'
trader resources and borrowing limits; `angeris2022constant` for the
constant-product construction. The detailed batch price, marginal quote,
and round-trip identity remain in Methods. The draft describes the model's
mechanisms without presenting simulation results or asserting that a smaller
dealer necessarily limits a price decline. The zero-reserve fixed-price
control remains a separate case in Methods.

Checked [Raberto and colleagues' primary record](https://arxiv.org/abs/cond-mat/0103600):
finite trader cash and asset portfolios, conserved total cash, and
resource-constrained trading. Checked
[Thurner, Farmer, and Geanakoplos](https://arxiv.org/abs/0908.1555):
borrowing permits leveraged purchases; leverage limits can require sales
and feed back into prices. These are specific precedents for resource
constraints, not a claim that all models implement the same constraints.
The reserve-price explanation agrees with the current Methods equations
for execution and settlement and the already checked executed clearing code.

**Verified citation problem in the existing paragraph:**
[Braun-Munzinger, Liu, and Turrell, §2.3](https://aeturrell.com/research/articles/braunmunzinger-liu-turrell/braunmunzinger-liu-turrell.pdf)
explicitly state that their market maker is not balance-sheet constrained.
It meets demand and supply requests and adjusts prices using net demand
and volatility. Their funds have budget constraints and cannot borrow,
but that does not establish finite dealer reserves. Do not use
`braunmunzinger2018agent` to support that part of the original grouped claim.
The proposal omits that attribution. Citation uses elsewhere in the paper
remain pending review; no unrelated section was changed.

## Four-paragraph consolidation: author correction and applied draft

The author rejected the fragmented progression and explicitly required no
more than four Introduction paragraphs. The preceding passage-by-passage
review had lost the section's overall argument. Standalone paragraphs for
literature, grid influence, cellular automata, and resources accumulated
separate openings and conclusions. Treating each review passage as a new
paragraph was the editorial error.

Reorganized the complete Introduction into four paragraphs. The accepted
opening is unchanged. The second paragraph connects shared prices and
trading mechanisms to direct influence through neighboring decisions.
The third explains the cellular-automaton approach and the present market
as one sequence from trader types through resource-constrained trading to
prices and feedback. The fourth describes the comparisons and the questions
they test. Removed duplicate question statements and the detailed batch-price
and round-trip material. Pulse and alternative-rule controls remain in
Methods. No model, data, experiment, or other manuscript section was changed.

The manuscript is a revised draft for review as a whole. Applying the author's
structural instruction does not establish approval of all new wording.
Earlier paragraph-level approvals remain useful calibration but must not
justify returning to the fragmented structure. `HOUSE_STYLE.md` now records
the four-paragraph maximum. `PUBLICATION_STYLE.md` records the general rule
that review units need not become manuscript paragraphs and that combining
passages requires rewritten transitions and removal of repetition.

Validation of this saved draft:

- Confirmed exactly four prose paragraphs in the Introduction. Read their
  connections and checked that earlier accepted distinctions remain intact.
  Paragraph counts are the author's requirement; word counts are not targets.
- Normal build passed. No LaTeX/BibTeX warnings, undefined references, or
  overfull boxes. The PDF is 28 pages, compared with 29 before this pass.
- Rendered and inspected PDF pages 2–14 and 24–28: the Introduction, reflowed
  main text and references, adjacent tables, and supplementary pages with
  renumbered citations. No clipping, overlap, broken references, or stranded
  headings was seen. Figure layouts and the remaining table layouts were
  unchanged and were not reinspected in this pass.
- The archive contains 25 source/dependency files. Its isolated compile
  passed and its extracted PDF text matches the root PDF exactly. Refreshed
  `output/pdf/Wolfram-markets-revised.pdf`; it matches the root PDF hash.
- Independent read-only reviewer `integrated_introduction_check` found no
  substantive scientific issue. It checked the saved text against the prior
  draft, recorded primary-source checks, current Methods, and frozen code.
  The review confirmed fixed trader rules, local influence, technical-trader
  feedback, dealer clearing and price direction, paired history, and the
  distinction between decisions and price declines. It also confirmed that
  the finite-dealer attribution to Braun-Munzinger was removed. This check
  does not constitute the author's acceptance of the narrative.

Checked PDF SHA-256: `3eb1a957ab4beec91aac1208cb94607c9bb4e5d2bb5f75cdb9372054117470ac`.
Earlier PDF hashes certify their corresponding historical artifacts only.

## Intentions, executed trades, and dealer quote: author correction

The author asked what completing a trade means and flagged language that
could be read as permitting short sales. The author also required the same
explanation for buyers without cash, a direct explanation of the dealer's
cash/share ratio, and explicit names in place of “that price” and “this
market.”

Applied within the existing third and fourth paragraphs:

- Buy and Sell indicate intentions. A completed trade transfers shares
  from seller to buyer and cash from buyer to seller.
- Traders cannot borrow cash or sell shares they do not own. A seller
  without shares and a buyer without enough cash cannot execute their
  intended trades. Neighbors can still respond to the intended actions.
- After trading, the dealer's quoted price per share equals remaining
  dealer cash divided by dealer share count. A dealer purchase reduces
  cash and increases shares, lowering the quote. Technical traders use
  the updated dealer quote in their next decisions.
- The closing paragraph now names the three-state cellular automaton
  market. The Sell-majority definition explicitly concerns the desire
  to sell, and vague demonstrative references in the changed passages
  were replaced with the named participants and quantities.

The quote is the post-settlement price signal, distinct from the common
execution price defined in Methods. The quote explanation concerns the
positive-reserve market; Methods separately defines the zero-reserve
fixed-price control. No change to execution, permitted positions, or
neighbor information was made. The scientific model already imposed the
constraints now made explicit in the Introduction.

Verification:

- Confirmed four Introduction paragraphs and unchanged first two paragraphs.
- Normal build passed without LaTeX/BibTeX warnings, undefined references,
  or overfull boxes. The PDF is 29 pages after reflow, up from 28.
- Rendered and visually inspected pages 2–15 and 25–29, covering the revised
  Introduction, reflowed main text and bibliography, adjacent tables, and
  supplementary pages. No clipping, overlap, or broken references was seen.
  The Conclusion now continues onto page 11. Unchanged figure layouts and
  remaining table layouts were not reinspected in this pass.
- The 25-file source archive passed its isolated compile with identical
  extracted PDF text. Refreshed the output PDF copy.
- Independent read-only reviewer `integrated_introduction_check` rechecked
  saved paragraphs 3–4 against Methods and frozen implementation and found
  no material scientific issue. The check covered intentions, resource
  limits, transfers, the quote, majority definition, and feedback removal.
  It did not perform layout review or constitute author approval of prose.

Checked PDF SHA-256: `d693af94dd276ee505a58840acfaaa8c534a8282855f7113bd4e9853f33c909a`. The root and output PDFs match.
Earlier hashes refer only to their corresponding historical artifacts.

## Closing study paragraph: paired states, held traders, and past tense

The author clarified that the review was still on the Introduction and
identified five problems in its closing paragraph: “retained” decisions
and holdings suggested identical later behavior; citations after “second
trader type” had no clear role; “mixture” did not identify the population;
the held condition seemed to stop price changes as well as feedback; and
present-tense statements remained. Moving to Methods was premature. The
Methods proposal is parked and unapplied.

Revised only the closing Introduction paragraph. The source now specifies
that intentions, trader cash and shares, dealer reserves, and quotes matched
when the second type was introduced. Later intentions and trades could
differ under the assigned rules. The varied quantity is the fraction of
interior traders using the second rule. The held comparison states that
interior traders still responded to neighboring intentions and could trade
with one another or the dealer. Dealer trades could alter reserves and the
quoted price. Technical traders kept signaling Hold regardless of the
quote, so price changes no longer entered interior decision rules through
neighboring intentions. Price could still affect financial execution; the
paragraph does not claim that all price effects disappeared.

The former citations were Glasserman and Yao's *Some guidelines and
guarantees for common random numbers* and Law's *Simulation modeling and
analysis*. Their purpose was support for paired simulation comparisons,
not the second trader type. Removed them from the closing Introduction
sentence. Their existing citation in the Discussion's paired-design
explanation remains. No bibliography entry was deleted and no Methods text
was changed.

The closing paragraph is past tense throughout, including “which we called
a Sell majority.” Removed the redundant present-tense concluding sentence.
Recorded the tense requirement in both style guides. The Introduction
remains four developed paragraphs; the first three were unchanged.

Evidence: current Methods' paired experiments and technical-trader feedback
descriptions; frozen `Simulate.jl:590–610` and `:678–754`. Rule assignment
changed before orders without resetting dynamic state. Reserve clearing
continued in held mode, while technical-trader states were set to Hold
before the interior update. The obsolete standing-quote comment in the
shared loop was not used as evidence of the executed clearing mechanism.

Verification of the saved closing paragraph:

- Independent read-only reviewer `integrated_introduction_check` found no
  material scientific issue. It confirmed common-state timing, possible
  subsequent divergence, the fraction varied, the majority definition,
  continued held-mode trading and quote changes, and removal of price
  feedback into intentions.
- Normal build passed without LaTeX/BibTeX warnings, undefined references,
  or overfull boxes. The PDF remains 29 pages.
- Compared extracted text with the prior PDF: pages 3–11 and 13 changed.
  Rendered and visually inspected pages 2–14 including neighbors. No
  clipping, overlap, broken citations, or stranded headings was seen.
  The Conclusion still continues on page 11. Unchanged table, figure,
  and supplementary layouts were not reinspected in this pass.
- The 25-file source archive passed its isolated compile with identical
  extracted PDF text. Refreshed the output PDF copy. No simulation, data,
  model source, or manuscript generator changed.

Checked PDF SHA-256: `a0c9313923b2ee60c13253e63eb07f436bf2b67fd9fe076d7e2007b494df0bcb`.
The root PDF and output copy match. Earlier hashes describe earlier PDFs.

## Synthetic market terminology

The author preferred “synthetic market” to “world” or “grid” for the
Introduction's setting. Replaced grid terminology in that section with
synthetic market, rows and columns, neighboring positions, or neighboring
traders as appropriate. The size comparison now names synthetic markets
containing different numbers of traders. The arrangement still specifies
who can influence whom, and the decision rule specifies each trader's
response. No geometry, decision rule, or financial mechanism changed.
Recorded the preference in both style guides. Formal geometry in Methods
remains pending review. The Introduction retains four paragraphs and a
closing study paragraph in past tense.

Verification:

- Independent read-only reviewer `integrated_introduction_check` found no
  material scientific issue. The wording preserves local interactions and
  does not imply that absolute dealer reserves stayed fixed as the trader
  population changed.
- Normal build passed without LaTeX/BibTeX warnings, undefined references,
  or overfull boxes. The PDF remains 29 pages.
- Extracted-text comparison identified changes on pages 2–11. Rendered and
  visually inspected pages 2–12, including the adjacent references page.
  No clipping, overlaps, or broken layout was seen.
- The 25-file source archive passed an isolated compile with identical
  extracted PDF text. Refreshed the output PDF. No simulation, model code,
  data, Methods source, or manuscript generator changed.

Checked PDF SHA-256: `204ed8a7f4bf8db92607bdefea8a72a347e5da3d81eef4af366656d38aeb4b1b`.
The root PDF, output copy, and archive validation hash match.

## Author's verb correction

Changed only “we used a synthetic market” to “we constructed a synthetic
market” in the closing paragraph. This names the authors' model construction
directly. The independent read-only reviewer found no material issue.
Normal and isolated archive builds passed without warnings or overfull
boxes; extracted archive PDF text matched. Only page 3 changed. Visually
inspected pages 2–4; no layout issue was seen. The PDF remains 29 pages.
Refreshed the output copy. Root, output, and archive validation SHA-256:
`a42ec2c11b52b33bab90a998ed63a1c19ac146d21c0ef73be0176fcf84e931cc`.

## Closing paragraph: further proposal under discussion

The author requested simpler language for later differences between the
paired markets, questioned whether market size changed with the mixture,
asked for the effect of price on execution to remain explicit in the held
condition, and requested a final sentence explaining the broader purpose.

Checked the frozen size-campaign summary: `gridn` contains 32, 48, 64, 96,
and 128. Frozen `Manifest.py` specifies separate mixture, size, and duration
comparisons. The number of traders stays fixed within each paired comparison;
the size experiments also vary total population. These must be distinguished
in prose rather than deleting the size comparison. Frozen
`ReserveClearing.jl` checks buyer cash against the execution price. Frozen
`Simulate.jl` keeps clearing active when technical traders indicate Hold.

Proposed a continuous closing paragraph that says traders could subsequently
make different decisions and complete different trades; explicitly states
the equal populations within a pair; introduces size and duration as separate
experiments; and explains execution-price effects through buyer affordability.
Proposed closing: “The broader aim was to understand how interactions among
traders and the resources available for trading could together produce a
market crash.” This states the study's purpose without adding a result.
The revised paragraph remains a proposal. No manuscript or PDF change was
made in this discussion turn.

## Assessment of the broader purpose

The author accepted the proposed execution clarification covering sellers
as well as buyers, then asked whether the study accomplished its broader
aim and whether the contribution was worthwhile. The closing paragraph
remains under discussion; no further manuscript edits have been applied.

Checked the frozen paired-rule, resource, dealer, and control summaries.
At fraction 0.20 with active technical traders and depth 100, 50/50 changed
markets reached a Sell majority and 0/50 paired controls did. The one-time
Sell pulses had zero majorities at the tested fractions 0.15, 0.20, and
0.25 under both feedback conditions. Of eighteen alternative responses at
fraction 0.20, six produced majorities in every tested starting market and
twelve produced none under both feedback conditions.

For held technical traders at fraction 0.18, depth 100, and unchanged cash,
share multipliers 0.1, 1, and 10 retained majority probability 0.64 and the
same mean final Sell fraction. Median drawdowns were 3.44%, 20.15%, and
77.11%. These values are from the held rows of the balance-sheet grouped
summary, not the active examples currently quoted in Results. The frozen
implementation and prior checks establish that the held decision histories
do not depend on financial state. That independence is a model property;
the occurrence and timing of majorities after the rule intervention are
simulation findings.

The controlled separation of persistent rule changes, selling intentions,
execution, and price outcomes supports a worthwhile modeling contribution.
The interpretation remains conditional on the assigned decision rules and
constant-product pricing mechanism. Dealer depth changes funding and price
sensitivity together, so their independent effects are not identified.
The shallow dealer controls already had large drawdowns; total declines
must not all be attributed to the rule change. Empirical explanation of
actual market crashes and field-wide novelty are not established by this
assessment. Proposed framing should state the question and approach in the
Introduction, reserving findings and their limits for Results and Discussion.

## Crowding and copy trading omitted from the current framing

The author asked that the study overview include crowding and copy trading,
clarifying that “clustering” meant crowding. The prior assessment covered
only the rule-change manuscript and omitted these completed extensions.
The current Introduction, Methods, Results, and Discussion do not describe
the following experiments. Integrating their contribution requires matching
coverage when those sections are reviewed; an Introduction-only claim would
leave the manuscript incomplete.

Read the repaired following pilot report, repaired-model assessment, and
fresh-market advice-confirmation assessment, report, primary endpoints, and
protocol. The corrected pilot contains shared advice and copying completed
trades across ten starting markets. It varies follower fraction and source
concentration and reports effects on non-followers, prices, and follower
cash after matched liquidation. Copying remains exploratory under the
corrected execution mechanism. The later 50-market confirmation covers
shared advice, not copying, and supports the contribution of direct local
influence to follower cash gains in its primary deep-reserve held setting.
Gains do not persist across all reserve and feedback conditions. The
archived following confirmation used the older execution mechanism and
cannot establish current-model financial claims.

Proposed Introduction scope: describe crowding as groups following shared
advice or copying other traders' completed trades; name follower fraction
and number of sources as distinct comparisons; connect their effects on
non-followers and the distribution of gains and losses to the existing
questions about widespread selling and price declines. Shared advice and
copying must remain distinct interventions, with their evidence levels
preserved. No claim that copying always increased selling or benefited
followers is supported. No manuscript edit or new simulation was made.

## Complete closing paragraph applied and PDF refreshed

At the author's request, integrated the accumulated agreed revisions into
one closing paragraph and rebuilt the PDF. It now uses simple language for
subsequent decisions and trades, distinguishes equal populations within a
paired rule-change comparison from separate size/duration experiments, and
explains both buyer and seller execution requirements. It includes crowding,
shared advice, copying completed trades, and the qualitative contribution
ending approved in the discussion. Recorded the author's contribution-ending
preference in the guides, superseding the earlier blanket exclusion of
findings from the closing paragraph. Numerical results remain outside it.

The independent reviewer identified one scope problem: holding technical
traders blocks financial inputs to intentions in the rule-change experiments,
but completed-trade copying retains an execution-mediated route. Confirmed
the distinction in the following design and `code/src/Following.jl:208`.
Limited the sentence explicitly to the rule-change experiments. The reviewer
rechecked the final saved paragraph and confirmed the finding resolved with
no remaining findings from this pass.

Verification: the first three Introduction paragraphs are unchanged, the
section remains four paragraphs, and the closing paragraph uses past tense.
The normal build passed with no LaTeX/BibTeX warnings, undefined references,
or overfull boxes. The PDF remains 29 pages. Extracted text changed on pages
3–11; visually inspected rendered pages 2–12, including the adjacent pages.
The complete closing paragraph fits on page 3. No clipping, overlap, or
broken page layout was seen. The 25-file source archive passed its isolated
compile with identical extracted PDF text. Refreshed the output PDF copy.
No model, data, simulation, or Methods/Results source changed. Integration
of the following studies into those later sections remains pending.

Checked PDF SHA-256: `6c4093cd23da05260a302d205c67f507841b5de29b10967d02ab624ad2f5420e`.
The root PDF, output copy, and archive validation hash match. Earlier hashes
refer to their historical PDF revisions.

## Author status: good draft

The author accepted the Introduction as a “good draft” and explicitly asked
to move on. Resume Methods review. This is approval of the current draft for
progressing through the paper, not a claim that later-section integration or
the final manuscript-wide consistency review is complete. No Introduction
source or PDF change was needed for this status update.
