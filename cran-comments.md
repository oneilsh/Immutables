## Resubmission

This is a resubmission addressing the prior reviewer comments:

* Added a reference describing the methods in the package to the
  Description field of DESCRIPTION:
  Hinze and Paterson (2006) <doi:10.1017/S0956796805005769>.

* The previously flagged `plot.flexseq()`, `plot.priority_queue()`,
  `plot.ordered_sequence()`, and `plot.interval_index()` S3 methods
  have been removed, replaced with `plot_structure()` as part
  of the developer API for understanding internal structure rather
  than general-purpose plotting.

* Added the required `\value` tag to `print.flexseq()` (the remaining flagged
  method), which returns its input invisibly and is called for the
  side effect of printing to the console.

* Replaced or removed all uses of `\dontrun{}`. Public examples that
  require the suggested `igraph` package now use `\donttest{}` gated
  on `requireNamespace("igraph", quietly = TRUE)`. Examples on
  internal helpers (`@keywords internal`) were dropped entirely.

## R CMD check results

0 errors | 0 warnings | 1 note

The NOTE has/had two components:

* "New submission" is expected.
* "catenable" was previously flagged as a possibly misspelled word but is standard
  terminology in functional data structures literature.

## Test environments

- local macOS (aarch64), R 4.5.3
- win-builder R-devel (R 4.6.0 RC, x86_64-w64-mingw32)
- GitHub Actions: ubuntu-latest, macos-latest, windows-latest
