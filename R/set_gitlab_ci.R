#' Configure GitLab CI pipeline for Docker builds
#'
#' Copies the `.gitlab-ci.yml` file provided by the `shiny2docker` package
#' into the specified directory. The GitLab CI configuration is designed to build a Docker image
#' and push the created image to the GitLab container registry.
#'
#' @param path A character string specifying the directory where the
#' `.gitlab-ci.yml` file will be copied. If missing, the user will be prompted to use
#' the current directory.
#'
#' @return A logical value indicating whether the file was successfully copied (`TRUE`)
#' or not (`FALSE`).
#' @export
#' @importFrom cli cli_alert_info cli_alert_danger cli_alert_success
#' @importFrom yesno yesno2
#' @examples
#' # Copy the .gitlab-ci.yml file to a temporary directory
#' set_gitlab_ci(path = tempdir())
set_gitlab_ci <- function(path) {

  # Check if the 'path' parameter is provided
  if (missing(path)) {
    cli::cli_alert_info("No path provided.")
    if (yesno::yesno2("The 'path' parameter is missing. Do you want to use the current directory?")) {
      path <- here::here()
      cli::cli_alert_info("Using current directory: {path}")
    } else {
      stop("Please provide a valid path.")
    }
  }

  cli::cli_alert_info("Copying .gitlab-ci.yml file to: {path}")

  # Retrieve the source file from the shiny2docker package
  source_file <- system.file("gitlab-ci.yml", package = "shiny2docker")
  if (source_file == "") {
    cli::cli_alert_danger("The gitlab-ci.yml file was not found in the shiny2docker package.")
    stop("gitlab-ci.yml file not found in the shiny2docker package.")
  }
  cli::cli_alert_info("Found source file at: {source_file}")

  # Copy the gitlab-ci.yml file to the destination directory
  success <- file.copy(
    from = source_file,
    to = file.path(path, ".gitlab-ci.yml"),
    overwrite = TRUE
  )

  if (isTRUE(success)) {
    cli::cli_alert_success(".gitlab-ci.yml file successfully copied to {path}")
  } else {
    cli::cli_alert_danger("Failed to copy .gitlab-ci.yml file to {path}")
  }

  return(success)
}
