#' Simulate many games of Mau Mau
#'
#' Runs `n` independent games under the same table setup and returns one tidy
#' row per game. This is the entry point for win-rate, game-length, and
#' draw-count analysis.
#'
#' @param n Integer; number of games to simulate.
#' @param verbose If `TRUE`, show a progress bar. Defaults to `FALSE`.
#' @inheritParams mm_play_game
#'
#' @return A [tibble::tibble()] with `n` rows: the columns of
#'   [mm_play_game()] (`winner`, `turns`, `draws`, `n_players`, `hand_sizes`,
#'   `strategy`, `trace`) preceded by `game`, an integer game id. `n = 0`
#'   yields a 0-row tibble with those columns.
#'
#' @family simulation
#' @seealso [mm_win_rate()], [mm_game_length()], and [mm_draw_summary()] for
#'   the summaries built on this table.
#'
#' @examples
#' sims <- mm_simulate(n = 20, n_players = 3, seed = 1)
#' sims
#'
#' # One strategy per seat.
#' mixed <- mm_simulate(
#'   n = 20,
#'   n_players = 3,
#'   strategies = list(
#'     mm_strategy_greedy(),
#'     mm_strategy_random(),
#'     mm_strategy_hold_wilds()
#'   ),
#'   seed = 2
#' )
#' mm_win_rate(mixed)
#'
#' @export
mm_simulate <- function(n = 100L,
                        n_players = 3L,
                        strategies = mm_strategy_greedy(),
                        spec = mm_deck_spec(),
                        hand_size = 5L,
                        max_turns = 500L,
                        announce_penalty = FALSE,
                        trace = FALSE,
                        seed = NULL,
                        verbose = FALSE,
                        call = rlang::caller_env()) {
  n <- .check_count(n, min = 0L, call = call)
  n_players <- .check_count(n_players, min = 2L, call = call)
  max_turns <- .check_count(max_turns, min = 1L, call = call)
  .check_flag(verbose, call = call)
  .check_class(spec, "mm_deck_spec", call = call)
  strategies <- .check_strategies(strategies, n_players, call = call)

  if (!is.null(seed)) {
    seed <- .check_count(seed, min = -.Machine$integer.max, call = call)
    old <- .seed_state()
    on.exit(.restore_seed(old), add = TRUE)
    set.seed(seed)
  }

  if (n == 0L) {
    return(.empty_sims())
  }

  if (verbose) {
    cli::cli_progress_bar("Simulating games", total = n)
  }
  results <- vector("list", n)
  for (i in seq_len(n)) {
    game <- mm_new_game(
      n_players = n_players,
      strategies = strategies,
      spec = spec,
      hand_size = hand_size,
      announce_penalty = announce_penalty,
      trace = trace,
      seed = NULL,
      call = call
    )
    game <- .play_out(game, max_turns, call = call)
    results[[i]] <- .game_result(game)
    if (verbose) {
      cli::cli_progress_update()
    }
  }
  if (verbose) {
    cli::cli_progress_done()
  }

  out <- dplyr::bind_rows(results)
  unfinished <- sum(is.na(out$winner))
  if (unfinished > 0L) {
    cli::cli_warn(
      c(
        "!" = "{unfinished} of {n} game{?s} ended without a winner.",
        "i" = "Raise {.arg max_turns} or check {.fn mm_deck_spec}."
      ),
      call = call
    )
  }
  dplyr::bind_cols(tibble::tibble(game = seq_len(n)), out)
}

.empty_sims <- function() {
  tibble::tibble(
    game = integer(0L),
    winner = integer(0L),
    turns = integer(0L),
    draws = integer(0L),
    n_players = integer(0L),
    hand_sizes = list(),
    strategy = list(),
    trace = list()
  )
}

# ---------------------------------------------------------------------------
# Summaries
# ---------------------------------------------------------------------------

#' Win rate by seat
#'
#' Counts wins per seat and turns them into the share of decided games each
#' seat took. Seats that never won still appear, so the table always has one
#' row per seat and player count.
#'
#' @param sims A tibble from [mm_simulate()].
#' @inheritParams mm_deck_spec
#'
#' @return A [tibble::tibble()] with one row per seat within each player
#'   count, and columns
#' \describe{
#'   \item{`n_players`}{Seats at the table (integer).}
#'   \item{`seat`}{Seat number, 1 is the first to move (integer).}
#'   \item{`strategy`}{Strategy that seat played (character).}
#'   \item{`wins`}{Games won (integer).}
#'   \item{`games`}{Games simulated at that table size (integer).}
#'   \item{`win_rate`}{Share of decided games won, summing to 1 within a
#'     player count (double); `NA` when no game was decided.}
#' }
#'
#' @family simulation
#' @seealso [mm_plot_win_rate()] for the matching chart.
#'
#' @examples
#' sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
#' mm_win_rate(sims)
#'
#' @export
mm_win_rate <- function(sims, call = rlang::caller_env()) {
  .check_sims(sims, c("winner", "n_players"), call = call)
  if (nrow(sims) == 0L) {
    return(.empty_win_rate())
  }

  sizes <- sort(unique(sims$n_players))
  parts <- lapply(sizes, function(size) {
    rows <- sims[sims$n_players == size, , drop = FALSE]
    seats <- seq_len(size)
    wins <- tabulate(rows$winner[!is.na(rows$winner)], nbins = size)
    decided <- sum(!is.na(rows$winner))
    tibble::tibble(
      n_players = rep(as.integer(size), size),
      seat = seats,
      strategy = .seat_strategies(rows, size),
      wins = as.integer(wins),
      games = rep(nrow(rows), size),
      win_rate = if (decided > 0L) wins / decided else rep(NA_real_, size)
    )
  })
  dplyr::bind_rows(parts)
}

.empty_win_rate <- function() {
  tibble::tibble(
    n_players = integer(0L),
    seat = integer(0L),
    strategy = character(0L),
    wins = integer(0L),
    games = integer(0L),
    win_rate = double(0L)
  )
}

# Per-seat strategy labels, padded to `size` so the column is always complete.
.seat_strategies <- function(rows, size) {
  labels <- rep(NA_character_, size)
  if ("strategy" %in% names(rows) && nrow(rows) > 0L) {
    first <- rows$strategy[[1L]]
    if (is.character(first) && length(first) > 0L) {
      take <- min(size, length(first))
      labels[seq_len(take)] <- first[seq_len(take)]
    }
  }
  labels
}

#' Game-length summary
#'
#' Summarises how many turns games take, by player count.
#'
#' @inheritParams mm_win_rate
#'
#' @return A [tibble::tibble()] with one row per player count and columns
#'   `n_players` (integer), `games` (integer), `mean_turns`, `sd_turns`,
#'   `min_turns`, `median_turns`, and `max_turns` (all double). A 0-row input
#'   yields a 0-row tibble with those columns.
#'
#' @family simulation
#' @seealso [mm_plot_game_length()] for the matching chart.
#'
#' @examples
#' sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
#' mm_game_length(sims)
#'
#' @export
mm_game_length <- function(sims, call = rlang::caller_env()) {
  .check_sims(sims, c("turns", "n_players"), call = call)
  if (nrow(sims) == 0L) {
    return(.empty_summary("turns"))
  }
  sims |>
    dplyr::group_by(.data$n_players) |>
    dplyr::summarise(
      games = dplyr::n(),
      mean_turns = mean(.data$turns),
      sd_turns = stats::sd(.data$turns),
      min_turns = as.double(min(.data$turns)),
      median_turns = stats::median(as.double(.data$turns)),
      max_turns = as.double(max(.data$turns)),
      .groups = "drop"
    )
}

#' Draw-count summary
#'
#' Summarises how many cards get drawn per game, by player count.
#'
#' @inheritParams mm_win_rate
#'
#' @return A [tibble::tibble()] with one row per player count and columns
#'   `n_players` (integer), `games` (integer), `mean_draws`, `sd_draws`,
#'   `min_draws`, `median_draws`, and `max_draws` (all double). A 0-row input
#'   yields a 0-row tibble with those columns.
#'
#' @family simulation
#' @seealso [mm_plot_draws()] for the matching chart.
#'
#' @examples
#' sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
#' mm_draw_summary(sims)
#'
#' @export
mm_draw_summary <- function(sims, call = rlang::caller_env()) {
  .check_sims(sims, c("draws", "n_players"), call = call)
  if (nrow(sims) == 0L) {
    return(.empty_summary("draws"))
  }
  sims |>
    dplyr::group_by(.data$n_players) |>
    dplyr::summarise(
      games = dplyr::n(),
      mean_draws = mean(.data$draws),
      sd_draws = stats::sd(.data$draws),
      min_draws = as.double(min(.data$draws)),
      median_draws = stats::median(as.double(.data$draws)),
      max_draws = as.double(max(.data$draws)),
      .groups = "drop"
    )
}

.empty_summary <- function(what) {
  out <- tibble::tibble(
    n_players = integer(0L),
    games = integer(0L),
    mean = double(0L),
    sd = double(0L),
    min = double(0L),
    median = double(0L),
    max = double(0L)
  )
  names(out) <- c(
    "n_players", "games",
    paste0(c("mean", "sd", "min", "median", "max"), "_", what)
  )
  out
}
