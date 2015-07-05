all:
	luatex cloze.ins
	lualatex cloze.dtx
	makeindex -s gglo.ist -o cloze.gls cloze.glo
	makeindex -s gind.ist -o cloze.ind cloze.idx
	lualatex cloze.dtx

clean:
	./.githook_pre-commit

ctan:
	rm -rf cloze
	mkdir cloze
	cp -f README.md cloze/README
	cp -f cloze.ins cloze/
	cp -f cloze.dtx cloze/
	cp -f cloze.sty cloze/
	cp -f cloze.lua cloze/
	cp -f cloze.pdf cloze/
	tar cvfz cloze.tar.gz cloze
	rm -rf cloze

.PHONY: all clean ctan
