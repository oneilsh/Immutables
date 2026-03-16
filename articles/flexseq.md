# flexseq

## What is a flexseq?

`flexseq` is a persistent sequence type. All updates return a new object
and keep the original unchanged.

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

## End operations

``` r
x3 <- push_back(x2, "f")
x3
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

x4 <- push_front(x3, "start")
x4
#> Unnamed flexseq with 7 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "start"
#> 
#> [[2]]
#> [1] "a"
#> 
#> ... (skipping 3 elements)
#> 
#> [[6]]
#> [1] "e"
#> 
#> [[7]]
#> [1] "f"
```

``` r
peek_front(x4)
#> [1] "start"
peek_back(x4)
#> [1] "f"

pf <- pop_front(x4)
pf$value
#> [1] "start"
pf$remaining
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
```

## Indexing and slicing

``` r
x2[[3]]
#> [1] "c"

x5 <- x2[c(1, 3, 5)]
x5
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

## Names

``` r
x_named <- as_flexseq(list(a = 1, b = 2, c = 3))
x_named
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

x_named[["b"]]
#> [1] 2
x_named$c
#> [1] 3
```

## Transforming and combining

``` r
x6 <- as_flexseq(4:6)
x7 <- c(x, x6)  # c() is supported for flexseq
x7
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

x8 <- as_flexseq(1:5)
fapply(x8, function(el) el * 10)
#> Unnamed flexseq with 5 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] 10
#> 
#> [[2]]
#> [1] 20
#> 
#> ... (skipping 1 element)
#> 
#> [[4]]
#> [1] 40
#> 
#> [[5]]
#> [1] 50
```

## Persistence recap

``` r
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
x4
#> Unnamed flexseq with 7 elements.
#> 
#> Elements:
#> 
#> [[1]]
#> [1] "start"
#> 
#> [[2]]
#> [1] "a"
#> 
#> ... (skipping 3 elements)
#> 
#> [[6]]
#> [1] "e"
#> 
#> [[7]]
#> [1] "f"
```
