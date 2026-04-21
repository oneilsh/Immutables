# Build an Interval Index from `x`, `start`, and `end`

Constructs an `interval_index` by pairing each element of `x` with
corresponding `start` and `end` endpoints.

## Usage

``` r
as_interval_index(x, start, end, default_query_bounds = "[)")
```

## Arguments

- x:

  Elements to add.

- start:

  Start endpoints with the same length as `x`.

- end:

  End endpoints with the same length as `x`.

- default_query_bounds:

  Boundary convention used as the default for query operations on this
  index: one of `"[)"`, `"[]"`, `"()"`, `"(]"`. Per-query `peek_*` /
  `pop_*` calls may override via their own `bounds` argument.

## Value

An `interval_index`.

## Details

Output is ordered by interval `start`.

Names on `x` are preserved as element names.

## Examples

``` r
ix <- as_interval_index(c("a", "b", "c"), start = c(1, 2, 2), end = c(3, 2, 4))
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
as.list(peek_all_point(ix, 2))
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "c"
#> 

# Endpoints can be other comparable types
ix_date <- as_interval_index(
  c("phase1", "phase2"),
  start = as.Date(c("2024-01-01", "2024-01-10")),
  end = as.Date(c("2024-01-05", "2024-01-15"))
)
ix_date
#> Unnamed interval_index with 2 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 2024-01-01 - 2024-01-05)
#> [1] "phase1"
#> 
#> [[2]] (interval 2024-01-10 - 2024-01-15)
#> [1] "phase2"
#> 
```
