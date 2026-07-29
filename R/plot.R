# ---------------------------------------------------------------------------
# Look and feel
#
# One palette, one theme, one set of helpers, shared by every plot the package
# draws. Data are always coloured with Okabe-Ito, which is colourblind-safe;
# the suite accent is reserved for furniture (facet strips), never for data.
# ---------------------------------------------------------------------------

# Okabe-Ito: colourblind-safe qualitative palette.
.mm_okabe_ito <- c(
  "#0072B2", "#E69F00", "#009E73", "#CC79A7",
  "#56B4E9", "#D55E00", "#F0E442", "#999999"
)

# The fill for a plot that distinguishes nothing. A histogram's panels are
# already named by their strip, so colouring them by player count would encode
# the facet variable twice and, worse, would make "#0072B2" mean "seat 1" in
# one of the package's figures and "2 players" in the next.
.mm_plain <- .mm_okabe_ito[[1L]]

# Suite accent and its tint, plus the neutrals the theme writes in.
.mm_accent <- "#5E2C8E"
.mm_accent_tint <- "#F1ECF8"
.mm_ink <- "#1B2A3B"
.mm_ink_soft <- "#5B6675"
.mm_rule <- "#3F3F46"
.mm_grid <- "#E6E8EC"

# `n` fills for `n` levels of a discrete scale.
.mm_fill <- function(n) {
  if (n <= 0L) {
    return(character(0L))
  }
  rep_len(.mm_okabe_ito, n)
}

# Proportions as percentages. Keeps `NA` as `NA` so that `geom_text()` can drop
# undecided seats instead of printing "NA%".
.mm_pct <- function(x, digits = 0L) {
  out <- rep(NA_character_, length(x))
  ok <- !is.na(x)
  out[ok] <- paste0(formatC(100 * x[ok], format = "f", digits = digits), "%")
  out
}

# "hold_wilds" -> "Hold wilds".
.mm_strategy_label <- function(x) {
  pretty <- gsub("_", " ", x)
  substr(pretty, 1L, 1L) <- toupper(substr(pretty, 1L, 1L))
  pretty
}

# Facet strips that read "3 players" rather than "n_players: 3".
.mm_player_labeller <- function() {
  ggplot2::as_labeller(function(x) paste0(x, " players"))
}

# One panel per player count - but a single player count needs no strip. A
# lone full-width band that says "3 players" is furniture, not information, and
# in a 400 px application card it costs a tenth of the plot's height; the
# caption carries the table size instead.
.mm_facet <- function(sims, ...) {
  if (length(unique(sims$n_players)) <= 1L) {
    return(NULL)
  }
  ggplot2::facet_wrap(
    ~ .data$n_players,
    labeller = .mm_player_labeller(),
    ...
  )
}

# A caption that says what the picture rests on, and - when there is only one
# of them - which table size it rests on.
.mm_games_caption <- function(sims) {
  n <- nrow(sims)
  if (n == 0L) {
    return(NULL)
  }
  games <- format(n, big.mark = ",", trim = TRUE)
  sizes <- unique(sims$n_players)
  if (length(sizes) > 1L) {
    sprintf(
      "%s simulated games across %d table sizes.",
      games,
      length(sizes)
    )
  } else {
    sprintf("%d players, %s simulated games.", as.integer(sizes[[1L]]), games)
  }
}

# Value labels are sized from the theme's base size, in points, so that they
# never drift away from the axis text they are read beside. `size` in a
# `geom_text()` is in millimetres, hence the division.
#
# A label sitting inside its bar has to fit the bar's width, so panels holding
# more than four bars take a smaller label: at six seats a facet is about nine
# millimetres per slot, and "26%" set at the full size overruns it.
.mm_label_size <- function(base_size = 11, bars = 1L) {
  scale <- if (bars > 4L) 0.78 else 0.9
  scale * base_size / ggplot2::.pt
}

# The most bars any one panel has to hold.
.mm_bars_per_panel <- function(panel) {
  if (length(panel) == 0L) {
    return(1L)
  }
  max(1L, max(table(panel)))
}

# Where a bar's value label goes.
#
# At the bar's *base*, inside, in white. The far end of a bar is the one place
# a label cannot go: the dashed reference line sits at 1/n and the bars cluster
# around it, so a label at the bar end is struck through by the line - which is
# exactly what happened at every size we rendered. The base is always empty.
#
# A bar too short to hold its own label carries it just beyond its end in ink.
# "Too short" is judged against the tallest bar *in the same panel*: judged
# against the tallest bar anywhere, a panel of small values ends up with some
# labels inside and some outside for no reason a reader can see.
.mm_label_inside <- function(values, panel, fraction = 0.2) {
  inside <- rep(FALSE, length(values))
  ok <- !is.na(values)
  if (!any(ok)) {
    return(inside)
  }
  keys <- as.character(panel[ok])
  top <- tapply(values[ok], keys, max)
  inside[ok] <- values[ok] >= fraction * as.double(top[keys])
  inside
}

.mm_label_colours <- function() {
  ggplot2::scale_colour_manual(
    values = c("TRUE" = "#FFFFFF", "FALSE" = .mm_ink),
    guide = "none"
  )
}

# Expected win rate per seat if seating did not matter.
.mm_baseline <- function(sizes) {
  tibble::tibble(
    n_players = as.integer(sizes),
    expected = 1 / as.double(sizes)
  )
}

#' The package plot theme
#'
#' The theme every `mm_plot_*()` function draws in: a light look with one faint
#' rule per axis break and none between them, a clear typographic hierarchy,
#' facet strips in the suite accent, and no legend. Add it to a `ggplot` of your
#' own to match the package's figures.
#'
#' @param base_size Base font size in points.
#'
#' @return A `ggplot2` theme object.
#'
#' @family plots
#'
#' @examples
#' deck <- mm_build_deck()
#' ggplot2::ggplot(deck, ggplot2::aes(x = type)) +
#'   ggplot2::geom_bar(fill = "#0072B2") +
#'   ggplot2::labs(title = "The deck", x = NULL, y = "Cards") +
#'   mm_theme()
#'
#' @export
mm_theme <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = .mm_ink),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title = ggplot2::element_text(
        face = "bold",
        size = ggplot2::rel(1.2),
        colour = .mm_ink,
        margin = ggplot2::margin(b = 3)
      ),
      plot.subtitle = ggplot2::element_text(
        size = ggplot2::rel(0.95),
        colour = .mm_ink_soft,
        margin = ggplot2::margin(b = 11)
      ),
      plot.caption = ggplot2::element_text(
        size = ggplot2::rel(0.78),
        colour = .mm_ink_soft,
        hjust = 0,
        margin = ggplot2::margin(t = 11)
      ),
      plot.margin = ggplot2::margin(10, 12, 8, 10),
      axis.title = ggplot2::element_text(
        size = ggplot2::rel(0.92),
        colour = .mm_ink_soft
      ),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 7)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 7)),
      axis.text = ggplot2::element_text(
        size = ggplot2::rel(0.88),
        colour = .mm_ink_soft
      ),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(
        colour = .mm_grid,
        linewidth = 0.3
      ),
      panel.spacing = ggplot2::unit(15, "pt"),
      strip.text = ggplot2::element_text(
        face = "bold",
        size = ggplot2::rel(0.88),
        colour = .mm_accent,
        margin = ggplot2::margin(4, 7, 4, 7)
      ),
      strip.background = ggplot2::element_rect(
        fill = .mm_accent_tint,
        colour = NA
      ),
      legend.position = "none"
    )
}

# The dashed "this is what chance looks like" rule.
.mm_reference_line <- function(baseline, horizontal = TRUE) {
  mapping <- if (horizontal) {
    ggplot2::aes(yintercept = .data$expected)
  } else {
    ggplot2::aes(xintercept = .data$expected)
  }
  geom <- if (horizontal) ggplot2::geom_hline else ggplot2::geom_vline
  geom(
    data = baseline,
    mapping = mapping,
    linetype = "22",
    linewidth = 0.45,
    colour = .mm_rule
  )
}

# ---------------------------------------------------------------------------
# Plots
# ---------------------------------------------------------------------------

#' Plot win rate by seat
#'
#' Draws the share of decided games each seat won, with a dashed line at the
#' rate expected if seating did not matter. Several player counts get a panel
#' each; a single player count is drawn without a strip and named in the
#' caption instead. Each bar carries its rate at its base, and the caption
#' records how many games the picture rests on.
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
  rates$inside <- .mm_label_inside(rates$win_rate, rates$n_players)
  baseline <- .mm_baseline(unique(rates$n_players))
  seats <- max(1L, length(unique(rates$seat)))
  bars <- .mm_bars_per_panel(rates$n_players)

  ggplot2::ggplot(
    rates,
    ggplot2::aes(
      x = factor(.data$seat),
      y = .data$win_rate,
      fill = factor(.data$seat)
    )
  ) +
    ggplot2::geom_col(width = 0.68) +
    .mm_reference_line(baseline) +
    ggplot2::geom_text(
      mapping = ggplot2::aes(
        y = ifelse(.data$inside, 0, .data$win_rate),
        label = .mm_pct(.data$win_rate),
        colour = .data$inside
      ),
      vjust = -0.6,
      size = .mm_label_size(bars = bars),
      na.rm = TRUE
    ) +
    .mm_label_colours() +
    .mm_facet(sims, scales = "free_x") +
    ggplot2::scale_fill_manual(values = .mm_fill(seats), guide = "none") +
    ggplot2::scale_y_continuous(
      labels = .mm_pct,
      expand = ggplot2::expansion(mult = c(0, 0.12))
    ) +
    ggplot2::labs(
      title = "Win rate by seat",
      subtitle = "Dashed line: no seat advantage",
      x = "Seat (1 moves first)",
      y = "Share of decided games",
      caption = .mm_games_caption(sims)
    ) +
    mm_theme() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank())
}

#' Plot the game-length distribution
#'
#' Draws the distribution of turns per game, one panel per player count, with
#' a dashed line at each panel's median. The x scale is shared, so the panels
#' can be compared directly. A single player count is drawn without a strip and
#' named in the caption instead.
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

  .mm_histogram(
    sims,
    column = "turns",
    bins = bins,
    title = "Game length",
    subtitle = "Turns per game, dashed line: median",
    x = "Turns"
  )
}

#' Plot the draw-count distribution
#'
#' Draws the distribution of cards drawn per game, one panel per player count,
#' with a dashed line at each panel's median. A single player count is drawn
#' without a strip and named in the caption instead.
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

  .mm_histogram(
    sims,
    column = "draws",
    bins = bins,
    title = "Cards drawn",
    subtitle = "Per game, dashed line: median",
    x = "Cards drawn by all seats"
  )
}

# Both distribution plots are the same picture of a different column.
.mm_histogram <- function(sims, column, bins, title, subtitle, x) {
  medians <- if (nrow(sims) > 0L) {
    sims |>
      dplyr::group_by(.data$n_players) |>
      dplyr::summarise(
        middle = stats::median(as.double(.data[[column]])),
        .groups = "drop"
      )
  } else {
    tibble::tibble(n_players = integer(0L), middle = double(0L))
  }

  ggplot2::ggplot(sims, ggplot2::aes(x = .data[[column]])) +
    ggplot2::geom_histogram(
      bins = bins,
      fill = .mm_plain,
      colour = "white",
      linewidth = 0.18
    ) +
    ggplot2::geom_vline(
      data = medians,
      mapping = ggplot2::aes(xintercept = .data$middle),
      linetype = "22",
      linewidth = 0.45,
      colour = .mm_rule
    ) +
    .mm_facet(sims) +
    ggplot2::scale_y_continuous(
      expand = ggplot2::expansion(mult = c(0, 0.08))
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = x,
      y = "Games",
      caption = .mm_games_caption(sims)
    ) +
    mm_theme()
}

#' Compare strategies head to head
#'
#' Averages the per-seat win rate of every strategy at the table, so that a
#' strategy seated twice is not flattered by its extra seat. Bars run
#' horizontally and share one order across panels - by overall mean win rate -
#' so a strategy keeps its row and its colour from panel to panel. The dashed
#' line is the rate expected if the strategy did not matter.
#'
#' Each panel scales its own x axis. A win rate at a two-player table is not
#' comparable with one at a four-player table - chance alone pays 50 % against
#' 25 % - so what a reader should compare is each bar against its own panel's
#' dashed line, and a shared axis would only leave the larger tables squeezed
#' into a third of their width. A strategy that did not sit at a given table
#' size is marked as such, so that an absent bar is not read as a zero.
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
    ) |>
    dplyr::mutate(label = .mm_strategy_label(.data$strategy))

  # Rows are ordered by overall mean win rate, but a strategy's fill is keyed to
  # its name, so that "Greedy" is the same colour whatever it happens to score.
  order <- by_strategy |>
    dplyr::group_by(.data$label) |>
    dplyr::summarise(overall = mean(.data$win_rate), .groups = "drop") |>
    dplyr::arrange(.data$overall)
  rows <- order$label
  fills <- .mm_fill(length(rows))
  names(fills) <- sort(rows)

  by_strategy$label <- factor(by_strategy$label, levels = rows)
  by_strategy$inside <- .mm_label_inside(
    by_strategy$win_rate,
    by_strategy$n_players
  )
  baseline <- .mm_baseline(unique(by_strategy$n_players))
  absent <- .mm_absent(by_strategy, rows)
  bars <- .mm_bars_per_panel(by_strategy$n_players)

  ggplot2::ggplot(
    by_strategy,
    ggplot2::aes(
      x = .data$win_rate,
      y = .data$label,
      fill = .data$label
    )
  ) +
    ggplot2::geom_col(width = 0.66) +
    .mm_reference_line(baseline, horizontal = FALSE) +
    ggplot2::geom_text(
      mapping = ggplot2::aes(
        # Horizontal bars have room for a decimal, and need it: two strategies
        # a few tenths apart draw visibly different bars, so rounding them to
        # the same whole percent would read as a mistake. The vertical seat
        # bars cannot spare the width and round to whole percentages.
        x = ifelse(.data$inside, 0, .data$win_rate),
        label = .mm_pct(.data$win_rate, digits = 1L),
        colour = .data$inside
      ),
      hjust = -0.3,
      size = .mm_label_size(bars = bars),
      na.rm = TRUE
    ) +
    .mm_label_colours() +
    ggplot2::geom_text(
      data = absent,
      mapping = ggplot2::aes(x = -Inf, y = .data$label),
      inherit.aes = FALSE,
      label = "not at this table",
      hjust = -0.06,
      size = .mm_label_size(bars = bars) * 0.88,
      colour = .mm_ink_soft,
      fontface = "italic"
    ) +
    .mm_facet(sims, scales = "free_x") +
    ggplot2::scale_fill_manual(values = fills, guide = "none") +
    ggplot2::scale_x_continuous(
      labels = .mm_pct,
      expand = ggplot2::expansion(mult = c(0, 0.14))
    ) +
    ggplot2::labs(
      title = "Strategy comparison",
      subtitle = "Dashed line: no strategy edge",
      x = "Mean win rate per seat held",
      y = NULL,
      caption = .mm_games_caption(sims)
    ) +
    mm_theme() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.spacing.x = ggplot2::unit(20, "pt")
    )
}

# The (player count, strategy) pairs that never sat down together. Without a
# mark, their empty row is indistinguishable from a strategy that won nothing.
.mm_absent <- function(by_strategy, rows) {
  full <- expand.grid(
    n_players = unique(by_strategy$n_players),
    label = rows,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  seated <- tibble::tibble(
    n_players = by_strategy$n_players,
    label = as.character(by_strategy$label)
  )
  gap <- dplyr::anti_join(full, seated, by = c("n_players", "label"))
  gap$label <- factor(gap$label, levels = rows)
  tibble::as_tibble(gap)
}
