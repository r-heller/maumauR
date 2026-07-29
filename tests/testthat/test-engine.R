test_that("mm_new_game() deals a legal opening position", {
  game <- mm_new_game(n_players = 3, hand_size = 5, seed = 1)

  expect_s3_class(game, "mm_game")
  expect_length(game$hands, 3L)
  expect_true(all(lengths(game$hands) == 5L))
  expect_identical(length(game$discard), 1L)
  expect_identical(
    sum(lengths(game$hands)) + length(game$draw) + length(game$discard),
    nrow(game$deck)
  )
  expect_true(game$active_color %in% game$spec$colours)
  expect_identical(game$current, 1L)
  expect_false(game$finished)
})

test_that("mm_new_game() validates the table", {
  expect_error(mm_new_game(n_players = 1), "between")
  expect_error(mm_new_game(n_players = 3, hand_size = 20), "too small")
  expect_error(mm_new_game(strategies = "greedy"), "mm_strategy")
  expect_error(
    mm_new_game(n_players = 3, strategies = list(mm_strategy_greedy(),
                                                 mm_strategy_random())),
    "one strategy per seat"
  )
  expect_error(mm_new_game(spec = list()), "mm_deck_spec")
})

test_that("a seed makes the deal reproducible and restores the RNG", {
  withr::local_seed(99)
  state_before <- .Random.seed

  game_a <- mm_new_game(n_players = 3, seed = 7)
  expect_identical(.Random.seed, state_before)

  game_b <- mm_new_game(n_players = 3, seed = 7)
  expect_identical(game_a$hands, game_b$hands)

  game_c <- mm_new_game(n_players = 3, seed = 8)
  expect_false(identical(game_a$hands, game_c$hands))
})

test_that("a game terminates with a winner holding no cards", {
  for (n in 2:4) {
    result <- mm_play_game(n_players = n, seed = n)
    expect_identical(nrow(result), 1L)
    expect_true(result$winner %in% seq_len(n))
    expect_gt(result$turns, 0L)
    expect_identical(result$hand_sizes[[1L]][[result$winner]], 0L)
    expect_length(result$hand_sizes[[1L]], n)
  }
})

test_that("mm_play_game() returns the documented column contract", {
  result <- mm_play_game(n_players = 3, seed = 3)

  expect_s3_class(result, "tbl_df")
  expect_named(
    result,
    c("winner", "turns", "draws", "n_players", "hand_sizes", "strategy",
      "trace")
  )
  expect_type(result$winner, "integer")
  expect_type(result$turns, "integer")
  expect_type(result$draws, "integer")
  expect_type(result$n_players, "integer")
  expect_type(result$hand_sizes, "list")
  expect_identical(result$strategy[[1L]], rep("greedy", 3L))
  expect_s3_class(result$trace[[1L]], "tbl_df")
  expect_identical(nrow(result$trace[[1L]]), 0L)
})

test_that("cards are conserved at every logged step", {
  spec <- mm_deck_spec()
  for (seed in 1:5) {
    result <- mm_play_game(n_players = 3, spec = spec, seed = seed,
                           trace = TRUE)
    trail <- result$trace[[1L]]

    expect_gt(nrow(trail), 0L)
    expect_true(all(trail$total == spec$size))
    expect_identical(
      trail$hand_cards + trail$draw_pile + trail$discard_pile,
      trail$total
    )
  }
})

test_that("+2 stacking pushes four cards onto the next seat", {
  game <- mm_new_game(n_players = 3, seed = 1)
  hands <- list(
    c(card_id(game, "plus2", color = "red"),
      card_id(game, "number", color = "red", value = 1)),
    c(card_id(game, "plus2", color = "green"),
      card_id(game, "number", color = "green", value = 2)),
    c(card_id(game, "number", color = "blue", value = 3),
      card_id(game, "number", color = "blue", value = 4))
  )
  top <- card_id(game, "number", color = "red", value = 5)
  game <- rig_game(hands, top)

  game <- mm_step(game, card = 1L)
  expect_identical(game$pending_draw, 2L)
  expect_identical(game$current, 2L)

  # Seat 2 may only answer with a +2 while a penalty is pending.
  expect_identical(mm_legal_moves(game), 1L)
  game <- mm_step(game, card = 1L)
  expect_identical(game$pending_draw, 4L)
  expect_identical(game$current, 3L)

  # Seat 3 has none, so it takes all four cards and loses its turn.
  before <- length(game$hands[[3L]])
  game <- mm_step(game)
  expect_identical(length(game$hands[[3L]]), before + 4L)
  expect_identical(game$pending_draw, 0L)
  expect_identical(game$draws, 4L)
  expect_identical(game$current, 1L)
})

test_that("a skip advances two seats", {
  game <- mm_new_game(n_players = 3, seed = 1)
  hands <- list(
    c(card_id(game, "skip", color = "red"),
      card_id(game, "number", color = "red", value = 1)),
    card_id(game, "number", color = "green", value = 2),
    card_id(game, "number", color = "blue", value = 3)
  )
  top <- card_id(game, "number", color = "red", value = 5)
  game <- rig_game(hands, top)

  game <- mm_step(game, card = 1L)
  expect_identical(game$current, 3L)
  expect_identical(game$turn, 1L)
})

test_that("a wild is legal on every possible discard", {
  game <- mm_new_game(n_players = 2, seed = 1)
  wild <- card_id(game, "wild")
  partner <- card_id(game, "number", "red", 1)

  for (top in seq_len(nrow(game$deck))) {
    if (top %in% c(wild, partner)) {
      next
    }
    rigged <- rig_game(list(wild, partner), top)
    expect_true(1L %in% mm_legal_moves(rigged))
  }
})

test_that("a wild sets the colour in force and the demand is validated", {
  game <- mm_new_game(n_players = 2, seed = 1)
  hands <- list(
    c(card_id(game, "wild"), card_id(game, "number", "red", 1)),
    card_id(game, "number", "green", 2)
  )
  top <- card_id(game, "number", "red", 5)
  game <- rig_game(hands, top)

  expect_error(mm_step(game, card = 1L, color = "purple"), "deck colours")
  played <- mm_step(game, card = 1L, color = "green")
  expect_identical(played$active_color, "green")
  expect_identical(mm_top_card(played)$type, "wild")
})

test_that("a seat with no legal card draws, then plays or passes", {
  game <- mm_new_game(n_players = 2, seed = 1)
  hands <- list(
    card_id(game, "number", "red", 1),
    card_id(game, "number", "green", 2)
  )
  top <- card_id(game, "number", "blue", 3)
  game <- rig_game(hands, top, active_color = "blue")

  expect_length(mm_legal_moves(game), 0L)
  drawn <- mm_step(game, card = NA_integer_)
  expect_identical(drawn$draws, 1L)
  expect_identical(length(drawn$hands[[1L]]), 2L)
})

test_that("mm_step() refuses illegal cards and finished games", {
  game <- mm_new_game(n_players = 2, seed = 1)
  hands <- list(
    c(card_id(game, "number", "red", 1),
      card_id(game, "number", "green", 2)),
    card_id(game, "number", "green", 3)
  )
  top <- card_id(game, "number", "red", 5)
  game <- rig_game(hands, top)

  expect_error(mm_step(game, card = 2L), "not legal")
  expect_error(mm_step(game, card = 99L), "between")
  expect_error(mm_step(game, card = c(1L, 2L)), "single card position")

  finished <- game
  finished$finished <- TRUE
  expect_error(mm_step(finished), "already finished")
})

test_that("the engine rejects a strategy that picks an illegal card", {
  game <- mm_new_game(
    n_players = 2,
    strategies = fixed_strategy(2L),
    seed = 1
  )
  hands <- list(
    c(card_id(game, "number", "red", 1),
      card_id(game, "number", "green", 2)),
    card_id(game, "number", "green", 3)
  )
  top <- card_id(game, "number", "red", 5)
  game <- rig_game(hands, top, strategies = fixed_strategy(2L))

  expect_error(mm_step(game), "illegal card")
})

test_that("the Mau announcement penalty only bites when switched on", {
  build <- function(announce_penalty) {
    game <- mm_new_game(
      n_players = 2,
      seed = 1,
      announce_penalty = announce_penalty
    )
    hands <- list(
      c(card_id(game, "number", "red", 1),
        card_id(game, "number", "red", 2)),
      card_id(game, "number", "green", 3)
    )
    top <- card_id(game, "number", "red", 5)
    rig_game(hands, top, announce_penalty = announce_penalty)
  }

  quiet <- mm_step(build(TRUE), card = 1L, announce = FALSE)
  expect_identical(length(quiet$hands[[1L]]), 3L)

  called <- mm_step(build(TRUE), card = 1L, announce = TRUE)
  expect_identical(length(called$hands[[1L]]), 1L)

  off <- mm_step(build(FALSE), card = 1L, announce = FALSE)
  expect_identical(length(off$hands[[1L]]), 1L)
})

test_that("an exhausted draw pile is refilled from the discard pile", {
  game <- mm_new_game(n_players = 2, seed = 1)
  hands <- list(
    card_id(game, "number", "red", 1),
    card_id(game, "number", "green", 2)
  )
  top <- card_id(game, "number", "blue", 3)
  game <- rig_game(hands, top, active_color = "blue")
  # Move the whole draw pile onto the discard pile, top card last.
  game$discard <- c(game$draw, game$discard)
  game$draw <- integer(0)

  drawn <- mm_step(game, card = NA_integer_)
  expect_identical(drawn$draws, 1L)
  expect_identical(
    sum(lengths(drawn$hands)) + length(drawn$draw) + length(drawn$discard),
    nrow(drawn$deck)
  )
})

test_that("a game with no way to finish stops instead of looping", {
  game <- mm_new_game(n_players = 2, seed = 1)
  hands <- list(
    card_id(game, "number", "red", 1),
    card_id(game, "number", "red", 2)
  )
  top <- card_id(game, "number", "blue", 3)
  game <- rig_game(hands, top, active_color = "blue")
  game$draw <- integer(0)

  game <- mm_step(game, card = NA_integer_)
  game <- mm_step(game, card = NA_integer_)
  expect_true(game$finished)
  expect_true(game$stalled)
  expect_true(is.na(game$winner))
})

test_that("mm_play_game() warns and reports no winner at the turn cap", {
  expect_warning(
    result <- mm_play_game(n_players = 3, seed = 1, max_turns = 3),
    "max_turns"
  )
  expect_true(is.na(result$winner))
  expect_identical(result$turns, 3L)
})

test_that("accessors describe the state without changing it", {
  game <- mm_new_game(n_players = 3, seed = 42)

  hand <- mm_hand(game, player = 2)
  expect_s3_class(hand, "tbl_df")
  expect_named(hand, c("card", "color", "value", "type", "legal"))
  expect_identical(nrow(hand), 5L)
  expect_type(hand$legal, "logical")

  top <- mm_top_card(game)
  expect_identical(nrow(top), 1L)
  expect_named(top, c("color", "value", "type", "active_color"))

  moves <- mm_legal_moves(game)
  expect_type(moves, "integer")
  expect_true(all(moves %in% seq_len(5L)))
  expect_identical(moves, which(mm_hand(game)$legal))

  expect_error(mm_hand(game, player = 9), "between")
  expect_error(mm_hand(list()), "mm_game")
})

test_that("an empty hand yields a 0-row hand table, never NULL", {
  game <- mm_new_game(n_players = 2, seed = 1)
  game$hands[[1L]] <- integer(0)

  hand <- mm_hand(game, player = 1)
  expect_s3_class(hand, "tbl_df")
  expect_identical(nrow(hand), 0L)
  expect_identical(mm_legal_moves(game, player = 1), integer(0))
})

test_that("print.mm_game() is informative and returns its input", {
  game <- mm_new_game(n_players = 3, seed = 1)
  expect_snapshot(print(game))
  expect_identical(withVisible(print(game))$visible, FALSE)
})
