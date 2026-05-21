.ivx_with_cpp_scan_enabled <- function(flag, expr) {
  old <- getOption("immutables.ivx.cpp_scan", default = TRUE)
  on.exit(options(immutables.ivx.cpp_scan = old), add = TRUE)
  options(immutables.ivx.cpp_scan = isTRUE(flag))
  force(expr)
}
