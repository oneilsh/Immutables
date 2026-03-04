# Peek All Intervals Containing a Query Interval

Peek All Intervals Containing a Query Interval

## Usage

``` r
peek_all_containing(x, start, end, bounds = NULL)
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

An `interval_index` slice of all matches (possibly empty).

## Details

The returned `interval_index` can be inspected with
[`as.list()`](https://rdrr.io/r/base/list.html).

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
