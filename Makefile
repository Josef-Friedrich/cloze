all:
	luatex cloze.ins
	lualatex cloze.dtx

test:
	lualatex tests/all-modes.tex
	lualatex tests/cloze.tex
	lualatex tests/clozefil.tex
	lualatex tests/clozefix.tex
	lualatex tests/clozefix_hide.tex
	lualatex tests/clozelinefil.tex
	lualatex tests/clozepar.tex
	lualatex tests/hide-text.tex
	lualatex tests/options.tex
	lualatex tests/show-text.tex

.PHONY: all test
