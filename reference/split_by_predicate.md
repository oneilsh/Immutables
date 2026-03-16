# Split into Left and Right Parts

Splits at the first point where `predicate` becomes `TRUE` while
scanning the sequence.

## Usage

``` r
split_by_predicate(x, predicate, monoid_name)
```

## Arguments

- x:

  A `flexseq` (or subclass).

- predicate:

  Function applied to accumulated monoid values.

- monoid_name:

  Name of the monoid used for scanning.

## Value

A list with fields:

- `left`: elements before the split point.

- `right`: elements from the split point onward.

## Details

This is the two-way variant of
[`split_around_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_around_by_predicate.md).

As with
[`split_around_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_around_by_predicate.md),
a common setup is a custom monoid created with
[`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md)
and attached via
[`add_monoids()`](https://oneilsh.github.io/immutables/reference/add_monoids.md).

`left` and `right` preserve subclass when the input is a subclass of
`flexseq`.

## Examples

``` r
x <- flexseq("a", "b", "c", "d")
size_monoid <- measure_monoid(`+`, 0L, function(e) 1L)
x2 <- add_monoids(x, list(size = size_monoid))
split_by_predicate(x2, function(v) v >= 3L, "size")
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

# Split at the first element
split_by_predicate(x2, function(v) v >= 1L, "size")
#> $left
#> Unnamed flexseq with 0 elements.
#> 
#> $right
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
```
