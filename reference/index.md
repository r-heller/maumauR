# Package index

## The deck

The single source of truth for deck composition. Correct it here and
everything downstream follows.

- [`mm_deck_spec()`](https://r-heller.github.io/maumauR/reference/mm_deck_spec.md)
  [`print(`*`<mm_deck_spec>`*`)`](https://r-heller.github.io/maumauR/reference/mm_deck_spec.md)
  : Deck specification for "der kleine ICE" Mau Mau
- [`mm_build_deck()`](https://r-heller.github.io/maumauR/reference/mm_build_deck.md)
  : Build the card table for a deck specification

## The engine

Deal a table, advance it one action at a time, or play it out.

- [`mm_new_game()`](https://r-heller.github.io/maumauR/reference/mm_new_game.md)
  [`print(`*`<mm_game>`*`)`](https://r-heller.github.io/maumauR/reference/mm_new_game.md)
  : Start a game of Mau Mau
- [`mm_step()`](https://r-heller.github.io/maumauR/reference/mm_step.md)
  : Advance a game by one action
- [`mm_hand()`](https://r-heller.github.io/maumauR/reference/mm_hand.md)
  [`mm_legal_moves()`](https://r-heller.github.io/maumauR/reference/mm_hand.md)
  [`mm_top_card()`](https://r-heller.github.io/maumauR/reference/mm_hand.md)
  : Inspect a game in progress
- [`mm_play_game()`](https://r-heller.github.io/maumauR/reference/mm_play_game.md)
  : Play one complete game of Mau Mau

## Strategies

How an artificial seat decides what to play.

- [`mm_strategy_greedy()`](https://r-heller.github.io/maumauR/reference/mm_strategy.md)
  [`mm_strategy_random()`](https://r-heller.github.io/maumauR/reference/mm_strategy.md)
  [`mm_strategy_hold_wilds()`](https://r-heller.github.io/maumauR/reference/mm_strategy.md)
  [`print(`*`<mm_strategy>`*`)`](https://r-heller.github.io/maumauR/reference/mm_strategy.md)
  : Artificial strategies

## Simulation and summaries

Many games, and the tidy tables built from them.

- [`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md)
  : Simulate many games of Mau Mau
- [`mm_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_win_rate.md)
  : Win rate by seat
- [`mm_game_length()`](https://r-heller.github.io/maumauR/reference/mm_game_length.md)
  : Game-length summary
- [`mm_draw_summary()`](https://r-heller.github.io/maumauR/reference/mm_draw_summary.md)
  : Draw-count summary

## Plots

Every plot returns a ggplot object you can keep building on.

- [`mm_plot_win_rate()`](https://r-heller.github.io/maumauR/reference/mm_plot_win_rate.md)
  : Plot win rate by seat
- [`mm_plot_game_length()`](https://r-heller.github.io/maumauR/reference/mm_plot_game_length.md)
  : Plot the game-length distribution
- [`mm_plot_draws()`](https://r-heller.github.io/maumauR/reference/mm_plot_draws.md)
  : Plot the draw-count distribution
- [`mm_plot_strategy_compare()`](https://r-heller.github.io/maumauR/reference/mm_plot_strategy_compare.md)
  : Compare strategies head to head
- [`mm_theme()`](https://r-heller.github.io/maumauR/reference/mm_theme.md)
  : The package plot theme

## Application

- [`mm_run_app()`](https://r-heller.github.io/maumauR/reference/mm_run_app.md)
  : Launch the Mau Mau Shiny application

## Package

- [`maumauR`](https://r-heller.github.io/maumauR/reference/maumauR-package.md)
  [`maumauR-package`](https://r-heller.github.io/maumauR/reference/maumauR-package.md)
  : maumauR: Simulation and Analysis of the DB Mau Mau Card Game
