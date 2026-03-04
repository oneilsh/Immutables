# Push an Element to the Back

Returns a new sequence with `value` appended at the right end.

## Usage

``` r
push_back(x, value)
```

## Arguments

- x:

  A `flexseq`.

- value:

  Element to append.

## Value

Updated `flexseq`.

## Details

This operation is persistent: `x` is not modified.

Elements can be named, but only if all are uniquely named (no missing
names).

## Examples

``` r
s <- as_flexseq(letters[1:3])
s2 <- push_back(s, "d")
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
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> [[3]]
#> [1] "c"
#> 

n <- as_flexseq(list(two = 2, three = 3))
new_el <- 4
names(new_el) <- "four"
push_back(n, new_el)
#> Named flexseq with 3 elements.
#> 
#> Elements:
#> 
#> $two
#> [1] 2
#> 
#> $three
#> [1] 3
#> 
#> $four
#> four 
#>    4 
#> 

# Named/unnamed mixes are rejected
try(push_back(n, 5))
#> Error in .ft_push_back_impl(x, value, context = "push_back()") : 
#>   Cannot mix named and unnamed elements (push_back would create mixed named and unnamed tree).
```
