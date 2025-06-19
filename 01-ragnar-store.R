library(ragnar)
library(ellmer)
library(tibble)
library(duckdb)
library(readr)

chunks_df <- readr::read_csv(
  file.path("data", "posit-conf-2025-sessions.csv")
)

store_location <- file.path("data", "posit-conf-2025.ragnar.duckdb")

store <- ragnar::ragnar_store_create(
  location = store_location,
  embed = \(x) ragnar::embed_openai(x, model = "text-embedding-3-small"),
  overwrite = TRUE
)

ragnar::ragnar_store_insert(store, chunks_df)

# Example retrieval
store <- ragnar_store_connect(store_location, read_only = TRUE)
text <- "Sessions on causal inference"

embedding_near_chunks <- ragnar_retrieve_vss(store, text, top_k = 3)
embedding_near_chunks$text[1] |> cat(sep = "\n~~~~~~~~\n")

# embedding_near_chunks <- ragnar_retrieve(store, text)
# embedding_near_chunks$text[1] |> cat(sep = "\n~~~~~~~~\n")
