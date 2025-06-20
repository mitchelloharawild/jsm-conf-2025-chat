library(httr2)
library(jsonlite)
library(purrr)
library(dplyr)
library(tidyr)
library(readr)
library(janitor)

payload <- "tab.day=20250918,20250916,20250917&search.day=20250916&search.day=20250918&search.day=20250917&type=session&browserTimezone=America%2FNew_York&catalogDisplay=list"

req <- request("https://events.conf.posit.co/api/search") |>
  req_method("POST") |>
  req_headers(
    `Content-Type` = "application/x-www-form-urlencoded; charset=UTF-8",
    `Accept` = "*/*",
    `Sec-Fetch-Site` = "cross-site",
    `Accept-Language` = "en-US,en;q=0.9",
    `Accept-Encoding` = "gzip, deflate, br",
    `Sec-Fetch-Mode` = "cors",
    `Origin` = "https://reg.rainfocus.com",
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
    `Referer` = "https://reg.rainfocus.com/",
    `Sec-Fetch-Dest` = "empty",
    `rfApiProfileId` = "oDos2PopAAEllY2HYh6s2xxvRcmcZHGe",
    `Priority` = "u=3, i",
    `rfWidgetId` = "GSqhY5UEq3FaXEHoQJrUFnDmsz4UGFCh",
    `Cookie` = "JSESSIONID=341780CAE383F8863252C1DE0F1DF48B"
  ) |>
  req_body_raw(charToRaw(payload))

resp <- tryCatch(
  req |> req_perform(),
  error = function(e) {
    message("Request failed: ", e$message)
    return(NULL)
  }
)

if (!is.null(resp)) {
  json <- resp_body_json(resp)
  
  resp_json <- resp_body_json(resp)
  
  resp_json |> 
    jsonlite::write_json(file.path("data", "api_response.json"))
}

## Process saved JSON file
resp_json <- jsonlite::read_json(file.path("data", "api_response.json"))

process_json <- function(json_input) {
  # Load JSON if input is file path
  out <- if (is.character(json_input)) fromJSON(json_input, simplifyVector = FALSE) else json_input
  
  items <- out$sectionList[[1]]$items
  
  # Split child vs. non-child sessions
  child_sessions_raw <- map(items, "childSessions")
  is_child <- !sapply(child_sessions_raw, is.null)
  child_sessions <- flatten(child_sessions_raw[is_child])
  non_child_sessions <- items[!is_child]
  
  # Helper to extract safely
  safe_extract <- function(x, keys) {
    setNames(map(keys, ~ x[[.x]] %||% NA), keys)
  }
  
  # Extract speakers from a session
  extract_speakers <- function(session) {
    if (is.null(session$participants)) return(NULL)
    talk_info <- safe_extract(session, c("code", "abstract", "title"))
    
    map(session$participants, function(speaker) {
      speaker_info <- safe_extract(speaker, c("globalBio", "globalJobtitle", "globalFullName"))
      as_tibble(c(speaker_info, talk_info))
    })
  }
  
  # Combine speaker entries from child and non-child sessions
  speakers <- c(
    flatten(map(child_sessions, extract_speakers)),
    flatten(map(non_child_sessions, extract_speakers))
  )
  
  bind_rows(speakers)
}

result <- process_json(resp_json) |>
  unnest(cols = everything()) |>
  rename_with(~ gsub("^global", "", .), starts_with("global")) |>
  janitor::clean_names() |>
  rename(job_title = jobtitle)

# Reformat result to comply with required chunks df format for ragnar
result <- result |>
 mutate( 
   text = glue::glue( 
"## Talk title: {title}
** Talk code: {code}

** Talk abstract:
{abstract}

** Speaker name: {full_name}
** Job title: {job_title}
** Bio: 
{bio}")
) |> 
  select(title, text)

result |>
  write_csv(file.path("data", "posit-conf-2025-abstracts.csv"))
