# Coerce Interval Index to List

Coerce Interval Index to List

## Usage

``` r
# S3 method for class 'interval_index'
as.list(x, ...)
```

## Arguments

- x:

  An `interval_index`.

- ...:

  Unused.

## Value

A plain list of payload elements in interval order.

## Details

This returns payload values only.

## Examples

``` r
ix <- interval_index("a", "b", "c", start = c(3, 1, 2), end = c(4, 2, 3))
as.list(ix)
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "c"
#> 
#> [[3]]
#> [1] "a"
#> 
```
