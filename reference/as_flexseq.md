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
semantics and returns a plain `flexseq` over stored entries.

This is an S3 generic. Notable method behavior:

- `as_flexseq.flexseq(x)` returns `x` unchanged.

- `as_flexseq.priority_queue(x)` drops queue-only API constraints and
  removes queue-specific monoids.

- `as_flexseq.ordered_sequence(x)` and `as_flexseq.interval_index(x)`
  drop ordered/query semantics and return sequence entries.

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
#> $item
#> [1] "a"
#> 
#> $priority
#> [1] 2
#> 
#> 
#> [[2]]
#> $item
#> [1] "b"
#> 
#> $priority
#> [1] 1
#> 
#> 

o <- ordered_sequence("a", "b", keys = c(2, 1))
as_flexseq(o)
#> Unnamed flexseq with 2 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> $item
#> [1] "b"
#> 
#> $key
#> [1] 1
#> 
#> 
#> [[2]]
#> $item
#> [1] "a"
#> 
#> $key
#> [1] 2
#> 
#> 
```
