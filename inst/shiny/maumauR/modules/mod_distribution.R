# Tab 4: game-length and draw-count distributions.

mod_distribution_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Simulation",
      shiny::checkboxGroupInput(
        ns("player_counts"),
        "Player counts",
        choices = c(2, 3, 4),
        selected = c(2, 3, 4)
      ),
      shiny::sliderInput(
        ns("n"),
        "Games per player count",
        min = 50,
        max = 1000,
        value = 200,
        step = 50
      ),
      shiny::sliderInput(
        ns("bins"),
        "Histogram bins",
        min = 5,
        max = 60,
        value = 25,
        step = 5
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
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(
        bslib::card_header("Game length"),
        shiny::plotOutput(ns("length_plot"), height = "320px"),
        shiny::tableOutput(ns("length_table"))
      ),
      bslib::card(
        bslib::card_header("Cards drawn"),
        shiny::plotOutput(ns("draw_plot"), height = "320px"),
        shiny::tableOutput(ns("draw_table"))
      )
    )
  )
}

mod_distribution_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    sims <- shiny::eventReactive(input$run, {
      shiny::req(input$player_counts)
      counts <- as.integer(input$player_counts)
      strategy <- mm_strategy_from(input$strategy)
      mm_safely({
        runs <- lapply(counts, function(count) {
          maumauR::mm_simulate(
            n = as.integer(input$n),
            n_players = count,
            strategies = strategy,
            seed = as.integer(input$seed)
          )
        })
        dplyr::bind_rows(runs)
      })
    })

    output$length_plot <- shiny::renderPlot({
      shiny::req(sims())
      mm_safely(
        maumauR::mm_plot_game_length(sims(), bins = as.integer(input$bins))
      )
    })

    output$draw_plot <- shiny::renderPlot({
      shiny::req(sims())
      mm_safely(
        maumauR::mm_plot_draws(sims(), bins = as.integer(input$bins))
      )
    })

    output$length_table <- shiny::renderTable({
      shiny::req(sims())
      mm_safely(maumauR::mm_game_length(sims()))
    })

    output$draw_table <- shiny::renderTable({
      shiny::req(sims())
      mm_safely(maumauR::mm_draw_summary(sims()))
    })
  })
}
