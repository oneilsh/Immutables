# Split at a Position or Name

Splits by a single one-based position or a single element name.

## Usage

``` r
split_at(x, at, pull_index = FALSE)
```

## Arguments

- x:

  A `flexseq`.

- at:

  A single positive integer position or a single character name.

- pull_index:

  Controls output shape:

  - `FALSE` (default): returns `list(left, value, right)`.

  - `TRUE`: returns `list(left, right)`.

## Value

A split result with shape controlled by `pull_index`.

## Details

`split_at(x, at, pull_index = FALSE)` is a convenience wrapper around
[`split_around_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_around_by_predicate.md)
using positional scanning.

`split_at(x, at, pull_index = TRUE)` is the two-way variant using
[`split_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_by_predicate.md).

## Examples

``` r
x <- flexseq("a", "b", "c", "d")
split_at(x, 3)
#> $left
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
#> 
#> $value
#> [1] "c"
#> 
#> $right
#> Unnamed flexseq with 1 element.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "d"
#> 
#> 
split_at(x, 3, pull_index = TRUE)
#> $left
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
#> 
#> $right
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "c"
#> 
#> [[2]]
#> [1] "d"
#> 
#> 

n <- flexseq(a = 1, b = 2, c = 3)
split_at(n, "b")
#> $left
#> Named flexseq with 1 element.
#> 
#> Elements:
#> 
#> $a
#> [1] 1
#> 
#> 
#> $value
#> [1] 2
#> attr(,"ft_name")
#> [1] "b"
#> 
#> $right
#> Named flexseq with 1 element.
#> 
#> Elements:
#> 
#> $c
#> [1] 3
#> 
#> 
```
