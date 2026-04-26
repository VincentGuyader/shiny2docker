#' shiny2docker_uvr
#'
#' Generate a Dockerfile for a Shiny application using
#' [uvr](https://github.com/nbafrank/uvr) instead of `renv`. The R version is
#' installed inside the container by `uvr` (no `rocker/r-ver` base image
#' required) and packages are restored from `uvr.lock` via `uvr sync --frozen`.
#'
#' Lifecycle: experimental. Requires the project to already be uvr-managed
#' (`uvr.toml`, `uvr.lock`, and `.r-version` present at the project root).
#'
#' @param path Character. Path to the folder containing the Shiny application.
#' @param output Character. Path to the generated Dockerfile.
#' @param uvr_toml Path to the `uvr.toml` manifest. Defaults to `<path>/uvr.toml`.
#' @param uvr_lock Path to the `uvr.lock` lockfile. Defaults to `<path>/uvr.lock`.
#' @param r_version_file Path to the R version pin. Defaults to `<path>/.r-version`.
#' @param base_image Character. Docker base image. Defaults to `"debian:stable-slim"`.
#' @param uvr_version Character. `"latest"` or a semver tag like `"v0.3.1"`.
#'   Pinning a tag is recommended for reproducible builds.
#' @param port Integer. Shiny port to expose. Default `3838`.
#' @param host Character. Shiny host. Default `"0.0.0.0"`.
#' @param extra_sysreqs Character vector of extra debian packages to install
#'   before `uvr sync` (escape hatch for system dependencies that uvr does not
#'   detect on its own).
#' @param write Logical. Whether to write the Dockerfile to `output`. Default `TRUE`.
#'
#' @return Invisibly, an R6 `dockerfiler::Dockerfile` object that can be further
#'   customised before writing.
#'
#' @export
#'
#' @importFrom dockerfiler Dockerfile
shiny2docker_uvr <- function(path           = ".",
                             output         = file.path(path, "Dockerfile"),
                             uvr_toml       = file.path(path, "uvr.toml"),
                             uvr_lock       = file.path(path, "uvr.lock"),
                             r_version_file = file.path(path, ".r-version"),
                             base_image     = "debian:stable-slim",
                             uvr_version    = "latest",
                             port           = 3838,
                             host           = "0.0.0.0",
                             extra_sysreqs  = NULL,
                             write          = TRUE) {

  uvr_assert_state(
    uvr_toml       = uvr_toml,
    uvr_lock       = uvr_lock,
    r_version_file = r_version_file
  )

  if (!file.exists(file.path(dirname(output), ".dockerignore"))) {
    create_dockerignore_uvr(path = file.path(dirname(output), ".dockerignore"))
  }

  dock <- uvr_build_dockerfile(
    base_image    = base_image,
    uvr_version   = uvr_version,
    port          = port,
    host          = host,
    extra_sysreqs = extra_sysreqs
  )

  if (isTRUE(write)) {
    dock$write(output)
  }

  invisible(dock)
}
