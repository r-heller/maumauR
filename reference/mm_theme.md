# The package plot theme

The theme every `mm_plot_*()` function draws in: a light look with one
faint rule per axis break and none between them, a clear typographic
hierarchy, facet strips in the suite accent, and no legend. Add it to a
`ggplot` of your own to match the package's figures.

## Usage

``` r
mm_theme(base_size = 11)
```

## Arguments

- base_size:

  Base font size in points.

## Value

A `ggplot2` theme object.

## See also

Other plots:
[`mm_plot_draws()`](https://r-heller.github.io/maumauR/reference/mm_plot_draws.md),
[`mm_plot_game_length()`](https://r-heller.github.io/maumauR/reference/mm_plot_game_length.md),
[`mm_plot_strategy_compare()`](https://r-heller.github.io/maumauR/reference/mm_plot_strategy_compare.md),
[`mm_plot_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_plot_win_rate.md)

## Examples

``` r
deck <- mm_build_deck()
ggplot2::ggplot(deck, ggplot2::aes(x = type)) +
  ggplot2::geom_bar(fill = "#0072B2") +
  ggplot2::labs(title = "The deck", x = NULL, y = "Cards") +
  mm_theme()

```
