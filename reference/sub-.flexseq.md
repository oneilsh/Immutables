# Flexseq Indexing

Index, replace, and extract elements of a `flexseq` by position or name.

## Usage

``` r
# S3 method for class 'flexseq'
x$name

# S3 method for class 'flexseq'
x$name <- value

# S3 method for class 'flexseq'
x[i, ...]

# S3 method for class 'flexseq'
x[[i, ...]]

# S3 method for class 'flexseq'
x[i] <- value

# S3 method for class 'flexseq'
x[[i]] <- value
```

## Arguments

- x:

  A `flexseq`.

- name:

  Element name (for `$` and `$<-`).

- value:

  Replacement values; recycled to selected index length.

- i:

  Positive integer indices, character element names, or logical mask.
  For `[[`, a single integer or character name.

- ...:

  Unused.

## Value

For `$`: the matched element.

For `$<-`: updated tree with one named element replaced.

For `[`: a new `flexseq` containing selected elements in query order.
For character indexing, missing names are represented as `NULL`
elements.

For `[[`: the extracted element (internal name metadata is removed).

For `[<-`: a new `flexseq` with selected elements replaced.

For `[[<-`: a new `flexseq` with one element replaced.

## Details

Selector behavior:

- Integer indexing (`[`) returns elements in the requested order.

- Character indexing (`[`) returns elements in requested name order;
  unknown names become `NULL` elements in the output.

- Logical indexing (`[`) is positional and follows logical-mask
  selection.

Replacement behavior:

- `[<-` is persistent and recycles `value` to the number of selected
  positions (with standard R recycling warnings where applicable).

- `[[<-` replaces one element; assigning `NULL` removes that element.

## Examples

``` r
# $ extracts by name
x <- as_flexseq(setNames(as.list(1:3), c("a", "b", "c")))
x$b
#> [1] 2

# $<- replaces by name
x <- as_flexseq(setNames(as.list(1:3), c("a", "b", "c")))
x$b <- 20
x$b
#> [1] 20
x <- as_flexseq(letters[1:6])
x
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
#> [1] "e"
#> 
#> [[6]]
#> [1] "f"
#> 

x2 <- x[c(2, 4, 6)]
x2
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "d"
#> 
#> [[3]]
#> [1] "f"
#> 

# named lookups return NULL for missing names
x3 <- as_flexseq(setNames(as.list(letters[1:4]), c("w", "x", "y", "z")))
x4 <- x3[c("y", "missing", "w")]
x4
#> Unnamed flexseq with 3 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "c"
#> 
#> [[2]]
#> NULL
#> 
#> [[3]]
#> [1] "a"
#> 

# logical indexing supports recycling
x[c(TRUE, FALSE)]
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
#> 

# [[ extracts one element
x <- as_flexseq(letters[1:5])
x[[3]]
#> [1] "c"

x2 <- as_flexseq(setNames(as.list(letters[1:3]), c("a1", "a2", "a3")))
x2[["a2"]]
#> [1] "b"

# [<- replaces selected elements
x <- as_flexseq(1:6)
x
#> Unnamed flexseq with 6 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> ... (skipping 2 elements)
#> 
#> [[5]]
#> [1] 5
#> 
#> [[6]]
#> [1] 6
#> 

x2 <- x
x2[c(2, 5)] <- list(20, 50)
x2
#> Unnamed flexseq with 6 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 20
#> 
#> ... (skipping 2 elements)
#> 
#> [[5]]
#> [1] 50
#> 
#> [[6]]
#> [1] 6
#> 

# character replacement uses element names
x3 <- as_flexseq(setNames(as.list(1:4), c("a", "b", "c", "d")))
x3[c("d", "a")] <- list(40, 10)
x3
#> Named flexseq with 4 elements.
#> 
#> Elements:
#> 
#> $a
#> [1] 10
#> 
#> $b
#> [1] 2
#> 
#> $c
#> [1] 3
#> 
#> $d
#> [1] 40
#> 

# logical replacement supports recycling
x4 <- x
x4[c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE)] <- list(1)
x4
#> Unnamed flexseq with 6 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 1
#> 
#> [[2]]
#> [1] 2
#> 
#> ... (skipping 2 elements)
#> 
#> [[5]]
#> [1] 1
#> 
#> [[6]]
#> [1] 6
#> 

# [[<- replaces one element
x <- as_flexseq(letters[1:4])
x2 <- x
x2[[2]] <- "ZZ"
x2
#> Unnamed flexseq with 4 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "a"
#> 
#> [[2]]
#> [1] "ZZ"
#> 
#> [[3]]
#> [1] "c"
#> 
#> [[4]]
#> [1] "d"
#> 

x3 <- as_flexseq(setNames(as.list(1:3), c("x", "y", "z")))
x3[["y"]] <- 99
x3
#> Named flexseq with 3 elements.
#> 
#> Elements:
#> 
#> $x
#> [1] 1
#> 
#> $y
#> [1] 99
#> 
#> $z
#> [1] 3
#> 

# assigning NULL removes one element
x4 <- as_flexseq(letters[1:4])
x4[[2]] <- NULL
x4
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
#> 
```
