# Flexible Sequences: Persistent Lists, Deques, and Slicing

## `flexseq` basics

`flexseq` is a persistent sequence type, with many of the same features
as an R [`list()`](https://rdrr.io/r/base/list.html), including storing
arbitrary items. All updates return a new object and keep the original
unchanged.

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

x2 <- as_flexseq(letters[1:5])
x2
#> Unnamed flexseq with 5 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "b"
#> 
#> ... (skipping 1 element)
#> 
#> [[4]]
#> [1] "d"
#> 
#> [[5]]
#> [1] "e"
```

## Names and indexing

Flexseqs may be named, but if any are named they must all have unique
non-`NULL` names. Large named flexseqs are somewhat slower than unnamed
ones; for efficient key/value stores consider using an
[`ordered_sequence()`](https://oneilsh.github.io/Immutables/reference/ordered_sequence.md).

``` r

x <- flexseq(a = 1, b = 2, c = 3)
x
#> Named flexseq with 3 elements.
#> 
#> Elements:
#> 
#> $a
#> [1] 1
#> 
#> $b
#> [1] 2
#> 
#> $c
#> [1] 3
x[c("c", "b")]
#> Named flexseq with 2 elements.
#> 
#> Elements:
#> 
#> $c
#> [1] 3
#> 
#> $b
#> [1] 2

x$b <- NULL # delete b
x
#> Named flexseq with 2 elements.
#> 
#> Elements:
#> 
#> $a
#> [1] 1
#> 
#> $c
#> [1] 3
```

In general indexing and slicing works as it does with lists: `[]`
returns a sublist indexed by integer (by position), character vector (by
name if named), or logical vector (by inclusion). Note that these
operations are $`O(k\log n)`$ where $`k`$ is the length of the indexing
vector.

``` r

x <- as_flexseq(letters[1:6])

x[[3]]
#> [1] "c"

x[c(1, 3, 5)]
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "c"
#> 
#> [[3]]
#> [1] "e"
```

## End operations

Flexseqs support pushing new elements onto the front or back of the
sequences, peeking at the front or back (i.e., getting a copy of the
first or last item), and popping from the front or back, which returns
the removed element and a copy of the flexseq input with that item
removed.
[`pop_front()`](https://oneilsh.github.io/Immutables/reference/pop_front.md)
and
[`pop_back()`](https://oneilsh.github.io/Immutables/reference/pop_back.md)
both return a list with fields `$value` and `$remaining`;
[`peek_back()`](https://oneilsh.github.io/Immutables/reference/peek_back.md)
is the symmetric counterpart to
[`peek_front()`](https://oneilsh.github.io/Immutables/reference/peek_front.md).

``` r

x <- as_flexseq(4:6)

x <- x |>
  push_back(100) |>
  push_front(50)

x
#> Unnamed flexseq with 5 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 50
#> 
#> [[2]]
#> [1] 4
#> 
#> ... (skipping 1 element)
#> 
#> [[4]]
#> [1] 6
#> 
#> [[5]]
#> [1] 100

xpopped <- pop_front(x)

xpopped$value
#> [1] 50
xpopped$remaining
#> Unnamed flexseq with 4 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 4
#> 
#> [[2]]
#> [1] 5
#> 
#> [[3]]
#> [1] 6
#> 
#> [[4]]
#> [1] 100
```

## Positional operations

Beyond the ends, flexseqs support arbitrary-position persistent
operations.
[`peek_at()`](https://oneilsh.github.io/Immutables/reference/peek_at.md)
is the non-throwing positional read (compare with `[[`, which errors
when out of bounds);
[`pop_at()`](https://oneilsh.github.io/Immutables/reference/pop_at.md)
removes an element at a given index and returns `$value`/`$remaining`;
[`insert_at()`](https://oneilsh.github.io/Immutables/reference/insert_at.md)
inserts before a given index, or at `length(x) + 1` to append.

``` r

x <- flexseq("a", "b", "c", "d")

peek_at(x, 10)  # NULL, no error
#> NULL

out <- pop_at(x, 2)
out$value
#> [1] "b"
out$remaining
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "c"
#> 
#> [[3]]
#> [1] "d"

insert_at(x, 3, c("x", "y"))
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

## Transforming and combining

[`c()`](https://rdrr.io/r/base/c.html) concatenates flexseqs, and
[`fapply()`](https://oneilsh.github.io/Immutables/reference/fapply.md)
applies a function to each element of one returning the result as a
flexseq, analygous to [`lapply()`](https://rdrr.io/r/base/lapply.html)
for R lists.

``` r

x <- as_flexseq(4:6)
x2 <- as_flexseq(8:10)

c(x, x2)
#> Unnamed flexseq with 6 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 4
#> 
#> [[2]]
#> [1] 5
#> 
#> ... (skipping 2 elements)
#> 
#> [[5]]
#> [1] 9
#> 
#> [[6]]
#> [1] 10

x <- as_flexseq(1:3)
fapply(x, function(el) el * 10)
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 10
#> 
#> [[2]]
#> [1] 20
#> 
#> [[3]]
#> [1] 30
```

`merge(x, y)` is provided as an alias for `c(x, y)` so that
[`merge()`](https://rdrr.io/r/base/merge.html) works uniformly across
the package’s four structure types. For `flexseq`,
[`c()`](https://rdrr.io/r/base/c.html) and
[`merge()`](https://rdrr.io/r/base/merge.html) are equivalent; the
distinction matters for `ordered_sequence`, `interval_index`, and
`priority_queue`, where [`merge()`](https://rdrr.io/r/base/merge.html)
performs a proper sorted/priority-aware combine.

[`loop()`](https://oneilsh.github.io/Immutables/reference/loop.md)
(re-exported from the **coro** package) enables `for`-loop traversal,
yielding elements left-to-right lazily without materializing a list.

``` r

x <- flexseq("a", "b", "c", "d")

loop(for (el in x) {
  print(el)
})
#> [1] "a"
#> [1] "b"
#> [1] "c"
#> [1] "d"
```

For named flexseqs,
[`loop()`](https://oneilsh.github.io/Immutables/reference/loop.md)
yields bare values (matching
[`peek_front()`](https://oneilsh.github.io/Immutables/reference/peek_front.md));
use [`as.list()`](https://rdrr.io/r/base/list.html) when you need names
alongside values.

``` r

x <- flexseq(a = 1, b = 2, c = 3)
loop(for (el in x) print(el))
#> [1] 1
#> [1] 2
#> [1] 3
```

Plain `for (el in x)` (without
[`loop()`](https://oneilsh.github.io/Immutables/reference/loop.md)) does
*not* dispatch to the iteration protocol — it walks the underlying
finger-tree storage and yields internal nodes rather than sequence
elements. Always wrap with
[`loop()`](https://oneilsh.github.io/Immutables/reference/loop.md).

Flexseqs convert back to standard R structures with
[`as.list()`](https://rdrr.io/r/base/list.html) (preserves names and
list semantics) and [`unlist()`](https://rdrr.io/r/base/unlist.html)
(atomic vector when possible).
[`length()`](https://rdrr.io/r/base/length.html) returns the element
count in O(1), and [`str()`](https://rdrr.io/r/utils/str.html) gives a
compact diagnostic display.

``` r

x <- flexseq(a = 1, b = 2, c = 3)

as.list(x)
#> $a
#> [1] 1
#> 
#> $b
#> [1] 2
#> 
#> $c
#> [1] 3
unlist(x)
#> a b c 
#> 1 2 3
length(x)
#> [1] 3
```

## Example: simulating complex queueing systems

Queueing systems represent one or more service queues, where arrival and
service times are typically drawn from defined distributions such as the
exponential. The dynamics of such systems are a common area of study,
for example in computing average wait times. While in many cases
closed-form solutions for these dynamics exist, simple policy choices
such as “each request joins the currently shortest queue” can complicate
analyses significantly. In this example we simulate such a system to
generate an empirical wait-time distribution.

We simulate `steps` time steps; at each, a new request arrives with
probability `p_arrival` and joins the shorter of two queues, `qa` or
`qb`. We keep track of each server’s next free time step, processing
requests from the front of its queue. Each request’s wait time is
calculated and collected in a running `flexseq`, which we convert to a
vector and summarize after.

``` r

set.seed(100)
steps <- 1000
p_arrival <- 0.9
mean_service <- 1 # service times ~ rpois(1, mean_service) + 1 (real mean 2)

qa <- flexseq(); free_a <- 0
qb <- flexseq(); free_b <- 0
waits <- flexseq()

for(t in seq_len(steps)) {
  # process new arrivals into the shorter queue
  if(runif(1) < p_arrival) {
    request <- list(arrival = t)
    if(length(qa) <= length(qb)) qa <- push_back(qa, request)
    else                         qb <- push_back(qb, request)
  }

  # if qa is free, process the front request and record total wait time
  if(free_a <= t && length(qa) > 0) {
    nxt <- pop_front(qa)
    qa <- nxt$remaining    # overwrite queue with remaining portion
    request <- nxt$value
    waits <- push_back(waits, t - request$arrival)
    free_a <- t + rpois(1, mean_service) + 1
  }

  # if qb is free, process the front request and record total wait time
  if(free_b <= t && length(qb) > 0) {
    nxt <- pop_front(qb)
    qb <- nxt$remaining    # overwrite queue with remaining portion
    request <- nxt$value
    waits <- push_back(waits, t - request$arrival)
    free_b <- t + rpois(1, mean_service) + 1
  }
}

mean(unlist(waits))
#> [1] 1.501116
```

This example may be extended in several ways, including tracking queue
lengths, requests that migrate between queues (as in queueing networks),
or other policies such as length-weighted random queue assignment.
