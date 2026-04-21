#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

extern SEXP ft_cpp_append_right(SEXP, SEXP, SEXP);
extern SEXP ft_cpp_prepend_left(SEXP, SEXP, SEXP);
extern SEXP ft_cpp_append_right_named(SEXP, SEXP, SEXP, SEXP);
extern SEXP ft_cpp_prepend_left_named(SEXP, SEXP, SEXP, SEXP);
extern SEXP ft_cpp_tree_from(SEXP, SEXP);
extern SEXP ft_cpp_tree_from_prepared(SEXP, SEXP, SEXP);
extern SEXP ft_cpp_tree_from_sorted(SEXP, SEXP);
extern SEXP ft_cpp_concat(SEXP, SEXP, SEXP);
extern SEXP ft_cpp_oms_insert(SEXP, SEXP, SEXP, SEXP);
extern SEXP ft_cpp_locate(SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP ft_cpp_split_tree(SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP ft_cpp_find_name_position(SEXP, SEXP);
extern SEXP ft_cpp_get_by_index(SEXP, SEXP);
extern SEXP ft_cpp_get_many_by_index(SEXP, SEXP);
extern SEXP ft_cpp_name_positions(SEXP);
extern SEXP ft_cpp_split_at_index(SEXP, SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
  {"ft_cpp_append_right", (DL_FUNC) &ft_cpp_append_right, 3},
  {"ft_cpp_prepend_left", (DL_FUNC) &ft_cpp_prepend_left, 3},
  {"ft_cpp_append_right_named", (DL_FUNC) &ft_cpp_append_right_named, 4},
  {"ft_cpp_prepend_left_named", (DL_FUNC) &ft_cpp_prepend_left_named, 4},
  {"ft_cpp_tree_from", (DL_FUNC) &ft_cpp_tree_from, 2},
  {"ft_cpp_tree_from_prepared", (DL_FUNC) &ft_cpp_tree_from_prepared, 3},
  {"ft_cpp_tree_from_sorted", (DL_FUNC) &ft_cpp_tree_from_sorted, 2},
  {"ft_cpp_concat", (DL_FUNC) &ft_cpp_concat, 3},
  {"ft_cpp_oms_insert", (DL_FUNC) &ft_cpp_oms_insert, 4},
  {"ft_cpp_locate", (DL_FUNC) &ft_cpp_locate, 5},
  {"ft_cpp_split_tree", (DL_FUNC) &ft_cpp_split_tree, 5},
  {"ft_cpp_find_name_position", (DL_FUNC) &ft_cpp_find_name_position, 2},
  {"ft_cpp_get_by_index", (DL_FUNC) &ft_cpp_get_by_index, 2},
  {"ft_cpp_get_many_by_index", (DL_FUNC) &ft_cpp_get_many_by_index, 2},
  {"ft_cpp_name_positions", (DL_FUNC) &ft_cpp_name_positions, 1},
  {"ft_cpp_split_at_index", (DL_FUNC) &ft_cpp_split_at_index, 3},
  {NULL, NULL, 0}
};

void R_init_Immutables(DllInfo *dll) {
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
