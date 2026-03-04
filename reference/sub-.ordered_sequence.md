# Indexing for Ordered Sequences

Read indexing treats vectors as selectors and returns subsets in key
order. Out-of-order selectors are canonicalized with a warning.
Replacement indexing is blocked to prevent order-breaking writes.

## Usage

``` r
# S3 method for class 'ordered_sequence'
x[i, ...]

# S3 method for class 'ordered_sequence'
x[[i, ...]]

# S3 method for class 'ordered_sequence'
x[i] <- value

# S3 method for class 'ordered_sequence'
x[[i]] <- value

# S3 method for class 'ordered_sequence'
x$name

# S3 method for class 'ordered_sequence'
x$name <- value
```

## Arguments

- x:

  An `ordered_sequence`.

- i:

  Index input.

- ...:

  Unused.

- value:

  Replacement value (unsupported).

- name:

  Element name (for `$` and `$<-`).

## Value

Read methods return ordered payload values/subsets; replacement forms
always error.

## Details

Vector selectors are treated as membership selectors, not output-order
instructions.

- Integer/character vectors are normalized to unique positions and
  returned in canonical sequence order.

- Out-of-order selector vectors trigger a warning and are canonicalized.

- Duplicate selectors are rejected.

- Replacement indexing (`[<-`, `[[<-`, `$<-`) is unsupported.

## Examples

``` r
x <- ordered_sequence(a = "A", b = "B", c = "C", keys = c(1, 2, 3))

x[c(3, 1)]          # warning; result returned in key order
#> Warning: Ordered subsetting canonicalizes selector order; pre-sort and unique selectors to silence this warning.
#> Named ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> $a (key 1)
#> [1] "A"
#> 
#> $c (key 3)
#> [1] "C"
#> 
x[c("c", "a")]      # warning; result returned in key order
#> Warning: Ordered subsetting canonicalizes selector order; pre-sort and unique selectors to silence this warning.
#> Named ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> $a (key 1)
#> [1] "A"
#> 
#> $c (key 3)
#> [1] "C"
#> 
x[c(TRUE, FALSE, TRUE)]
#> Named ordered_sequence with 2 elements.
#> 
#> Elements (by key order):
#> 
#> $a (key 1)
#> [1] "A"
#> 
#> $c (key 3)
#> [1] "C"
#> 
x[["b"]]
#> [1] "B"
x$b
#> [1] "B"

try(x[c(2, 2)])
#> Error in .ord_normalize_selector_positions(idx) : 
#>   Ordered subsetting does not allow duplicate indices.
try(x$b <- "updated")
#> Error in .ft_stop_ordered_like(x, "$<-", "Replacement indexing is not supported. Consider converting with as_flexseq().") : 
#>   `$<-()` is not supported for ordered_sequence. Replacement indexing is not supported. Consider converting with as_flexseq().
```
