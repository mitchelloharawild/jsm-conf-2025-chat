library(tibble)
library(dplyr)
library(purrr)
library(httr2)
library(rvest)
library(vctrs)
library(ellmer)

events <- rvest::read_html("https://ww3.aievolution.com/JSMAnnual2025/Events/pubSearchEvents?style=0")

table_rows <- events |>
  html_elements("tr")

row_id <- html_attr(table_rows, "id")

row_dates <- which(row_id == "_dateHeader")
rows_split <- map2(row_dates+1, c(row_dates[-1], length(table_rows)), \(start, end) table_rows[start:end])

event_dates <- as.Date("2025-08-01") + 0:6

# Get event IDs for each day
event_ids <- rows_split |>
  map(function(day) {
    html_elements(day, ".eventTitle>a") |>
      html_attr("href") |>
      sub(".*previewEvent\\((\\d+)\\).*", "\\1", x = _)
  })
# Get event titles for each day

event_titles <- rows_split |>
  map(function(day) {
    html_elements(day, ".eventTitle>a") |>
      html_attr("title")
  })

# Get event types for each day
event_types <- rows_split |>
  map(function(day) {
    html_elements(day[which(html_attr(day, "class") %in% c("row", "rowalt"))], "td:last-of-type") |>
      html_text()
  })


jsm_sessions <-
  tibble(
    date = rep(event_dates, lengths(event_ids)),
    id = unlist(event_ids),
    title = unlist(event_titles),
    type = unlist(event_types)
  )

jsm_sessions |>
  dplyr::count(type)

# Scrape event content
get_event_talks <- function(id) {
  path <- paste0("data/jsm-events/", id, ".rds")
  if(file.exists(path)) return(readRDS(path))

  event_url <- request("https://ww3.aievolution.com/JSMAnnual2025/Events/viewEv")
  event_html <- req_url_query(event_url, ev = id) |>
    req_perform() |>
    resp_body_html()

  event_time <- html_nodes(event_html, ".eventinfo > .datetime > .time") |> html_text2()
  # event_type <- html_nodes(event_html, "#eventPreview_eventType") |> html_text2()
  event_location <- html_nodes(event_html, "#eventPreview_location") |> html_text2()
  event_room <- html_nodes(event_html, "#eventPreview_roomAssignments") |> html_text2()

  talk_titles <- html_nodes(event_html, ".presentation-title") |> html_text2() |>
    gsub("^[ \t\r\n]+|[ \t\r\n]+$", "", x = _)
  talk_abstracts <- html_nodes(event_html, ".presentationPreview_description") |> html_text2()
  talk_speakers <- html_nodes(event_html, "div em.speakername:last-of-type") |> html_text2()
  
  # Fallback to LLM extraction
  talks <- if(n_distinct(lengths(list(talk_titles, talk_abstracts, talk_speakers))) > 1) {
    chat <- chat_openai("Extract talk details from the following HTML")
    
    chat$chat_structured(
      as.character(html_nodes(event_html, ".event")),
      type = type_array(
        type_object(
          title = type_string("The title of the talk"),
          abstract = type_string("The abstract of the talk"),
          speaker = type_string("The main speaker of the talk")
        )
      )
    )
  } else {
    tibble(
      title = talk_titles %0% "",
      abstract = talk_abstracts %0% "",
      speaker = talk_speakers %0% ""
    )
  }

  x <- tibble(
    time = paste0(event_time, collapse = " - "),
    location = event_location,
    room = event_room %0% "No room",
    talks = list(talks)
  )
  saveRDS(x, path)
  x
}

jsm_sessions |> 
  rowwise() |>
  mutate(title = sub("^View\\s", "", title), get_event_talks(id)) |> 
  ungroup() |> 
  readr::write_rds("data/jsm-conf-sessions.rds")
