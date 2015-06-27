all:
	luatex cloze.ins
	lualatex cloze.dtx
	makeindex -s gglo.ist -o cloze.gls cloze.glo
	makeindex -s gind.ist -o cloze.ind cloze.idx
	lualatex cloze.dtx

clean:
	./.githook_pre-commit

.PHONY: all clean
