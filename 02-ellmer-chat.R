library(ellmer)
library(ragnar)

store_location <- file.path("data", "posit-conf-2025.ragnar.duckdb")
store <- ragnar::ragnar_store_connect(store_location, read_only = TRUE)

read_prompt <- function(filepath) {
  paste(readLines(filepath), collapse = "\n")
}

system_prompt <- read_prompt("system-prompt.md")

chat <- ellmer::chat_openai(
  system_prompt,
  model = "gpt-4o-mini",
  api_args = list(temperature = .5)
)

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

ragnar_register_tool_retrieve_vss(chat, store, top_k = 10)

chat$chat("What sessions are on casual inference?")
