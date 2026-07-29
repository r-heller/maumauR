test_that("mm_simulate() returns one row per game with stable columns", {
  sims <- mm_simulate(n = 15, n_players = 3, seed = 1)

  expect_s3_class(sims, "tbl_df")
  expect_identical(nrow(sims), 15L)
  expect_named(
    sims,
    c("game", "winner", "turns", "draws", "n_players", "hand_sizes",
      "strategy", "trace")
  )
  expect_identical(sims$game, 1:15)
  expect_true(all(sims$n_players == 3L))
  expect_true(all(sims$winner %in% 1:3))
  expect_type(sims$turns, "integer")
  expect_type(sims$draws, "integer")
})

test_that("mm_simulate() is reproducible and seat-aware", {
  a <- mm_simulate(n = 10, n_players = 3, seed = 11)
  b <- mm_simulate(n = 10, n_players = 3, seed = 11)
  c_ <- mm_simulate(n = 10, n_players = 3, seed = 12)

  expect_identical(a$winner, b$winner)
  expect_false(identical(a$winner, c_$winner))

  mixed <- mm_simulate(
    n = 10,
    n_players = 3,
    strategies = list(
      mm_strategy_greedy(),
      mm_strategy_random(),
      mm_strategy_hold_wilds()
    ),
    seed = 4
  )
  expect_identical(
    mixed$strategy[[1L]],
    c("greedy", "random", "hold_wilds")
  )
})

test_that("mm_simulate() returns a 0-row tibble for n = 0", {
  sims <- mm_simulate(n = 0)

  expect_s3_class(sims, "tbl_df")
  expect_identical(nrow(sims), 0L)
  expect_named(
    sims,
    c("game", "winner", "turns", "draws", "n_players", "hand_sizes",
      "strategy", "trace")
  )
})

test_that("mm_simulate() validates its arguments", {
  expect_error(mm_simulate(n = -1), "between")
  expect_error(mm_simulate(n = 1, n_players = 1), "between")
  expect_error(mm_simulate(n = 1, verbose = "yes"), "TRUE")
  expect_error(mm_simulate(n = 1, strategies = list(1)), "mm_strategy")
})

test_that("mm_simulate() warns once when games do not finish", {
  expect_warning(
    sims <- mm_simulate(n = 3, n_players = 3, max_turns = 2, seed = 1),
    "without a winner"
  )
  expect_identical(nrow(sims), 3L)
  expect_true(all(is.na(sims$winner)))
})

test_that("mm_win_rate() covers every seat and sums to one", {
  sims <- mm_simulate(n = 60, n_players = 3, seed = 2)
  rates <- mm_win_rate(sims)

  expect_s3_class(rates, "tbl_df")
  expect_named(
    rates,
    c("n_players", "seat", "strategy", "wins", "games", "win_rate")
  )
  expect_identical(rates$seat, 1:3)
  expect_identical(sum(rates$wins), 60L)
  expect_equal(sum(rates$win_rate), 1, tolerance = 1e-8)
  expect_true(all(rates$strategy == "greedy"))
})

test_that("mm_win_rate() keeps player counts apart", {
  sims <- dplyr::bind_rows(
    mm_simulate(n = 10, n_players = 2, seed = 1),
    mm_simulate(n = 10, n_players = 4, seed = 1)
  )
  rates <- mm_win_rate(sims)

  expect_identical(nrow(rates), 6L)
  expect_identical(rates$n_players, c(2L, 2L, 4L, 4L, 4L, 4L))
  by_size <- tapply(rates$win_rate, rates$n_players, sum)
  expect_equal(as.numeric(by_size), c(1, 1), tolerance = 1e-8)
})

test_that("mm_win_rate() reports NA when nothing was decided", {
  suppressWarnings(
    sims <- mm_simulate(n = 2, n_players = 3, max_turns = 2, seed = 1)
  )
  rates <- mm_win_rate(sims)

  expect_identical(rates$wins, c(0L, 0L, 0L))
  expect_true(all(is.na(rates$win_rate)))
})

test_that("summaries return 0-row tibbles for empty input", {
  empty <- mm_simulate(n = 0)

  expect_identical(nrow(mm_win_rate(empty)), 0L)
  expect_identical(nrow(mm_game_length(empty)), 0L)
  expect_identical(nrow(mm_draw_summary(empty)), 0L)
  expect_named(
    mm_game_length(empty),
    c("n_players", "games", "mean_turns", "sd_turns", "min_turns",
      "median_turns", "max_turns")
  )
  expect_named(
    mm_draw_summary(empty),
    c("n_players", "games", "mean_draws", "sd_draws", "min_draws",
      "median_draws", "max_draws")
  )
})

test_that("mm_game_length() and mm_draw_summary() summarise per table size", {
  sims <- dplyr::bind_rows(
    mm_simulate(n = 12, n_players = 2, seed = 3),
    mm_simulate(n = 12, n_players = 4, seed = 3)
  )

  lengths_tbl <- mm_game_length(sims)
  expect_identical(nrow(lengths_tbl), 2L)
  expect_identical(lengths_tbl$games, c(12L, 12L))
  expect_true(all(lengths_tbl$mean_turns >= lengths_tbl$min_turns))
  expect_true(all(lengths_tbl$max_turns >= lengths_tbl$mean_turns))

  draws_tbl <- mm_draw_summary(sims)
  expect_identical(nrow(draws_tbl), 2L)
  expect_true(all(draws_tbl$min_draws >= 0))
})

test_that("summaries reject tables that are not simulation results", {
  expect_error(mm_win_rate("nope"), "data frame")
  expect_error(mm_win_rate(tibble::tibble(x = 1)), "missing required column")
  expect_error(mm_game_length(tibble::tibble(x = 1)), "missing required")
  expect_error(mm_draw_summary(tibble::tibble(x = 1)), "missing required")
})

test_that("a longer run keeps the first seat's edge modest", {
  sims <- mm_simulate(n = 200, n_players = 3, seed = 20)
  rates <- mm_win_rate(sims)

  expect_true(all(rates$win_rate > 0.15))
  expect_true(all(rates$win_rate < 0.55))
})
