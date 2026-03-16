# Concatenate Sequences

Concatenate Sequences

## Usage

``` r
# S3 method for class 'flexseq'
c(..., recursive = FALSE)
```

## Arguments

- ...:

  `flexseq` objects.

- recursive:

  Unused; must be `FALSE`.

## Value

A concatenated `flexseq`.

## Details

[`c()`](https://rdrr.io/r/base/c.html) is supported for `flexseq` and
returns a new concatenated `flexseq`.

For `priority_queue`, `ordered_sequence`, and `interval_index`,
[`c()`](https://rdrr.io/r/base/c.html) is not supported because
concatenation can violate structure-specific invariants. Cast first with
[`as_flexseq()`](https://oneilsh.github.io/immutables/reference/as_flexseq.md)
when sequence-style concatenation is intended, noting that this drops
ordering and priority metadata.

## Examples

``` r
x <- flexseq("a", "b")
y <- flexseq("c", "d")
c(x, y)
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

q1 <- priority_queue("a", priorities = 2)
q2 <- priority_queue("b", priorities = 1)
try(c(q1, q2))
#> Error in c.priority_queue(q1, q2) : 
#>   `c()` is not supported for priority_queue. Cast first with `as_flexseq()`.
c(as_flexseq(q1), as_flexseq(q2))
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

o1 <- ordered_sequence("a", keys = 1)
o2 <- ordered_sequence("b", keys = 2)
try(c(o1, o2))
#> Error in c.ordered_sequence(o1, o2) : 
#>   `c()` is not supported for ordered_sequence. Cast first with `as_flexseq()`.
```
