# Read a Cached Subtree Measure

Returns the monoid's accumulated measure across the whole (sub)tree at
the root of `x`. This is the cached value that internal operations use
for O(log n) locate and split.

## Usage

``` r
get_measure(x, monoid_name)
```

## Arguments

- x:

  A flexseq (or any immutables subclass).

- monoid_name:

  Name of an attached monoid (e.g. `.size`, a custom name from
  [`add_monoids()`](https://oneilsh.github.io/immutables/reference/add_monoids.md),
  or a built-in like `.pq_min` / `.oms_max_key`).

## Value

The cached monoid value at the root of `x`. Shape depends on the monoid
— typically atomic (e.g. a numeric sum) but may be a list for built-ins
that carry auxiliary state.

## Details

On the full tree `x`, this is the aggregate over every element. After a
split — e.g. `s <- split_by_predicate(x, p, "sum")` — call
`get_measure(s$left, "sum")` to read the aggregate of just the left side
in O(1).

For per-element measures, see
[`get_measures()`](https://oneilsh.github.io/immutables/reference/get_measures.md).

## See also

[`get_measures()`](https://oneilsh.github.io/immutables/reference/get_measures.md),
[`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md),
[`add_monoids()`](https://oneilsh.github.io/immutables/reference/add_monoids.md)

## Examples

``` r
sum_m <- measure_monoid(`+`, 0, function(el) el)
x <- add_monoids(as_flexseq(c(3, 1, 4, 1, 5, 9, 2, 6)),
                 list(sum = sum_m))
get_measure(x, "sum")         # total across the whole tree
#> [1] 31
get_measure(x, ".size")       # built-in: element count
#> [1] 8

q <- priority_queue("a", "b", "c", priorities = c(5, 1, 3))
get_measure(q, ".pq_min")     # built-in, list-valued
#> $has
#> [1] TRUE
#> 
#> $priority
#> [1] 1
#> 
```
