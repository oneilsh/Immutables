# Construct an Interval Index

Convenience constructor from `...`, `start`, and `end`.

## Usage

``` r
interval_index(..., start, end, default_query_bounds = "[)")
```

## Arguments

- ...:

  Elements to add.

- start:

  Start endpoints matching `...`.

- end:

  End endpoints matching `...`.

- default_query_bounds:

  Boundary convention used as the default for query operations on this
  index: one of `"[)"`, `"[]"`, `"()"`, `"(]"`. Per-query `peek_*` /
  `pop_*` calls may override via their own `bounds` argument.

## Value

An `interval_index`.

## Details

Empty construction is supported: `interval_index()` returns an empty
index.

Output is ordered by interval `start`.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 2, 2), end = c(3, 2, 4))
ix
#> Unnamed interval_index with 3 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "a"
#> 
#> [[2]] (interval 2 - 2)
#> [1] "b"
#> 
#> [[3]] (interval 2 - 4)
#> [1] "c"
#> 

interval_index()
#> Unnamed interval_index with 0 elements, default query bounds [start, end).
```
