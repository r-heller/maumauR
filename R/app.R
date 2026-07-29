#' Launch the Mau Mau Shiny application
#'
#' Starts the bundled Shiny application: play a hand against the artificial
#' opponents, explore win rates by seat, compare strategies head to head, and
#' inspect the game-length and draw-count distributions.
#'
#' @param ... Additional arguments passed to [shiny::runApp()], for example
#'   `launch.browser = FALSE` or `port`.
#' @inheritParams mm_deck_spec
#'
#' @return Invisible `NULL`. Called for its side effect of launching a Shiny
#'   application.
#'
#' @family app
#' @seealso [mm_simulate()] for the same analyses at the console.
#'
#' @examples
#' \donttest{
#' if (interactive()) {
#'   mm_run_app()
#' }
#' }
#'
#' @export
mm_run_app <- function(..., call = rlang::caller_env()) {
  pkg <- utils::packageName()
  needed <- c("shiny", "bslib")
  absent <- needed[!vapply(needed, .has_package, logical(1L))]
  if (length(absent) > 0L) {
    cli::cli_abort(
      c(
        "The application needs {.pkg {absent}}.",
        "i" = 'Install with {.code install.packages(c("shiny", "bslib"))}.'
      ),
      call = call
    )
  }

  app_dir <- .app_dir(pkg)
  if (!nzchar(app_dir)) {
    cli::cli_abort(
      c(
        "Could not find the application inside {.pkg {pkg}}.",
        "i" = "Reinstall the package."
      ),
      call = call
    )
  }

  shiny::runApp(app_dir, ...)
  invisible(NULL)
}

# Indirection so that the guards above can be exercised in tests.
.has_package <- function(pkg) {
  requireNamespace(pkg, quietly = TRUE)
}

.app_dir <- function(pkg) {
  system.file("shiny", pkg, package = pkg)
}
