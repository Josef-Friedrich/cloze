# Description

EN: `cloze` is a LuaLaTeX/LaTeX package to generate cloze. It uses the
capabilities of the modern TeX engine LuaTex.

DE: `cloze` ist a LuaLaTeX/LaTeX-Paket zum Erstellen von Lückentexten.
Es nutzt die Möglichkeiten der modernen TeX-Engine LuaTeX.

# License

Copyright (C) 2015-2020 by Josef Friedrich <josef@friedrich.rocks>
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
    lualatex --shell-escape cloze.dtx
    makeindex -s gglo.ist -o cloze.gls cloze.glo
    makeindex -s gind.ist -o cloze.ind cloze.idx
    lualatex --shell-escape cloze.dtx

# Development

First delete the stable version installed by TeX Live. Because the
package `cloze` belongs to the collection `collection-latexextra`, the
option  `--force` must be used to delete the package.

    tlmgr remove --force cloze

## Deploying a new version

Update the version number in the file `cloze.dtx` on this locations:

### In the markup for the file `cloze.sty` (approximately at the line number 30)

    %<*package>
      [2020/05/20 v1.4 Package to typeset cloze worksheets or cloze tests]
    %<*package>

Add a changes entry (approximately at the line 90):

```latex
\changes{v1.4}{2020/05/20}{...}
```

### In the package documentation `documentation.tex` (approximately at the line number 125)

```latex
\date{v1.6~from 2020/06/30}
```

### In the markup for the file `cloze.lua` (approximately at the line number 1900)

```lua
if not modules then modules = { } end modules ['cloze'] = {
  version   = '1.4'
}
```

### Update the copyright year:

```
sed -i 's/(C) 2015-2020/(C) 2015-2021/g' cloze.ins
sed -i 's/(C) 2015-2020/(C) 2015-2021/g' cloze.dtx
```

### Command line tasks:

```
git tag v1.4
make
make ctan
```
