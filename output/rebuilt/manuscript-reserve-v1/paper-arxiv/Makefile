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

pdf:
	latexmk -pdf -interaction=nonstopmode -halt-on-error $(JOB).tex

watch:
	latexmk -pdf -pvc -interaction=nonstopmode $(JOB).tex

clean:
	latexmk -c $(JOB).tex

distclean:
	latexmk -C $(JOB).tex
