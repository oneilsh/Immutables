# Peek All Intervals Matching a Point

Peek All Intervals Matching a Point

## Usage

``` r
peek_all_point(
  x,
  point,
  bounds = NULL,
  match_at = c("interval", "start", "end", "either"),
  as_list = FALSE
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

- as_list:

  If `TRUE`, return a list with `values` (list of payloads), `starts`,
  and `ends` parallel vectors instead of an `interval_index` slice.
  Avoids the result-tree rebuild and is significantly faster for large
  match sets when the caller doesn't need a queryable result.

## Value

When `as_list = FALSE` (default): an `interval_index` slice of all
matches (possibly empty). When `as_list = TRUE`: a named list with
`values` (list of payloads), `starts`, and `ends`. For `numeric` /
integer endpoint domains, `starts` and `ends` are atomic vectors; for
class-bearing endpoint domains (e.g. `Date`, `POSIXct`) they are
returned as lists to preserve the endpoint class.

## Details

With `as_list = FALSE`, the returned `interval_index` can be inspected
with [`as.list()`](https://rdrr.io/r/base/list.html).

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
