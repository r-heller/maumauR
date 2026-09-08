# Play one complete game of Mau Mau

Deals a game and plays it to the end with artificial opponents,
returning a one-row record of the outcome.

## Usage

``` r
mm_play_game(
  n_players = 3L,
  strategies = mm_strategy_greedy(),
  spec = mm_deck_spec(),
  hand_size = 5L,
  max_turns = 500L,
  announce_penalty = FALSE,
  trace = FALSE,
  seed = NULL,
  call = rlang::caller_env()
)
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

- max_turns:

  Integer; the turn cap that stops a game which cannot finish. Reaching
  it warns and returns a game with no winner.

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

## Value

A one-row
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns

- `winner`:

  Winning seat (integer), `NA` if the game did not finish.

- `turns`:

  Turns played (integer).

- `draws`:

  Cards drawn by all seats together (integer).

- `n_players`:

  Seats at the table (integer).

- `hand_sizes`:

  List column; per-seat cards left at the end (integer).

- `strategy`:

  List column; per-seat strategy names (character).

- `trace`:

  List column; the audit trail as a tibble with columns `turn`,
  `player`, `action`, `hand_cards`, `draw_pile`, `discard_pile`, and
  `total`. 0 rows unless `trace = TRUE`.

## See also

[`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md)
to repeat this many times,
[`mm_new_game()`](https://r-heller.github.io/maumauR/reference/mm_new_game.md)
and
[`mm_step()`](https://r-heller.github.io/maumauR/reference/mm_step.md)
for turn-by-turn control.

Other engine:
[`mm_hand()`](https://r-heller.github.io/maumauR/reference/mm_hand.md),
[`mm_new_game()`](https://r-heller.github.io/maumauR/reference/mm_new_game.md),
[`mm_step()`](https://r-heller.github.io/maumauR/reference/mm_step.md)

## Examples

``` r
mm_play_game(n_players = 3, seed = 1)
#> # A tibble: 1 × 7
#>   winner turns draws n_players hand_sizes strategy  trace           
#>    <int> <int> <int>     <int> <list>     <list>    <list>          
#> 1      1    35    16         3 <int [3]>  <chr [3]> <tibble [0 × 7]>

# The audit trail lets you check that no card is lost or duplicated.
one <- mm_play_game(n_players = 2, seed = 7, trace = TRUE)
unique(one$trace[[1]]$total)
#> [1] 32
```
