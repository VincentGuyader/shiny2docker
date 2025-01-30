#' shiny2docker
#'
#' Generate a Dockerfile for a Shiny Application
#'
#' Automate the creation of a Dockerfile tailored for deploying Shiny applications. It manages R dependencies using `renv`, generates a `.dockerignore` file to optimize the Docker build process, and leverages the `dockerfiler` package to allow further customization of the Dockerfile object before writing it to disk.
#'
#' @param path Character. Path to the folder containing the Shiny application (e.g., `app.R` or `ui.R` and `server.R`) along with any other necessary files.
#' @param lockfile Character. Path to the `renv.lock` file that specifies the R package dependencies. If the `renv.lock` file does not exist, it will be created for production using the `attachment::create_renv_for_prod` function.
#' @param output Character. Path to the generated Dockerfile. Defaults to `"Dockerfile"`.
#'
#' @return An object of class `dockerfiler`, representing the generated Dockerfile. This object can be further manipulated using `dockerfiler` functions before being written to disk.
#'
#' @export
#'
#' @importFrom attachment create_renv_for_prod
#' @importFrom dockerfiler dock_from_renv
#'
#' @examples
#' \dontrun{
#'   # Generate Dockerfile in the current directory
#'   shiny2docker(path = ".")
#'
#'   # Generate Dockerfile with a specific renv.lock and output path
#'   shiny2docker(path = "path/to/shiny/app",
#'               lockfile = "path/to/shiny/app/renv.lock",
#'               output = "path/to/shiny/app/Dockerfile")
#'
#'   # Further manipulate the Dockerfile object
#'   docker_obj <- shiny2docker()
#'   docker_obj$ENV("MY_ENV_VAR", "value")
#'   docker_obj$write("Dockerfile")
#' }
shiny2docker <- function(path = ".",
                         lockfile = "renv.lock",
                         output = "Dockerfile") {
  if (!file.exists(lockfile)) {
    attachment::create_renv_for_prod(path = path, output = lockfile)

  }
  if (!file.exists(".dockerignore")) {
    create_dockerignore(path = ".dockerignore")
  }

  dock <- dockerfiler::dock_from_renv(lockfile = lockfile)
  dock$WORKDIR("/srv/shiny-server/")
  dock$COPY(from = ".", to = "/srv/shiny-server/")
  dock$EXPOSE(3838)
  dock$CMD("R -e 'shiny::runApp(\"/srv/shiny-server\",host=\"0.0.0.0\",port=3838)'")
  dock$write(output)
  invisible(dock)
}


create_dockerignore <- function(path = ".dockerignore") {
  dockerignore_content <- c(".Rhistory",
                            ".git",
                            ".gitignore",
                            "manifest.json",
                            "rsconnect/",
                            ".Rproj.user")

  writeLines(dockerignore_content, con = path)

}
