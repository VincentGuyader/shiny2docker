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
