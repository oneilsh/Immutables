# Indexing for Interval Indexes

Read indexing returns `interval_index` subsets while preserving
interval/key order; out-of-order selectors are canonicalized with a
warning. Replacement indexing is blocked.

## Usage

``` r
# S3 method for class 'interval_index'
x[i, ...]

# S3 method for class 'interval_index'
x[[i, ...]]

# S3 method for class 'interval_index'
x[i] <- value

# S3 method for class 'interval_index'
x[[i]] <- value

# S3 method for class 'interval_index'
x$name

# S3 method for class 'interval_index'
x$name <- value
```

## Arguments

- x:

  An `interval_index`.

- i:

  Index input.

- ...:

  Unused.

- value:

  Replacement value (unsupported).

- name:

  Element name (for `$` and `$<-`).

## Value

Read methods return interval payload values/subsets; replacement forms
always error.

For `$`: the matched payload element.

No return value; always errors because replacement indexing is
unsupported.

## Details

Read indexing preserves canonical interval order in returned subsets.

- Integer/character vectors are treated as selectors and canonicalized
  to interval-order output.

- Out-of-order selector vectors trigger a warning and are canonicalized.

- Duplicate selectors are rejected.

- `[[` and `$` return payload values.

- Replacement indexing (`[<-`, `[[<-`, `$<-`) is unsupported.

## Examples

``` r
ix <- interval_index(a = "A", b = "B", c = "C", start = c(1, 3, 5), end = c(2, 4, 6))

ix[c(3, 1)]         # warning; result returned in interval order
#> Warning: Ordered subsetting canonicalizes selector order; pre-sort and unique selectors to silence this warning.
#> Named interval_index with 2 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> $a (interval [1, 2))
#> [1] "A"
#> 
#> $c (interval [5, 6))
#> [1] "C"
#> 
ix[c("c", "a")]     # warning; result returned in interval order
#> Warning: Ordered subsetting canonicalizes selector order; pre-sort and unique selectors to silence this warning.
#> Named interval_index with 2 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> $a (interval [1, 2))
#> [1] "A"
#> 
#> $c (interval [5, 6))
#> [1] "C"
#> 
ix[c(TRUE, FALSE, TRUE)]
#> Named interval_index with 2 elements, default bounds [start, end).
#> 
#> Elements (by interval start order):
#> 
#> $a (interval [1, 2))
#> [1] "A"
#> 
#> $c (interval [5, 6))
#> [1] "C"
#> 
ix[["b"]]
#> [1] "B"
ix$b
#> [1] "B"

try(ix[c(2, 2)])
#> Error in .ord_normalize_selector_positions(idx) : 
#>   Ordered subsetting does not allow duplicate indices.
try(ix$b <- "updated")
#> Error in `$<-.interval_index`(`*tmp*`, b, value = "updated") : 
#>   `$<-` is not supported for interval_index.
```
