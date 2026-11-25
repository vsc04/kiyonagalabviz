test_that("Slides targets accept URLs and contain no authentication data", {
  target <- slides_target("https://docs.google.com/presentation/d/abc_123/edit#slide=id.x", "deploy_123")
  expect_s3_class(target, "kiyonaga_slides_target")
  expect_identical(unclass(target), list(presentation = "abc_123", deployment_id = "deploy_123"))
  expect_error(slides_target("", "deploy"), "non-empty")
  expect_error(slides_target("id", "https://other.example"), "deployment ID")
})

test_that("OAuth uses a Desktop client and caches outside the working directory", {
  skip_if_not_installed("httr")
  skip_if_not_installed("jsonlite")
  client <- tempfile(fileext = ".json")
  cache <- tempfile()
  jsonlite::write_json(list(installed = list(client_id = "test-client",
                                            client_secret = "test-secret")), client, auto_unbox = TRUE)
  previous <- slides_session$token
  withr::defer(slides_session$token <- previous)
  seen <- NULL
  local_mocked_bindings(oauth2.0_token = function(endpoint, app, scope, cache, ...) {
    seen <<- list(app = app, scope = scope, cache = cache,
                  existed = file.exists(cache), extra = list(...))
    writeLines("test cache", cache)
    "test-token"
  }, .package = "httr")
  expect_identical(slides_auth(client, cache), "test-token")
  expect_identical(slides_session$token, "test-token")
  expect_identical(seen$scope, c("https://www.googleapis.com/auth/presentations",
                                 "https://www.googleapis.com/auth/script.storage"))
  expect_identical(seen$cache, file.path(cache, "google-oauth"))
  expect_identical(seen$app$key, "test-client")
  expect_false(startsWith(tools::R_user_dir("kiyonagalabviz", "cache"), getwd()))
  expect_identical(slides_auth(client, cache, reauth = TRUE), "test-token")
  expect_false(seen$existed)
  expect_identical(seen$extra$query_authorize_extra$prompt, "consent")
  expect_error(slides_auth(client, cache, reauth = NA), "TRUE or FALSE")
  jsonlite::write_json(list(web = list(client_id = "test")), client)
  expect_error(slides_auth(client, cache), "Desktop app")
})

test_that("private bridge requests use the deployment ID and authenticated JSON", {
  skip_if_not_installed("httr")
  skip_if_not_installed("jsonlite")
  previous <- slides_session$token
  withr::defer(slides_session$token <- previous)
  slides_session$token <- NULL
  expect_error(slides_call(slides_target("p", "deployment"), "inspect", list()), "Sign in")
  slides_session$token <- "test-token"
  seen <- NULL
  local_mocked_bindings(
    POST = function(url, ..., body, encode) {
      seen <<- list(url = url, body = body, encode = encode)
      list()
    },
    status_code = function(...) 200L,
    content = function(...) list(done = TRUE, response = list(result = list(panels = list()))),
    .package = "httr"
  )
  expect_equal(slides_call(slides_target("p", "deployment"), "inspect", list()),
               list(panels = list()))
  expect_identical(seen$url, "https://script.googleapis.com/v1/scripts/deployment:run")
  expect_identical(seen$body$`function`, "kiyonagaSlides")
  expect_identical(seen$body$parameters[[1]]$presentation, "p")
  expect_identical(seen$encode, "json")
})

test_that("HTTP errors expose Google's explanation without request credentials", {
  skip_if_not_installed("httr")
  local_mocked_bindings(
    status_code = function(...) 403L,
    content = function(...) list(error = list(
      message = "Apps Script API has not been used in project 123 or it is disabled.",
      details = list(list(reason = "SERVICE_DISABLED"))
    )),
    .package = "httr"
  )
  expect_error(slides_response(list()), "HTTP 403.*API has not been used.*SERVICE_DISABLED")
  local_mocked_bindings(content = function(...) "HTML error page", .package = "httr")
  expect_error(slides_response(list()), "HTTP 403.*Google rejected the request")
})

test_that("invalid panel files are rejected before remote calls", {
  local_mocked_bindings(slides_call = function(...) stop("Unexpected network call"))
  expect_error(slides_sync(NULL, "a.png"), "unique")
  expect_error(slides_sync(NULL, c(A = "a", A = "b")), "unique")
  expect_error(slides_sync(NULL, c(A = "missing.png")), "not found")
  text <- tempfile(fileext = ".png")
  writeLines("not PNG", text)
  expect_error(slides_sync(NULL, c(A = text)), "PNG images")
})

slides_test_png <- function() {
  file <- tempfile(fileext = ".png")
  grDevices::png(file, width = 100, height = 100)
  grid::grid.rect(gp = grid::gpar(fill = "red", col = NA))
  grDevices::dev.off()
  file
}

test_that("refresh uses unique panel names and sends PNGs only after inspection", {
  skip_if_not_installed("jsonlite")
  files <- c(B = slides_test_png(), A = slides_test_png())
  calls <- list()
  local_mocked_bindings(slides_call = function(target, action, payload) {
    calls[[length(calls) + 1L]] <<- list(action = action, payload = payload)
    if (action == "inspect") return(list(panels = list(
      list(panel = "A", object_id = "id_a", fingerprint = "fp_a", crop = list(0, 0, 1, 1)),
      list(panel = "B", object_id = "id_b", fingerprint = "fp_b", crop = list(0, 0, 1, 1)))))
    list(panel = payload$panel)
  })
  expect_message(result <- slides_sync(slides_target("p", "d"), files), "Updated")
  expect_equal(result, names(files))
  expect_equal(vapply(calls, `[[`, character(1), "action"), c("inspect", "update", "update"))
  expect_equal(calls[[2]]$payload$object_id, "id_a")
  expect_identical(jsonlite::base64_dec(calls[[2]]$payload$image),
                   readBin(files[["A"]], "raw", n = file.info(files[["A"]])$size))
})

test_that("bad plans and unsupported crops cause no remote writes", {
  skip_if_not_installed("jsonlite")
  files <- c(A = slides_test_png())
  actions <- character()
  plan <- list(panel = "A", crop = list(0, 0, 2, 1))
  local_mocked_bindings(slides_call = function(target, action, payload) {
    actions <<- c(actions, action)
    list(panels = list(plan))
  })
  expect_error(slides_sync(slides_target("p", "d"), files), "Unsupported panel crop")
  expect_identical(actions, "inspect")
  plan$panel <- "other"
  expect_error(slides_sync(slides_target("p", "d"), files), "does not match")
})

test_that("crop pixels and alpha are preserved for repeated source exports", {
  skip_if_not_installed("png")
  file <- tempfile(fileext = ".png")
  image <- array(seq_len(8 * 10 * 4) / (8 * 10 * 4), c(8, 10, 4))
  png::writePNG(image, file)
  original <- png::readPNG(file)
  expect_equal(png::readPNG(slides_crop(file, c(.2, .25, .8, .75))),
               original[3:6, 3:8, , drop = FALSE])
  expect_identical(slides_crop(file, c(0, 0, 1, 1)),
                   readBin(file, "raw", n = file.info(file)$size))
  expect_error(slides_crop(file, c(1, 0, 0, 1)), "Unsupported")
})

test_that("Apps Script failures and incomplete responses are not successes", {
  expect_error(slides_result(list(error = list(message = "Failure", details = list(
    list(errorMessage = "Panel A missing"))))), "Panel A missing")
  expect_error(slides_result(list(done = FALSE)), "did not confirm")
  expect_equal(slides_result(list(done = TRUE, response = list(result = list(panel = "A")))),
               list(panel = "A"))
})

test_that("nice_save refreshes only after successful PNG export", {
  file <- tempfile(fileext = ".png")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() + theme_kiyonaga()
  target <- slides_target("p", "d")
  seen <- NULL
  local_mocked_bindings(slides_sync = function(target, files) {
    expect_true(file.exists(files[[1]]))
    seen <<- files
  })
  expect_message(nice_save(file, p, dpi = 72, slides = target, panel = "A"), "Saving")
  expect_identical(seen, c(A = file))
  expect_error(nice_save("bad.pdf", p, slides = target, panel = "A"), "must be saved as .png")
  expect_error(nice_save(file, p, slides = target), "non-empty")
  expect_error(nice_save(file, p, panel = "A"), "Supply `slides`")
  local_mocked_bindings(slides_sync = function(...) stop("Remote failure"))
  expect_error(nice_save(file, p, dpi = 72, slides = target, panel = "A"), "Remote failure")
  expect_true(file.exists(file))
})
