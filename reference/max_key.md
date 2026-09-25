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

Uses cached `.oms_max_key` monoid state. Equivalent to
`key_at(x, length(x))`.

## See also

[`min_key()`](https://oneilsh.github.io/Immutables/reference/min_key.md),
[`key_at()`](https://oneilsh.github.io/Immutables/reference/key_at.md),
[`nearest_key()`](https://oneilsh.github.io/Immutables/reference/nearest_key.md)

## Examples

``` r
x <- ordered_sequence("a", "b", keys = c(2, 1))
max_key(x)
#> [1] 2
max_key(ordered_sequence())
#> NULL
```
