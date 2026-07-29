# Shared helpers for the maumauR application. No packages are attached
# anywhere in this application; everything is namespace qualified.

# The suite accent carries the chrome; the deck colours carry the cards.
mm_accent <- "#5E2C8E"
mm_ink <- "#1B2A3B"

# Every plot in the app is drawn at this resolution. The Shiny default of 72
# dpi renders publication-sized type at about six pixels, which is unreadable.
mm_plot_res <- 108

mm_strategy_choices <- c(
  "Greedy" = "greedy",
  "Random" = "random",
  "Hold wilds" = "hold_wilds"
)

# The largest table the interface offers.
mm_max_players <- 4L

# The strategy a seat starts on: the three of them in turn, so that the strategy
# tab opens on a genuinely mixed table.
mm_default_seat <- function(seat) {
  unname(mm_strategy_choices[[1L + (seat - 1L) %% length(mm_strategy_choices)]])
}

# Turn a strategy label from the interface into a strategy object.
mm_strategy_from <- function(name) {
  switch(
    name,
    greedy = maumauR::mm_strategy_greedy(),
    random = maumauR::mm_strategy_random(),
    hold_wilds = maumauR::mm_strategy_hold_wilds(),
    maumauR::mm_strategy_greedy()
  )
}

# The interface label for a strategy key, for card headers and captions.
mm_strategy_title <- function(name) {
  hit <- names(mm_strategy_choices)[match(name, mm_strategy_choices)]
  ifelse(is.na(hit), name, hit)
}

# The face printed on a card.
mm_card_label <- function(type, value) {
  if (identical(type, "number")) {
    return(as.character(value))
  }
  switch(type, plus2 = "+2", skip = "Skip", wild = "Wild", "?")
}

# One card as an HTML tag. `id` turns it into a button.
mm_card_tag <- function(type, color, value, id = NULL, disabled = FALSE,
                        large = FALSE) {
  classes <- paste(
    "mm-card",
    paste0("mm-card-", if (is.na(color)) "wild" else color),
    if (large) "mm-card-top" else "",
    if (disabled) "mm-card-muted" else ""
  )
  face <- mm_card_label(type, value)
  label <- if (identical(type, "number")) {
    face
  } else {
    shiny::span(class = "mm-card-face", face)
  }
  alt <- mm_card_text(type, color, value)
  if (is.null(id)) {
    return(shiny::tags$div(class = classes, title = alt, label))
  }
  # `disabled` is a formal argument of `actionButton()` and wants a plain
  # logical. Handed the `NA` that would make an HTML boolean attribute, it
  # renders no attribute at all, and an illegal card that merely looked disabled
  # stayed clickable and keyboard-reachable - clicking one answered "that card
  # is not legal right now" instead of nothing.
  shiny::actionButton(
    inputId = id,
    label = label,
    class = classes,
    title = if (disabled) paste0(alt, " (not legal now)") else paste("Play", alt),
    disabled = isTRUE(disabled)
  )
}

# A short human-readable description of a card, for prose rather than for a
# card face, so the face is lower case: "blue skip", not "blue Skip".
mm_card_text <- function(type, color, value) {
  face <- mm_card_label(type, value)
  if (!identical(type, "number")) {
    face <- tolower(face)
  }
  if (is.na(color)) {
    return("a wild card")
  }
  paste(color, face)
}

# A coloured dot for the colour currently in force.
mm_colour_dot <- function(color) {
  fills <- c(
    red = "#D55E00", green = "#009E73",
    blue = "#0072B2", yellow = "#E69F00"
  )
  fill <- if (is.na(color) || !color %in% names(fills)) {
    "#B9BEC7"
  } else {
    unname(fills[[color]])
  }
  shiny::span(
    class = "mm-dot",
    style = paste0("background-color:", fill, ";")
  )
}

# "1 card" / "5 cards".
mm_cards_word <- function(n) {
  paste(n, if (n == 1L) "card" else "cards")
}

# A labelled figure for the stat strip.
mm_stat <- function(label, value) {
  shiny::div(
    shiny::span(class = "mm-stat-label", label),
    shiny::span(class = "mm-stat-value", value)
  )
}

# What a panel shows before it has anything to show.
mm_empty_state <- function(text, mark = "♣") {
  shiny::div(
    class = "mm-empty",
    shiny::div(class = "mm-empty-mark", mark),
    shiny::div(class = "mm-empty-text", text)
  )
}

# Human column names and rounded numbers for the summary tables, wrapped so
# that a wide table scrolls inside its card instead of being clipped by it.
mm_table_labels <- c(
  n_players = "Players",
  seat = "Seat",
  strategy = "Strategy",
  wins = "Wins",
  games = "Games",
  win_rate = "Win rate",
  mean_turns = "Mean", sd_turns = "SD", min_turns = "Min",
  median_turns = "Median", max_turns = "Max",
  mean_draws = "Mean", sd_draws = "SD", min_draws = "Min",
  median_draws = "Median", max_draws = "Max"
)

# A column the interface has already fixed carries no information: on the
# win-rate tab every row says "3" under Players and "Greedy" under Strategy,
# and the card header says both once. Seats and counts are never dropped.
mm_drop_constant <- function(x, columns = c("n_players", "strategy")) {
  for (column in intersect(columns, names(x))) {
    if (length(unique(x[[column]])) <= 1L && nrow(x) > 1L) {
      x[[column]] <- NULL
    }
  }
  x
}

mm_tidy_table <- function(x) {
  if (is.null(x) || nrow(x) == 0L) {
    return(NULL)
  }
  x <- mm_drop_constant(as.data.frame(x))
  if ("win_rate" %in% names(x)) {
    x$win_rate <- ifelse(
      is.na(x$win_rate),
      "–",
      paste0(formatC(100 * x$win_rate, format = "f", digits = 1L), "%")
    )
  }
  if ("strategy" %in% names(x)) {
    pretty <- gsub("_", " ", x$strategy)
    substr(pretty, 1L, 1L) <- toupper(substr(pretty, 1L, 1L))
    x$strategy <- pretty
  }
  # Averages and spreads earn a decimal; counts of turns and cards do not.
  for (column in intersect(names(x), c("mean_turns", "sd_turns",
                                       "mean_draws", "sd_draws"))) {
    x[[column]] <- formatC(x[[column]], format = "f", digits = 1L)
  }
  for (column in intersect(names(x), c("min_turns", "median_turns",
                                       "max_turns", "min_draws",
                                       "median_draws", "max_draws"))) {
    x[[column]] <- formatC(x[[column]], format = "f", digits = 0L)
  }
  known <- names(x) %in% names(mm_table_labels)
  names(x)[known] <- unname(mm_table_labels[names(x)[known]])
  x
}

mm_scroll_table <- function(output_id) {
  shiny::div(class = "mm-scroll-x", shiny::tableOutput(output_id))
}

# The card header already names the figure and the scenario it was run under, so
# the plot's own title and caption would say both a second time. The subtitle
# stays: it is the only thing that explains the dashed line.
mm_untitled <- function(p) {
  p + ggplot2::labs(title = NULL, caption = NULL)
}

# A plot that carries a message, so a failed or empty run still renders
# something readable instead of a blank rectangle.
mm_plot_message <- function(text) {
  ggplot2::ggplot() +
    ggplot2::annotate(
      "text",
      x = 0, y = 0,
      label = text,
      colour = "#5B6675",
      size = 4
    ) +
    ggplot2::theme_void()
}

# Guard a render expression: never let a transient state take the app down.
mm_safely <- function(expr, fallback = NULL) {
  tryCatch(expr, error = function(e) fallback)
}

# The same guard for plots, with a legible fallback.
mm_plot_safely <- function(expr) {
  out <- tryCatch(expr, error = function(e) NULL)
  if (is.null(out)) {
    return(mm_plot_message("Nothing to draw for this setting."))
  }
  mm_untitled(out)
}
