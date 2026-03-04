# Peek All Intervals Overlapping a Query Interval

Peek All Intervals Overlapping a Query Interval

## Usage

``` r
peek_all_overlaps(x, start, end, bounds = NULL)
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
ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
as.list(peek_all_overlaps(ix, 2, 5))
#> [[1]]
#> [1] "b"
#> 
```
