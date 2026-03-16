# Pop the Front Element

Returns the first element and the remaining sequence.

## Usage

``` r
pop_front(x)
```

## Arguments

- x:

  A `flexseq`.

## Value

A list with fields:

- `value`: the first element, or `NULL` when `x` is empty.

- `remaining`: the sequence after removing the first element.

## Details

This operation is persistent: `x` is not modified.

On empty input, returns a non-throwing miss object with `value = NULL`
and `remaining = x`.

## Examples

``` r
s <- flexseq("a", "b", "c")
out <- pop_front(s)
out$value
#> [1] "a"
out$remaining
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "c"
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

pop_front(flexseq())
#> $value
#> NULL
#> 
#> $remaining
#> Unnamed flexseq with 0 elements.
#> 
```
