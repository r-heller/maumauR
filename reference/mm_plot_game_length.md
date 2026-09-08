# Plot the game-length distribution

Draws the distribution of turns per game, one panel per player count,
with a dashed line at each panel's median. The x scale is shared, so the
panels can be compared directly. A single player count is drawn without
a strip and named in the caption instead.

## Usage

``` r
mm_plot_game_length(sims, bins = 30L, call = rlang::caller_env())
```

## Arguments

- sims:

  A tibble from
  [`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md).

- bins:

  Integer; number of histogram bins.

- call:

  The environment used for error reporting. Experts only.

## Value

A `ggplot` object.

## See also

[`mm_game_length()`](https://r-heller.github.io/maumauR/reference/mm_game_length.md)
for the underlying summary.

Other plots:
[`mm_plot_draws()`](https://r-heller.github.io/maumauR/reference/mm_plot_draws.md),
[`mm_plot_strategy_compare()`](https://r-heller.github.io/maumauR/reference/mm_plot_strategy_compare.md),
[`mm_plot_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_plot_win_rate.md),
[`mm_theme()`](https://r-heller.github.io/maumauR/reference/mm_theme.md)

## Examples

``` r
sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
mm_plot_game_length(sims)

```
