
<!-- README.md is generated from README.Rmd. Please edit that file -->

# shiny2docker

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/VincentGuyader/shiny2docker/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/VincentGuyader/shiny2docker/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

An R package designed to streamline the process of containerizing Shiny
applications using Docker. By automating the generation of essential
Docker files and managing R dependencies with `renv`, `shiny2docker`
simplifies the deployment of Shiny apps, ensuring reproducibility and
consistency across different environments.

- **Automated Dockerfile Generation**: Quickly generate Dockerfiles
  tailored for Shiny applications.
- **Dependency Management**: Utilize `renv` to manage and restore R
  package dependencies.
- **Optimized Docker Build**: Create `.dockerignore` files to exclude
  unnecessary files, reducing build time and image size.
- **Customisable** : The `shiny2docker` function returns a
  **dockerfiler** object that can be further manipulated using
  **dockerfiler**’s methods before writing it to a file. see
  [dockerfiler](https://github.com/ThinkR-open/dockerfiler)

## Installation

You can install the development version of shiny2docker from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("VincentGuyader/shiny2docker")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(shiny2docker)
# Generate Dockerfile in the current directory
shiny2docker(path = ".")

# Generate Dockerfile with a specific renv.lock and output path
shiny2docker(path = "path/to/shiny/app",
            lockfile = "path/to/shiny/app/renv.lock",
            output = "path/to/shiny/app/Dockerfile")

# Further manipulate the Dockerfile object
docker_obj <- shiny2docker()
docker_obj$ENV("MY_ENV_VAR", "value")
docker_obj$write("Dockerfile")
```
