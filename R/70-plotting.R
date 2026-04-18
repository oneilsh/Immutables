
#' Build graph data frames for a finger tree
#'
#' @param t FingerTree.
#' @return A list with three elements: `edge_df` (parent/child/label),
#'   `node_df` (node/type/label), and `node_data` — a named list keyed by node
#'   id whose values are lists with fields `type`, `label`, `measures` (cached
#'   monoid values for structural nodes; `NULL` for element leaves), and
#'   `element` (the raw leaf entry for element nodes; `NULL` for structural
#'   nodes).
#' @examples
#' \dontrun{
#' t <- as_flexseq(letters[1:4])
#' gdf <- get_graph_df(t)
#' names(gdf)
#' }
#' @keywords internal
# Runtime: O(n) over tree nodes/elements.
get_graph_df <- function(t) {
  edge_rows <- list()
  node_rows <- list()
  node_data <- list()

  # Monoids are attached at the tree root; use them to compute the per-leaf
  # measure value exposed on element-node `$measures` so plot/label code can
  # access measures uniformly on structural and leaf nodes.
  root_monoids <- if(is_structural_node(t)) attr(t, "monoids", exact = TRUE) else NULL

  leaf_measures <- function(entry) {
    if(is.null(root_monoids)) {
      return(NULL)
    }
    out <- lapply(root_monoids, function(mo) mo$measure(entry))
    names(out) <- names(root_monoids)
    out
  }

  # The root of a flexseq/subclass carries the outer S3 class first
  # (e.g. c("flexseq", "Deep", ...)); pick the finger-tree structural class
  # for coloring, falling back to class(t)[1] for anything unexpected.
  structural_class <- function(t) {
    hits <- intersect(class(t),
                      c("Deep", "Single", "Empty", "Digit", "Node2", "Node3"))
    if(length(hits) > 0L) hits[[1L]] else class(t)[[1L]]
  }

  add_edge_row <- function(parent, child, label) {
    edge_rows[[length(edge_rows) + 1L]] <<- list(
      parent = as.character(parent),
      child = as.character(child),
      label = as.character(label)
    )
  }

  add_node_row <- function(node, type, label, measures = NULL, element = NULL) {
    key <- as.character(node)
    if(!is.null(node_data[[key]])) {
      return(invisible())
    }
    node_rows[[length(node_rows) + 1L]] <<- list(
      node = key,
      type = as.character(type),
      label = as.character(label)
    )
    node_data[[key]] <<- list(
      id = key,
      type = as.character(type),
      label = as.character(label),
      measures = measures,
      element = element
    )
  }

# Runtime: O(n) worst-case in relevant input/subtree size.
  add_edges <- function(t, path) {

    if(is_structural_node(t) && t %isa% Empty) {
      add_node_row(path, structural_class(t), "",
                   measures = attr(t, "measures", exact = TRUE))
    }
    else if(!is_structural_node(t)) {
      add_node_row(path, "Element",
                   paste0(as.character(unlist(t)), collapse = ", "),
                   element = t,
                   measures = leaf_measures(t))
    } else {
      add_node_row(path, structural_class(t), "",
                   measures = attr(t, "measures", exact = TRUE))

      if(!is.null(names(t))) {
        for(subthing_name in names(t)) {
          subthing <- .subset2(t, subthing_name)
          childid <- paste(path, subthing_name, sep = ":")
          add_edge_row(path, childid, subthing_name)
          add_edges(subthing, childid)
        }
      } else {
        index <- 1
        for(subthing in t) {
          childid <- paste(path, index, sep = ":")
          add_edge_row(path, childid, index)
          add_edges(subthing, childid)
          index <- index + 1
        }
      }
    }
    return(invisible())
  }

  add_edges(t, "root")

  edge_df <- if(length(edge_rows) == 0L) {
    data.frame(parent = character(0), child = character(0), label = character(0), stringsAsFactors = FALSE)
  } else {
    do.call(rbind.data.frame, c(lapply(edge_rows, as.data.frame, stringsAsFactors = FALSE), list(stringsAsFactors = FALSE)))
  }
  node_df <- if(length(node_rows) == 0L) {
    data.frame(node = character(0), type = character(0), label = character(0), stringsAsFactors = FALSE)
  } else {
    do.call(rbind.data.frame, c(lapply(node_rows, as.data.frame, stringsAsFactors = FALSE), list(stringsAsFactors = FALSE)))
  }

  return(list(edge_df, node_df, node_data))
}



#' @importFrom graphics par plot.new polygon strheight strwidth
#' @keywords internal
NULL

# Build a closed polygon path for a rounded rectangle centered at (cx, cy)
# with width w, height h, and corner radius r (clamped to min(w, h) / 2).
# Returns list(x, y) suitable for graphics::polygon().
# Runtime: O(1) in polygon samples; arc sampled at 10 points per corner.
.roundrect_path <- function(cx, cy, w, h, r) {
  r <- min(r, w / 2, h / 2)
  n_arc <- 10L
  ang <- seq(0, pi / 2, length.out = n_arc)

  rx <- cx + w / 2 - r
  lx <- cx - w / 2 + r
  ty <- cy + h / 2 - r
  by <- cy - h / 2 + r

  list(
    x = c(rx + r * cos(ang),           # top-right corner
          lx + r * cos(pi / 2 + ang),  # top-left corner
          lx + r * cos(pi + ang),      # bottom-left corner
          rx + r * cos(3 * pi / 2 + ang)),   # bottom-right corner
    y = c(ty + r * sin(ang),
          ty + r * sin(pi / 2 + ang),
          by + r * sin(pi + ang),
          by + r * sin(3 * pi / 2 + ang))
  )
}

# Register the custom "rounded_rect" igraph vertex shape if not already present.
# The shape sizes each vertex to fit its own label text (so varying-length
# labels all get appropriately sized boxes), and uses `shape_noclip` as the
# clip function — safe here because edges have no arrowheads and the filled
# rectangle is drawn over the edge endpoints.
# Runtime: O(1) per registration; the plot function is O(n) per plot call.
.register_rounded_rect_shape <- function() {
  if("rounded_rect" %in% igraph::shapes()) {
    return(invisible())
  }

  plot_fn <- function(coords, v = NULL, params) {
    vcolor <- params("vertex", "color")
    if(length(vcolor) != 1L && !is.null(v)) vcolor <- vcolor[v]
    fcolor <- params("vertex", "frame.color")
    if(length(fcolor) != 1L && !is.null(v)) fcolor <- fcolor[v]
    vlabel <- params("vertex", "label")
    if(!is.null(v)) vlabel <- vlabel[v]
    lcex <- params("vertex", "label.cex")
    if(length(lcex) != 1L && !is.null(v)) lcex <- lcex[v]

    n <- nrow(coords)
    vcolor <- rep(vcolor, length.out = n)
    fcolor <- rep(fcolor, length.out = n)
    vlabel <- rep(as.character(vlabel), length.out = n)
    lcex <- rep(lcex, length.out = n)

    for(i in seq_len(n)) {
      lbl <- vlabel[i]
      if(is.na(lbl) || nchar(lbl) == 0L) {
        w <- strwidth("oo", cex = lcex[i])
        h <- strheight("M", cex = lcex[i]) * 1.5
      } else {
        lines <- strsplit(lbl, "\n", fixed = TRUE)[[1L]]
        w <- max(strwidth(lines, cex = lcex[i])) + strwidth("oo", cex = lcex[i])
        h <- strheight("Mg", cex = lcex[i]) * length(lines) * 1.35 +
             strheight("o", cex = lcex[i]) * 0.6
      }
      r <- min(w, h) * 0.25
      path <- .roundrect_path(coords[i, 1L], coords[i, 2L], w, h, r)
      polygon(path$x, path$y, col = vcolor[i], border = fcolor[i])
    }
  }

  igraph::add_shape("rounded_rect",
                    clip = igraph::shape_noclip,
                    plot = plot_fn)
  invisible()
}


#' Plot the Internal Finger-Tree Structure
#'
#' Developer-facing visualizer for the finger-tree backing any immutables
#' structure (`flexseq`, `ordered_sequence`, `priority_queue`,
#' `interval_index`). The S3 `plot()` methods on those classes forward to
#' this function, but `plot_structure()` is also callable directly and gives
#' access to the full `node_label` API for custom label formatting. Requires
#' the `igraph` package (listed in `Suggests`).
#'
#' @param t1 A finger-tree-backed immutables structure.
#' @param vertex.size Passed to `igraph::plot.igraph`. Ignored by the default
#'   `"rounded_rect"` shape, which sizes each box to its own label text.
#' @param vertex.shape Vertex shape. Defaults to `"rounded_rect"`, a custom
#'   shape registered on first call that auto-sizes every box to fit its
#'   label (so multi-line labels render cleanly without tuning
#'   `vertex.size`). Any built-in igraph shape (`"circle"`, `"rectangle"`,
#'   `"none"`, ...) also works and is passed through unchanged.
#' @param edge.width Edge width passed to `igraph::plot.igraph`.
#' @param label_edges If `TRUE`, draw the child slot name on each edge
#'   (`"prefix"`/`"middle"`/`"suffix"` for `Deep` nodes, or the numeric
#'   position for `Digit`/`Node2`/`Node3`).
#' @param title Optional plot title.
#' @param node_label Either one of the preset modes `"value"` (default;
#'   payload for elements, blank for structural), `"type"` (node class
#'   name), `"both"` (type + value on separate lines), `"none"`, or a
#'   user-supplied function `function(node)` returning a single character
#'   string per vertex. The `node` argument is a list with fields:
#'   \describe{
#'     \item{`id`}{Internal graph vertex id (string).}
#'     \item{`type`}{Node class: `"Element"`, `"Digit"`, `"Deep"`,
#'       `"Node2"`, `"Node3"`, `"Single"`, or `"Empty"`.}
#'     \item{`label`}{The default label string.}
#'     \item{`measures`}{Named list of accumulated monoid values for the
#'       subtree rooted at this node. For structural nodes these are the
#'       cached values; for element leaves, each entry is the monoid's
#'       `measure()` applied to the leaf entry. Keys include built-ins
#'       (`.size`, `.named_count`, and any structure-specific ones like
#'       `.pq_min`) plus any custom name added via [add_monoids()].}
#'     \item{`element`}{For element nodes, the raw leaf entry. Shape
#'       depends on the structure type; see [measure_monoid()] for the
#'       entry contract. `NULL` for structural nodes.}
#'   }
#'   Measure values are exposed as-is, including list-valued measures
#'   (e.g. the built-in `.pq_min` is `list(has, priority)`).
#' @param label.cex Numeric scalar controlling label text size (passed as
#'   `vertex.label.cex` to igraph). If `NULL` (default), scales
#'   automatically from ~1.0 on small trees down to ~0.55 on dense ones so
#'   the auto-sized `"rounded_rect"` boxes don't collide. Override with a
#'   fixed value for finer control.
#' @param asp Plot aspect ratio (physical y-unit / physical x-unit).
#'   Default `NA` lets the tree fill the device without aspect constraint.
#'   Set to a numeric (e.g. `0.4`) to enforce horizontal stretching,
#'   or `1` for a square plot region.
#' @param legend If `TRUE` (default), draws a horizontal legend below the
#'   tree mapping node-type names to their fill colors, restricted to
#'   types actually present.
#' @param ... Additional arguments passed to `igraph::plot.igraph` (e.g.
#'   `vertex.label.color`, `vertex.frame.color`).
#' @return Invoked for its side effect (draws to the active graphics
#'   device). Returns `NULL` invisibly.
#' @examples
#' \dontrun{
#' t <- as_flexseq(letters[1:8])
#' plot_structure(t, title = "Finger tree")
#'
#' # Custom label: show subtree sum at every node (leaves show their own
#' # value, structural nodes show the accumulated total).
#' sum_monoid <- measure_monoid(`+`, 0, function(el) el)
#' xs <- add_monoids(as_flexseq(c(3, 1, 4, 1, 5, 9, 2, 6)),
#'                   list(sum = sum_monoid))
#' plot_structure(xs, node_label = function(node) {
#'   if(node$type == "Element") sprintf("%g\nΣ=%g", node$element, node$measures$sum)
#'   else sprintf("%s\nΣ=%g", node$type, node$measures$sum)
#' })
#' }
#' @seealso [plot.flexseq()], [measure_monoid()], [add_monoids()]
#' @export
# Runtime: O(n) to build graph structures prior to plotting.
plot_structure <- function(t1, vertex.size = 15, vertex.shape = "rounded_rect",
                           edge.width = 1, label_edges = FALSE, title = NULL,
                           node_label = "value", label.cex = NULL,
                           asp = NA, legend = TRUE, ...) {
  if(!requireNamespace("igraph", quietly = TRUE)) {
    stop("Package 'igraph' is required for plot_structure(). Install it with install.packages('igraph').")
  }

  if(identical(vertex.shape, "rounded_rect")) {
    .register_rounded_rect_shape()
  }

  gdf <- get_graph_df(t1)
  t1_edge_df <- gdf[[1]]
  t1_node_df <- gdf[[2]]
  node_data <- gdf[[3]]

  type_colors <- c(
    Element = "#ffffb3",
    Digit   = "#8dd3c7",
    Deep    = "#bebada",
    Node2   = "#b3de69",
    Node3   = "#fdb462",
    Single  = "#80b1d3",
    Empty   = "#fb8072"
  )
  t1_node_df$color <- unname(type_colors[t1_node_df$type])

  vertices_df <- unique(t1_node_df)
  g <- igraph::graph_from_data_frame(t1_edge_df, vertices = vertices_df, directed = TRUE)

  present_types <- if(isTRUE(legend)) {
    intersect(names(type_colors), unique(vertices_df$type))
  } else {
    character(0L)
  }
  draw_legend <- length(present_types) > 0L

  old_par <- par(no.readonly = TRUE)
  on.exit({
    graphics::layout(1L)
    par(old_par)
  }, add = TRUE)

  if(draw_legend) {
    graphics::layout(matrix(c(1L, 2L), ncol = 1L), heights = c(10, 1))
  }
  # Shrink default margins so the tree fills the panel; leave a little on
  # top for the optional `title`.
  par(mar = c(0.2, 0.2, if(is.null(title)) 0.2 else 2, 0.2))

  if(is.function(node_label)) {
    vertex_ids <- igraph::V(g)$name
    vlabels <- vapply(vertex_ids, function(id) {
      out <- node_label(node_data[[id]])
      if(is.null(out) || length(out) == 0L) "" else as.character(out)[[1L]]
    }, character(1))
  } else {
    node_label <- match.arg(node_label, c("value", "type", "both", "none"))
    if(node_label == "none") {
      vlabels <- rep("", igraph::vcount(g))
    } else if(node_label == "type") {
      vlabels <- igraph::V(g)$type
    } else if(node_label == "both") {
      vlabels <- ifelse(igraph::V(g)$label == "", igraph::V(g)$type, paste0(igraph::V(g)$type, "\n", igraph::V(g)$label))
    } else {
      vlabels <- igraph::V(g)$label
    }
  }

  auto_cex <- if(is.null(label.cex)) {
    # Shrink labels on dense trees so auto-sized rounded_rect boxes don't
    # collide. Tuned so small trees render at cex ~1 and trees approaching
    # ~50+ nodes render around cex ~0.6–0.7.
    n_nodes <- igraph::vcount(g)
    max(0.55, min(1.0, sqrt(25 / n_nodes)))
  } else {
    label.cex
  }

  plot(g,
       layout = igraph::layout_as_tree(g),
       vertex.label = vlabels,
       vertex.label.cex = auto_cex,
       vertex.size = vertex.size,
       vertex.shape = vertex.shape,
       asp = asp,
       edge.arrow.size = 0.4,
       edge.arrow.mode = 0,
       edge.width = edge.width,
       edge.label = ifelse(label_edges, t1_edge_df$label, ""),
       main = title,
       ...
  )

  if(draw_legend) {
    par(mar = c(0, 0, 0, 0))
    plot.new()
    graphics::legend(
      "center",
      legend = present_types,
      fill = unname(type_colors[present_types]),
      border = "black",
      bty = "n",
      cex = 0.8,
      horiz = TRUE
    )
  }

  invisible(NULL)
}
