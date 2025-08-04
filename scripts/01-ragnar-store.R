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
  select(-title) |> 
  tidyr::unnest(talks) |> 
  rowwise() |> 
  transmute(
    title,
    text = glue::glue(
"
<title>{title}</title>
<session internal=true>{id}</session>
<date>{date}</date>
<time>{time}</time>
<speaker>{speaker}</speaker>
<abstract>
{abstract}
</abstract>
"
  ),
  ) |> 
  ungroup() |> 
  filter(nchar(text) < 30000)

store_location <- file.path("data", "jsm-talks-2025.ragnar.duckdb")

store <- ragnar::ragnar_store_create(
  location = store_location,
  embed = \(x) ragnar::embed_openai(x, model = "text-embedding-3-small"),
  overwrite = TRUE,
  version = 1
)


ragnar::ragnar_store_insert(store, chunks_df)

# Example retrieval
store <- ragnar_store_connect(store_location, read_only = TRUE)
text <- "Matthew Kay"

embedding_near_chunks <- ragnar_retrieve_vss(store, text, top_k = 10)
embedding_near_chunks$text[1] |> cat(sep = "\n~~~~~~~~\n")

xml_extract <- function(x, dom) {
  xpath <- paste0("descendant-or-self::", dom)
  vapply(x, function(content) {
    xml2::read_html(content) |> 
      xml2::xml_find_all(xpath) |> 
      xml2::xml_text()
  }, character(1L)) |> 
    unname()
}

session_id <- xml_extract(embedding_near_chunks$text, "session")
talk_date <- xml_extract(embedding_near_chunks$text, "date")

selectr::css_to_xpath()

# embedding_near_chunks <- ragnar_retrieve(store, text)
# embedding_near_chunks$text[1] |> cat(sep = "\n~~~~~~~~\n")


# write last modified date based on CSV as text file

info <- fs::file_info(file.path("data", "jsm-conf-2025.ragnar.duckdb"))

last_modified_date <- as.Date(info$modification_time)

writeLines(
  as.character(last_modified_date),
  file.path("data", "retrieval-date.txt")
)
