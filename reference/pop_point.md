# Pop First Interval Matching a Point

Pop First Interval Matching a Point

## Usage

``` r
pop_point(
  x,
  point,
  bounds = NULL,
  match_at = c("interval", "start", "end", "either")
)
```

## Arguments

- x:

  An `interval_index`.

- point:

  Query point.

- bounds:

  Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.
  Ignored when `match_at` is not `"interval"`.

- match_at:

  How the query point is matched against each entry. One of `"interval"`
  (default; containment under `bounds`), `"start"`, `"end"`, or
  `"either"`. See
  [`peek_point()`](https://oneilsh.github.io/immutables/reference/peek_point.md)
  for details.

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
#> Unnamed interval_index with 2 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 2 - 2)
#> [1] "b"
#> 
#> [[2]] (interval 4 - 5)
#> [1] "c"
#> 
#> 
```
