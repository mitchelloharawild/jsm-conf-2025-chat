library(ragnar)
library(ellmer)
library(tibble)
library(duckdb)
library(readr)
library(dplyr)

jsm_df <- readr::read_rds(
  file.path("data", "jsm-conf-sessions.rds")
)

chunks_df <- jsm_df |>
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
      "</session>\n",
      "---"
    )
  ) |> 
  ungroup() |> 
  filter(nchar(text) < 30000)

store_location <- file.path("data", "jsm-conf-2025.ragnar.duckdb")

store <- ragnar::ragnar_store_create(
  location = store_location,
  embed = \(x) ragnar::embed_openai(x, model = "text-embedding-3-small"),
  overwrite = TRUE,
  version = 1
)


ragnar::ragnar_store_insert(store, chunks_df)

# Example retrieval
store <- ragnar_store_connect(store_location, read_only = TRUE)
text <- "ggplot extenders"

embedding_near_chunks <- ragnar_retrieve_vss(store, text, top_k = 3)
embedding_near_chunks$text[1] |> cat(sep = "\n~~~~~~~~\n")

# embedding_near_chunks <- ragnar_retrieve(store, text)
# embedding_near_chunks$text[1] |> cat(sep = "\n~~~~~~~~\n")


# write last modified date based on CSV as text file

info <- fs::file_info(file.path("data", "jsm-conf-2025.ragnar.duckdb"))

last_modified_date <- as.Date(info$modification_time)

writeLines(
  as.character(last_modified_date),
  file.path("data", "retrieval-date.txt")
)
