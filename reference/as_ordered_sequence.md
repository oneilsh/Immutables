# Build an Ordered Sequence from `x` and `keys`

Constructs an `ordered_sequence` by pairing each element of `x` with the
corresponding key in `keys`.

## Usage

``` r
as_ordered_sequence(x, keys)
```

## Arguments

- x:

  Elements to add.

- keys:

  Key values with the same length as `x`.

## Value

An `ordered_sequence`.

## Details

Output is always sorted by key.

Duplicate keys are allowed; ties preserve input order (stable/FIFO
within the same key).

Names on `x` are preserved as element names.

## Examples

``` r
xs <- as_ordered_sequence(c("d", "a", "b", "a2"), keys = c(4, 1, 2, 1))
xs
#> Unnamed ordered_sequence with 4 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a"
#> 
#> [[2]] (key 1)
#> [1] "a2"
#> 
#> [[3]] (key 2)
#> [1] "b"
#> 
#> [[4]] (key 4)
#> [1] "d"
#> 
length(elements_between(xs, 1, 1))
#> [1] 2

n <- as_ordered_sequence(setNames(as.list(c("a", "b")), c("ka", "kb")), keys = c(2, 1))
n[["kb"]]
#> [1] "b"

# Keys can be other comparable types
num_by_chr <- as_ordered_sequence(c(20, 10, 30), keys = c("b", "a", "c"))
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
```
