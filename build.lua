#!/ usr/bin/env texlua
module = "cloze"

checkengines = {"lualatex"}
stdengine = "lualatex"

kpse.set_program_name ("kpsewhich")
dofile (kpse.lookup ("l3build.lua"))