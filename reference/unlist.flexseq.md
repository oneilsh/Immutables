# Coerce a Sequence to an Atomic Vector

Convenience wrapper around
[`base::unlist()`](https://rdrr.io/r/base/unlist.html) over
[`as.list()`](https://rdrr.io/r/base/list.html).

## Usage

``` r
# S3 method for class 'flexseq'
unlist(x, recursive = TRUE, use.names = TRUE)
```

## Arguments

- x:

  A `flexseq`.

- recursive:

  Passed through to
  [`base::unlist()`](https://rdrr.io/r/base/unlist.html).

- use.names:

  Passed through to
  [`base::unlist()`](https://rdrr.io/r/base/unlist.html).

## Value

An atomic vector built from
[`as.list.flexseq()`](https://oneilsh.github.io/immutables/reference/as.list.flexseq.md).

## Details

For `priority_queue`, this unwraps queue entries to payload items before
unlisting (equivalent to `unlist(as.list(x, drop_meta = TRUE), ...)`).

Inherited by `ordered_sequence` and `interval_index` through the shared
class stack.

## Examples

``` r
x <- flexseq(1, 2, 3)
unlist(x)
#> [1] 1 2 3

q <- priority_queue("a", "b", priorities = c(2, 1))
unlist(q)
#> [1] "a" "b"
```
