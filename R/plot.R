# Okabe-Ito: colourblind-safe qualitative palette.
.mm_okabe_ito <- c(
  "#0072B2", "#E69F00", "#009E73", "#CC79A7",
  "#56B4E9", "#D55E00", "#F0E442", "#999999"
)

.mm_fill <- function(n) {
  if (n <= 0L) {
    return(character(0L))
  }
  rep_len(.mm_okabe_ito, n)
}

# Expected win rate per seat if seating did not matter.
.mm_baseline <- function(sizes) {
  tibble::tibble(
    n_players = as.integer(sizes),
    expected = 1 / as.double(sizes)
  )
}

#' Plot win rate by seat
#'
#' Draws the share of decided games each seat won, with a dashed line at the
#' rate expected if seating did not matter.
#'
#' @inheritParams mm_win_rate
#'
#' @return A `ggplot` object.
#'
#' @family plots
#' @seealso [mm_win_rate()] for the underlying table.
#'
#' @examples
#' sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
#' mm_plot_win_rate(sims)
#'
#' @export
mm_plot_win_rate <- function(sims, call = rlang::caller_env()) {
  rates <- mm_win_rate(sims, call = call)
  baseline <- .mm_baseline(unique(rates$n_players))

  ggplot2::ggplot(
    rates,
    ggplot2::aes(
      x = factor(.data$seat),
      y = .data$win_rate,
      fill = factor(.data$seat)
    )
  ) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::geom_hline(
      data = baseline,
      mapping = ggplot2::aes(yintercept = .data$expected),
      linetype = "dashed",
      colour = "grey30"
    ) +
    ggplot2::facet_wrap(~ .data$n_players, labeller = ggplot2::label_both) +
    ggplot2::scale_fill_manual(values = .mm_fill(nrow(rates))) +
    ggplot2::labs(
      title = "Win rate by seat",
      subtitle = "Dashed line: the rate expected if the seat did not matter",
      x = "Seat (1 moves first)",
      y = "Share of decided games won",
      fill = "Seat"
    ) +
    ggplot2::theme_minimal()
}

#' Plot the game-length distribution
#'
#' Draws the distribution of turns per game, one panel per player count.
#'
#' @inheritParams mm_win_rate
#' @param bins Integer; number of histogram bins.
#'
#' @return A `ggplot` object.
#'
#' @family plots
#' @seealso [mm_game_length()] for the underlying summary.
#'
#' @examples
#' sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
#' mm_plot_game_length(sims)
#'
#' @export
mm_plot_game_length <- function(sims, bins = 30L, call = rlang::caller_env()) {
  .check_sims(sims, c("turns", "n_players"), call = call)
  bins <- .check_count(bins, min = 1L, call = call)

  ggplot2::ggplot(
    sims,
    ggplot2::aes(x = .data$turns, fill = factor(.data$n_players))
  ) +
    ggplot2::geom_histogram(bins = bins, colour = "white", linewidth = 0.2) +
    ggplot2::facet_wrap(~ .data$n_players, labeller = ggplot2::label_both) +
    ggplot2::scale_fill_manual(
      values = .mm_fill(length(unique(sims$n_players)))
    ) +
    ggplot2::labs(
      title = "Game length",
      subtitle = "Turns played per game",
      x = "Turns",
      y = "Games",
      fill = "Players"
    ) +
    ggplot2::theme_minimal()
}

#' Plot the draw-count distribution
#'
#' Draws the distribution of cards drawn per game, one panel per player count.
#'
#' @inheritParams mm_plot_game_length
#'
#' @return A `ggplot` object.
#'
#' @family plots
#' @seealso [mm_draw_summary()] for the underlying summary.
#'
#' @examples
#' sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
#' mm_plot_draws(sims)
#'
#' @export
mm_plot_draws <- function(sims, bins = 30L, call = rlang::caller_env()) {
  .check_sims(sims, c("draws", "n_players"), call = call)
  bins <- .check_count(bins, min = 1L, call = call)

  ggplot2::ggplot(
    sims,
    ggplot2::aes(x = .data$draws, fill = factor(.data$n_players))
  ) +
    ggplot2::geom_histogram(bins = bins, colour = "white", linewidth = 0.2) +
    ggplot2::facet_wrap(~ .data$n_players, labeller = ggplot2::label_both) +
    ggplot2::scale_fill_manual(
      values = .mm_fill(length(unique(sims$n_players)))
    ) +
    ggplot2::labs(
      title = "Cards drawn",
      subtitle = "Cards drawn by all seats together, per game",
      x = "Cards drawn",
      y = "Games",
      fill = "Players"
    ) +
    ggplot2::theme_minimal()
}

#' Compare strategies head to head
#'
#' Averages the per-seat win rate of every strategy at the table, so that a
#' strategy seated twice is not flattered by its extra seat. The dashed line
#' is the rate expected if the strategy did not matter.
#'
#' @inheritParams mm_win_rate
#'
#' @return A `ggplot` object.
#'
#' @family plots
#' @seealso [mm_simulate()] for running a mixed table.
#'
#' @examples
#' sims <- mm_simulate(
#'   n = 30,
#'   n_players = 3,
#'   strategies = list(
#'     mm_strategy_greedy(),
#'     mm_strategy_random(),
#'     mm_strategy_hold_wilds()
#'   ),
#'   seed = 3
#' )
#' mm_plot_strategy_compare(sims)
#'
#' @export
mm_plot_strategy_compare <- function(sims, call = rlang::caller_env()) {
  rates <- mm_win_rate(sims, call = call)
  if (nrow(rates) > 0L && all(is.na(rates$strategy))) {
    cli::cli_abort(
      c(
        "{.arg sims} does not record which strategy played each seat.",
        "i" = "Use the tibble returned by {.fn maumauR::mm_simulate}."
      ),
      call = call
    )
  }

  by_strategy <- rates |>
    dplyr::group_by(.data$n_players, .data$strategy) |>
    dplyr::summarise(
      seats = dplyr::n(),
      wins = sum(.data$wins),
      win_rate = mean(.data$win_rate),
      .groups = "drop"
    )
  baseline <- .mm_baseline(unique(by_strategy$n_players))

  ggplot2::ggplot(
    by_strategy,
    ggplot2::aes(
      x = stats::reorder(.data$strategy, -.data$win_rate),
      y = .data$win_rate,
      fill = .data$strategy
    )
  ) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::geom_hline(
      data = baseline,
      mapping = ggplot2::aes(yintercept = .data$expected),
      linetype = "dashed",
      colour = "grey30"
    ) +
    ggplot2::facet_wrap(~ .data$n_players, labeller = ggplot2::label_both) +
    ggplot2::scale_fill_manual(values = .mm_fill(nrow(by_strategy))) +
    ggplot2::labs(
      title = "Strategy comparison",
      subtitle = "Mean win rate per seat held by each strategy",
      x = "Strategy",
      y = "Mean win rate per seat",
      fill = "Strategy"
    ) +
    ggplot2::theme_minimal()
}
