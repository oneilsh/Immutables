# Display Internal Structure of a flexseq

Display Internal Structure of a flexseq

## Usage

``` r
# S3 method for class 'flexseq'
str(object, ...)
```

## Arguments

- object:

  A `flexseq`.

- ...:

  Passed to [`utils::str()`](https://rdrr.io/r/utils/str.html).

## Value

`NULL`, invisibly.

## Examples

``` r
x <- flexseq(a = 1, b = list(k = 2))
str(x)
#> List of 3
#>  $ prefix:List of 1
#>   ..$ : num 1
#>   .. ..- attr(*, "ft_name")= chr "a"
#>   ..- attr(*, "class")= chr [1:2] "Digit" "list"
#>   ..- attr(*, "monoids")=List of 2
#>   .. ..$ .size       :List of 3
#>   .. .. ..$ f      :function (a, b)  
#>   .. .. ..$ i      : num 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   .. ..$ .named_count:List of 3
#>   .. .. ..$ f      :function (a, b)  
#>   .. .. ..$ i      : int 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   ..- attr(*, "measures")=List of 2
#>   .. ..$ .size       : num 1
#>   .. ..$ .named_count: int 1
#>  $ middle:List of 1
#>   ..$ : NULL
#>   ..- attr(*, "class")= chr [1:3] "Empty" "FingerTree" "list"
#>   ..- attr(*, "monoids")=List of 2
#>   .. ..$ .size       :List of 3
#>   .. .. ..$ f      :function (a, b)  
#>   .. .. ..$ i      : num 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   .. ..$ .named_count:List of 3
#>   .. .. ..$ f      :function (a, b)  
#>   .. .. ..$ i      : int 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   ..- attr(*, "measures")=List of 2
#>   .. ..$ .size       : num 0
#>   .. ..$ .named_count: int 0
#>  $ suffix:List of 1
#>   ..$ :List of 1
#>   .. ..$ k: num 2
#>   .. ..- attr(*, "ft_name")= chr "b"
#>   ..- attr(*, "class")= chr [1:2] "Digit" "list"
#>   ..- attr(*, "monoids")=List of 2
#>   .. ..$ .size       :List of 3
#>   .. .. ..$ f      :function (a, b)  
#>   .. .. ..$ i      : num 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   .. ..$ .named_count:List of 3
#>   .. .. ..$ f      :function (a, b)  
#>   .. .. ..$ i      : int 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   ..- attr(*, "measures")=List of 2
#>   .. ..$ .size       : num 1
#>   .. ..$ .named_count: int 1
#>  - attr(*, "monoids")=List of 2
#>   ..$ .size       :List of 3
#>   .. ..$ f      :function (a, b)  
#>   .. ..$ i      : num 0
#>   .. ..$ measure:function (el)  
#>   .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   ..$ .named_count:List of 3
#>   .. ..$ f      :function (a, b)  
#>   .. ..$ i      : int 0
#>   .. ..$ measure:function (el)  
#>   .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>  - attr(*, "measures")=List of 2
#>   ..$ .size       : num 2
#>   ..$ .named_count: int 2
```
