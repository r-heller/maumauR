# Compare strategies head to head

Averages the per-seat win rate of every strategy at the table, so that a
strategy seated twice is not flattered by its extra seat. Bars run
horizontally and share one order across panels - by overall mean win
rate - so a strategy keeps its row and its colour from panel to panel.
The dashed line is the rate expected if the strategy did not matter.

## Usage

``` r
mm_plot_strategy_compare(sims, call = rlang::caller_env())
```

## Arguments

- sims:

  A tibble from
  [`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md).

- call:

  The environment used for error reporting. Experts only.

## Value

A `ggplot` object.

## Details

Each panel scales its own x axis. A win rate at a two-player table is
not comparable with one at a four-player table - chance alone pays 50 %
against 25 % - so what a reader should compare is each bar against its
own panel's dashed line, and a shared axis would only leave the larger
tables squeezed into a third of their width. A strategy that did not sit
at a given table size is marked as such, so that an absent bar is not
read as a zero.

## See also

[`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md)
for running a mixed table.

Other plots:
[`mm_plot_draws()`](https://r-heller.github.io/maumauR/reference/mm_plot_draws.md),
[`mm_plot_game_length()`](https://r-heller.github.io/maumauR/reference/mm_plot_game_length.md),
[`mm_plot_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_plot_win_rate.md),
[`mm_theme()`](https://r-heller.github.io/maumauR/reference/mm_theme.md)

## Examples

``` r
sims <- mm_simulate(
  n = 30,
  n_players = 3,
  strategies = list(
    mm_strategy_greedy(),
    mm_strategy_random(),
    mm_strategy_hold_wilds()
  ),
  seed = 3
)
mm_plot_strategy_compare(sims)

```
