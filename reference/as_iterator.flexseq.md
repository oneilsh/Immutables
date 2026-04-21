# Iterate over a `flexseq` (coro iterator)

Returns a lazy iterator that yields payload elements left-to-right. Use
with [`loop()`](https://oneilsh.github.io/immutables/reference/loop.md)
as the canonical iteration form:

## Usage

``` r
# S3 method for class 'flexseq'
as_iterator(x)
```

## Arguments

- x:

  A `flexseq`.

## Value

A `coro` iterator function.

## Details

    loop(for (x in s) print(x))

Iteration uses repeated left-view (`viewL`) and is O(n) total, O(1)
amortized per step. The original `x` is not modified; the iterator holds
a private cursor over progressively-smaller tails.

For named sequences, internal name metadata is stripped from yielded
values to match `peek_front(s)` semantics. Access names via
[`as.list()`](https://rdrr.io/r/base/list.html) when needed.

Inherited by `ordered_sequence` and `interval_index`: for those
subclasses the yielded value is the unwrapped payload (keys / interval
endpoints dropped), in key-ascending / start-position order
respectively. See
[`as_iterator.priority_queue()`](https://oneilsh.github.io/immutables/reference/as_iterator.priority_queue.md)
for the priority-order override.

## Do not use plain `for` directly

Writing `for (x in s) ...` (without
[`loop()`](https://oneilsh.github.io/immutables/reference/loop.md)) will
not dispatch this method. R's `for` walks the object's underlying list
storage at the C level and bypasses S3 `length`/`[[`, so it silently
yields raw finger-tree internals (Digit/Empty/Deep nodes) rather than
sequence elements. Always wrap with
[`loop()`](https://oneilsh.github.io/immutables/reference/loop.md), or
call [`as.list()`](https://rdrr.io/r/base/list.html) first for an eager
copy.

## Examples

``` r
s <- flexseq("a", "b", "c")
loop(for (x in s) print(x))
#> [1] "a"
#> [1] "b"
#> [1] "c"
```
