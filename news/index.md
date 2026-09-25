# Changelog

## Immutables 1.2.0

### Deprecated

- [`peek_overlaps()`](https://oneilsh.github.io/Immutables/reference/Immutables-deprecated.md),
  [`peek_all_overlaps()`](https://oneilsh.github.io/Immutables/reference/Immutables-deprecated.md),
  [`pop_overlaps()`](https://oneilsh.github.io/Immutables/reference/Immutables-deprecated.md),
  and
  [`pop_all_overlaps()`](https://oneilsh.github.io/Immutables/reference/Immutables-deprecated.md)
  are renamed to
  [`peek_overlapping()`](https://oneilsh.github.io/Immutables/reference/peek_overlapping.md),
  [`peek_all_overlapping()`](https://oneilsh.github.io/Immutables/reference/peek_all_overlapping.md),
  [`pop_overlapping()`](https://oneilsh.github.io/Immutables/reference/pop_overlapping.md),
  and
  [`pop_all_overlapping()`](https://oneilsh.github.io/Immutables/reference/pop_all_overlapping.md).
  The new names match
  [`peek_containing()`](https://oneilsh.github.io/Immutables/reference/peek_containing.md)
  and make clear that the non-`all` versions return a single match. The
  old names still work but emit a deprecation warning, and will be
  removed in a future release.

### New features

- [`pop_front()`](https://oneilsh.github.io/Immutables/reference/pop_front.md),
  [`pop_back()`](https://oneilsh.github.io/Immutables/reference/pop_back.md),
  and
  [`pop_at()`](https://oneilsh.github.io/Immutables/reference/pop_at.md)
  on an `ordered_sequence` now return the popped element’s `key`
  alongside `value` and `remaining` (`NULL` on a miss), matching
  [`pop_key()`](https://oneilsh.github.io/Immutables/reference/pop_key.md),
  [`pop_min()`](https://oneilsh.github.io/Immutables/reference/pop_min.md),
  and the interval `pop_*` helpers. Plain `flexseq` pops are unchanged.
- New
  [`key_at()`](https://oneilsh.github.io/Immutables/reference/key_at.md)
  reads the key of an `ordered_sequence` element at a given one-based
  position without removing it (the positional companion to
  [`peek_at()`](https://oneilsh.github.io/Immutables/reference/peek_at.md),
  and the general form of
  [`min_key()`](https://oneilsh.github.io/Immutables/reference/min_key.md)
  /
  [`max_key()`](https://oneilsh.github.io/Immutables/reference/max_key.md)).
- New
  [`nearest_key()`](https://oneilsh.github.io/Immutables/reference/nearest_key.md)
  returns the existing key closest to a query key, composing with
  [`peek_key()`](https://oneilsh.github.io/Immutables/reference/peek_key.md)
  /
  [`pop_key()`](https://oneilsh.github.io/Immutables/reference/pop_key.md).
  It resolves by order alone at the extremes and on an exact hit (any
  key type), and uses `abs(query - key)` when the query falls strictly
  between two distinct keys (numeric/Date/POSIXct). The `ties` argument
  resolves an equidistant tie between two distinct keys: `"lower"`
  (default), `"upper"`, or `"both"` (returns both keys). It errors for
  non-subtractable keys (e.g. `character`) in that between case, where
  “closer” is undefined.

### Performance

- `ordered_sequence` key-boundary lookups now use a native C++ descent
  for `numeric`, `character`, and `logical` keys, speeding up
  [`lower_bound()`](https://oneilsh.github.io/Immutables/reference/lower_bound.md),
  [`upper_bound()`](https://oneilsh.github.io/Immutables/reference/upper_bound.md),
  [`peek_key()`](https://oneilsh.github.io/Immutables/reference/peek_key.md),
  [`pop_key()`](https://oneilsh.github.io/Immutables/reference/pop_key.md),
  [`peek_all_key()`](https://oneilsh.github.io/Immutables/reference/peek_all_key.md),
  [`pop_all_key()`](https://oneilsh.github.io/Immutables/reference/pop_all_key.md),
  [`count_key()`](https://oneilsh.github.io/Immutables/reference/count_key.md),
  [`elements_between()`](https://oneilsh.github.io/Immutables/reference/elements_between.md),
  and
  [`count_between()`](https://oneilsh.github.io/Immutables/reference/count_between.md).
- The implementation now uses lazy evaluation matching the Hinze and
  Paterson reference implementation, making amortized-constant-time end
  access claims true when structures are used in a persistent setting.

### Documentation and fixes

- Minor documentation improvements
- Trimming of unit tests to speed check times on CRAN machines

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
  [`peek_point()`](https://oneilsh.github.io/Immutables/reference/peek_point.md)
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
    [`print.flexseq()`](https://oneilsh.github.io/Immutables/reference/print.flexseq.md).
  - Removed `\dontrun{}` example wrappers from internal helpers.
- Removed the [`plot()`](https://rdrr.io/r/graphics/plot.default.html)
  in favor of
  [`plot_structure()`](https://oneilsh.github.io/Immutables/reference/plot_structure.md)
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
