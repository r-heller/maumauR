test_sims <- function() {
  mm_simulate(n = 20, n_players = 3, seed = 1)
}

mixed_sims <- function() {
  mm_simulate(
    n = 20,
    n_players = 3,
    strategies = list(
      mm_strategy_greedy(),
      mm_strategy_random(),
      mm_strategy_hold_wilds()
    ),
    seed = 2
  )
}

test_that("every plot function returns a ggplot object", {
  sims <- test_sims()

  expect_s3_class(mm_plot_win_rate(sims), "ggplot")
  expect_s3_class(mm_plot_game_length(sims), "ggplot")
  expect_s3_class(mm_plot_draws(sims), "ggplot")
  expect_s3_class(mm_plot_strategy_compare(mixed_sims()), "ggplot")
})

test_that("plots carry labels rather than raw column names", {
  labels <- mm_plot_win_rate(test_sims())$labels

  expect_true(nzchar(labels$title))
  expect_true(nzchar(labels$x))
  expect_true(nzchar(labels$y))
})

test_that("plots build without warnings", {
  sims <- test_sims()

  expect_silent(ggplot2::ggplot_build(mm_plot_win_rate(sims)))
  expect_silent(ggplot2::ggplot_build(mm_plot_game_length(sims, bins = 10)))
  expect_silent(ggplot2::ggplot_build(mm_plot_draws(sims, bins = 10)))
  expect_silent(ggplot2::ggplot_build(mm_plot_strategy_compare(mixed_sims())))
})

test_that("plots cope with several player counts at once", {
  sims <- dplyr::bind_rows(
    mm_simulate(n = 10, n_players = 2, seed = 5),
    mm_simulate(n = 10, n_players = 4, seed = 5)
  )

  expect_s3_class(mm_plot_win_rate(sims), "ggplot")
  expect_s3_class(mm_plot_game_length(sims, bins = 8), "ggplot")
})

test_that("plot functions validate their input", {
  expect_error(mm_plot_win_rate("nope"), "data frame")
  expect_error(mm_plot_game_length(tibble::tibble(x = 1)), "missing required")
  expect_error(mm_plot_draws(tibble::tibble(x = 1)), "missing required")
  expect_error(mm_plot_game_length(test_sims(), bins = 0), "between")
})

test_that("mm_plot_strategy_compare() needs strategy labels", {
  sims <- test_sims()
  sims$strategy <- lapply(sims$strategy, function(x) rep(NA_character_, 3L))

  expect_error(mm_plot_strategy_compare(sims), "does not record")
})

test_that("the palette is colourblind-safe and long enough", {
  fills <- ggplot2::ggplot_build(mm_plot_win_rate(test_sims()))$data[[1L]]$fill

  expect_length(unique(fills), 3L)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", fills)))
})

# The layer that carries the value labels, whatever position it ends up in.
labelled_layer <- function(p) {
  built <- ggplot2::ggplot_build(p)$data
  hit <- vapply(built, function(d) "label" %in% names(d), logical(1L))
  built[[which(hit)[[1L]]]]
}

several_sizes <- function() {
  dplyr::bind_rows(
    mm_simulate(n = 10, n_players = 2, seed = 5),
    mm_simulate(n = 10, n_players = 4, seed = 5)
  )
}

test_that("a single player count is drawn without a facet strip", {
  expect_s3_class(mm_plot_win_rate(test_sims())$facet, "FacetNull")
  expect_s3_class(mm_plot_game_length(test_sims())$facet, "FacetNull")
  expect_s3_class(mm_plot_draws(test_sims())$facet, "FacetNull")
  expect_s3_class(mm_plot_win_rate(several_sizes())$facet, "FacetWrap")
})

test_that("the caption names the table size when there is only one", {
  expect_match(mm_plot_win_rate(test_sims())$labels$caption, "^3 players, ")
  expect_match(
    mm_plot_win_rate(several_sizes())$labels$caption,
    "across 2 table sizes"
  )
})

test_that("value labels sit at the base of the bar, clear of the rule", {
  # The dashed rule sits at 1/n, where the bars end. A label placed there is
  # struck through by it, so a bar tall enough to hold its label carries it at
  # y = 0 instead.
  text <- labelled_layer(mm_plot_win_rate(test_sims()))

  expect_true(all(text$y == 0))
  expect_true(all(text$colour == "#FFFFFF"))
  expect_true(all(grepl("^[0-9]+%$", text$label)))
})

test_that("a bar too short for its label carries it outside, in ink", {
  rates <- tibble::tibble(
    win_rate = c(0.95, 0.05),
    n_players = c(2L, 2L)
  )
  inside <- .mm_label_inside(rates$win_rate, rates$n_players)

  expect_equal(inside, c(TRUE, FALSE))
})

test_that("inside or outside is judged within a panel, not across all of them", {
  values <- c(0.90, 0.10, 0.09)
  panels <- c(1L, 2L, 2L)

  # Judged against the global maximum of 0.90 the two small bars both fall
  # outside; judged against their own panel, where 0.10 is the tallest bar,
  # neither does. A panel must not mix the two placements.
  expect_equal(.mm_label_inside(values, panels), c(TRUE, TRUE, TRUE))
  expect_equal(
    .mm_label_inside(values, rep(1L, 3L)),
    c(TRUE, FALSE, FALSE)
  )
})

test_that("histograms take one fill for every panel", {
  fills <- ggplot2::ggplot_build(
    mm_plot_game_length(several_sizes(), bins = 8)
  )$data[[1L]]$fill

  expect_length(unique(fills), 1L)
})

test_that("a strategy absent from a table size is marked, not left blank", {
  sims <- dplyr::bind_rows(
    mm_simulate(
      n = 20,
      n_players = 2,
      strategies = list(mm_strategy_greedy(), mm_strategy_random()),
      seed = 5
    ),
    mixed_sims()
  )
  built <- ggplot2::ggplot_build(mm_plot_strategy_compare(sims))$data
  labels <- unlist(lapply(built, function(d) d$label))

  expect_true("not at this table" %in% labels)
})

test_that("a strategy keeps its colour whatever it scores", {
  greedy_fill <- function(sims) {
    p <- mm_plot_strategy_compare(sims)
    built <- ggplot2::ggplot_build(p)
    rows <- levels(p$data$label)
    built$data[[1L]]$fill[[match("Greedy", rows[built$data[[1L]]$y])]]
  }

  expect_equal(greedy_fill(mixed_sims()), "#0072B2")
})

test_that("mm_theme() is exported and draws no legend", {
  theme <- mm_theme()

  expect_s3_class(theme, "theme")
  expect_equal(theme$legend.position, "none")
})
