# Description

EN: `cloze` is a LuaLaTeX/LaTeX package to generate cloze. It uses the
capabilities of the modern TeX engine LuaTex.

DE: `cloze` ist a LuaLaTeX/LaTeX-Paket zum Erstellen von Lückentexten.
Es nutzt die Möglichkeiten der modernen TeX-Engine LuaTeX.

# License

Copyright (C) 2015 by Josef Friedrich <josef@friedrich.rocks>
------------------------------------------------------------------------
This work may be distributed and/or modified under the conditions of
the LaTeX Project Public License, either version 1.3 of this license
or (at your option) any later version.  The latest version of this
license is in:

  http://www.latex-project.org/lppl.txt

and version 1.3 or later is part of all distributions of LaTeX
version 2005/12/01 or later.

# CTAN

Since July 2015 the cloze package is included in the Comprehensive TeX
Archive Network (CTAN).

* TeX archive: http://mirror.ctan.org/tex-archive/macros/luatex/latex/cloze
* Package page: https://www.ctan.org/pkg/cloze

# Repository

https://github.com/Josef-Friedrich/cloze

# Installation

Get source:

    git clone git@github.com:Josef-Friedrich/cloze.git
    cd cloze

Compile:

    make

or manually:

    luatex cloze.ins
    lualatex cloze.dtx
    makeindex -s gglo.ist -o cloze.gls cloze.glo
    makeindex -s gind.ist -o cloze.ind cloze.idx
    lualatex cloze.dtx

# Requirements

## Tests

* forest
* pgfopts
* environ
* trimspaces
* inlinedef
