# Iterate over a `priority_queue` (coro iterator)

Returns a lazy iterator that yields payload elements in
priority-ascending order. Use with
[`loop()`](https://oneilsh.github.io/immutables/reference/loop.md):

## Usage

``` r
# S3 method for class 'priority_queue'
as_iterator(x)
```

## Arguments

- x:

  A `priority_queue`.

## Value

A `coro` iterator function.

## Details

    loop(for (x in pq) print(x))

Traversal is driven by repeated
[`pop_min()`](https://oneilsh.github.io/immutables/reference/pop_min.md):
each step is O(log n), so full traversal is O(n log n). Ties within
equal priorities are yielded in FIFO insertion order (inherited from
[`pop_min()`](https://oneilsh.github.io/immutables/reference/pop_min.md)).

The original `x` is not modified; the iterator holds a private cursor
and partial iteration (e.g. via
[`break`](https://rdrr.io/r/base/Control.html)) leaves the source
intact.

Each yielded value is the bare payload (matching
[`peek_min()`](https://oneilsh.github.io/immutables/reference/peek_min.md)).
Use
[`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md)
if your callback needs the priority alongside the value, or cast with
[`as_flexseq()`](https://oneilsh.github.io/immutables/reference/as_flexseq.md)
for insertion-order iteration.

## Examples

``` r
pq <- priority_queue("a", "b", "c", priorities = c(3, 1, 2))
loop(for (x in pq) print(x))  # "b", "c", "a"
#> [1] "b"
#> [1] "c"
#> [1] "a"
```
