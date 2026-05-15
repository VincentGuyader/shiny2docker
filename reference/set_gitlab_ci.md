# Configure GitLab CI pipeline for Docker builds

Copies the `.gitlab-ci.yml` file provided by the `shiny2docker` package
into the specified directory. The GitLab CI configuration is designed to
build a Docker image and push the created image to the GitLab container
registry.

## Usage

``` r
set_gitlab_ci(path, tags = NULL)
```

## Arguments

- path:

  A character string specifying the directory where the `.gitlab-ci.yml`
  file will be copied. If missing, the user will be prompted to use the
  current directory.

- tags:

  Optional character vector of GitLab runner tags. If provided, the
  function will add these tags to the generated CI job so the
  appropriate runner is selected. You can provide multiple tags.

## Value

A logical value indicating whether the file was successfully copied
(`TRUE`) or not (`FALSE`).

## Examples

``` r
# Copy the .gitlab-ci.yml file to a temporary directory
set_gitlab_ci(path = tempdir())
#> ℹ Copying .gitlab-ci.yml file to: /tmp/RtmpVfJwpn
#> ℹ Found source file at: /home/runner/work/_temp/Library/shiny2docker/gitlab-ci.yml
#> ✔ .gitlab-ci.yml file successfully copied to /tmp/RtmpVfJwpn
#> [1] TRUE

# Copy the file and specify runner tags
set_gitlab_ci(path = tempdir(), tags = c("shiny_build", "prod"))
#> ℹ Copying .gitlab-ci.yml file to: /tmp/RtmpVfJwpn
#> ℹ Found source file at: /home/runner/work/_temp/Library/shiny2docker/gitlab-ci.yml
#> ℹ Adding runner tags to .gitlab-ci.yml: shiny_build, prod
#> ✔ .gitlab-ci.yml file successfully copied to /tmp/RtmpVfJwpn
#> [1] TRUE
```
