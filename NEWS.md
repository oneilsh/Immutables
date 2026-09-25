# Immutables 1.2.0

## Deprecated

* `peek_overlaps()`, `peek_all_overlaps()`, `pop_overlaps()`, and
  `pop_all_overlaps()` are renamed to `peek_overlapping()`,
  `peek_all_overlapping()`, `pop_overlapping()`, and `pop_all_overlapping()`.
  The new names match `peek_containing()` and make clear that the non-`all`
  versions return a single match. The old names still work but emit a
  deprecation warning, and will be removed in a future release.

## New features

* `pop_front()`, `pop_back()`, and `pop_at()` on an `ordered_sequence` now
  return the popped element's `key` alongside `value` and `remaining` (`NULL`
  on a miss), matching `pop_key()`, `pop_min()`, and the interval `pop_*`
  helpers. Plain `flexseq` pops are unchanged.
* New `key_at()` reads the key of an `ordered_sequence` element at a given
  one-based position without removing it (the positional companion to
  `peek_at()`, and the general form of `min_key()` / `max_key()`).
* New `nearest_key()` returns the existing key closest to a query key, composing
  with `peek_key()` / `pop_key()`. It resolves by order alone at the extremes and
  on an exact hit (any key type), and uses `abs(query - key)` when the query
  falls strictly between two distinct keys (numeric/Date/POSIXct). The `ties`
  argument resolves an equidistant tie between two distinct keys: `"lower"`
  (default), `"upper"`, or `"both"` (returns both keys). It errors for
  non-subtractable keys (e.g. `character`) in that between case, where "closer"
  is undefined.

## Performance

* `ordered_sequence` key-boundary lookups now use a native C++ descent for
  `numeric`, `character`, and `logical` keys, speeding up `lower_bound()`,
  `upper_bound()`, `peek_key()`, `pop_key()`, `peek_all_key()`, `pop_all_key()`,
  `count_key()`, `elements_between()`, and `count_between()`.
* The implementation now uses lazy evaluation matching the Hinze and Paterson
  reference implementation, making amortized-constant-time end access
  claims true when structures are used in a persistent setting.

## Documentation and fixes

* Minor documentation improvements
* Trimming of unit tests to speed check times on CRAN machines

# Immutables 1.1.0

## New features

* `interval_index` queries and removals now run through a native C++ engine,
  yielding large speedups.
* Interval endpoints now use the same native query fast path as other structures 
  for `character`, `Date`, or `POSIXct` (in addition to numeric and integer) endpoints.

## Documentation and fixes

* Corrected the documented return field of the interval `pop_*` functions to
  `$value`
* Clarified that `peek_point()` and the other "first match" interval queries
  return the match in canonical interval order: smallest start, with
  insertion/FIFO order breaking ties.
* Hardened the pure-R reference tree builder against C-stack overflow when
  constructing very large structures, by replacing a deep recursion in the bulk
  builder with iterative node grouping.
* Reworking benchmarks vignette in preparation for publication.

# Immutables 1.0.1

* CRAN resubmission. Addresses reviewer feedback:
    * Added a reference to Hinze and Paterson (2006) <doi:10.1017/S0956796805005769> in DESCRIPTION.
    * Added missing `\value` tag for `print.flexseq()`.
    * Removed `\dontrun{}` example wrappers from internal helpers.
* Removed the `plot()` in favor of `plot_structure()` as part of the developer API.
* Added `inst/CITATION` with a Zenodo DOI for the package.

# Immutables 1.0.0

* First CRAN submission.
* `flexseq`s: list-like sequences with push/pop/peek from either end, indexed and named access, insertion, splitting, and concatenation.
* `priority_queue`s, `ordered_sequence`s, `interval_index`es: finger-tree-backed structures for min/max-by-priority, sorted-by-key, and interval-overlap queries.
* Developer API for building custom structures via monoid/measure combinations.
* Core operations implemented in C++ via Rcpp, with matching pure-R reference implementations using `lambda.r`.
