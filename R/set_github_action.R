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

  # Define the destination folder (.github/workflows) inside the provided base directory
  dest_path <- file.path(path, ".github", "workflows")
  cli::cli_alert_info("Creating destination directory: {dest_path}")

  # Create the destination directory if it doesn't exist
  if (!dir.exists(dest_path)) {
    dir.create(dest_path, recursive = TRUE, showWarnings = FALSE)
    cli::cli_alert_success("Directory created: {dest_path}")
  } else {
    cli::cli_alert_info("Directory already exists: {dest_path}")
  }

  # Retrieve the source file from the shiny2docker package
  source_file <- system.file("docker-build.yml", package = "shiny2docker")
  if (source_file == "") {
    cli::cli_alert_danger("The docker-build.yml file was not found in the shiny2docker package.")
    stop("docker-build.yml file not found in the shiny2docker package.")
  }
  cli::cli_alert_info("Copying file from: {source_file}")

  # Copy the docker-build.yml file to the destination directory
  success <- file.copy(
    from = source_file,
    to = file.path(dest_path, "docker-build.yml"),
    overwrite = TRUE
  )

  if (isTRUE(success)) {
    cli::cli_alert_success("File docker-build.yml copied successfully to {dest_path}")
  } else {
    cli::cli_alert_danger("Failed to copy docker-build.yml to {dest_path}")
  }

  return(success)
}


