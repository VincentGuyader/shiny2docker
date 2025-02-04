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
#' set_gitlab_ci()
set_gitlab_ci <- function(path = '.') {
  file.copy(
    from = system.file("gitlab-ci.yml", package = "shiny2docker"),
    to = file.path(path, ".gitlab-ci.yml")
  )
}
