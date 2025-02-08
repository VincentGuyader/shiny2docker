#' Configure GitHub Action pipeline for Docker builds
#'
#' Copies the \code{docker-build.yml} file provided by the \code{shiny2docker} package
#' into the \code{.github/workflows/} directory within the specified base directory.
#' This GitHub Action configuration is designed to build a Docker image and push the
#' created image to the GitHub Container Registry.
#'
#' @param path A character string specifying the base directory where the
#' \code{.github/workflows/} folder will be created and the \code{docker-build.yml}
#' file copied. If missing, the user will be prompted to use the current directory.
#'
#' @return A logical value indicating whether the file was successfully copied
#' (\code{TRUE}) or not (\code{FALSE}).
#' @export
#'
#' @examples
#' # Copy the docker-build.yml file to the .github/workflows/ directory in a temporary folder
#' set_github_action(path = tempdir())
set_github_action <- function(path) {

  if (missing(path)) {
    if (yesno::yesno2("path is missing. Do you want to use the current directory?")) {
      path <- here::here()
    } else {
      stop("Please supply a valid path.")
    }
  }
  path <- file.path(path,".github/workflows/")

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  file.copy(
    from = system.file("docker-build.yml", package = "shiny2docker"),
    to = file.path(path, "docker-build.yml")
  )
}

