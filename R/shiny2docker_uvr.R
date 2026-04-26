#' shiny2docker_uvr
#'
#' Generate a Dockerfile for a Shiny application using
#' [uvr](https://github.com/nbafrank/uvr) instead of `renv`. The R version is
#' installed inside the container by `uvr` (no `rocker/r-ver` base image
#' required) and packages are restored from `uvr.lock` via `uvr sync`.
#'
#' Lifecycle: experimental. Requires the project to already be uvr-managed —
#' `uvr.toml`, `uvr.lock`, and `.r-version` must live at the root of `path`,
#' under those exact filenames (the generated Dockerfile copies them by name
#' from the build context, matching uvr's own convention).
#'
#' What `uvr_assert_state()` checks before generation: those three files exist,
#' `uvr.lock` is at least as recent as `uvr.toml` (mtime check), and
#' `.r-version` contains a single `MAJOR.MINOR.PATCH` line. It does **not**
#' parse `uvr.toml` to cross-validate the pinned R version against any
#' `[r] version` constraint — uvr itself owns that consistency contract.
#'
#' Platform constraints: the generated Dockerfile uses `apt-get` and Debian
#' package names, and downloads the `x86_64-unknown-linux-gnu` uvr binary, so
#' `base_image` must be a Debian/Ubuntu-derived image on amd64/glibc.
#'
#' @param path Character. Path to the folder containing the Shiny application
#'   *and* the uvr files (`uvr.toml`, `uvr.lock`, `.r-version`).
#' @param output Character. Path to the generated Dockerfile.
#' @param base_image Character. Docker base image. Defaults to `"debian:stable-slim"`.
#'   Must be a Debian/Ubuntu-based amd64 image (see "Platform constraints" above).
#' @param uvr_version Character. `"latest"` or a semver tag like `"v0.3.1"`.
#'   Pinning a tag is recommended for reproducible builds.
#' @param port Integer in `[1, 65535]`. Shiny port to expose. Default `3838`.
#' @param host Character. Shiny host. Default `"0.0.0.0"`. Single value, no
#'   shell metacharacters; validated before being interpolated into the image.
#' @param extra_sysreqs Character vector of extra debian package names to
#'   install before `uvr sync` (escape hatch for system dependencies that uvr
#'   does not detect on its own). Each entry must match
#'   `[A-Za-z0-9.+:-]+` to avoid shell injection.
#' @param frozen Logical. If `TRUE`, the generated Dockerfile runs
#'   `uvr sync --frozen` so the build fails when `uvr.lock` is out of date
#'   relative to `uvr.toml`. Default `FALSE` because uvr 0.2.15 rejects
#'   locks generated on a different host than the container's target OS;
#'   opt in once your setup supports it. When `FALSE`, an `cli` warning is
#'   emitted to make the relaxed strictness explicit.
#' @param write Logical. Whether to write the Dockerfile and `.dockerignore`
#'   to disk. When `FALSE`, the function only returns the in-memory Dockerfile
#'   object and does not touch the filesystem. Default `TRUE`. The parent
#'   directory of `output` is created if it does not already exist.
#'
#' @return Invisibly, an R6 `dockerfiler::Dockerfile` object that can be further
#'   customised before writing.
#'
#' @export
#'
#' @importFrom dockerfiler Dockerfile
shiny2docker_uvr <- function(path          = ".",
                             output        = file.path(path, "Dockerfile"),
                             base_image    = "debian:stable-slim",
                             uvr_version   = "latest",
                             port          = 3838,
                             host          = "0.0.0.0",
                             extra_sysreqs = NULL,
                             frozen        = FALSE,
                             write         = TRUE) {

  uvr_assert_state(
    uvr_toml       = file.path(path, "uvr.toml"),
    uvr_lock       = file.path(path, "uvr.lock"),
    r_version_file = file.path(path, ".r-version")
  )

  uvr_validate_host_port(host = host, port = port)
  uvr_validate_sysreqs(extra_sysreqs)

  if (!isTRUE(frozen)) {
    cli::cli_alert_warning(paste(
      "frozen = FALSE: the generated build runs `uvr sync` (no --frozen),",
      "so a stale uvr.lock will not block the image. Set frozen = TRUE",
      "once your environment supports it."
    ))
  }

  dock <- uvr_build_dockerfile(
    base_image    = base_image,
    uvr_version   = uvr_version,
    port          = port,
    host          = host,
    extra_sysreqs = extra_sysreqs,
    frozen        = frozen
  )

  if (isTRUE(write)) {
    out_dir <- dirname(output)
    if (!dir.exists(out_dir)) {
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    }
    dockerignore <- file.path(out_dir, ".dockerignore")
    if (!file.exists(dockerignore)) {
      create_dockerignore_uvr(path = dockerignore)
    }
    dock$write(output)
  }

  invisible(dock)
}
