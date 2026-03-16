# Pop First Interval Containing a Point

Pop First Interval Containing a Point

## Usage

``` r
pop_point(x, point, bounds = NULL)
```

## Arguments

- x:

  An `interval_index`.

- point:

  Query point.

- bounds:

  Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.

## Value

A list with `element`, `start`, `end`, and `remaining`. On miss:
`element`, `start`, and `end` are `NULL`.

## Details

Removes the first match in canonical interval order. On miss, returns a
non-throwing miss object with `remaining = x`. Use
[`pop_all_point()`](https://oneilsh.github.io/immutables/reference/pop_all_point.md)
to remove all matches.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(3, 2, 5))
pop_point(ix, 2)
#> $value
#> [1] "a"
#> 
#> $start
#> [1] 1
#> 
#> $end
#> [1] 3
#> 
#> $remaining
#> Unnamed interval_index with 2 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval [2, 2))
#> [1] "b"
#> 
#> [[2]] (interval [4, 5))
#> [1] "c"
#> 
#> 
```
