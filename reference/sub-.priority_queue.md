# Indexing for Priority Queues

Name-based indexing is supported for reads only. Positional indexing and
all replacement indexing are intentionally blocked to preserve
queue-first UX.

## Usage

``` r
# S3 method for class 'priority_queue'
x[i, ...]

# S3 method for class 'priority_queue'
x[[i, ...]]

# S3 method for class 'priority_queue'
x[i] <- value

# S3 method for class 'priority_queue'
x[[i]] <- value

# S3 method for class 'priority_queue'
x$name

# S3 method for class 'priority_queue'
x$name <- value
```

## Arguments

- x:

  A `priority_queue`.

- i:

  Index input. For reads, must be a character name (scalar for `[[`).

- ...:

  Unused.

- value:

  Replacement value (unsupported).

- name:

  Element name (for `$` and `$<-`).

## Value

For `$`/`[[`/`[`: queue payload values or queue subsets by name.
Replacement forms always error.

## Details

`priority_queue` supports name-based read indexing only.

- `[`: character vector of names, returns a `priority_queue` subset.

- `[[` and `$`: scalar name, return the payload value.

- Positional indexing and all replacement indexing forms are
  unsupported.

## Examples

``` r
q <- priority_queue(a = "task-a", b = "task-b", priorities = c(2, 1))

q["a"]
#> Named priority_queue with 1 element.
#> Minimum priority: 2, Maximum priority: 2
#> 
#> Elements (by priority):
#> 
#> $a (priority 2)
#> [1] "task-a"
#> 
q[["b"]]
#> [1] "task-b"
q$b
#> [1] "task-b"

try(q[1])
#> Error in `[.priority_queue`(q, 1) : 
#>   `[.priority_queue` supports character name indexing only. Cast first with `as_flexseq()`.
try(q$a <- "updated")
#> Error in `$<-.priority_queue`(`*tmp*`, a, value = "updated") : 
#>   `$<-` is not supported for priority_queue. Cast first with `as_flexseq()`.
```
