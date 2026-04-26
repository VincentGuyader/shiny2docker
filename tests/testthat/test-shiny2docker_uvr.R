# Helper: lay down a minimal uvr-ready project in a tmp dir
make_uvr_fixture <- function() {
  tmp <- tempfile("uvrproj_")
  dir.create(tmp)
  writeLines("4.4.2", file.path(tmp, ".r-version"))
  writeLines(
    c(
      "[project]",
      "name = \"demo\"",
      "r-version = \">=4.3\"",
      "",
      "[dependencies]",
      "shiny = \"*\""
    ),
    file.path(tmp, "uvr.toml")
  )
  # uvr.lock placeholder; mtime must be >= uvr.toml's mtime
  writeLines("# uvr.lock fixture", file.path(tmp, "uvr.lock"))
  Sys.setFileTime(file.path(tmp, "uvr.lock"), Sys.time() + 1)
  writeLines("library(shiny); shinyApp(fluidPage(), function(input,output){})",
             file.path(tmp, "app.R"))
  tmp
}

test_that("uvr_release_url returns latest URL when version = 'latest'", {
  out <- uvr_release_url("latest")
  expect_match(out$url, "releases/latest/download/uvr-x86_64-unknown-linux-gnu\\.tar\\.gz$")
  expect_true(is.na(out$arg_value))
})

test_that("uvr_release_url accepts pinned tags with or without leading v", {
  a <- uvr_release_url("0.3.1")
  b <- uvr_release_url("v0.3.1")
  expect_identical(a$url, b$url)
  expect_match(a$url, "releases/download/v0\\.3\\.1/")
  expect_identical(a$arg_value, "v0.3.1")
})

test_that("uvr_release_url rejects garbage versions", {
  expect_error(uvr_release_url("nope"),       "semver")
  expect_error(uvr_release_url("1.2"),        "semver")
  expect_error(uvr_release_url("v0.3.1junk"), "semver")
  expect_error(uvr_release_url("0.3.1-beta"), "semver")
})

test_that("uvr_validate_host_port rejects shell-unsafe values", {
  expect_silent(uvr_validate_host_port("0.0.0.0", 3838))
  expect_silent(uvr_validate_host_port("my-host_1.local", 80))
  expect_error(uvr_validate_host_port("0.0.0.0; rm -rf /", 3838), "host")
  expect_error(uvr_validate_host_port("0.0.0.0", 0),        "port")
  expect_error(uvr_validate_host_port("0.0.0.0", 99999),    "port")
  expect_error(uvr_validate_host_port("0.0.0.0", "3838"),   "port")
  expect_error(uvr_validate_host_port(NA, 3838),            "host")
  expect_error(uvr_validate_host_port(c("a","b"), 3838),    "host")
})

test_that("uvr_validate_sysreqs rejects shell-unsafe entries", {
  expect_silent(uvr_validate_sysreqs(NULL))
  expect_silent(uvr_validate_sysreqs(character()))
  expect_silent(uvr_validate_sysreqs(c("libpq-dev", "libsqlite3-dev")))
  expect_error(uvr_validate_sysreqs(c("libpq-dev", "evil; rm -rf /")), "Invalid")
  expect_error(uvr_validate_sysreqs(c("libpq-dev", NA)),               "NA")
})

test_that("shiny2docker_uvr propagates validation errors", {
  tmp <- make_uvr_fixture()
  expect_error(
    shiny2docker_uvr(path = tmp, host = "0.0.0.0; whoami", write = FALSE),
    "host"
  )
  expect_error(
    shiny2docker_uvr(path = tmp, port = 70000, write = FALSE),
    "port"
  )
  expect_error(
    shiny2docker_uvr(path = tmp,
                     extra_sysreqs = c("libpq-dev", "evil;cmd"),
                     write = FALSE),
    "Invalid"
  )
})

test_that("shiny2docker_uvr does not write a .dockerignore when write = FALSE", {
  tmp <- make_uvr_fixture()
  out_file <- file.path(tmp, "Dockerfile")
  shiny2docker_uvr(path = tmp, output = out_file, write = FALSE)
  expect_false(file.exists(out_file))
  expect_false(file.exists(file.path(tmp, ".dockerignore")))
})

test_that("uvr_assert_state errors when files are missing", {
  tmp <- tempfile("uvr_missing_"); dir.create(tmp)
  expect_error(
    uvr_assert_state(file.path(tmp, "uvr.toml"),
                     file.path(tmp, "uvr.lock"),
                     file.path(tmp, ".r-version")),
    "uvr.toml not found"
  )
})

test_that("uvr_assert_state errors when uvr.lock is older than uvr.toml", {
  tmp <- make_uvr_fixture()
  Sys.setFileTime(file.path(tmp, "uvr.lock"), Sys.time() - 60)
  Sys.setFileTime(file.path(tmp, "uvr.toml"), Sys.time())
  expect_error(
    uvr_assert_state(file.path(tmp, "uvr.toml"),
                     file.path(tmp, "uvr.lock"),
                     file.path(tmp, ".r-version")),
    "older than uvr.toml"
  )
})

test_that("shiny2docker_uvr produces a Dockerfile with the expected steps", {
  tmp <- make_uvr_fixture()
  out_file <- file.path(tmp, "Dockerfile")

  dock <- shiny2docker_uvr(path = tmp, output = out_file, uvr_version = "v0.3.1")

  expect_s3_class(dock, "Dockerfile")
  expect_s3_class(dock, "R6")
  expect_true(file.exists(out_file))
  expect_true(file.exists(file.path(tmp, ".dockerignore")))

  contents <- paste(readLines(out_file), collapse = "\n")
  expect_match(contents, "FROM debian:stable-slim")
  expect_match(contents, "ARG UVR_VERSION=v0\\.3\\.1")
  expect_match(contents, "uvr r install")
  expect_match(contents, "uvr sync")
  expect_match(contents, "EXPOSE 3838")
  expect_match(contents, "shiny::runApp")
})

test_that("shiny2docker_uvr does not write when write = FALSE", {
  tmp <- make_uvr_fixture()
  out_file <- file.path(tmp, "Dockerfile")
  dock <- shiny2docker_uvr(path = tmp, output = out_file, write = FALSE)
  expect_false(file.exists(out_file))
  expect_s3_class(dock, "Dockerfile")
})

test_that("shiny2docker_uvr injects extra_sysreqs in a dedicated RUN before uvr sync", {
  tmp <- make_uvr_fixture()
  out_file <- file.path(tmp, "Dockerfile")
  # Use packages that are NOT in the baseline apt list so we can locate
  # the dedicated RUN unambiguously.
  dock <- shiny2docker_uvr(
    path = tmp, output = out_file,
    extra_sysreqs = c("libsqlite3-dev", "libpq-dev")
  )
  contents <- paste(readLines(out_file), collapse = "\n")
  expect_match(contents, "libsqlite3-dev libpq-dev")
  pos_extra <- regexpr("libsqlite3-dev libpq-dev", contents)
  pos_sync  <- regexpr("uvr sync",                 contents)
  expect_true(pos_extra > 0 && pos_sync > 0 && pos_extra < pos_sync)
})
