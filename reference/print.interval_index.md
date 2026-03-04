# Print an Interval Index Summary

Prints a compact summary with interval bounds and a head/tail preview of
payload elements.

## Usage

``` r
# S3 method for class 'interval_index'
print(x, max_elements = 4L, ...)
```

## Arguments

- x:

  An `interval_index`.

- max_elements:

  Maximum number of elements shown in the preview.

- ...:

  Passed through to per-element
  [`print()`](https://rdrr.io/r/base/print.html).

## Value

Invisibly returns `x`.

## Examples

``` r
ix <- interval_index(
  one = 1, two = 2, three = 3,
  start = c(20, 30, 10), end = c(25, 37, 24)
)
print(ix, max_elements = 4)
#> Named interval_index with 3 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> $three (interval [10, 24))
#> [1] 3
#> 
#> $one (interval [20, 25))
#> [1] 1
#> 
#> $two (interval [30, 37))
#> [1] 2
#> 

ix2 <- interval_index(1, 2, 3, start = c(2, 4, 6), end = c(3, 5, 8), bounds = "[]")
print(ix2, max_elements = 3)
#> Unnamed interval_index with 3 elements, default bounds [start, end].
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval [2, 3])
#> [1] 1
#> 
#> [[2]] (interval [4, 5])
#> [1] 2
#> 
#> [[3]] (interval [6, 8])
#> [1] 3
#> 

print(interval_index())
#> Unnamed interval_index with 0 elements, default bounds [start, end).
```
