#SO

#' Build a Structural Tree from a Vector or List
#'
#' @param x Elements to insert.
#' @param monoids Optional named list of `measure_monoid` objects.
#' @return A finger tree with cached measures for all monoids.
#'   If `x` has names, they are used for name-based indexing and must be
#'   complete (no missing/empty names) and unique.
#' @keywords internal
# Runtime: O(n) for validation + linear bulk build.
tree_from <- function(x, monoids = NULL) {
  # Phase 1: normalize monoid set and decide whether C++ build path is available.
  ms <- if(is.null(monoids)) ensure_size_monoids(list(.size = size_measure_monoid())) else ensure_size_monoids(monoids)
  can_cpp <- .ft_cpp_can_use(ms)

  # Phase 2: normalize container shape and detect caller-supplied outer names.
  x_list <- as.list(x)
  n <- length(x_list)

  resolved_names <- NULL
  in_names <- names(x)
  use_names <- !is.null(in_names) && length(in_names) > 0L
  if(use_names && length(in_names) != n) {
    stop("Input names length must match input length.")
  }

  # Phase 3a: explicit outer names path. Enforce complete/unique naming.
  if(use_names) {
    norm_names <- as.character(in_names)
    missing_name <- is.na(norm_names) | norm_names == ""
    has_any <- any(!missing_name)
    if(has_any) {
      if(any(missing_name)) {
        stop("Mixed named and unnamed elements are not allowed.")
      }
      if(anyDuplicated(norm_names) > 0L) {
        stop("Element names must be unique.")
      }
      resolved_names <- norm_names
    }
  } else if(n > 0L) {
    # Phase 3b: no outer names. Optionally derive names from element payload attrs.
    if(can_cpp) {
      # Common constructor path: if elements have no attrs there are no inline
      # names to preserve, so we can bulk-build directly in C++.
      if(!any(vapply(x_list, function(el) !is.null(attributes(el)), logical(1)))) {
        return(.as_flexseq(.ft_cpp_tree_from(x_list, ms)))
      }
    }

    # Preserve existing behavior: when outer names are absent, derive names
    # from each element payload (ft_name attr or inline scalar names()).
    # Fast local path avoids lambda dispatch in hot construction workloads.
    derived <- vector("list", n)
    has_any <- FALSE
    has_missing <- FALSE
    for(i in seq_len(n)) {
      el <- x_list[[i]]
      nm <- attr(el, "ft_name", exact = TRUE)
      if(!is.null(nm) && length(nm) > 0L) {
        if(length(nm) != 1L) {
          stop("Element names must be scalar.")
        }
        nm <- as.character(nm[[1L]])
        if(is.na(nm) || nm == "") {
          nm <- NULL
        }
      } else {
        nms <- names(el)
        if(is.null(nms) || length(nms) != 1L) {
          nm <- NULL
        } else {
          nm <- nms[[1L]]
          if(is.na(nm) || nm == "") {
            nm <- NULL
          } else {
            nm <- as.character(nm)
          }
        }
      }
      derived[[i]] <- nm
      if(is.null(nm)) {
        has_missing <- TRUE
      } else {
        has_any <- TRUE
      }
    }
    if(has_any) {
      if(has_missing) {
        stop("Mixed named and unnamed elements are not allowed.")
      }
      resolved_names <- unlist(derived, use.names = FALSE)
      if(anyDuplicated(resolved_names) > 0L) {
        stop("Element names must be unique.")
      }
    }
  }

  # Phase 4: dispatch to backend constructor (C++ fast path vs R reference path).
  if(can_cpp) {
    if(is.null(resolved_names)) {
      return(.as_flexseq(.ft_cpp_tree_from(x_list, ms)))
    }
    return(.as_flexseq(.ft_cpp_tree_from_prepared(
      x_list,
      resolved_names,
      ms
    )))
  }

  # R path needs names materialized on each element before structural build.
  if(!is.null(resolved_names)) {
    for(i in seq_along(x_list)) {
      el <- x_list[[i]]
      el <- .ft_set_name(el, resolved_names[[i]])
      # Preserve NULL elements; `[[<- NULL` would drop positions from the list.
      x_list[i] <- list(el)
    }
  }

  .ft_tree_from_list_linear(x_list, ms)
}

# Runtime: O(n) in total elements across recursive levels.
.ft_tree_from_ordered_ref <- function(xs, monoids) {
  n <- length(xs)

  # Small-n base shapes mirror fingertree constructors directly.
  if(n == 0L) {
    return(measured_empty(monoids))
  }
  if(n == 1L) {
    return(measured_single(xs[[1L]], monoids))
  }
  if(n == 2L) {
    return(measured_deep(
      build_digit(list(xs[[1L]]), monoids),
      measured_empty(monoids),
      build_digit(list(xs[[2L]]), monoids),
      monoids
    ))
  }
  if(n == 3L) {
    return(measured_deep(
      build_digit(xs[1:2], monoids),
      measured_empty(monoids),
      build_digit(list(xs[[3L]]), monoids),
      monoids
    ))
  }
  if(n == 4L) {
    return(measured_deep(
      build_digit(xs[1:2], monoids),
      measured_empty(monoids),
      build_digit(xs[3:4], monoids),
      monoids
    ))
  }

  # Reference shape rule: avoid a 1-element middle segment since middle trees
  # are built from Node2/Node3 blocks only.
  prefix_len <- if(n == 5L) 1L else 2L
  suffix_len <- 2L

  prefix <- build_digit(xs[seq_len(prefix_len)], monoids)
  suffix <- build_digit(xs[(n - suffix_len + 1L):n], monoids)
  middle_elems <- xs[(prefix_len + 1L):(n - suffix_len)]
  middle_nodes <- measured_nodes(middle_elems, monoids)
  middle <- .ft_tree_from_ordered_ref(middle_nodes, monoids)

  measured_deep(prefix, middle, suffix, monoids)
}

# Runtime: O(n).
.ft_tree_from_list_linear <- function(x_list, monoids) {
  .as_flexseq(.ft_tree_from_ordered_ref(x_list, monoids))
}
