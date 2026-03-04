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
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 5 18 5 37 18 37 5 5
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137bba22e8> 
#>   .. .. ..$ i      : num 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 5 43 5 56 43 56 5 5
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137bba22e8> 
#>   .. .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   .. ..$ .named_count:List of 3
#>   .. .. ..$ f      :function (a, b)  
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 8 18 8 37 18 37 8 8
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137c076608> 
#>   .. .. ..$ i      : int 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 8 44 12 3 44 3 8 12
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137c076608> 
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
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 5 18 5 37 18 37 5 5
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137bba22e8> 
#>   .. .. ..$ i      : num 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 5 43 5 56 43 56 5 5
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137bba22e8> 
#>   .. .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   .. ..$ .named_count:List of 3
#>   .. .. ..$ f      :function (a, b)  
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 8 18 8 37 18 37 8 8
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137c076608> 
#>   .. .. ..$ i      : int 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 8 44 12 3 44 3 8 12
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137c076608> 
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
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 5 18 5 37 18 37 5 5
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137bba22e8> 
#>   .. .. ..$ i      : num 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 5 43 5 56 43 56 5 5
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137bba22e8> 
#>   .. .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   .. ..$ .named_count:List of 3
#>   .. .. ..$ f      :function (a, b)  
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 8 18 8 37 18 37 8 8
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137c076608> 
#>   .. .. ..$ i      : int 0
#>   .. .. ..$ measure:function (el)  
#>   .. .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 8 44 12 3 44 3 8 12
#>   .. .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137c076608> 
#>   .. .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   ..- attr(*, "measures")=List of 2
#>   .. ..$ .size       : num 1
#>   .. ..$ .named_count: int 1
#>  - attr(*, "monoids")=List of 2
#>   ..$ .size       :List of 3
#>   .. ..$ f      :function (a, b)  
#>   .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 5 18 5 37 18 37 5 5
#>   .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137bba22e8> 
#>   .. ..$ i      : num 0
#>   .. ..$ measure:function (el)  
#>   .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 5 43 5 56 43 56 5 5
#>   .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137bba22e8> 
#>   .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>   ..$ .named_count:List of 3
#>   .. ..$ f      :function (a, b)  
#>   .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 8 18 8 37 18 37 8 8
#>   .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137c076608> 
#>   .. ..$ i      : int 0
#>   .. ..$ measure:function (el)  
#>   .. .. ..- attr(*, "srcref")= 'srcref' int [1:8] 8 44 12 3 44 3 8 12
#>   .. .. .. ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x56137c076608> 
#>   .. ..- attr(*, "class")= chr [1:3] "measure_monoid" "MeasureMonoid" "list"
#>  - attr(*, "measures")=List of 2
#>   ..$ .size       : num 2
#>   ..$ .named_count: int 2
```
