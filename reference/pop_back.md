# Pop the Back Element

Returns the last element and the remaining sequence.

## Usage

``` r
pop_back(x)
```

## Arguments

- x:

  A `flexseq`.

## Value

A list with fields:

- `element`: the last element, or `NULL` when `x` is empty.

- `remaining`: the sequence after removing the last element.

## Details

This operation is persistent: `x` is not modified.

On empty input, returns a non-throwing miss object with `element = NULL`
and `remaining = x`.

## Examples

``` r
s <- flexseq("a", "b", "c")
out <- pop_back(s)
out$element
#> [1] "c"
out$remaining
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
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

pop_back(flexseq())
#> $element
#> NULL
#> 
#> $remaining
#> Unnamed flexseq with 0 elements.
#> 
```
