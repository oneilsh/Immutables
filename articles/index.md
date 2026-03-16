# immutables

## Overview

`immutables` provides four fast data structures:

[`flexseq()`](https://oneilsh.github.io/immutables/reference/flexseq.md) -
Provides list-like operations including indexed and named element
access, push/pop/peek from either end for double-ended queue behavior,
insertion, splitting, and concatenation.

[`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md) -
Associates items with priority values and provides min and max peek/pop
by priority and fast insertion.

[`ordered_sequence()`](https://oneilsh.github.io/immutables/reference/ordered_sequence.md) -
Associates items with key values and keeps the elements in sorted order
by key. These may be similarly be inserted/popped/peeked by key value as
well as position. Keys may be duplicated, with first-in-first-out order
within key groups.

[`interval_index()`](https://oneilsh.github.io/immutables/reference/interval_index.md) -
Stores items associated with interval ranges, supporting point and
interval overlap/containment/subsumption queries. Items are kept in
interval-start-order.

Built on monoid-annotated finger trees described by [Hinze and Paterson
(2006)](https://www.cs.ox.ac.uk/ralf.hinze/publications/FingerTrees.pdf),
they are immutable: operations return modified copies, and are thus
‘side-effect free’. Their fascinating internal structure ensures most
operations are fast, either constant amortized time or
$O\left( \log(n) \right)$, memory proportional to $n\log(n)$, and
`immutables` implements core operations in `C++` via `Rcpp` for
numeric/character/logical key and priority types, while enabling R
fallback for more complex types such as dates.

## Quick Tour

### flexseq

``` r
s <- flexseq("a", "b", "c")
s2 <- push_back(s, "d")
```

### priority_queue

``` r
q <- priority_queue("low", "high", priorities = c(10, 1))
peek_min(q)
#> [1] "high"
pop_min(q)$remaining
#> Unnamed priority_queue with 1 element.
#> Minimum priority: 10, Maximum priority: 10
#> 
#> Elements (by priority):
#> 
#> (priority 10)
#> [1] "low"
```

### ordered_sequence

``` r
os <- ordered_sequence("one", "two", "two-b", keys = c(1, 2, 2))
peek_key(os, 2)
#> [1] "two"
as.list(peek_all_key(os, 2))
#> [[1]]
#> [1] "two"
#> 
#> [[2]]
#> [1] "two-b"
```

### interval_index

``` r
ix <- interval_index("A", "B", start = c(1, 3), end = c(4, 5))
peek_point(ix, 3)
#> [1] "A"
as.list(peek_all_overlaps(ix, 2, 3))
#> [[1]]
#> [1] "A"
```

## Choosing a Structure

- Use `flexseq` for general sequence updates and slicing.
- Use `priority_queue` when min/max priority operations are primary.
- Use `ordered_sequence` when key lookup/range queries are primary.
- Use `interval_index` for point/overlap/containment interval relations.

All structures support names using standard R accessors
(`seq[c("name1", "name2")]`, `seq[["name"]]`, `seq$name`), but access by
name is slower than other operations in some cases. In the case of
ordered sequences and interval indices, return sequences are kept in
order, and a warning is displayed if this is different than the
requested order. It is generally possible to cast down with `as_flexseq`
with

If names are used, all elements must be non-NULL and unique. Every
write-like operation returns a new value and leaves the original
unchanged, though assignment with `[<-`, `[[<-`, and `$<-` is possible
in

## Next Articles

- [flexseq](https://oneilsh.github.io/immutables/articles/flexseq.md)
- [Priority
  Queues](https://oneilsh.github.io/immutables/articles/priority-queues.md)
- [Ordered
  Sequences](https://oneilsh.github.io/immutables/articles/ordered-sequences.md)
- [Interval
  Indices](https://oneilsh.github.io/immutables/articles/interval-indices.md)
- [Algorithm
  Demos](https://oneilsh.github.io/immutables/articles/algorithm-demos.md)
- [Developer
  API](https://oneilsh.github.io/immutables/articles/developer-api.md)
