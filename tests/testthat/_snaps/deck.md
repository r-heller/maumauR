# the deck-size warning and the print method are informative

    Code
      spec <- mm_deck_spec(numbers = 0:5)
    Condition
      Warning:
      ! The deck specification totals 36 cards, but the box states 32.
      i Correct the `mm_deck_spec()` arguments after a physical card count; every simulation, summary, and plot follows from them.

---

    Code
      print(mm_deck_spec())
    Message
      <mm_deck_spec>: 32 cards in 4 colours
      * colours: "red", "green", "blue", and "yellow"
      * number faces per colour: 1, 2, 3, 4, and 5
      * +2 per colour: 1; skip per colour: 1
      * wild cards: 4
      * cards per colour: 7

---

    Code
      print(suppressWarnings(mm_deck_spec(numbers = 0:5)))
    Message
      <mm_deck_spec>: 36 cards in 4 colours
      * colours: "red", "green", "blue", and "yellow"
      * number faces per colour: 0, 1, 2, 3, 4, and 5
      * +2 per colour: 1; skip per colour: 1
      * wild cards: 4
      * cards per colour: 8
      ! Total is 36, not the 32 printed on the box.

