library(testthat)

# Create temp directory for testing
tmp_dir <- tempfile()

test_that("set_gitlab_ci inserts multiple tags", {
  set_gitlab_ci(path = tmp_dir, tags = c("shiny_build", "prod"))
  expect_true(file.exists(file.path(tmp_dir, ".gitlab-ci.yml")))
  ci_lines <- readLines(file.path(tmp_dir, ".gitlab-ci.yml"))
  expect_true(any(grepl("^\\s*tags:\\s*$", ci_lines)))
  expect_true(any(grepl("^\\s*tags:\\s*$", ci_lines)))
  expect_true(any(grepl("shiny_build", ci_lines)))
  expect_true(any(grepl("prod", ci_lines)))
  file.remove(file.path(tmp_dir, ".gitlab-ci.yml"))
})

test_that("set_gitlab_ci copies the file without tags when none supplied", {
  d <- tempfile("s2d_glci_")
  on.exit(unlink(d, recursive = TRUE, force = TRUE), add = TRUE)

  result <- set_gitlab_ci(path = d)

  expect_true(isTRUE(result))
  expect_true(file.exists(file.path(d, ".gitlab-ci.yml")))
  ci_lines <- readLines(file.path(d, ".gitlab-ci.yml"))
  expect_false(any(grepl("^\\s*tags:\\s*$", ci_lines)))
})

test_that("set_gitlab_ci errors when path missing and user declines", {
  testthat::with_mocked_bindings(
    yesno2 = function(...) {
      FALSE
    },
    .package = "yesno",
    code = {
      expect_error(
        set_gitlab_ci(),
        regexp = "Please provide a valid path"
      )
    }
  )
})

test_that("set_gitlab_ci uses here::here() when path missing and user accepts", {
  d <- tempfile("s2d_glci_here_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE, force = TRUE), add = TRUE)

  testthat::with_mocked_bindings(
    yesno2 = function(...) {
      TRUE
    },
    .package = "yesno",
    code = {
      testthat::with_mocked_bindings(
        here = function(...) {
          d
        },
        .package = "here",
        code = {
          result <- set_gitlab_ci()
          expect_true(isTRUE(result))
          expect_true(file.exists(file.path(d, ".gitlab-ci.yml")))
        }
      )
    }
  )
})

test_that("set_gitlab_ci errors when gitlab-ci.yml is missing from the package", {
  skip_if_not_installed("mockery")

  d <- tempfile("s2d_glci_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE, force = TRUE), add = TRUE)

  mockery::stub(
    where = set_gitlab_ci,
    what = "system.file",
    how = ""
  )

  expect_error(
    set_gitlab_ci(path = d),
    regexp = "gitlab-ci.yml file not found"
  )
})

test_that("set_gitlab_ci returns FALSE when source YAML has no stage: line for tag insertion", {
  skip_if_not_installed("mockery")

  d <- tempfile("s2d_glci_nostage_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE, force = TRUE), add = TRUE)

  fake_yaml <- tempfile(fileext = ".yml")
  on.exit(unlink(fake_yaml, force = TRUE), add = TRUE)
  writeLines(c("build:", "  script:", "    - echo hi"), con = fake_yaml)

  mockery::stub(
    where = set_gitlab_ci,
    what = "system.file",
    how = fake_yaml
  )

  expect_message(
    result <- set_gitlab_ci(path = d, tags = c("runner1")),
    regexp = "Unable to locate stage line"
  )
  expect_false(isTRUE(result))
})

test_that("set_gitlab_ci errors when directory creation fails", {
  skip_if_not_installed("mockery")

  d <- tempfile("s2d_glci_dirfail_")

  mockery::stub(
    where = set_gitlab_ci,
    what = "dir.create",
    how = FALSE
  )

  expect_error(
    set_gitlab_ci(path = d),
    regexp = "Directory creation failed"
  )
})
