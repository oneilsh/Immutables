# Priority Queues

## Creating a priority queue

``` r
x <- priority_queue("task_a", "task_b", "task_c", priorities = c(3, 1, 2))
x
#> Unnamed priority_queue with 3 elements.
#> Minimum priority: 1, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "task_b"
#> 
#> (priority 2)
#> [1] "task_c"
#> 
#> (priority 3)
#> [1] "task_a"
```

## Peeking at extremes

``` r
peek_min(x)
#> [1] "task_b"
peek_max(x)
#> [1] "task_a"
```

## Popping elements

[`pop_min()`](https://oneilsh.github.io/immutables/reference/pop_min.md)
and
[`pop_max()`](https://oneilsh.github.io/immutables/reference/pop_max.md)
return both the element and the updated queue.

``` r
x2 <- pop_min(x)
x2$element
#> [1] "task_b"
x2$priority
#> [1] 1
x2$remaining
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: 2, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 2)
#> [1] "task_c"
#> 
#> (priority 3)
#> [1] "task_a"
```

## Bulk extrema (tie runs)

Use bulk helpers to read/remove all elements tied at the current minimum
or maximum priority.

``` r
peek_all_min(x)
#> Unnamed priority_queue with 1 element.
#> Minimum priority: 1, Maximum priority: 1
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "task_b"
pop_all_min(x)
#> $elements
#> Unnamed priority_queue with 1 element.
#> Minimum priority: 1, Maximum priority: 1
#> 
#> Elements (by priority):
#> 
#> (priority 1)
#> [1] "task_b"
#> 
#> 
#> $remaining
#> Unnamed priority_queue with 2 elements.
#> Minimum priority: 2, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 2)
#> [1] "task_c"
#> 
#> (priority 3)
#> [1] "task_a"
```

## Empty queues

Scalar peek/pop helpers are non-throwing on empty queues.

``` r
empty_q <- priority_queue()
peek_min(empty_q)
#> NULL
pop_min(empty_q)
#> $element
#> NULL
#> 
#> $priority
#> NULL
#> 
#> $remaining
#> Unnamed priority_queue with 0 elements.
```

## Inserting elements

``` r
x3 <- insert(x, "task_d", priority = 0)
x3
#> Unnamed priority_queue with 4 elements.
#> Minimum priority: 0, Maximum priority: 3
#> 
#> Elements (by priority):
#> 
#> (priority 0)
#> [1] "task_d"
#> 
#> (priority 1)
#> [1] "task_b"
#> 
#> (priority 2)
#> [1] "task_c"
#> 
#> (priority 3)
#> [1] "task_a"
peek_min(x3)
#> [1] "task_d"
```

## Persistence

The original queue is unchanged.

``` r
peek_min(x)
#> [1] "task_b"
length(x)
#> [1] 3
```
