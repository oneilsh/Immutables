# Minimum Key Value

Returns the smallest key currently present in the ordered sequence.

## Usage

``` r
min_key(x)
```

## Arguments

- x:

  An `ordered_sequence`.

## Value

Minimum key, or `NULL` when `x` is empty.

## Details

This follows sequence key order directly. Equivalent to `key_at(x, 1)`.

## See also

[`max_key()`](https://oneilsh.github.io/Immutables/reference/max_key.md),
[`key_at()`](https://oneilsh.github.io/Immutables/reference/key_at.md),
[`nearest_key()`](https://oneilsh.github.io/Immutables/reference/nearest_key.md)

## Examples

``` r
x <- ordered_sequence("a", "b", keys = c(2, 1))
min_key(x)
#> [1] 1
min_key(ordered_sequence())
#> NULL
```
