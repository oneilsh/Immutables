# Minimum Left Endpoint

Returns the smallest left endpoint (`start`) currently present.

## Usage

``` r
min_endpoint(x)
```

## Arguments

- x:

  An `interval_index`.

## Value

Minimum left endpoint, or `NULL` when `x` is empty.

## Details

Because intervals are stored in start order, this reads the first
entry's `start`.

## Examples

``` r
ix <- interval_index("a", "b", start = c(3, 1), end = c(4, 2))
min_endpoint(ix)
#> [1] 1
min_endpoint(interval_index())
#> NULL
```
