#' Configure GitLab CI pipeline for Docker builds
#'
#' Set the \code{gitlab-ci.yml} file provided by the
#' \code{shiny2docker} package to the specified directory. The GitLab CI configuration
#' is designed to build a Docker image and push the created image to the GitLab container registry.
#'
#' @param path A character string specifying the path to the directory where
#' the \code{.gitlab-ci.yml} file will be copied. Defaults to the current directory ('.').
#'
#' @return A logical value indicating whether the file was successfully copied (\code{TRUE}) or not (\code{FALSE}).
#' @export
#'
#' @examples
#' # Copy the .gitlab-ci.yml file to the current directory
#' set_gitlab_ci(path=tempdir())
set_gitlab_ci <- function(path) {

  if (missing(path)) {
    if (yesno::yesno2("path is missing. Do you want to use the current directory?")) {
      path <- here::here()
    } else {
      stop("Please supply a valid path.")
    }
  }

  file.copy(
    from = system.file("gitlab-ci.yml", package = "shiny2docker"),
    to = file.path(path, ".gitlab-ci.yml")
  )
}
