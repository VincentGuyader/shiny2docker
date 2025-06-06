library(testthat)

# Create temp directory for testing
tmp_dir <- tempdir(check = TRUE)

test_that("set_gitlab_ci inserts multiple tags", {
  file.remove(file.path(tmp_dir, ".gitlab-ci.yml"))
  set_gitlab_ci(path = tmp_dir, tags = c("shiny_build", "prod"))
  expect_true(file.exists(file.path(tmp_dir, ".gitlab-ci.yml")))
  ci_lines <- readLines(file.path(tmp_dir, ".gitlab-ci.yml"))
  expect_true(any(grepl("^\s*tags:\s*$", ci_lines)))
  expect_true(any(grepl("shiny_build", ci_lines)))
  expect_true(any(grepl("prod", ci_lines)))
  file.remove(file.path(tmp_dir, ".gitlab-ci.yml"))
})
