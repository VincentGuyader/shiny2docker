## Submission

This release exposes the new `renv_version` parameter of
`shiny2docker()`, forwarded to `dockerfiler::dock_from_renv()`.
Setting `renv_version = NULL` lets the Dockerfile bootstrap with the
latest renv available from the configured repositories, skipping the
`remotes` dependency entirely.

The minimum `dockerfiler` version is bumped to `>= 0.2.6`, which is
satisfied by `dockerfiler` 1.0.0, currently on CRAN.

## Test environments

* Local: Ubuntu 24.04, R release
* GitHub Actions: ubuntu-latest (R devel, release, oldrel-1),
  macOS-latest (R release), windows-latest (R release)
* R-hub: linux, macos, macos-arm64, windows
* win-builder: R devel, release

## R CMD check results

0 errors | 0 warnings | 0 notes

## Reverse dependencies

`shiny2docker` has no reverse dependencies on CRAN at the time of this
submission. `revdepcheck::revdep_check()` was therefore not run.
