# Build the paper and refresh bibliography and cross-references.
# latexmk owns the dependency tracking (reruns pdflatex/bibtex as needed),
# so the pdf target always delegates to it; a no-op rebuild is fast.
#
# Usage:
#   make                 build Paper_v1.pdf
#   make JOB=<name>      build <name>.pdf instead
#   make watch           rebuild continuously on file changes
#   make clean           remove aux files (keeps the PDF)
#   make distclean       remove aux files and the PDF

JOB ?= Paper_v1

.PHONY: all pdf watch clean distclean

all: pdf

pdf: figs/Fig1-RuleQuench.pdf
	latexmk -pdf -interaction=nonstopmode -halt-on-error $(JOB).tex

figs/Fig1-RuleQuench.pdf: figures/Fig1-RuleComparison.tex ../code/rebuild/RenderRuleFigure.py ../code/figs/Fig1-PairedMarkets.pdf
	python3 ../code/rebuild/RenderRuleFigure.py

watch:
	python3 ../code/rebuild/RenderRuleFigure.py --watch --job $(JOB)

clean:
	latexmk -c $(JOB).tex

distclean:
	latexmk -C $(JOB).tex
