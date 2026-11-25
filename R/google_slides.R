#' Sign in to Google Slides
#'
#' Uses a Google OAuth Desktop app client, not an API key. The client JSON and
#' cached refresh tokens should be stored outside your project. See the
#' setup instructions in `inst/google-slides/README.md` in the
#' source package, or `system.file("google-slides", "README.md",
#' package = "kiyonagalabviz")` after installation.
#'
#' @param client Path to the downloaded OAuth Desktop app client JSON.
#' @param cache Directory for private OAuth tokens. Defaults to the user's
#'   application cache, outside the project.
#' @param reauth Discard this package's local token cache and request fresh
#'   consent. Use after changing scopes or when a cached grant has expired.
#' @return The OAuth token, invisibly. Also stores it for this R session.
#' @export
slides_auth <- function(client = Sys.getenv("KIYONAGA_GOOGLE_CLIENT"),
                        cache = tools::R_user_dir("kiyonagalabviz", "cache"),
                        reauth = FALSE) {
  slides_require(c("httr", "jsonlite"))
  if (!nzchar(client) || !file.exists(client)) {
    stop("Set `client` to your OAuth Desktop app JSON outside the repository.", call. = FALSE)
  }
  credentials <- jsonlite::read_json(client)$installed
  if (!is.character(credentials$client_id) || length(credentials$client_id) != 1L ||
      !is.character(credentials$client_secret) || length(credentials$client_secret) != 1L) {
    stop("Use an OAuth Desktop app client JSON (with an `installed` entry).", call. = FALSE)
  }
  if (!is.logical(reauth) || length(reauth) != 1L || is.na(reauth)) {
    stop("`reauth` must be TRUE or FALSE.", call. = FALSE)
  }
  dir.create(cache, recursive = TRUE, showWarnings = FALSE, mode = "0700")
  cache_file <- file.path(cache, "google-oauth")
  if (reauth) {
    slides_session$token <- NULL
    if (file.exists(cache_file) && unlink(cache_file) != 0L) {
      stop("Cannot clear the local OAuth cache: ", cache_file, call. = FALSE)
    }
  }
  authorize <- list(access_type = "offline")
  if (reauth) authorize$prompt <- "consent"
  token <- httr::oauth2.0_token(
    httr::oauth_endpoints("google"),
    httr::oauth_app("kiyonagalabviz", key = credentials$client_id,
                   secret = credentials$client_secret),
    scope = c("https://www.googleapis.com/auth/presentations",
              "https://www.googleapis.com/auth/script.storage"),
    cache = cache_file,
    use_oob = FALSE,
    query_authorize_extra = authorize
  )
  Sys.chmod(cache_file, mode = "0600")
  slides_session$token <- token
  invisible(token)
}

slides_session <- new.env(parent = emptyenv())

#' Connect plot files to a Google Slides presentation
#'
#' This configuration contains presentation and deployment IDs, not credentials.
#' Install the bundled Apps Script bridge once; see the setup instructions at
#' `system.file("google-slides", "README.md", package = "kiyonagalabviz")`.
#'
#' @param presentation Presentation ID or its Google Slides URL.
#' @param deployment_id Apps Script API executable deployment ID. Defaults to
#'   the `KIYONAGA_SLIDES_DEPLOYMENT` environment variable.
#' @return A Slides target configuration, for [slides_panels()], [slides_sync()]
#'   and [nice_save()].
#' @export
#' @examples
#' target <- slides_target("presentation_id", "deployment_id")
slides_target <- function(presentation,
                          deployment_id = Sys.getenv("KIYONAGA_SLIDES_DEPLOYMENT")) {
  slides_string(presentation, "presentation")
  slides_string(deployment_id, "deployment_id")
  if (grepl("^https://docs.google.com/presentation/d/", presentation)) {
    presentation <- sub("^https://docs.google.com/presentation/d/([^/]+).*$", "\\1", presentation)
  }
  if (!grepl("^[A-Za-z0-9_-]+$", presentation) ||
      !grepl("^[A-Za-z0-9_-]+$", deployment_id)) {
    stop("Use a presentation ID/URL and an API executable deployment ID.", call. = FALSE)
  }
  structure(list(presentation = presentation, deployment_id = deployment_id),
            class = "kiyonaga_slides_target")
}

#' List panel images in Google Slides
#'
#' Give each panel image a unique Alt text **Title** in Slides, for example
#' `panel_A`. Only top-level images are supported; ungroup panels before syncing.
#'
#' @param target A [slides_target()] configuration.
#' @return A data frame of panel names, object IDs, slide numbers and frame sizes
#'   in points (72 points per inch). This does not modify the presentation.
#' @export
slides_panels <- function(target) {
  result <- slides_call(target, "inspect", list())
  fields <- c("panel", "object_id", "slide", "width", "height")
  if (!length(result$panels)) {
    return(data.frame(panel = character(), object_id = character(), slide = integer(),
                      width = numeric(), height = numeric()))
  }
  rows <- lapply(result$panels, function(x) as.data.frame(x[fields], stringsAsFactors = FALSE))
  do.call(rbind, rows)
}

#' Refresh plot panels in Google Slides
#'
#' Replaces named panel images while keeping their frames, rotation, stacking
#' order and Alt text. Current crops are applied to the new PNG before upload;
#' the bridge remembers the source crop for subsequent refreshes. Further crops
#' in Slides are relative to the already cropped preview. To restore the full
#' source, delete and reinsert that panel image, then restore its Alt text Title.
#' Rotated crop regions, flipped crops, and crops outside the source are rejected.
#'
#' All files and panel names are checked before replacement. Updates occur one
#' panel at a time: an error may leave earlier panels updated. There is no
#' background watcher; call this at the end of a successful plotting script, or
#' use `slides` and `panel` in [nice_save()] to refresh immediately after saving.
#' Images travel through an authenticated Apps Script request; no public image
#' hosting or Drive sharing changes are required. PNG previews are raster images;
#' retain SVG/PDF exports for vector publication output.
#'
#' @param target A [slides_target()] configuration. Call [slides_auth()] first.
#' @param files Named character vector of PNG paths. Names must match unique
#'   image Alt text Titles in the presentation.
#' @return Panel names refreshed, invisibly.
#' @export
#' @examples
#' \dontrun{
#' slides_auth(client = "~/.config/kiyonagalabviz/google_client.json")
#' target <- slides_target("presentation_id", "deployment_id")
#' slides_panels(target)
#' slides_sync(target, c(panel_A = "panels/means.png", panel_B = "panels/scatter.png"))
#' }
slides_sync <- function(target, files) {
  slides_files(files)
  plan <- slides_call(target, "inspect", list(panels = unname(as.list(names(files)))))$panels
  if (length(plan) != length(files)) stop("Incomplete panel plan from Slides.", call. = FALSE)
  matched <- vapply(plan, function(x) x$panel, character(1))
  if (!setequal(matched, names(files))) stop("Panel plan does not match files.", call. = FALSE)
  # Prepare every image before making any remote edits.
  payloads <- lapply(plan, function(x) {
    bytes <- slides_crop(files[[x$panel]], unlist(x$crop, use.names = FALSE))
    list(panel = x$panel, object_id = x$object_id, fingerprint = x$fingerprint,
         crop = x$crop, image = jsonlite::base64_enc(bytes))
  })
  for (payload in payloads) {
    slides_call(target, "update", payload)
    message("Updated Google Slides panel: ", payload$panel)
  }
  invisible(names(files))
}

slides_string <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    stop("`", name, "` must be a non-empty string.", call. = FALSE)
  }
}

slides_require <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop("Google Slides support requires: ", paste(missing, collapse = ", "),
         ". Install with install.packages(c(",
         paste(sprintf('"%s"', missing), collapse = ", "), ")).", call. = FALSE)
  }
}

slides_files <- function(files) {
  if (!is.character(files) || !length(files) || is.null(names(files)) ||
      anyNA(files) || anyNA(names(files)) || any(!nzchar(names(files))) ||
      anyDuplicated(names(files))) {
    stop("`files` must be PNG paths with unique, non-empty panel names.", call. = FALSE)
  }
  for (file in files) {
    if (!file.exists(file) || dir.exists(file)) stop("Panel file not found: ", file, call. = FALSE)
    header <- readBin(file, "raw", n = 24L)
    signature <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
    if (length(header) < 24L || !identical(header[1:8], signature)) {
      stop("Slides panel files must be PNG images: ", file, call. = FALSE)
    }
    width <- sum(as.integer(header[17:20]) * 256^(3:0))
    height <- sum(as.integer(header[21:24]) * 256^(3:0))
    if (width * height > 25e6 || width <= 0 || height <= 0 || file.info(file)$size >= 50e6) {
      stop("Panel exceeds Google's image limits (25 megapixels; under 50 MB): ", file, call. = FALSE)
    }
  }
  invisible(files)
}

slides_crop <- function(file, crop) {
  if (!is.numeric(crop) || length(crop) != 4L || any(!is.finite(crop)) ||
      crop[1] < 0 || crop[2] < 0 || crop[3] > 1 || crop[4] > 1 ||
      crop[1] >= crop[3] || crop[2] >= crop[4]) {
    stop("Unsupported panel crop; restore a crop within the source image.", call. = FALSE)
  }
  if (isTRUE(all.equal(crop, c(0, 0, 1, 1)))) {
    return(readBin(file, "raw", n = file.info(file)$size))
  }
  slides_require("png")
  image <- png::readPNG(file)
  dims <- dim(image)
  left <- floor(crop[1] * dims[2]) + 1L
  top <- floor(crop[2] * dims[1]) + 1L
  right <- max(left, ceiling(crop[3] * dims[2]))
  bottom <- max(top, ceiling(crop[4] * dims[1]))
  image <- if (length(dims) == 2L) {
    image[top:bottom, left:right, drop = FALSE]
  } else image[top:bottom, left:right, , drop = FALSE]
  png::writePNG(image)
}

slides_call <- function(target, action, payload) {
  if (!inherits(target, "kiyonaga_slides_target")) {
    stop("`target` must come from slides_target().", call. = FALSE)
  }
  slides_require(c("httr", "jsonlite"))
  if (is.null(slides_session$token)) stop("Sign in with slides_auth() first.", call. = FALSE)
  response <- httr::POST(
    paste0("https://script.googleapis.com/v1/scripts/", target$deployment_id, ":run"),
    httr::config(token = slides_session$token), httr::timeout(360),
    body = list(`function` = "kiyonagaSlides", parameters = list(list(
      presentation = target$presentation, action = action, payload = payload))),
    encode = "json"
  )
  slides_response(response)
}

slides_response <- function(response) {
  status <- httr::status_code(response)
  result <- tryCatch(
    httr::content(response, as = "parsed", simplifyVector = FALSE),
    error = function(e) NULL
  )
  if (status >= 400L) {
    # Report Google's explanation, rather than exposing the request, OAuth
    # token, or uploaded image bytes while troubleshooting authentication.
    error <- if (is.list(result)) result$error else NULL
    message <- if (is.character(error$message) && length(error$message) == 1L) {
      error$message
    } else "Google rejected the request."
    reasons <- vapply(error$details, function(x) {
      if (is.character(x$reason) && length(x$reason) == 1L) x$reason else ""
    }, character(1))
    reasons <- unique(reasons[nzchar(reasons)])
    stop("Google Slides (HTTP ", status, "): ", message,
         if (length(reasons)) paste0(" [", paste(reasons, collapse = ", "), "]"),
         call. = FALSE)
  }
  slides_result(result)
}

slides_result <- function(result) {
  if (!is.null(result$error)) {
    detail <- result$error$details
    message <- if (length(detail) && !is.null(detail[[1]]$errorMessage)) {
      detail[[1]]$errorMessage
    } else result$error$message
    stop("Google Slides: ", message, call. = FALSE)
  }
  if (!isTRUE(result$done) || is.null(result$response$result)) {
    stop("Google Slides did not confirm completion. Inspect the deck before retrying.", call. = FALSE)
  }
  result$response$result
}
