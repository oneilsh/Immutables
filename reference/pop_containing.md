# Pop First Containing Interval

Pop First Containing Interval

## Usage

``` r
pop_containing(x, start, end, bounds = NULL)
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
[`pop_all_containing()`](https://oneilsh.github.io/immutables/reference/pop_all_containing.md)
to remove all matches.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(6, 3, 7))
pop_containing(ix, 2, 4)
#> $value
#> [1] "a"
#> 
#> $start
#> [1] 1
#> 
#> $end
#> [1] 6
#> 
#> $remaining
#> Unnamed interval_index with 2 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval [2, 3))
#> [1] "b"
#> 
#> [[2]] (interval [4, 7))
#> [1] "c"
#> 
#> 
```
