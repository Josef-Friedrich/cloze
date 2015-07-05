all:
	luatex cloze.ins
	lualatex cloze.dtx
	makeindex -s gglo.ist -o cloze.gls cloze.glo
	makeindex -s gind.ist -o cloze.ind cloze.idx
	lualatex cloze.dtx

clean:
	./.githook_pre-commit

ctan:
	mkdir cloze
	cp -f README.md cloze/README
	cp -f cloze.ins cloze/
	cp -f cloze.dtx cloze/
	cp -f cloze.sty cloze/
	cp -f cloze.lua cloze/
	tar cvfz cloze.tar.gz cloze

.PHONY: all clean ctan
