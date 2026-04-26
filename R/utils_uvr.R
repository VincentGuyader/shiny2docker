#' Write a uvr-aware .dockerignore
#'
#' Adds the entries that are specific to a uvr-managed project (`.uvr/`,
#' `.Rprofile` written by `uvr init`) on top of the defaults used by the
#' `renv` backend.
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
    "renv/",
    "renv.lock"
  )
  writeLines(entries, con = path)
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
      "uvr.lock is older than uvr.toml — manifest changed since last lock.\n",
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
  if (!grepl("^v[0-9]+\\.[0-9]+\\.[0-9]+", tag)) {
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
                                 extra_sysreqs = NULL) {

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

  # Note: ideally `uvr sync --frozen` for CI strictness, but as of uvr 0.2.15
  # the frozen check rejects locks generated on a different host than the
  # container's target OS (e.g. host-side P3M URL vs CRAN source URL). Track
  # upstream and switch back to --frozen once that's resolved.
  dock$RUN("apt-get update && uvr sync && rm -rf /var/lib/apt/lists/*")

  dock$COPY(from = ".", to = "/srv/shiny-server/")

  # `uvr run` takes a script, not arbitrary R args, so embed the launch as a
  # tiny R file written into the image at build time.
  dock$RUN(sprintf(
    "printf '%%s\\n' \"shiny::runApp(appDir = '/srv/shiny-server', host = '%s', port = %s)\" > /srv/shiny-server/_uvr_start.R",
    host, port
  ))

  dock$EXPOSE(port)

  dock$CMD("uvr run /srv/shiny-server/_uvr_start.R")

  dock
}
