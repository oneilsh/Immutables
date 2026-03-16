# Developer API

## Scope

This vignette sketches low-level APIs used to extend/query immutable
structures:

- [`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md)
- [`add_monoids()`](https://oneilsh.github.io/immutables/reference/add_monoids.md)
- [`predicate()`](https://oneilsh.github.io/immutables/reference/Predicate.md)
- [`locate_by_predicate()`](https://oneilsh.github.io/immutables/reference/locate_by_predicate.md)
- [`split_around_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_around_by_predicate.md)
  /
  [`split_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_by_predicate.md)
- [`validate_tree()`](https://oneilsh.github.io/immutables/reference/validate_tree.md)
  /
  [`validate_name_state()`](https://oneilsh.github.io/immutables/reference/validate_name_state.md)

## Define and attach a monoid

``` r
x <- flexseq("a", "bb", "ccc", "dddd")

width_monoid <- measure_monoid(
  f = `+`,
  i = 0L,
  measure = function(el) nchar(el)
)

x2 <- add_monoids(x, list(width = width_monoid))
attr(x2, "measures")$width
#> [1] 10
```

## Leaf entry contract

Developer APIs are entry-oriented.
[`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md)
measure functions should always be `function(entry)`.

- `flexseq`: entry is the stored user element.
- `ordered_sequence`: entry is `list(value, key)`.
- `priority_queue`: entry is `list(value, priority)`.
- `interval_index`: entry is `list(value, start, end)`.

``` r
os <- as_ordered_sequence(list("x", "yy"), keys = c(1, 2))
by_key <- measure_monoid(`+`, 0L, function(entry) as.integer(entry$key))
os2 <- add_monoids(os, list(by_key = by_key))
loc_key <- locate_by_predicate(os2, function(v) v >= 3L, "by_key", include_metadata = TRUE)
loc_key$metadata$hit_measure
#> [1] 3
```

[`split_around_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_around_by_predicate.md)
and
[`locate_by_predicate()`](https://oneilsh.github.io/immutables/reference/locate_by_predicate.md)
return leaf entries in that same structure-specific form.

## Locate with predicate scans

``` r
p <- predicate(function(v) v >= 5L)

loc <- locate_by_predicate(x2, p, "width", include_metadata = TRUE)
loc$found
#> [1] TRUE
loc$value
#> [1] "ccc"
loc$metadata
#> $left_measure
#> [1] 3
#> 
#> $hit_measure
#> [1] 6
#> 
#> $right_measure
#> [1] 4
#> 
#> $index
#> [1] 3
```

## Split with predicate scans

``` r
s1 <- split_around_by_predicate(x2, function(v) v >= 5L, "width")
s1$left
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "bb"
s1$value
#> [1] "ccc"
s1$right
#> Unnamed flexseq with 1 element.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "dddd"

s2 <- split_by_predicate(x2, function(v) v >= 5L, "width")
s2$left
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "bb"
s2$right
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "ccc"
#> 
#> [[2]]
#> [1] "dddd"
```

## Invariant checks

These are intended for debugging and tests.

``` r
validate_tree(x2)
validate_name_state(as_flexseq(list(a = 1, b = 2)))
```
