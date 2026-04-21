# Read Per-Element Monoid Measures

Applies the named monoid's `measure()` function to each leaf entry in
sequence order, returning the results as a new `flexseq`.

## Usage

``` r
get_measures(x, monoid_name)
```

## Arguments

- x:

  A flexseq (or any immutables subclass).

- monoid_name:

  Name of an attached monoid.

## Value

A plain unnamed `flexseq` of length `length(x)`. Entry `i` is the
monoid's `measure()` applied to the `i`-th leaf entry.

## Details

Each leaf in a finger tree stores a structure-specific *entry* (flexseq:
the raw element; ordered_sequence: `list(value, key)`; priority_queue:
`list(value, priority)`; interval_index: `list(value, start, end)`). A
monoid's `measure()` function is defined over that entry shape, and this
accessor exposes the per-element values that would be combined to
produce the cached aggregate.

Returns a `flexseq` rather than a base list so results can be piped back
into other immutables operations; use
[`as.list()`](https://rdrr.io/r/base/list.html) or
[`unlist()`](https://rdrr.io/r/base/unlist.html) to convert.

## See also

[`get_measure()`](https://oneilsh.github.io/immutables/reference/get_measure.md),
[`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md),
[`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md)

## Examples

``` r
sum_m <- measure_monoid(`+`, 0, function(el) el)
x <- add_monoids(as_flexseq(c(3, 1, 4, 1, 5, 9)), list(sum = sum_m))
get_measures(x, "sum") |> unlist()
#> [1] 3 1 4 1 5 9

q <- priority_queue("a", "b", "c", priorities = c(5, 1, 3))
# Per-element .pq_min measures — each is list(has, priority).
get_measures(q, ".pq_min")
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> $has
#> [1] TRUE
#> 
#> $priority
#> [1] 5
#> 
#> 
#> [[2]]
#> $has
#> [1] TRUE
#> 
#> $priority
#> [1] 1
#> 
#> 
#> [[3]]
#> $has
#> [1] TRUE
#> 
#> $priority
#> [1] 3
#> 
#> 
```
