## R CMD check results

0 errors | 0 warnings | 1 note

The note is the incoming-feasibility one, and it says two things.

* New submission. This is indeed the first.
* `https://r-heller.github.io/maumauR/` returns 404. The documentation site is
  built by the `pkgdown` workflow in `.github/workflows/`, and the URL will
  resolve once that workflow has run against the default branch. We have left
  the URL in `DESCRIPTION` because it is where the site will live.

With the network part of that check disabled
(`_R_CHECK_CRAN_INCOMING_REMOTE_=false`, which is what the CI workflow and
`devtools::check()` use) the status is OK: 0 errors, 0 warnings, 0 notes.

## Test environments

* local: Ubuntu 24.04, R 4.6.1
* GitHub Actions: ubuntu-latest (devel, release, oldrel-1), macos-latest
  (release), windows-latest (release)

## This is a new submission.

The package has no external dependencies beyond CRAN packages, requires no
internet access, and writes nothing outside `tempdir()`. The bundled Shiny
application is only started by `mm_run_app()`, whose example is wrapped in
`\donttest{}` and guarded by `interactive()`.
