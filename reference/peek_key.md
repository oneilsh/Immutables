# Peek First Element for One Key

Returns the first element whose key equals `key`.

## Usage

``` r
peek_key(x, key)
```

## Arguments

- x:

  An `ordered_sequence`.

- key:

  Query key.

## Value

Matched element, or `NULL` when no matching key exists.

## Details

For duplicate keys, this returns the first element in stable sequence
order.

## Examples

``` r
x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
peek_key(x, 2)
#> [1] "b"
peek_key(x, 10)
#> NULL
```
