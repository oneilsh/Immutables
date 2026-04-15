#SO

#' @method as_flexseq interval_index
#' @export
# Runtime: O(n) from list materialization + linear rebuild.
# Public cast to plain flexseq while dropping interval-specific behavior.
# **Inputs:** `x` interval_index.
# **Outputs:** flexseq.
# **Used by:** users/tests.
as_flexseq.interval_index <- function(x) {
  entries <- as.list(x)
  .as_flexseq_build.default(entries, monoids = NULL)
}

# Runtime: O(n).
# Coerce to payload list in interval order.
# **Inputs:** `x` interval_index.
# **Outputs:** base list of payload items with names preserved.
# **Used by:** users/tests.
#' Coerce Interval Index to List
#'
#' @method as.list interval_index
#' @param x An `interval_index`.
#' @param ... Unused.
#' @return A plain list of payload elements in interval order.
#' @details
#' This returns payload values only.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(3, 1, 2), end = c(4, 2, 3))
#' as.list(ix)
#' @export
as.list.interval_index <- function(x, ...) {
  .ivx_assert_index(x)
  entries <- as.list.flexseq(x, ...)
  out <- lapply(entries, function(e) e$value)
  names(out) <- names(entries)
  out
}

# Runtime: O(1).
# Length method backed by cached `.size` measure.
# **Inputs:** `x` interval_index.
# **Outputs:** scalar integer length.
# **Used by:** users/tests/base generics.
#' Interval Index Length
#'
#' @method length interval_index
#' @param x An `interval_index`.
#' @return Number of indexed intervals.
#' @details
#' Uses cached size metadata and runs in O(1).
#' @examples
#' ix <- interval_index("a", "b", start = c(1, 3), end = c(2, 5))
#' length(ix)
#'
#' length(interval_index())
#' @export
length.interval_index <- function(x) {
  as.integer(node_measure(x, ".size"))
}

# Plot method delegates to shared flexseq tree plotting.
# **Inputs:** `x` interval_index; `...`.
# **Outputs:** plot side-effect (invisible device result).
# **Used by:** users.
#' Plot an Interval Index Tree
#'
#' Plots the underlying tree structure used by an `interval_index`.
#'
#' @method plot interval_index
#' @param x An `interval_index`.
#' @param ... Passed to the internal tree plotting routine.
#' @details
#' Visualizes the internal finger-tree structure used for interval queries.
#' @examples
#' ix <- interval_index("a", "b", "c", start = c(1, 3, 5), end = c(2, 4, 6))
#' plot(ix)
#' @export
# Runtime: O(n) to build plot graph data.
plot.interval_index <- function(x, ...) {
  plot.flexseq(x, ...)
}
