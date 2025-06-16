library(ragnar)
library(ellmer)
library(tibble)
library(duckdb)

store_location <- "posit-conf-2025.ragnar.duckdb"

store <- ragnar::ragnar_store_create(
  store_location,
  embed = \(x) ragnar::embed_openai(x, model = "text-embedding-3-small"),
  overwrite = TRUE
)

chunks_df <- data.frame(
  title = names(sessions_md),
  text = sessions_md,
  stringsAsFactors = FALSE
)

ragnar::ragnar_store_insert(store, chunks_df)

# Example retrieval
store <- ragnar_store_connect(store_location, read_only = TRUE)
text <- "Sessions on causal inference"

embedding_near_chunks <- ragnar_retrieve_vss(store, text, top_k = 3)
embedding_near_chunks$text[1] |> cat(sep = "\n~~~~~~~~\n")

# embedding_near_chunks <- ragnar_retrieve(store, text)
# embedding_near_chunks$text[1] |> cat(sep = "\n~~~~~~~~\n")
