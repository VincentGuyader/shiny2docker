# Changelog

## shiny2docker 0.0.4

- [`shiny2docker()`](https://vincentguyader.github.io/shiny2docker/reference/shiny2docker.md)
  gains a `renv_version` parameter, forwarded to
  [`dockerfiler::dock_from_renv()`](https://thinkr-open.github.io/dockerfiler/reference/dock_from_renv.html).
  Set to `NULL` to bootstrap with the latest available renv (skipping
  the `remotes` dependency entirely).
- Minimum `dockerfiler` version bumped to `>= 0.2.6` for the
  `renv_version` argument.

## shiny2docker 0.0.3

CRAN release: 2025-06-28

- [`set_gitlab_ci()`](https://vincentguyader.github.io/shiny2docker/reference/set_gitlab_ci.md)
  now accepts a `tags` parameter so you can specify one or more GitLab
  runner tags to use for the CI job.

## shiny2docker 0.0.2

CRAN release: 2025-02-09

### New functions

- **`set_github_action`**  
  Configure a GitHub Action pipeline for Docker builds.

## shiny2docker 0.0.1

CRAN release: 2025-02-04

- Initial CRAN submission.

### New functions

- **`shiny2docker`**  
  Generate a Dockerfile for a Shiny Application. This function automates
  the creation of a Dockerfile tailored for deploying Shiny applications
  by managing R dependencies with `renv`, generating a `.dockerignore`
  file to optimize the Docker build process, and leveraging the
  `dockerfiler` package for further customization. Additionally, it uses
  [`attachment::create_renv_for_prod`](https://thinkr-open.github.io/attachment/reference/create_renv_for_dev.html)
  to create a lockfile if one is missing.

- **`set_gitlab_ci`**  
  Configure a GitLab CI pipeline for Docker builds. This function copies
  the `gitlab-ci.yml` file provided by the package to a specified
  directory. The configuration is designed to build a Docker image and
  push the created image to the GitLab container registry.
