# Changelog

## Immutables 1.1.0

CRAN release: 2026-08-21

### New features

- `interval_index` queries and removals now run through a native C++
  engine, yielding large speedups.
- Interval endpoints now use the same native query fast path as other
  structures for `character`, `Date`, or `POSIXct` (in addition to
  numeric and integer) endpoints.

### Documentation and fixes

- Corrected the documented return field of the interval `pop_*`
  functions to `$value`
- Clarified that
  [`peek_point()`](https://oneilsh.github.io/immutables/reference/peek_point.md)
  and the other “first match” interval queries return the match in
  canonical interval order: smallest start, with insertion/FIFO order
  breaking ties.
- Hardened the pure-R reference tree builder against C-stack overflow
  when constructing very large structures, by replacing a deep recursion
  in the bulk builder with iterative node grouping.
- Reworking benchmarks vignette in preparation for publication.

## Immutables 1.0.1

CRAN release: 2026-04-28

- CRAN resubmission. Addresses reviewer feedback:
  - Added a reference to Hinze and Paterson (2006)
    <doi:10.1017/S0956796805005769> in DESCRIPTION.
  - Added missing `\value` tag for
    [`print.flexseq()`](https://oneilsh.github.io/immutables/reference/print.flexseq.md).
  - Removed `\dontrun{}` example wrappers from internal helpers.
- Removed the [`plot()`](https://rdrr.io/r/graphics/plot.default.html)
  in favor of
  [`plot_structure()`](https://oneilsh.github.io/immutables/reference/plot_structure.md)
  as part of the developer API.
- Added `inst/CITATION` with a Zenodo DOI for the package.

## Immutables 1.0.0

- First CRAN submission.
- `flexseq`s: list-like sequences with push/pop/peek from either end,
  indexed and named access, insertion, splitting, and concatenation.
- `priority_queue`s, `ordered_sequence`s, `interval_index`es:
  finger-tree-backed structures for min/max-by-priority, sorted-by-key,
  and interval-overlap queries.
- Developer API for building custom structures via monoid/measure
  combinations.
- Core operations implemented in C++ via Rcpp, with matching pure-R
  reference implementations using `lambda.r`.
