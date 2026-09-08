# Inspect a game in progress

Accessors for the pieces of an `mm_game` a player or an interface needs:
the cards a seat holds, the positions it may legally play, and the card
on top of the discard pile.

## Usage

``` r
mm_hand(game, player = game$current, call = rlang::caller_env())

mm_legal_moves(game, player = game$current, call = rlang::caller_env())

mm_top_card(game, call = rlang::caller_env())
```

## Arguments

- game:

  An `mm_game` object from
  [`mm_new_game()`](https://r-heller.github.io/maumauR/reference/mm_new_game.md).

- player:

  Integer; the seat to inspect. Defaults to the seat to move.

- call:

  The environment used for error reporting. Experts only.

## Value

`mm_hand()` returns a
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per held card and columns `card` (integer card id), `color`
(character), `value` (integer), `type` (character), and `legal`
(logical, whether the card could be played on the current discard). A
seat with no cards yields a 0-row tibble.

`mm_legal_moves()` returns an integer vector of row positions into
`mm_hand()`, empty when nothing is playable - never `NULL`.

`mm_top_card()` returns a one-row
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `color`, `value`, `type`, and `active_color` (the colour in
force, which differs from `color` after a wild).

## See also

[`mm_step()`](https://r-heller.github.io/maumauR/reference/mm_step.md)
to play one of the legal moves.

Other engine:
[`mm_new_game()`](https://r-heller.github.io/maumauR/reference/mm_new_game.md),
[`mm_play_game()`](https://r-heller.github.io/maumauR/reference/mm_play_game.md),
[`mm_step()`](https://r-heller.github.io/maumauR/reference/mm_step.md)

## Examples

``` r
game <- mm_new_game(n_players = 3, seed = 42)
mm_top_card(game)
#> # A tibble: 1 × 4
#>   color value type   active_color
#>   <chr> <int> <chr>  <chr>       
#> 1 red       3 number red         
mm_hand(game)
#> # A tibble: 5 × 5
#>    card color  value type   legal
#>   <int> <chr>  <int> <chr>  <lgl>
#> 1    17 yellow     2 number FALSE
#> 2    25 blue      NA plus2  FALSE
#> 3    18 yellow     3 number TRUE 
#> 4     7 green      2 number FALSE
#> 5    14 blue       4 number FALSE
mm_legal_moves(game)
#> [1] 3
```
