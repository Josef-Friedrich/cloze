## Description

EN: `cloze` is a LuaLaTeX/LaTeX package to generate cloze. It uses the
capabilities of the modern TeX engine LuaTex.

DE: `cloze` ist a LuaLaTeX/LaTeX-Paket zum Erstellen von Lückentexten.
Es nutzt die Möglichkeiten der modernen TeX-Engine LuaTeX.

## License

Copyright (C) 2015-2025 by Josef Friedrich <josef@friedrich.rocks>
------------------------------------------------------------------------
This work may be distributed and/or modified under the conditions of
the LaTeX Project Public License, either version 1.3c of this license
or (at your option) any later version.  The latest version of this
license is in:

  http://www.latex-project.org/lppl.txt

and version 1.3c or later is part of all distributions of LaTeX
version 2008/05/04 or later.

## Packaging

### CTAN

The `cloze` package has been included in the Comprehensive TeX Archive
Network (CTAN) since July 2015.

* [TeX archive](https://mirrors.ctan.org/macros/luatex/generic/cloze/)
* [Package page](https://www.ctan.org/pkg/cloze)

### Distributions

* TeX Live:
  * run files:
    * [scripts/cloze/cloze.lua](https://tug.org/svn/texlive/trunk/Master/texmf-dist/scripts/cloze/cloze.lua)
    * [tex/luatex/cloze/cloze.tex](https://tug.org/svn/texlive/trunk/Master/texmf-dist/tex/luatex/cloze/cloze.tex)
    * [tex/luatex/cloze/cloze.sty](https://tug.org/svn/texlive/trunk/Master/texmf-dist/tex/luatex/cloze/cloze.sty)
  * doc files:
    * [tex/luatex/cloze/cloze-doc.tex](https://tug.org/svn/texlive/trunk/Master/texmf-dist/tex/luatex/cloze/cloze-doc.tex) texmf-dist/tex/luatex/cloze/cloze-doc.tex
    * [doc/luatex/cloze/cloze-doc.pdf](https://tug.org/svn/texlive/trunk/Master/texmf-dist/doc/luatex/cloze/cloze-doc.pdf) texmf-dist/doc/luatex/cloze/cloze-doc.pdf
    * [doc/luatex/cloze/README.md](https://tug.org/svn/texlive/trunk/Master/texmf-dist/doc/luatex/cloze/README.md)
* [MiKTeX](https://miktex.org/packages/cloze)

### Repository

The [Git repository](https://github.com/Josef-Friedrich/cloze) in
which the development takes place is hosted on
[GitHub](https://github.com).

## Documentation

* [User documentation as a PDF](https://ctan.net/macros/luatex/generic/cloze/cloze-doc.pdf)

## Installation

### TeX Live

    tlmgr install cloze

### Manually

    git clone git@github.com:Josef-Friedrich/cloze.git
    cd cloze
    make install
