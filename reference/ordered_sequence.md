# Construct an Ordered Sequence

Convenience constructor from `...` and matching `keys`.

## Usage

``` r
ordered_sequence(..., keys)
```

## Arguments

- ...:

  Elements to add.

- keys:

  Key values with the same length as `...`.

## Value

An `ordered_sequence`.

## Details

Empty construction is supported: `ordered_sequence()` returns an empty
ordered sequence.

Output is always sorted by key, with stable order across duplicate keys.

## Examples

``` r
xs <- ordered_sequence("bb", "a", "ccc", keys = c(2, 1, 3))
xs
#> Unnamed ordered_sequence with 3 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a"
#> 
#> [[2]] (key 2)
#> [1] "bb"
#> 
#> [[3]] (key 3)
#> [1] "ccc"
#> 
lower_bound(xs, 2)
#> $found
#> [1] TRUE
#> 
#> $index
#> [1] 2
#> 
#> $element
#> [1] "bb"
#> 
#> $key
#> [1] 2
#> 

num_by_chr <- ordered_sequence(20, 10, 30, keys = c("b", "a", "c"))
num_by_chr
#> Unnamed ordered_sequence with 3 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key a)
#> [1] 10
#> 
#> [[2]] (key b)
#> [1] 20
#> 
#> [[3]] (key c)
#> [1] 30
#> 

ordered_sequence()
#> Unnamed ordered_sequence with 0 elements.
```
