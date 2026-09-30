.PHONY: all clean
all:
	mkdir -p build/description build/pitch output/pdf
	cd project-description-doc && latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=../build/description project-description.tex
	cd pitch-slide && latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=../build/pitch inventory-pitch.tex
	cp build/description/project-description.pdf output/pdf/inventory-project-description.pdf
	cp build/pitch/inventory-pitch.pdf output/pdf/inventory-pitch.pdf

clean:
	latexmk -C -outdir=build/description project-description-doc/project-description.tex
	latexmk -C -outdir=build/pitch pitch-slide/inventory-pitch.tex
