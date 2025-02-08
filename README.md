
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
