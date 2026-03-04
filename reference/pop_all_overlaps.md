# Pop All Overlapping Intervals

Pop All Overlapping Intervals

## Usage

``` r
pop_all_overlaps(x, start, end, bounds = NULL)
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

A list with `elements` and `remaining`, both `interval_index` objects.

## Details

Use [`as.list()`](https://rdrr.io/r/base/list.html) to convert
`elements` to a standard R list.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
out <- pop_all_overlaps(ix, 2, 5)
as.list(out$elements)
#> [[1]]
#> [1] "b"
#> 
```
