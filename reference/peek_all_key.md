# Peek All Elements for One Key

Returns all elements whose key equals `key`.

## Usage

``` r
peek_all_key(x, key)
```

## Arguments

- x:

  An `ordered_sequence`.

- key:

  Query key.

## Value

An `ordered_sequence` containing all matches; empty on miss.

## Details

The returned `ordered_sequence` can be inspected with
[`as.list()`](https://rdrr.io/r/base/list.html).

## Examples

``` r
x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
out <- peek_all_key(x, 2)
as.list(out)
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "c"
#> 
```
