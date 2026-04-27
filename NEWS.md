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
