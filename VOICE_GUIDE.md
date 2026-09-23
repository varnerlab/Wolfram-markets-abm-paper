# Voice Guide: Jeffrey Varner

Written 23 September 2026 from three sources: the author's single-author
papers (arXiv 2607.07677, weighted highest, plus 2603.20115 and 2603.14717),
his first-author coagulation paper (2604.07557), and his own recorded
feedback on this manuscript. On questions of voice, this guide takes
precedence over PUBLICATION_STYLE.md and HOUSE_STYLE.md. HOUSE_STYLE.md still
governs terminology, claims, numbers, evidence, generators, and the build.

## What he asked for, in his words

- "simple, and direct language without adjective overuse ... simple direct
  sentences (not a bunch of comma or ; spliced fragments) and ... long well
  developed paragraphs."
- "a bit robotic ... NOT a call for fancy, slick phrases ... a few well
  placed direct and simple big picture type sentences."
- "Combine: The grid specifies who can influence whom, while decision rule
  specifies how each trader responds ... make sure we are smooooooth."
- "choppy"; "not 20 small vignettes"; "I hate short paragraphs."
- "keep it simple"; "of what?"; "just say what you are referring to";
  "This is an impl detail."

He never asked for shorter sentences. The 16–18 September review split
them anyway: the Introduction went from a median of 24 to 16 words per
sentence. That is the choppiness he objected to. Do not repeat it.

## Sentences

- **Rhythm.** A long sentence (30–50 words) carries the setup or mechanism.
  Two or three shorter ones (8–20 words) land the point, and the shortest
  is usually the verdict: "That decision itself has not been written down."
  In Introduction, Results, and Discussion, aim for a median of 21–25 words,
  a 90th percentile of 35–46, and about one comma per sentence. A paragraph
  median under 20 words reads as choppy.
- **Join related clauses** with *because, which, while, whereas, so, but*,
  and above all *rather than*, his signature contrast. Do not split a
  sentence just because it has two clauses. Split it when the reader must
  hold several qualifications before reaching the verb, or when three or
  more clauses are spliced with commas or semicolons.
- **One semicolon** joining two closely related clauses is fine; his Results
  use one in about every ten sentences. A chain of them is not.
- **Colons** expand a general statement into its concrete content ("a
  linear utility forced the optimum to a corner: the entire budget went to
  the single most profitable substrate"). They also pose a question. Every
  display equation gets a colon lead-in with a short connector ("is given
  by:", "of the form:").
- **Name every symbol** at its first use in each sentence: "dealer depth
  $h=100$", "fraction $f=0.20$", "grid size $L=32$", never a bare "$h=100$".
  Later values in the same sentence may stay bare ("at dealer depth
  $h=0.1$, 99.52\% at $h=1$, and ..."). This is the author's request of
  23 September.
- **Plain words; name the referent.** Write "the dealer's quoted price", not
  "that price". Gloss a technical term in apposition ("An indifference curve
  is a locus of constant utility, ..."), never with "called a". Leave
  implementation details (seeds, rounding, priorities) to the supplement.
- **Tense and person.** Findings are past tense; general mechanisms are
  present. "We" does what the authors did or asked (*solved, compared,
  asked whether, found*). Findings take the system as subject ("A Sell
  majority formed ..."). Never "we believe" or "we argue"; no "I".
- **Never.** Em dashes. *Notably, Importantly, Interestingly, Moreover,
  Furthermore, Additionally, Indeed, Crucially.* Unmeasured evaluative
  words: *significant* (without a test), *novel, robust, dramatic, clearly,
  very, powerful, remarkable*. Roadmap sentences, "Note that", sentences
  that start with And or But, and contractions.

## Paragraphs

- Introduction paragraphs run 200–400 words, Results and Discussion
  paragraphs 150–450. There are no stubs. Methods may hold shorter
  procedural paragraphs, but never one paragraph per item. Topic sentences
  do the segmenting, not blank lines.
- **Results paragraph = one experiment:**
  1. Open with a bridge or a question: "Having established X, we next asked
     whether Y", "To determine whether ..., we compared ...", or a flat
     statement about the system ("Not all sugar pairs were strictly
     ordered.").
  2. Give the procedure in one sentence.
  3. Give the numbers, with the baseline named in the same sentence.
  4. Add one mechanism sentence that explains why, built on *because* or
     *which*.
  5. Close with "Thus," or "Together," and an interpretation bounded by
     *rather than*, *not*, or the tested scope.
- **Numbers.** Make the value the predicate ("was 0.34"). Put the interval
  right after it. Write counts as "42 of 50 markets", and spell out a count
  that starts a sentence. Name no more than three numbers in a row; the
  rest belong in the table. Figures and tables are parenthetical at the end
  of the claim, never the subject.
- **Bounded claims.** "X, not Y". "did not establish". "was consistent
  with". Qualifications sit beside the claim they limit. Avoid a
  boilerplate disclaimer on every paragraph.

## Sections

- **Introduction.** At most four paragraphs, wide to narrow. The first
  opens on context (history, the field's goal, a dated fact), not on this
  paper, and ends on the gap stated as a need. The middle names the
  specific prior work and the exact open question. The last begins "In
  this study, we", stays in past tense, runs mechanism → what we did, and
  contains no numbers or figure references. It ends by saying how the study
  addressed its aim, with one big-picture sentence on why that matters.
- **Results.** No subsections. One paragraph per experiment; the last may
  open "Finally,".
- **Discussion.** The first paragraph opens "In this study, we explored
  how ..." (the author's wording, 23 September; not "We asked ..."
  followed by "The answer had two parts") and answers in past tense. Each later paragraph opens by naming the question it
  answers. State limitations as concrete things not done, with the
  consequence: "We did not test X, so Y." Some carry a remedy and its cost.
  End on a limitation plus a horizon clause, or an "X, not Y" statement,
  never on a grand claim.
- **Conclusion.** One paragraph, with no "we", citations, or figures.

## Exemplars (verbatim)

*Framing.* "Catabolite repression is nonetheless only a proximate
explanation, describing the molecular machinery that implements sequential
substrate consumption without explaining why sequential consumption is the
strategy a cell should adopt in the first place." (2607.07677 intro)

*Gap as a verdict.* "Thus, the matching rule has remained a control
heuristic with proven optimality properties rather than the solution of a
stated economic decision. That decision itself has not been written down."
(2607.07677 intro)

*Purpose from a limitation.* "Marginal agreement alone could result from
profiles that closely copied stored records, so we also quantified
similarity to stored profiles with two metrics (Table~\ref{...})."
(2604.07557 results)

*Bridge opener.* "Having characterized how SA self-tunes in isolation, we
next compared it against three established learned baselines ..."
(2603.14717 results)

*Result with a named baseline.* "On a log cellmass scale the LP fit gave
RMSE = 0.0421 and $R^{2}$ = 0.9974, comparable to the classical cybernetic
matching law (RMSE = 0.0461, $R^{2}$ = 0.9969) on the same trajectory
(Fig.~\ref{...}A)." (2607.07677 results)

*Number, then verdict.* "The fitted slope, however, was smaller than
geometry alone predicts: $0.28$, against the ${\approx}1.6$ expected for
random patterns under a Gaussian random-score model. That gap is a
signature of real sequence structure." (2603.14717 results)

*Result, then plain consequence.* "Under the hard mask, P1~K/R was only
0.50 at its operating point, $\beta^{*}=3.23$, and reached 1.00 only near
$\beta/\beta^{*}\approx160$. Complete recovery therefore takes a sampler
running two orders of magnitude sharper than its own operating point."
(2603.20115 results)

*Mechanism.* "These step functions indicated that the sequence of diauxic
growth followed from the geometry of the LP rather than from an explicit
regulatory rule." (2607.07677 results)

*Closers.* "Thus, diauxie was a property of the resource-allocation
decision rather than of the activity gating." (2607.07677) / "Together,
these experiments showed that sharper retrieval can compensate for
latent-to-sequence loss, but only by sacrificing novelty." (2603.20115)

*Limitations.* "The decisive computational control, folding the
consensus-with-noise ensemble through the same structure predictors, was
not performed here and remains for future work." (2603.14717) / "We
therefore do not recommend using these cohorts to estimate extreme risk
without additional real data." (2604.07557) / "The results establish
proof of concept, not generalizability." (2604.07557)

*His own corrections on this paper.* "The grid specifies who can influence
whom. The decision rule specifies how each trader responds." became "The
arrangement specifies who can influence whom, while the decision rule
specifies how each trader responds." Likewise, "Their subsequent
intentions and completed trades could differ as the populations followed
their assigned decision rules." became "The traders could then make
different decisions and complete different trades."

## Workflow

The unit of review is a section. Draft the whole section against this
guide, run `python3 paper-arxiv/voice_check.py <files>`, and give the author
a latexdiff PDF to mark up once. Apply all of the markup together. Then run
one build and one read-only technical check of the claims that changed, and
log one line. New experiments or claims wait on a parking list until the
voice pass is done. Archive packaging, page renders, and PDF hashes happen
once, at release.
