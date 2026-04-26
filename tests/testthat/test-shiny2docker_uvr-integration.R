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

http_probe <- function(host, port, path = "/", tries = 30L, delay = 2) {
  request <- sprintf(
    "GET %s HTTP/1.0\r\nHost: %s:%d\r\nConnection: close\r\n\r\n",
    path, host, port
  )
  one_attempt <- function() {
    con <- NULL
    on.exit(if (!is.null(con)) try(close(con), silent = TRUE), add = TRUE)
    con <- tryCatch(
      suppressWarnings(socketConnection(host = host, port = port,
                                        blocking = TRUE, open = "r+",
                                        timeout = 5)),
      error = function(e) NULL
    )
    if (is.null(con)) return(NA_integer_)
    tryCatch({
      writeLines(request, con, sep = "")
      first <- readLines(con, n = 1, warn = FALSE)
      m <- regmatches(first, regexec("^HTTP/[0-9.]+ ([0-9]{3})", first))[[1]]
      if (length(m) >= 2) as.integer(m[2]) else NA_integer_
    }, error = function(e) NA_integer_)
  }
  for (i in seq_len(tries)) {
    status <- one_attempt()
    if (isTRUE(status == 200L)) return(200L)
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

  status <- http_probe(host = "127.0.0.1", port = port, path = "/",
                       tries = 30L, delay = 2)
  expect_identical(status, 200L)
})
