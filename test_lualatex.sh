#! /bin/sh

make install

lualatex tests/lualatex/$1.tex

xdg-open $1.pdf > /dev/null 2>&1
