# Pop All Intervals Containing a Point

Pop All Intervals Containing a Point

## Usage

``` r
pop_all_point(x, point, bounds = NULL)
```

## Arguments

- x:

  An `interval_index`.

- point:

  Query point.

- bounds:

  Optional boundary override. One of `"[)"`, `"[]"`, `"()"`, `"(]"`.

## Value

A list with `elements` and `remaining`, both `interval_index` objects.

## Details

Use [`as.list()`](https://rdrr.io/r/base/list.html) to convert
`elements` to a standard R list.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 2, 4), end = c(3, 2, 5))
out <- pop_all_point(ix, 2)
as.list(out$elements)
#> [[1]]
#> [1] "a"
#> 
```
