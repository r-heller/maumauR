# Tab 1: play a hand against the artificial opponents.

mod_play_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      title = "Table",
      width = 260,
      shiny::sliderInput(
        ns("n_players"),
        "Players",
        min = 2,
        max = mm_max_players,
        value = 3,
        step = 1,
        ticks = FALSE
      ),
      shiny::selectInput(
        ns("strategy"),
        "Opponents play",
        choices = mm_strategy_choices,
        selected = "greedy"
      ),
      shiny::checkboxInput(
        ns("announce_penalty"),
        "House rule: forgetting \"Mau\" costs two cards",
        value = FALSE
      ),
      shiny::actionButton(ns("new_game"), "New game", class = "btn-primary"),
      shiny::actionButton(
        ns("draw"),
        "Draw or pass",
        class = "btn-outline-primary"
      ),
      shiny::p(
        class = "mm-help",
        "You are seat 1. Click a card to play it. Faded, dashed cards are",
        "not legal on the current discard."
      )
    ),
    # The discard pile and the running commentary stack in the narrow column:
    # each is short, and side by side with the table they left a third of the
    # viewport empty below the row.
    bslib::layout_columns(
      col_widths = c(4, 8),
      shiny::div(
        class = "mm-stack",
        bslib::card(
          bslib::card_header("Discard pile"),
          shiny::uiOutput(ns("top_card"))
        ),
        bslib::card(
          class = "mm-stack-grow",
          bslib::card_header("What happened"),
          shiny::uiOutput(ns("log"))
        )
      ),
      bslib::card(
        bslib::card_header("Your table"),
        shiny::uiOutput(ns("table_state"))
      )
    )
  )
}

mod_play_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    state <- shiny::reactiveValues(
      game = NULL,
      log = character(0),
      pending_wild = NULL
    )

    say <- function(...) {
      state$log <- utils::head(c(paste0(...), state$log), 40L)
    }

    describe <- function(game) {
      top <- maumauR::mm_top_card(game)
      mm_card_text(top$type, top$color, top$value)
    }

    start_game <- function() {
      n <- as.integer(input$n_players)
      strategy <- mm_strategy_from(input$strategy)
      game <- maumauR::mm_new_game(
        n_players = n,
        strategies = rep(list(strategy), n),
        announce_penalty = isTRUE(input$announce_penalty)
      )
      state$game <- game
      state$pending_wild <- NULL
      state$log <- character(0)
      say("New game with ", n, " players. Face up: ", describe(game), ".")
    }

    # Let every artificial seat move until it is the human's turn again.
    run_opponents <- function() {
      game <- state$game
      guard <- 0L
      while (!is.null(game) && !game$finished && game$current != 1L &&
             guard < 200L) {
        seat <- game$current
        before <- length(game$hands[[seat]])
        game <- maumauR::mm_step(game)
        after <- length(game$hands[[seat]])
        say(
          "Seat ", seat,
          if (after < before) " played a card." else " drew a card.",
          " Face up: ", describe(game), "."
        )
        guard <- guard + 1L
      }
      state$game <- game
      announce_end(game)
    }

    announce_end <- function(game) {
      if (is.null(game) || !game$finished) {
        return(invisible(NULL))
      }
      if (is.na(game$winner)) {
        say("The game ended without a winner: nobody could move.")
      } else if (identical(game$winner, 1L)) {
        say("You win after ", game$turn, " turns.")
      } else {
        say("Seat ", game$winner, " wins after ", game$turn, " turns.")
      }
      invisible(NULL)
    }

    play_card <- function(position, color = NULL) {
      game <- state$game
      shiny::req(game, !game$finished, game$current == 1L)
      hand <- maumauR::mm_hand(game, player = 1L)
      if (position > nrow(hand) || !hand$legal[[position]]) {
        say("That card is not legal right now.")
        return(invisible(NULL))
      }
      played <- hand[position, ]
      state$game <- maumauR::mm_step(
        game,
        card = position,
        color = color,
        announce = TRUE
      )
      say(
        "You played ", mm_card_text(played$type, played$color, played$value),
        if (!is.null(color)) paste0(" and demanded ", color) else "",
        "."
      )
      announce_end(state$game)
      if (!state$game$finished) {
        run_opponents()
      }
    }

    # Deal a hand as soon as the inputs exist, so the tab is never empty.
    shiny::observeEvent(input$n_players, once = TRUE, {
      start_game()
    })

    shiny::observeEvent(input$new_game, {
      start_game()
    })

    shiny::observeEvent(input$draw, {
      game <- state$game
      shiny::req(game, !game$finished, game$current == 1L)
      before <- length(game$hands[[1L]])
      state$game <- maumauR::mm_step(game, card = NA_integer_)
      after <- length(state$game$hands[[1L]])
      say(
        if (after > before) "You drew a card." else "You passed.",
        " Face up: ", describe(state$game), "."
      )
      announce_end(state$game)
      if (!state$game$finished && state$game$current != 1L) {
        run_opponents()
      }
    })

    # One observer per card slot; a hand can never hold more cards than the
    # deck has.
    lapply(seq_len(32L), function(position) {
      shiny::observeEvent(input[[paste0("card_", position)]], {
        game <- state$game
        shiny::req(game, !game$finished, game$current == 1L)
        hand <- maumauR::mm_hand(game, player = 1L)
        shiny::req(position <= nrow(hand))
        if (identical(hand$type[[position]], "wild")) {
          state$pending_wild <- position
          shiny::showModal(shiny::modalDialog(
            title = "Choose a colour",
            shiny::radioButtons(
              session$ns("wild_color"),
              NULL,
              choices = game$spec$colours,
              inline = TRUE
            ),
            footer = shiny::tagList(
              shiny::modalButton("Cancel"),
              shiny::actionButton(
                session$ns("wild_ok"),
                "Play",
                class = "btn-primary"
              )
            ),
            easyClose = TRUE
          ))
        } else {
          play_card(position)
        }
      }, ignoreInit = TRUE)
    })

    shiny::observeEvent(input$wild_ok, {
      position <- state$pending_wild
      shiny::req(position, input$wild_color)
      shiny::removeModal()
      state$pending_wild <- NULL
      play_card(position, color = input$wild_color)
    })

    output$top_card <- shiny::renderUI({
      game <- state$game
      if (is.null(game)) {
        return(mm_empty_state("Press \"New game\" to deal a table."))
      }
      top <- maumauR::mm_top_card(game)
      shiny::tagList(
        shiny::div(
          class = "mm-hand",
          mm_card_tag(top$type, top$color, top$value, large = TRUE)
        ),
        shiny::p(
          mm_colour_dot(top$active_color),
          shiny::strong("Colour in force: "),
          shiny::span(class = "mm-swatch", top$active_color)
        ),
        shiny::div(
          class = "mm-stats",
          mm_stat("Turn", game$turn),
          mm_stat("Draw pile", length(game$draw)),
          if (game$pending_draw > 0L) {
            mm_stat("Stacked penalty", paste(game$pending_draw, "cards"))
          }
        )
      )
    })

    output$table_state <- shiny::renderUI({
      game <- state$game
      if (is.null(game)) {
        return(mm_empty_state("No table yet.", mark = "♠"))
      }
      sizes <- lengths(game$hands)
      seats <- seq_along(sizes)
      hand <- mm_safely(maumauR::mm_hand(game, player = 1L))
      playable <- !game$finished && game$current == 1L

      status <- if (game$finished) {
        if (is.na(game$winner)) {
          "Nobody could move: the game ended undecided."
        } else if (identical(game$winner, 1L)) {
          paste0("You win after ", game$turn, " turns.")
        } else {
          paste0("Seat ", game$winner, " wins after ", game$turn, " turns.")
        }
      } else if (playable) {
        "Your move."
      } else {
        paste0("Seat ", game$current, " is thinking.")
      }

      shiny::tagList(
        shiny::p(shiny::strong(status)),
        shiny::div(class = "mm-section", "Seats"),
        shiny::div(
          class = "mm-seats",
          lapply(seats, function(seat) {
            active <- !game$finished && game$current == seat
            who <- if (seat == 1L) "You" else paste("Seat", seat)
            # The count goes in a badge of its own. Set as plain text beside
            # the seat number it read "Seat 2 5 cards" - two numbers and a
            # space.
            shiny::div(
              class = paste(
                "mm-seat",
                if (active) "mm-seat-active" else ""
              ),
              title = paste0(who, ": ", mm_cards_word(sizes[[seat]])),
              shiny::span(class = "mm-seat-name", who),
              shiny::span(class = "mm-seat-count", sizes[[seat]]),
              shiny::span(
                class = "mm-seat-unit",
                if (sizes[[seat]] == 1L) "card" else "cards"
              )
            )
          })
        ),
        shiny::div(class = "mm-section", "Your hand"),
        if (is.null(hand) || nrow(hand) == 0L) {
          shiny::p("No cards left.")
        } else {
          shiny::div(
            class = "mm-hand",
            lapply(seq_len(nrow(hand)), function(i) {
              mm_card_tag(
                hand$type[[i]],
                hand$color[[i]],
                hand$value[[i]],
                id = session$ns(paste0("card_", i)),
                disabled = !(playable && hand$legal[[i]])
              )
            })
          )
        }
      )
    })

    output$log <- shiny::renderUI({
      if (length(state$log) == 0L) {
        return(mm_empty_state("The running commentary appears here."))
      }
      shiny::div(
        class = "mm-log",
        lapply(seq_along(state$log), function(i) {
          shiny::div(
            class = paste(
              "mm-log-line",
              if (i == 1L) "mm-log-line-latest" else ""
            ),
            state$log[[i]]
          )
        })
      )
    })
  })
}
