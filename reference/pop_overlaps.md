# Pop First Overlapping Interval

Pop First Overlapping Interval

## Usage

``` r
pop_overlaps(x, start, end, bounds = NULL)
```

## Arguments

- x:

  An `interval_index`.

- start:

  Query interval start.

- end:

  Query interval end.

- bounds:

  Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.

## Value

A list with `element`, `start`, `end`, and `remaining`. On miss:
`element`, `start`, and `end` are `NULL`.

## Details

Removes the first match in canonical interval order. On miss, returns a
non-throwing miss object with `remaining = x`. Use
[`pop_all_overlaps()`](https://oneilsh.github.io/immutables/reference/pop_all_overlaps.md)
to remove all matches.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
pop_overlaps(ix, 2, 3)
#> $value
#> NULL
#> 
#> $start
#> NULL
#> 
#> $end
#> NULL
#> 
#> $remaining
#> Unnamed interval_index with 3 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval [1, 2))
#> [1] "a"
#> 
#> [[2]] (interval [3, 4))
#> [1] "b"
#> 
#> [[3]] (interval [5, 6))
#> [1] "c"
#> 
#> 
```
