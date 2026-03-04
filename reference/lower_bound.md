# Find First Element with Key `>=` Query

Find First Element with Key `>=` Query

## Usage

``` r
lower_bound(x, key)
```

## Arguments

- x:

  An `ordered_sequence`.

- key:

  Query key.

## Value

A list with fields:

- `found`: logical flag.

- `index`: one-based position of the first match, or `NULL`.

- `element`: matched element, or `NULL`.

- `key`: matched key, or `NULL`.

## Details

`lower_bound()` finds the first element with key `>= key`. This includes
an exact key match when present, which is useful for starting equality
or inclusive range scans.

## See also

[`upper_bound()`](https://oneilsh.github.io/immutables/reference/upper_bound.md)

## Examples

``` r
x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
lower_bound(x, 2)
#> $found
#> [1] TRUE
#> 
#> $index
#> [1] 2
#> 
#> $element
#> [1] "b"
#> 
#> $key
#> [1] 2
#> 
lower_bound(x, 10)
#> $found
#> [1] FALSE
#> 
#> $index
#> NULL
#> 
#> $element
#> NULL
#> 
#> $key
#> NULL
#> 
```
