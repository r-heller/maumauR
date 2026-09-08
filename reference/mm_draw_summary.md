# Draw-count summary

Summarises how many cards get drawn per game, by player count.

## Usage

``` r
mm_draw_summary(sims, call = rlang::caller_env())
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
(integer), `mean_draws`, `sd_draws`, `min_draws`, `median_draws`, and
`max_draws` (all double). A 0-row input yields a 0-row tibble with those
columns.

## See also

[`mm_plot_draws()`](https://r-heller.github.io/maumauR/reference/mm_plot_draws.md)
for the matching chart.

Other simulation:
[`mm_game_length()`](https://r-heller.github.io/maumauR/reference/mm_game_length.md),
[`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md),
[`mm_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_win_rate.md)

## Examples

``` r
sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
mm_draw_summary(sims)
#> # A tibble: 1 × 7
#>   n_players games mean_draws sd_draws min_draws median_draws max_draws
#>       <int> <int>      <dbl>    <dbl>     <dbl>        <dbl>     <dbl>
#> 1         3    30       9.27     5.53         1            8        24
```
