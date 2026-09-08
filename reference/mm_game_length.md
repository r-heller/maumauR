# Game-length summary

Summarises how many turns games take, by player count.

## Usage

``` r
mm_game_length(sims, call = rlang::caller_env())
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
with one row per player count and columns `n_players` (integer), `games`
(integer), `mean_turns`, `sd_turns`, `min_turns`, `median_turns`, and
`max_turns` (all double). A 0-row input yields a 0-row tibble with those
columns.

## See also

[`mm_plot_game_length()`](https://r-heller.github.io/maumauR/reference/mm_plot_game_length.md)
for the matching chart.

Other simulation:
[`mm_draw_summary()`](https://r-heller.github.io/maumauR/reference/mm_draw_summary.md),
[`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md),
[`mm_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_win_rate.md)

## Examples

``` r
sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
mm_game_length(sims)
#> # A tibble: 1 × 7
#>   n_players games mean_turns sd_turns min_turns median_turns max_turns
#>       <int> <int>      <dbl>    <dbl>     <dbl>        <dbl>     <dbl>
#> 1         3    30       23.1     8.96        11           21        45
```
