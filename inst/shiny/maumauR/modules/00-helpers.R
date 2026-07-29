# Shared helpers for the maumauR application. No packages are attached
# anywhere in this application; everything is namespace qualified.

mm_strategy_choices <- c(
  "Greedy" = "greedy",
  "Random" = "random",
  "Hold wilds" = "hold_wilds"
)

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

# The face printed on a card.
mm_card_label <- function(type, value) {
  if (identical(type, "number")) {
    return(as.character(value))
  }
  switch(type, plus2 = "+2", skip = "skip", wild = "wild", "?")
}

# One card as an HTML tag. `on_click` turns it into a button.
mm_card_tag <- function(type, color, value, id = NULL, disabled = FALSE) {
  classes <- paste0(
    "mm-card mm-card-",
    if (is.na(color)) "wild" else color
  )
  label <- mm_card_label(type, value)
  if (is.null(id)) {
    return(shiny::tags$div(class = classes, label))
  }
  shiny::actionButton(
    inputId = id,
    label = label,
    class = paste(classes, if (disabled) "mm-card-muted" else ""),
    disabled = if (disabled) NA else NULL
  )
}

# A short human-readable description of a card.
mm_card_text <- function(type, color, value) {
  face <- mm_card_label(type, value)
  if (is.na(color)) {
    return(paste0("wild (", face, ")"))
  }
  paste(color, face)
}

# Guard a render expression: never let a transient state take the app down.
mm_safely <- function(expr, fallback = NULL) {
  tryCatch(expr, error = function(e) fallback)
}
