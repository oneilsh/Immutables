# print.flexseq handles empty, single, and small named trees

    Code
      print(flexseq())
    Output
      Unnamed flexseq with 0 elements.

---

    Code
      print(as_flexseq(1))
    Output
      Unnamed flexseq with 1 element.
      
      Elements:
      
      [[1]]
      [1] 1
      

---

    Code
      print(as_flexseq(setNames(as.list(1:4), letters[1:4])))
    Output
      Named flexseq with 4 elements.
      
      Elements:
      
      $a
      [1] 1
      
      $b
      [1] 2
      
      $c
      [1] 3
      
      $d
      [1] 4
      

# print.flexseq truncates long unnamed trees with head/tail preview

    Code
      print(as_flexseq(1:12), max_elements = 4)
    Output
      Unnamed flexseq with 12 elements.
      
      Elements:
      
      [[1]]
      [1] 1
      
      [[2]]
      [1] 2
      
      ... (skipping 8 elements)
      
      [[11]]
      [1] 11
      
      [[12]]
      [1] 12
      

---

    Code
      print(as_flexseq(1:12), max_elements = 0)
    Output
      Unnamed flexseq with 12 elements.

# print.flexseq shows custom monoid aggregates when requested

    Code
      print(x, max_elements = 2, show_custom_monoids = TRUE)
    Output
      Unnamed flexseq with 5 elements.
      Custom monoids + measures:
        sum: 15 (aggregate)
      
      Elements:
      
      [[1]]
      [1] 1
        sum measure: 1
      
      ... (skipping 3 elements)
      
      [[5]]
      [1] 5
        sum measure: 5
      

---

    Code
      print(as_flexseq(1:3), max_elements = 0, show_custom_monoids = TRUE)
    Output
      Unnamed flexseq with 3 elements.
      Custom monoids + measures: <none>

# print.priority_queue handles empty, named, unnamed, and truncated queues

    Code
      print(priority_queue())
    Output
      Unnamed priority_queue with 0 elements.

---

    Code
      print(priority_queue(one = 1, two = 2, three = 3, priorities = c(20, 30, 10)))
    Output
      Named priority_queue with 3 elements.
      Minimum priority: 10, Maximum priority: 30
      
      Elements (by priority):
      
      $three (priority 10)
      [1] 3
      
      $one (priority 20)
      [1] 1
      
      $two (priority 30)
      [1] 2
      

---

    Code
      print(priority_queue(1, 2, 3, priorities = c(2, 1, 3)))
    Output
      Unnamed priority_queue with 3 elements.
      Minimum priority: 1, Maximum priority: 3
      
      Elements (by priority):
      
      (priority 1)
      [1] 2
      
      (priority 2)
      [1] 1
      
      (priority 3)
      [1] 3
      

---

    Code
      print(big_q, max_elements = 4)
    Output
      Unnamed priority_queue with 10 elements.
      Minimum priority: 1, Maximum priority: 10
      
      Elements (by priority):
      
      (priority 1)
      [1] "b"
      
      (priority 2)
      [1] "e"
      
      ... (skipping 6 elements)
      
      (priority 9)
      [1] "f"
      
      (priority 10)
      [1] "j"
      

# print.priority_queue shows custom monoid aggregates

    Code
      print(q, max_elements = 0, show_custom_monoids = TRUE)
    Output
      Unnamed priority_queue with 3 elements.
      Minimum priority: 1, Maximum priority: 3
      Custom monoids + measures:
        sum_item: 6 (aggregate)

# print.ordered_sequence handles empty, named, unnamed, and truncated sequences

    Code
      print(ordered_sequence())
    Output
      Unnamed ordered_sequence with 0 elements.

---

    Code
      print(ordered_sequence(one = "a", two = "b", three = "c", keys = c(20, 30, 10)))
    Output
      Named ordered_sequence with 3 elements.
      
      Elements (by key order):
      
      $three (key 10)
      [1] "c"
      
      $one (key 20)
      [1] "a"
      
      $two (key 30)
      [1] "b"
      

---

    Code
      print(ordered_sequence("x", "y", "z", keys = c(2, 1, 3)))
    Output
      Unnamed ordered_sequence with 3 elements.
      
      Elements (by key order):
      
      [[1]] (key 1)
      [1] "y"
      
      [[2]] (key 2)
      [1] "x"
      
      [[3]] (key 3)
      [1] "z"
      

---

    Code
      print(as_ordered_sequence(letters[1:10], keys = 10:1), max_elements = 4)
    Output
      Unnamed ordered_sequence with 10 elements.
      
      Elements (by key order):
      
      [[1]] (key 1)
      [1] "j"
      
      [[2]] (key 2)
      [1] "i"
      
      ... (skipping 6 elements)
      
      [[9]] (key 9)
      [1] "b"
      
      [[10]] (key 10)
      [1] "a"
      

# print.ordered_sequence shows custom monoid aggregates

    Code
      print(ys, max_elements = 0, show_custom_monoids = TRUE)
    Output
      Unnamed ordered_sequence with 2 elements.
      Custom monoids + measures:
        sum_key: 3 (aggregate)

# print.interval_index handles empty, named, unnamed, and truncated indices

    Code
      print(interval_index())
    Output
      Unnamed interval_index with 0 elements, default query bounds [start, end).

---

    Code
      print(interval_index(one = 1, two = 2, three = 3, start = c(20, 30, 10), end = c(
        25, 37, 24)))
    Output
      Named interval_index with 3 elements, default query bounds [start, end).
      
      Elements (by interval start order):
      
      $three (interval 10 - 24)
      [1] 3
      
      $one (interval 20 - 25)
      [1] 1
      
      $two (interval 30 - 37)
      [1] 2
      

---

    Code
      print(interval_index(1, 2, 3, start = c(2, 4, 6), end = c(3, 5, 8),
      default_query_bounds = "[]"))
    Output
      Unnamed interval_index with 3 elements, default query bounds [start, end].
      
      Elements (by interval start order):
      
      [[1]] (interval 2 - 3)
      [1] 1
      
      [[2]] (interval 4 - 5)
      [1] 2
      
      [[3]] (interval 6 - 8)
      [1] 3
      

---

    Code
      print(big_ix, max_elements = 4)
    Output
      Unnamed interval_index with 10 elements, default query bounds [start, end).
      
      Elements (by interval start order):
      
      [[1]] (interval 1 - 2)
      [1] "a"
      
      [[2]] (interval 2 - 3)
      [1] "b"
      
      ... (skipping 6 elements)
      
      [[9]] (interval 9 - 10)
      [1] "i"
      
      [[10]] (interval 10 - 11)
      [1] "j"
      

# print.interval_index shows custom monoid aggregates

    Code
      print(ix, max_elements = 0, show_custom_monoids = TRUE)
    Output
      Unnamed interval_index with 2 elements, default query bounds [start, end).
      Custom monoids + measures:
        width_sum: 3 (aggregate)

