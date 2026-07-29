# Tab 3: put strategies against each other, one per seat.

mod_strategy_ui <- function(id) {
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
      # All four seat pickers exist from the moment the page loads, and the ones
      # past the table size are hidden rather than absent. Built by
      # `renderUI()` they did not yet exist when the simulation first ran, so
      # the opening figure was an all-greedy table while the sidebar and the
      # card header both said "Greedy vs Random vs Hold wilds".
      lapply(seq_len(mm_max_players), function(seat) {
        shiny::conditionalPanel(
          condition = paste("input.n_players >=", seat),
          ns = ns,
          shiny::selectInput(
            ns(paste0("seat_", seat)),
            paste("Seat", seat),
            choices = mm_strategy_choices,
            selected = mm_default_seat(seat)
          )
        )
      }),
      shiny::sliderInput(
        ns("n"),
        "Games",
        min = 50,
        max = 1000,
        value = 200,
        step = 50,
        ticks = FALSE
      ),
      shiny::numericInput(ns("seed"), "Seed", value = 1, min = 1, step = 1),
      shiny::actionButton(ns("run"), "Run", class = "btn-primary"),
      shiny::p(
        class = "mm-help",
        "Seat one always moves first, so give a strategy several seats",
        "before reading much into a small gap."
      )
    ),
    bslib::layout_columns(
      col_widths = c(7, 5),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          "Which strategy wins?",
          shiny::uiOutput(ns("scenario"), inline = TRUE)
        ),
        shiny::plotOutput(ns("plot"), height = "380px")
      ),
      bslib::card(
        class = "mm-fit",
        bslib::card_header("Seat by seat"),
        mm_scroll_table(ns("table"))
      )
    )
  )
}

mod_strategy_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    picks <- shiny::reactive({
      seats <- seq_len(as.integer(input$n_players))
      vapply(
        seats,
        function(seat) {
          value <- input[[paste0("seat_", seat)]]
          if (is.null(value)) mm_default_seat(seat) else value
        },
        character(1L)
      )
    })

    sims <- shiny::eventReactive(input$run, ignoreNULL = FALSE, {
      shiny::req(input$n, input$n_players)
      chosen <- picks()
      mm_safely(
        maumauR::mm_simulate(
          n = as.integer(input$n),
          n_players = length(chosen),
          strategies = lapply(chosen, mm_strategy_from),
          seed = as.integer(input$seed)
        )
      )
    })

    output$scenario <- shiny::renderUI({
      shiny::req(input$n, input$n_players)
      shiny::span(
        class = "mm-scenario",
        paste(
          input$n, "games",
          "·", paste(mm_strategy_title(picks()), collapse = " vs ")
        )
      )
    })

    output$plot <- shiny::renderPlot(res = mm_plot_res, {
      shiny::req(sims())
      mm_plot_safely(maumauR::mm_plot_strategy_compare(sims()))
    })

    output$table <- shiny::renderTable(
      striped = TRUE,
      hover = TRUE,
      spacing = "s",
      {
        shiny::req(sims())
        mm_tidy_table(mm_safely(maumauR::mm_win_rate(sims())))
      }
    )
  })
}
