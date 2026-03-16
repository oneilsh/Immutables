# Maximum Right Endpoint

Returns the largest right endpoint (`end`) currently present.

## Usage

``` r
max_endpoint(x)
```

## Arguments

- x:

  An `interval_index`.

## Value

Maximum right endpoint, or `NULL` when `x` is empty.

## Details

Uses cached `.ivx_max_end` monoid state.

## Examples

``` r
ix <- interval_index("a", "b", start = c(3, 1), end = c(4, 2))
max_endpoint(ix)
#> [1] 4
max_endpoint(interval_index())
#> NULL
```
