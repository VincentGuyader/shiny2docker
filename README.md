
<!-- README.md is generated from README.Rmd. Please edit that file -->

# shiny2docker

<!-- badges: start -->

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![R-CMD-check](https://github.com/VincentGuyader/shiny2docker/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/VincentGuyader/shiny2docker/actions/workflows/R-CMD-check.yaml)
[![CRAN
status](https://www.r-pkg.org/badges/version/shiny2docker)](https://CRAN.R-project.org/package=shiny2docker)
<!-- badges: end -->

`shiny2docker` is an R package designed to streamline the process of
containerizing Shiny applications using Docker. By automating the
generation of essential Docker files and managing R dependencies with
`renv`, `shiny2docker` simplifies the deployment of Shiny apps, ensuring
reproducibility and consistency across different environments.

## Features

- **Automated Dockerfile Generation**:  
  Quickly generate Dockerfiles tailored for Shiny applications. The main
  function, `shiny2docker()`, creates a Dockerfile using a `renv.lock`
  file to capture your R package dependencies.

- **Dependency Management**:  
  Utilize `renv` to manage and restore R package dependencies. If a
  lockfile does not exist, `shiny2docker()` will automatically create
  one for production using the `attachment::create_renv_for_prod`
  function.

- **Customizability**:  
  The `shiny2docker()` function returns a **dockerfiler** object that
  can be further manipulated using **dockerfiler**’s methods before
  writing it to a file. This enables advanced users to customize the
  Dockerfile to better suit their needs. See
  [dockerfiler](https://github.com/ThinkR-open/dockerfiler) for more
  details.

- **GitLab CI Integration**:  
  With the `set_gitlab_ci()` function, you can easily configure your
  GitLab CI pipeline. This function copies a pre-configured
  `gitlab-ci.yml` file from the package into your project directory. The
  provided CI configuration is designed to build your Docker image and
  push the created image to the GitLab container registry, thereby
  streamlining continuous integration and deployment workflows.

- **GitHub Actions Integration**:  
  With the `set_github_action()` function, you can quickly set up a
  GitHub Actions pipeline. This function copies a pre-configured
  `docker-build.yml` file from the package into the `.github/workflows/`
  directory of your project. The provided CI configuration is designed
  to build your Docker image and push the created image to the GitHub
  Container Registry, facilitating automated builds and deployments on
  GitHub.

## Installation

You can install the production version from CRAN with :

``` r
install.packages("shiny2docker")
```

You can install the development version of `shiny2docker` from
[GitHub](https://github.com/VincentGuyader/shiny2docker) with:

``` r
# install.packages("pak")
pak::pak("VincentGuyader/shiny2docker")
```

## Usage

### Generate a Dockerfile for a Shiny Application

Use the `shiny2docker()` function to automatically generate a Dockerfile
based on your application’s dependencies.

``` r
library(shiny2docker)

# Generate Dockerfile in the current directory
shiny2docker(path = ".")

# Generate Dockerfile with a specific renv.lock and output path
shiny2docker(path = "path/to/shiny/app",
             lockfile = "path/to/shiny/app/renv.lock",
             output = "path/to/shiny/app/Dockerfile")

# Further manipulate the Dockerfile object before writing to disk
docker_obj <- shiny2docker()
docker_obj$ENV("MY_ENV_VAR", "value")
docker_obj$write("Dockerfile")
```

### Configure GitLab CI for Docker Builds

The `set_gitlab_ci()` function allows you to quickly set up a GitLab CI
pipeline that will build your Docker image and push it to the GitLab
container registry.

``` r
library(shiny2docker)

# Copy the .gitlab-ci.yml file to the current directory
set_gitlab_ci()

# Specify runner tags
set_gitlab_ci(tags = c("shiny_build", "prod"))
```

### Configure GitHub Actions for Docker Builds

The new `set_github_action()` function allows you to quickly set up a
GitHub Actions pipeline that will build your Docker image and push it to
the GitHub Container Registry.

``` r
library(shiny2docker)

# Copy the docker-build.yml file to the .github/workflows/ directory
set_github_action(path = ".")
```

Once the `docker-build.yml` file is in place, you can integrate it with
GitHub Actions to automate the Docker image build and deployment
process.

## Experimental: uvr backend (`shiny2docker_uvr()`)

`shiny2docker_uvr()` is a sister function that generates a Dockerfile
using [**uvr**](https://github.com/nbafrank/uvr) — a Rust-based,
uv-style R project manager — instead of `renv`. With this backend:

- The R version is installed **inside the container** by `uvr` (no
  `rocker/r-ver` base image required); pick any Debian/Ubuntu-derived
  amd64 image you want.
- Packages are restored from `uvr.lock` via `uvr sync` at build time.
- Manifest, lockfile and R version live in three small files at the
  project root: `uvr.toml`, `uvr.lock`, `.r-version`.

> **Lifecycle: experimental.** It works end-to-end on Linux, but on
> Debian targets `uvr` 0.2.15 currently falls back to source compilation
> for some packages (P3M binary detection still maturing), so cold
> builds can be slow. See the [uvr
> README](https://github.com/nbafrank/uvr) for the upstream roadmap.

### Install the `uvr` CLI from R

You don’t have to leave R to install the binary — `install_uvr()`
downloads the right release for your platform and drops the executable
in a sensible place:

``` r
shiny2docker::install_uvr()
# Linux/macOS default:  ~/.local/bin/uvr
# Windows default:      %LOCALAPPDATA%\shiny2docker\bin\uvr.exe
```

If `~/.local/bin` (or the Windows equivalent) isn’t on your `PATH` yet,
`install_uvr()` prints a one-line `export`/`setx` hint to make it
permanent.

You can also pin a specific release or a custom destination:

``` r
shiny2docker::install_uvr(version = "v0.2.15", dest = "/usr/local/bin")
```

### Generate the Dockerfile

``` r
library(shiny2docker)

# In a directory containing your shiny app:
shiny2docker_uvr()
```

If `uvr.toml` / `uvr.lock` / `.r-version` are missing, the function
bootstraps them automatically (same UX as `shiny2docker()` does for
`renv.lock`):

1.  generate `renv.lock` via `attachment::create_renv_for_prod()` if
    missing,
2.  run `uvr init` + `uvr import` to produce `uvr.toml`,
3.  pin `.r-version` to the local R version,
4.  run `uvr lock` to produce `uvr.lock`.

Set `bootstrap = FALSE` if you want it to fail fast instead — useful in
CI where you expect those three files to already exist.

If the `uvr` CLI isn’t installed when bootstrapping is needed and the
session is interactive, you’ll be prompted to install it on the spot.

### The `frozen` argument

Reproducibility detail worth understanding before deploying:

- `uvr.toml` is the **manifest** (“I want shiny, dplyr, …”).
- `uvr.lock` is the **lockfile** (“here are the exact versions: shiny
  1.10.0, dplyr 1.1.4, …”). It’s the one to commit and trust as source
  of truth.

Inside the generated Dockerfile, the package install step is either:

- `uvr sync --frozen` — strict CI mode. **If `uvr.lock` is out of date
  relative to `uvr.toml`, the build fails.** This is what you want
  long-term: the image installs *exactly* what’s in your committed
  lockfile, no surprise.
- `uvr sync` — lenient mode. If `uvr.lock` looks stale, uvr re-resolves
  on the fly. Build still succeeds, but the image may contain package
  versions that aren’t pinned in your committed lock — you’ve quietly
  lost reproducibility.

`shiny2docker_uvr()` defaults to `frozen = FALSE` (lenient) and emits a
`cli` warning to make this explicit. Why not strict by default? Because
`uvr` 0.2.15 has a known false-positive: a lockfile generated on host OS
A gets rejected as “stale” by `uvr sync --frozen` running inside a
container based on host OS B (Ubuntu host → Debian image is the typical
case). So flipping `--frozen` on by default would break builds for the
wrong reason.

Switch to `frozen = TRUE` once any of these is true:

- upstream uvr fixes the cross-host false positive (track
  [nbafrank/uvr](https://github.com/nbafrank/uvr));
- your dev host runs the same distribution as your container
  (e.g. Debian dev → Debian image);
- you’re confident the lock will always be regenerated on the same OS as
  the Docker target.

``` r
# Once your environment supports it:
shiny2docker_uvr(frozen = TRUE)
```

### Other useful arguments

``` r
shiny2docker_uvr(
  path          = ".",
  base_image    = "debian:stable-slim",   # any Debian/Ubuntu amd64 image
  uvr_version   = "v0.2.15",              # pin the uvr binary version
  port          = 3838,
  host          = "0.0.0.0",
  extra_sysreqs = c("libsqlite3-dev"),    # injected before `uvr sync`
  bootstrap     = TRUE,                   # auto-create missing uvr files
  frozen        = FALSE,                  # see above
  write         = TRUE                    # FALSE -> return Dockerfile only
)
```

## Example Workflow

1.  **Prepare Your Shiny Application**:  
    Ensure that your Shiny app is located in a folder with the necessary
    files (e.g., `app.R` or `ui.R` and `server.R`).

2.  **Generate the Dockerfile**:  
    Run `shiny2docker()` to create the Dockerfile (and a `.dockerignore`
    file) in your project directory. This Dockerfile will include
    instructions to install system dependencies, R packages, and launch
    the Shiny app.

3.  **Set Up Continuous Integration (Optional)**:

    - If you use GitLab, run `set_gitlab_ci()` to copy the
      pre-configured GitLab CI file into your project. This CI
      configuration will handle the Docker image build and deployment to
      GitLab’s container registry.
    - If you use GitHub, run `set_github_action(path = ".")` to copy the
      pre-configured GitHub Actions file into your project. This CI
      configuration will build your Docker image and push it to the
      GitHub Container Registry.

4.  **Deploy Your Application**:  
    Use Docker to build and run your image, or integrate with your
    chosen CI/CD service for automated deployments.

## License

This project is licensed under the terms of the MIT license.
