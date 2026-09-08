# Deck specification for "der kleine ICE" Mau Mau

Builds the specification of the DB "der kleine ICE" Mau Mau deck: which
colours exist, which number faces each colour carries, and how many
special cards the deck holds. The specification is the single source of
truth for deck composition - the engine, the simulator, the summaries,
and the Shiny app all read the deck from it.

## Usage

``` r
mm_deck_spec(
  colours = c("red", "green", "blue", "yellow"),
  numbers = 1:5,
  plus2 = 1L,
  skip = 1L,
  wild = 4L,
  call = rlang::caller_env()
)

# S3 method for class 'mm_deck_spec'
print(x, ...)
```

## Arguments

- colours:

  Character vector of colour names. Must be unique and non-missing.

- numbers:

  Integer vector of number-card face values present in each colour. Must
  be unique and non-missing.

- plus2:

  Integer; number of `+2` (draw two) cards per colour.

- skip:

  Integer; number of skip (`Aussetzen`) cards per colour.

- wild:

  Integer; number of colourless wild (`Farbwahl`) cards.

- call:

  The environment used for error reporting. Experts only.

- x:

  An object of class `mm_deck_spec`.

- ...:

  Not used.

## Value

An object of class `mm_deck_spec`: a list with elements

- `colours`:

  Colour names (character).

- `numbers`:

  Number faces per colour (integer).

- `plus2`:

  `+2` cards per colour (integer, length 1).

- `skip`:

  Skip cards per colour (integer, length 1).

- `wild`:

  Wild cards in the deck (integer, length 1).

- `size`:

  Total number of cards (integer, length 1).

## Details

**This is the single point of correction for the deck.** The box states
32 cards (`Inhalt: 32 Spielkarten`). The defaults are the only
reconstruction that reaches that total while keeping every card type
described in the printed rules:

- four colours (red, green, blue, yellow),

- five number faces per colour (`1:5`) - 20 cards,

- one `+2` (draw two) per colour - 4 cards,

- one skip (`Aussetzen`) per colour - 4 cards,

- four colourless wild cards (`Farbwahl`) - 4 cards.

The *number of number faces* (five per colour) is fixed by arithmetic
once the specials are known, and the face values `1:5` are confirmed
against the physical deck. Adjust `numbers`, `plus2`, `skip`, and `wild`
here and everything downstream follows. A specification whose total is
not 32 is accepted but warns, so a wrongly built deck can never pass
unnoticed.

## See also

[`mm_build_deck()`](https://r-heller.github.io/maumauR/reference/mm_build_deck.md)
to turn a specification into a card table.

Other deck:
[`mm_build_deck()`](https://r-heller.github.io/maumauR/reference/mm_build_deck.md)

## Examples

``` r
spec <- mm_deck_spec()
spec
#> <mm_deck_spec>: 32 cards in 4 colours
#> • colours: "red", "green", "blue", and "yellow"
#> • number faces per colour: 1, 2, 3, 4, and 5
#> • +2 per colour: 1; skip per colour: 1
#> • wild cards: 4
#> • cards per colour: 7
spec$size
#> [1] 32

# A specification that departs from the printed 32-card total warns:
suppressWarnings(mm_deck_spec(numbers = 0:5))$size
#> [1] 36
```
