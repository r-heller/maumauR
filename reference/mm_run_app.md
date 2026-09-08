# Launch the Mau Mau Shiny application

Starts the bundled Shiny application: play a hand against the artificial
opponents, explore win rates by seat, compare strategies head to head,
and inspect the game-length and draw-count distributions.

## Usage

``` r
mm_run_app(..., call = rlang::caller_env())
```

## Arguments

- ...:

  Additional arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html), for
  example `launch.browser = FALSE` or `port`.

- call:

  The environment used for error reporting. Experts only.

## Value

Invisible `NULL`. Called for its side effect of launching a Shiny
application.

## See also

[`mm_simulate()`](https://r-heller.github.io/maumauR/reference/mm_simulate.md)
for the same analyses at the console.

## Examples

``` r
# \donttest{
if (interactive()) {
  mm_run_app()
}
# }
```
