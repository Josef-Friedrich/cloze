# Description

EN: `cloze` is a LaTeX package to generate cloze. It uses the
capabilities of the modern TeX engine LuaTex.

DE: `cloze` ist a LaTeX-Paket zum Erstellen von Lückentexten. Es
nutzt die Möglichkeiten der modernen TeX-Engine LuaTeX.

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

