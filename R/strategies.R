# Low-level constructor for strategies. `move` picks a card, `color` names the
# colour to demand after a wild. Both are trusted here and validated by the
# helpers below.
new_mm_strategy <- function(name, move, color) {
  stopifnot(is.character(name), length(name) == 1L)
  stopifnot(is.function(move), is.function(color))

  structure(
    move,
    class = c("mm_strategy", "function"),
    strategy_name = name,
    color_picker = color
  )
}

# Ask a strategy for a move and validate the answer before the engine trusts
# it. Returns a single integer position into the hand, or `NA_integer_`.
.strategy_move <- function(strategy, hand, state, call = rlang::caller_env()) {
  choice <- strategy(hand, state)
  name <- attr(strategy, "strategy_name")

  if (is.null(choice) || length(choice) != 1L) {
    cli::cli_abort(
      c(
        "Strategy {.val {name}} must return a single card position or
         {.val NA}.",
        "x" = "Got {.cls {class(choice)[[1L]]}} of length {length(choice)}."
      ),
      call = call
    )
  }
  if (is.na(choice)) {
    return(NA_integer_)
  }
  if (!is.numeric(choice) || choice != trunc(choice)) {
    cli::cli_abort(
      c(
        "Strategy {.val {name}} must return a whole-number card position.",
        "x" = "Got {.val {choice}}."
      ),
      call = call
    )
  }
  choice <- as.integer(choice)
  if (!choice %in% state$legal) {
    cli::cli_abort(
      c(
        "Strategy {.val {name}} chose an illegal card.",
        "x" = "Position {choice} is not playable on the current discard.",
        "i" = "Legal position{?s}: {.val {state$legal}}."
      ),
      call = call
    )
  }
  choice
}

# Ask a strategy which colour to demand after playing a wild.
.strategy_color <- function(strategy, hand, state, call = rlang::caller_env()) {
  picker <- attr(strategy, "color_picker")
  name <- attr(strategy, "strategy_name")
  choice <- picker(hand, state)

  if (!is.character(choice) || length(choice) != 1L || is.na(choice) ||
      !choice %in% state$colours) {
    cli::cli_abort(
      c(
        "Strategy {.val {name}} must name one of the deck colours after a
         wild.",
        "x" = "Got {.val {choice}}.",
        "i" = "Deck colours: {.val {state$colours}}."
      ),
      call = call
    )
  }
  choice
}

# The colour a player holds most of; ties resolve to the first such colour.
.most_common_color <- function(hand, state) {
  colors <- hand$color[!is.na(hand$color)]
  if (length(colors) == 0L) {
    if (length(state$colours) == 0L) {
      return(NA_character_)
    }
    return(state$colours[[1L]])
  }
  counts <- vapply(
    state$colours,
    function(cl) sum(colors == cl),
    integer(1L)
  )
  state$colours[[which.max(counts)]]
}

#' Artificial strategies
#'
#' Strategies decide which card a seat plays. Each constructor returns a
#' function of class `mm_strategy` that the engine calls once per decision.
#'
#' @details
#' A strategy is a function `(hand, state)` returning the position of the card
#' to play (an index into the rows of `hand`), or `NA_integer_` to draw and
#' pass. It must only ever return a position listed in `state$legal`.
#'
#' `hand` is a [tibble::tibble()] with columns `card` (integer card id),
#' `color`, `value`, and `type`. `state` is a list with elements
#' \describe{
#'   \item{`player`}{Seat to move (integer).}
#'   \item{`n_players`}{Number of seats (integer).}
#'   \item{`turn`}{Completed turns so far (integer).}
#'   \item{`legal`}{Playable positions in `hand` (integer, possibly empty).}
#'   \item{`top`}{The discard pile's top card (one-row tibble).}
#'   \item{`active_color`}{The colour currently in force (character).}
#'   \item{`pending_draw`}{Cards stacked by unanswered `+2`s (integer).}
#'   \item{`hand_sizes`}{Cards held by each seat (integer).}
#'   \item{`draw_remaining`}{Cards left in the draw pile (integer).}
#'   \item{`discard_size`}{Cards on the discard pile (integer).}
#'   \item{`colours`}{Deck colours (character).}
#' }
#'
#' Each strategy also carries a colour picker used when it plays a wild:
#' `mm_strategy_greedy()` and `mm_strategy_hold_wilds()` demand the colour they
#' hold most of, `mm_strategy_random()` demands a uniformly random colour.
#'
#' The three supplied strategies differ only in which legal card they pick:
#' \describe{
#'   \item{`mm_strategy_greedy()`}{The first legal card in hand order.}
#'   \item{`mm_strategy_random()`}{A uniformly random legal card.}
#'   \item{`mm_strategy_hold_wilds()`}{A non-wild legal card when one exists,
#'     keeping wild cards for turns that would otherwise be a draw.}
#' }
#'
#' @return The constructors return a function of class `mm_strategy` with
#'   signature `(hand, state)`, returning a single integer card position or
#'   `NA_integer_`. `print()` returns its input invisibly.
#'
#' @family strategies
#' @seealso [mm_play_game()] and [mm_simulate()], which take strategies per
#'   seat.
#'
#' @examples
#' greedy <- mm_strategy_greedy()
#' greedy
#'
#' # Strategies are plain functions; the engine calls them per decision.
#' hand <- mm_build_deck()[1:3, ]
#' hand$card <- 1:3
#' state <- list(legal = c(1L, 3L), colours = c("red", "green", "blue",
#'                                              "yellow"))
#' greedy(hand, state)
#'
#' @name mm_strategy
NULL

#' @rdname mm_strategy
#' @export
mm_strategy_greedy <- function() {
  new_mm_strategy(
    name = "greedy",
    move = function(hand, state) {
      if (length(state$legal) == 0L) NA_integer_ else state$legal[[1L]]
    },
    color = .most_common_color
  )
}

#' @rdname mm_strategy
#' @export
mm_strategy_random <- function() {
  new_mm_strategy(
    name = "random",
    move = function(hand, state) {
      n <- length(state$legal)
      if (n == 0L) NA_integer_ else state$legal[[sample.int(n, 1L)]]
    },
    color = function(hand, state) {
      n <- length(state$colours)
      if (n == 0L) NA_character_ else state$colours[[sample.int(n, 1L)]]
    }
  )
}

#' @rdname mm_strategy
#' @export
mm_strategy_hold_wilds <- function() {
  new_mm_strategy(
    name = "hold_wilds",
    move = function(hand, state) {
      if (length(state$legal) == 0L) {
        return(NA_integer_)
      }
      plain <- state$legal[hand$type[state$legal] != "wild"]
      if (length(plain) > 0L) plain[[1L]] else state$legal[[1L]]
    },
    color = .most_common_color
  )
}

#' @param x An object of class `mm_strategy`.
#' @param ... Not used.
#' @rdname mm_strategy
#' @export
print.mm_strategy <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_text(
    "{.cls mm_strategy} {.val {attr(x, 'strategy_name')}}"
  )
  invisible(x)
}
