# Immutables 1.0.0

* First CRAN submission.
* `flexseq`s: list-like sequences with push/pop/peek from either end, indexed and named access, insertion, splitting, and concatenation.
* `priority_queue`s, `ordered_sequence`s, `interval_index`es: finger-tree-backed structures for min/max-by-priority, sorted-by-key, and interval-overlap queries.
* Developer API for building custom structures via monoid/measure combinations.
* Core operations implemented in C++ via Rcpp, with matching pure-R reference implementations using `lambda.r`.
