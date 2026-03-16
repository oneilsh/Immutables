# Construct a Predicate Function

Construct a Predicate Function

## Usage

``` r
predicate(f)
```

## Arguments

- f:

  Predicate function over accumulated measure values.

## Value

The predicate function.

## Examples

``` r
p <- predicate(function(v) v >= 3)
p(2)
#> [1] FALSE
p(3)
#> [1] TRUE

x <- as_flexseq(letters[1:5])
locate_by_predicate(x, p, ".size")
#> $found
#> [1] TRUE
#> 
#> $value
#> [1] "c"
#> 
```
