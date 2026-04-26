#' Write a uvr-aware .dockerignore
#'
#' Adds the entries that are specific to a uvr-managed project (`.uvr/`,
#' `.Rprofile` written by `uvr init`, leftover `renv/` artefacts) on top of
#' the defaults used by the `renv` backend.
#'
#' @param path Path to the `.dockerignore` to write.
#' @noRd
create_dockerignore_uvr <- function(path = ".dockerignore") {
  entries <- c(
    ".Rhistory",
    ".git",
    ".gitignore",
    ".Rproj.user",
    "manifest.json",
    "rsconnect/",
    ".uvr/",
    ".Rprofile",
    "renv/",
    "renv.lock"
  )
  writeLines(entries, con = path)
}

#' Validate user-supplied host and port
#'
#' Both values are interpolated into shell commands inside the Dockerfile, so
#' we reject anything that could break the build or inject extra tokens.
#'
#' @param host Character of length 1.
#' @param port Numeric of length 1, integer in `[1, 65535]`.
#' @return Invisibly `TRUE` on success; raises an error otherwise.
#' @noRd
uvr_validate_host_port <- function(host, port) {
  if (!is.character(host) || length(host) != 1L || is.na(host) ||
      !grepl("^[A-Za-z0-9._-]+$", host)) {
    stop("`host` must be a single non-NA character matching ",
         "[A-Za-z0-9._-]+ (e.g. \"0.0.0.0\").", call. = FALSE)
  }
  if (!is.numeric(port) || length(port) != 1L || is.na(port) ||
      port != as.integer(port) || port < 1L || port > 65535L) {
    stop("`port` must be a single integer in [1, 65535].", call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate user-supplied extra system requirements
#'
#' Each entry is concatenated into an `apt-get install` command in the
#' Dockerfile. We restrict to a conservative Debian package-name pattern to
#' avoid shell injection.
#'
#' @param sysreqs `NULL` or a character vector.
#' @return Invisibly `TRUE` on success; raises an error otherwise.
#' @noRd
uvr_validate_sysreqs <- function(sysreqs) {
  if (is.null(sysreqs) || length(sysreqs) == 0L) return(invisible(TRUE))
  if (!is.character(sysreqs) || any(is.na(sysreqs))) {
    stop("`extra_sysreqs` must be a character vector with no NA.", call. = FALSE)
  }
  bad <- !grepl("^[A-Za-z0-9.+:-]+$", sysreqs)
  if (any(bad)) {
    stop("Invalid package name(s) in `extra_sysreqs`: ",
         paste(shQuote(sysreqs[bad]), collapse = ", "),
         ". Allowed characters: A-Z a-z 0-9 . + : -", call. = FALSE)
  }
  invisible(TRUE)
}

#' Bootstrap a uvr project layout if files are missing
#'
#' Mirrors what `shiny2docker()` does for `renv` (auto-creating `renv.lock` via
#' `attachment::create_renv_for_prod()`): if `uvr.toml`, `uvr.lock` or
#' `.r-version` are absent, generate them so the user does not have to learn
#' the uvr CLI before being able to call `shiny2docker_uvr()`.
#'
#' Strategy:
#'   1. If `uvr.toml` is missing, generate a `renv.lock` via `attachment` (or
#'      reuse an existing one), then `uvr import` it to produce `uvr.toml`.
#'   2. If `.r-version` is missing, pin it to the current R version.
#'   3. If `uvr.lock` is missing or older than `uvr.toml`, run `uvr lock`.
#'
#' Requires the `uvr` CLI on PATH; errors out with install instructions
#' otherwise. All `uvr` invocations run with `path` as the working directory.
#'
#' @param path Project root.
#' @param renv_lockfile Path to `renv.lock` to import from (created if missing).
#' @param document Passed to `attachment::create_renv_for_prod()`.
#' @param folder_to_exclude Passed to `attachment::create_renv_for_prod()`.
#'
#' @return Invisibly `TRUE`.
#' @noRd
uvr_bootstrap <- function(path,
                          renv_lockfile     = file.path(path, "renv.lock"),
                          document          = TRUE,
                          folder_to_exclude = c("renv", ".uvr")) {

  uvr_bin <- Sys.which("uvr")
  if (!nzchar(uvr_bin)) {
    stop(
      "`uvr` CLI not found on PATH; needed to bootstrap a uvr project.\n",
      "Install it once: ",
      "curl -fsSL https://raw.githubusercontent.com/nbafrank/uvr/main/install.sh | sh\n",
      "Or from R: install.packages(\"uvr\"); uvr::install_uvr()\n",
      "If you've already bootstrapped the project elsewhere, ",
      "make sure `uvr.toml`, `uvr.lock` and `.r-version` are at '", path, "/'.",
      call. = FALSE
    )
  }

  uvr_toml  <- file.path(path, "uvr.toml")
  uvr_lock  <- file.path(path, "uvr.lock")
  rver_file <- file.path(path, ".r-version")

  run_uvr <- function(args, label) {
    owd <- setwd(path); on.exit(setwd(owd), add = TRUE)
    rc <- suppressWarnings(system2(uvr_bin, args, stdout = TRUE, stderr = TRUE))
    setwd(owd); on.exit()
    status <- attr(rc, "status")
    if (!is.null(status) && status != 0L) {
      stop(label, " failed (exit ", status, "):\n",
           paste(rc, collapse = "\n"), call. = FALSE)
    }
    invisible(rc)
  }

  if (!file.exists(uvr_toml)) {
    cli::cli_alert_info("uvr.toml not found at {.path {uvr_toml}} -- bootstrapping.")

    if (!file.exists(renv_lockfile)) {
      cli::cli_alert_info(
        "Generating {.path renv.lock} via {.fn attachment::create_renv_for_prod} ..."
      )
      attachment::create_renv_for_prod(
        path              = path,
        output            = renv_lockfile,
        folder_to_exclude = folder_to_exclude,
        document          = document
      )
    }

    cli::cli_alert_info("Running {.code uvr init} ...")
    run_uvr(c("init", "--quiet", "."), "uvr init")

    cli::cli_alert_info(
      "Running {.code uvr import {basename(renv_lockfile)}} ..."
    )
    run_uvr(c("import", basename(renv_lockfile)), "uvr import")
  }

  if (!file.exists(rver_file)) {
    # R.version$minor packs MINOR.PATCH (e.g. "4.3" for R 4.4.3), so a simple
    # paste gives MAJOR.MINOR.PATCH directly.
    current_r <- paste(R.version$major, R.version$minor, sep = ".")
    cli::cli_alert_info(
      "Pinning R to current local version: {.val {current_r}} ..."
    )
    tryCatch(
      run_uvr(c("r", "pin", current_r), "uvr r pin"),
      error = function(e) {
        fallback <- "4.4.2"
        cli::cli_alert_warning(paste0(
          "Could not pin R ", current_r, " (", e$message,
          "). Falling back to ", fallback, "."
        ))
        run_uvr(c("r", "pin", fallback), "uvr r pin (fallback)")
      }
    )
  }

  if (!file.exists(uvr_lock) ||
      file.info(uvr_lock)$mtime < file.info(uvr_toml)$mtime) {
    cli::cli_alert_info("Running {.code uvr lock} ...")
    run_uvr(c("lock", "--quiet"), "uvr lock")
  }

  invisible(TRUE)
}

#' Assert that the project is uvr-ready
#'
#' Checks that `uvr.toml`, `uvr.lock` and a R version pin file all exist, and
#' that `uvr.lock` is at least as recent as `uvr.toml`. Stops with an actionable
#' message otherwise.
#'
#' @param uvr_toml Path to `uvr.toml`.
#' @param uvr_lock Path to `uvr.lock`.
#' @param r_version_file Path to `.r-version`.
#'
#' @return Invisibly `TRUE` on success.
#' @noRd
uvr_assert_state <- function(uvr_toml, uvr_lock, r_version_file) {

  if (!file.exists(uvr_toml)) {
    stop(
      "uvr.toml not found at '", uvr_toml, "'.\n",
      "Run `uvr init` (or `uvr import` from an existing renv.lock), then `uvr lock`.",
      call. = FALSE
    )
  }
  if (!file.exists(uvr_lock)) {
    stop(
      "uvr.lock not found at '", uvr_lock, "'.\n",
      "Run `uvr lock` to generate it.",
      call. = FALSE
    )
  }
  if (file.info(uvr_lock)$mtime < file.info(uvr_toml)$mtime) {
    stop(
      "uvr.lock is older than uvr.toml -- manifest changed since last lock.\n",
      "Run `uvr lock` to refresh it.",
      call. = FALSE
    )
  }
  if (!file.exists(r_version_file)) {
    stop(
      ".r-version not found at '", r_version_file, "'.\n",
      "Run `uvr r pin <version>` to pin the R version for the project.",
      call. = FALSE
    )
  }
  r_lines <- readLines(r_version_file, warn = FALSE)
  r_lines <- r_lines[nzchar(trimws(r_lines))]
  if (length(r_lines) != 1L ||
      !grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", trimws(r_lines))) {
    stop(
      ".r-version at '", r_version_file, "' must contain a single line ",
      "with a MAJOR.MINOR.PATCH version (e.g. \"4.4.2\"). Got: ",
      paste(shQuote(r_lines), collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Build the uvr release download URL
#'
#' @param uvr_version Either `"latest"` or a tag like `"v0.3.1"` / `"0.3.1"`.
#' @return A list with `url` and `arg_value`. `arg_value` is `NA` when
#'   `uvr_version = "latest"` (no `ARG UVR_VERSION` injected).
#' @noRd
uvr_release_url <- function(uvr_version = "latest") {
  asset <- "uvr-x86_64-unknown-linux-gnu.tar.gz"
  base  <- "https://github.com/nbafrank/uvr/releases"

  if (identical(uvr_version, "latest")) {
    return(list(
      url       = sprintf("%s/latest/download/%s", base, asset),
      arg_value = NA_character_
    ))
  }

  tag <- if (startsWith(uvr_version, "v")) uvr_version else paste0("v", uvr_version)
  if (!grepl("^v[0-9]+\\.[0-9]+\\.[0-9]+$", tag)) {
    stop(
      "uvr_version must be 'latest' or a semver tag like 'v0.3.1' / '0.3.1'. ",
      "Got: '", uvr_version, "'",
      call. = FALSE
    )
  }
  list(
    url       = sprintf("%s/download/%s/%s", base, tag, asset),
    arg_value = tag
  )
}

#' Build the Dockerfile object for the uvr backend
#'
#' @param base_image Base OS image (e.g. `"debian:stable-slim"`).
#' @param uvr_version `"latest"` or a tag (`"v0.3.1"`).
#' @param port Shiny port.
#' @param host Shiny host.
#' @param extra_sysreqs Optional character vector of extra debian packages to
#'   `apt-get install` before `uvr sync`.
#'
#' @return An R6 `dockerfiler::Dockerfile` object.
#' @noRd
uvr_build_dockerfile <- function(base_image    = "debian:stable-slim",
                                 uvr_version   = "latest",
                                 port          = 3838,
                                 host          = "0.0.0.0",
                                 extra_sysreqs = NULL,
                                 frozen        = FALSE) {

  release <- uvr_release_url(uvr_version)

  dock <- dockerfiler::Dockerfile$new(FROM = base_image)

  dock$ENV("DEBIAN_FRONTEND", "noninteractive")
  dock$ENV("LANG",   "en_US.UTF-8")
  dock$ENV("LC_ALL", "en_US.UTF-8")

  dock$RUN(paste(
    "apt-get update && apt-get install -y --no-install-recommends",
    # base tooling
    "ca-certificates curl locales tzdata",
    # binutils provides `ar`, used by `uvr r install` to extract the Posit .deb
    "binutils",
    # runtime + build deps required by Posit's R .deb
    "g++ gcc gfortran make zip unzip ucf",
    "libbz2-dev libc6 libcairo2 libcurl4-openssl-dev libdeflate-dev",
    "libglib2.0-0 libgomp1 libicu-dev liblzma-dev libopenblas-dev",
    "libpango-1.0-0 libpangocairo-1.0-0 libpaper-utils libpcre2-dev",
    "libpng16-16 libreadline8 libtcl8.6 libtiff6 libtirpc-dev libtk8.6",
    "libx11-6 libxt6 zlib1g-dev",
    # extra deps commonly needed when uvr falls back to source compilation
    # (P3M binaries are not always available on debian targets as of uvr 0.2.15)
    "libuv1-dev libxml2-dev libssl-dev libsodium-dev",
    "&& sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen && locale-gen",
    "&& rm -rf /var/lib/apt/lists/*"
  ))

  if (!is.na(release$arg_value)) {
    dock$ARG(paste0("UVR_VERSION=", release$arg_value))
  }

  dock$RUN(paste0(
    "curl -fsSL ", release$url,
    " | tar xz -C /usr/local/bin uvr && uvr --version"
  ))

  dock$WORKDIR("/srv/shiny-server")
  dock$COPY(from = ".r-version", to = "./")
  dock$COPY(from = "uvr.toml",   to = "./")
  dock$COPY(from = "uvr.lock",   to = "./")

  # Workaround for nbafrank/uvr <= 0.2.15: `uvr r install` writes
  # `etc/Renviron.site` directly under <r-versions>/<ver>/ but fails because
  # that `etc/` dir doesn't exist (Posit's .deb places etc under lib/R/).
  # Pre-creating the dir lets the install complete. Track upstream and drop
  # this once fixed.
  dock$RUN(paste(
    "mkdir -p \"/root/.uvr/r-versions/$(cat .r-version)/etc\"",
    "&& uvr r install \"$(cat .r-version)\""
  ))

  if (length(extra_sysreqs) > 0) {
    dock$RUN(paste(
      "apt-get update && apt-get install -y --no-install-recommends",
      paste(extra_sysreqs, collapse = " "),
      "&& rm -rf /var/lib/apt/lists/*"
    ))
  }

  # `--frozen` is what we want in CI (lock = source of truth), but uvr 0.2.15
  # rejects locks generated on a different host than the container's target OS
  # (e.g. host-side P3M URL vs CRAN source URL inside the container). Default
  # is FALSE to keep the build green; opt in once your environment supports it.
  sync_cmd <- if (isTRUE(frozen)) "uvr sync --frozen" else "uvr sync"
  dock$RUN(paste("apt-get update &&", sync_cmd, "&& rm -rf /var/lib/apt/lists/*"))

  dock$COPY(from = ".", to = "/srv/shiny-server/")

  # `uvr run` takes a script, not arbitrary R args, so embed the launch as a
  # tiny R file written into the image at build time. host/port are validated
  # by the public entry point; we still escape them defensively for the shell
  # and the R source.
  port_int   <- as.integer(port)
  r_call     <- sprintf(
    "shiny::runApp(appDir = '/srv/shiny-server', host = %s, port = %d)",
    encodeString(host, quote = "\""), port_int
  )
  dock$RUN(sprintf(
    "printf '%%s\\n' %s > /srv/shiny-server/_uvr_start.R",
    shQuote(r_call)
  ))

  dock$EXPOSE(port)

  dock$CMD("uvr run /srv/shiny-server/_uvr_start.R")

  dock
}
