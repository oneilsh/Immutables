#SO

#' Display Internal Structure of a flexseq
#'
#' @method str flexseq
#' @param object A `flexseq`.
#' @param ... Passed to [utils::str()].
#' @return `NULL`, invisibly.
#' @examples
#' x <- flexseq(a = 1, b = list(k = 2))
#' str(x)
#' @keywords internal
#' @export
str.flexseq <- function(object, ...) {
  utils::str(unclass(object), ...)
  invisible(NULL)
}
