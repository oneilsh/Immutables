# Merge Two Sequences

Returns a new `flexseq` containing all elements of `x` followed by all
elements of `y`. Thin wrapper over
[`c()`](https://rdrr.io/r/base/c.html) for API uniformity across the
package's merge methods; `c(x, y)` and `merge(x, y)` are equivalent for
`flexseq`.

## Usage

``` r
# S3 method for class 'flexseq'
merge(x, y, ...)
```

## Arguments

- x:

  A `flexseq`.

- y:

  A `flexseq`.

- ...:

  Unused.

## Value

A new `flexseq`.

## Details

For ordered types (`ordered_sequence`, `interval_index`),
[`merge()`](https://rdrr.io/r/base/merge.html) performs a proper sorted
merge respecting keys/intervals — see
[`merge.ordered_sequence()`](https://oneilsh.github.io/immutables/reference/merge.ordered_sequence.md)
and
[`merge.interval_index()`](https://oneilsh.github.io/immutables/reference/merge.interval_index.md).
For `priority_queue`, see
[`merge.priority_queue()`](https://oneilsh.github.io/immutables/reference/merge.priority_queue.md).

## Examples

``` r
x <- flexseq("a", "b")
y <- flexseq("c", "d")
merge(x, y)
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
```
