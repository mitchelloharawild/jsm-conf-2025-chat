read_md <- function(filepath) {
  paste(readLines(filepath), collapse = "\n")
}

## Use alternative to default ragnar retrieval tool
ragnar_register_tool_retrieve_vss <-
  function(chat, sessions_df, store, store_description = "the knowledge store", ...) {
    rlang::check_installed("ellmer")
    store
    list(...)
    
    chat$register_tool(
      ellmer::tool(
        .name = glue::glue("rag_retrieve_from_{store@name}"),
        function(text, filter_date = FALSE, date = NULL, session = FALSE) {
          results <- ragnar::ragnar_retrieve_vss(store, text, ...)$text
          # Filter out entries to be on the specific date
          
          if (filter_date) {
            results <- results[xml_extract(results, "date") == date]
          }
          result_session_id <- xml_extract(results, "session")
          if (session) {
            results <- session_info(sessions_df, unique(result_session_id))
          } else {
            results <- data.frame(id = result_session_id, talk = results) |> 
              inner_join(sessions_df |> select(-talks), by = "id") |> 
              with(paste0(
                "<session_title>", title, "</session_title>\n",
                "<session_type>", type, "</session_type>\n",
                "<location>", location, ", ", room, "</location>",
                talk
              ))
          }
          
          stringi::stri_flatten(results, "\n\n---\n\n")
        },
        glue::glue(
          "Given a string, retrieve the most relevent excerpts from {store_description}."
        ),
        text = ellmer::type_string(
          "The text to find the most relevent matches for."
        ),
        filter_date = ellmer::type_boolean(
          "TRUE if the prompt requests for information related to a specific day or time, FALSE otherwise."
        ),
        date = ellmer::type_string(
          "The date of requested talks in YYYY-MM-DD."
        ),
        session = ellmer::type_boolean(
          "TRUE if the prompt requests for a session of talks, FALSE if it enquires about specific talks or speakers."
        )
      )
    )
    invisible(chat)
  }

xml_extract <- function(x, dom) {
  xpath <- paste0("descendant-or-self::", dom)
  vapply(x, function(content) {
    xml2::read_html(content) |> 
      xml2::xml_find_all(xpath) |> 
      xml2::xml_text()
  }, character(1L)) |> 
    unname()
}

session_info <- function(data, id) {
  data |> 
    filter(id %in% .env$id) |> 
    rowwise() |> 
    mutate(talks = paste0(
      paste0(
        "<talk>\n",
        glue::glue_data(talks, "<title>{title}</title>\n<speaker>{speaker}</speaker>\n<abstract>{abstract}</abstract>"),
        "\n</talk>\n"
      ),
      collapse = "\n")
    ) |> 
    transmute(
      title,
      text = paste0(
        "<session>\n",
        "<title>", title, "</title>\n",
        "<type>", type, "</type>\n",
        "<date>", date, "</date>\n",
        "<time>", time, "</time>\n",
        "<location>", location, "</location>\n",
        "<room>", room, "</room>",
        talks,
        "</session>\n\n"
      )
    ) |> 
    pull(text)
}
