# Start a game of Mau Mau

Shuffles a deck, deals a hand to every seat, and turns the first card
face up. The returned object is the complete game state, open to
inspection: advance it one action at a time with
[`mm_step()`](https://r-heller.github.io/maumauR/reference/mm_step.md),
or play it out in one call with
[`mm_play_game()`](https://r-heller.github.io/maumauR/reference/mm_play_game.md).

## Usage

``` r
mm_new_game(
  n_players = 3L,
  strategies = mm_strategy_greedy(),
  spec = mm_deck_spec(),
  hand_size = 5L,
  announce_penalty = FALSE,
  trace = FALSE,
  seed = NULL,
  call = rlang::caller_env()
)

# S3 method for class 'mm_game'
print(x, ...)
```

## Arguments

- n_players:

  Integer; number of seats. The box calls for 2 to 4.

- strategies:

  An `mm_strategy` object, or a list of them with one entry per seat. A
  single strategy is recycled across all seats. See
  [`mm_strategy_greedy()`](https://r-heller.github.io/maumauR/reference/mm_strategy.md).

- spec:

  A deck specification from
  [`mm_deck_spec()`](https://r-heller.github.io/maumauR/reference/mm_deck_spec.md).

- hand_size:

  Integer; cards dealt to each seat. The printed rules deal five.

- announce_penalty:

  If `TRUE`, a seat that plays down to one card without announcing "Mau"
  draws two penalty cards. Artificial strategies always announce, so
  this only bites interactive players. Defaults to `FALSE`.

- trace:

  If `TRUE`, record one row per step (turn, actor, action, and the card
  counts of every pile) for auditing. Defaults to `FALSE`.

- seed:

  Optional integer seed. The caller's random stream is restored
  afterwards.

- call:

  The environment used for error reporting. Experts only.

- x:

  An object of class `mm_game`.

- ...:

  Not used.

## Value

An object of class `mm_game`: a list holding the deck, the hands, the
draw and discard piles, the colour in force, the seat to move, and the
running turn, draw, and winner counters.

## Details

The opening card's effect is not applied: only its colour (and value)
set the state, so the first seat always moves. If the opening card is a
wild, the colour in force is drawn at random from the deck colours.

## See also

[`mm_step()`](https://r-heller.github.io/maumauR/reference/mm_step.md)
to advance the game,
[`mm_hand()`](https://r-heller.github.io/maumauR/reference/mm_hand.md)
and
[`mm_top_card()`](https://r-heller.github.io/maumauR/reference/mm_hand.md)
to inspect it.

Other engine:
[`mm_hand()`](https://r-heller.github.io/maumauR/reference/mm_hand.md),
[`mm_play_game()`](https://r-heller.github.io/maumauR/reference/mm_play_game.md),
[`mm_step()`](https://r-heller.github.io/maumauR/reference/mm_step.md)

## Examples

``` r
game <- mm_new_game(n_players = 3, seed = 1)
game
#> <mm_game>: 3 players, turn 0
#> • top card: "wild" NA (colour in force: "blue")
#> • hand sizes: 5, 5, and 5
#> • draw pile: 16; discard pile: 1
#> • to move: seat 1
mm_hand(game, player = 1)
#> # A tibble: 5 × 5
#>    card color  value type   legal
#>   <int> <chr>  <int> <chr>  <lgl>
#> 1    25 blue      NA plus2  TRUE 
#> 2     1 red        1 number FALSE
#> 3    11 blue       1 number TRUE 
#> 4    19 yellow     4 number FALSE
#> 5    10 green      5 number FALSE
```
