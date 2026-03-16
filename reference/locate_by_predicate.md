# Locate First Predicate Match

Scans accumulated monoid values and returns the first element where
`predicate` becomes `TRUE`, without rebuilding split trees.

## Usage

``` r
locate_by_predicate(
  t,
  predicate,
  monoid_name,
  accumulator = NULL,
  include_metadata = FALSE
)
```

## Arguments

- t:

  A `flexseq` (or subclass).

- predicate:

  Function applied to accumulated monoid values.

- monoid_name:

  Name of the monoid used for scanning.

- accumulator:

  Optional starting accumulator value.

- include_metadata:

  Logical; include scan metadata.

## Value

If `include_metadata = FALSE`, a list with:

- `found`: logical flag.

- `value`: matched element when found, otherwise `NULL`.

If `include_metadata = TRUE`, adds `metadata` with:

- `left_measure`

- `hit_measure`

- `right_measure`

- `index`

## Details

This is the read-only analogue of
[`split_around_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_around_by_predicate.md).

As with split helpers, a common setup is a custom monoid created with
[`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md)
and attached via
[`add_monoids()`](https://oneilsh.github.io/immutables/reference/add_monoids.md).

`value` is the matched leaf entry for the input structure:

- `flexseq`: stored user element.

- `ordered_sequence`: `list(value, key)`.

- `priority_queue`: `list(value, priority)`.

- `interval_index`: `list(value, start, end)`.

## Examples

``` r
x <- flexseq("a", "b", "c", "d")
size_monoid <- measure_monoid(`+`, 0L, function(e) 1L)
x2 <- add_monoids(x, list(size = size_monoid))

locate_by_predicate(x2, function(v) v >= 3L, "size")
#> $found
#> [1] TRUE
#> 
#> $value
#> [1] "c"
#> 
locate_by_predicate(x2, function(v) v >= 3L, "size", include_metadata = TRUE)
#> $found
#> [1] TRUE
#> 
#> $value
#> [1] "c"
#> 
#> $metadata
#> $metadata$left_measure
#> [1] 2
#> 
#> $metadata$hit_measure
#> [1] 3
#> 
#> $metadata$right_measure
#> [1] 1
#> 
#> $metadata$index
#> [1] 3
#> 
#> 
```
