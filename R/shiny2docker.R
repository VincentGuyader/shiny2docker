#' shiny2docker
#'
#' Generate a Dockerfile for a Shiny Application
#'
#' Automate the creation of a Dockerfile tailored for deploying Shiny applications. It manages R dependencies using `renv`, generates a `.dockerignore` file to optimize the Docker build process, and leverages the `dockerfiler` package to allow further customization of the Dockerfile object before writing it to disk.
#'
#' @param path Character. Path to the folder containing the Shiny application (e.g., `app.R` or `ui.R` and `server.R`) along with any other necessary files.
#' @param lockfile Character. Path to the `renv.lock` file that specifies the R package dependencies. If the `renv.lock` file does not exist, it will be created for production using the `attachment::create_renv_for_prod` function.
#' @param output Character. Path to the generated Dockerfile. Defaults to `"Dockerfile"`.
#' @param FROM Docker image to start FROM Default is FROM rocker/r-base
#' @param AS The AS of the Dockerfile. Default it `NULL`.
#' @param sysreqs boolean. If `TRUE`, the Dockerfile will contain sysreq installation.
#' @param expand boolean. If `TRUE` each system requirement will have its own `RUN` line.
#' @param repos character. The URL(s) of the repositories to use for `options("repos")`.
#' @param extra_sysreqs character vector. Extra debian system requirements.
#'    Will be installed with apt-get install.
#' @param use_pak boolean. If `TRUE` use pak to deal with dependencies  during `renv::restore()`. FALSE by default
#' @param user Name of the user to specify in the Dockerfile with the USER instruction. Default is `NULL`, in which case the user from the FROM image is used.
#' @param dependencies What kinds of dependencies to install. Most commonly
#'   one of the following values:
#'   - `NA`: only required (hard) dependencies,
#'   - `TRUE`: required dependencies plus optional and development
#'     dependencies,
#'   - `FALSE`: do not install any dependencies. (You might end up with a
#'     non-working package, and/or the installation might fail.)
#' @param sysreqs_platform System requirements platform.`ubuntu` by default. If `NULL`, then the  current platform is used. Can be : "ubuntu-22.04" if needed to fit with the `FROM` Operating System. Only debian or ubuntu based images are supported
#' @param folder_to_exclude Folder to exclude during scan to detect packages
#'
#' @return An object of class `dockerfiler`, representing the generated Dockerfile. This object can be further manipulated using `dockerfiler` functions before being written to disk.
#'
#' @export
#'
#' @importFrom attachment create_renv_for_prod
#' @importFrom dockerfiler dock_from_renv
#' @importFrom yesno yesno2
#' @importFrom here here
#'
#' @examples
#' \donttest{
#'   temp_dir <- tempfile("shiny2docker_example_")
#'   dir.create(temp_dir)
#'   example_app <- system.file("dummy_app", package = "shiny2docker")
#'   file.copy(example_app, temp_dir, recursive = TRUE)
#'
#'   app_path <- file.path(temp_dir, "dummy_app")
#'   if (requireNamespace("rstudioapi", quietly = TRUE) &&
#'   rstudioapi::isAvailable()) {
#'     rstudioapi::filesPaneNavigate(app_path)
#'   }
#'
#'   docker_obj <- shiny2docker::shiny2docker(path = app_path)
#'
#'   print(list.files(app_path,all.files = TRUE,no.. = TRUE))
#'
#'   # Further manipulate the Dockerfile object
#'  docker_obj$add_after(
#'    cmd = "ENV ENV \'MY_ENV_VAR\'=\'value\'",
#'    after = 3
#'  )
#'  docker_obj$write(file.path(app_path, "Dockerfile"))
#' }
shiny2docker <- function(path = ".",
                         lockfile = file.path(path, "renv.lock"),
                         output = file.path(path, "Dockerfile"),
                         FROM = "rocker/geospatial",
                         AS = NULL,
                         sysreqs = TRUE,
                         repos = c(CRAN = "https://cran.rstudio.com/"),
                         expand = FALSE,
                         extra_sysreqs = NULL,
                         use_pak = FALSE,
                         user = NULL,
                         dependencies = NA,
                         sysreqs_platform = "ubuntu",
                         folder_to_exclude = c("renv")) {

  if (missing(path)) {
    if (yesno::yesno2("path is missing. Do you want to use the current directory?")) {
      path <- here::here()
    } else {
      stop("Please supply a valid path.")
    }
  }

  if (!file.exists(lockfile)) {
    attachment::create_renv_for_prod(path = path, output = lockfile,folder_to_exclude = folder_to_exclude,document = TRUE)

  }
  if (!file.exists(file.path(dirname(output), ".dockerignore"))) {
    create_dockerignore(path = file.path(dirname(output), ".dockerignore"))
  }

  dock <- dockerfiler::dock_from_renv(
    lockfile = lockfile,

    FROM = FROM,
    AS = AS,
    sysreqs = sysreqs,
    repos = repos,
    expand = expand,
    extra_sysreqs = extra_sysreqs,
    use_pak = use_pak,
    user = user,
    dependencies = dependencies,
    sysreqs_platform = sysreqs_platform


  )
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
