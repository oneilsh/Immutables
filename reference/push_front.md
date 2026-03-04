# Push an Element to the Front

Returns a new sequence with `value` prepended at the left end.

## Usage

``` r
push_front(x, value)
```

## Arguments

- x:

  A `flexseq`.

- value:

  Element to prepend.

## Value

Updated `flexseq`.

## Details

This operation is persistent: `x` is not modified.

Elements can be named, but only if all are uniquely named (no missing
names).

## Examples

``` r
s <- as_flexseq(letters[2:4])
s2 <- push_front(s, "a")
s2
#> Unnamed flexseq with 4 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> [[3]]
#> [1] "c"
#> 
#> [[4]]
#> [1] "d"
#> 
s  # unchanged
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "c"
#> 
#> [[3]]
#> [1] "d"
#> 

n <- as_flexseq(list(two = 2, three = 3))
new_el <- 1
names(new_el) <- "one"
push_front(n, new_el)
#> Named flexseq with 3 elements.
#> 
#> Elements:
#> 
#> $one
#> one 
#>   1 
#> 
#> $two
#> [1] 2
#> 
#> $three
#> [1] 3
#> 

# Named/unnamed mixes are rejected
try(push_front(n, 0))
#> Error in push_front(n, 0) : 
#>   Cannot mix named and unnamed elements (push_front would create mixed named and unnamed tree).
```
