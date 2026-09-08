# Changelog

## maumauR 0.1.0

First release.

### The deck

- [`mm_deck_spec()`](https://r-heller.github.io/maumauR/reference/mm_deck_spec.md):
  the single source of truth for deck composition, with full input
  validation. The default now totals the 32 cards printed on the box:
  four colours, five number faces per colour, one `+2` and one skip per
  colour, and four wild cards. Any specification that does not total 32
  is accepted but warns.
- [`mm_build_deck()`](https://r-heller.github.io/maumauR/reference/mm_build_deck.md):
  expands a specification into one row per card.
- [`print()`](https://rdrr.io/r/base/print.html) method for
  `mm_deck_spec`.

### The engine

- [`mm_new_game()`](https://r-heller.github.io/maumauR/reference/mm_new_game.md):
  shuffles, deals, and turns the first card face up.
- [`mm_step()`](https://r-heller.github.io/maumauR/reference/mm_step.md):
  advances a game by one action, either from a seat’s strategy or from
  an explicit card, so the same engine drives simulations and
  interactive play. Implements true `+2` stacking, skips, wild colour
  choice, draw-pile reshuffling, and the optional “Mau” announcement
  penalty.
- [`mm_hand()`](https://r-heller.github.io/maumauR/reference/mm_hand.md),
  [`mm_legal_moves()`](https://r-heller.github.io/maumauR/reference/mm_hand.md),
  [`mm_top_card()`](https://r-heller.github.io/maumauR/reference/mm_hand.md):
  inspect a game in progress.
- [`mm_play_game()`](https://r-heller.github.io/maumauR/reference/mm_play_game.md):
  plays one game to the end and returns a one-row record, with an
  optional audit trail that logs every pile size at every step.
- [`print()`](https://rdrr.io/r/base/print.html) method for `mm_game`.

### Strategies

- [`mm_strategy_greedy()`](https://r-heller.github.io/maumauR/reference/mm_strategy.md),
  [`mm_strategy_random()`](https://r-heller.github.io/maumauR/reference/mm_strategy.md),
  [`mm_strategy_hold_wilds()`](https://r-heller.github.io/maumauR/reference/mm_strategy.md):
  artificial seats, each a function of `(hand, state)` with a colour
  picker for wild cards. Custom strategies only need to follow the same
  contract.
- [`print()`](https://rdrr.io/r/base/print.html) method for
  `mm_strategy`.

### Simulation and summaries

- [`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md):
  many games, one tidy row each, with per-seat strategies.
- [`mm_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_win_rate.md):
  wins and win rate by seat within each player count.
- [`mm_game_length()`](https://r-heller.github.io/maumauR/reference/mm_game_length.md),
  [`mm_draw_summary()`](https://r-heller.github.io/maumauR/reference/mm_draw_summary.md):
  distribution summaries by player count.

### Plots

- [`mm_plot_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_plot_win_rate.md),
  [`mm_plot_game_length()`](https://r-heller.github.io/maumauR/reference/mm_plot_game_length.md),
  [`mm_plot_draws()`](https://r-heller.github.io/maumauR/reference/mm_plot_draws.md),
  [`mm_plot_strategy_compare()`](https://r-heller.github.io/maumauR/reference/mm_plot_strategy_compare.md):
  colourblind-safe ggplot objects. Data are coloured with Okabe-Ito and
  the suite accent is kept for furniture, so no reading depends on
  telling two hues apart. Each bar carries its rate at its base, clear
  of the dashed line that marks what chance alone would pay, and the
  caption records how many games the figure rests on.
- [`mm_theme()`](https://r-heller.github.io/maumauR/reference/mm_theme.md):
  the theme those figures are drawn in, exported so that a plot of your
  own can match them.

### Application

- [`mm_run_app()`](https://r-heller.github.io/maumauR/reference/mm_run_app.md):
  a four-tab Shiny application - play against the artificial opponents,
  explore win rates by seat, compare strategies, and inspect the
  game-length and draw-count distributions.
