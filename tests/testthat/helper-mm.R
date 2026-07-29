# Test helpers: build fully determined game states so that rules can be
# checked one at a time.

# Row index of the first card matching a description.
card_id <- function(game, type, color = NULL, value = NULL) {
  deck <- game$deck
  hit <- deck$type == type
  if (!is.null(color)) {
    hit <- hit & !is.na(deck$color) & deck$color == color
  }
  if (!is.null(value)) {
    hit <- hit & !is.na(deck$value) & deck$value == value
  }
  which(hit)[[1L]]
}

# Replace the deal with a chosen one. `hands` is a list of integer card ids,
# `top` the card face up on the discard pile.
rig_game <- function(hands, top, active_color = NULL, ...) {
  game <- mm_new_game(n_players = length(hands), seed = 1, ...)
  used <- c(unlist(hands, use.names = FALSE), top)
  game$hands <- lapply(hands, as.integer)
  game$discard <- as.integer(top)
  game$draw <- setdiff(seq_len(nrow(game$deck)), used)
  top_color <- game$deck$color[[top]]
  if (is.null(active_color)) {
    active_color <- if (is.na(top_color)) game$spec$colours[[1L]] else top_color
  }
  game$active_color <- active_color
  game$current <- 1L
  game
}

# A strategy that always names the same card position, used to check that the
# engine validates what a strategy hands back.
fixed_strategy <- function(choice, name = "fixed", color = "red") {
  structure(
    function(hand, state) choice,
    class = c("mm_strategy", "function"),
    strategy_name = name,
    color_picker = function(hand, state) color
  )
}
