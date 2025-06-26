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
