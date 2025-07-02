# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-06-29

### Changed

- `LuaLaTeX`: commands are now defined with `\NewDocumentCommand` or
  `\NewDocumentEnvironment` instead of `\newcommand` or
  `\newenvironment`.
- Remove dependency of [xcolor](https://www.ctan.org/pkg/xcolor).

### Added

- `oarg` (optional argument) support for the plain `LuaTeX` commands.
- option `font`

### Removed

- `\clozesetoption` and `\clozesetlocaloption`

## [1.8.1] - 2025-06-17

### Added

- Add option `log`

### Changed

- Implement `\clozestrike` in Lua without LaTeX packages

### Removed

- Dependency to the packages [stackengine](https://www.ctan.org/pkg/stackengine), [ulem](https://www.ctan.org/pkg/ulem) and [transparent](https://www.ctan.org/pkg/transparent)

## [1.8.0] - 2025-06-11

### Added

- Add an option to enlarge gaps by a `spread` factor #1

### Fixed

- Local option handling #5

## [1.7.0] - 2025-06-06

### Added

- New options: `extension_count`, `extension_width`, `extension_height`
- Options can be written with underscores: `box_height`, `box_rule`, `box_width`.
- Debug informations can be enabled using the debug `option`.

### Fixed

- Fix color changes to black after cloze command #9
- Fix old font commands error #15

## [1.6] - 2020-06-30

### Added

- Implement basic plain `TeX` respectively plain `LuaTeX` interface.

### Fixed

- Fix duplicate line generation on the second line in cloze.
- Fix width of first line wrong in itemize, mdframed.
- Fix `\clozenol` not transparent #4
- Fix `clozebox` not transparent.

## [1.5] - 2020-05-27

### Changed

- The Lua part of the package (cloze.lua) is now being developed in a
  separate file.
- The readme file is now a standalone mardown file and not embedded in
  the dtx file any more.
- [LDoc](https://github.com/stevedonovan/LDoc) is being used
  to generate the
  [source code documentation](https://josef-friedrich.github.io/cloze).

### Fixed

- Fix two bugs (cloze in display math, line color and
  hide).

## [1.4] - 2020-05-20

### Added

- Add the new macro `\clozestrike`

### Changed

- Improve the documentation

## [1.3] - 2017-03-13

### Added

- Add the new macros `\clozenol` and `\clozeextend` and the
  environments `clozebox` and `clozespace`
  (This version was not published on CTAN.)

## [1.2] - 2016-06-23

### Fixed

- The cloze makros are now working in tabular, tabbing and picture
  environments

## [1.1] - 2016-06-13

### Fixed

- Make cloze compatible to `LuaTeX` version 0.95

## [1.0] - 2015-07-08

### Added

- Inital release

## [0.1] - 2015-06-16

### Changed

- Converted to DTX file

[2.0.0]: https://github.com/Josef-Friedrich/cloze/compare/v1.8.1..v2.0.0
[1.8.1]: https://github.com/Josef-Friedrich/cloze/compare/v1.8.0..v1.8.1
[1.8.0]: https://github.com/Josef-Friedrich/cloze/compare/v1.7.0..v1.8.0
[1.7.0]: https://github.com/Josef-Friedrich/cloze/compare/v1.6..v1.7.0
[1.6]: https://github.com/Josef-Friedrich/cloze/compare/v1.5..v1.6
[1.5]: https://github.com/Josef-Friedrich/cloze/compare/v1.4..v1.5
[1.4]: https://github.com/Josef-Friedrich/cloze/compare/v1.3..v1.4
[1.3]: https://github.com/Josef-Friedrich/cloze/compare/v1.2..v1.3
[1.2]: https://github.com/Josef-Friedrich/cloze/compare/v1.1..v1.2
[1.1]: https://github.com/Josef-Friedrich/cloze/compare/v1.0..v1.1
[1.0]: https://github.com/Josef-Friedrich/cloze/compare/v0.1..v1.0
