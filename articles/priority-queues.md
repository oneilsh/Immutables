# Priority Queues

## Priority queue basics

`priority_queue` is a persistent structure that associates elements with
priority values, typically numeric or character (string). They provide
fast access to elements by min or max priority, and insertion of new
elements with given priorities.

All operations are persistent, and return modified copies. Peeking at
the min/max returns the stored element (which may be any type), popping
returns a list with `$value` containing the stored element, `$priority`
the priority, and `$remaining` the rest of the priority queue without
those elements.

``` r
x <- priority_queue("task_a", "task_b", "task_c", priorities = c(3, 1, 2))
x
#> Unnamed priority_queue with 3 elements.
#> Minimum priority: 1, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "task_b"
#> 
#> (priority 2)
#> [1] "task_c"
#> 
#> (priority 3)
#> [1] "task_a"

peek_min(x)
#> [1] "task_b"
res <- pop_max(x)

res$value
#> [1] "task_a"
res$priority
#> [1] 3
res$remaining
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: 1, Maximum priority: 2
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "task_b"
#> 
#> (priority 2)
#> [1] "task_c"
```

The
[`as_priority_queue()`](https://oneilsh.github.io/immutables/reference/as_priority_queue.md)
variant builds a queue from a vector or list of elements paired with a
priority vector. useful when priorities are already in a separate
vector.

``` r
q <- as_priority_queue(letters[1:4], priorities = c(3, 1, 2, 1))
q
#> Unnamed priority_queue with 4 elements.
#> Minimum priority: 1, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "b"
#> 
#> (priority 1)
#> [1] "d"
#> 
#> (priority 2)
#> [1] "c"
#> 
#> (priority 3)
#> [1] "a"
```

## Priority ties

In the case of multiple identical priorities, peek/pop for min/max
return a *single element*, in their original insertion order. Their
“all” counterparts (`peek_all_min`, `pop_all_max`, etc.) return two
priorities: in `$elements` the elements peeked/popped and in
`$remaining` the other elements. `peek_all_max` and `pop_all_max` behave
symmetrically on the maximum-priority tie run.

``` r
y <- priority_queue() |>
  insert("Jones", priority = "B") |>
  insert("Smith", priority = "A") |>
  insert("Adams", priority = "A")

peek_min(y)
#> [1] "Smith"
peek_all_min(y)
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: A, Maximum priority: A
#> 
#> Elements (by priority):
#> 
#> (priority A)
#> [1] "Smith"
#> 
#> (priority A)
#> [1] "Adams"

res1 <- pop_min(y)
res1$value
#> [1] "Smith"
res1$priority
#> [1] "A"
res1$remaining
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: A, Maximum priority: B
#> 
#> Elements (by priority):
#> 
#> (priority A)
#> [1] "Adams"
#> 
#> (priority B)
#> [1] "Jones"

res2 <- pop_all_min(y)

res2$elements
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: A, Maximum priority: A
#> 
#> Elements (by priority):
#> 
#> (priority A)
#> [1] "Smith"
#> 
#> (priority A)
#> [1] "Adams"
res2$remaining
#> Unnamed priority_queue with 1 element.
#> Minimum priority: B, Maximum priority: B
#> 
#> Elements (by priority):
#> 
#> (priority B)
#> [1] "Jones"
```

Priority queues can be converted to R lists with
[`as.list()`](https://rdrr.io/r/base/list.html). The `drop_meta`
parameter defaulting to `FALSE` controls whether priority values are
included.

``` r
as.list(res2$elements) |> str()
#> List of 2
#>  $ :List of 2
#>   ..$ value   : chr "Smith"
#>   ..$ priority: chr "A"
#>  $ :List of 2
#>   ..$ value   : chr "Adams"
#>   ..$ priority: chr "A"
as.list(res2$elements, drop_meta = TRUE) |> str()
#> List of 2
#>  $ : chr "Smith"
#>  $ : chr "Adams"
```

## Empty queues

Peek/pop helpers are non-throwing on empty queues,
[`length()`](https://rdrr.io/r/base/length.html) allows for empty
checking.

``` r
empty_q <- priority_queue()
length(empty_q)
#> [1] 0
peek_min(empty_q)
#> NULL
pop_min(empty_q)
#> $value
#> NULL
#> 
#> $priority
#> NULL
#> 
#> $remaining
#> Unnamed priority_queue with 0 elements.
```

## Priority values

[`min_priority()`](https://oneilsh.github.io/immutables/reference/min_priority.md)
and
[`max_priority()`](https://oneilsh.github.io/immutables/reference/max_priority.md)
return the current extrema *priority* (not the stored element), in O(1)
via cached monoid state.

``` r
q <- priority_queue("a", "b", "c", priorities = c(3, 1, 2))
min_priority(q)
#> [1] 1
max_priority(q)
#> [1] 3
min_priority(priority_queue())  # NULL when empty
#> NULL
```

## Named priorities

Priority queues can carry names, set either at construction or on
[`insert()`](https://oneilsh.github.io/immutables/reference/insert.md).
Names support read-only indexing via `[`, `[[`, and `$`. This is the
*only* indexing form `priority_queue` supports. Positional indexing and
all replacement forms (`[<-`, `[[<-`, `$<-`) error; cast to
[`as_flexseq()`](https://oneilsh.github.io/immutables/reference/as_flexseq.md)
first to mutate.

``` r
q <- priority_queue(a = "task-a", b = "task-b", priorities = c(2, 1)) |>
  insert("task-c", priority = 3, name = "c")

q[["b"]]
#> [1] "task-b"
q[c("a", "c")]
#> Named priority_queue with 2 elements.
#> Minimum priority: 2, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> $a (priority 2)
#> [1] "task-a"
#> 
#> $c (priority 3)
#> [1] "task-c"

try(q[1])         # positional indexing blocked
#> Error in `[.priority_queue`(q, 1) : 
#>   `[.priority_queue` supports character name indexing only. Cast first with `as_flexseq()`.
try(q$a <- "!!")  # replacement blocked
#> Error in `$<-.priority_queue`(`*tmp*`, a, value = "!!") : 
#>   `$<-` is not supported for priority_queue. Cast first with `as_flexseq()`.
```

## Transforming, iterating, merging

[`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md)
maps a function over queue elements while preserving priorities. The
function receives `(value, priority)`, or `(value, priority, name)` if
it accepts a third argument — priorities and names are passed in
read-only, and the return value replaces the stored element.

``` r
q <- priority_queue("alice", "bob", "carol", priorities = c(3, 1, 2))
fapply(q, function(value, priority) toupper(value))
#> Unnamed priority_queue with 3 elements.
#> Minimum priority: 1, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "BOB"
#> 
#> (priority 2)
#> [1] "CAROL"
#> 
#> (priority 3)
#> [1] "ALICE"
```

[`loop()`](https://oneilsh.github.io/immutables/reference/loop.md)
(re-exported from the **coro** package) walks the queue in
priority-ascending order, yielding bare values. Traversal is driven by
repeated
[`pop_min()`](https://oneilsh.github.io/immutables/reference/pop_min.md),
so full traversal is $O\left( n\log n \right)$ ($O\left( \log n \right)$
per step); ties within equal priority follow insertion order.

``` r
q <- priority_queue("task_a", "task_b", "task_c", priorities = c(3, 1, 2))
loop(for (v in q) print(v))
#> [1] "task_b"
#> [1] "task_c"
#> [1] "task_a"
```

Use
[`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md)
if your callback needs the priority alongside the value, or cast with
[`as_flexseq()`](https://oneilsh.github.io/immutables/reference/as_flexseq.md)
for insertion-order iteration. Plain `for (v in q)` (without
[`loop()`](https://oneilsh.github.io/immutables/reference/loop.md))
yields raw finger-tree internals rather than elements — always wrap with
[`loop()`](https://oneilsh.github.io/immutables/reference/loop.md).

`merge(x, y)` combines two priority queues into a new one containing
every entry from both, in O(log(min(m, n))). The `.pq_min` / `.pq_max`
monoids recompute automatically on the merged tree, so extremum queries
work immediately on the result.

``` r
a <- priority_queue("x", "y", priorities = c(5, 1))
b <- priority_queue("z", priorities = 3)
m <- merge(a, b)
length(m)
#> [1] 3
peek_min(m)
#> [1] "y"
peek_max(m)
#> [1] "x"
```

Both queues must share the same priority type and monoid set; mismatches
error (rather than being silently harmonized). Both inputs are left
unmodified.

For full sequence-style operations, cast with
[`as_flexseq()`](https://oneilsh.github.io/immutables/reference/as_flexseq.md).
This returns payload items only; priority metadata and any custom
monoids are dropped. To instead obtain a `flexseq` of entry records
(`value` + `priority`), compose with
[`as.list()`](https://rdrr.io/r/base/list.html).

``` r
y <- priority_queue() |>
  insert("Jones", priority = "B") |>
  insert("Smith", priority = "A") |>
  insert("Adams", priority = "A")

as_flexseq(y)
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "Jones"
#> 
#> [[2]]
#> [1] "Smith"
#> 
#> [[3]]
#> [1] "Adams"
as_flexseq(as.list(y))
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> $value
#> [1] "Jones"
#> 
#> $priority
#> [1] "B"
#> 
#> 
#> [[2]]
#> $value
#> [1] "Smith"
#> 
#> $priority
#> [1] "A"
#> 
#> 
#> [[3]]
#> $value
#> [1] "Adams"
#> 
#> $priority
#> [1] "A"
```
