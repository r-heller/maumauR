# Tab 4: game-length and draw-count distributions.

mod_distribution_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      title = "Simulation",
      width = 260,
      shiny::checkboxGroupInput(
        ns("player_counts"),
        "Player counts",
        choices = c(2, 3, 4),
        selected = c(2, 3, 4),
        inline = TRUE
      ),
      shiny::sliderInput(
        ns("n"),
        "Games per player count",
        min = 50,
        max = 1000,
        value = 200,
        step = 50,
        ticks = FALSE
      ),
      shiny::sliderInput(
        ns("bins"),
        "Histogram bins",
        min = 5,
        max = 60,
        value = 25,
        step = 5,
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
        "Both panels share an x scale across player counts, so the panels",
        "can be read against each other."
      )
    ),
    # Full width, one above the other. Side by side, three histogram panels had
    # about 130 px each and their tick labels ran into one another.
    bslib::layout_columns(
      col_widths = c(12, 12),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          "How long is a game?",
          shiny::uiOutput(ns("scenario"), inline = TRUE)
        ),
        shiny::plotOutput(ns("length_plot"), height = "330px"),
        mm_scroll_table(ns("length_table"))
      ),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          "How much gets drawn?",
          shiny::uiOutput(ns("scenario_draw"), inline = TRUE)
        ),
        shiny::plotOutput(ns("draw_plot"), height = "330px"),
        mm_scroll_table(ns("draw_table"))
      )
    )
  )
}

mod_distribution_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    sims <- shiny::eventReactive(input$run, ignoreNULL = FALSE, {
      shiny::req(input$player_counts, input$n)
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

    scenario <- shiny::reactive({
      shiny::req(input$n, input$player_counts)
      shiny::span(
        class = "mm-scenario",
        paste(
          input$n, "games each",
          "·", mm_strategy_title(input$strategy)
        )
      )
    })

    output$scenario <- shiny::renderUI(scenario())
    output$scenario_draw <- shiny::renderUI(scenario())

    output$length_plot <- shiny::renderPlot(res = mm_plot_res, {
      shiny::req(sims())
      mm_plot_safely(
        maumauR::mm_plot_game_length(sims(), bins = as.integer(input$bins))
      )
    })

    output$draw_plot <- shiny::renderPlot(res = mm_plot_res, {
      shiny::req(sims())
      mm_plot_safely(
        maumauR::mm_plot_draws(sims(), bins = as.integer(input$bins))
      )
    })

    output$length_table <- shiny::renderTable(
      striped = TRUE,
      hover = TRUE,
      spacing = "s",
      {
        shiny::req(sims())
        mm_tidy_table(mm_safely(maumauR::mm_game_length(sims())))
      }
    )

    output$draw_table <- shiny::renderTable(
      striped = TRUE,
      hover = TRUE,
      spacing = "s",
      {
        shiny::req(sims())
        mm_tidy_table(mm_safely(maumauR::mm_draw_summary(sims())))
      }
    )
  })
}
