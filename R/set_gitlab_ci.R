#' Configure GitLab CI pipeline for Docker builds
#'
#' Copies the `.gitlab-ci.yml` file provided by the `shiny2docker` package
#' into the specified directory. The GitLab CI configuration is designed to build a Docker image
#' and push the created image to the GitLab container registry.
#'
#' @param path A character string specifying the directory where the
#'   `.gitlab-ci.yml` file will be copied. If missing, the user will be prompted to use
#'   the current directory.
#' @param tags Optional character vector of GitLab runner tags. If provided, the
#'   function will add these tags to the generated CI job so the appropriate
#'   runner is selected. You can provide multiple tags.
#'
#' @return A logical value indicating whether the file was successfully copied (`TRUE`)
#' or not (`FALSE`).
#' @export
#' @importFrom cli cli_alert_info cli_alert_danger cli_alert_success
#' @importFrom yesno yesno2
#' @examples
#' # Copy the .gitlab-ci.yml file to a temporary directory
#' set_gitlab_ci(path = tempdir())
#'
#' # Copy the file and specify runner tags
#' set_gitlab_ci(path = tempdir(), tags = c("shiny_build", "prod"))
set_gitlab_ci <- function(path, tags = NULL) {

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

  # Create the destination directory if it doesn't exist
  if (!dir.exists(path)) {
    success <- dir.create(path, recursive = TRUE, showWarnings = FALSE)
    if (!isTRUE(success)) {
      cli::cli_alert_danger("Failed to create directory: {path}")
      stop("Directory creation failed. Please check the path and permissions.")
    }
    cli::cli_alert_success("Directory created: {path}")
  } 

  cli::cli_alert_info("Copying .gitlab-ci.yml file to: {path}")

  # Retrieve the source file from the shiny2docker package
  source_file <- system.file("gitlab-ci.yml", package = "shiny2docker")
  if (source_file == "") {
    cli::cli_alert_danger("The gitlab-ci.yml file was not found in the shiny2docker package.")
    stop("gitlab-ci.yml file not found in the shiny2docker package.")
  }
  cli::cli_alert_info("Found source file at: {source_file}")

  # Path to destination file
  dest_file <- file.path(path, ".gitlab-ci.yml")

  # Copy the gitlab-ci.yml file to the destination directory
  success <- file.copy(
    from = source_file,
    to = dest_file,
    overwrite = TRUE
  )

  # If copy succeeded and tags supplied, add them to the job
  if (isTRUE(success) && !is.null(tags)) {
    cli::cli_alert_info("Adding runner tags to .gitlab-ci.yml: {paste(tags, collapse = ', ')}")
    yaml_lines <- readLines(dest_file)
    stage_line <- grep("^\\s*stage:", yaml_lines)[1]
    if (length(stage_line) == 1 && !is.na(stage_line)) {
      tag_lines <- c("  tags:", paste0("    - ", tags))
      yaml_lines <- append(yaml_lines, tag_lines, after = stage_line)
      writeLines(yaml_lines, dest_file)
    } else {
      cli::cli_alert_danger("Unable to locate stage line in .gitlab-ci.yml for tag insertion")
    }
  }

  if (isTRUE(success)) {
    cli::cli_alert_success(".gitlab-ci.yml file successfully copied to {path}")
  } else {
    cli::cli_alert_danger("Failed to copy .gitlab-ci.yml file to {path}")
  }

  return(success)
}
