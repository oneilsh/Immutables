# Pop All Elements for One Key

Removes and returns all elements whose key equals `key`.

## Usage

``` r
pop_all_key(x, key)
```

## Arguments

- x:

  An `ordered_sequence`.

- key:

  Query key.

## Value

A list with fields:

- `elements`: `ordered_sequence` of removed matches.

- `remaining`: `ordered_sequence` after removal.

## Details

Use [`as.list()`](https://rdrr.io/r/base/list.html) to convert
`elements` to a standard R list.

## Examples

``` r
x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
out <- pop_all_key(x, 2)
as.list(out$elements)
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "c"
#> 
out$remaining
#> Unnamed ordered_sequence with 1 element.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a"
#> 
```
