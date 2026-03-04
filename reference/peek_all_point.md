# Peek All Intervals Containing a Point

Peek All Intervals Containing a Point

## Usage

``` r
peek_all_point(x, point, bounds = NULL)
```

## Arguments

- x:

  An `interval_index`.

- point:

  Query point.

- bounds:

  Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.

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
```
