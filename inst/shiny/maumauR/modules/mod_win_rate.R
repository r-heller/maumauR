# Tab 2: win rate by seat, simulated live.

mod_win_rate_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      title = "Simulation",
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
      shiny::sliderInput(
        ns("n"),
        "Games",
        min = 50,
        max = 1000,
        value = 200,
        step = 50,
        ticks = FALSE
      ),
      shiny::selectInput(
        ns("strategy"),
        "Every seat plays",
        choices = mm_strategy_choices,
        selected = "greedy"
      ),
      shiny::numericInput(ns("seed"), "Seed", value = 1, min = 1, step = 1),
      shiny::actionButton(ns("run"), "Run", class = "btn-primary"),
      shiny::p(
        class = "mm-help",
        "Every seat plays the same strategy, so any difference between the",
        "bars is the seat itself."
      )
    ),
    bslib::layout_columns(
      col_widths = c(7, 5),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          "Does the seat matter?",
          shiny::uiOutput(ns("scenario"), inline = TRUE)
        ),
        # Three bars in a seven-column card: 430 px keeps the panel close to
        # 3:2. Stretched to the full viewport height the bars turned into
        # 600 px slivers.
        shiny::plotOutput(ns("plot"), height = "430px")
      ),
      bslib::card(
        class = "mm-fit",
        bslib::card_header("The numbers behind the bars"),
        mm_scroll_table(ns("table"))
      )
    )
  )
}

mod_win_rate_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    # `ignoreNULL = FALSE` runs once on load, so the tab is never a blank card.
    sims <- shiny::eventReactive(input$run, ignoreNULL = FALSE, {
      shiny::req(input$n, input$n_players)
      mm_safely(
        maumauR::mm_simulate(
          n = as.integer(input$n),
          n_players = as.integer(input$n_players),
          strategies = mm_strategy_from(input$strategy),
          seed = as.integer(input$seed)
        )
      )
    })

    output$scenario <- shiny::renderUI({
      shiny::req(input$n, input$n_players, input$strategy)
      shiny::span(
        class = "mm-scenario",
        paste(
          input$n_players, "players",
          "·", input$n, "games",
          "·", mm_strategy_title(input$strategy)
        )
      )
    })

    output$plot <- shiny::renderPlot(res = mm_plot_res, {
      shiny::req(sims())
      mm_plot_safely(maumauR::mm_plot_win_rate(sims()))
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
