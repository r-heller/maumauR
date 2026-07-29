test_that("mm_deck_spec() returns a type-stable spec that totals 32", {
  spec <- mm_deck_spec()

  expect_s3_class(spec, "mm_deck_spec")
  expect_type(spec$size, "integer")
  expect_type(spec$numbers, "integer")
  expect_type(spec$plus2, "integer")
  expect_type(spec$skip, "integer")
  expect_type(spec$wild, "integer")
  expect_identical(spec$size, 32L)
  expect_identical(
    spec$size,
    length(spec$colours) *
      (length(spec$numbers) + spec$plus2 + spec$skip) + spec$wild
  )
})

test_that("mm_deck_spec() validates its arguments", {
  expect_error(mm_deck_spec(colours = c("red", "red")), "unique")
  expect_error(mm_deck_spec(colours = 1:4), "character vector")
  expect_error(mm_deck_spec(numbers = c(1.5, 2)), "whole numbers")
  expect_error(mm_deck_spec(numbers = c(1L, 1L)), "unique")
  expect_error(mm_deck_spec(plus2 = -1L), "between")
  expect_error(mm_deck_spec(wild = "four"), "whole number")
})

test_that("a deck that departs from the printed 32 cards warns", {
  expect_warning(mm_deck_spec(numbers = 0:5), "32")
  expect_identical(suppressWarnings(mm_deck_spec(numbers = 0:5))$size, 36L)
})

test_that("the deck-size warning and the print method are informative", {
  expect_snapshot(spec <- mm_deck_spec(numbers = 0:5))
  expect_snapshot(print(mm_deck_spec()))
  expect_snapshot(print(suppressWarnings(mm_deck_spec(numbers = 0:5))))
})

test_that("mm_build_deck() has one row per card with stable columns", {
  spec <- mm_deck_spec()
  deck <- mm_build_deck(spec)

  expect_s3_class(deck, "tbl_df")
  expect_named(deck, c("color", "value", "type"))
  expect_identical(nrow(deck), spec$size)
  expect_type(deck$color, "character")
  expect_type(deck$value, "integer")
  expect_type(deck$type, "character")
  expect_setequal(unique(deck$type), c("number", "plus2", "skip", "wild"))
})

test_that("mm_build_deck() encodes wilds and specials with NA", {
  deck <- mm_build_deck()

  expect_true(all(is.na(deck$color[deck$type == "wild"])))
  expect_true(all(!is.na(deck$color[deck$type != "wild"])))
  expect_true(all(is.na(deck$value[deck$type != "number"])))
  expect_true(all(!is.na(deck$value[deck$type == "number"])))
})

test_that("mm_build_deck() honours a corrected specification", {
  spec <- suppressWarnings(
    mm_deck_spec(numbers = 0:5, plus2 = 2L, skip = 1L, wild = 2L)
  )
  deck <- mm_build_deck(spec)

  expect_identical(nrow(deck), spec$size)
  expect_identical(sum(deck$type == "plus2"), 8L)
  expect_identical(sum(deck$type == "wild"), 2L)
})

test_that("an empty specification yields a 0-row tibble, never NULL", {
  spec <- suppressWarnings(
    mm_deck_spec(
      colours = character(0),
      numbers = integer(0),
      plus2 = 0L,
      skip = 0L,
      wild = 0L
    )
  )
  deck <- mm_build_deck(spec)

  expect_s3_class(deck, "tbl_df")
  expect_identical(nrow(deck), 0L)
  expect_named(deck, c("color", "value", "type"))
  expect_type(deck$color, "character")
  expect_type(deck$value, "integer")
})

test_that("mm_build_deck() rejects anything that is not a deck spec", {
  expect_error(mm_build_deck(list(size = 32L)), "mm_deck_spec")
})
