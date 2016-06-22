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

doc:
	lualatex $(jobname).dtx
	makeindex -s gglo.ist -o $(jobname).gls $(jobname).glo
	makeindex -s gind.ist -o $(jobname).ind $(jobname).idx
	lualatex $(jobname).dtx
	mkdir -p $(texmf)/doc
	cp $(jobname).pdf $(texmf)/doc

test:
	find tests -name "*.tex" -exec lualatex {} \;

clean:
	./clean.sh

ctan:
	rm -rf cloze
	mkdir cloze
	cp -f README.md cloze/README
	cp -f cloze.ins cloze/
	cp -f cloze.dtx cloze/
	cp -f cloze.pdf cloze/
	tar cvfz cloze.tar.gz cloze
	rm -rf cloze

.PHONY: all install doc clean ctan
