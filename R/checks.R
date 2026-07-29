# Internal input validators.
#
# Every validator takes the value, the argument label used in the message, and
# the calling environment so that errors are reported against user code rather
# than against package internals. Validators return the (coerced) value
# invisibly so they can be used as `x <- .check_*(x)`.

.check_flag <- function(x,
                        arg = rlang::caller_arg(x),
                        call = rlang::caller_env()) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be {.code TRUE} or {.code FALSE}.",
        "x" = "Got {.cls {class(x)[[1L]]}} of length {length(x)}."
      ),
      call = call
    )
  }
  invisible(x)
}

.check_string <- function(x,
                          arg = rlang::caller_arg(x),
                          call = rlang::caller_env()) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a single non-missing string.",
        "x" = "Got {.cls {class(x)[[1L]]}} of length {length(x)}."
      ),
      call = call
    )
  }
  invisible(x)
}

.check_count <- function(x,
                         arg = rlang::caller_arg(x),
                         min = 0L,
                         max = Inf,
                         call = rlang::caller_env()) {
  ok <- is.numeric(x) && length(x) == 1L && !is.na(x) && x == trunc(x)
  if (!ok) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a single whole number.",
        "x" = "Got {.cls {class(x)[[1L]]}} of length {length(x)}."
      ),
      call = call
    )
  }
  if (x < min || x > max) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be between {min} and {max}.",
        "x" = "Got {.val {x}}."
      ),
      call = call
    )
  }
  invisible(as.integer(x))
}

.check_class <- function(x,
                         cls,
                         arg = rlang::caller_arg(x),
                         call = rlang::caller_env()) {
  if (!inherits(x, cls)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a {.cls {cls}} object.",
        "x" = "Got {.cls {class(x)[[1L]]}} instead.",
        "i" = "See {.fn maumauR::mm_deck_spec} and {.fn maumauR::mm_new_game}."
      ),
      call = call
    )
  }
  invisible(x)
}

# Coerce a single strategy or a list of strategies to a list of length
# `n_players`. A single strategy is recycled across all seats.
.check_strategies <- function(x,
                              n_players,
                              arg = rlang::caller_arg(x),
                              call = rlang::caller_env()) {
  strategies <- if (inherits(x, "mm_strategy")) list(x) else x
  if (!is.list(strategies) || length(strategies) == 0L) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be an {.cls mm_strategy} or a list of them.",
        "x" = "Got {.cls {class(x)[[1L]]}} of length {length(x)}.",
        "i" = "See {.fn maumauR::mm_strategy_greedy}."
      ),
      call = call
    )
  }
  is_strategy <- vapply(
    strategies,
    function(s) inherits(s, "mm_strategy"),
    logical(1L)
  )
  if (!all(is_strategy)) {
    bad <- which(!is_strategy)
    cli::cli_abort(
      c(
        "Every element of {.arg {arg}} must be an {.cls mm_strategy}.",
        "x" = "Element{?s} {bad} {?is/are} not.",
        "i" = "See {.fn maumauR::mm_strategy_greedy}."
      ),
      call = call
    )
  }
  if (length(strategies) == 1L) {
    strategies <- rep(strategies, n_players)
  }
  if (length(strategies) != n_players) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must have one strategy per seat.",
        "x" = "Got {length(strategies)} strateg{?y/ies} for {n_players} \\
               player{?s}."
      ),
      call = call
    )
  }
  strategies
}

# Validate that a tibble carries the columns a downstream summary needs.
.check_sims <- function(x,
                        cols,
                        arg = rlang::caller_arg(x),
                        call = rlang::caller_env()) {
  if (!is.data.frame(x)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a data frame from {.fn maumauR::mm_simulate}.",
        "x" = "Got {.cls {class(x)[[1L]]}} instead."
      ),
      call = call
    )
  }
  missing <- setdiff(cols, names(x))
  if (length(missing) > 0L) {
    cli::cli_abort(
      c(
        "{.arg {arg}} is missing required column{?s} {.field {missing}}.",
        "i" = "Use the tibble returned by {.fn maumauR::mm_simulate}."
      ),
      call = call
    )
  }
  invisible(x)
}

# Save and restore the RNG state around a seeded call, so that seeding a
# simulation never leaks into the caller's random stream.
.seed_state <- function() {
  if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
    get(".Random.seed", envir = globalenv(), inherits = FALSE)
  } else {
    NULL
  }
}

.restore_seed <- function(state) {
  if (is.null(state)) {
    if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  } else {
    assign(".Random.seed", state, envir = globalenv())
  }
  invisible(NULL)
}
