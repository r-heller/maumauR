## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local: Ubuntu 24.04, R 4.6.1
* GitHub Actions: ubuntu-latest (devel, release, oldrel-1), macos-latest
  (release), windows-latest (release)

## This is a new submission.

The package has no external dependencies beyond CRAN packages, requires no
internet access, and writes nothing outside `tempdir()`. The bundled Shiny
application is only started by `mm_run_app()`, whose example is wrapped in
`\donttest{}` and guarded by `interactive()`.
