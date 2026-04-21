# Package index

## Flexible Sequence (flexseq)

General-purpose persistent sequence with O(1) amortized push/pop at both
ends, O(log n) indexing and replacement, and efficient split/concat.

- [`flexseq()`](https://oneilsh.github.io/immutables/reference/flexseq.md)
  : Construct a Persistent Flexible Sequence

- [`as_flexseq()`](https://oneilsh.github.io/immutables/reference/as_flexseq.md)
  :

  Coerce Objects to `flexseq`

- [`push_front()`](https://oneilsh.github.io/immutables/reference/push_front.md)
  : Push an Element to the Front

- [`push_back()`](https://oneilsh.github.io/immutables/reference/push_back.md)
  : Push an Element to the Back

- [`pop_front()`](https://oneilsh.github.io/immutables/reference/pop_front.md)
  : Pop the Front Element

- [`pop_back()`](https://oneilsh.github.io/immutables/reference/pop_back.md)
  : Pop the Back Element

- [`peek_front()`](https://oneilsh.github.io/immutables/reference/peek_front.md)
  : Peek at the Front Element

- [`peek_back()`](https://oneilsh.github.io/immutables/reference/peek_back.md)
  : Peek at the Back Element

- [`insert_at()`](https://oneilsh.github.io/immutables/reference/insert_at.md)
  : Insert Elements at a Position

- [`peek_at()`](https://oneilsh.github.io/immutables/reference/peek_at.md)
  : Peek at an Element by Position

- [`pop_at()`](https://oneilsh.github.io/immutables/reference/pop_at.md)
  : Pop an Element by Position

- [`split_at()`](https://oneilsh.github.io/immutables/reference/split_at.md)
  : Split at a Position or Name

- [`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md)
  : Fapply with S3 dispatch

- [`loop()`](https://oneilsh.github.io/immutables/reference/loop.md) :
  Iterate over an iterator (re-exported from coro)

- [`as_iterator(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/as_iterator.flexseq.md)
  :

  Iterate over a `flexseq` (coro iterator)

- [`c(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/c.flexseq.md)
  : Concatenate Sequences

- [`merge(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/merge.flexseq.md)
  : Merge Two Sequences

- [`` `$`( ``*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.flexseq.md)
  [`` `$<-`( ``*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.flexseq.md)
  [`` `[`( ``*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.flexseq.md)
  [`` `[[`( ``*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.flexseq.md)
  [`` `[<-`( ``*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.flexseq.md)
  [`` `[[<-`( ``*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.flexseq.md)
  : Flexseq Indexing

- [`print(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/print.flexseq.md)
  : Print a flexseq

- [`length(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/length.flexseq.md)
  : Sequence Length

- [`as.list(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/as.list.flexseq.md)
  : Coerce a Sequence to Base List

- [`unlist(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/unlist.flexseq.md)
  : Coerce a Sequence to an Atomic Vector

- [`plot(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/plot.flexseq.md)
  : Plot a Sequence Tree

## Priority Queue

Persistent priority queue with O(log n) insert and min/max peek/pop.
Name-based read indexing only; cast with
[`as_flexseq()`](https://oneilsh.github.io/immutables/reference/as_flexseq.md)
for full sequence operations.

- [`priority_queue()`](https://oneilsh.github.io/immutables/reference/priority_queue.md)
  : Construct a Priority Queue

- [`as_priority_queue()`](https://oneilsh.github.io/immutables/reference/as_priority_queue.md)
  :

  Build a Priority Queue from `x` and `priorities`

- [`insert()`](https://oneilsh.github.io/immutables/reference/insert.md)
  : Insert an Element

- [`peek_min()`](https://oneilsh.github.io/immutables/reference/peek_min.md)
  : Peek Minimum-Priority Element

- [`peek_max()`](https://oneilsh.github.io/immutables/reference/peek_max.md)
  : Peek Maximum-Priority Element

- [`peek_all_min()`](https://oneilsh.github.io/immutables/reference/peek_all_min.md)
  : Peek All Minimum-Priority Elements

- [`peek_all_max()`](https://oneilsh.github.io/immutables/reference/peek_all_max.md)
  : Peek All Maximum-Priority Elements

- [`pop_min()`](https://oneilsh.github.io/immutables/reference/pop_min.md)
  : Pop Minimum-Priority Element

- [`pop_max()`](https://oneilsh.github.io/immutables/reference/pop_max.md)
  : Pop Maximum-Priority Element

- [`pop_all_min()`](https://oneilsh.github.io/immutables/reference/pop_all_min.md)
  : Pop All Minimum-Priority Elements

- [`pop_all_max()`](https://oneilsh.github.io/immutables/reference/pop_all_max.md)
  : Pop All Maximum-Priority Elements

- [`min_priority()`](https://oneilsh.github.io/immutables/reference/min_priority.md)
  : Minimum Priority Value

- [`max_priority()`](https://oneilsh.github.io/immutables/reference/max_priority.md)
  : Maximum Priority Value

- [`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md)
  : Fapply with S3 dispatch

- [`as_iterator(`*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/as_iterator.priority_queue.md)
  :

  Iterate over a `priority_queue` (coro iterator)

- [`merge(`*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/merge.priority_queue.md)
  : Merge Two Priority Queues

- [`` `[`( ``*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.priority_queue.md)
  [`` `[[`( ``*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.priority_queue.md)
  [`` `[<-`( ``*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.priority_queue.md)
  [`` `[[<-`( ``*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.priority_queue.md)
  [`` `$`( ``*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.priority_queue.md)
  [`` `$<-`( ``*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.priority_queue.md)
  : Indexing for Priority Queues

- [`as.list(`*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/as.list.priority_queue.md)
  : Coerce Priority Queue to List

- [`unlist(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/unlist.flexseq.md)
  : Coerce a Sequence to an Atomic Vector

- [`print(`*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/print.priority_queue.md)
  : Print a Priority Queue Summary

- [`length(`*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/length.priority_queue.md)
  : Priority Queue Length

- [`plot(`*`<priority_queue>`*`)`](https://oneilsh.github.io/immutables/reference/plot.priority_queue.md)
  : Plot a Priority Queue Tree

## Ordered Sequence

Persistent key-ordered sequence with O(log n) insert, key lookup, and
range queries. Read indexing preserves key order; replacement indexing
is not supported.

- [`ordered_sequence()`](https://oneilsh.github.io/immutables/reference/ordered_sequence.md)
  : Construct an Ordered Sequence

- [`as_ordered_sequence()`](https://oneilsh.github.io/immutables/reference/as_ordered_sequence.md)
  :

  Build an Ordered Sequence from `x` and `keys`

- [`insert()`](https://oneilsh.github.io/immutables/reference/insert.md)
  : Insert an Element

- [`peek_key()`](https://oneilsh.github.io/immutables/reference/peek_key.md)
  : Peek First Element for One Key

- [`peek_all_key()`](https://oneilsh.github.io/immutables/reference/peek_all_key.md)
  : Peek All Elements for One Key

- [`pop_key()`](https://oneilsh.github.io/immutables/reference/pop_key.md)
  : Pop First Element for One Key

- [`pop_all_key()`](https://oneilsh.github.io/immutables/reference/pop_all_key.md)
  : Pop All Elements for One Key

- [`lower_bound()`](https://oneilsh.github.io/immutables/reference/lower_bound.md)
  :

  Find First Element with Key `>=` Query

- [`upper_bound()`](https://oneilsh.github.io/immutables/reference/upper_bound.md)
  :

  Find First Element with Key `>` Query

- [`elements_between()`](https://oneilsh.github.io/immutables/reference/elements_between.md)
  : Return Elements in a Key Range

- [`count_key()`](https://oneilsh.github.io/immutables/reference/count_key.md)
  : Count Elements Matching One Key

- [`count_between()`](https://oneilsh.github.io/immutables/reference/count_between.md)
  : Count Elements in a Key Range

- [`min_key()`](https://oneilsh.github.io/immutables/reference/min_key.md)
  : Minimum Key Value

- [`max_key()`](https://oneilsh.github.io/immutables/reference/max_key.md)
  : Maximum Key Value

- [`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md)
  : Fapply with S3 dispatch

- [`merge(`*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/merge.ordered_sequence.md)
  : Merge Two Ordered Sequences

- [`` `[`( ``*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.ordered_sequence.md)
  [`` `[[`( ``*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.ordered_sequence.md)
  [`` `[<-`( ``*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.ordered_sequence.md)
  [`` `[[<-`( ``*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.ordered_sequence.md)
  [`` `$`( ``*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.ordered_sequence.md)
  [`` `$<-`( ``*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.ordered_sequence.md)
  : Indexing for Ordered Sequences

- [`print(`*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/print.ordered_sequence.md)
  : Print an Ordered Sequence Summary

- [`length(`*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/length.ordered_sequence.md)
  : Ordered Sequence Length

- [`as.list(`*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/as.list.ordered_sequence.md)
  : Coerce Ordered Sequence to List

- [`unlist(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/unlist.flexseq.md)
  : Coerce a Sequence to an Atomic Vector

- [`plot(`*`<ordered_sequence>`*`)`](https://oneilsh.github.io/immutables/reference/plot.ordered_sequence.md)
  : Plot an Ordered Sequence Tree

## Interval Index

Persistent interval index with O(log n) insertion and immutable interval
query/pop helpers over ordered interval endpoints.

- [`interval_index()`](https://oneilsh.github.io/immutables/reference/interval_index.md)
  : Construct an Interval Index

- [`as_interval_index()`](https://oneilsh.github.io/immutables/reference/as_interval_index.md)
  :

  Build an Interval Index from `x`, `start`, and `end`

- [`insert()`](https://oneilsh.github.io/immutables/reference/insert.md)
  : Insert an Element

- [`peek_point()`](https://oneilsh.github.io/immutables/reference/peek_point.md)
  : Peek First Interval Matching a Point

- [`peek_all_point()`](https://oneilsh.github.io/immutables/reference/peek_all_point.md)
  : Peek All Intervals Matching a Point

- [`pop_point()`](https://oneilsh.github.io/immutables/reference/pop_point.md)
  : Pop First Interval Matching a Point

- [`pop_all_point()`](https://oneilsh.github.io/immutables/reference/pop_all_point.md)
  : Pop All Intervals Matching a Point

- [`peek_overlaps()`](https://oneilsh.github.io/immutables/reference/peek_overlaps.md)
  : Peek First Interval Overlapping a Query Interval

- [`peek_all_overlaps()`](https://oneilsh.github.io/immutables/reference/peek_all_overlaps.md)
  : Peek All Intervals Overlapping a Query Interval

- [`peek_containing()`](https://oneilsh.github.io/immutables/reference/peek_containing.md)
  : Peek First Interval Containing a Query Interval

- [`peek_all_containing()`](https://oneilsh.github.io/immutables/reference/peek_all_containing.md)
  : Peek All Intervals Containing a Query Interval

- [`peek_within()`](https://oneilsh.github.io/immutables/reference/peek_within.md)
  : Peek First Interval Within a Query Interval

- [`peek_all_within()`](https://oneilsh.github.io/immutables/reference/peek_all_within.md)
  : Peek All Intervals Within a Query Interval

- [`pop_overlaps()`](https://oneilsh.github.io/immutables/reference/pop_overlaps.md)
  : Pop First Overlapping Interval

- [`pop_all_overlaps()`](https://oneilsh.github.io/immutables/reference/pop_all_overlaps.md)
  : Pop All Overlapping Intervals

- [`pop_containing()`](https://oneilsh.github.io/immutables/reference/pop_containing.md)
  : Pop First Containing Interval

- [`pop_all_containing()`](https://oneilsh.github.io/immutables/reference/pop_all_containing.md)
  : Pop All Containing Intervals

- [`pop_within()`](https://oneilsh.github.io/immutables/reference/pop_within.md)
  : Pop First Interval Within a Query Interval

- [`pop_all_within()`](https://oneilsh.github.io/immutables/reference/pop_all_within.md)
  : Pop All Intervals Within a Query Interval

- [`min_endpoint()`](https://oneilsh.github.io/immutables/reference/min_endpoint.md)
  : Minimum Left Endpoint

- [`max_endpoint()`](https://oneilsh.github.io/immutables/reference/max_endpoint.md)
  : Maximum Right Endpoint

- [`fapply()`](https://oneilsh.github.io/immutables/reference/fapply.md)
  : Fapply with S3 dispatch

- [`merge(`*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/merge.interval_index.md)
  : Merge Two Interval Indices

- [`` `[`( ``*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.interval_index.md)
  [`` `[[`( ``*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.interval_index.md)
  [`` `[<-`( ``*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.interval_index.md)
  [`` `[[<-`( ``*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.interval_index.md)
  [`` `$`( ``*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.interval_index.md)
  [`` `$<-`( ``*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/sub-.interval_index.md)
  : Indexing for Interval Indexes

- [`print(`*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/print.interval_index.md)
  : Print an Interval Index Summary

- [`length(`*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/length.interval_index.md)
  : Interval Index Length

- [`as.list(`*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/as.list.interval_index.md)
  : Coerce Interval Index to List

- [`unlist(`*`<flexseq>`*`)`](https://oneilsh.github.io/immutables/reference/unlist.flexseq.md)
  : Coerce a Sequence to an Atomic Vector

- [`plot(`*`<interval_index>`*`)`](https://oneilsh.github.io/immutables/reference/plot.interval_index.md)
  : Plot an Interval Index Tree

## Developer Tools

Lower-level primitives for custom monoids, predicate queries,
validation, and structure visualization.

- [`add_monoids()`](https://oneilsh.github.io/immutables/reference/add_monoids.md)
  : Add or Merge Measure Monoids
- [`get_measure()`](https://oneilsh.github.io/immutables/reference/get_measure.md)
  : Read a Cached Subtree Measure
- [`get_measures()`](https://oneilsh.github.io/immutables/reference/get_measures.md)
  : Read Per-Element Monoid Measures
- [`locate_by_predicate()`](https://oneilsh.github.io/immutables/reference/locate_by_predicate.md)
  : Locate First Predicate Match
- [`split_around_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_around_by_predicate.md)
  : Split Around First Predicate Match
- [`split_by_predicate()`](https://oneilsh.github.io/immutables/reference/split_by_predicate.md)
  : Split into Left and Right Parts
- [`measure_monoid()`](https://oneilsh.github.io/immutables/reference/measure_monoid.md)
  : Construct a Measure Monoid Specification
- [`validate_tree()`](https://oneilsh.github.io/immutables/reference/validate_tree.md)
  : Validate full tree invariants (debug/test utility)
- [`validate_name_state()`](https://oneilsh.github.io/immutables/reference/validate_name_state.md)
  : Validate name-state invariants only (debug/test utility)
- [`plot_structure()`](https://oneilsh.github.io/immutables/reference/plot_structure.md)
  : Plot the Internal Finger-Tree Structure
