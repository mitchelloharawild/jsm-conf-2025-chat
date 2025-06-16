# Posit Conf 2025 Chat App

This repository contains a chat application built for Posit Conf 2025. The project is implemented in R and consists of several scripts and an interactive app.

## Getting Started

To get started, clone this repository and run the scripts in order before launching the app:

1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd posit-conf-2025-chat
   ```

2. **Run the data preparation scripts:**
   - `01-scrape-webpages.R`: Scrapes relevant webpages and collects data needed for the chat application.
   - `02-ragnar-store.R`: Processes and stores the scraped data in a format suitable for the app.

   You can run these scripts in your R environment:
   ```r
   source('01-scrape-webpages.R')
   source('02-ragnar-store.R')
   ```

3. **(Optional) Run additional scripts:**
   - `03-ellmer-chat.R`: Additional processing or features for the chat app (see script for details).

4. **Run the app:**
   - Launch the chat application with:
   ```r
   source('app.R')
   ```

## General Implementation

- **Data Collection:** The `01-scrape-webpages.R` script scrapes and collects data from specified web sources.
- **Data Processing:** The `02-ragnar-store.R` script processes the scraped data and stores it in a structured format for efficient access by the app.
- **App Launch:** The `app.R` script launches the interactive chat application, using the processed data.

## Requirements
- R (latest version recommended)
- Required R packages (see script headers for package requirements)

## Notes
- Make sure to run the scripts in order for the app to function correctly.
- For more details, see comments within each script.

---

For questions or contributions, please open an issue or submit a pull request.
