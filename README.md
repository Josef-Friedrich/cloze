# Description

EN: `cloze` is a LuaLaTeX/LaTeX package to generate cloze. It uses the
capabilities of the modern TeX engine LuaTex.

DE: `cloze` ist a LuaLaTeX/LaTeX-Paket zum Erstellen von Lückentexten.
Es nutzt die Möglichkeiten der modernen TeX-Engine LuaTeX.

# License

Copyright (C) 2015-2025 by Josef Friedrich <josef@friedrich.rocks>
------------------------------------------------------------------------
This work may be distributed and/or modified under the conditions of
the LaTeX Project Public License, either version 1.3c of this license
or (at your option) any later version.  The latest version of this
license is in:

  http://www.latex-project.org/lppl.txt

and version 1.3c or later is part of all distributions of LaTeX
version 2008/05/04 or later.

# CTAN

Since July 2015 the cloze package is included in the Comprehensive TeX
Archive Network (CTAN).

* TeX archive: http://mirror.ctan.org/tex-archive/macros/luatex/generic/cloze
* Package page: https://www.ctan.org/pkg/cloze

# Distributions

* MiKTeX: https://miktex.org/packages/cloze
* TeX Live:
  * run files:
    * [cloze.lua](https://tug.org/svn/texlive/trunk/Master/texmf-dist/scripts/cloze/cloze.lua) texmf-dist/scripts/cloze/cloze.lua
    * [cloze.tex](https://tug.org/svn/texlive/trunk/Master/texmf-dist/tex/luatex/cloze/cloze.tex) texmf-dist/tex/luatex/cloze/cloze.tex
    * [cloze.sty](https://tug.org/svn/texlive/trunk/Master/texmf-dist/tex/luatex/cloze/cloze.sty) texmf-dist/tex/luatex/cloze/cloze.sty
  * doc files:
    * [cloze-doc.tex](https://tug.org/svn/texlive/trunk/Master/texmf-dist/tex/luatex/cloze/cloze-doc.tex) texmf-dist/tex/luatex/cloze/cloze-doc.tex
    * [cloze-doc.pdf](https://tug.org/svn/texlive/trunk/Master/texmf-dist/doc/luatex/cloze/cloze-doc.pdf) texmf-dist/doc/luatex/cloze/cloze-doc.pdf
    * [README.md](https://tug.org/svn/texlive/trunk/Master/texmf-dist/doc/luatex/cloze/README.md) texmf-dist/doc/luatex/cloze/README.md

# Repository

https://github.com/Josef-Friedrich/cloze

# Documentation

* [User documentation as a PDF](https://ctan.net/macros/luatex/generic/cloze/cloze-doc.pdf)

# Installation

## TeX Live

    tlmgr install cloze

## Manually

    git clone git@github.com:Josef-Friedrich/cloze.git
    cd cloze
    make install
