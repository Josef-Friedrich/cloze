# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- ...

### Changed

- ...

### Deprecated

- ...

### Removed

- ...

### Fixed

- ...

### Security

- ...

## [v0.1] - 2015/06/16

Converted to DTX file}

## [v1.0] - 2015/07/08

Inital release}

## [v1.1] - 2016/06/13

Make cloze compatible to LuaTeX version
0.95}

## [v1.2] - 2016/06/23

The cloze makros are now working in
tabular, tabbing and picture environments}

## [v1.3] - 2017/03/13

Add the new macros \cmd{\clozenol} and
\cmd{\clozeextend} and the environments \texttt{clozebox} and
\texttt{clozespace} (This version was not published on CTAN.)}

## [v1.4] - 2020/05/20

Add the new macro \cmd{\clozestrike} and
improve the documentation}

## [v1.5] - 2020/05/27


* The Lua part of the package (cloze.lua) is now being developed in a
separate file.
* The readme file is now a standalone mardown file and not embedded in
the dtx file any more.
* \href{https://github.com/stevedonovan/LDoc}{LDoc} is being used
to generate
\href{https://josef-friedrich.github.io/cloze}{source code documentation}.
* This version fixes two bugs (cloze in display math, line color and
hide).
}

## [v1.6] - 2020/06/30


* Implement basic plain \TeX{} respectively plain Lua\TeX{} interface.
* Fix issue: Duplicate line generation on the second line in cloze.
* Fix issue: width of first line wrong in itemize, mdframed.
* Fix issue \#4: \texttt{\string\clozenol} not transparent.
* Fix issue: \texttt{clozebox} not transparent.
}
