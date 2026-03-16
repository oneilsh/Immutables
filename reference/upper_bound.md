# Find First Element with Key `>` Query

Find First Element with Key `>` Query

## Usage

``` r
upper_bound(x, key)
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

- `value`: matched element, or `NULL`.

- `key`: matched key, or `NULL`.

## Details

`upper_bound()` finds the first element with key `> key`. This skips
exact key matches, which is useful for exclusive range endpoints and for
finding the position immediately after a duplicate-key run.

## See also

[`lower_bound()`](https://oneilsh.github.io/immutables/reference/lower_bound.md)

## Examples

``` r
x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
upper_bound(x, 2)
#> $found
#> [1] FALSE
#> 
#> $index
#> NULL
#> 
#> $value
#> NULL
#> 
#> $key
#> NULL
#> 
upper_bound(x, 10)
#> $found
#> [1] FALSE
#> 
#> $index
#> NULL
#> 
#> $value
#> NULL
#> 
#> $key
#> NULL
#> 
```
