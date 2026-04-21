# Merge Two Interval Indices

Returns a new `interval_index` containing every entry from both inputs,
preserving start-position order. On tied start positions, `x`'s entries
precede `y`'s (left-biased FIFO).

## Usage

``` r
# S3 method for class 'interval_index'
merge(x, y, ...)
```

## Arguments

- x:

  An `interval_index`.

- y:

  An `interval_index`.

- ...:

  Unused.

## Value

A new `interval_index` of size `length(x) + length(y)`.

## Details

The merge runs in O(m + n) via a zipper-style traversal on interval
starts, with a fast path to O(log(min(m, n))) when the start ranges are
disjoint.

Both indices must share the same endpoint type and the same `bounds`
convention (e.g. `"[)"` half-open vs. `"[]"` closed), and the same
monoid set. Mismatches error.

The reserved monoids `.ivx_min_end` / `.ivx_max_end` recompute
automatically on the merged tree, so
[`min_endpoint()`](https://oneilsh.github.io/immutables/reference/min_endpoint.md)
/
[`max_endpoint()`](https://oneilsh.github.io/immutables/reference/max_endpoint.md)
and interval-relation queries work immediately on the result.

Both inputs are left unmodified.

## Examples

``` r
a <- interval_index("A1", "A2", start = c(1, 5), end = c(4, 8))
b <- interval_index("B1", "B2", start = c(3, 7), end = c(6, 10))
m <- merge(a, b)
as.list(m)
#> [[1]]
#> [1] "A1"
#> 
#> [[2]]
#> [1] "B1"
#> 
#> [[3]]
#> [1] "A2"
#> 
#> [[4]]
#> [1] "B2"
#> 
```
