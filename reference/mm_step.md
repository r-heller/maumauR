# Advance a game by one action

Plays a single action for the seat to move: either play a card, or draw.
Leave `card` at `NULL` to let the seat's strategy decide, which is what
[`mm_play_game()`](https://r-heller.github.io/maumauR/reference/mm_play_game.md)
does; pass a position to play a specific card, which is what an
interactive front end does.

## Usage

``` r
mm_step(
  game,
  card = NULL,
  color = NULL,
  announce = TRUE,
  call = rlang::caller_env()
)
```

## Arguments

- game:

  An `mm_game` object from
  [`mm_new_game()`](https://r-heller.github.io/maumauR/reference/mm_new_game.md).

- card:

  Position of the card to play within
  [`mm_hand()`](https://r-heller.github.io/maumauR/reference/mm_hand.md),
  `NA` to draw or pass, or `NULL` (the default) to let the seat's
  strategy choose.

- color:

  Colour to demand when playing a wild. `NULL` (the default) asks the
  seat's strategy.

- announce:

  Set to `FALSE` to omit the "Mau" call when a play leaves one card in
  hand. Only matters when the game was created with
  `announce_penalty = TRUE`.

- call:

  The environment used for error reporting. Experts only.

## Value

The updated `mm_game` object.

## Details

A turn is at most two actions. A seat with no legal card draws one; if
the drawn card is playable the seat may still play it, otherwise the
turn ends immediately. A seat that has already drawn and does not play
passes.

`+2` cards stack: the penalty accumulates while seats keep answering
with a `+2` of their own, and the first seat that cannot (or will not)
answer draws the whole pile and loses its turn. While a penalty is
pending, `+2` cards are the only legal play - a wild does not cancel it.

## See also

[`mm_play_game()`](https://r-heller.github.io/maumauR/reference/mm_play_game.md)
to run a whole game,
[`mm_legal_moves()`](https://r-heller.github.io/maumauR/reference/mm_hand.md)
to see what is playable.

Other engine:
[`mm_hand()`](https://r-heller.github.io/maumauR/reference/mm_hand.md),
[`mm_new_game()`](https://r-heller.github.io/maumauR/reference/mm_new_game.md),
[`mm_play_game()`](https://r-heller.github.io/maumauR/reference/mm_play_game.md)

## Examples

``` r
game <- mm_new_game(n_players = 3, seed = 42)
game <- mm_step(game)
mm_top_card(game)
#> # A tibble: 1 × 4
#>   color  value type   active_color
#>   <chr>  <int> <chr>  <chr>       
#> 1 yellow     3 number yellow      

# Play a specific card interactively.
legal <- mm_legal_moves(game)
if (length(legal) > 0) {
  game <- mm_step(game, card = legal[[1]], color = "red")
}
```
