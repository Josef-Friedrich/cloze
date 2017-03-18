#!/ usr/bin/env texlua
-- Build script for abc package
module = "abc"

stdengine = "lualatex"

-- variable overwrites (if needed)
-- call standard script
kpse.set_program_name ("kpsewhich")
dofile (kpse.lookup ("l3build.lua"))