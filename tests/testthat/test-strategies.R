make_hand <- function() {
  hand <- mm_build_deck()[c(1L, 6L, 21L, 29L), ]
  hand$card <- c(1L, 6L, 21L, 29L)
  hand
}

make_state <- function(legal) {
  list(
    player = 1L,
    n_players = 3L,
    turn = 1L,
    legal = legal,
    active_color = "red",
    pending_draw = 0L,
    hand_sizes = c(4L, 5L, 5L),
    draw_remaining = 10L,
    discard_size = 3L,
    colours = c("red", "green", "blue", "yellow")
  )
}

test_that("every strategy is a function of class mm_strategy", {
  strategies <- list(
    mm_strategy_greedy(),
    mm_strategy_random(),
    mm_strategy_hold_wilds()
  )
  for (strategy in strategies) {
    expect_s3_class(strategy, "mm_strategy")
    expect_true(is.function(strategy))
    expect_type(attr(strategy, "strategy_name"), "character")
    expect_true(is.function(attr(strategy, "color_picker")))
  }
})

test_that("strategies return a legal position or NA", {
  hand <- make_hand()
  legal <- c(2L, 4L)
  state <- make_state(legal)

  for (strategy in list(mm_strategy_greedy(), mm_strategy_random(),
                        mm_strategy_hold_wilds())) {
    choice <- strategy(hand, state)
    expect_length(choice, 1L)
    expect_true(choice %in% legal)
  }
})

test_that("strategies pass when nothing is legal", {
  hand <- make_hand()
  state <- make_state(integer(0))

  for (strategy in list(mm_strategy_greedy(), mm_strategy_random(),
                        mm_strategy_hold_wilds())) {
    expect_true(is.na(strategy(hand, state)))
  }
})

test_that("greedy plays the first legal card", {
  hand <- make_hand()
  expect_identical(mm_strategy_greedy()(hand, make_state(c(3L, 1L))), 3L)
  expect_identical(mm_strategy_greedy()(hand, make_state(c(1L, 4L))), 1L)
})

test_that("random draws from the legal cards only", {
  withr::local_seed(1)
  hand <- make_hand()
  legal <- c(1L, 2L, 4L)
  picks <- vapply(
    seq_len(50L),
    function(i) mm_strategy_random()(hand, make_state(legal)),
    integer(1L)
  )

  expect_true(all(picks %in% legal))
  expect_gt(length(unique(picks)), 1L)
})

test_that("hold_wilds never plays a wild while another card is legal", {
  hand <- make_hand()
  wilds <- which(hand$type == "wild")
  plain <- which(hand$type != "wild")
  expect_gt(length(wilds), 0L)

  strategy <- mm_strategy_hold_wilds()
  legal <- sort(c(wilds[[1L]], plain[[1L]]))
  expect_identical(strategy(hand, make_state(legal)), plain[[1L]])

  # With only wild cards legal it must still play one rather than pass.
  expect_identical(strategy(hand, make_state(wilds[[1L]])), wilds[[1L]])
})

test_that("colour pickers name a deck colour", {
  hand <- make_hand()
  state <- make_state(1L)

  for (strategy in list(mm_strategy_greedy(), mm_strategy_random(),
                        mm_strategy_hold_wilds())) {
    picker <- attr(strategy, "color_picker")
    expect_true(picker(hand, state) %in% state$colours)
  }
})

test_that("the greedy colour picker demands the colour it holds most of", {
  deck <- mm_build_deck()
  green <- which(deck$color == "green" & deck$type == "number")[1:3]
  red <- which(deck$color == "red" & deck$type == "number")[[1L]]
  hand <- deck[c(green, red), ]
  hand$card <- c(green, red)

  picker <- attr(mm_strategy_greedy(), "color_picker")
  expect_identical(picker(hand, make_state(1L)), "green")
})

test_that("a hand of nothing but wilds still yields a colour", {
  deck <- mm_build_deck()
  wilds <- which(deck$type == "wild")
  hand <- deck[wilds, ]
  hand$card <- wilds

  picker <- attr(mm_strategy_greedy(), "color_picker")
  expect_true(picker(hand, make_state(1L)) %in% make_state(1L)$colours)
})

test_that("strategies drive whole games without engine complaints", {
  for (strategy in list(mm_strategy_greedy(), mm_strategy_random(),
                        mm_strategy_hold_wilds())) {
    result <- mm_play_game(n_players = 3, strategies = strategy, seed = 5)
    expect_true(result$winner %in% 1:3)
  }
})

test_that("print.mm_strategy() names the strategy and returns its input", {
  expect_snapshot(print(mm_strategy_greedy()))
  expect_snapshot(print(mm_strategy_hold_wilds()))
  expect_identical(withVisible(print(mm_strategy_random()))$visible, FALSE)
})

test_that("the engine checks what a custom strategy returns", {
  game <- mm_new_game(n_players = 2, seed = 1, strategies = fixed_strategy(1L))

  expect_error(
    mm_step(mm_new_game(
      n_players = 2,
      seed = 1,
      strategies = fixed_strategy(c(1L, 2L))
    )),
    "single card position"
  )
  expect_error(
    mm_step(mm_new_game(
      n_players = 2,
      seed = 1,
      strategies = fixed_strategy(1.5)
    )),
    "whole-number"
  )
  expect_s3_class(mm_step(game), "mm_game")
})
