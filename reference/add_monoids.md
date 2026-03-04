# Add or Merge Measure Monoids

Attaches one or more named
[`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md)
definitions to an existing immutable structure.

## Usage

``` r
add_monoids(t, monoids, overwrite = FALSE)
```

## Arguments

- t:

  Immutable structure (`flexseq` and subclasses).

- monoids:

  Named list of
  [`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md)
  objects.

- overwrite:

  Logical; if `TRUE`, replace existing monoids with the same names. If
  `FALSE`, existing names are kept.

## Value

A persistent copy with updated monoid definitions and cached measures.

## Details

Mechanics:

- Each monoid name defines an independent accumulated measure over
  elements in the tree.

- New monoids are computed for all elements and cached in the returned
  object.

- Existing monoids are unchanged unless `overwrite = TRUE`.

- Structural/reserved monoid names cannot be replaced.

This operation is persistent: `t` is not modified.

Use this when you want fast predicate scans (for example with
[`locate_by_predicate()`](https://oneilsh.github.io/immutables/reference/locate_by_predicate.md),
[`split_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_by_predicate.md),
[`split_around_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_around_by_predicate.md))
driven by domain-specific accumulated values.

## See also

`add_monoids.flexseq()`, `add_monoids.priority_queue()`,
`add_monoids.ordered_sequence()`, `add_monoids.interval_index()`

## Examples

``` r
x <- flexseq(10, 20, 30)

running_sum <- measure_monoid(`+`, 0, as.numeric)
x2 <- add_monoids(x, list(sum = running_sum))
attr(x2, "measures")$sum
#> [1] 60

# Use the monoid in a split query
split_around_by_predicate(x2, function(v) v >= 30, "sum")
#> $left
#> Unnamed flexseq with 1 element.
#> Custom monoids: sum
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 10
#> 
#> 
#> $elem
#> [1] 20
#> 
#> $right
#> Unnamed flexseq with 1 element.
#> Custom monoids: sum
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 30
#> 
#> 

# Overwrite an existing monoid definition
running_count <- measure_monoid(`+`, 0L, function(e) 1L)
x3 <- add_monoids(x2, list(sum = running_count), overwrite = TRUE)
attr(x3, "measures")$sum
#> [1] 3
```
