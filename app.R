library(ragnar)
library(shiny)
library(shinychat)

store_location <- file.path("data", "posit-conf-2025.ragnar.duckdb")
store <- ragnar::ragnar_store_connect(store_location, read_only = TRUE)

read_md <- function(filepath) {
  paste(readLines(filepath), collapse = "\n")
}

## Use alternative to default ragnar retrieval tool
ragnar_register_tool_retrieve_vss <-
  function(chat, store, store_description = "the knowledge store", ...) {
    rlang::check_installed("ellmer")
    store
    list(...)
    
    chat$register_tool(
      ellmer::tool(
        .name = glue::glue("rag_retrieve_from_{store@name}"),
        function(text, status_ignore_workshops = status_ignore_workshops) {
          results <- ragnar::ragnar_retrieve_vss(store, text, ...)$text
          # Filter out entries containing 'workshop' if the toggle is on
          if (status_ignore_workshops) {
            results <- results[!grepl("workshop", results, ignore.case = TRUE)]
          }
          stringi::stri_flatten(results, "\n\n---\n\n")
        },
        glue::glue(
          "Given a string, retrieve the most relevent excerpts from {store_description}."
        ),
        text = ellmer::type_string(
          "The text to find the most relevent matches for."
        ),
        status_ignore_workshops = ellmer::type_boolean(
          "Whether to ignore workshops in the results."
        )
      )
    )
    invisible(chat)
  }

last_updated <- readLines(file.path("data", "retrieval-date.txt")) |>
  as.Date(format = "%Y-%m-%d")

system_prompt <- ellmer::interpolate_file(
  "system-prompt.md", 
  event_info = read_md("event-info.md"),
  status_ignore_workshops = FALSE
)

welcome_message <- ellmer::interpolate_file(
  "welcome-message.md", update_date = last_updated
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
  chat <- ellmer::chat_openai(
    system_prompt = system_prompt,
    model = "gpt-4.1-mini",
    api_args = list(temperature = 0.2)
  )
  ragnar_register_tool_retrieve_vss(chat, store, top_k = 10)
  
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    shinychat::chat_append("chat", stream)
    if (grepl("error occurred", stream, ignore.case = TRUE)) {
      showNotification(
        "You have reached the rate limit for the chat service. Please wait a moment and try again. You will need to refresh the page to reset the chat.",
        type = "error"
      )
    }
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

