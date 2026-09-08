# Simulate many games of Mau Mau

Runs `n` independent games under the same table setup and returns one
tidy row per game. This is the entry point for win-rate, game-length,
and draw-count analysis.

## Usage

``` r
mm_simulate(
  n = 100L,
  n_players = 3L,
  strategies = mm_strategy_greedy(),
  spec = mm_deck_spec(),
  hand_size = 5L,
  max_turns = 500L,
  announce_penalty = FALSE,
  trace = FALSE,
  seed = NULL,
  verbose = FALSE,
  call = rlang::caller_env()
)
```

## Arguments

- n:

  Integer; number of games to simulate.

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

- verbose:

  If `TRUE`, show a progress bar. Defaults to `FALSE`.

- call:

  The environment used for error reporting. Experts only.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with `n` rows: the columns of
[`mm_play_game()`](https://r-heller.github.io/maumauR/reference/mm_play_game.md)
(`winner`, `turns`, `draws`, `n_players`, `hand_sizes`, `strategy`,
`trace`) preceded by `game`, an integer game id. `n = 0` yields a 0-row
tibble with those columns.

## See also

[`mm_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_win_rate.md),
[`mm_game_length()`](https://r-heller.github.io/maumauR/reference/mm_game_length.md),
and
[`mm_draw_summary()`](https://r-heller.github.io/maumauR/reference/mm_draw_summary.md)
for the summaries built on this table.

Other simulation:
[`mm_draw_summary()`](https://r-heller.github.io/maumauR/reference/mm_draw_summary.md),
[`mm_game_length()`](https://r-heller.github.io/maumauR/reference/mm_game_length.md),
[`mm_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_win_rate.md)

## Examples

``` r
sims <- mm_simulate(n = 20, n_players = 3, seed = 1)
sims
#> # A tibble: 20 × 8
#>     game winner turns draws n_players hand_sizes strategy  trace           
#>    <int>  <int> <int> <int>     <int> <list>     <list>    <list>          
#>  1     1      1    35    16         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#>  2     2      3    15     5         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#>  3     3      3    21     7         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#>  4     4      1    20     7         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#>  5     5      1    14     3         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#>  6     6      1    16     5         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#>  7     7      2    39    17         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#>  8     8      1    13     3         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#>  9     9      2    25     9         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 10    10      1    20     7         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 11    11      1    27    12         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 12    12      1    27    11         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 13    13      1    36    16         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 14    14      2    14     3         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 15    15      1    13     1         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 16    16      1    11     1         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 17    17      1    18     8         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 18    18      3    14     6         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 19    19      3    28    15         3 <int [3]>  <chr [3]> <tibble [0 × 7]>
#> 20    20      2    17     5         3 <int [3]>  <chr [3]> <tibble [0 × 7]>

# One strategy per seat.
mixed <- mm_simulate(
  n = 20,
  n_players = 3,
  strategies = list(
    mm_strategy_greedy(),
    mm_strategy_random(),
    mm_strategy_hold_wilds()
  ),
  seed = 2
)
mm_win_rate(mixed)
#> # A tibble: 3 × 6
#>   n_players  seat strategy    wins games win_rate
#>       <int> <int> <chr>      <int> <int>    <dbl>
#> 1         3     1 greedy         2    20     0.1 
#> 2         3     2 random         7    20     0.35
#> 3         3     3 hold_wilds    11    20     0.55
```
