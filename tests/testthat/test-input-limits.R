test_that("counts reject non-finite and integer-overflow inputs before coercion", {
  for (bad in list(Inf, -Inf, NaN, NA_real_, 1.5, .Machine$integer.max + 1)) {
    expect_error(mm_new_game(n_players = bad), "whole number|between")
    expect_error(mm_simulate(n = bad), "whole number|between")
    expect_error(mm_new_game(seed = bad), "whole number|between")
  }
})

test_that("impossible deals fail before allocating per-seat strategy lists", {
  local_mocked_bindings(.check_strategies = function(...) stop("allocation attempted"))
  expect_error(mm_new_game(n_players = 1000000), "deck is too small")
  expect_error(mm_simulate(n = 0, n_players = 1000000), "deck is too small")
  expect_error(mm_new_game(n_players = .Machine$integer.max, hand_size = 5), "deck is too small")
})
