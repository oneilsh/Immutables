# Construct a Persistent Flexible Sequence

`flexseq(...)` creates an immutable sequence from `...`, preserving
element order and optional names, with efficient persistent updates.

## Usage

``` r
flexseq(...)
```

## Arguments

- ...:

  Sequence elements.

## Value

A `flexseq` object.

## Details

It is list-like in payload flexibility (any R object per element), but
sequence-oriented in API (`push_*`, `peek_*`, `pop_*`, indexing,
split/concat).

`flexseq` is the base general-purpose structure in this package.
Specialized structures such as `priority_queue`, `ordered_sequence`, and
`interval_index` build on related internals but expose narrower
semantics.

`flexseq` operations are persistent: updates return new objects and do
not mutate prior versions.

## See also

[`as_flexseq()`](https://oneilsh.github.io/immutables/reference/as_flexseq.md),
[`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md),
[`ordered_sequence()`](https://oneilsh.github.io/immutables/reference/ordered_sequence.md),
[`interval_index()`](https://oneilsh.github.io/immutables/reference/interval_index.md)

## Examples

``` r
x <- flexseq(1, 2, 3)
x
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> [[3]]
#> [1] 3
#> 

y <- push_front(x, 0)
y
#> Unnamed flexseq with 4 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 0
#> 
#> [[2]]
#> [1] 1
#> 
#> [[3]]
#> [1] 2
#> 
#> [[4]]
#> [1] 3
#> 
x  # unchanged
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> [[3]]
#> [1] 3
#> 

named <- flexseq(a = 1, b = 2)
named
#> Named flexseq with 2 elements.
#> 
#> Elements:
#> 
#> $a
#> [1] 1
#> 
#> $b
#> [1] 2
#> 
named[["a"]]
#> [1] 1
```
