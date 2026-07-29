# Tab 2: win rate by seat, simulated live.

mod_win_rate_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Simulation",
      shiny::sliderInput(
        ns("n_players"),
        "Players",
        min = 2,
        max = 4,
        value = 3,
        step = 1
      ),
      shiny::sliderInput(
        ns("n"),
        "Games",
        min = 50,
        max = 1000,
        value = 200,
        step = 50
      ),
      shiny::selectInput(
        ns("strategy"),
        "Every seat plays",
        choices = mm_strategy_choices,
        selected = "greedy"
      ),
      shiny::numericInput(ns("seed"), "Seed", value = 1, min = 1, step = 1),
      shiny::actionButton(ns("run"), "Run", class = "btn-primary")
    ),
    bslib::card(
      bslib::card_header("Win rate by seat"),
      shiny::plotOutput(ns("plot"), height = "380px")
    ),
    bslib::card(
      bslib::card_header("Numbers"),
      shiny::tableOutput(ns("table"))
    )
  )
}

mod_win_rate_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    sims <- shiny::eventReactive(input$run, {
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

    output$plot <- shiny::renderPlot({
      shiny::req(sims())
      mm_safely(maumauR::mm_plot_win_rate(sims()))
    })

    output$table <- shiny::renderTable({
      shiny::req(sims())
      mm_safely(maumauR::mm_win_rate(sims()))
    })
  })
}
