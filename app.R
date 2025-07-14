library(ragnar)
library(shiny)
library(shinychat)

source("scripts/utilities.R")

store_location <- file.path("data", "posit-conf-2025.ragnar.duckdb")
store <- ragnar::ragnar_store_connect(store_location, read_only = TRUE)

last_updated <- readLines(file.path("data", "retrieval-date.txt")) |>
  as.Date(format = "%Y-%m-%d")

system_prompt <- ellmer::interpolate_file(
  "system-prompt.md",
  event_info = read_md("event-info.md"),
  status_ignore_workshops = FALSE
)

welcome_message <- ellmer::interpolate_file(
  "welcome-message.md",
  update_date = last_updated
)

ui <- bslib::page_sidebar(
  # Custom header row with title and smaller settings button
  tags$div(
    style = "display: flex; align-items: center; justify-content: space-between; width: 100%; position: relative; z-index: 1000; margin-bottom: 0.25rem;",
    tags$h4("posit::conf(2025) chat", style = "margin: 0;"),
    actionButton(
      "open_settings",
      label = NULL,
      icon = shiny::icon("gear"),
      class = "btn-default",
      style = "margin-left: auto; padding: 0.2rem 0.4rem; font-size: 1.1rem; height: 2rem; width: 2rem; min-width: 2rem; border: none; background: transparent; color: #495057; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: none;",
    )
  ),
  sidebar = bslib::sidebar(
    p("Welcome to a chat bot for posit::conf(2025)! Start by typing in a question."),
    p("This chat interface allows you to ask questions about the sessions at posit::conf(2025)."),
    p("The chat is powered by ellmer using an OpenAI model and retrieves relevant information from a ragnar knowledge store."),
    class = "text-center"
  ),
  shinychat::chat_ui(
    "chat",
    messages = welcome_message
  )
)

server <- function(input, output, session) {
  chat <- ellmer::chat_anthropic(
    system_prompt = system_prompt,
    api_args = list(temperature = 0.2)
  )
  ragnar_register_tool_retrieve_vss(chat, store, top_k = 10)

  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    shinychat::chat_append("chat", stream)
  })

  observeEvent(input$open_settings, {
    showModal(
      modalDialog(
        title = "Settings",
        bslib::input_switch("switch_workshops", "Ignore all workshops", value = isTRUE(input$switch_workshops)),
        easyClose = TRUE
      )
    )
  })

  observeEvent(input$switch_workshops, {
    chat$set_system_prompt(
      ellmer::interpolate_file(
        "system-prompt.md",
        event_info = read_md("event-info.md"),
        status_ignore_workshops = input$switch_workshops
      )
    )
  })
}

shinyApp(ui, server)
