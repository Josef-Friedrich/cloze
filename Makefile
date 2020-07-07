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

doc_lua_open:
	ldoc .
	xdg-open docs/index.html

test: test_luatex_without_open test_lualatex_without_open
	pdftk tests-luatex.pdf tests-lualatex.pdf cat output tests.pdf
	xdg-open tests.pdf > /dev/null 2>&1 &

test_luatex_without_open:
	find tests/luatex -name "*.tex" -exec latexmk -latex=luatex -cd {} \;
	pdftk tests/luatex/*.pdf cat output tests-luatex.pdf

test_luatex: test_luatex_without_open
	xdg-open tests-luatex.pdf > /dev/null 2>&1 &

test_lualatex_without_open:
	find tests/lualatex -name "*.tex" -exec latexmk -latex=lualatex -cd {} \;
	pdftk tests/lualatex/*.pdf cat output tests-lualatex.pdf

test_lualatex: test_lualatex_without_open
	xdg-open tests-lualatex.pdf > /dev/null 2>&1 &

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
