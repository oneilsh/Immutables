# Interval Index Length

Interval Index Length

## Usage

``` r
# S3 method for class 'interval_index'
length(x)
```

## Arguments

- x:

  An `interval_index`.

## Value

Number of indexed intervals.

## Details

Uses cached size metadata and runs in O(1).

## Examples

``` r
ix <- interval_index("a", "b", start = c(1, 3), end = c(2, 5))
length(ix)
#> [1] 2

length(interval_index())
#> [1] 0
```
