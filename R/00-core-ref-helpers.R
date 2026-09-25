#SO

# identify internal structural nodes (vs user elements)
# Runtime: O(1). Plain S3-class lookup avoids lambda.r dispatcher overhead;
# called from many tree-traversal hot paths.
is_structural_node <- function(x) {
  cls <- class(x)
  any(cls %in% c("FingerTree", "Deep", "Digit", "Node", "Single", "Empty"))
}

# ---- suspended middle trees ----
# Amortized O(1) deque operations only survive persistence (reusing an old
# version repeatedly) if the recursive part of a push/pop is suspended and its
# result memoized, so every version sharing the suspension shares the paid-off
# work (Hinze & Paterson 2006, Sec. 3; Okasaki 1998). A Deep node's middle slot
# may therefore hold an "FTThunk": an environment (a reference object, so the
# memo is shared) recording one pending one-level operation on a middle tree,
# with the cached measures of its eventual value. The layout matches the C++
# backend (src/ft_cpp.cpp), so either backend can force either's suspensions.
.FT_THUNK_ADD_LEFT <- 1L    # add_left(t, x)
.FT_THUNK_ADD_RIGHT <- 2L   # add_right(t, x)
.FT_THUNK_TAIL_LEFT <- 3L   # viewL(t)$rest
.FT_THUNK_INIT_RIGHT <- 4L  # viewR(t)$rest

# suspend `op` on forced tree `t` (and node `x` for adds). `parts` are the
# structural pieces whose combined measure equals the eventual value's.
# Runtime: O(m * k) for m monoids and k = length(parts) (at most 2).
.ft_make_thunk <- function(op, t, x, parts, monoids) {
  th <- new.env(parent = emptyenv(), size = 4L)
  assign("op", op, envir = th)
  assign("t", t, envir = th)
  assign("x", x, envir = th)
  nms <- names(monoids)
  ms <- vector("list", length(monoids))
  names(ms) <- nms
  for(i in seq_along(monoids)) {
    r <- monoids[[i]]
    acc <- r$i
    for(p in parts) {
      acc <- r$f(acc, .measure_child_named_fast(p, nms[[i]], r))
    }
    ms[[i]] <- acc
  }
  attr(th, "measures") <- ms
  attr(th, "monoids") <- monoids
  class(th) <- "FTThunk"
  th
}

# evaluate a suspension once and memoize the result in place; non-suspensions
# are returned as is.
# Runtime: O(1) amortized.
.ft_force <- function(m) {
  if(!inherits(m, "FTThunk")) {
    return(m)
  }
  if(.ft_cpp_enabled()) {
    return(.Call("ft_cpp_force", m, PACKAGE = "Immutables"))
  }
  if(exists("value", envir = m, inherits = FALSE)) {
    return(get("value", envir = m, inherits = FALSE))
  }
  ms <- attr(m, "monoids", exact = TRUE)
  t <- get("t", envir = m, inherits = FALSE)
  x <- get("x", envir = m, inherits = FALSE)
  out <- switch(get("op", envir = m, inherits = FALSE),
    add_left(t, x, ms),
    add_right(t, x, ms),
    viewL(t, ms)$rest,
    viewR(t, ms)$rest
  )
  assign("value", out, envir = m)
  # drop the inputs so the suspension doesn't keep them alive
  assign("t", NULL, envir = m)
  assign("x", NULL, envir = m)
  out
}

# middle tree of a Deep node as a structural tree, forcing it if suspended.
# Runtime: O(1) amortized.
.ft_middle <- function(t) {
  .ft_force(.subset2(t, "middle"))
}
