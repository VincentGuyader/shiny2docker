test_that("shiny2docker works", {
unlink("dummy_app/renv.lock",force = TRUE)
unlink("dummy_app/Dockerfile",force = TRUE)
unlink("dummy_app/.dockerignore",force = TRUE)

# if on cran, use renv.cran.lock
if (isTRUE(testthat:::on_cran())){
  file.copy(from = "dummy_app/renv.lock.cran.lock",
            to = "dummy_app/renv.lock")
}

 out <-  shiny2docker(path = "dummy_app/")

expect_true(file.exists("dummy_app/renv.lock"))
expect_true(file.exists("dummy_app/Dockerfile"))
expect_true(file.exists("dummy_app/.dockerignore"))
testthat::expect_s3_class(out,"Dockerfile")
testthat::expect_s3_class(out,"R6")
unlink("dummy_app/renv.lock",force = TRUE)
unlink("dummy_app/Dockerfile",force = TRUE)
unlink("dummy_app/.dockerignore",force = TRUE)
})

test_that("shiny2docker forwards renv_version to dock_from_renv", {
  unlink("dummy_app/renv.lock", force = TRUE)
  unlink("dummy_app/Dockerfile", force = TRUE)
  unlink("dummy_app/.dockerignore", force = TRUE)

  if (isTRUE(testthat:::on_cran())) {
    file.copy(from = "dummy_app/renv.lock.cran.lock",
              to = "dummy_app/renv.lock")
  }

  # When renv_version is forwarded as NULL, dock_from_renv() takes the
  # "latest renv" branch and must NOT use remotes::install_version (which
  # is the default branch when renv_version is missing). The exact install
  # line differs across dockerfiler versions, but the absence of
  # `install_version` is invariant.
  out <- shiny2docker(path = "dummy_app/", renv_version = NULL)
  expect_false(any(grepl("install_version", out$Dockerfile)))

  unlink("dummy_app/renv.lock", force = TRUE)
  unlink("dummy_app/Dockerfile", force = TRUE)
  unlink("dummy_app/.dockerignore", force = TRUE)
})

test_that("shiny2docker forwards an explicit renv_version to dock_from_renv", {
  unlink("dummy_app/renv.lock", force = TRUE)
  unlink("dummy_app/Dockerfile", force = TRUE)
  unlink("dummy_app/.dockerignore", force = TRUE)

  if (isTRUE(testthat:::on_cran())) {
    file.copy(from = "dummy_app/renv.lock.cran.lock",
              to = "dummy_app/renv.lock")
  }

  # An explicit version string must reach dock_from_renv() and produce a
  # remotes::install_version("renv", version = "1.0.3") line.
  out <- shiny2docker(path = "dummy_app/", renv_version = "1.0.3")
  expect_true(
    any(grepl("install_version.*renv.*1\\.0\\.3", out$Dockerfile))
  )

  unlink("dummy_app/renv.lock", force = TRUE)
  unlink("dummy_app/Dockerfile", force = TRUE)
  unlink("dummy_app/.dockerignore", force = TRUE)
})
