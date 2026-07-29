app_files <- function() {
  root <- system.file("shiny", "maumauR", package = "maumauR")
  if (!nzchar(root)) {
    return(character(0))
  }
  c(
    file.path(root, "app.R"),
    list.files(
      file.path(root, "modules"),
      pattern = "\\.R$",
      full.names = TRUE
    )
  )
}

test_that("the application ships with an entry point and modules", {
  files <- app_files()

  expect_true(length(files) > 1L)
  expect_true(all(file.exists(files)))
  expect_true(any(grepl("mod_play", files)))
  expect_true(any(grepl("mod_win_rate", files)))
  expect_true(any(grepl("mod_strategy", files)))
  expect_true(any(grepl("mod_distribution", files)))
})

test_that("every application file parses", {
  for (file in app_files()) {
    expect_no_error(parse(file))
  }
})

test_that("the application never attaches packages", {
  for (file in app_files()) {
    code <- readLines(file, warn = FALSE)
    expect_false(any(grepl("^\\s*(library|require)\\(", code)))
  }
})

test_that("module files define matching UI and server functions", {
  env <- new.env(parent = globalenv())
  modules <- setdiff(app_files(), grep("app\\.R$", app_files(), value = TRUE))
  for (file in modules) {
    sys.source(file, envir = env)
  }

  ui_fns <- grep("_ui$", ls(env), value = TRUE)
  server_fns <- grep("_server$", ls(env), value = TRUE)

  expect_true(length(ui_fns) >= 4L)
  expect_identical(
    sort(sub("_ui$", "", ui_fns)),
    sort(sub("_server$", "", server_fns))
  )
  for (fn in c(ui_fns, server_fns)) {
    expect_true(is.function(get(fn, envir = env)))
    expect_identical(names(formals(get(fn, envir = env)))[[1L]], "id")
  }
})

test_that("the logo is wired into the application", {
  root <- system.file("shiny", "maumauR", package = "maumauR")
  expect_true(file.exists(file.path(root, "www", "logo.png")))
  expect_true(file.exists(file.path(root, "www", "maumau.css")))
})

test_that("mm_run_app() reports missing optional packages", {
  expect_true(is.function(mm_run_app))
  expect_identical(names(formals(mm_run_app)), c("...", "call"))

  local_mocked_bindings(.has_package = function(pkg) FALSE)
  expect_error(mm_run_app(), "shiny")
})

test_that("mm_run_app() reports a missing application directory", {
  local_mocked_bindings(
    .has_package = function(pkg) TRUE,
    .app_dir = function(pkg) ""
  )
  expect_error(mm_run_app(), "Could not find the application")
})
