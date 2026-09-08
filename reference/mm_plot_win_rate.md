# Plot win rate by seat

Draws the share of decided games each seat won, with a dashed line at
the rate expected if seating did not matter. Several player counts get a
panel each; a single player count is drawn without a strip and named in
the caption instead. Each bar carries its rate at its base, and the
caption records how many games the picture rests on.

## Usage

``` r
mm_plot_win_rate(sims, call = rlang::caller_env())
```

## Arguments

- sims:

  A tibble from
  [`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md).

- call:

  The environment used for error reporting. Experts only.

## Value

A `ggplot` object.

## See also

[`mm_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_win_rate.md)
for the underlying table.

Other plots:
[`mm_plot_draws()`](https://r-heller.github.io/maumauR/reference/mm_plot_draws.md),
[`mm_plot_game_length()`](https://r-heller.github.io/maumauR/reference/mm_plot_game_length.md),
[`mm_plot_strategy_compare()`](https://r-heller.github.io/maumauR/reference/mm_plot_strategy_compare.md),
[`mm_theme()`](https://r-heller.github.io/maumauR/reference/mm_theme.md)

## Examples

``` r
sims <- mm_simulate(n = 30, n_players = 3, seed = 1)
mm_plot_win_rate(sims)

```
