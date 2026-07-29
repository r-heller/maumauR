# Tab 3: put strategies against each other, one per seat.

mod_strategy_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Table",
      shiny::sliderInput(
        ns("n_players"),
        "Players",
        min = 2,
        max = 4,
        value = 3,
        step = 1
      ),
      shiny::uiOutput(ns("seats")),
      shiny::sliderInput(
        ns("n"),
        "Games",
        min = 50,
        max = 1000,
        value = 200,
        step = 50
      ),
      shiny::numericInput(ns("seed"), "Seed", value = 1, min = 1, step = 1),
      shiny::actionButton(ns("run"), "Run", class = "btn-primary")
    ),
    bslib::card(
      bslib::card_header("Mean win rate per seat held"),
      shiny::plotOutput(ns("plot"), height = "380px")
    ),
    bslib::card(
      bslib::card_header("By seat"),
      shiny::tableOutput(ns("table"))
    )
  )
}

mod_strategy_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    output$seats <- shiny::renderUI({
      shiny::req(input$n_players)
      seats <- seq_len(as.integer(input$n_players))
      defaults <- rep_len(names(mm_strategy_choices), length(seats))
      shiny::tagList(lapply(seats, function(seat) {
        shiny::selectInput(
          session$ns(paste0("seat_", seat)),
          paste("Seat", seat),
          choices = mm_strategy_choices,
          selected = unname(mm_strategy_choices[[defaults[[seat]]]])
        )
      }))
    })

    sims <- shiny::eventReactive(input$run, {
      seats <- seq_len(as.integer(input$n_players))
      picks <- vapply(
        seats,
        function(seat) {
          value <- input[[paste0("seat_", seat)]]
          if (is.null(value)) "greedy" else value
        },
        character(1L)
      )
      mm_safely(
        maumauR::mm_simulate(
          n = as.integer(input$n),
          n_players = length(seats),
          strategies = lapply(picks, mm_strategy_from),
          seed = as.integer(input$seed)
        )
      )
    })

    output$plot <- shiny::renderPlot({
      shiny::req(sims())
      mm_safely(maumauR::mm_plot_strategy_compare(sims()))
    })

    output$table <- shiny::renderTable({
      shiny::req(sims())
      mm_safely(maumauR::mm_win_rate(sims()))
    })
  })
}
