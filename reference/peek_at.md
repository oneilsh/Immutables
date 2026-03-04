# Peek at an Element by Position

Returns the element at a one-based index without modifying the sequence.

## Usage

``` r
peek_at(x, index)
```

## Arguments

- x:

  A `flexseq`.

- index:

  One-based position to read.

## Value

Element at `index`, or `NULL` when `index` is out of bounds.

## Details

Positive integer indices beyond `length(x)` return `NULL`. Invalid
indices (`NA`, non-integer, `<= 0`, or length not equal to 1) error.

## Examples

``` r
x <- flexseq("a", "b", "c")
peek_at(x, 2)
#> [1] "b"
peek_at(x, 10)
#> NULL

try(peek_at(x, 0))
#> Error in .ft_validate_scalar_position_missable(index, n) : 
#>   Only positive integer indices are supported.
```
