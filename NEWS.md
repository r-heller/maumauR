# maumauR 0.1.0

First release.

## The deck

* `mm_deck_spec()`: the single source of truth for deck composition, with full
  input validation. The default now totals the 32 cards printed on the box:
  four colours, five number faces per colour, one `+2` and one skip per colour,
  and four wild cards. Any specification that does not total 32 is accepted but
  warns.
* `mm_build_deck()`: expands a specification into one row per card.
* `print()` method for `mm_deck_spec`.

## The engine

* `mm_new_game()`: shuffles, deals, and turns the first card face up.
* `mm_step()`: advances a game by one action, either from a seat's strategy or
  from an explicit card, so the same engine drives simulations and interactive
  play. Implements true `+2` stacking, skips, wild colour choice, draw-pile
  reshuffling, and the optional "Mau" announcement penalty.
* `mm_hand()`, `mm_legal_moves()`, `mm_top_card()`: inspect a game in progress.
* `mm_play_game()`: plays one game to the end and returns a one-row record,
  with an optional audit trail that logs every pile size at every step.
* `print()` method for `mm_game`.

## Strategies

* `mm_strategy_greedy()`, `mm_strategy_random()`, `mm_strategy_hold_wilds()`:
  artificial seats, each a function of `(hand, state)` with a colour picker for
  wild cards. Custom strategies only need to follow the same contract.
* `print()` method for `mm_strategy`.

## Simulation and summaries

* `mm_simulate()`: many games, one tidy row each, with per-seat strategies.
* `mm_win_rate()`: wins and win rate by seat within each player count.
* `mm_game_length()`, `mm_draw_summary()`: distribution summaries by player
  count.

## Plots

* `mm_plot_win_rate()`, `mm_plot_game_length()`, `mm_plot_draws()`,
  `mm_plot_strategy_compare()`: colourblind-safe ggplot objects. Data are
  coloured with Okabe-Ito and the suite accent is kept for furniture, so no
  reading depends on telling two hues apart. Each bar carries its rate at its
  base, clear of the dashed line that marks what chance alone would pay, and
  the caption records how many games the figure rests on.
* `mm_theme()`: the theme those figures are drawn in, exported so that a plot
  of your own can match them.

## Application

* `mm_run_app()`: a four-tab Shiny application - play against the artificial
  opponents, explore win rates by seat, compare strategies, and inspect the
  game-length and draw-count distributions.
