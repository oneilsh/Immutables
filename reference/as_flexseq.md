# Coerce Objects to `flexseq`

`as_flexseq()` is the canonical way to obtain a plain `flexseq` for full
sequence-style operations.

## Usage

``` r
as_flexseq(x)
```

## Arguments

- x:

  Input object.

## Value

A plain `flexseq`.

## Details

For base vectors/lists, this builds a new `flexseq` preserving element
order and names.

For specialized immutable subclasses (`priority_queue`,
`ordered_sequence`, `interval_index`), this intentionally drops subclass
semantics and returns a plain `flexseq`.

This is an S3 generic. Notable method behavior:

- `as_flexseq.flexseq(x)` returns `x` unchanged.

- `as_flexseq.priority_queue(x)` returns payload items.

- `as_flexseq.ordered_sequence(x)` returns payload items.

- `as_flexseq.interval_index(x)` returns payload items.

For advanced types, custom monoids are dropped and the rebuilt `flexseq`
keeps only structural monoids (`.size`, `.named_count`). For
`priority_queue`, a flexseq of full entry records can be obtained by
composing with [`as.list()`](https://rdrr.io/r/base/list.html):
`as_flexseq(as.list(x))`. For `ordered_sequence` and `interval_index`,
[`as.list()`](https://rdrr.io/r/base/list.html) also returns
payload-only lists, so no direct record-preserving cast is provided.

## See also

[`flexseq()`](https://oneilsh.github.io/immutables/reference/flexseq.md),
[`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md),
[`ordered_sequence()`](https://oneilsh.github.io/immutables/reference/ordered_sequence.md),
[`interval_index()`](https://oneilsh.github.io/immutables/reference/interval_index.md)

## Examples

``` r
x <- as_flexseq(1:3)
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

q <- priority_queue("a", "b", priorities = c(2, 1))
as_flexseq(q)
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 

o <- ordered_sequence("a", "b", keys = c(2, 1))
as_flexseq(o)
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "a"
#> 
```
