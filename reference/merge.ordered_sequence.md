# Merge Two Ordered Sequences

Returns a new `ordered_sequence` containing every entry from both
inputs, preserving key order. On duplicate keys, `x`'s entries precede
`y`'s (left-biased FIFO).

## Usage

``` r
# S3 method for class 'ordered_sequence'
merge(x, y, ...)
```

## Arguments

- x:

  An `ordered_sequence`.

- y:

  An `ordered_sequence`.

- ...:

  Unused.

## Value

A new `ordered_sequence` of size `length(x) + length(y)`.

## Details

The merge runs in O(m + n) via a zipper-style traversal, with a fast
path to O(log(min(m, n))) when the key ranges are disjoint (all of `x`'s
keys `<=` all of `y`'s keys, or vice versa with a strict `<` to keep
left-biased FIFO intact on equal boundary keys).

Both sequences must share the same key type and the same monoid set;
mismatches error rather than being silently harmonized. Merging an empty
sequence with a non-empty sequence returns the non-empty one unchanged.

Both inputs are left unmodified.

## Examples

``` r
a <- ordered_sequence("a1", "a2", "a3", keys = c(1, 3, 5))
b <- ordered_sequence("b1", "b2", "b3", keys = c(2, 3, 6))
m <- merge(a, b)
as.list(m)
#> [[1]]
#> [1] "a1"
#> 
#> [[2]]
#> [1] "b1"
#> 
#> [[3]]
#> [1] "a2"
#> 
#> [[4]]
#> [1] "b2"
#> 
#> [[5]]
#> [1] "a3"
#> 
#> [[6]]
#> [1] "b3"
#> 
# At the tied key 3, "a2" precedes "b2".
```
