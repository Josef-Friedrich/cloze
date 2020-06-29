jobname = cloze
texmf = $(HOME)/texmf
texmftex = $(texmf)/tex/lualatex
installdir = $(texmftex)/$(jobname)

all: install doc

install:
	luatex $(jobname).ins
	mkdir -p $(installdir)
	cp -f $(jobname).tex $(installdir)
	cp -f $(jobname).sty $(installdir)
	cp -f $(jobname).lua $(installdir)
	./clean.sh install

doc: doc_pdf doc_lua

doc_pdf:
	lualatex --shell-escape documentation.tex
	makeindex -s gglo.ist -o documentation.gls documentation.glo
	makeindex -s gind.ist -o documentation.ind documentation.idx
	lualatex --shell-escape documentation.tex
	mkdir -p $(texmf)/doc
	mv documentation.pdf cloze.pdf
	cp $(jobname).pdf $(texmf)/doc

doc_lua:
	ldoc .

test: test_luatex test_lualatex

test_luatex:
	find tests/luatex -name "*.tex" -exec latexmk -latex=luatex -cd {} \;
	pdftk tests/luatex/*.pdf cat output tests-luatex.pdf
	xdg-open tests-luatex.pdf > /dev/null 2>&1 &

test_lualatex:
	find tests/lualatex -name "*.tex" -exec latexmk -latex=lualatex -cd {} \;

clean:
	./clean.sh

ctan:
	rm -rf $(jobname)
	mkdir $(jobname)
	cp -f README.md $(jobname)/
	rm -f $(jobname)/README.md.bak
	cp -f $(jobname).ins $(jobname)/
	cp -f $(jobname).dtx $(jobname)/
	cp -f $(jobname).lua $(jobname)/
	cp -f $(jobname).pdf $(jobname)/
	tar cvfz $(jobname).tar.gz $(jobname)
	rm -rf $(jobname)

.PHONY: all install doc doc_pdf doc_lua test test_luatex test_lualatex clean ctan
