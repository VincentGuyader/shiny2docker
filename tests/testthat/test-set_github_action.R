library(testthat)

test_that("set_github_action copies docker-build.yml to .github/workflows/", {
  tmp_dir <- tempfile("s2d_gha_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  result <- set_github_action(path = tmp_dir)

  expect_true(isTRUE(result))
  expect_true(dir.exists(file.path(tmp_dir, ".github", "workflows")))
  expect_true(file.exists(file.path(tmp_dir, ".github", "workflows", "docker-build.yml")))
})

test_that("set_github_action copied content matches source file byte-equivalent", {
  tmp_dir <- tempfile("s2d_gha_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  set_github_action(path = tmp_dir)

  source_file <- system.file("docker-build.yml", package = "shiny2docker")
  dest_file <- file.path(tmp_dir, ".github", "workflows", "docker-build.yml")

  src_bytes <- readBin(source_file, what = "raw", n = file.info(source_file)$size)
  dst_bytes <- readBin(dest_file, what = "raw", n = file.info(dest_file)$size)

  expect_identical(src_bytes, dst_bytes)
})

test_that("set_github_action creates nested .github/workflows even when parent .github does not exist", {
  tmp_dir <- tempfile("s2d_gha_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  expect_false(dir.exists(file.path(tmp_dir, ".github")))

  result <- set_github_action(path = tmp_dir)

  expect_true(isTRUE(result))
  expect_true(dir.exists(file.path(tmp_dir, ".github", "workflows")))
})

test_that("set_github_action overwrites existing docker-build.yml on second call", {
  tmp_dir <- tempfile("s2d_gha_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  dest_dir <- file.path(tmp_dir, ".github", "workflows")
  dir.create(dest_dir, recursive = TRUE)
  dest_file <- file.path(dest_dir, "docker-build.yml")
  writeLines("placeholder content that should be overwritten", con = dest_file)

  result <- set_github_action(path = tmp_dir)

  expect_true(isTRUE(result))
  expect_false(any(grepl("placeholder content", readLines(dest_file))))
})

test_that("set_github_action errors when path missing and user declines", {
  testthat::with_mocked_bindings(
    yesno2 = function(...) {
      FALSE
    },
    .package = "yesno",
    code = {
      expect_error(
        set_github_action(),
        regexp = "Please provide a valid path"
      )
    }
  )
})

test_that("set_github_action uses here::here() when path missing and user accepts", {
  tmp_dir <- tempfile("s2d_gha_here_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  testthat::with_mocked_bindings(
    yesno2 = function(...) {
      TRUE
    },
    .package = "yesno",
    code = {
      testthat::with_mocked_bindings(
        here = function(...) {
          tmp_dir
        },
        .package = "here",
        code = {
          result <- set_github_action()
          expect_true(isTRUE(result))
          expect_true(file.exists(file.path(tmp_dir, ".github", "workflows", "docker-build.yml")))
        }
      )
    }
  )
})

test_that("set_github_action errors when docker-build.yml is missing from the package", {
  skip_if_not_installed("mockery")

  tmp_dir <- tempfile("s2d_gha_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  mockery::stub(
    where = set_github_action,
    what = "system.file",
    how = ""
  )

  expect_error(
    set_github_action(path = tmp_dir),
    regexp = "docker-build.yml file not found"
  )
})

test_that("set_github_action handles pre-existing workflows directory without error", {
  tmp_dir <- tempfile("s2d_gha_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  dir.create(file.path(tmp_dir, ".github", "workflows"), recursive = TRUE)

  result <- set_github_action(path = tmp_dir)

  expect_true(isTRUE(result))
  expect_true(file.exists(file.path(tmp_dir, ".github", "workflows", "docker-build.yml")))
})
