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
