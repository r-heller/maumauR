# The card count printed on the box: "Inhalt: 32 Spielkarten".
.mm_box_size <- 32L

# Card types, in the order used for building and printing a deck.
.mm_types <- c("number", "plus2", "skip", "wild")

# Low-level constructor. Trusted input only: everything is validated by
# `mm_deck_spec()` before it gets here.
new_mm_deck_spec <- function(colours, numbers, plus2, skip, wild, size) {
  stopifnot(is.character(colours))
  stopifnot(is.integer(numbers))
  stopifnot(is.integer(plus2), is.integer(skip), is.integer(wild))
  stopifnot(is.integer(size))

  structure(
    list(
      colours = colours,
      numbers = numbers,
      plus2 = plus2,
      skip = skip,
      wild = wild,
      size = size
    ),
    class = "mm_deck_spec"
  )
}

# Validator. Checks the invariants the constructor trusts, and warns - never
# errors - when the total departs from the printed box count.
validate_mm_deck_spec <- function(x, call = rlang::caller_env()) {
  .check_class(x, "mm_deck_spec", call = call)

  parts <- length(x$colours) * (length(x$numbers) + x$plus2 + x$skip) + x$wild
  if (!identical(x$size, as.integer(parts))) {
    cli::cli_abort(
      c(
        "Invalid {.cls mm_deck_spec}: {.field size} does not match the parts.",
        "x" = "{.field size} is {x$size} but the parts sum to {parts}."
      ),
      call = call
    )
  }
  box <- .mm_box_size
  if (!identical(x$size, box)) {
    cli::cli_warn(
      c(
        "!" = "The deck specification totals {x$size} card{?s}, but the box
               states {box}.",
        "i" = "Correct the {.fn mm_deck_spec} arguments after a physical card
               count; every simulation, summary, and plot follows from them."
      ),
      call = call
    )
  }
  x
}

#' Deck specification for "der kleine ICE" Mau Mau
#'
#' Builds the specification of the DB "der kleine ICE" Mau Mau deck: which
#' colours exist, which number faces each colour carries, and how many special
#' cards the deck holds. The specification is the single source of truth for
#' deck composition - the engine, the simulator, the summaries, and the Shiny
#' app all read the deck from it.
#'
#' @details
#' **This is the single point of correction for the deck.** The box states 32
#' cards (`Inhalt: 32 Spielkarten`). The defaults are the only reconstruction
#' that reaches that total while keeping every card type described in the
#' printed rules:
#'
#' \itemize{
#'   \item four colours (red, green, blue, yellow),
#'   \item five number faces per colour (`1:5`) - 20 cards,
#'   \item one `+2` (draw two) per colour - 4 cards,
#'   \item one skip (`Aussetzen`) per colour - 4 cards,
#'   \item four colourless wild cards (`Farbwahl`) - 4 cards.
#' }
#'
#' The *number of number faces* (five per colour) is fixed by arithmetic once
#' the specials are known; the face values themselves (`1:5`) remain a
#' reconstruction pending a physical card count. Adjust `numbers`, `plus2`,
#' `skip`, and `wild` here and everything downstream follows. A specification
#' whose total is not 32 is accepted but warns, so a wrongly built deck can
#' never pass unnoticed.
#'
#' @param colours Character vector of colour names. Must be unique and
#'   non-missing.
#' @param numbers Integer vector of number-card face values present in each
#'   colour. Must be unique and non-missing.
#' @param plus2 Integer; number of `+2` (draw two) cards per colour.
#' @param skip Integer; number of skip (`Aussetzen`) cards per colour.
#' @param wild Integer; number of colourless wild (`Farbwahl`) cards.
#' @param call The environment used for error reporting. Experts only.
#'
#' @return An object of class `mm_deck_spec`: a list with elements
#' \describe{
#'   \item{`colours`}{Colour names (character).}
#'   \item{`numbers`}{Number faces per colour (integer).}
#'   \item{`plus2`}{`+2` cards per colour (integer, length 1).}
#'   \item{`skip`}{Skip cards per colour (integer, length 1).}
#'   \item{`wild`}{Wild cards in the deck (integer, length 1).}
#'   \item{`size`}{Total number of cards (integer, length 1).}
#' }
#'
#' @family deck
#' @seealso [mm_build_deck()] to turn a specification into a card table.
#'
#' @examples
#' spec <- mm_deck_spec()
#' spec
#' spec$size
#'
#' # A specification that departs from the printed 32-card total warns:
#' suppressWarnings(mm_deck_spec(numbers = 0:5))$size
#'
#' @export
mm_deck_spec <- function(colours = c("red", "green", "blue", "yellow"),
                         numbers = 1:5,
                         plus2 = 1L,
                         skip = 1L,
                         wild = 4L,
                         call = rlang::caller_env()) {
  colours <- .check_labels(colours, call = call)
  numbers <- .check_faces(numbers, call = call)
  plus2 <- .check_count(plus2, min = 0L, call = call)
  skip <- .check_count(skip, min = 0L, call = call)
  wild <- .check_count(wild, min = 0L, call = call)

  size <- length(colours) * (length(numbers) + plus2 + skip) + wild
  spec <- new_mm_deck_spec(
    colours = colours,
    numbers = numbers,
    plus2 = plus2,
    skip = skip,
    wild = wild,
    size = as.integer(size)
  )
  validate_mm_deck_spec(spec, call = call)
}

.check_labels <- function(x,
                          arg = rlang::caller_arg(x),
                          call = rlang::caller_env()) {
  if (!is.character(x) || anyNA(x)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a character vector without missing values.",
        "x" = "Got {.cls {class(x)[[1L]]}}."
      ),
      call = call
    )
  }
  if (anyDuplicated(x) > 0L) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be unique.",
        "x" = "Duplicated: {.val {unique(x[duplicated(x)])}}."
      ),
      call = call
    )
  }
  x
}

.check_faces <- function(x,
                         arg = rlang::caller_arg(x),
                         call = rlang::caller_env()) {
  if (!is.numeric(x) || anyNA(x) || any(x != trunc(x))) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be whole numbers without missing values.",
        "x" = "Got {.cls {class(x)[[1L]]}}."
      ),
      call = call
    )
  }
  if (anyDuplicated(x) > 0L) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be unique.",
        "x" = "Duplicated: {.val {unique(x[duplicated(x)])}}."
      ),
      call = call
    )
  }
  as.integer(x)
}

#' Build the card table for a deck specification
#'
#' Expands an [mm_deck_spec()] into one row per physical card. This is the
#' table the engine deals from.
#'
#' @param spec A deck specification from [mm_deck_spec()].
#' @inheritParams mm_deck_spec
#'
#' @return A [tibble::tibble()] with `spec$size` rows and columns
#' \describe{
#'   \item{`color`}{Card colour (character); `NA` for wild cards.}
#'   \item{`value`}{Number face (integer); `NA` for `+2`, skip, and wild.}
#'   \item{`type`}{One of `"number"`, `"plus2"`, `"skip"`, `"wild"`
#'     (character).}
#' }
#' An empty specification yields a 0-row tibble with those columns, never
#' `NULL`.
#'
#' @family deck
#' @seealso [mm_deck_spec()] for the composition itself.
#'
#' @examples
#' deck <- mm_build_deck()
#' deck
#' table(deck$type)
#'
#' @export
mm_build_deck <- function(spec = mm_deck_spec(), call = rlang::caller_env()) {
  .check_class(spec, "mm_deck_spec", call = call)

  n_colours <- length(spec$colours)
  n_numbers <- length(spec$numbers)
  n_special <- spec$plus2 + spec$skip

  number_color <- rep(spec$colours, each = n_numbers)
  number_value <- rep(spec$numbers, times = n_colours)

  special_color <- rep(spec$colours, each = n_special)
  special_type <- rep(
    c(rep("plus2", spec$plus2), rep("skip", spec$skip)),
    times = n_colours
  )

  tibble::tibble(
    color = c(
      number_color,
      special_color,
      rep(NA_character_, spec$wild)
    ),
    value = c(
      number_value,
      rep(NA_integer_, length(special_color)),
      rep(NA_integer_, spec$wild)
    ),
    type = c(
      rep("number", length(number_color)),
      special_type,
      rep("wild", spec$wild)
    )
  )
}

#' @param x An object of class `mm_deck_spec`.
#' @param ... Not used.
#' @rdname mm_deck_spec
#' @export
print.mm_deck_spec <- function(x, ...) {
  rlang::check_dots_empty()

  per_colour <- length(x$numbers) + x$plus2 + x$skip
  box <- .mm_box_size
  cli::cli_text(
    "{.cls mm_deck_spec}: {x$size} card{?s} in {length(x$colours)} colour{?s}"
  )
  cli::cli_ul()
  cli::cli_li("colours: {.val {x$colours}}")
  cli::cli_li("number faces per colour: {.val {x$numbers}}")
  cli::cli_li("{.field +2} per colour: {x$plus2}; skip per colour: {x$skip}")
  cli::cli_li("wild cards: {x$wild}")
  cli::cli_li("cards per colour: {per_colour}")
  cli::cli_end()
  if (!identical(x$size, box)) {
    cli::cli_alert_warning(
      "Total is {x$size}, not the {box} printed on the box."
    )
  }
  invisible(x)
}
