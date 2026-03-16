# Pop First Element for One Key

Removes and returns the first element whose key equals `key`.

## Usage

``` r
pop_key(x, key)
```

## Arguments

- x:

  An `ordered_sequence`.

- key:

  Query key.

## Value

A list with fields:

- `value`: removed element, or `NULL` on miss.

- `key`: removed key, or `NULL` on miss.

- `remaining`: ordered sequence after removal.

## Details

For duplicate keys, the first element in stable sequence order is
removed.

## Examples

``` r
x <- ordered_sequence("a", "b", "c", keys = c(1, 2, 2))
out <- pop_key(x, 2)
out$value
#> [1] "b"
out$remaining
#> Unnamed ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a"
#> 
#> [[2]] (key 2)
#> [1] "c"
#> 
pop_key(x, 10)
#> $value
#> NULL
#> 
#> $key
#> NULL
#> 
#> $remaining
#> Unnamed ordered_sequence with 3 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a"
#> 
#> [[2]] (key 2)
#> [1] "b"
#> 
#> [[3]] (key 2)
#> [1] "c"
#> 
#> 
```
