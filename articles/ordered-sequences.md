# Ordered Sequences: Key-Sorted Storage with Range Queries

## Ordered sequence basics

`ordered_sequence` is a persistent structure that associates elements
with keys, typically numeric or character (string). They store elements
sorted by key, with stable first-in-first-out (FIFO) behavior for
duplicate keys, and provide fast key-based lookup, range queries over
keys, and insertion.

All operations are persistent, and return modified copies. Peeking by
key returns the stored element (which may be any type), popping returns
a list with `$value` containing the stored element, `$key` the key, and
`$remaining` the rest of the sequence without that element.

``` r

xs <- ordered_sequence("a1", "b1", "b2", "c1", keys = c(1, 2, 2, 3))
xs
#> Unnamed ordered_sequence with 4 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a1"
#> 
#> [[2]] (key 2)
#> [1] "b1"
#> 
#> [[3]] (key 2)
#> [1] "b2"
#> 
#> [[4]] (key 3)
#> [1] "c1"
```

The
[`as_ordered_sequence()`](https://oneilsh.github.io/Immutables/reference/as_ordered_sequence.md)
variant builds a sequence from a vector or list of elements paired with
a key vector, useful when keys are already in a separate vector.

``` r

xs2 <- as_ordered_sequence(c(3, 1, 2, 1), keys = letters[1:4])
xs2
#> Unnamed ordered_sequence with 4 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key a)
#> [1] 3
#> 
#> [[2]] (key b)
#> [1] 1
#> 
#> [[3]] (key c)
#> [1] 2
#> 
#> [[4]] (key d)
#> [1] 1
```

`as_flexseq(xs)` returns a payload-only `flexseq`; keys and any custom
monoids are dropped (see `as.list` to convert and preservekey metadata).

## Peek, pop, insert, and range query by key

Insertion is by key, and *keys may be duplicated*.

``` r

seq <- as_ordered_sequence(1:3, keys = letters[1:3])
seq2 <- insert(seq, 10, key = "b")
seq2
#> Unnamed ordered_sequence with 4 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key a)
#> [1] 1
#> 
#> [[2]] (key b)
#> [1] 2
#> 
#> [[3]] (key b)
#> [1] 10
#> 
#> [[4]] (key c)
#> [1] 3
```

[`pop_key()`](https://oneilsh.github.io/Immutables/reference/pop_key.md)
removes and returns the first match for a key as
`$value`/`$key`/`$remaining`. Its “all” counterpart
[`pop_all_key()`](https://oneilsh.github.io/Immutables/reference/pop_all_key.md)
removes the entire tie run for that key, returning `$elements` (an
ordered sequence of removed matches) and `$remaining`.

``` r

one <- pop_key(seq, key = "b")
one$value
#> [1] 2
one$key
#> [1] "b"
one$remaining
#> Unnamed ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key a)
#> [1] 1
#> 
#> [[2]] (key c)
#> [1] 3

all_two <- pop_all_key(seq, "b")
all_two$elements
#> Unnamed ordered_sequence with 1 element.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key b)
#> [1] 2
all_two$remaining
#> Unnamed ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key a)
#> [1] 1
#> 
#> [[2]] (key c)
#> [1] 3
```

Keys may be counted, and elements accessed;
[`peek_key()`](https://oneilsh.github.io/Immutables/reference/peek_key.md)
returns one element, the first in insertion order.
[`peek_all_key()`](https://oneilsh.github.io/Immutables/reference/peek_all_key.md)
returns an ordered sequence with all matching keys.

``` r

count_key(seq, key = "b")
#> [1] 1
peek_key(seq, key = "b")
#> [1] 2
peek_all_key(seq, key = "b")
#> Unnamed ordered_sequence with 1 element.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key b)
#> [1] 2
```

Counting and accessing elements over query ranges support
inclusive/exclusive on both sides (defaulting to `TRUE`).

``` r

elements_between(seq, from_key = "b", to_key ="c", include_from = TRUE, include_to = TRUE)
#> Unnamed ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key b)
#> [1] 2
#> 
#> [[2]] (key c)
#> [1] 3
count_between(seq, from_key = "b", to_key = "c", include_from = TRUE, include_to = TRUE)
#> [1] 2

# exclude "b" keys
elements_between(seq, from_key = "b", to_key ="c", include_from = FALSE, include_to = TRUE)
#> Unnamed ordered_sequence with 1 element.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key c)
#> [1] 3
```

## Key boundaries, and extrema

[`lower_bound()`](https://oneilsh.github.io/Immutables/reference/lower_bound.md)
finds the first element with key `>=` a query key;
[`upper_bound()`](https://oneilsh.github.io/Immutables/reference/upper_bound.md)
finds the first with key strictly `>`. Both return a list with `$found`,
`$index`, `$value`, and `$key` (`NULL` fields when no match exists).
Together they support successor queries (“find the nearest entry at or
above this key”) and duplicate counting via index arithmetic.

``` r

seq <- as_ordered_sequence(1:4, keys = c("b", "d", "d", "f"))

lower_bound(seq, key = "d") |> str()
#> List of 4
#>  $ found: logi TRUE
#>  $ index: int 2
#>  $ value: int 2
#>  $ key  : chr "d"
upper_bound(seq, key = "d") |> str()
#> List of 4
#>  $ found: logi TRUE
#>  $ index: int 4
#>  $ value: int 4
#>  $ key  : chr "f"
```

When the query key falls between or outside existing keys,
[`lower_bound()`](https://oneilsh.github.io/Immutables/reference/lower_bound.md)
returns the next entry at or above, useful for nearest-match lookups.
Both return `found = FALSE` when no keys satisfy the condition.

``` r

lower_bound(seq, key = "a") |> str()
#> List of 4
#>  $ found: logi TRUE
#>  $ index: int 1
#>  $ value: int 1
#>  $ key  : chr "b"

upper_bound(seq, key = "g") |> str()
#> List of 4
#>  $ found: logi FALSE
#>  $ index: NULL
#>  $ value: NULL
#>  $ key  : NULL
```

The difference `upper_bound(x, k)$index - lower_bound(x, k)$index` gives
the count of entries with key `k` (this is what
[`count_key()`](https://oneilsh.github.io/Immutables/reference/count_key.md)
does internally).

``` r

upper_bound(seq, key = "d")$index - lower_bound(seq, key = "d")$index
#> [1] 2
count_key(seq, key = "d")
#> [1] 2
```

[`min_key()`](https://oneilsh.github.io/Immutables/reference/min_key.md)
and
[`max_key()`](https://oneilsh.github.io/Immutables/reference/max_key.md)
return the current minimum and maximum *keys* (not the stored elements).

``` r

min_key(xs)
#> [1] 1
max_key(xs)
#> [1] 3
min_key(ordered_sequence())  # NULL when empty
#> NULL
```

Because keys are stored in sorted order, ordered sequences also support
the positional operators inherited from `flexseq` —
[`peek_at()`](https://oneilsh.github.io/Immutables/reference/peek_at.md),
[`pop_front()`](https://oneilsh.github.io/Immutables/reference/pop_front.md),
[`pop_back()`](https://oneilsh.github.io/Immutables/reference/pop_back.md),
and
[`pop_at()`](https://oneilsh.github.io/Immutables/reference/pop_at.md).
On an ordered sequence the pops additionally return `$key` (alongside
`$value`/`$remaining`), and
[`key_at()`](https://oneilsh.github.io/Immutables/reference/key_at.md)
reads the key at a one-based position without removing anything: the
positional companion to
[`peek_at()`](https://oneilsh.github.io/Immutables/reference/peek_at.md)
(which reads the value there) and the general form of
[`min_key()`](https://oneilsh.github.io/Immutables/reference/min_key.md)/[`max_key()`](https://oneilsh.github.io/Immutables/reference/max_key.md).

``` r

key_at(xs, 2)                          # key at position 2
#> [1] 2
key_at(xs, 1) == min_key(xs)           # first position holds the minimum key
#> [1] TRUE
key_at(xs, length(xs)) == max_key(xs)  # last position holds the maximum key
#> [1] TRUE
key_at(xs, 10)                         # NULL when out of bounds
#> NULL

front <- pop_front(xs)                 # positional pop carries the key too
front$value
#> [1] "a1"
front$key
#> [1] 1
```

[`nearest_key()`](https://oneilsh.github.io/Immutables/reference/nearest_key.md)
returns the existing key closest to a query, which then composes with
[`peek_key()`](https://oneilsh.github.io/Immutables/reference/peek_key.md)
/
[`pop_key()`](https://oneilsh.github.io/Immutables/reference/pop_key.md)
to read or remove the matching element. It resolves by order alone at
the extremes and on an exact hit, and only needs a distance metric when
the query falls strictly between two distinct keys — so it supports
`numeric`, `Date`, and `POSIXct` keys there. An equidistant tie between
two distinct keys is resolved by `ties` — `"lower"` (default),
`"upper"`, or `"both"` (returns both keys). For `character` keys the
between-case is undefined (“is `"Ben"` closer to `"Alex"` or
`"Charlie"`?”) and errors; use
[`lower_bound()`](https://oneilsh.github.io/Immutables/reference/lower_bound.md)
/
[`peek_key()`](https://oneilsh.github.io/Immutables/reference/peek_key.md)
for order-based lookup instead.

``` r

nearest_key(xs, 2.4)                    # between 2 and 3 -> closer key (2)
#> [1] 2
nearest_key(xs, 0)                      # below all -> min_key (1)
#> [1] 1
nearest_key(xs, 2.5, ties = "both")     # exactly between 2 and 3 -> c(2, 3)
#> [1] 2 3

k <- nearest_key(xs, 2.4)               # locate, then act with the keyed helpers
pop_key(xs, k)$value
#> [1] "b1"
```

## Empty sequences

Key and range helpers are non-throwing on empty sequences, and
[`length()`](https://rdrr.io/r/base/length.html) allows for empty
checking.

``` r

empty_os <- ordered_sequence()
length(empty_os)
#> [1] 0
peek_key(empty_os, 1)
#> NULL
count_between(empty_os, 1, 5)
#> [1] 0
```

## Named ordered sequences

Ordered sequences can carry names, set either at construction or through
[`as_ordered_sequence()`](https://oneilsh.github.io/Immutables/reference/as_ordered_sequence.md)
on a named list. Names and integer positions both support read-only
indexing via `[`, `[[`, and `$`. All replacement forms (`[<-`, `[[<-`,
`$<-`) error, because index-based assignment may break the ordering
invariant. Ordered sequences may be cast down with
[`as_flexseq()`](https://oneilsh.github.io/Immutables/reference/as_flexseq.md)
or [`as.list()`](https://rdrr.io/r/base/list.html). Named and unnamed
elements cannot be mixed within one sequence.

``` r

xs_named <- as_ordered_sequence(
  setNames(list("alice", "bob", "carol"), c("a", "b", "c")),
  keys = c(3, 1, 2)
)
xs_named
#> Named ordered_sequence with 3 elements.
#> 
#> Elements (by key order):
#> 
#> $b (key 1)
#> [1] "bob"
#> 
#> $c (key 2)
#> [1] "carol"
#> 
#> $a (key 3)
#> [1] "alice"

xs_named[["b"]]
#> [1] "bob"
xs_named[c("a", "c")]
#> Warning: Ordered subsetting canonicalizes selector order; pre-sort and unique
#> selectors to silence this warning.
#> Named ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> $c (key 2)
#> [1] "carol"
#> 
#> $a (key 3)
#> [1] "alice"
xs_named[1]            # positional read also works
#> Named ordered_sequence with 1 element.
#> 
#> Elements (by key order):
#> 
#> $b (key 1)
#> [1] "bob"

try(xs_named$a <- "!!")  # replacement blocked
#> Error in .ft_stop_ordered_like(x, "$<-", "Replacement indexing is not supported. Consider converting with as_flexseq().") : 
#>   `$<-()` is not supported for ordered_sequence. Replacement indexing is not supported. Consider converting with as_flexseq().
```

## Transforming, iterating, merging

[`fapply()`](https://oneilsh.github.io/Immutables/reference/fapply.md)
maps a function over elements while preserving keys and order. The
function receives `(value, key)`, or `(value, key, name)` if it accepts
a third argument. Keys and names are passed in read-only, and the return
value replaces the stored element at the associated key (and name if
named).

``` r

xs_t <- ordered_sequence("alice", "bob", "carol", keys = c(3, 1, 2))
fapply(xs_t, function(value, key) toupper(value))
#> Unnamed ordered_sequence with 3 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "BOB"
#> 
#> [[2]] (key 2)
#> [1] "CAROL"
#> 
#> [[3]] (key 3)
#> [1] "ALICE"
```

[`loop()`](https://oneilsh.github.io/Immutables/reference/loop.md)
(re-exported from the **coro** package) walks the sequence in
key-ascending order, yielding bare values. Keys are dropped from each
yield; use
[`fapply()`](https://oneilsh.github.io/Immutables/reference/fapply.md)
if your callback needs the key alongside the value, or iterate over
[`as.list()`](https://rdrr.io/r/base/list.html) when you want a list
keyed by name.

``` r

loop(for (v in xs_t) print(v))
#> [1] "bob"
#> [1] "carol"
#> [1] "alice"
```

Plain `for (v in xs_t)` (without
[`loop()`](https://oneilsh.github.io/Immutables/reference/loop.md)) does
*not* dispatch to the iteration protocol, it walks the underlying
internal structure and yields those rather than sequence elements.
Always wrap with
[`loop()`](https://oneilsh.github.io/Immutables/reference/loop.md).

`merge(x, y)` combines two ordered sequences into a new one in key
order, preserving left-biased FIFO on duplicate keys (all of `x`’s
entries at a tied key precede `y`’s). The general case runs in O(m + n);
when the key ranges are disjoint it collapses to O(log(min(m, n))) via
concat.

``` r

a <- as_ordered_sequence(c("a1", "a2", "a3"), keys = c(1, 3, 5))
b <- as_ordered_sequence(c("b1", "b2", "b3"), keys = c(2, 3, 6))
merge(a, b)
#> Unnamed ordered_sequence with 6 elements.
#> 
#> Elements (by key order):
#> 
#> [[1]] (key 1)
#> [1] "a1"
#> 
#> [[2]] (key 2)
#> [1] "b1"
#> 
#> ... (skipping 2 elements)
#> 
#> [[5]] (key 5)
#> [1] "a3"
#> 
#> [[6]] (key 6)
#> [1] "b3"
```

Both sequences must share the same key type and monoid set; mismatches
error. Both inputs are left unmodified.

## Example: scalar matching without replacement

Many potential uses for ordered sequences are handled well by named
lists and vectors, where access-by-key is the primary functionality. In
some cases we need to dynamically find, add, and remove elements by key,
but as
[`vignette("benchmarks", package = "Immutables")`](https://oneilsh.github.io/Immutables/articles/benchmarks.md)
shows these operations are excessively slow on large base-R structures.
Matching without replacement is one such case, often employed for cohort
matching purposes in observational studies using propensity scores.
Foregoing details, “treated” patients are matched to a subset of
distinct “control” patients with similar scores. We start by simulating
some populations and scores, and initialize an empty `flexseq` to store
matches. We also convert the treated and untreated row numbers (serving
as identifiers) to ordered sequences, keyed by their score.

``` r

set.seed(100)
n_patients <- 200
patients <- data.frame(treated = sample(c(TRUE, FALSE),
                                        n_patients,
                                        prob = c(0.1, 0.9),
                                        replace = TRUE),
                       score = runif(n_patients))

# row numbers act as identifiers
treated_rows <- which(patients$treated)
treated_scores <- patients$score[patients$treated]

untreated_rows <- which(!patients$treated)
untreated_scores <- patients$score[!patients$treated]

matches <- flexseq()

treated_seq <- as_ordered_sequence(treated_rows, keys = treated_scores)
untreated_seq <- as_ordered_sequence(untreated_rows, keys = untreated_scores)
```

Matching itself is a simple greedy selection. Popping treated patients
in order, each is matched to their nearest untreated record by score
key, using
[`nearest_key()`](https://oneilsh.github.io/Immutables/reference/nearest_key.md).
That patient is popped from wherever it was located, and a data frame
describing the match is pushed onto the accumulating `flexseq`. This
example also illustrates collecting these into a single result data
frame for use after.

``` r

while(length(treated_seq) > 0) {
  # no untreated patients left to match against
  if (length(untreated_seq) == 0L) break

  # pop the first (lowest-score) treated patient
  front_el <- pop_front(treated_seq)
  treated_seq <- front_el$remaining

  treated_pt_score <- front_el$key
  treated_pt_row   <- front_el$value

  # find and remove the nearest-score untreated patient
  match_key <- nearest_key(untreated_seq, treated_pt_score)
  match_el  <- pop_key(untreated_seq, match_key)
  untreated_seq <- match_el$remaining

  untreated_pt_score <- match_el$key
  untreated_pt_row   <- match_el$value

  match_row <- data.frame(treated_pt_row,
                          treated_pt_score,
                          untreated_pt_row,
                          untreated_pt_score)

  matches <- push_back(matches, match_row)
}

match_df <- do.call(rbind, as.list(matches))
head(match_df)
#>   treated_pt_row treated_pt_score untreated_pt_row untreated_pt_score
#> 1             83       0.01631959              151         0.02058322
#> 2             74       0.11503942              161         0.10753897
#> 3             91       0.13271604               58         0.13250605
#> 4            177       0.13878037              197         0.13886056
#> 5            152       0.17096903               78         0.17104804
#> 6             63       0.19755671              184         0.19731313
```
