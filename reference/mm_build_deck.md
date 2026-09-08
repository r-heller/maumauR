# Build the card table for a deck specification

Expands an
[`mm_deck_spec()`](https://r-heller.github.io/maumauR/reference/mm_deck_spec.md)
into one row per physical card. This is the table the engine deals from.

## Usage

``` r
mm_build_deck(spec = mm_deck_spec(), call = rlang::caller_env())
```

## Arguments

- spec:

  A deck specification from
  [`mm_deck_spec()`](https://r-heller.github.io/maumauR/reference/mm_deck_spec.md).

- call:

  The environment used for error reporting. Experts only.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with `spec$size` rows and columns

- `color`:

  Card colour (character); `NA` for wild cards.

- `value`:

  Number face (integer); `NA` for `+2`, skip, and wild.

- `type`:

  One of `"number"`, `"plus2"`, `"skip"`, `"wild"` (character).

An empty specification yields a 0-row tibble with those columns, never
`NULL`.

## See also

[`mm_deck_spec()`](https://r-heller.github.io/maumauR/reference/mm_deck_spec.md)
for the composition itself.

Other deck:
[`mm_deck_spec()`](https://r-heller.github.io/maumauR/reference/mm_deck_spec.md)

## Examples

``` r
deck <- mm_build_deck()
deck
#> # A tibble: 32 × 3
#>    color value type  
#>    <chr> <int> <chr> 
#>  1 red       1 number
#>  2 red       2 number
#>  3 red       3 number
#>  4 red       4 number
#>  5 red       5 number
#>  6 green     1 number
#>  7 green     2 number
#>  8 green     3 number
#>  9 green     4 number
#> 10 green     5 number
#> # ℹ 22 more rows
table(deck$type)
#> 
#> number  plus2   skip   wild 
#>     20      4      4      4 
```
