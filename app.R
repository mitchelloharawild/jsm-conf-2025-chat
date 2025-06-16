library(ragnar)
library(shiny)
library(shinychat)

store_location <- "posit-conf-2025.ragnar.duckdb"
store <- ragnar::ragnar_store_connect(store_location, read_only = TRUE)

read_prompt <- function(filepath) {
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
        function(text) {
          ragnar::ragnar_retrieve_vss(store, text, ...)$text |>
            stringi::stri_flatten("\n\n---\n\n")
        },
        glue::glue(
          "Given a string, retrieve the most relevent excerpts from {store_description}."
        ),
        text = ellmer::type_string(
          "The text to find the most relevent matches for."
        )
      )
    )
    invisible(chat)
  }


system_prompt <- read_prompt("system-prompt.md")

ui <- bslib::page_sidebar(
  title = "posit::conf(2025) chat",
  sidebar = bslib::sidebar(
      p("Welcome to this chat instance! Start by typing in a question."),
      p("This chat interface allows you to ask questions about the sessions at the posit::conf(2025)."),
      p("The chat is powered ellmer using an OpenAI model and retrieves relevant information from a ragnar knowledge store."),
      class = "text-center"
  ),
  shinychat::chat_ui("chat")
)

server <- function(input, output, session) {
  chat <- ellmer::chat_openai(
    system_prompt = system_prompt,
    model = "gpt-4o-mini",
    api_args = list(temperature = .5)
  )
  ragnar_register_tool_retrieve_vss(chat, store, top_k = 10)
  
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
