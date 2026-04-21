#!/usr/bin/env Rscript

# Maintainer utility: regenerate vignette demo GIF assets.
# Run from repository root:
#   R -q -f vignettes/articles/helpers/render_algorithm_demo_assets.R
#   R -q -f vignettes/articles/helpers/render_algorithm_demo_assets.R --args demo=sweep_line

source_demo_without_runner <- function(path, envir) {
  lines <- readLines(path, warn = FALSE)
  cut <- grep("^#?if\\s*\\(sys\\.nframe\\s*\\(\\)\\s*==\\s*0L\\)", lines)
  if(length(cut) > 0L) {
    lines <- lines[seq_len(cut[[1L]] - 1L)]
  }
  eval(parse(text = paste(lines, collapse = "\n")), envir = envir)
  invisible(TRUE)
}

load_render_dependencies <- function(repo_root) {
  if(requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(repo_root, quiet = TRUE)
  } else if(requireNamespace("Immutables", quietly = TRUE)) {
    library(Immutables)
  } else {
    stop("Need either installed 'Immutables' or 'pkgload' to render assets.")
  }
  invisible(TRUE)
}

source_demo_environment <- function(repo_root, helper_env, source_key) {
  demo_env <- new.env(parent = globalenv())
  source_rel <- helper_env$algorithm_demo_sources[[source_key]]
  if(is.null(source_rel) || !nzchar(source_rel)) {
    stop("Unknown demo source key: ", source_key)
  }
  source_demo_without_runner(file.path(repo_root, source_rel), envir = demo_env)
  demo_env
}

parse_render_cli_args <- function(args) {
  out <- list(demos = NULL, overwrite = TRUE, verbose = TRUE, sync_pkgdown = TRUE)
  if(length(args) == 0L) {
    return(out)
  }

  for(arg in args) {
    if(startsWith(arg, "demo=")) {
      v <- sub("^demo=", "", arg)
      out$demos <- if(nzchar(v)) strsplit(v, ",", fixed = TRUE)[[1L]] else character(0)
      next
    }
    if(startsWith(arg, "overwrite=")) {
      v <- tolower(sub("^overwrite=", "", arg))
      out$overwrite <- !identical(v, "false")
      next
    }
    if(startsWith(arg, "verbose=")) {
      v <- tolower(sub("^verbose=", "", arg))
      out$verbose <- !identical(v, "false")
      next
    }
    if(startsWith(arg, "sync_pkgdown=")) {
      v <- tolower(sub("^sync_pkgdown=", "", arg))
      out$sync_pkgdown <- !identical(v, "false")
      next
    }
  }

  out
}

render_algorithm_demo_assets <- function(
  demos = NULL,
  overwrite = TRUE,
  verbose = TRUE,
  sync_pkgdown = TRUE
) {
  repo_root <- normalizePath(getwd(), mustWork = TRUE)
  if(!file.exists(file.path(repo_root, "DESCRIPTION"))) {
    stop("Run this script from the repository root (directory containing DESCRIPTION).")
  }

  helper_env <- new.env(parent = baseenv())
  sys.source(file.path(repo_root, "vignettes", "articles", "helpers", "algorithm_demos_helpers.R"), envir = helper_env)
  presets <- helper_env$algorithm_demo_render_presets

  selected <- if(is.null(demos)) names(presets) else unique(as.character(demos))
  if(length(selected) == 1L && grepl(",", selected[[1L]], fixed = TRUE)) {
    selected <- strsplit(selected[[1L]], ",", fixed = TRUE)[[1L]]
  }
  selected <- selected[nzchar(selected)]
  if(length(selected) == 0L) {
    stop("No demos selected.")
  }

  unknown <- setdiff(selected, names(presets))
  if(length(unknown) > 0L) {
    stop("Unknown demo names: ", paste(unknown, collapse = ", "))
  }

  asset_dir <- file.path(repo_root, "vignettes", "articles", "assets", "algorithm-demos")
  dir.create(asset_dir, recursive = TRUE, showWarnings = FALSE)

  load_render_dependencies(repo_root)
  results <- vector("list", length(selected))
  names(results) <- selected

  for(name in selected) {
    preset <- presets[[name]]
    source_key <- preset$source
    runner <- preset$runner
    asset_key <- preset$asset_key
    outfile <- file.path(asset_dir, helper_env$algorithm_demo_asset_files[[asset_key]])

    if(file.exists(outfile) && !isTRUE(overwrite)) {
      if(isTRUE(verbose)) {
        cat("Skipping (exists):", outfile, "\n")
      }
      info <- file.info(outfile)
      results[[name]] <- list(
        demo = name,
        file = outfile,
        skipped = TRUE,
        frame_count = NA_integer_,
        steps = NA_integer_,
        size_bytes = as.numeric(info$size)
      )
      next
    }

    if(isTRUE(verbose)) {
      cat("Rendering", name, "->", outfile, "\n")
    }
    demo_env <- source_demo_environment(repo_root, helper_env, source_key)
    if(!exists(runner, envir = demo_env, mode = "function")) {
      stop("Missing runner function in sourced demo scripts: ", runner)
    }

    args <- preset$args
    args$outfile <- outfile
    render_result <- do.call(demo_env[[runner]], args)

    if(!file.exists(outfile)) {
      stop("Expected output GIF was not created: ", outfile)
    }

    frame_count <- NA_integer_
    steps <- NA_integer_
    if(is.list(render_result) && !is.null(render_result$visualization) && is.list(render_result$visualization)) {
      if(!is.null(render_result$visualization$frame_count)) {
        frame_count <- as.integer(render_result$visualization$frame_count)
      }
    }
    if(is.list(render_result) && !is.null(render_result$steps)) {
      steps <- as.integer(render_result$steps)
    }

    if(isTRUE(verbose)) {
      cat(
        sprintf(
          "  done: steps=%s frames=%s\n",
          ifelse(is.na(steps), "NA", as.character(steps)),
          ifelse(is.na(frame_count), "NA", as.character(frame_count))
        )
      )
    }

    info <- file.info(outfile)
    results[[name]] <- list(
      demo = name,
      file = outfile,
      skipped = FALSE,
      frame_count = frame_count,
      steps = steps,
      size_bytes = as.numeric(info$size)
    )
  }

  summary_df <- data.frame(
    demo = vapply(results, function(x) x$demo, character(1)),
    file = vapply(results, function(x) basename(x$file), character(1)),
    skipped = vapply(results, function(x) isTRUE(x$skipped), logical(1)),
    steps = vapply(results, function(x) x$steps, integer(1)),
    frame_count = vapply(results, function(x) x$frame_count, integer(1)),
    size_bytes = vapply(results, function(x) x$size_bytes, numeric(1)),
    stringsAsFactors = FALSE
  )

  if(isTRUE(verbose)) {
    cat("Wrote assets to", asset_dir, "\n")
    print(summary_df)
  }

  pkgdown_asset_dir <- file.path(repo_root, "docs", "articles", "assets", "algorithm-demos")
  synced_files <- character(0)
  if(isTRUE(sync_pkgdown) && dir.exists(pkgdown_asset_dir)) {
    for(name in selected) {
      from <- file.path(asset_dir, helper_env$algorithm_demo_asset_files[[name]])
      to <- file.path(pkgdown_asset_dir, helper_env$algorithm_demo_asset_files[[name]])
      ok <- file.copy(from, to, overwrite = TRUE)
      if(!isTRUE(ok)) {
        stop("Failed syncing pkgdown asset: ", to)
      }
      synced_files <- c(synced_files, to)
    }
    if(isTRUE(verbose)) {
      cat("Synced pkgdown assets to", pkgdown_asset_dir, "\n")
    }
  }

  invisible(list(
    asset_dir = asset_dir,
    pkgdown_asset_dir = pkgdown_asset_dir,
    synced_pkgdown_files = synced_files,
    selected = selected,
    summary = summary_df,
    results = results
  ))
}

if(sys.nframe() == 0L) {
  cli <- parse_render_cli_args(commandArgs(trailingOnly = TRUE))
  render_algorithm_demo_assets(
    demos = cli$demos,
    overwrite = cli$overwrite,
    verbose = cli$verbose,
    sync_pkgdown = cli$sync_pkgdown
  )
}
