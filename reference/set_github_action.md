# Configure GitHub Action pipeline for Docker builds

Copies the `docker-build.yml` file provided by the `shiny2docker`
package into the `.github/workflows/` directory within the specified
base directory. This GitHub Action configuration is designed to build a
Docker image and push the created image to the GitHub Container
Registry.

## Usage

``` r
set_github_action(path)
```

## Arguments

- path:

  A character string specifying the base directory where the
  `.github/workflows/` folder will be created and the `docker-build.yml`
  file copied. If missing, the user will be prompted to use the current
  directory.

## Value

A logical value indicating whether the file was successfully copied
(`TRUE`) or not (`FALSE`).

## Examples

``` r
# Copy the docker-build.yml file to the .github/workflows/ directory in a temporary folder
set_github_action(path = tempdir())
#> ℹ Creating destination directory: /tmp/RtmpVfJwpn/.github/workflows
#> ✔ Directory created: /tmp/RtmpVfJwpn/.github/workflows
#> ℹ Copying file from: /home/runner/work/_temp/Library/shiny2docker/docker-build.yml
#> ✔ File docker-build.yml copied successfully to /tmp/RtmpVfJwpn/.github/workflows
#> [1] TRUE
```
