# shiny2docker

Generate a Dockerfile for a Shiny Application

## Usage

``` r
shiny2docker(
  path = ".",
  lockfile = file.path(path, "renv.lock"),
  output = file.path(path, "Dockerfile"),
  FROM = "rocker/geospatial",
  AS = NULL,
  sysreqs = TRUE,
  repos = c(CRAN = "https://cran.rstudio.com/"),
  expand = FALSE,
  extra_sysreqs = NULL,
  use_pak = FALSE,
  user = NULL,
  dependencies = NA,
  sysreqs_platform = "ubuntu",
  folder_to_exclude = c("renv"),
  renv_version
)
```

## Arguments

- path:

  Character. Path to the folder containing the Shiny application (e.g.,
  `app.R` or `ui.R` and `server.R`) along with any other necessary
  files.

- lockfile:

  Character. Path to the `renv.lock` file that specifies the R package
  dependencies. If the `renv.lock` file does not exist, it will be
  created for production using the
  [`attachment::create_renv_for_prod`](https://thinkr-open.github.io/attachment/reference/create_renv_for_dev.html)
  function.

- output:

  Character. Path to the generated Dockerfile. Defaults to
  `"Dockerfile"`.

- FROM:

  Docker image to start FROM. Default is rocker/geospatial

- AS:

  The AS of the Dockerfile. Default it `NULL`.

- sysreqs:

  boolean. If `TRUE`, the Dockerfile will contain sysreq installation.

- repos:

  character. The URL(s) of the repositories to use for
  `options("repos")`.

- expand:

  boolean. If `TRUE` each system requirement will have its own `RUN`
  line.

- extra_sysreqs:

  character vector. Extra debian system requirements. Will be installed
  with apt-get install.

- use_pak:

  boolean. If `TRUE` use pak to deal with dependencies during
  [`renv::restore()`](https://rstudio.github.io/renv/reference/restore.html).
  FALSE by default

- user:

  Name of the user to specify in the Dockerfile with the USER
  instruction. Default is `NULL`, in which case the user from the FROM
  image is used.

- dependencies:

  What kinds of dependencies to install. Most commonly one of the
  following values:

  - `NA`: only required (hard) dependencies,

  - `TRUE`: required dependencies plus optional and development
    dependencies,

  - `FALSE`: do not install any dependencies. (You might end up with a
    non-working package, and/or the installation might fail.)

- sysreqs_platform:

  System requirements platform.`ubuntu` by default. If `NULL`, then the
  current platform is used. Can be : "ubuntu-22.04" if needed to fit
  with the `FROM` Operating System. Only debian or ubuntu based images
  are supported

- folder_to_exclude:

  Folder to exclude during scan to detect packages

- renv_version:

  character. Optional. Forwarded to
  [`dockerfiler::dock_from_renv()`](https://thinkr-open.github.io/dockerfiler/reference/dock_from_renv.html).
  By default (parameter omitted), the renv version recorded in the
  `renv.lock` file is used. Set to `NULL` to install the latest
  available renv from the configured repos (faster build, no `remotes`
  dependency).

## Value

An object of class `dockerfiler`, representing the generated Dockerfile.
This object can be further manipulated using `dockerfiler` functions
before being written to disk.

## Details

Automate the creation of a Dockerfile tailored for deploying Shiny
applications. It manages R dependencies using `renv`, generates a
`.dockerignore` file to optimize the Docker build process, and leverages
the `dockerfiler` package to allow further customization of the
Dockerfile object before writing it to disk.

## Examples

``` r
# \donttest{
  temp_dir <- tempfile("shiny2docker_example_")
  dir.create(temp_dir)
  example_app <- system.file("dummy_app", package = "shiny2docker")
  file.copy(example_app, temp_dir, recursive = TRUE)
#> [1] TRUE

  app_path <- file.path(temp_dir, "dummy_app")
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
  rstudioapi::isAvailable()) {
    rstudioapi::filesPaneNavigate(app_path)
  }

  docker_obj <- shiny2docker::shiny2docker(path = app_path)
#> Loading required namespace: renv
#> ℹ No DESCRIPTION file found
#> ℹ we wil parse qmd files,Rmd files and R scripts from  /tmp/RtmpVfJwpn/shiny2docker_example_1a252ce6cd46/dummy_app .
#> All required packages are installed
#> ✔ create renv.lock at /tmp/RtmpVfJwpn/shiny2docker_example_1a252ce6cd46/dummy_app/renv.lock
#> The following package(s) will be updated in the lockfile:
#> 
#> # RSPM -----------------------------------------------------------------------
#> - R6            [* -> 2.6.1]
#> - Rcpp          [* -> 1.1.1-1.1]
#> - base64enc     [* -> 0.1-6]
#> - bslib         [* -> 0.10.0]
#> - cachem        [* -> 1.1.0]
#> - cli           [* -> 3.6.6]
#> - commonmark    [* -> 2.0.0]
#> - digest        [* -> 0.6.39]
#> - fastmap       [* -> 1.2.0]
#> - fontawesome   [* -> 0.5.3]
#> - fs            [* -> 2.1.0]
#> - glue          [* -> 1.8.1]
#> - htmltools     [* -> 0.5.9]
#> - httpuv        [* -> 1.6.17]
#> - jquerylib     [* -> 0.1.4]
#> - jsonlite      [* -> 2.0.0]
#> - later         [* -> 1.4.8]
#> - lifecycle     [* -> 1.0.5]
#> - magrittr      [* -> 2.0.5]
#> - memoise       [* -> 2.0.1]
#> - mime          [* -> 0.13]
#> - otel          [* -> 0.2.0]
#> - promises      [* -> 1.5.0]
#> - rappdirs      [* -> 0.3.4]
#> - remotes       [* -> 2.5.0]
#> - rlang         [* -> 1.2.0]
#> - sass          [* -> 0.4.10]
#> - shiny         [* -> 1.13.0]
#> - sourcetools   [* -> 0.1.7-2]
#> - withr         [* -> 3.0.2]
#> - xtable        [* -> 1.8-8]
#> 
#> The version of R recorded in the lockfile will be updated:
#> - R             [* -> 4.6.0]
#> 
#> - Lockfile written to "/tmp/RtmpVfJwpn/shiny2docker_example_1a252ce6cd46/dummy_app/renv.lock".
#> renv version = the most up to date version in the repos
#> ℹ Please wait while we compute system requirements...
#> Fetching system dependencies for 31 package(s) records.
#> Warning: `lang()` is deprecated as of rlang 0.2.0. Please use `call2()` instead.
#> This warning is displayed once every 8 hours.
#> ℹ Loading metadata database
#> ✔ Loading metadata database ... done
#> 
#> ✔ Done

  print(list.files(app_path,all.files = TRUE,no.. = TRUE))
#> [1] ".dockerignore" "Dockerfile"    "app.R"         "renv.lock"    

  # Further manipulate the Dockerfile object
 docker_obj$add_after(
   cmd = "ENV ENV \'MY_ENV_VAR\'=\'value\'",
   after = 3
 )
 docker_obj$write(file.path(app_path, "Dockerfile"))
# }
```
