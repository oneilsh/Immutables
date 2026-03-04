# Pop an Element by Position

Returns the selected element and the remaining sequence.

## Usage

``` r
pop_at(x, index)
```

## Arguments

- x:

  A `flexseq`.

- index:

  One-based position to remove.

## Value

A list with fields:

- `element`: the element at `index`, or `NULL` when `index` is out of
  bounds.

- `remaining`: the sequence after removing the selected element.

## Details

This operation is persistent: `x` is not modified.

Positive integer indices beyond `length(x)` return a non-throwing miss
object with `element = NULL` and `remaining = x`. Invalid indices (`NA`,
non-integer, `<= 0`, or length not equal to 1) error.

## Examples

``` r
x <- flexseq("a", "b", "c", "d")
out <- pop_at(x, 3)
out$element
#> [1] "c"
out$remaining
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
#> [1] "d"
#> 
x  # unchanged
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

pop_at(x, 10)
#> $element
#> NULL
#> 
#> $remaining
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
#> 
try(pop_at(x, 0))
#> Error in .ft_validate_scalar_position_missable(index, n) : 
#>   Only positive integer indices are supported.
```
