#! /bin/sh

make install

luatex tests/luatex/$1.tex

xdg-open $1.pdf > /dev/null 2>&1
