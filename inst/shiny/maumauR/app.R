# maumauR Shiny application.
#
# Tabs: (1) Play vs AI, (2) Win-rate explorer, (3) Strategy comparison,
# (4) Distributions. No packages are attached anywhere: every call is
# namespace qualified, and no asset is fetched from the internet.

for (mm_module in list.files("modules", pattern = "\\.R$", full.names = TRUE)) {
  source(mm_module, local = FALSE)
}
rm(mm_module)

# The application directory is named after the package that ships it, so the
# identity below is derived rather than hardcoded.
mm_package <- basename(getwd())
mm_url_field <- utils::packageDescription(mm_package)[["URL"]]
if (is.null(mm_url_field) || is.na(mm_url_field)) {
  mm_url_field <- ""
}
mm_urls <- strsplit(mm_url_field, ",\\s*")[[1L]]
mm_docs_url <- if (length(mm_urls) > 1L) mm_urls[[2L]] else mm_url_field

mm_theme <- bslib::bs_theme(
  version = 5,
  bg = "#FFFFFF",
  fg = "#1B2A3B",
  primary = "#0072B2",
  secondary = "#56B4E9",
  success = "#009E73",
  warning = "#E69F00",
  danger = "#D55E00"
)

mm_ui <- bslib::page_navbar(
  title = shiny::tagList(
    shiny::img(src = "logo.png", height = "34px", alt = "maumauR logo"),
    shiny::span(mm_package, class = "mm-title")
  ),
  theme = mm_theme,
  header = shiny::tags$head(
    shiny::tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "maumau.css"
    )
  ),
  bslib::nav_panel("Play vs AI", mod_play_ui("play")),
  bslib::nav_panel("Win rates", mod_win_rate_ui("win_rate")),
  bslib::nav_panel("Strategies", mod_strategy_ui("strategy")),
  bslib::nav_panel("Distributions", mod_distribution_ui("distribution")),
  bslib::nav_spacer(),
  bslib::nav_item(
    shiny::tags$a(
      "Documentation",
      href = mm_docs_url,
      target = "_blank",
      rel = "noopener"
    )
  )
)

mm_server <- function(input, output, session) {
  mod_play_server("play")
  mod_win_rate_server("win_rate")
  mod_strategy_server("strategy")
  mod_distribution_server("distribution")
}

shiny::shinyApp(ui = mm_ui, server = mm_server)
