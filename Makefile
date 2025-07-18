jobname = cloze
texmf = $(HOME)/texmf
texmftex = $(texmf)/tex/luatex
installdir = $(texmftex)/$(jobname)
googlefonts = https://raw.githubusercontent.com/google/fonts/refs/heads/main

all: install doc

install:
	-tlmgr remove --force cloze
	rm -rf $(texmf)/tex/lualatex/$(jobname)
	mkdir -p $(installdir)
	cp -f $(jobname).tex $(installdir)
	cp -f $(jobname).sty $(installdir)
	cp -f $(jobname).lua $(installdir)
	cp -f $(jobname)-test.tex $(installdir)
	cp -f $(jobname)-test.sty $(installdir)
	cp -f $(jobname)-test.lua $(installdir)

doc: doc_pdf

doc_pdf:
	lualatex --shell-escape $(jobname)-doc.tex
	makeindex -s gglo.ist -o $(jobname)-doc.gls $(jobname)-doc.glo
	makeindex -s gind.ist -o $(jobname)-doc.ind $(jobname)-doc.idx
	lualatex --shell-escape $(jobname)-doc.tex
	mkdir -p $(texmf)/doc
	cp $(jobname)-doc.pdf $(texmf)/doc/$(jobname).pdf

test: install test_luatex_without_open test_lualatex_without_open doc_pdf
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
	git clean -d -x --force

debug: install
	lualatex -cd tests/lualatex/environment_clozebox.tex

ctan: doc_pdf
	rm -rf $(jobname)
	mkdir $(jobname)
	cp -f README.md $(jobname)/
	cp -f $(jobname).tex $(jobname)/
	cp -f $(jobname).sty $(jobname)/
	cp -f $(jobname).lua $(jobname)/
	cp -f $(jobname)-doc.pdf $(jobname)/
	cp -f $(jobname)-doc.tex $(jobname)/
	tar cvfz $(jobname).tar.gz $(jobname)
	rm -rf $(jobname)

download_google_fonts:
	mkdir -p $(HOME)/.local/share/fonts/google-fonts
	cd $(HOME)/.local/share/fonts/google-fonts
	curl --output-dir $(HOME)/.local/share/fonts/google-fonts -O $(googlefonts)/ofl/oregano/Oregano-Regular.ttf
	curl --output-dir $(HOME)/.local/share/fonts/google-fonts -O $(googlefonts)/ofl/mali/Mali-Regular.ttf
	curl --output-dir $(HOME)/.local/share/fonts/google-fonts -O "$(googlefonts)/ofl/gluten/Gluten%5Bslnt%2Cwght%5D.ttf"
	curl --output-dir $(HOME)/.local/share/fonts/google-fonts -O $(googlefonts)/apache/comingsoon/ComingSoon-Regular.ttf
	curl --output-dir $(HOME)/.local/share/fonts/google-fonts -O $(googlefonts)/ofl/kalam/Kalam-Regular.ttf

.PHONY: all install doc doc_pdf doc_lua test test_luatex test_lualatex clean ctan download_google_fonts
