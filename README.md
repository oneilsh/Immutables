# Immutables <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- Uncomment after CRAN submission:
[![CRAN status](https://www.r-pkg.org/badges/version/Immutables)](https://CRAN.R-project.org/package=Immutables)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/Immutables)](https://CRAN.R-project.org/package=Immutables)
-->
[![Lifecycle: experimental](https://lifecycle.r-lib.org/reference/figures/lifecycle-experimental.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/oneilsh/immutables/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/oneilsh/immutables/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/oneilsh/immutables/branch/main/graph/badge.svg)](https://app.codecov.io/gh/oneilsh/immutables)
[![pkgdown](https://github.com/oneilsh/immutables/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/oneilsh/immutables/actions/workflows/pkgdown.yaml)
[![docs](https://img.shields.io/badge/docs-pkgdown-blue)](https://oneilsh.github.io/immutables/)
[![DOI](https://zenodo.org/badge/154557443.svg)](https://doi.org/10.5281/zenodo.19686096)

`Immutables` implements several immutable, or persistent, data
structures for R: operations return modified copies while remaining fast 
and true to R's side-effect-free functional nature with `list`-like semantics.


- `flexseq`s provide list-like operations:
   - indexed and named element access
   - push/pop/peek from either end for double-ended queue behavior 
   - efficient insertion, splitting, and concatenation
- `priority_queue`s associate items with priority values and provide
  min and max peek/pop by priority and fast insertion.
- `ordered_sequence`s associate items with key values and keep the elements in
  sorted order by key. These may be similarly be inserted/popped/peeked by key
  value as well as position. Keys may be duplicated, with first-in-first-out order within key groups.
- `interval_index`es store items associated with interval ranges, supporting
  point as well as interval overlaps/contains/within queries. Items are kept
  in start-order enabling ordered sequence operations and sweep-line
  algorithms.
  
## Speed and Flexibility

Backed by monoid-annotated 2-3 fingertrees as described by
[Hinze and Paterson](https://doi.org/10.1017/S0956796805005769), most 
operations are constant time, amortized constant time, or $O\(\log n\)$. 
Core functions are implemented in C++ (via Rcpp) for speed, with matching p
ure-R reference implementations using `lambda.r` syntax to match the paper.

The developer API supports the addition of custom structures via 
combinations of monoids and measures; see vignettes for details.