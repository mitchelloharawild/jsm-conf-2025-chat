library(ragnar)
library(shiny)
library(shinychat)

store_location <- "posit-conf-2025.ragnar.duckdb"
store <- ragnar::ragnar_store_connect(store_location, read_only = TRUE)

read_prompt <- function(filepath) {
  paste(readLines(filepath), collapse = "\n")
}

welcome_message <- "Hello! Welcome to Posit Conf 2025! 🎉 I'm a chat bot designed to help you find information about the sessions at this year's conference. If you have any questions about the sessions, speakers, feel free to ask. This app is **not** officially affiliated with Posit, but it uses agenda data from the conference website.

Here are some examples:
- 'Are there any sessions about causal inference?'
- 'What talks is Hadley giving this year?'
- 'I'm interested in learning about ellmer, what sessions should I attend?'

Let's get started! Type your question below, and I'll do my best to assist you. 😊"

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
      p("Welcome to a chat bot for posit::conf(2025)! Start by typing in a question."),
      p("This chat interface allows you to ask questions about the sessions at posit::conf(2025)."),
      p("The chat is powered ellmer using an OpenAI model and retrieves relevant information from a ragnar knowledge store."),
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
    model = "gpt-4o-mini",
    api_args = list(temperature = 0.4)
  )
  ragnar_register_tool_retrieve_vss(chat, store, top_k = 10)
  
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    shinychat::chat_append("chat", stream)
  })
}

shinyApp(ui, server)
