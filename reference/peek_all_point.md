# Peek All Intervals Matching a Point

Peek All Intervals Matching a Point

## Usage

``` r
peek_all_point(
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

An `interval_index` slice of all matches (possibly empty).

## Details

The returned `interval_index` can be inspected with
[`as.list()`](https://rdrr.io/r/base/list.html).

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(3, 2, 5))
as.list(peek_all_point(ix, 2))
#> [[1]]
#> [1] "a"
#> 

# Entries ending at 3
as.list(peek_all_point(ix, 3, match_at = "end"))
#> [[1]]
#> [1] "a"
#> 
```
