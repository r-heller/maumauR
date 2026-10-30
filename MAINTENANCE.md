# Maintenance review — 30 October 2026

## Purpose and acceptance criteria

A configurable Mau Mau engine, reproducible simulations, and a local teaching
app. This increment requires invalid counts to fail before coercion/allocation,
existing legal play to remain compatible, a clean source package check, and a
working installed first-use path. No rules or historical simulation data changed.

## Findings and completed work

- High: `R/checks.R` accepted infinity and values beyond integer range, producing
  missing values or unsafe allocation downstream. Counts now require finite
  bounded integers; regression tests include fractions, infinity, and overflow.
- High: player strategy replication preceded the deck-capacity check. An
  impossible million-player deal could allocate a large list before failing.
  `R/engine.R` and `R/simulate.R` now check capacity first, using double arithmetic
  to avoid integer multiplication overflow, including zero-game simulations.
- Packaging: linked-worktree `.git` metadata is excluded from source archives.

## Validation

On macOS arm64, R 4.6.1: full source tests passed in 7.43 seconds. Source build
with vignettes and complete `R CMD check --no-manual` passed, Status OK
(build 62.13 s; check 39.01 s). The package installed by that check conserved all
32 cards at every step of 30 seeded games, all of which finished. A 25-game
simulation repeated exactly and restored the caller's RNG state.

The installed Shiny app, launched outside the checkout, passed Chromium checks
for draw/pass, new game, win-rate table and plot, with no browser or Shiny errors.
Evidence is retained in the workspace's dated repository audit directory.

## Use and remaining work

Follow README installation, then `mm_play_game(seed = 1)` or `mm_run_app()`.
Existing tests cover stacking, skips, wilds, reshuffling and announcement rules.
This review does not independently authenticate the physical card deck or rerun
the historical 12,000-game README study. Its stated results are preserved.

Dependable-use repairs are complete locally. Optional future work is a
cross-platform browser CI job and independently reproduced large simulation
reports. Publication requires review/integration of this branch and a fresh
remote CI run; no push, CRAN submission, or hosted app deployment occurred.
