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
mm_description <- utils::packageDescription(mm_package)
mm_url_field <- mm_description[["URL"]]
if (is.null(mm_url_field) || is.na(mm_url_field)) {
  mm_url_field <- ""
}
mm_urls <- strsplit(mm_url_field, ",\\s*")[[1L]]
mm_docs_url <- if (length(mm_urls) > 1L) mm_urls[[2L]] else mm_url_field

mm_theme_bs <- bslib::bs_theme(
  version = 5,
  bg = "#FFFFFF",
  fg = mm_ink,
  primary = mm_accent,
  secondary = "#56B4E9",
  success = "#009E73",
  warning = "#E69F00",
  danger = "#D55E00",
  base_font = c(
    "system-ui", "-apple-system", "Segoe UI", "Roboto",
    "Helvetica Neue", "Arial", "sans-serif"
  )
)

mm_ui <- bslib::page_navbar(
  title = shiny::tagList(
    shiny::img(src = "logo.png", height = "36px", alt = "maumauR logo"),
    shiny::div(
      class = "d-inline-block align-middle",
      shiny::span(mm_package, class = "mm-title"),
      shiny::span("Mau Mau, simulated", class = "mm-tagline")
    )
  ),
  window_title = paste(mm_package, "- Mau Mau, simulated"),
  theme = mm_theme_bs,
  header = shiny::tagList(
    shiny::tags$head(
      shiny::tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = "maumau.css"
      )
    ),
    # A run over three player counts takes several seconds. Without this the
    # distribution tab is two large blank white cards for the whole of it, with
    # nothing to say that anything is happening.
    shiny::useBusyIndicators(spinners = TRUE, pulse = TRUE),
    shiny::busyIndicatorOptions(
      spinner_type = "ring2",
      spinner_color = mm_accent,
      spinner_size = "3rem",
      pulse_background = paste0(
        "linear-gradient(120deg, #F1ECF8, ", mm_accent, ")"
      )
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
