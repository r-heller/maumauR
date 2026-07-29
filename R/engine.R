# ---------------------------------------------------------------------------
# Game state
# ---------------------------------------------------------------------------

# Low-level constructor. Trusted input only.
new_mm_game <- function(spec, deck, n_players, strategies, hands, draw,
                        discard, active_color, hand_size, announce_penalty,
                        trace) {
  structure(
    list(
      spec = spec,
      deck = deck,
      color = deck$color,
      value = deck$value,
      type = deck$type,
      n_players = n_players,
      strategies = strategies,
      hands = hands,
      draw = draw,
      discard = discard,
      active_color = active_color,
      hand_size = hand_size,
      announce_penalty = announce_penalty,
      pending_draw = 0L,
      drawn_this_turn = FALSE,
      passes = 0L,
      current = 1L,
      turn = 0L,
      draws = 0L,
      last_drawn = 0L,
      winner = NA_integer_,
      finished = FALSE,
      stalled = FALSE,
      trace_on = trace,
      trace = list()
    ),
    class = "mm_game"
  )
}

#' Start a game of Mau Mau
#'
#' Shuffles a deck, deals a hand to every seat, and turns the first card face
#' up. The returned object is the complete game state, open to inspection:
#' advance it one action at a time with [mm_step()], or play it out in one call
#' with [mm_play_game()].
#'
#' @details
#' The opening card's effect is not applied: only its colour (and value) set
#' the state, so the first seat always moves. If the opening card is a wild,
#' the colour in force is drawn at random from the deck colours.
#'
#' @param n_players Integer; number of seats. The box calls for 2 to 4.
#' @param strategies An `mm_strategy` object, or a list of them with one entry
#'   per seat. A single strategy is recycled across all seats. See
#'   [mm_strategy_greedy()].
#' @param spec A deck specification from [mm_deck_spec()].
#' @param hand_size Integer; cards dealt to each seat. The printed rules deal
#'   five.
#' @param announce_penalty If `TRUE`, a seat that plays down to one card
#'   without announcing "Mau" draws two penalty cards. Artificial strategies
#'   always announce, so this only bites interactive players. Defaults to
#'   `FALSE`.
#' @param trace If `TRUE`, record one row per step (turn, actor, action, and
#'   the card counts of every pile) for auditing. Defaults to `FALSE`.
#' @param seed Optional integer seed. The caller's random stream is restored
#'   afterwards.
#' @inheritParams mm_deck_spec
#'
#' @return An object of class `mm_game`: a list holding the deck, the hands,
#'   the draw and discard piles, the colour in force, the seat to move, and the
#'   running turn, draw, and winner counters.
#'
#' @family engine
#' @seealso [mm_step()] to advance the game, [mm_hand()] and [mm_top_card()]
#'   to inspect it.
#'
#' @examples
#' game <- mm_new_game(n_players = 3, seed = 1)
#' game
#' mm_hand(game, player = 1)
#'
#' @export
mm_new_game <- function(n_players = 3L,
                        strategies = mm_strategy_greedy(),
                        spec = mm_deck_spec(),
                        hand_size = 5L,
                        announce_penalty = FALSE,
                        trace = FALSE,
                        seed = NULL,
                        call = rlang::caller_env()) {
  n_players <- .check_count(n_players, min = 2L, call = call)
  hand_size <- .check_count(hand_size, min = 1L, call = call)
  .check_class(spec, "mm_deck_spec", call = call)
  .check_flag(announce_penalty, call = call)
  .check_flag(trace, call = call)
  strategies <- .check_strategies(strategies, n_players, call = call)

  if (!is.null(seed)) {
    seed <- .check_count(seed, min = -.Machine$integer.max, call = call)
    old <- .seed_state()
    on.exit(.restore_seed(old), add = TRUE)
    set.seed(seed)
  }

  deck <- mm_build_deck(spec, call = call)
  needed <- n_players * hand_size + 1L
  if (nrow(deck) < needed) {
    cli::cli_abort(
      c(
        "The deck is too small for this table.",
        "x" = "{nrow(deck)} card{?s} cannot deal {hand_size} each to \\
               {n_players} player{?s} plus an opening card.",
        "i" = "Increase the deck in {.fn mm_deck_spec} or lower \\
               {.arg hand_size}."
      ),
      call = call
    )
  }
  if (length(spec$colours) == 0L) {
    cli::cli_abort(
      c(
        "The deck must have at least one colour.",
        "i" = "Set {.arg colours} in {.fn mm_deck_spec}."
      ),
      call = call
    )
  }

  order <- sample.int(nrow(deck))
  hands <- vector("list", n_players)
  for (p in seq_len(n_players)) {
    hands[[p]] <- order[seq(p, by = n_players, length.out = hand_size)]
  }
  rest <- order[-seq_len(n_players * hand_size)]
  discard <- rest[[1L]]
  draw <- rest[-1L]

  active_color <- deck$color[[discard]]
  if (is.na(active_color)) {
    active_color <- spec$colours[[sample.int(length(spec$colours), 1L)]]
  }

  game <- new_mm_game(
    spec = spec,
    deck = deck,
    n_players = n_players,
    strategies = strategies,
    hands = hands,
    draw = draw,
    discard = discard,
    active_color = active_color,
    hand_size = hand_size,
    announce_penalty = announce_penalty,
    trace = trace
  )
  .trace(game, "deal")
}

# ---------------------------------------------------------------------------
# Accessors
# ---------------------------------------------------------------------------

#' Inspect a game in progress
#'
#' Accessors for the pieces of an `mm_game` a player or an interface needs:
#' the cards a seat holds, the positions it may legally play, and the card on
#' top of the discard pile.
#'
#' @param game An `mm_game` object from [mm_new_game()].
#' @param player Integer; the seat to inspect. Defaults to the seat to move.
#' @inheritParams mm_deck_spec
#'
#' @return
#' `mm_hand()` returns a [tibble::tibble()] with one row per held card and
#' columns `card` (integer card id), `color` (character), `value` (integer),
#' `type` (character), and `legal` (logical, whether the card could be played
#' on the current discard). A seat with no cards yields a 0-row tibble.
#'
#' `mm_legal_moves()` returns an integer vector of row positions into
#' `mm_hand()`, empty when nothing is playable - never `NULL`.
#'
#' `mm_top_card()` returns a one-row [tibble::tibble()] with columns `color`,
#' `value`, `type`, and `active_color` (the colour in force, which differs
#' from `color` after a wild).
#'
#' @family engine
#' @seealso [mm_step()] to play one of the legal moves.
#'
#' @examples
#' game <- mm_new_game(n_players = 3, seed = 42)
#' mm_top_card(game)
#' mm_hand(game)
#' mm_legal_moves(game)
#'
#' @export
mm_hand <- function(game, player = game$current, call = rlang::caller_env()) {
  .check_class(game, "mm_game", call = call)
  player <- .check_player(game, player, call = call)

  .hand_tbl(game, game$hands[[player]])
}

# Hand table without the validation overhead: the engine builds one of these
# per decision, so it uses the unchecked tibble constructor.
.hand_tbl <- function(game, ids) {
  tibble::new_tibble(
    list(
      card = as.integer(ids),
      color = game$color[ids],
      value = game$value[ids],
      type = game$type[ids],
      legal = .is_legal(game, ids)
    ),
    nrow = length(ids)
  )
}

.top_tbl <- function(game) {
  top <- game$discard[[length(game$discard)]]
  tibble::new_tibble(
    list(
      color = game$color[[top]],
      value = game$value[[top]],
      type = game$type[[top]],
      active_color = game$active_color
    ),
    nrow = 1L
  )
}

#' @rdname mm_hand
#' @export
mm_legal_moves <- function(game,
                           player = game$current,
                           call = rlang::caller_env()) {
  .check_class(game, "mm_game", call = call)
  player <- .check_player(game, player, call = call)
  which(.is_legal(game, game$hands[[player]]))
}

#' @rdname mm_hand
#' @export
mm_top_card <- function(game, call = rlang::caller_env()) {
  .check_class(game, "mm_game", call = call)
  .top_tbl(game)
}

#' @param x An object of class `mm_game`.
#' @param ... Not used.
#' @rdname mm_new_game
#' @export
print.mm_game <- function(x, ...) {
  rlang::check_dots_empty()

  top <- mm_top_card(x)
  cli::cli_text(
    "{.cls mm_game}: {x$n_players} player{?s}, turn {x$turn}"
  )
  cli::cli_ul()
  cli::cli_li(
    "top card: {.val {top$type}} {.val {top$color}} \\
     (colour in force: {.val {x$active_color}})"
  )
  cli::cli_li("hand sizes: {.val {lengths(x$hands)}}")
  cli::cli_li("draw pile: {length(x$draw)}; discard pile: {length(x$discard)}")
  if (x$pending_draw > 0L) {
    cli::cli_li("stacked draw penalty: {x$pending_draw}")
  }
  if (x$finished) {
    if (is.na(x$winner)) {
      cli::cli_li("finished without a winner (no legal moves remained)")
    } else {
      cli::cli_li("winner: seat {x$winner}")
    }
  } else {
    cli::cli_li("to move: seat {x$current}")
  }
  cli::cli_end()
  invisible(x)
}

# ---------------------------------------------------------------------------
# Internal state helpers
# ---------------------------------------------------------------------------

.check_player <- function(game, player, call = rlang::caller_env()) {
  player <- .check_count(player, min = 1L, max = game$n_players, call = call)
  player
}

# Which of `ids` may be played on the current discard?
.is_legal <- function(game, ids) {
  if (length(ids) == 0L) {
    return(logical(0L))
  }
  type <- game$type[ids]
  if (game$pending_draw > 0L) {
    return(type == "plus2")
  }

  top <- game$discard[[length(game$discard)]]
  top_type <- game$type[[top]]
  top_value <- game$value[[top]]

  color <- game$color[ids]
  value <- game$value[ids]

  legal <- type == "wild"
  legal <- legal | (!is.na(color) & color == game$active_color)
  if (top_type == "number" && !is.na(top_value)) {
    legal <- legal | (type == "number" & !is.na(value) & value == top_value)
  }
  if (top_type %in% c("plus2", "skip")) {
    legal <- legal | type == top_type
  }
  legal
}

.next_player <- function(game, steps = 1L) {
  ((game$current - 1L + steps) %% game$n_players) + 1L
}

.state <- function(game, player, legal) {
  list(
    player = player,
    n_players = game$n_players,
    turn = game$turn,
    legal = legal,
    top = .top_tbl(game),
    active_color = game$active_color,
    pending_draw = game$pending_draw,
    hand_sizes = lengths(game$hands),
    draw_remaining = length(game$draw),
    discard_size = length(game$discard),
    colours = game$spec$colours
  )
}

# Move the discard pile back under the draw pile, keeping the top card face up.
.reshuffle <- function(game) {
  n_discard <- length(game$discard)
  if (n_discard <= 1L) {
    return(game)
  }
  recycled <- game$discard[-n_discard]
  game$discard <- game$discard[n_discard]
  game$draw <- c(game$draw, recycled[sample.int(length(recycled))])
  game
}

# Draw up to `n` cards for `player`; returns the game and records how many
# cards were actually available.
.draw_cards <- function(game, player, n) {
  taken <- 0L
  while (taken < n) {
    if (length(game$draw) == 0L) {
      game <- .reshuffle(game)
    }
    if (length(game$draw) == 0L) {
      break
    }
    game$hands[[player]] <- c(game$hands[[player]], game$draw[[1L]])
    game$draw <- game$draw[-1L]
    taken <- taken + 1L
  }
  game$draws <- game$draws + taken
  game$last_drawn <- taken
  game
}

.end_turn <- function(game, steps = 1L) {
  game$turn <- game$turn + 1L
  game$drawn_this_turn <- FALSE
  game$current <- .next_player(game, steps)
  game
}

# Append one row to the audit trail. Cheap when tracing is off.
.trace <- function(game, action, player = game$current) {
  if (!isTRUE(game$trace_on)) {
    return(game)
  }
  n_hands <- sum(lengths(game$hands))
  game$trace[[length(game$trace) + 1L]] <- list(
    turn = game$turn,
    player = as.integer(player),
    action = action,
    hand_cards = as.integer(n_hands),
    draw_pile = length(game$draw),
    discard_pile = length(game$discard),
    total = as.integer(n_hands + length(game$draw) + length(game$discard))
  )
  game
}

# The audit trail as a tidy tibble. Always the same columns, 0 rows when
# tracing was off.
.trace_tbl <- function(game) {
  records <- game$trace
  tibble::tibble(
    turn = vapply(records, function(r) as.integer(r$turn), integer(1L)),
    player = vapply(records, function(r) r$player, integer(1L)),
    action = vapply(records, function(r) r$action, character(1L)),
    hand_cards = vapply(records, function(r) r$hand_cards, integer(1L)),
    draw_pile = vapply(records, function(r) r$draw_pile, integer(1L)),
    discard_pile = vapply(records, function(r) r$discard_pile, integer(1L)),
    total = vapply(records, function(r) r$total, integer(1L))
  )
}

# ---------------------------------------------------------------------------
# One step of play
# ---------------------------------------------------------------------------

#' Advance a game by one action
#'
#' Plays a single action for the seat to move: either play a card, or draw.
#' Leave `card` at `NULL` to let the seat's strategy decide, which is what
#' [mm_play_game()] does; pass a position to play a specific card, which is
#' what an interactive front end does.
#'
#' @details
#' A turn is at most two actions. A seat with no legal card draws one; if the
#' drawn card is playable the seat may still play it, otherwise the turn ends
#' immediately. A seat that has already drawn and does not play passes.
#'
#' `+2` cards stack: the penalty accumulates while seats keep answering with a
#' `+2` of their own, and the first seat that cannot (or will not) answer draws
#' the whole pile and loses its turn. While a penalty is pending, `+2` cards
#' are the only legal play - a wild does not cancel it.
#'
#' @param game An `mm_game` object from [mm_new_game()].
#' @param card Position of the card to play within [mm_hand()], `NA` to draw
#'   or pass, or `NULL` (the default) to let the seat's strategy choose.
#' @param color Colour to demand when playing a wild. `NULL` (the default)
#'   asks the seat's strategy.
#' @param announce Set to `FALSE` to omit the "Mau" call when a play leaves one
#'   card in hand. Only matters when the game was created with
#'   `announce_penalty = TRUE`.
#' @inheritParams mm_deck_spec
#'
#' @return The updated `mm_game` object.
#'
#' @family engine
#' @seealso [mm_play_game()] to run a whole game, [mm_legal_moves()] to see
#'   what is playable.
#'
#' @examples
#' game <- mm_new_game(n_players = 3, seed = 42)
#' game <- mm_step(game)
#' mm_top_card(game)
#'
#' # Play a specific card interactively.
#' legal <- mm_legal_moves(game)
#' if (length(legal) > 0) {
#'   game <- mm_step(game, card = legal[[1]], color = "red")
#' }
#'
#' @export
mm_step <- function(game,
                    card = NULL,
                    color = NULL,
                    announce = TRUE,
                    call = rlang::caller_env()) {
  .check_class(game, "mm_game", call = call)
  .check_flag(announce, call = call)
  if (game$finished) {
    cli::cli_abort(
      c(
        "The game is already finished.",
        "i" = "Start a new one with {.fn maumauR::mm_new_game}."
      ),
      call = call
    )
  }

  player <- game$current
  ids <- game$hands[[player]]
  legal <- which(.is_legal(game, ids))

  if (is.null(card)) {
    card <- .strategy_move(
      game$strategies[[player]],
      .hand_tbl(game, ids),
      .state(game, player, legal),
      call = call
    )
  } else {
    card <- .check_card(card, length(ids), call = call)
  }

  if (is.na(card)) {
    return(.do_draw(game, player))
  }
  if (!card %in% legal) {
    cli::cli_abort(
      c(
        "That card cannot be played on the current discard.",
        "x" = "Position {card} is not legal for seat {player}.",
        "i" = "Legal position{?s}: {.val {legal}}."
      ),
      call = call
    )
  }
  .do_play(game, player, card, color, announce, call = call)
}

.check_card <- function(card, n_cards, call = rlang::caller_env()) {
  if (length(card) != 1L) {
    cli::cli_abort(
      c(
        "{.arg card} must be a single card position or {.val NA}.",
        "x" = "Got a value of length {length(card)}."
      ),
      call = call
    )
  }
  if (is.na(card)) {
    return(NA_integer_)
  }
  card <- .check_count(card, min = 1L, max = n_cards, call = call)
  card
}

.do_draw <- function(game, player) {
  if (game$pending_draw > 0L) {
    penalty <- game$pending_draw
    game <- .draw_cards(game, player, penalty)
    game$pending_draw <- 0L
    game$passes <- 0L
    game <- .end_turn(game)
    return(.trace(game, "draw_penalty", player = player))
  }

  if (!game$drawn_this_turn) {
    game <- .draw_cards(game, player, 1L)
    if (game$last_drawn == 0L) {
      # Nothing left to draw anywhere: the seat can only pass.
      game$passes <- game$passes + 1L
      game <- .end_turn(game)
      game <- .trace(game, "pass", player = player)
      return(.check_stall(game))
    }
    game$passes <- 0L
    game$drawn_this_turn <- TRUE
    if (!any(.is_legal(game, game$hands[[player]]))) {
      game <- .end_turn(game)
      return(.trace(game, "draw", player = player))
    }
    return(.trace(game, "draw", player = player))
  }

  game$passes <- game$passes + 1L
  game <- .end_turn(game)
  game <- .trace(game, "pass", player = player)
  .check_stall(game)
}

# Every seat in turn passed without being able to draw: the game cannot end.
.check_stall <- function(game) {
  if (game$passes >= game$n_players) {
    game$finished <- TRUE
    game$stalled <- TRUE
  }
  game
}

.do_play <- function(game, player, card, color, announce,
                     call = rlang::caller_env()) {
  ids <- game$hands[[player]]
  id <- ids[[card]]
  type <- game$type[[id]]

  game$hands[[player]] <- ids[-card]
  game$discard <- c(game$discard, id)
  game$passes <- 0L

  if (type == "wild") {
    if (is.null(color)) {
      color <- .strategy_color(
        game$strategies[[player]],
        .hand_tbl(game, game$hands[[player]]),
        .state(game, player, integer(0L)),
        call = call
      )
    } else {
      .check_string(color, call = call)
      if (!color %in% game$spec$colours) {
        cli::cli_abort(
          c(
            "{.arg color} must be one of the deck colours.",
            "x" = "Got {.val {color}}.",
            "i" = "Deck colours: {.val {game$spec$colours}}."
          ),
          call = call
        )
      }
    }
    game$active_color <- color
  } else {
    game$active_color <- game$color[[id]]
  }

  # House rule: forgetting to call "Mau" on the second-to-last card costs two.
  if (game$announce_penalty && length(game$hands[[player]]) == 1L &&
      !isTRUE(announce)) {
    game <- .draw_cards(game, player, 2L)
    game <- .trace(game, "mau_penalty", player = player)
  }

  if (length(game$hands[[player]]) == 0L) {
    game$winner <- as.integer(player)
    game$finished <- TRUE
    game$turn <- game$turn + 1L
    return(.trace(game, paste0("win_", type), player = player))
  }

  if (type == "plus2") {
    game$pending_draw <- game$pending_draw + 2L
    game <- .end_turn(game, steps = 1L)
  } else if (type == "skip") {
    game <- .end_turn(game, steps = 2L)
  } else {
    game <- .end_turn(game, steps = 1L)
  }
  .trace(game, paste0("play_", type), player = player)
}

# ---------------------------------------------------------------------------
# Whole games
# ---------------------------------------------------------------------------

#' Play one complete game of Mau Mau
#'
#' Deals a game and plays it to the end with artificial opponents, returning a
#' one-row record of the outcome.
#'
#' @param max_turns Integer; the turn cap that stops a game which cannot
#'   finish. Reaching it warns and returns a game with no winner.
#' @inheritParams mm_new_game
#'
#' @return A one-row [tibble::tibble()] with columns
#' \describe{
#'   \item{`winner`}{Winning seat (integer), `NA` if the game did not finish.}
#'   \item{`turns`}{Turns played (integer).}
#'   \item{`draws`}{Cards drawn by all seats together (integer).}
#'   \item{`n_players`}{Seats at the table (integer).}
#'   \item{`hand_sizes`}{List column; per-seat cards left at the end
#'     (integer).}
#'   \item{`strategy`}{List column; per-seat strategy names (character).}
#'   \item{`trace`}{List column; the audit trail as a tibble with columns
#'     `turn`, `player`, `action`, `hand_cards`, `draw_pile`, `discard_pile`,
#'     and `total`. 0 rows unless `trace = TRUE`.}
#' }
#'
#' @family engine
#' @seealso [mm_simulate()] to repeat this many times, [mm_new_game()] and
#'   [mm_step()] for turn-by-turn control.
#'
#' @examples
#' mm_play_game(n_players = 3, seed = 1)
#'
#' # The audit trail lets you check that no card is lost or duplicated.
#' one <- mm_play_game(n_players = 2, seed = 7, trace = TRUE)
#' unique(one$trace[[1]]$total)
#'
#' @export
mm_play_game <- function(n_players = 3L,
                         strategies = mm_strategy_greedy(),
                         spec = mm_deck_spec(),
                         hand_size = 5L,
                         max_turns = 500L,
                         announce_penalty = FALSE,
                         trace = FALSE,
                         seed = NULL,
                         call = rlang::caller_env()) {
  max_turns <- .check_count(max_turns, min = 1L, call = call)

  game <- mm_new_game(
    n_players = n_players,
    strategies = strategies,
    spec = spec,
    hand_size = hand_size,
    announce_penalty = announce_penalty,
    trace = trace,
    seed = seed,
    call = call
  )

  game <- .play_out(game, max_turns, call = call)
  .warn_unfinished(game, max_turns, call = call)
  .game_result(game)
}

# Run the turn loop. The step cap is a second belt against a pathological deck
# that could otherwise spin inside a single turn.
.play_out <- function(game, max_turns, call = rlang::caller_env()) {
  steps <- 0L
  max_steps <- 4L * max_turns
  while (!game$finished && game$turn < max_turns && steps < max_steps) {
    game <- mm_step(game, call = call)
    steps <- steps + 1L
  }
  game
}

.warn_unfinished <- function(game, max_turns, call = rlang::caller_env()) {
  if (!game$finished) {
    cli::cli_warn(
      c(
        "!" = "The game hit the {.arg max_turns} cap of {max_turns} without a
               winner.",
        "i" = "Raise {.arg max_turns} or check the deck specification."
      ),
      call = call
    )
  } else if (game$stalled) {
    cli::cli_warn(
      c(
        "!" = "The game ended without a winner: no seat could draw or play.",
        "i" = "This deck cannot finish a game with {game$n_players} seats;
               check {.fn mm_deck_spec}."
      ),
      call = call
    )
  }
  invisible(game)
}

.game_result <- function(game) {
  tibble::tibble(
    winner = as.integer(game$winner),
    turns = as.integer(game$turn),
    draws = as.integer(game$draws),
    n_players = as.integer(game$n_players),
    hand_sizes = list(as.integer(lengths(game$hands))),
    strategy = list(.strategy_names(game$strategies)),
    trace = list(.trace_tbl(game))
  )
}

.strategy_names <- function(strategies) {
  vapply(
    strategies,
    function(s) attr(s, "strategy_name") %||% NA_character_,
    character(1L)
  )
}
