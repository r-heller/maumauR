# Win rate by seat

Counts wins per seat and turns them into the share of decided games each
seat took. Seats that never won still appear, so the table always has
one row per seat and player count.

## Usage

``` r
mm_win_rate(sims, call = rlang::caller_env())
```

## Arguments

- sims:

  A tibble from
  [`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md).

- call:

  The environment used for error reporting. Experts only.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per seat within each player count, and columns

- `n_players`:

  Seats at the table (integer).

- `seat`:

  Seat number, 1 is the first to move (integer).

- `strategy`:

  Strategy that seat played (character).

- `wins`:

  Games won (integer).

- `games`:

  Games simulated at that table size (integer).

- `win_rate`:

  Share of decided games won, summing to 1 within a player count
  (double); `NA` when no game was decided.

## See also

[`mm_plot_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_plot_win_rate.md)
for the matching chart.

Other simulation:
[`mm_draw_summary()`](https://r-heller.github.io/maumauR/reference/mm_draw_summary.md),
[`mm_game_length()`](https://r-heller.github.io/maumauR/reference/mm_game_length.md),
[`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md)

## Examples

``` r
sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
mm_win_rate(sims)
#> # A tibble: 3 × 6
#>   n_players  seat strategy  wins games win_rate
#>       <int> <int> <chr>    <int> <int>    <dbl>
#> 1         3     1 greedy      15    30      0.5
#> 2         3     2 greedy       6    30      0.2
#> 3         3     3 greedy       9    30      0.3
```
