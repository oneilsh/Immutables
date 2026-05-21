#include <Rcpp.h>
#include <algorithm>

// SO
// Core methods match reference R core methods

using namespace Rcpp;

namespace {

struct ReprotectSEXP {
  SEXP value;
  PROTECT_INDEX index;

  explicit ReprotectSEXP(SEXP init) : value(R_NilValue) {
    PROTECT_WITH_INDEX(value = init, &index);
  }

  ReprotectSEXP(const ReprotectSEXP&) = delete;
  ReprotectSEXP& operator=(const ReprotectSEXP&) = delete;

  ~ReprotectSEXP() {
    UNPROTECT(1);
  }

  SEXP get() const {
    return value;
  }

  SEXP set(SEXP next) {
    REPROTECT(value = next, index);
    return value;
  }
};

SEXP class_sym = Rf_install("class");
SEXP monoids_sym = Rf_install("monoids");
SEXP measures_sym = Rf_install("measures");
SEXP ft_name_sym = Rf_install("ft_name");

bool has_class(SEXP x, const char* cls) {
  return Rf_inherits(x, cls);
}

bool is_structural_node_cpp(SEXP x) {
  return has_class(x, "FingerTree") || has_class(x, "Digit") || has_class(x, "Node");
}

bool has_name_attr(SEXP x) {
  SEXP nm = Rf_getAttrib(x, ft_name_sym);
  return !Rf_isNull(nm) && XLENGTH(nm) > 0;
}

SEXP list_get_named_or_index(const List& x, const char* key, int fallback_idx = -1) {
  if(x.containsElementNamed(key)) {
    return x[key];
  }
  if(fallback_idx >= 0 && fallback_idx < x.size()) {
    return x[fallback_idx];
  }
  stop(std::string("Missing required list field: ") + key);
}

double compute_tree_size_fallback(SEXP x) {
  if(!is_structural_node_cpp(x)) {
    return 1.0;
  }
  if(has_class(x, "Empty")) {
    return 0.0;
  }
  if(has_class(x, "Single")) {
    List s(x);
    return compute_tree_size_fallback(s[0]);
  }
  if(has_class(x, "Deep")) {
    List d(x);
    return compute_tree_size_fallback(d["prefix"]) +
      compute_tree_size_fallback(d["middle"]) +
      compute_tree_size_fallback(d["suffix"]);
  }
  List xs(x);
  double total = 0.0;
  for(int i = 0; i < xs.size(); ++i) {
    total += compute_tree_size_fallback(xs[i]);
  }
  return total;
}

int compute_tree_named_count_fallback(SEXP x) {
  if(!is_structural_node_cpp(x)) {
    return has_name_attr(x) ? 1 : 0;
  }
  if(has_class(x, "Empty")) {
    return 0;
  }
  if(has_class(x, "Single")) {
    List s(x);
    return compute_tree_named_count_fallback(s[0]);
  }
  if(has_class(x, "Deep")) {
    List d(x);
    return compute_tree_named_count_fallback(d["prefix"]) +
      compute_tree_named_count_fallback(d["middle"]) +
      compute_tree_named_count_fallback(d["suffix"]);
  }
  List xs(x);
  int total = 0;
  for(int i = 0; i < xs.size(); ++i) {
    total += compute_tree_named_count_fallback(xs[i]);
  }
  return total;
}

bool name_equals(SEXP x, const std::string& target) {
  SEXP nm = Rf_getAttrib(x, ft_name_sym);
  if(Rf_isNull(nm) || XLENGTH(nm) == 0) {
    return false;
  }
  return as<std::string>(STRING_ELT(nm, 0)) == target;
}

double child_size(SEXP x) {
  if(has_class(x, "FingerTree") || has_class(x, "Digit") || has_class(x, "Node")) {
    List ms = Rf_getAttrib(x, measures_sym);
    if(ms.containsElementNamed(".size")) {
      return as<double>(ms[".size"]);
    }
    return compute_tree_size_fallback(x);
  }
  return 1.0;
}

int child_named_count(SEXP x) {
  if(has_class(x, "FingerTree") || has_class(x, "Digit") || has_class(x, "Node")) {
    List ms = Rf_getAttrib(x, measures_sym);
    if(ms.containsElementNamed(".named_count")) {
      return as<int>(ms[".named_count"]);
    }
    return compute_tree_named_count_fallback(x);
  }
  return has_name_attr(x) ? 1 : 0;
}

int find_name_position_impl(SEXP x, const std::string& target, int offset) {
  if(!is_structural_node_cpp(x)) {
    return name_equals(x, target) ? (offset + 1) : -1;
  }

  if(has_class(x, "Empty")) {
    return -1;
  }

  if(has_class(x, "Single")) {
    List s(x);
    return find_name_position_impl(s[0], target, offset);
  }

  if(has_class(x, "Deep")) {
    List d(x);
    SEXP prefix = d["prefix"];
    SEXP middle = d["middle"];
    SEXP suffix = d["suffix"];

    int p = find_name_position_impl(prefix, target, offset);
    if(p >= 0) {
      return p;
    }
    offset += static_cast<int>(child_size(prefix));

    p = find_name_position_impl(middle, target, offset);
    if(p >= 0) {
      return p;
    }
    offset += static_cast<int>(child_size(middle));

    return find_name_position_impl(suffix, target, offset);
  }

  List xs(x);
  for(int i = 0; i < xs.size(); ++i) {
    SEXP el = xs[i];
    int p = find_name_position_impl(el, target, offset);
    if(p >= 0) {
      return p;
    }
    offset += static_cast<int>(child_size(el));
  }
  return -1;
}

SEXP get_by_index_impl(SEXP x, int idx) {
  if(idx <= 0) {
    stop("Only positive integer indices are supported.");
  }

  if(!is_structural_node_cpp(x)) {
    if(idx == 1) {
      return x;
    }
    stop("Index out of bounds.");
  }

  if(has_class(x, "Empty")) {
    stop("Index out of bounds.");
  }

  if(has_class(x, "Single")) {
    List s(x);
    return get_by_index_impl(s[0], idx);
  }

  if(has_class(x, "Deep")) {
    List d(x);
    SEXP prefix = d["prefix"];
    SEXP middle = d["middle"];
    SEXP suffix = d["suffix"];

    const int npr = static_cast<int>(child_size(prefix));
    if(idx <= npr) {
      return get_by_index_impl(prefix, idx);
    }
    idx -= npr;

    const int nm = static_cast<int>(child_size(middle));
    if(idx <= nm) {
      return get_by_index_impl(middle, idx);
    }
    idx -= nm;

    return get_by_index_impl(suffix, idx);
  }

  List xs(x);
  for(int i = 0; i < xs.size(); ++i) {
    SEXP el = xs[i];
    const int n = static_cast<int>(child_size(el));
    if(idx <= n) {
      return get_by_index_impl(el, idx);
    }
    idx -= n;
  }

  stop("Index out of bounds.");
}

void collect_names_impl(SEXP x, CharacterVector& out, int& pos) {
  if(!is_structural_node_cpp(x)) {
    if(pos >= out.size()) {
      stop("Name collection overflow: more leaves than expected from .size measure.");
    }
    SEXP nm = Rf_getAttrib(x, ft_name_sym);
    if(Rf_isNull(nm) || XLENGTH(nm) == 0) {
      out[pos++] = NA_STRING;
      return;
    }
    out[pos++] = STRING_ELT(nm, 0);
    return;
  }

  if(has_class(x, "Empty")) {
    return;
  }

  if(has_class(x, "Single")) {
    List s(x);
    collect_names_impl(s[0], out, pos);
    return;
  }

  if(has_class(x, "Deep")) {
    List d(x);
    collect_names_impl(d["prefix"], out, pos);
    collect_names_impl(d["middle"], out, pos);
    collect_names_impl(d["suffix"], out, pos);
    return;
  }

  List xs(x);
  for(int i = 0; i < xs.size(); ++i) {
    collect_names_impl(xs[i], out, pos);
  }
}

SEXP oms_entry_key(SEXP entry) {
  if(TYPEOF(entry) != VECSXP || XLENGTH(entry) < 2) {
    stop("ordered entries must be list(value, key).");
  }
  List e(entry);
  SEXP key = e[1];
  if(Rf_isNull(key)) {
    stop("ordered_multiset entry is missing `key`.");
  }
  return key;
}

int oms_compare_keys(SEXP a, SEXP b, const std::string& key_type) {
  if(key_type == "numeric") {
    const double da = as<double>(a);
    const double db = as<double>(b);
    if(da < db) return -1;
    if(da > db) return 1;
    return 0;
  }
  if(key_type == "character") {
    const std::string sa = as<std::string>(a);
    const std::string sb = as<std::string>(b);
    if(sa < sb) return -1;
    if(sa > sb) return 1;
    return 0;
  }
  if(key_type == "logical") {
    const int ia = as<bool>(a) ? 1 : 0;
    const int ib = as<bool>(b) ? 1 : 0;
    if(ia < ib) return -1;
    if(ia > ib) return 1;
    return 0;
  }
  stop("Unsupported ordered_multiset key type.");
}

bool monoid_name_is_pq_minmax(const std::string& monoid_name, bool& is_min) {
  if(monoid_name == ".pq_min") {
    is_min = true;
    return true;
  }
  if(monoid_name == ".pq_max") {
    is_min = false;
    return true;
  }
  return false;
}

bool scalar_string_non_missing(SEXP x) {
  return TYPEOF(x) == STRSXP && XLENGTH(x) == 1 && STRING_ELT(x, 0) != NA_STRING;
}

bool scalar_logical_non_missing(SEXP x) {
  if(TYPEOF(x) != LGLSXP || XLENGTH(x) != 1) {
    return false;
  }
  return LOGICAL(x)[0] != NA_LOGICAL;
}

bool scalar_numeric_non_missing(SEXP x) {
  if(TYPEOF(x) == REALSXP && XLENGTH(x) == 1) {
    const double v = REAL(x)[0];
    return !ISNA(v) && !ISNAN(v);
  }
  if(TYPEOF(x) == INTSXP && XLENGTH(x) == 1) {
    return INTEGER(x)[0] != NA_INTEGER;
  }
  return false;
}

bool has_non_fast_numeric_class(SEXP x) {
  if(TYPEOF(x) != REALSXP && TYPEOF(x) != INTSXP) {
    return false;
  }
  if(Rf_inherits(x, "Date") || Rf_inherits(x, "POSIXct")) {
    return false;
  }
  SEXP cls = Rf_getAttrib(x, class_sym);
  return !Rf_isNull(cls) && XLENGTH(cls) > 0;
}

enum class ScalarKind {
  UNKNOWN = 0,
  NUMERIC,
  CHARACTER,
  LOGICAL,
  DATE,
  POSIXCT
};

const char* scalar_kind_name(ScalarKind kind) {
  switch(kind) {
  case ScalarKind::NUMERIC:
    return "numeric";
  case ScalarKind::CHARACTER:
    return "character";
  case ScalarKind::LOGICAL:
    return "logical";
  case ScalarKind::DATE:
    return "Date";
  case ScalarKind::POSIXCT:
    return "POSIXct";
  default:
    return "";
  }
}

ScalarKind scalar_kind_from_type_name(SEXP type_name) {
  if(!scalar_string_non_missing(type_name)) {
    return ScalarKind::UNKNOWN;
  }
  const std::string t = as<std::string>(type_name);
  if(t == "numeric") {
    return ScalarKind::NUMERIC;
  }
  if(t == "character") {
    return ScalarKind::CHARACTER;
  }
  if(t == "logical") {
    return ScalarKind::LOGICAL;
  }
  if(t == "Date") {
    return ScalarKind::DATE;
  }
  if(t == "POSIXct") {
    return ScalarKind::POSIXCT;
  }
  return ScalarKind::UNKNOWN;
}

ScalarKind scalar_kind_from_value(SEXP x) {
  if(scalar_string_non_missing(x)) {
    return ScalarKind::CHARACTER;
  }
  if(scalar_logical_non_missing(x)) {
    return ScalarKind::LOGICAL;
  }
  if(scalar_numeric_non_missing(x)) {
    if(Rf_inherits(x, "Date")) {
      return ScalarKind::DATE;
    }
    if(Rf_inherits(x, "POSIXct")) {
      return ScalarKind::POSIXCT;
    }
    if(has_non_fast_numeric_class(x)) {
      return ScalarKind::UNKNOWN;
    }
    return ScalarKind::NUMERIC;
  }
  return ScalarKind::UNKNOWN;
}

double scalar_numeric_value(SEXP x) {
  return TYPEOF(x) == REALSXP ? REAL(x)[0] : static_cast<double>(INTEGER(x)[0]);
}

bool scalar_compare_fast(SEXP a, SEXP b, ScalarKind kind, int& cmp_out) {
  if(kind == ScalarKind::CHARACTER) {
    if(!scalar_string_non_missing(a) || !scalar_string_non_missing(b)) {
      return false;
    }
    const std::string sa = as<std::string>(a);
    const std::string sb = as<std::string>(b);
    if(sa < sb) cmp_out = -1;
    else if(sa > sb) cmp_out = 1;
    else cmp_out = 0;
    return true;
  }

  if(kind == ScalarKind::LOGICAL) {
    if(!scalar_logical_non_missing(a) || !scalar_logical_non_missing(b)) {
      return false;
    }
    const int ia = LOGICAL(a)[0];
    const int ib = LOGICAL(b)[0];
    if(ia < ib) cmp_out = -1;
    else if(ia > ib) cmp_out = 1;
    else cmp_out = 0;
    return true;
  }

  if(kind == ScalarKind::NUMERIC || kind == ScalarKind::DATE || kind == ScalarKind::POSIXCT) {
    if(!scalar_numeric_non_missing(a) || !scalar_numeric_non_missing(b)) {
      return false;
    }
    if(kind == ScalarKind::NUMERIC) {
      if(Rf_inherits(a, "Date") || Rf_inherits(a, "POSIXct") || Rf_inherits(b, "Date") || Rf_inherits(b, "POSIXct")) {
        return false;
      }
      if(has_non_fast_numeric_class(a) || has_non_fast_numeric_class(b)) {
        return false;
      }
    } else if(kind == ScalarKind::DATE) {
      if(!Rf_inherits(a, "Date") || !Rf_inherits(b, "Date")) {
        return false;
      }
    } else {
      if(!Rf_inherits(a, "POSIXct") || !Rf_inherits(b, "POSIXct")) {
        return false;
      }
    }
    const double da = scalar_numeric_value(a);
    const double db = scalar_numeric_value(b);
    if(da < db) cmp_out = -1;
    else if(da > db) cmp_out = 1;
    else cmp_out = 0;
    return true;
  }

  return false;
}

bool pq_extract_priority_from_entry(SEXP x, SEXP& priority_out) {
  if(TYPEOF(x) != VECSXP) {
    return false;
  }
  List el(x);
  if(!el.containsElementNamed("priority")) {
    return false;
  }
  SEXP priority = el["priority"];
  if(Rf_isNull(priority) || XLENGTH(priority) != 1) {
    return false;
  }
  priority_out = priority;
  return true;
}

bool oms_extract_key_from_entry(SEXP x, SEXP& key_out) {
  if(TYPEOF(x) != VECSXP) {
    return false;
  }
  List el(x);
  SEXP key = R_NilValue;
  if(el.containsElementNamed("key")) {
    key = el["key"];
  } else if(el.size() >= 2) {
    key = el[1];
  } else {
    return false;
  }
  if(Rf_isNull(key) || XLENGTH(key) != 1) {
    return false;
  }
  key_out = key;
  return true;
}

bool ivx_extract_start_from_entry(SEXP x, SEXP& start_out) {
  if(TYPEOF(x) != VECSXP) {
    return false;
  }
  List el(x);
  SEXP start = R_NilValue;
  if(el.containsElementNamed("start")) {
    start = el["start"];
  } else if(el.size() >= 2) {
    start = el[1];
  } else {
    return false;
  }
  if(Rf_isNull(start) || XLENGTH(start) != 1) {
    return false;
  }
  start_out = start;
  return true;
}

bool measure_parse_has(SEXP measure, bool& has_out, SEXP& payload_out, const char* payload_name, int payload_idx);

bool pq_parse_measure(SEXP measure, bool& has_out, SEXP& priority_out) {
  return measure_parse_has(measure, has_out, priority_out, "priority", 1);
}

SEXP pq_make_measure(SEXP priority) {
  return List::create(_["has"] = true, _["priority"] = priority);
}

bool pq_combine_measure_fast(SEXP left, SEXP right, bool is_min, SEXP& out) {
  bool left_has = false;
  bool right_has = false;
  SEXP left_priority = R_NilValue;
  SEXP right_priority = R_NilValue;
  if(!pq_parse_measure(left, left_has, left_priority) || !pq_parse_measure(right, right_has, right_priority)) {
    return false;
  }
  if(!left_has) {
    out = right;
    return true;
  }
  if(!right_has) {
    out = left;
    return true;
  }
  int cmp = 0;
  const ScalarKind kind = scalar_kind_from_value(left_priority);
  if(kind == ScalarKind::UNKNOWN || !scalar_compare_fast(left_priority, right_priority, kind, cmp)) {
    return false;
  }
  const bool take_left = is_min ? (cmp <= 0) : (cmp >= 0);
  out = take_left ? left : right;
  return true;
}

bool measure_parse_has(SEXP measure, bool& has_out, SEXP& payload_out, const char* payload_name, int payload_idx) {
  if(TYPEOF(measure) != VECSXP) {
    return false;
  }
  List m(measure);
  SEXP has_val = R_NilValue;
  if(m.containsElementNamed("has")) {
    has_val = m["has"];
  } else if(m.size() >= 1) {
    has_val = m[0];
  } else {
    return false;
  }
  if(TYPEOF(has_val) != LGLSXP || XLENGTH(has_val) != 1) {
    return false;
  }
  const int hv = LOGICAL(has_val)[0];
  if(hv == NA_LOGICAL) {
    return false;
  }
  has_out = hv == 1;
  if(!has_out) {
    payload_out = R_NilValue;
    return true;
  }

  SEXP payload = R_NilValue;
  if(m.containsElementNamed(payload_name)) {
    payload = m[payload_name];
  } else if(m.size() > payload_idx) {
    payload = m[payload_idx];
  } else {
    return false;
  }
  if(Rf_isNull(payload) || XLENGTH(payload) != 1) {
    return false;
  }
  payload_out = payload;
  return true;
}

bool oms_parse_measure(SEXP measure, bool& has_out, SEXP& key_out, ScalarKind& kind_out) {
  if(!measure_parse_has(measure, has_out, key_out, "key", 1)) {
    return false;
  }
  kind_out = ScalarKind::UNKNOWN;
  if(!has_out) {
    return true;
  }
  List m(measure);
  SEXP type_val = R_NilValue;
  if(m.containsElementNamed("key_type")) {
    type_val = m["key_type"];
  } else if(m.size() >= 3) {
    type_val = m[2];
  }
  kind_out = scalar_kind_from_type_name(type_val);
  if(kind_out == ScalarKind::UNKNOWN) {
    kind_out = scalar_kind_from_value(key_out);
  }
  return true;
}

bool ivx_parse_measure(SEXP measure, bool& has_out, SEXP& start_out, ScalarKind& kind_out) {
  if(!measure_parse_has(measure, has_out, start_out, "start", 1)) {
    return false;
  }
  kind_out = ScalarKind::UNKNOWN;
  if(!has_out) {
    return true;
  }
  List m(measure);
  SEXP type_val = R_NilValue;
  if(m.containsElementNamed("endpoint_type")) {
    type_val = m["endpoint_type"];
  } else if(m.size() >= 3) {
    type_val = m[2];
  }
  kind_out = scalar_kind_from_type_name(type_val);
  if(kind_out == ScalarKind::UNKNOWN) {
    kind_out = scalar_kind_from_value(start_out);
  }
  return true;
}

SEXP oms_make_measure(SEXP key, ScalarKind kind) {
  return List::create(_["has"] = true, _["key"] = key, _["key_type"] = scalar_kind_name(kind));
}

SEXP ivx_make_measure(SEXP start, ScalarKind kind) {
  return List::create(_["has"] = true, _["start"] = start, _["endpoint_type"] = scalar_kind_name(kind));
}

bool oms_combine_measure_fast(SEXP left, SEXP right, SEXP& out) {
  bool left_has = false;
  bool right_has = false;
  SEXP left_key = R_NilValue;
  SEXP right_key = R_NilValue;
  ScalarKind left_kind = ScalarKind::UNKNOWN;
  ScalarKind right_kind = ScalarKind::UNKNOWN;
  if(!oms_parse_measure(left, left_has, left_key, left_kind) || !oms_parse_measure(right, right_has, right_key, right_kind)) {
    return false;
  }
  if(!left_has) {
    out = right;
    return true;
  }
  if(!right_has) {
    out = left;
    return true;
  }
  if(left_kind == ScalarKind::UNKNOWN || right_kind == ScalarKind::UNKNOWN || left_kind != right_kind) {
    return false;
  }
  int cmp = 0;
  if(!scalar_compare_fast(left_key, right_key, left_kind, cmp)) {
    return false;
  }
  out = (cmp >= 0) ? left : right;
  return true;
}

bool ivx_combine_measure_fast(SEXP left, SEXP right, SEXP& out) {
  bool left_has = false;
  bool right_has = false;
  SEXP left_start = R_NilValue;
  SEXP right_start = R_NilValue;
  ScalarKind left_kind = ScalarKind::UNKNOWN;
  ScalarKind right_kind = ScalarKind::UNKNOWN;
  if(!ivx_parse_measure(left, left_has, left_start, left_kind) || !ivx_parse_measure(right, right_has, right_start, right_kind)) {
    return false;
  }
  if(!left_has) {
    out = right;
    return true;
  }
  if(!right_has) {
    out = left;
    return true;
  }
  if(left_kind == ScalarKind::UNKNOWN || right_kind == ScalarKind::UNKNOWN || left_kind != right_kind) {
    return false;
  }
  int cmp = 0;
  if(!scalar_compare_fast(left_start, right_start, left_kind, cmp)) {
    return false;
  }
  out = (cmp >= 0) ? left : right;
  return true;
}

// Native compound interval-index query walk.
//
// Walks a pre-partitioned candidate subtree leaf-by-leaf, applying the relation
// predicate at each leaf, and pruning entire subtrees via the cached
// .ivx_max_end measure where applicable (point / overlaps / containing). For
// "within" there is no max_end prune (max_end provides no useful upper bound).
//
// Peek-only (with_unmatched = FALSE) in this task; pop-side fields come later.

// Predicate: 1 = match, 0 = miss, -1 = NA (compare failed). entries are leaf
// records list(value, start, end, key) per R/60-interval_index-internals.R
// (.ivx_make_entry); we read $start at index 1 and $end at index 2 by
// VECTOR_ELT.
int ivx_native_predicate(
    SEXP s, SEXP en,
    const std::string& relation_kind,
    SEXP qlo, SEXP qhi,
    ScalarKind kind,
    bool include_start, bool include_end
) {
  if(relation_kind == "point") {
    int cmp_lo = 0, cmp_hi = 0;
    if(!scalar_compare_fast(qlo, s,  kind, cmp_lo)) return -1;
    if(!scalar_compare_fast(qlo, en, kind, cmp_hi)) return -1;
    bool left_ok  = include_start ? (cmp_lo >= 0) : (cmp_lo > 0);
    bool right_ok = include_end   ? (cmp_hi <= 0) : (cmp_hi < 0);
    return (left_ok && right_ok) ? 1 : 0;
  }
  if(relation_kind == "overlaps") {
    bool touching_is_overlap = include_start && include_end;
    int cmp_aend_blo = 0, cmp_bend_alo = 0;
    if(!scalar_compare_fast(en,  qlo, kind, cmp_aend_blo)) return -1;
    if(!scalar_compare_fast(qhi, s,   kind, cmp_bend_alo)) return -1;
    bool a_before_b = touching_is_overlap ? (cmp_aend_blo < 0) : (cmp_aend_blo <= 0);
    bool b_before_a = touching_is_overlap ? (cmp_bend_alo < 0) : (cmp_bend_alo <= 0);
    return (!(a_before_b || b_before_a)) ? 1 : 0;
  }
  if(relation_kind == "containing") {
    // Mirrors R .ivx_spec_containing leaf_match:
    //   contains: start <= qlo && end >= qhi (always inclusive)
    //   then overlaps with touching_is_overlap = include_start && include_end
    int cmp_s_lo = 0, cmp_e_hi = 0;
    if(!scalar_compare_fast(s,  qlo, kind, cmp_s_lo)) return -1;
    if(!scalar_compare_fast(en, qhi, kind, cmp_e_hi)) return -1;
    if(!(cmp_s_lo <= 0 && cmp_e_hi >= 0)) return 0;
    bool touching_is_overlap = include_start && include_end;
    int cmp_e_lo = 0, cmp_hi_s = 0;
    if(!scalar_compare_fast(en,  qlo, kind, cmp_e_lo)) return -1;
    if(!scalar_compare_fast(qhi, s,   kind, cmp_hi_s)) return -1;
    bool a_before_b = touching_is_overlap ? (cmp_e_lo < 0) : (cmp_e_lo <= 0);
    bool b_before_a = touching_is_overlap ? (cmp_hi_s < 0) : (cmp_hi_s <= 0);
    return (!(a_before_b || b_before_a)) ? 1 : 0;
  }
  if(relation_kind == "within") {
    // Mirrors R .ivx_spec_within leaf_match:
    //   within: qlo <= start && qhi >= end (always inclusive)
    //   then overlaps with touching_is_overlap = include_start && include_end
    int cmp_s_lo = 0, cmp_e_hi = 0;
    if(!scalar_compare_fast(s,  qlo, kind, cmp_s_lo)) return -1;
    if(!scalar_compare_fast(en, qhi, kind, cmp_e_hi)) return -1;
    if(!(cmp_s_lo >= 0 && cmp_e_hi <= 0)) return 0;
    bool touching_is_overlap = include_start && include_end;
    int cmp_e_lo = 0, cmp_hi_s = 0;
    if(!scalar_compare_fast(en,  qlo, kind, cmp_e_lo)) return -1;
    if(!scalar_compare_fast(qhi, s,   kind, cmp_hi_s)) return -1;
    bool a_before_b = touching_is_overlap ? (cmp_e_lo < 0) : (cmp_e_lo <= 0);
    bool b_before_a = touching_is_overlap ? (cmp_hi_s < 0) : (cmp_hi_s <= 0);
    return (!(a_before_b || b_before_a)) ? 1 : 0;
  }
  return -1;
}

// Read the .size measure from a structural node; returns subtree leaf count.
// .size is stored as a numeric (double) scalar in the measures named list.
int ivx_native_subtree_size(SEXP node) {
  if(!is_structural_node_cpp(node)) return 1;
  if(has_class(node, "Empty")) return 0;
  List ms = Rf_getAttrib(node, measures_sym);
  if(ms.containsElementNamed(".size")) {
    SEXP s = ms[".size"];
    if(TYPEOF(s) == INTSXP && Rf_xlength(s) >= 1) return INTEGER(s)[0];
    if(TYPEOF(s) == REALSXP && Rf_xlength(s) >= 1) return (int) REAL(s)[0];
  }
  return (int) compute_tree_size_fallback(node);
}

// Returns true if the subtree can be pruned: its max_end is strictly less than
// the prune threshold (qpt for point, qlo for overlaps, qhi for containing).
// "has = FALSE" indicates the subtree contributes no entries (Empty); we treat
// that as prunable.
bool ivx_native_can_prune(
    SEXP node,
    SEXP prune_threshold,
    ScalarKind kind
) {
  if(!is_structural_node_cpp(node)) return false;
  List ms = Rf_getAttrib(node, measures_sym);
  if(!ms.containsElementNamed(".ivx_max_end")) return false;
  SEXP me = ms[".ivx_max_end"];
  if(TYPEOF(me) != VECSXP) return false;
  List me_list(me);
  if(me_list.containsElementNamed("has")) {
    SEXP has_val = me_list["has"];
    if(TYPEOF(has_val) == LGLSXP && Rf_xlength(has_val) >= 1) {
      if(LOGICAL(has_val)[0] == FALSE) return true;
    }
  }
  if(!me_list.containsElementNamed("end")) return false;
  SEXP end_val = me_list["end"];
  if(end_val == R_NilValue) return false;
  int cmp = 0;
  if(!scalar_compare_fast(end_val, prune_threshold, kind, cmp)) return false;
  return cmp < 0;
}

// Recursively walk a structural subtree, appending every leaf to `out`
// (in left-to-right order). Used to drain pruned subtrees into the
// unmatched accumulator.
void ivx_native_collect_leaves(SEXP node, std::vector<SEXP>& out) {
  if(node == R_NilValue) return;

  if(!is_structural_node_cpp(node)) {
    // Leaf entry
    out.push_back(node);
    return;
  }

  if(has_class(node, "Empty")) return;

  if(has_class(node, "Single")) {
    List s(node);
    ivx_native_collect_leaves(s[0], out);
    return;
  }

  if(has_class(node, "Deep")) {
    List d(node);
    ivx_native_collect_leaves(d["prefix"], out);
    ivx_native_collect_leaves(d["middle"], out);
    ivx_native_collect_leaves(d["suffix"], out);
    return;
  }

  // Digit / Node / Node2 / Node3 — iterate children left-to-right
  List xs(node);
  R_xlen_t n = xs.size();
  for(R_xlen_t i = 0; i < n; ++i) {
    ivx_native_collect_leaves(xs[i], out);
  }
}

// Recursive walk. Returns false to signal "stop the walk" (used for want_first
// after the first match has been recorded AND with_unmatched is false).
//
// When `with_unmatched` is true:
//   - Pre-match leaf misses are appended to `unmatched`.
//   - After a match has been recorded under `want_first`, remaining leaves are
//     drained into `unmatched` without predicate evaluation. The flag
//     `first_already_found` signals this post-match drain mode.
//   - Pruned subtrees have all of their leaves collected into `unmatched`.
bool ivx_native_walk_node(
    SEXP node,
    const std::string& relation_kind,
    SEXP qlo, SEXP qhi,
    ScalarKind kind,
    bool include_start, bool include_end,
    bool prune_enabled,
    SEXP prune_threshold,
    bool want_first,
    int& position_counter,
    std::vector<SEXP>& matched,
    std::vector<int>& matched_indices,
    bool with_unmatched,
    std::vector<SEXP>& unmatched,
    bool& first_already_found
) {
  if(node == R_NilValue) return true;

  if(!is_structural_node_cpp(node)) {
    // Leaf entry
    if(TYPEOF(node) != VECSXP || Rf_xlength(node) < 3) {
      position_counter += 1;
      return true;
    }

    // Post-match drain: everything else goes to unmatched without predicate.
    if(want_first && first_already_found) {
      if(with_unmatched) unmatched.push_back(node);
      position_counter += 1;
      return true;
    }

    SEXP s  = VECTOR_ELT(node, 1);
    SEXP en = VECTOR_ELT(node, 2);
    int hit = ivx_native_predicate(s, en, relation_kind, qlo, qhi, kind,
                                   include_start, include_end);
    if(hit == 1) {
      matched.push_back(node);
      matched_indices.push_back(position_counter);
      position_counter += 1;
      if(want_first) {
        first_already_found = true;
        // If we're collecting unmatched, keep walking to drain the remainder.
        // Otherwise stop immediately.
        if(!with_unmatched) return false;
      }
      return true;
    }
    if(with_unmatched) unmatched.push_back(node);
    position_counter += 1;
    return true;
  }

  // Structural node: try max_end prune
  if(prune_enabled && ivx_native_can_prune(node, prune_threshold, kind)) {
    if(with_unmatched) {
      // Drain the pruned subtree's leaves into unmatched. In post-match drain
      // mode they're going to unmatched anyway; same destination either way.
      ivx_native_collect_leaves(node, unmatched);
    }
    position_counter += ivx_native_subtree_size(node);
    return true;
  }

  if(has_class(node, "Empty")) return true;

  if(has_class(node, "Single")) {
    List s(node);
    return ivx_native_walk_node(
      s[0], relation_kind, qlo, qhi, kind,
      include_start, include_end,
      prune_enabled, prune_threshold,
      want_first, position_counter, matched, matched_indices,
      with_unmatched, unmatched, first_already_found
    );
  }

  if(has_class(node, "Deep")) {
    List d(node);
    SEXP prefix = d["prefix"];
    SEXP middle = d["middle"];
    SEXP suffix = d["suffix"];
    if(!ivx_native_walk_node(prefix, relation_kind, qlo, qhi, kind,
                             include_start, include_end,
                             prune_enabled, prune_threshold,
                             want_first, position_counter, matched, matched_indices,
                             with_unmatched, unmatched, first_already_found)) return false;
    if(!ivx_native_walk_node(middle, relation_kind, qlo, qhi, kind,
                             include_start, include_end,
                             prune_enabled, prune_threshold,
                             want_first, position_counter, matched, matched_indices,
                             with_unmatched, unmatched, first_already_found)) return false;
    if(!ivx_native_walk_node(suffix, relation_kind, qlo, qhi, kind,
                             include_start, include_end,
                             prune_enabled, prune_threshold,
                             want_first, position_counter, matched, matched_indices,
                             with_unmatched, unmatched, first_already_found)) return false;
    return true;
  }

  // Digit / Node / Node2 / Node3 — iterate children left-to-right
  List xs(node);
  R_xlen_t n = xs.size();
  for(R_xlen_t i = 0; i < n; ++i) {
    if(!ivx_native_walk_node(xs[i], relation_kind, qlo, qhi, kind,
                             include_start, include_end,
                             prune_enabled, prune_threshold,
                             want_first, position_counter, matched, matched_indices,
                             with_unmatched, unmatched, first_already_found)) return false;
  }
  return true;
}

// Forward declaration: defined later in the file, needed here for rebuilding
// matched/unmatched trees from sorted accumulators.
SEXP tree_from_sorted_list_cpp(const List& xs, const List& monoids);

SEXP ivx_native_query_impl(
    SEXP candidate_tree,
    const std::string& relation_kind,
    SEXP qlo, SEXP qhi,
    List bounds_flags,
    int endpoint_kind,
    const std::string& which,
    bool with_unmatched,
    SEXP monoids_sexp,
    bool as_list
) {
  ScalarKind kind;
  if(endpoint_kind == 1 || endpoint_kind == 2) {
    kind = ScalarKind::NUMERIC;
  } else {
    stop("ivx_native_query: unsupported endpoint_kind");
  }

  bool include_start = as<bool>(bounds_flags["include_start"]);
  bool include_end   = as<bool>(bounds_flags["include_end"]);

  bool prune_enabled = (relation_kind != "within");
  SEXP prune_threshold = R_NilValue;
  if(relation_kind == "point")           prune_threshold = qlo;
  else if(relation_kind == "overlaps")   prune_threshold = qlo;
  else if(relation_kind == "containing") prune_threshold = qhi;
  else if(relation_kind == "within")     prune_threshold = R_NilValue;
  else stop("ivx_native_query: unknown relation_kind");

  std::vector<SEXP> matched;
  std::vector<int> matched_indices;
  std::vector<SEXP> unmatched;
  int position_counter = 1;  // 1-based, relative to candidate
  bool want_first = (which == "first");
  bool first_already_found = false;

  ivx_native_walk_node(
    candidate_tree, relation_kind, qlo, qhi, kind,
    include_start, include_end,
    prune_enabled, prune_threshold,
    want_first, position_counter, matched, matched_indices,
    with_unmatched, unmatched, first_already_found
  );

  R_xlen_t m = (R_xlen_t) matched.size();
  List matched_list(m);
  for(R_xlen_t i = 0; i < m; ++i) matched_list[i] = matched[(size_t) i];
  IntegerVector indices_vec(m);
  for(R_xlen_t i = 0; i < m; ++i) indices_vec[i] = matched_indices[(size_t) i];

  if(!with_unmatched) {
    // Peek path. For which == "all", optionally build the final result shape
    // directly so R-side dispatch doesn't have to re-walk the matched list.
    // The extra fields are opt-in: as_list = TRUE adds parallel vectors;
    // as_list = FALSE adds matched_tree iff monoids were supplied.
    if(which == "all" && as_list) {
      // Parallel-vector shape: values + scalar-SEXP lists for starts/ends.
      // R-side caller runs .ivx_simplify_endpoints on starts_l/ends_l.
      List values_list(m);
      List starts_l(m);
      List ends_l(m);
      for(R_xlen_t i = 0; i < m; ++i) {
        SEXP entry = matched[(size_t) i];
        values_list[i] = VECTOR_ELT(entry, 0);
        starts_l[i]   = VECTOR_ELT(entry, 1);
        ends_l[i]     = VECTOR_ELT(entry, 2);
      }
      return List::create(
        _["matched"]         = matched_list,
        _["matched_indices"] = indices_vec,
        _["values"]          = values_list,
        _["starts_l"]        = starts_l,
        _["ends_l"]          = ends_l
      );
    }
    if(which == "all" && !as_list && monoids_sexp != R_NilValue && TYPEOF(monoids_sexp) == VECSXP) {
      // Slice shape: build matched_tree natively (skips the C++ -> R -> C++
      // round trip through .ivx_tree_from_ordered_entries).
      List monoids(monoids_sexp);
      Shield<SEXP> matched_tree(tree_from_sorted_list_cpp(matched_list, monoids));
      return List::create(
        _["matched"]         = matched_list,
        _["matched_indices"] = indices_vec,
        _["matched_tree"]    = (SEXP) matched_tree
      );
    }
    // Legacy / first-hit shape (engine pre-Task-3 still uses this for which="all").
    return List::create(
      _["matched"]         = matched_list,
      _["matched_indices"] = indices_vec
    );
  }

  // Build unmatched_tree (and matched_tree for which == "all") from the
  // accumulators. Both accumulators are in left-to-right (sorted) order.
  if(monoids_sexp == R_NilValue || TYPEOF(monoids_sexp) != VECSXP) {
    stop("ivx_native_query: monoids required when with_unmatched = TRUE");
  }
  List monoids(monoids_sexp);

  R_xlen_t u = (R_xlen_t) unmatched.size();
  List unmatched_list(u);
  for(R_xlen_t i = 0; i < u; ++i) unmatched_list[i] = unmatched[(size_t) i];
  Shield<SEXP> unmatched_tree(tree_from_sorted_list_cpp(unmatched_list, monoids));

  if(which == "all") {
    Shield<SEXP> matched_tree(tree_from_sorted_list_cpp(matched_list, monoids));
    return List::create(
      _["matched"]         = matched_list,
      _["matched_indices"] = indices_vec,
      _["unmatched_tree"]  = (SEXP) unmatched_tree,
      _["matched_tree"]    = (SEXP) matched_tree
    );
  }

  return List::create(
    _["matched"]         = matched_list,
    _["matched_indices"] = indices_vec,
    _["unmatched_tree"]  = (SEXP) unmatched_tree
  );
}

bool monoid_combine_fast(SEXP left, SEXP right, const std::string& monoid_name, SEXP& out) {
  bool is_min = false;
  if(monoid_name_is_pq_minmax(monoid_name, is_min)) {
    return pq_combine_measure_fast(left, right, is_min, out);
  }
  if(monoid_name == ".oms_max_key") {
    return oms_combine_measure_fast(left, right, out);
  }
  if(monoid_name == ".ivx_max_start") {
    return ivx_combine_measure_fast(left, right, out);
  }
  return false;
}

SEXP monoid_combine(
  SEXP left,
  SEXP right,
  const std::string& monoid_name,
  const List& monoid_spec,
  const Function* maybe_f = nullptr
) {
  SEXP fast = R_NilValue;
  if(monoid_combine_fast(left, right, monoid_name, fast)) {
    return fast;
  }
  if(maybe_f != nullptr) {
    return (*maybe_f)(left, right);
  }
  Function f = as<Function>(list_get_named_or_index(monoid_spec, "f", 0));
  return f(left, right);
}

SEXP monoid_measure_for_child(SEXP ch, const std::string& monoid_name, const List& monoid_spec);

List measures_from_children(const List& children, const List& monoids) {
  CharacterVector nms = monoids.names();
  List out(nms.size());
  out.attr("names") = nms;
  for(int i = 0; i < nms.size(); ++i) {
    std::string nm = CharacterVector::is_na(nms[i]) ? std::string() : as<std::string>(nms[i]);
    if(nm == ".size") {
      double s = 0.0;
      for(int j = 0; j < children.size(); ++j) {
        s += child_size(children[j]);
      }
      out[i] = s;
      continue;
    }
    if(nm == ".named_count") {
      int c = 0;
      for(int j = 0; j < children.size(); ++j) {
        c += child_named_count(children[j]);
      }
      out[i] = c;
      continue;
    }

    List r = as<List>(monoids[i]);
    Function f = as<Function>(list_get_named_or_index(r, "f", 0));
    ReprotectSEXP acc(list_get_named_or_index(r, "i", 1));
    for(int j = 0; j < children.size(); ++j) {
      SEXP ch = children[j];
      SEXP mv = R_NilValue;
      if(has_class(ch, "FingerTree") || has_class(ch, "Digit") || has_class(ch, "Node")) {
        List cms = Rf_getAttrib(ch, measures_sym);
        if(!Rf_isNull(cms) && i < cms.size() && !Rf_isNull(cms[i])) {
          mv = cms[i];
        }
      }
      if(Rf_isNull(mv)) {
        mv = monoid_measure_for_child(ch, nm, r);
      }
      Shield<SEXP> mv_protected(mv);
      Shield<SEXP> next(monoid_combine(acc.get(), (SEXP)mv_protected, nm, r, &f));
      acc.set((SEXP)next);
    }
    out[i] = acc.get();
  }
  return out;
}

List measures_empty(const List& monoids) {
  CharacterVector nms = monoids.names();
  List out(nms.size());
  out.attr("names") = nms;
  for(int i = 0; i < nms.size(); ++i) {
    std::string nm = CharacterVector::is_na(nms[i]) ? std::string() : as<std::string>(nms[i]);
    if(nm == ".size") out[i] = 0.0;
    else if(nm == ".named_count") out[i] = 0;
    else {
      List r = as<List>(monoids[i]);
      out[i] = list_get_named_or_index(r, "i", 1);
    }
  }
  return out;
}

SEXP make_empty(const List& monoids) {
  List e = List::create(R_NilValue);
  e.attr("class") = CharacterVector::create("Empty", "FingerTree", "list");
  e.attr("monoids") = monoids;
  e.attr("measures") = measures_empty(monoids);
  return e;
}

SEXP make_single(SEXP el, const List& monoids) {
  List s = List::create(el);
  s.attr("class") = CharacterVector::create("Single", "FingerTree", "list");
  s.attr("monoids") = monoids;
  List children = List::create(el);
  s.attr("measures") = measures_from_children(children, monoids);
  return s;
}

SEXP make_digit(const List& children, const List& monoids) {
  List d(children.size());
  for(int i = 0; i < children.size(); ++i) d[i] = children[i];
  d.attr("class") = CharacterVector::create("Digit", "list");
  d.attr("monoids") = monoids;
  d.attr("measures") = measures_from_children(children, monoids);
  return d;
}

SEXP make_node3(SEXP a, SEXP b, SEXP c, const List& monoids) {
  List n = List::create(a, b, c);
  n.attr("class") = CharacterVector::create("Node3", "Node", "list");
  n.attr("monoids") = monoids;
  List children = List::create(a, b, c);
  n.attr("measures") = measures_from_children(children, monoids);
  return n;
}

SEXP make_node2(SEXP a, SEXP b, const List& monoids) {
  List n = List::create(a, b);
  n.attr("class") = CharacterVector::create("Node2", "Node", "list");
  n.attr("monoids") = monoids;
  List children = List::create(a, b);
  n.attr("measures") = measures_from_children(children, monoids);
  return n;
}

SEXP make_deep(SEXP prefix, SEXP middle, SEXP suffix, const List& monoids) {
  List d = List::create(_["prefix"] = prefix, _["middle"] = middle, _["suffix"] = suffix);
  d.attr("class") = CharacterVector::create("Deep", "FingerTree", "list");
  d.attr("monoids") = monoids;
  List children = List::create(prefix, middle, suffix);
  d.attr("measures") = measures_from_children(children, monoids);
  return d;
}

SEXP add_right_cpp(SEXP t, SEXP el, const List& monoids) {
  if(has_class(t, "Empty")) {
    return make_single(el, monoids);
  }
  if(has_class(t, "Single")) {
    List s(t);
    Shield<SEXP> prefix(make_digit(List::create(s[0]), monoids));
    Shield<SEXP> middle(make_empty(monoids));
    Shield<SEXP> suffix(make_digit(List::create(el), monoids));
    return make_deep(prefix, middle, suffix, monoids);
  }
  if(has_class(t, "Digit")) {
    List d(t);
    List children(d.size() + 1);
    for(int i = 0; i < d.size(); ++i) children[i] = d[i];
    children[d.size()] = el;
    return make_digit(children, monoids);
  }
  if(has_class(t, "Deep")) {
    List d(t);
    List suffix = d["suffix"];
    if(suffix.size() == 4) {
      Shield<SEXP> new_suffix(make_digit(List::create(suffix[3], el), monoids));
      Shield<SEXP> middle_node(make_node3(suffix[0], suffix[1], suffix[2], monoids));
      Shield<SEXP> new_middle(add_right_cpp(d["middle"], middle_node, monoids));
      return make_deep(d["prefix"], new_middle, new_suffix, monoids);
    }
    Shield<SEXP> new_suffix(add_right_cpp(d["suffix"], el, monoids));
    return make_deep(d["prefix"], d["middle"], new_suffix, monoids);
  }
  stop("Unsupported node type in ft_cpp_append_right.");
}

SEXP add_left_cpp(SEXP t, SEXP el, const List& monoids) {
  if(has_class(t, "Empty")) {
    return make_single(el, monoids);
  }
  if(has_class(t, "Single")) {
    List s(t);
    Shield<SEXP> prefix(make_digit(List::create(el), monoids));
    Shield<SEXP> middle(make_empty(monoids));
    Shield<SEXP> suffix(make_digit(List::create(s[0]), monoids));
    return make_deep(prefix, middle, suffix, monoids);
  }
  if(has_class(t, "Digit")) {
    List d(t);
    List children(d.size() + 1);
    children[0] = el;
    for(int i = 0; i < d.size(); ++i) children[i + 1] = d[i];
    return make_digit(children, monoids);
  }
  if(has_class(t, "Deep")) {
    List d(t);
    List prefix = d["prefix"];
    if(prefix.size() == 4) {
      Shield<SEXP> new_prefix(make_digit(List::create(el, prefix[0]), monoids));
      Shield<SEXP> middle_node(make_node3(prefix[1], prefix[2], prefix[3], monoids));
      Shield<SEXP> new_middle(add_left_cpp(d["middle"], middle_node, monoids));
      return make_deep(new_prefix, new_middle, d["suffix"], monoids);
    }
    Shield<SEXP> new_prefix(add_left_cpp(d["prefix"], el, monoids));
    return make_deep(new_prefix, d["middle"], d["suffix"], monoids);
  }
  stop("Unsupported node type in ft_cpp_prepend_left.");
}

SEXP clone_with_name(SEXP el, SEXP name_) {
  SEXP out = PROTECT(Rf_duplicate(el));
  CharacterVector nm(name_);
  if(nm.size() != 1 || CharacterVector::is_na(nm[0])) {
    UNPROTECT(1);
    stop("`name` must be a single non-empty string.");
  }
  std::string s = as<std::string>(nm[0]);
  if(s.empty()) {
    UNPROTECT(1);
    stop("`name` must be a single non-empty string.");
  }
  Rf_setAttrib(out, ft_name_sym, Rf_mkString(s.c_str()));
  UNPROTECT(1);
  return out;
}

SEXP clone_with_attrs(SEXP el, SEXP name_) {
  SEXP out = PROTECT(Rf_duplicate(el));

  if(!Rf_isNull(name_)) {
    CharacterVector nm(name_);
    if(nm.size() != 1 || CharacterVector::is_na(nm[0])) {
      UNPROTECT(1);
      stop("Element names must be scalar, non-missing, and non-empty.");
    }
    std::string s = as<std::string>(nm[0]);
    if(s.empty()) {
      UNPROTECT(1);
      stop("Element names must be scalar, non-missing, and non-empty.");
    }
    if(Rf_isNull(out)) {
      UNPROTECT(1);
      stop("Cannot attach a name to NULL element.");
    }
    Rf_setAttrib(out, ft_name_sym, Rf_mkString(s.c_str()));
  }

  UNPROTECT(1);
  return out;
}

List prepare_elements_with_names_cpp(const List& elements, SEXP names_) {
  if(Rf_isNull(names_)) {
    return elements;
  }
  if(TYPEOF(names_) != STRSXP) {
    stop("`names` must be a character vector.");
  }

  CharacterVector names(names_);
  if(names.size() != elements.size()) {
    stop("`names` length must match elements length.");
  }

  List prepared(elements.size());
  for(int i = 0; i < elements.size(); ++i) {
    Shield<SEXP> name(Rf_ScalarString(STRING_ELT(names_, i)));
    Shield<SEXP> el(clone_with_attrs(elements[i], name));
    prepared[i] = el;
  }
  return prepared;
}

SEXP add_all_right_cpp(SEXP t, const List& els, const List& monoids) {
  ReprotectSEXP cur(t);
  for(int i = 0; i < els.size(); ++i) {
    cur.set(add_right_cpp(cur.get(), els[i], monoids));
  }
  return cur.get();
}

SEXP add_all_left_cpp(SEXP t, const List& els, const List& monoids) {
  ReprotectSEXP cur(t);
  for(int i = els.size() - 1; i >= 0; --i) {
    cur.set(add_left_cpp(cur.get(), els[i], monoids));
  }
  return cur.get();
}

List measured_nodes_cpp(const List& xs, const List& monoids) {
  const int n = xs.size();
  if(n < 2) {
    stop("measured_nodes_cpp requires at least two elements.");
  }

  List out;
  int i = 0;
  while(i < n) {
    const int rem = n - i;
    if(rem == 2) {
      Shield<SEXP> node(make_node2(xs[i], xs[i + 1], monoids));
      out.push_back(node);
      break;
    }
    if(rem == 3) {
      Shield<SEXP> node(make_node3(xs[i], xs[i + 1], xs[i + 2], monoids));
      out.push_back(node);
      break;
    }
    if(rem == 4) {
      Shield<SEXP> node1(make_node2(xs[i], xs[i + 1], monoids));
      out.push_back(node1);
      Shield<SEXP> node2(make_node2(xs[i + 2], xs[i + 3], monoids));
      out.push_back(node2);
      break;
    }

    Shield<SEXP> node(make_node3(xs[i], xs[i + 1], xs[i + 2], monoids));
    out.push_back(node);
    i += 3;
  }
  return out;
}

SEXP tree_from_sorted_list_cpp(const List& xs, const List& monoids) {
  const int n = xs.size();
  if(n == 0) {
    return make_empty(monoids);
  }
  if(n == 1) {
    return make_single(xs[0], monoids);
  }
  if(n == 2) {
    Shield<SEXP> p(make_digit(List::create(xs[0]), monoids));
    Shield<SEXP> m(make_empty(monoids));
    Shield<SEXP> s(make_digit(List::create(xs[1]), monoids));
    return make_deep(p, m, s, monoids);
  }
  if(n == 3) {
    Shield<SEXP> p(make_digit(List::create(xs[0], xs[1]), monoids));
    Shield<SEXP> m(make_empty(monoids));
    Shield<SEXP> s(make_digit(List::create(xs[2]), monoids));
    return make_deep(p, m, s, monoids);
  }
  if(n == 4) {
    Shield<SEXP> p(make_digit(List::create(xs[0], xs[1]), monoids));
    Shield<SEXP> m(make_empty(monoids));
    Shield<SEXP> s(make_digit(List::create(xs[2], xs[3]), monoids));
    return make_deep(p, m, s, monoids);
  }

  const int prefix_len = (n == 5) ? 1 : 2;
  const int suffix_len = 2;
  const int middle_n = n - prefix_len - suffix_len;
  if(middle_n < 2) {
    stop("Invalid middle segment while building ordered tree.");
  }

  List prefix_children(prefix_len);
  for(int i = 0; i < prefix_len; ++i) {
    prefix_children[i] = xs[i];
  }

  List suffix_children(suffix_len);
  for(int i = 0; i < suffix_len; ++i) {
    suffix_children[i] = xs[n - suffix_len + i];
  }

  List middle_elems(middle_n);
  for(int i = 0; i < middle_n; ++i) {
    middle_elems[i] = xs[prefix_len + i];
  }

  Shield<SEXP> prefix(make_digit(prefix_children, monoids));
  Shield<SEXP> suffix(make_digit(suffix_children, monoids));
  List middle_nodes = measured_nodes_cpp(middle_elems, monoids);
  Shield<SEXP> middle(tree_from_sorted_list_cpp(middle_nodes, monoids));
  return make_deep(prefix, middle, suffix, monoids);
}

SEXP app3_cpp(SEXP xs, const List& ts, SEXP ys, const List& monoids) {
  if(has_class(xs, "Empty")) {
    return add_all_left_cpp(ys, ts, monoids);
  }
  if(has_class(ys, "Empty")) {
    return add_all_right_cpp(xs, ts, monoids);
  }
  if(has_class(xs, "Single")) {
    List sx(xs);
    Shield<SEXP> with_ts(add_all_left_cpp(ys, ts, monoids));
    return add_left_cpp(with_ts, sx[0], monoids);
  }
  if(has_class(ys, "Single")) {
    List sy(ys);
    Shield<SEXP> with_ts(add_all_right_cpp(xs, ts, monoids));
    return add_right_cpp(with_ts, sy[0], monoids);
  }
  if(has_class(xs, "Deep") && has_class(ys, "Deep")) {
    List dx(xs);
    List dy(ys);
    List sfx = dx["suffix"];
    List pry = dy["prefix"];

    List bridge(sfx.size() + ts.size() + pry.size());
    int j = 0;
    for(int i = 0; i < sfx.size(); ++i) bridge[j++] = sfx[i];
    for(int i = 0; i < ts.size(); ++i) bridge[j++] = ts[i];
    for(int i = 0; i < pry.size(); ++i) bridge[j++] = pry[i];

    List nts = measured_nodes_cpp(bridge, monoids);
    Shield<SEXP> m(app3_cpp(dx["middle"], nts, dy["middle"], monoids));
    return make_deep(dx["prefix"], m, dy["suffix"], monoids);
  }

  stop("Unsupported node type in ft_cpp_concat.");
}

SEXP monoid_measure_for_child(SEXP ch, const std::string& monoid_name, const List& monoid_spec) {
  if(is_structural_node_cpp(ch)) {
    List cms = Rf_getAttrib(ch, measures_sym);
    if(!Rf_isNull(cms) && !Rf_isNull(cms[monoid_name])) {
      return cms[monoid_name];
    }
  }

  bool is_min = false;
  if(monoid_name_is_pq_minmax(monoid_name, is_min)) {
    SEXP priority = R_NilValue;
    if(pq_extract_priority_from_entry(ch, priority)) {
      return pq_make_measure(priority);
    }
  }
  if(monoid_name == ".oms_max_key") {
    SEXP key = R_NilValue;
    if(oms_extract_key_from_entry(ch, key)) {
      const ScalarKind kind = scalar_kind_from_value(key);
      if(kind != ScalarKind::UNKNOWN) {
        return oms_make_measure(key, kind);
      }
    }
  }
  if(monoid_name == ".ivx_max_start") {
    SEXP start = R_NilValue;
    if(ivx_extract_start_from_entry(ch, start)) {
      const ScalarKind kind = scalar_kind_from_value(start);
      if(kind != ScalarKind::UNKNOWN) {
        return ivx_make_measure(start, kind);
      }
    }
  }

  Function measure = as<Function>(list_get_named_or_index(monoid_spec, "measure", 2));
  return measure(ch);
}

int size_for_child(SEXP ch, const List& size_monoid) {
  if(is_structural_node_cpp(ch)) {
    List cms = Rf_getAttrib(ch, measures_sym);
    if(!Rf_isNull(cms) && !Rf_isNull(cms[".size"])) {
      return as<int>(cms[".size"]);
    }
  }
  Function measure = as<Function>(size_monoid["measure"]);
  return as<int>(measure(ch));
}

SEXP measure_sequence(const List& xs, const std::string& monoid_name, const List& monoid_spec) {
  Function f = as<Function>(list_get_named_or_index(monoid_spec, "f", 0));
  ReprotectSEXP acc(list_get_named_or_index(monoid_spec, "i", 1));
  for(int i = 0; i < xs.size(); ++i) {
    Shield<SEXP> m(monoid_measure_for_child(xs[i], monoid_name, monoid_spec));
    Shield<SEXP> acc_after(monoid_combine(acc.get(), (SEXP)m, monoid_name, monoid_spec, &f));
    acc.set((SEXP)acc_after);
  }
  return acc.get();
}

bool predicate_true(const Function& predicate, SEXP x) {
  return as<bool>(predicate(x));
}

SEXP node_measure_named(SEXP x, const std::string& monoid_name) {
  List ms = Rf_getAttrib(x, measures_sym);
  if(Rf_isNull(ms) || Rf_isNull(ms[monoid_name])) {
    stop("Missing cached measure on structural node.");
  }
  return ms[monoid_name];
}

List locate_tree_impl_cpp(
  const Function& predicate,
  SEXP i,
  SEXP t,
  const List& monoids,
  const std::string& monoid_name,
  const List& monoid_spec,
  const List& size_monoid,
  int i_size
);

List locate_digit_impl_cpp(
  const Function& predicate,
  SEXP i,
  const List& digit,
  const List& monoids,
  const std::string& monoid_name,
  const List& monoid_spec,
  const List& size_monoid,
  int i_size
) {
  if(digit.size() == 0) {
    stop("locate_digit called with empty digit");
  }

  Function f = as<Function>(list_get_named_or_index(monoid_spec, "f", 0));
  ReprotectSEXP acc(i);
  int size_before = i_size;

  for(int idx = 0; idx < digit.size(); ++idx) {
    SEXP el = digit[idx];
    Shield<SEXP> m_el(monoid_measure_for_child(el, monoid_name, monoid_spec));
    int n_el = size_for_child(el, size_monoid);
    Shield<SEXP> acc_after(monoid_combine(acc.get(), (SEXP)m_el, monoid_name, monoid_spec, &f));

    if(predicate_true(predicate, acc_after)) {
      if(is_structural_node_cpp(el)) {
        return locate_tree_impl_cpp(
          predicate, acc.get(), el, monoids, monoid_name, monoid_spec, size_monoid, size_before
        );
      }

      List right;
      if(idx + 1 < digit.size()) {
        right = List(digit.size() - idx - 1);
        int j = 0;
        for(int k = idx + 1; k < digit.size(); ++k) {
          right[j++] = digit[k];
        }
      } else {
        right = List(0);
      }
      SEXP right_measure = measure_sequence(right, monoid_name, monoid_spec);

      return List::create(
        _["found"] = true,
        _["value"] = el,
        _["left_measure"] = acc.get(),
        _["hit_measure"] = acc_after,
        _["right_measure"] = right_measure,
        _["index"] = size_before + 1
      );
    }

    acc.set(acc_after);
    size_before += n_el;
  }

  return List::create(
    _["found"] = false,
    _["value"] = R_NilValue,
    _["left_measure"] = acc.get(),
    _["hit_measure"] = R_NilValue,
    _["right_measure"] = R_NilValue,
    _["index"] = R_NilValue
  );
}

List locate_tree_impl_cpp(
  const Function& predicate,
  SEXP i,
  SEXP t,
  const List& monoids,
  const std::string& monoid_name,
  const List& monoid_spec,
  const List& size_monoid,
  int i_size
) {
  if(!is_structural_node_cpp(t)) {
    List d = List::create(t);
    return locate_digit_impl_cpp(
      predicate, i, d, monoids, monoid_name, monoid_spec, size_monoid, i_size
    );
  }

  if(has_class(t, "Empty")) {
    return List::create(
      _["found"] = false,
      _["value"] = R_NilValue,
      _["left_measure"] = i,
      _["hit_measure"] = R_NilValue,
      _["right_measure"] = R_NilValue,
      _["index"] = R_NilValue
    );
  }

  if(has_class(t, "Single")) {
    List s(t);
    List d = List::create(s[0]);
    return locate_digit_impl_cpp(
      predicate, i, d, monoids, monoid_name, monoid_spec, size_monoid, i_size
    );
  }

  if(has_class(t, "Deep")) {
    List d(t);
    SEXP prefix = d["prefix"];
    SEXP middle = d["middle"];
    SEXP suffix = d["suffix"];

    List pm = Rf_getAttrib(prefix, measures_sym);
    List mm = Rf_getAttrib(middle, measures_sym);
    List sm = Rf_getAttrib(suffix, measures_sym);

    SEXP mpr = pm[monoid_name];
    SEXP mmid = mm[monoid_name];
    SEXP msf = sm[monoid_name];

    Function f = as<Function>(list_get_named_or_index(monoid_spec, "f", 0));
    Shield<SEXP> vpr(monoid_combine(i, mpr, monoid_name, monoid_spec, &f));
    Shield<SEXP> vm(monoid_combine(vpr, mmid, monoid_name, monoid_spec, &f));

    int npr = as<int>(pm[".size"]);
    int nm = as<int>(mm[".size"]);

    if(predicate_true(predicate, vpr)) {
      List res = locate_tree_impl_cpp(
        predicate, i, prefix, monoids, monoid_name, monoid_spec, size_monoid, i_size
      );
      if(as<bool>(res["found"])) {
        Shield<SEXP> r(static_cast<SEXP>(res["right_measure"]));
        Shield<SEXP> rr(monoid_combine(r, mmid, monoid_name, monoid_spec, &f));
        Shield<SEXP> new_right(monoid_combine(rr, msf, monoid_name, monoid_spec, &f));
        res["right_measure"] = static_cast<SEXP>(new_right);
      }
      return res;
    }

    if(predicate_true(predicate, vm)) {
      List res = locate_tree_impl_cpp(
        predicate, vpr, middle, monoids, monoid_name, monoid_spec, size_monoid, i_size + npr
      );
      if(as<bool>(res["found"])) {
        Shield<SEXP> r(static_cast<SEXP>(res["right_measure"]));
        Shield<SEXP> new_right(monoid_combine(r, msf, monoid_name, monoid_spec, &f));
        res["right_measure"] = static_cast<SEXP>(new_right);
      }
      return res;
    }

    return locate_tree_impl_cpp(
      predicate, vm, suffix, monoids, monoid_name, monoid_spec, size_monoid, i_size + npr + nm
    );
  }

  List as_list(t);
  return locate_digit_impl_cpp(
    predicate, i, as_list, monoids, monoid_name, monoid_spec, size_monoid, i_size
  );
}

SEXP build_digit_cpp(const List& xs, const List& monoids) {
  if(xs.size() == 0) {
    return List(0);
  }
  return make_digit(xs, monoids);
}

SEXP digit_to_tree_cpp(const List& d, const List& monoids) {
  const int n = d.size();
  if(n == 0) {
    return make_empty(monoids);
  }
  if(n == 1) {
    return make_single(d[0], monoids);
  }
  if(n == 2) {
    Shield<SEXP> p(make_digit(List::create(d[0]), monoids));
    Shield<SEXP> m(make_empty(monoids));
    Shield<SEXP> s(make_digit(List::create(d[1]), monoids));
    return make_deep(p, m, s, monoids);
  }
  if(n == 3) {
    Shield<SEXP> p(make_digit(List::create(d[0], d[1]), monoids));
    Shield<SEXP> m(make_empty(monoids));
    Shield<SEXP> s(make_digit(List::create(d[2]), monoids));
    return make_deep(p, m, s, monoids);
  }
  if(n == 4) {
    Shield<SEXP> p(make_digit(List::create(d[0], d[1]), monoids));
    Shield<SEXP> m(make_empty(monoids));
    Shield<SEXP> s(make_digit(List::create(d[2], d[3]), monoids));
    return make_deep(p, m, s, monoids);
  }
  stop("digit_to_tree expects a digit of size 0..4");
}

SEXP node_to_digit_cpp(SEXP node, const List& monoids) {
  List xs(node);
  return make_digit(xs, monoids);
}

List viewL_cpp(SEXP t, const List& monoids);
List viewR_cpp(SEXP t, const List& monoids);

SEXP deepL_cpp(SEXP pr, SEXP m, SEXP sf, const List& monoids) {
  if(Rf_xlength(pr) > 0) {
    return make_deep(pr, m, sf, monoids);
  }
  if(has_class(m, "Empty")) {
    return digit_to_tree_cpp(List(sf), monoids);
  }
  List res = viewL_cpp(m, monoids);
  Shield<SEXP> node(static_cast<SEXP>(res["value"]));
  Shield<SEXP> m_rest(static_cast<SEXP>(res["rest"]));
  Shield<SEXP> new_pr(node_to_digit_cpp(node, monoids));
  return make_deep(new_pr, m_rest, sf, monoids);
}

SEXP deepR_cpp(SEXP pr, SEXP m, SEXP sf, const List& monoids) {
  if(Rf_xlength(sf) > 0) {
    return make_deep(pr, m, sf, monoids);
  }
  if(has_class(m, "Empty")) {
    return digit_to_tree_cpp(List(pr), monoids);
  }
  List res = viewR_cpp(m, monoids);
  Shield<SEXP> node(static_cast<SEXP>(res["value"]));
  Shield<SEXP> m_rest(static_cast<SEXP>(res["rest"]));
  Shield<SEXP> new_sf(node_to_digit_cpp(node, monoids));
  return make_deep(pr, m_rest, new_sf, monoids);
}

List viewL_cpp(SEXP t, const List& monoids) {
  if(has_class(t, "Empty")) {
    stop("viewL on Empty");
  }
  if(has_class(t, "Single")) {
    List s(t);
    return List::create(_["value"] = s[0], _["rest"] = make_empty(monoids));
  }

  List d(t);
  List pr = d["prefix"];
  if(pr.size() > 1) {
    Shield<SEXP> head(static_cast<SEXP>(pr[0]));
    List tail(pr.size() - 1);
    for(int i = 1; i < pr.size(); ++i) tail[i - 1] = pr[i];
    Shield<SEXP> new_pr(build_digit_cpp(tail, monoids));
    return List::create(
      _["value"] = head,
      _["rest"] = make_deep(new_pr, d["middle"], d["suffix"], monoids)
    );
  }

  Shield<SEXP> head(static_cast<SEXP>(pr[0]));
  Shield<SEXP> m(static_cast<SEXP>(d["middle"]));
  if(has_class(m, "Empty")) {
    return List::create(_["value"] = head, _["rest"] = digit_to_tree_cpp(List(d["suffix"]), monoids));
  }
  List res = viewL_cpp(m, monoids);
  Shield<SEXP> node(static_cast<SEXP>(res["value"]));
  Shield<SEXP> m_rest(static_cast<SEXP>(res["rest"]));
  Shield<SEXP> new_pr(node_to_digit_cpp(node, monoids));
  return List::create(_["value"] = head, _["rest"] = make_deep(new_pr, m_rest, d["suffix"], monoids));
}

List viewR_cpp(SEXP t, const List& monoids) {
  if(has_class(t, "Empty")) {
    stop("viewR on Empty");
  }
  if(has_class(t, "Single")) {
    List s(t);
    return List::create(_["value"] = s[0], _["rest"] = make_empty(monoids));
  }

  List d(t);
  List sf = d["suffix"];
  if(sf.size() > 1) {
    Shield<SEXP> head(static_cast<SEXP>(sf[sf.size() - 1]));
    List tail(sf.size() - 1);
    for(int i = 0; i < sf.size() - 1; ++i) tail[i] = sf[i];
    Shield<SEXP> new_sf(build_digit_cpp(tail, monoids));
    return List::create(
      _["value"] = head,
      _["rest"] = make_deep(d["prefix"], d["middle"], new_sf, monoids)
    );
  }

  Shield<SEXP> head(static_cast<SEXP>(sf[0]));
  Shield<SEXP> m(static_cast<SEXP>(d["middle"]));
  if(has_class(m, "Empty")) {
    return List::create(_["value"] = head, _["rest"] = digit_to_tree_cpp(List(d["prefix"]), monoids));
  }
  List res = viewR_cpp(m, monoids);
  Shield<SEXP> node(static_cast<SEXP>(res["value"]));
  Shield<SEXP> m_rest(static_cast<SEXP>(res["rest"]));
  Shield<SEXP> new_sf(node_to_digit_cpp(node, monoids));
  return List::create(_["value"] = head, _["rest"] = make_deep(d["prefix"], m_rest, new_sf, monoids));
}

List split_digit_cpp(
  const Function& predicate,
  SEXP i,
  const List& digit,
  const std::string& monoid_name,
  const List& monoid_spec
) {
  if(digit.size() == 0) {
    stop("split_digit called with empty digit");
  }

  Function f = as<Function>(list_get_named_or_index(monoid_spec, "f", 0));
  ReprotectSEXP acc(i);
  for(int idx = 0; idx < digit.size(); ++idx) {
    SEXP el = digit[idx];
    Shield<SEXP> m_el(monoid_measure_for_child(el, monoid_name, monoid_spec));
    Shield<SEXP> acc_after(monoid_combine(acc.get(), (SEXP)m_el, monoid_name, monoid_spec, &f));
    if(predicate_true(predicate, acc_after)) {
      List left(idx);
      for(int j = 0; j < idx; ++j) left[j] = digit[j];
      List right(digit.size() - idx - 1);
      for(int j = idx + 1; j < digit.size(); ++j) right[j - idx - 1] = digit[j];
      return List::create(_["left"] = left, _["value"] = el, _["right"] = right);
    }
    acc.set(acc_after);
  }
  stop("split_digit: predicate never became true; precondition violated");
}

List split_tree_impl_cpp(
  const Function& predicate,
  SEXP i,
  SEXP t,
  const List& monoids,
  const std::string& monoid_name,
  const List& monoid_spec
) {
  if(has_class(t, "Empty")) {
    stop("split_tree_impl requires a non-empty tree");
  }

  Function f = as<Function>(list_get_named_or_index(monoid_spec, "f", 0));
  if(has_class(t, "Single")) {
    List s(t);
    return List::create(
      _["left"] = make_empty(monoids),
      _["value"] = s[0],
      _["right"] = make_empty(monoids)
    );
  }

  List d(t);
  SEXP prefix = d["prefix"];
  SEXP middle = d["middle"];
  SEXP suffix = d["suffix"];

  Shield<SEXP> vpr(monoid_combine(i, node_measure_named(prefix, monoid_name), monoid_name, monoid_spec, &f));
  Shield<SEXP> vm(monoid_combine(vpr, node_measure_named(middle, monoid_name), monoid_name, monoid_spec, &f));

  if(predicate_true(predicate, vpr)) {
    List s = split_digit_cpp(predicate, i, List(prefix), monoid_name, monoid_spec);
    Shield<SEXP> left_tree(digit_to_tree_cpp(as<List>(s["left"]), monoids));
    Shield<SEXP> right_digit(build_digit_cpp(as<List>(s["right"]), monoids));
    Shield<SEXP> right_tree(deepL_cpp(right_digit, middle, suffix, monoids));
    return List::create(_["left"] = left_tree, _["value"] = s["value"], _["right"] = right_tree);
  }

  if(predicate_true(predicate, vm)) {
    List sm = split_tree_impl_cpp(predicate, vpr, middle, monoids, monoid_name, monoid_spec);
    Shield<SEXP> inode(monoid_combine(vpr, node_measure_named(sm["left"], monoid_name), monoid_name, monoid_spec, &f));
    List sx = split_digit_cpp(predicate, inode, List(sm["value"]), monoid_name, monoid_spec);
    Shield<SEXP> left_digit(build_digit_cpp(as<List>(sx["left"]), monoids));
    Shield<SEXP> right_digit(build_digit_cpp(as<List>(sx["right"]), monoids));
    Shield<SEXP> left_tree(deepR_cpp(prefix, sm["left"], left_digit, monoids));
    Shield<SEXP> right_tree(deepL_cpp(right_digit, sm["right"], suffix, monoids));
    return List::create(_["left"] = left_tree, _["value"] = sx["value"], _["right"] = right_tree);
  }

  List s = split_digit_cpp(predicate, vm, List(suffix), monoid_name, monoid_spec);
  Shield<SEXP> left_digit(build_digit_cpp(as<List>(s["left"]), monoids));
  Shield<SEXP> left_tree(deepR_cpp(prefix, middle, left_digit, monoids));
  Shield<SEXP> right_tree(digit_to_tree_cpp(as<List>(s["right"]), monoids));
  return List::create(_["left"] = left_tree, _["value"] = s["value"], _["right"] = right_tree);
}

// Callback-free index-based split. Avoids all R<->C++ predicate callbacks.
// Returns {left: tree, value: single_element, right: tree}.
// i = accumulated element count before this subtree (0 for root call).
// target_idx = 1-based index of the element to extract.

List split_tree_at_index_cpp(int i, int target_idx, SEXP t, const List& monoids);

List split_digit_at_index_cpp(int i, int target_idx, const List& digit, const List& monoids) {
  for(int idx = 0; idx < digit.size(); ++idx) {
    SEXP el = digit[idx];
    int n_el = (int)child_size(el);
    int acc_after = i + n_el;
    if(acc_after >= target_idx) {
      List left(idx);
      for(int j = 0; j < idx; ++j) left[j] = digit[j];
      List right(digit.size() - idx - 1);
      for(int j = idx + 1; j < digit.size(); ++j) right[j - idx - 1] = digit[j];
      return List::create(_["left"] = left, _["value"] = el, _["right"] = right);
    }
    i = acc_after;
  }
  stop("split_digit_at_index: precondition violated");
}

List split_tree_at_index_cpp(int i, int target_idx, SEXP t, const List& monoids) {
  if(has_class(t, "Empty")) {
    stop("split_tree_at_index requires a non-empty tree");
  }

  if(has_class(t, "Single")) {
    List s(t);
    return List::create(
      _["left"] = make_empty(monoids),
      _["value"] = s[0],
      _["right"] = make_empty(monoids)
    );
  }

  List d(t);
  SEXP prefix = d["prefix"];
  SEXP middle = d["middle"];
  SEXP suffix = d["suffix"];

  int vpr = i + (int)child_size(prefix);
  int vm  = vpr + (int)child_size(middle);

  if(vpr >= target_idx) {
    List s = split_digit_at_index_cpp(i, target_idx, List(prefix), monoids);
    Shield<SEXP> left_tree(digit_to_tree_cpp(as<List>(s["left"]), monoids));
    Shield<SEXP> right_digit(build_digit_cpp(as<List>(s["right"]), monoids));
    Shield<SEXP> right_tree(deepL_cpp(right_digit, middle, suffix, monoids));
    return List::create(_["left"] = left_tree, _["value"] = s["value"], _["right"] = right_tree);
  }

  if(vm >= target_idx) {
    List sm = split_tree_at_index_cpp(vpr, target_idx, middle, monoids);
    SEXP sm_left = sm["left"];
    int sm_left_size = (int)child_size(sm_left);
    List sx = split_digit_at_index_cpp(vpr + sm_left_size, target_idx, List(static_cast<SEXP>(sm["value"])), monoids);
    Shield<SEXP> left_digit(build_digit_cpp(as<List>(sx["left"]), monoids));
    Shield<SEXP> right_digit(build_digit_cpp(as<List>(sx["right"]), monoids));
    Shield<SEXP> left_tree(deepR_cpp(prefix, sm_left, left_digit, monoids));
    Shield<SEXP> right_tree(deepL_cpp(right_digit, sm["right"], suffix, monoids));
    return List::create(_["left"] = left_tree, _["value"] = sx["value"], _["right"] = right_tree);
  }

  List s = split_digit_at_index_cpp(vm, target_idx, List(suffix), monoids);
  Shield<SEXP> left_digit(build_digit_cpp(as<List>(s["left"]), monoids));
  Shield<SEXP> left_tree(deepR_cpp(prefix, middle, left_digit, monoids));
  Shield<SEXP> right_tree(digit_to_tree_cpp(as<List>(s["right"]), monoids));
  return List::create(_["left"] = left_tree, _["value"] = s["value"], _["right"] = right_tree);
}

bool oms_measure_has_gt_key(SEXP measure, SEXP key, const std::string& key_type) {
  if(TYPEOF(measure) != VECSXP || XLENGTH(measure) < 2) {
    stop("Invalid .oms_max_key measure payload.");
  }
  List m(measure);
  SEXP has = m[0];
  if(TYPEOF(has) != LGLSXP || XLENGTH(has) != 1 || LOGICAL(has)[0] == NA_LOGICAL) {
    stop("Invalid .oms_max_key `has` flag.");
  }
  if(LOGICAL(has)[0] == FALSE) {
    return false;
  }
  SEXP max_key = m[1];
  if(Rf_isNull(max_key)) {
    stop("Invalid .oms_max_key payload: missing key.");
  }
  return oms_compare_keys(max_key, key, key_type) > 0;
}

bool oms_child_has_gt_key(SEXP child, SEXP key, const std::string& key_type) {
  if(is_structural_node_cpp(child)) {
    List measures = Rf_getAttrib(child, measures_sym);
    if(Rf_isNull(measures)) {
      stop("Missing cached measures on structural node.");
    }
    SEXP mk = measures[".oms_max_key"];
    if(Rf_isNull(mk)) {
      stop("Missing .oms_max_key measure on ordered_multiset tree.");
    }
    return oms_measure_has_gt_key(mk, key, key_type);
  }
  return oms_compare_keys(oms_entry_key(child), key, key_type) > 0;
}

bool oms_tree_has_gt_key(SEXP t, SEXP key, const std::string& key_type) {
  if(has_class(t, "Empty")) {
    return false;
  }
  return oms_child_has_gt_key(t, key, key_type);
}

List oms_split_digit_gt_key(const List& digit, SEXP key, const std::string& key_type) {
  if(digit.size() == 0) {
    stop("oms_split_digit_gt_key called with empty digit");
  }

  for(int idx = 0; idx < digit.size(); ++idx) {
    SEXP el = digit[idx];
    if(oms_child_has_gt_key(el, key, key_type)) {
      List left(idx);
      for(int j = 0; j < idx; ++j) {
        left[j] = digit[j];
      }
      List right(digit.size() - idx - 1);
      for(int j = idx + 1; j < digit.size(); ++j) {
        right[j - idx - 1] = digit[j];
      }
      return List::create(_["left"] = left, _["value"] = el, _["right"] = right);
    }
  }

  stop("oms_split_digit_gt_key precondition violated: no element with key > target.");
}

List oms_split_tree_gt_key(
  SEXP t,
  SEXP key,
  const std::string& key_type,
  const List& monoids
) {
  if(has_class(t, "Empty")) {
    stop("oms_split_tree_gt_key requires a non-empty tree");
  }

  if(has_class(t, "Single")) {
    List s(t);
    return List::create(
      _["left"] = make_empty(monoids),
      _["value"] = s[0],
      _["right"] = make_empty(monoids)
    );
  }

  List d(t);
  SEXP prefix = d["prefix"];
  SEXP middle = d["middle"];
  SEXP suffix = d["suffix"];

  if(oms_tree_has_gt_key(prefix, key, key_type)) {
    List s = oms_split_digit_gt_key(List(prefix), key, key_type);
    Shield<SEXP> left_tree(digit_to_tree_cpp(as<List>(s["left"]), monoids));
    Shield<SEXP> right_digit(build_digit_cpp(as<List>(s["right"]), monoids));
    Shield<SEXP> right_tree(deepL_cpp(right_digit, middle, suffix, monoids));
    return List::create(_["left"] = left_tree, _["value"] = s["value"], _["right"] = right_tree);
  }

  if(oms_tree_has_gt_key(middle, key, key_type)) {
    List sm = oms_split_tree_gt_key(middle, key, key_type, monoids);
    List sx = oms_split_digit_gt_key(List(sm["value"]), key, key_type);
    Shield<SEXP> left_digit(build_digit_cpp(as<List>(sx["left"]), monoids));
    Shield<SEXP> right_digit(build_digit_cpp(as<List>(sx["right"]), monoids));
    Shield<SEXP> left_tree(deepR_cpp(prefix, sm["left"], left_digit, monoids));
    Shield<SEXP> right_tree(deepL_cpp(right_digit, sm["right"], suffix, monoids));
    return List::create(_["left"] = left_tree, _["value"] = sx["value"], _["right"] = right_tree);
  }

  if(oms_tree_has_gt_key(suffix, key, key_type)) {
    List s = oms_split_digit_gt_key(List(suffix), key, key_type);
    Shield<SEXP> left_digit(build_digit_cpp(as<List>(s["left"]), monoids));
    Shield<SEXP> left_tree(deepR_cpp(prefix, middle, left_digit, monoids));
    Shield<SEXP> right_tree(digit_to_tree_cpp(as<List>(s["right"]), monoids));
    return List::create(_["left"] = left_tree, _["value"] = s["value"], _["right"] = right_tree);
  }

  stop("oms_split_tree_gt_key precondition violated: no element with key > target.");
}

SEXP oms_insert_cpp_impl(SEXP x, SEXP entry, const List& monoids, const std::string& key_type) {
  SEXP key = oms_entry_key(entry);
  if(!oms_tree_has_gt_key(x, key, key_type)) {
    return add_right_cpp(x, entry, monoids);
  }

  List s = oms_split_tree_gt_key(x, key, key_type, monoids);
  Shield<SEXP> right_with_hit(add_left_cpp(s["right"], s["value"], monoids));
  Shield<SEXP> left_plus_entry(add_right_cpp(s["left"], entry, monoids));
  List ts(0);
  return app3_cpp(left_plus_entry, ts, right_with_hit, monoids);
}

} // namespace

extern "C" SEXP ft_cpp_append_right(SEXP t, SEXP el, SEXP monoids_) {
  BEGIN_RCPP
  List monoids(monoids_);
  return add_right_cpp(t, el, monoids);
  END_RCPP
}

extern "C" SEXP ft_cpp_prepend_left(SEXP t, SEXP el, SEXP monoids_) {
  BEGIN_RCPP
  List monoids(monoids_);
  return add_left_cpp(t, el, monoids);
  END_RCPP
}

extern "C" SEXP ft_cpp_append_right_named(SEXP t, SEXP el, SEXP name_, SEXP monoids_) {
  BEGIN_RCPP
  List monoids(monoids_);
  Shield<SEXP> named_el(clone_with_name(el, name_));
  return add_right_cpp(t, named_el, monoids);
  END_RCPP
}

extern "C" SEXP ft_cpp_prepend_left_named(SEXP t, SEXP el, SEXP name_, SEXP monoids_) {
  BEGIN_RCPP
  List monoids(monoids_);
  Shield<SEXP> named_el(clone_with_name(el, name_));
  return add_left_cpp(t, named_el, monoids);
  END_RCPP
}

extern "C" SEXP ft_cpp_tree_from(SEXP elements_, SEXP monoids_) {
  BEGIN_RCPP
  List elements(elements_);
  List monoids(monoids_);
  return tree_from_sorted_list_cpp(elements, monoids);
  END_RCPP
}

extern "C" SEXP ft_cpp_tree_from_prepared(SEXP elements_, SEXP names_, SEXP monoids_) {
  BEGIN_RCPP
  List elements(elements_);
  List monoids(monoids_);
  List prepared = prepare_elements_with_names_cpp(elements, names_);
  return tree_from_sorted_list_cpp(prepared, monoids);
  END_RCPP
}

extern "C" SEXP ft_cpp_tree_from_sorted(SEXP elements_, SEXP monoids_) {
  BEGIN_RCPP
  List elements(elements_);
  List monoids(monoids_);
  return tree_from_sorted_list_cpp(elements, monoids);
  END_RCPP
}

extern "C" SEXP ft_cpp_concat(SEXP x, SEXP y, SEXP monoids_) {
  BEGIN_RCPP
  List monoids(monoids_);
  List ts(0);
  return app3_cpp(x, ts, y, monoids);
  END_RCPP
}

extern "C" SEXP ft_cpp_oms_insert(SEXP x, SEXP entry, SEXP monoids_, SEXP key_type_) {
  BEGIN_RCPP
  std::string key_type = as<std::string>(key_type_);
  if(key_type != "numeric" && key_type != "character" && key_type != "logical") {
    stop("Unsupported ordered_multiset key type.");
  }
  List monoids(monoids_);
  return oms_insert_cpp_impl(x, entry, monoids, key_type);
  END_RCPP
}

extern "C" SEXP ft_cpp_locate(SEXP t, SEXP predicate_, SEXP monoids_, SEXP monoid_name_, SEXP i_) {
  BEGIN_RCPP
  Function predicate(predicate_);
  List monoids(monoids_);
  std::string monoid_name = as<std::string>(monoid_name_);
  SEXP monoid_spec_sexp = monoids[monoid_name];
  if(Rf_isNull(monoid_spec_sexp)) {
    stop("Unknown monoid name.");
  }
  List monoid_spec(monoid_spec_sexp);
  List size_monoid = as<List>(monoids[".size"]);
  return locate_tree_impl_cpp(predicate, i_, t, monoids, monoid_name, monoid_spec, size_monoid, 0);
  END_RCPP
}

extern "C" SEXP ft_cpp_split_tree(SEXP t, SEXP predicate_, SEXP monoids_, SEXP monoid_name_, SEXP i_) {
  BEGIN_RCPP
  Function predicate(predicate_);
  List monoids(monoids_);
  std::string monoid_name = as<std::string>(monoid_name_);
  SEXP monoid_spec_sexp = monoids[monoid_name];
  if(Rf_isNull(monoid_spec_sexp)) {
    stop("Unknown monoid name.");
  }
  List monoid_spec(monoid_spec_sexp);
  return split_tree_impl_cpp(predicate, i_, t, monoids, monoid_name, monoid_spec);
  END_RCPP
}

// Callback-free index-based split: no R<->C++ predicate callbacks.
// idx is a 1-based integer position.
extern "C" SEXP ft_cpp_split_at_index(SEXP t, SEXP idx_, SEXP monoids_) {
  BEGIN_RCPP
  IntegerVector idx(idx_);
  if(idx.size() != 1 || IntegerVector::is_na(idx[0])) {
    stop("`idx` must be a single non-missing integer.");
  }
  int target = idx[0];
  if(target <= 0) {
    stop("`idx` must be a positive integer.");
  }
  List monoids(monoids_);
  return split_tree_at_index_cpp(0, target, t, monoids);
  END_RCPP
}

extern "C" SEXP ft_cpp_find_name_position(SEXP t, SEXP name_) {
  BEGIN_RCPP
  CharacterVector nm(name_);
  if(nm.size() != 1 || CharacterVector::is_na(nm[0])) {
    stop("`name` must be a single non-missing string.");
  }
  std::string target = as<std::string>(nm[0]);
  if(target.empty()) {
    stop("`name` must be a single non-empty string.");
  }
  int p = find_name_position_impl(t, target, 0);
  if(p < 0) {
    return IntegerVector::create(NA_INTEGER);
  }
  return IntegerVector::create(p);
  END_RCPP
}

extern "C" SEXP ft_cpp_get_by_index(SEXP t, SEXP idx_) {
  BEGIN_RCPP
  IntegerVector idx(idx_);
  if(idx.size() != 1 || IntegerVector::is_na(idx[0])) {
    stop("`idx` must be a single non-missing integer index.");
  }
  return get_by_index_impl(t, idx[0]);
  END_RCPP
}

extern "C" SEXP ft_cpp_get_many_by_index(SEXP t, SEXP idx_) {
  BEGIN_RCPP
  IntegerVector idx(idx_);
  List out(idx.size());
  for(int i = 0; i < idx.size(); ++i) {
    if(IntegerVector::is_na(idx[i])) {
      stop("Only non-missing integer indices are supported.");
    }
    out[i] = get_by_index_impl(t, idx[i]);
  }
  return out;
  END_RCPP
}

extern "C" SEXP ft_cpp_name_positions(SEXP t) {
  BEGIN_RCPP
  SEXP m = Rf_getAttrib(t, measures_sym);
  if(Rf_isNull(m)) {
    stop("Tree has no measures attribute.");
  }
  List ms(m);
  const int n = as<int>(ms[".size"]);
  const int nn = as<int>(ms[".named_count"]);
  if(n == 0 || nn == 0) {
    stop("Tree has no element names.");
  }
  if(nn != n) {
    stop("Invalid name state: mixed named and unnamed elements are not allowed.");
  }

  CharacterVector nms(n);
  int pos = 0;
  collect_names_impl(t, nms, pos);
  if(pos != n) {
    stop("Name collection mismatch with .size measure.");
  }

  IntegerVector out(n);
  for(int i = 0; i < n; ++i) {
    out[i] = i + 1;
  }
  out.attr("names") = nms;
  return out;
  END_RCPP
}

extern "C" SEXP ft_cpp_ivx_native_query(
    SEXP candidate_tree,
    SEXP relation_kind_,
    SEXP qlo,
    SEXP qhi,
    SEXP bounds_flags_,
    SEXP endpoint_kind_,
    SEXP which_,
    SEXP with_unmatched_,
    SEXP monoids_,
    SEXP as_list_
) {
  BEGIN_RCPP
  std::string relation_kind = as<std::string>(relation_kind_);
  List bounds_flags(bounds_flags_);
  int endpoint_kind = as<int>(endpoint_kind_);
  std::string which = as<std::string>(which_);
  bool with_unmatched = as<bool>(with_unmatched_);
  bool as_list = as<bool>(as_list_);
  return ivx_native_query_impl(
    candidate_tree, relation_kind, qlo, qhi,
    bounds_flags, endpoint_kind, which, with_unmatched, monoids_, as_list
  );
  END_RCPP
}
