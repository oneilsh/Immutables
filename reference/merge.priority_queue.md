# Merge Two Priority Queues

Returns a new `priority_queue` containing every entry from both inputs,
preserving each queue's internal insertion order (entries of `x` come
first, then entries of `y`).

## Usage

``` r
# S3 method for class 'priority_queue'
merge(x, y, ...)
```

## Arguments

- x:

  A `priority_queue`.

- y:

  A `priority_queue`.

- ...:

  Unused.

## Value

A new `priority_queue` of size `length(x) + length(y)`.

## Details

The cached `.pq_min` / `.pq_max` monoids recompute automatically on the
merged tree, so
[`peek_min()`](https://oneilsh.github.io/immutables/reference/peek_min.md)
/
[`peek_max()`](https://oneilsh.github.io/immutables/reference/peek_max.md)
reflect the combined extremum immediately.

Both queues must share the same priority type and the same monoid set;
mismatches error rather than being silently harmonized. Merging an empty
queue with a non-empty queue returns the non-empty queue unchanged.

Both inputs are left unmodified.

## Examples

``` r
a <- priority_queue("x", "y", priorities = c(5, 1))
b <- priority_queue("z", priorities = 3)
m <- merge(a, b)
peek_min(m)
#> [1] "y"
length(m)
#> [1] 3
```
