# Heavy end-to-end test: builds a Docker image from the uvr fixture, starts it,
# and probes the running shiny app over HTTP. Skipped by default — only runs
# when SHINY2DOCKER_TEST_INTEGRATION=true and `docker` is on PATH.
#
# Local run:
#   SHINY2DOCKER_TEST_INTEGRATION=true Rscript -e \
#     'devtools::test_active_file("tests/testthat/test-shiny2docker_uvr-integration.R")'
#
# Expect 5–10 min on a cold cache (uvr 0.2.15 currently compiles all R deps
# from source on debian targets).

skip_unless_docker_uvr_integration <- function() {
  testthat::skip_on_cran()
  if (!identical(Sys.getenv("SHINY2DOCKER_TEST_INTEGRATION"), "true")) {
    testthat::skip("Set SHINY2DOCKER_TEST_INTEGRATION=true to run.")
  }
  if (!nzchar(Sys.which("docker"))) {
    testthat::skip("docker not on PATH")
  }
  if (system("docker info > /dev/null 2>&1") != 0) {
    testthat::skip("docker daemon not reachable")
  }
}

free_port <- function() {
  con <- socketConnection(host = "127.0.0.1", port = 0L,
                          server = TRUE, blocking = FALSE)
  on.exit(close(con))
  port <- as.integer(socketSelect(list(con)) || TRUE)
  # fallback: pick a high random port if the above doesn't expose it
  sample(20000:39999, 1)
}

http_probe <- function(url, tries = 30L, delay = 2) {
  for (i in seq_len(tries)) {
    code <- tryCatch(
      suppressWarnings({
        con <- url(url, "rb")
        on.exit(close(con), add = TRUE)
        readLines(con, n = 1, warn = FALSE)
        200L
      }),
      error = function(e) NA_integer_
    )
    if (isTRUE(code == 200L)) return(200L)
    Sys.sleep(delay)
  }
  NA_integer_
}

test_that("shiny2docker_uvr produces an image that serves a shiny app over HTTP", {
  skip_unless_docker_uvr_integration()

  # Stage the committed fixture into a tmp build context (we don't want the
  # Dockerfile/.dockerignore the test generates polluting the repo).
  src_fixture <- testthat::test_path("fixtures", "uvr-app")
  ctx <- tempfile("uvr_app_ctx_"); dir.create(ctx)
  file.copy(list.files(src_fixture, all.files = TRUE, no.. = TRUE,
                       full.names = TRUE),
            ctx, recursive = TRUE, copy.date = TRUE)
  # Make sure uvr.lock is at least as recent as uvr.toml after copy.
  Sys.setFileTime(file.path(ctx, "uvr.lock"), Sys.time())

  shiny2docker_uvr(
    path        = ctx,
    uvr_version = "v0.2.15"
  )
  expect_true(file.exists(file.path(ctx, "Dockerfile")))
  expect_true(file.exists(file.path(ctx, ".dockerignore")))

  tag       <- paste0("shiny2docker-uvr-it:", as.integer(Sys.time()))
  port      <- sample(20000:39999, 1)
  container <- sub("^.*:", "s2duvr-it-", tag)

  on.exit({
    system(paste("docker rm -f", shQuote(container), "> /dev/null 2>&1"))
    system(paste("docker rmi -f", shQuote(tag),     "> /dev/null 2>&1"))
    unlink(ctx, recursive = TRUE)
  }, add = TRUE)

  t0 <- Sys.time()
  build_rc <- system2(
    "docker",
    args   = c("build", "-q", "-t", tag, ctx),
    stdout = TRUE, stderr = TRUE
  )
  build_dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  expect_true(!is.null(attr(build_rc, "status")) == FALSE,
              info = paste("docker build failed:",
                           paste(build_rc, collapse = "\n")))
  message(sprintf("[uvr-IT] docker build: %.1fs", build_dt))

  size_str <- system2(
    "docker",
    args = c("images", tag, "--format", "{{.Size}}"),
    stdout = TRUE
  )
  message(sprintf("[uvr-IT] image size: %s", size_str))

  run_rc <- system2(
    "docker",
    args = c("run", "-d", "--name", container, "-p",
             paste0(port, ":3838"), tag),
    stdout = TRUE, stderr = TRUE
  )
  expect_true(is.null(attr(run_rc, "status")) || attr(run_rc, "status") == 0,
              info = paste("docker run failed:", paste(run_rc, collapse = "\n")))

  status <- http_probe(sprintf("http://127.0.0.1:%d/", port), tries = 30L, delay = 2)
  expect_identical(status, 200L)
})
