# shiny2docker 0.0.2

## New functions

+ **`set_github_action`**  
  Configure a Github Action pipeline for Docker builds.

# shiny2docker 0.0.1

* Initial CRAN submission.

## New functions

+ **`shiny2docker`**  
  Generate a Dockerfile for a Shiny Application. This function automates the creation of a Dockerfile tailored for deploying Shiny applications by managing R dependencies with `renv`, generating a `.dockerignore` file to optimize the Docker build process, and leveraging the `dockerfiler` package for further customization. Additionally, it uses `attachment::create_renv_for_prod` to create a lockfile if one is missing.

+ **`set_gitlab_ci`**  
  Configure a GitLab CI pipeline for Docker builds. This function copies the `gitlab-ci.yml` file provided by the package to a specified directory. The configuration is designed to build a Docker image and push the created image to the GitLab container registry.
