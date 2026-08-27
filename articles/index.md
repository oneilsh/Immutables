# Immutables

## Overview

`immutables` provides four fast data structures:

[`flexseq()`](https://oneilsh.github.io/immutables/articles/flexseq.md) -
Provides list-like operations including indexed and named element
access, push/pop/peek from either end for double-ended queue behavior,
insertion, splitting, and concatenation.

[`priority_queue()`](https://oneilsh.github.io/immutables/articles/priority-queues.md) -
Associates items with priority values and provides min and max peek/pop
by priority and fast insertion.

[`ordered_sequence()`](https://oneilsh.github.io/immutables/articles/ordered-sequences.md) -
Associates items with key values and keeps the elements in sorted order
by key. These may be similarly be inserted/popped/peeked by key value as
well as position. Keys may be duplicated, with first-in-first-out order
within key groups.

[`interval_index()`](https://oneilsh.github.io/immutables/articles/interval-indices.md) -
Stores items associated with interval ranges, supporting point and
interval overlap/containment/subsumption queries. Items are kept in
interval-start-order.

A [developer
API](https://oneilsh.github.io/immutables/articles/developer-api.md)
exposes the underlying monoid-annotated finger tree primitives (custom
monoids, predicate-based locate/split, validation helpers) for building
new structures and indexes.

## Quick Tour

### flexseq

Construct, then push or pop at either end:

``` r

s <- flexseq("a", "b", "c", "d")
s |> push_front("z") |> push_back("e")
#> Unnamed flexseq with 6 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "z"
#> 
#> [[2]]
#> [1] "a"
#> 
#> ... (skipping 2 elements)
#> 
#> [[5]]
#> [1] "d"
#> 
#> [[6]]
#> [1] "e"
pop_front(s)$remaining
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "c"
#> 
#> [[3]]
#> [1] "d"
```

Random-access and positional edits:

``` r

s[[3]]
#> [1] "c"
peek_back(s)
#> [1] "d"
insert_at(s, 3, c("x", "y"))
#> Unnamed flexseq with 6 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> ... (skipping 2 elements)
#> 
#> [[5]]
#> [1] "c"
#> 
#> [[6]]
#> [1] "d"
```

Map, concatenate, and iterate:

``` r

fapply(s, toupper)
#> Unnamed flexseq with 4 elements.
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
#> [[4]]
#> [1] "D"
c(s, as_flexseq(letters[10:12]))
#> Unnamed flexseq with 7 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> ... (skipping 3 elements)
#> 
#> [[6]]
#> [1] "k"
#> 
#> [[7]]
#> [1] "l"
loop(for (el in s) print(el))
#> [1] "a"
#> [1] "b"
#> [1] "c"
#> [1] "d"
```

### priority_queue

Construct with priorities, optionally with names, and insert more
entries:

``` r

q <- priority_queue(a = "task_a", b = "task_b", c = "task_c", priorities = c(3, 1, 2)) |>
  insert("task_d", priority = 1, name = "d")
```

Peek/pop by min or max priority; the `*_all_*` variants handle ties:

``` r

peek_min(q)
#> [1] "task_b"
pop_max(q)$value
#> [1] "task_a"
pop_all_min(q)$elements
#> Named priority_queue with 2 elements.
#> Minimum priority: 1, Maximum priority: 1
#> 
#> Elements (by priority):
#> 
#> $b (priority 1)
#> [1] "task_b"
#> 
#> $d (priority 1)
#> [1] "task_d"
```

Read extrema and merge two queues into one:

``` r

min_priority(q); max_priority(q)
#> [1] 1
#> [1] 3
merge(q, priority_queue("task_e", priorities = 0))
#> Named priority_queue with 5 elements.
#> Minimum priority: 0, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 0)
#> [1] "task_e"
#> 
#> $b (priority 1)
#> [1] "task_b"
#> 
#> ... (skipping 1 element)
#> 
#> $c (priority 2)
#> [1] "task_c"
#> 
#> $a (priority 3)
#> [1] "task_a"
```

### ordered_sequence

Construct sorted by key (duplicates allowed, ties FIFO):

``` r

xs <- ordered_sequence("a1", "b1", "b2", "c1", keys = c(1, 2, 2, 3))
peek_key(xs, 2)
#> [1] "b1"
peek_all_key(xs, 2)
#> Unnamed ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 2)
#> [1] "b1"
#> 
#> [[2]] (key 2)
#> [1] "b2"
```

Range queries and successor lookup:

``` r

count_between(xs, 1, 2)
#> [1] 3
elements_between(xs, 2, 3, include_to = FALSE)
#> Unnamed ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 2)
#> [1] "b1"
#> 
#> [[2]] (key 2)
#> [1] "b2"
lower_bound(xs, 2)$index
#> [1] 2
```

Extrema and merge:

``` r

min_key(xs); max_key(xs)
#> [1] 1
#> [1] 3
merge(xs, ordered_sequence("d1", keys = 4))
#> Unnamed ordered_sequence with 5 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a1"
#> 
#> [[2]] (key 2)
#> [1] "b1"
#> 
#> ... (skipping 1 element)
#> 
#> [[4]] (key 3)
#> [1] "c1"
#> 
#> [[5]] (key 4)
#> [1] "d1"
```

### interval_index

Construct with start/end coordinates; entries stay in start order:

``` r

ix <- interval_index("A", "B", "C", start = c(1, 2, 4), end = c(3, 4, 5))
peek_point(ix, 2)
#> [1] "A"
```

Interval-relation queries (overlap, containment), plus sweep-line
endpoint matches via `match_at`:

``` r

peek_all_overlaps(ix, start = 2, end = 5)
#> Unnamed interval_index with 3 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "A"
#> 
#> [[2]] (interval 2 - 4)
#> [1] "B"
#> 
#> [[3]] (interval 4 - 5)
#> [1] "C"
peek_all_containing(ix, start = 2, end = 3)
#> Unnamed interval_index with 2 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "A"
#> 
#> [[2]] (interval 2 - 4)
#> [1] "B"
peek_all_point(ix, point = 3, match_at = "end")
#> Unnamed interval_index with 1 element, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "A"
```

Endpoint extrema and merge:

``` r

min_endpoint(ix); max_endpoint(ix)
#> [1] 1
#> [1] 5
merge(ix, interval_index("D", start = 6, end = 8))
#> Unnamed interval_index with 4 elements, default query bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> [[1]] (interval 1 - 3)
#> [1] "A"
#> 
#> [[2]] (interval 2 - 4)
#> [1] "B"
#> 
#> [[3]] (interval 4 - 5)
#> [1] "C"
#> 
#> [[4]] (interval 6 - 8)
#> [1] "D"
```

### developer API

Define a custom monoid (here, a running sum) and attach it to any
structure:

``` r

sum_monoid <- measure_monoid(f = `+`, i = 0, measure = function(el) el)
x <- as_flexseq(c(3, 1, 4, 1, 5, 9, 2, 6)) |>
  add_monoids(list(sum = sum_monoid))
get_measure(x, "sum")
#> [1] 31
```

Use a monotonic predicate over the cached measure for $`O(\log n)`$
locate and split:

``` r

locate_by_predicate(x, function(v) v > 10, "sum")
#> $found
#> [1] TRUE
#> 
#> $value
#> [1] 5
split_around_by_predicate(x, function(v) v > 10, "sum")$value
#> [1] 5
validate_tree(x)
```
