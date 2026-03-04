# Fapply with S3 dispatch

`fapply()` is an S3 generic for applying functions over immutable
structures with type-specific dispatch.

## Usage

``` r
fapply(X, FUN, ...)
```

## Arguments

- X:

  Object to apply over.

- FUN:

  Function to apply.

- ...:

  Method-specific arguments.

## Value

Method-dependent result.

## Details

`fapply()` returns a new object and preserves class semantics.

Method signatures:

- `fapply.flexseq(X, FUN, ..., preserve_custom_monoids = TRUE)`

- `fapply.priority_queue(X, FUN, ..., preserve_custom_monoids = TRUE)`

- `fapply.ordered_sequence(X, FUN, ..., preserve_custom_monoids = TRUE)`

- `fapply.interval_index(X, FUN, ..., preserve_custom_monoids = TRUE)`

For `priority_queue`, `ordered_sequence`, and `interval_index`, `FUN`
receives structured fields (`item` plus metadata) and should return the
new payload value only; ordering metadata is preserved.

If supported by the method, `preserve_custom_monoids = TRUE` keeps added
user monoids; `FALSE` rebuilds with required structural monoids only.

## See also

[`flexseq()`](https://oneilsh.github.io/immutables/reference/flexseq.md),
[`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md),
[`ordered_sequence()`](https://oneilsh.github.io/immutables/reference/ordered_sequence.md),
[`interval_index()`](https://oneilsh.github.io/immutables/reference/interval_index.md)

## Examples

``` r
x <- flexseq("a", "b", "c")
fapply(x, toupper)
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "A"
#> 
#> [[2]]
#> [1] "B"
#> 
#> [[3]]
#> [1] "C"
#> 

q <- priority_queue(one = "a", two = "b", priorities = c(2, 1))
fapply(q, function(item, priority, name) paste0(item, priority))
#> Named priority_queue with 2 elements.
#> Minimum priority: 1, Maximum priority: 2
#> 
#> Elements (by priority):
#> 
#> $two (priority 1)
#> [1] "b1"
#> 
#> $one (priority 2)
#> [1] "a2"
#> 

o <- ordered_sequence(one = "a", two = "b", keys = c(2, 1))
fapply(o, function(item, key, name) paste0(item, "_", key))
#> Named ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> $two (key 1)
#> [1] "b_1"
#> 
#> $one (key 2)
#> [1] "a_2"
#> 

ix <- interval_index(one = "a", two = "b", start = c(1, 3), end = c(2, 4))
fapply(ix, function(item, start, end, name) paste0(item, "[", start, ",", end, "]"))
#> Named interval_index with 2 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> $one (interval [1, 2))
#> [1] "a[1,2]"
#> 
#> $two (interval [3, 4))
#> [1] "b[3,4]"
#> 
```
