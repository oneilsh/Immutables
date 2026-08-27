# Peek All Intervals Containing a Query Interval

Peek All Intervals Containing a Query Interval

## Usage

``` r
peek_all_containing(x, start, end, bounds = NULL, as_list = FALSE)
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
ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(6, 5, 7))
as.list(peek_all_containing(ix, 2, 4))
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
```
