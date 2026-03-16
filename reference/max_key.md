# Maximum Key Value

Returns the largest key currently present in the ordered sequence.

## Usage

``` r
max_key(x)
```

## Arguments

- x:

  An `ordered_sequence`.

## Value

Maximum key, or `NULL` when `x` is empty.

## Details

Uses cached `.oms_max_key` monoid state.

## Examples

``` r
x <- ordered_sequence("a", "b", keys = c(2, 1))
max_key(x)
#> [1] 2
max_key(ordered_sequence())
#> NULL
```
