# Artificial strategies

Strategies decide which card a seat plays. Each constructor returns a
function of class `mm_strategy` that the engine calls once per decision.

## Usage

``` r
mm_strategy_greedy()

mm_strategy_random()

mm_strategy_hold_wilds()

# S3 method for class 'mm_strategy'
print(x, ...)
```

## Arguments

- x:

  An object of class `mm_strategy`.

- ...:

  Not used.

## Value

The constructors return a function of class `mm_strategy` with signature
`(hand, state)`, returning a single integer card position or
`NA_integer_`. [`print()`](https://rdrr.io/r/base/print.html) returns
its input invisibly.

## Details

A strategy is a function `(hand, state)` returning the position of the
card to play (an index into the rows of `hand`), or `NA_integer_` to
draw and pass. It must only ever return a position listed in
`state$legal`.

`hand` is a
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `card` (integer card id), `color`, `value`, and `type`.
`state` is a list with elements

- `player`:

  Seat to move (integer).

- `n_players`:

  Number of seats (integer).

- `turn`:

  Completed turns so far (integer).

- `legal`:

  Playable positions in `hand` (integer, possibly empty).

- `top`:

  The discard pile's top card (one-row tibble).

- `active_color`:

  The colour currently in force (character).

- `pending_draw`:

  Cards stacked by unanswered `+2`s (integer).

- `hand_sizes`:

  Cards held by each seat (integer).

- `draw_remaining`:

  Cards left in the draw pile (integer).

- `discard_size`:

  Cards on the discard pile (integer).

- `colours`:

  Deck colours (character).

Each strategy also carries a colour picker used when it plays a wild:
`mm_strategy_greedy()` and `mm_strategy_hold_wilds()` demand the colour
they hold most of, `mm_strategy_random()` demands a uniformly random
colour.

The three supplied strategies differ only in which legal card they pick:

- `mm_strategy_greedy()`:

  The first legal card in hand order.

- `mm_strategy_random()`:

  A uniformly random legal card.

- `mm_strategy_hold_wilds()`:

  A non-wild legal card when one exists, keeping wild cards for turns
  that would otherwise be a draw.

## See also

[`mm_play_game()`](https://r-heller.github.io/maumauR/reference/mm_play_game.md)
and
[`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md),
which take strategies per seat.

## Examples

``` r
greedy <- mm_strategy_greedy()
greedy
#> <mm_strategy> "greedy"

# Strategies are plain functions; the engine calls them per decision.
hand <- mm_build_deck()[1:3, ]
hand$card <- 1:3
state <- list(legal = c(1L, 3L), colours = c("red", "green", "blue",
                                             "yellow"))
greedy(hand, state)
#> [1] 1
```
