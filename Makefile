jobname = cloze
texmf = $(HOME)/texmf
texmftex = $(texmf)/tex/lualatex
installdir = $(texmftex)/$(jobname)

all: install doc

install:
	luatex $(jobname).ins
	mkdir -p $(installdir)
	cp -f $(jobname).sty $(installdir)
	cp -f $(jobname).lua $(installdir)
	./clean.sh install

doc: doc_pdf doc_lua

doc_pdf:
	lualatex --shell-escape $(jobname).dtx
	makeindex -s gglo.ist -o $(jobname).gls $(jobname).glo
	makeindex -s gind.ist -o $(jobname).ind $(jobname).idx
	lualatex --shell-escape $(jobname).dtx
	mkdir -p $(texmf)/doc
	cp $(jobname).pdf $(texmf)/doc

doc_lua:
	ldoc .

test:
	find tests -name "*.tex" -exec lualatex {} \;

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

.PHONY: all install doc doclua clean ctan
