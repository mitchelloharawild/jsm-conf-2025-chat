# posit::conf(2025) chat app

This repository contains a chat application built for [posit::conf(2025)](https://posit.co/conference/). The project is implemented in R and consists of several scripts and an interactive app.

## Getting Started

To get started, clone this repository and run the scripts in order before launching the app:

1. **Clone the repository:**
   ```sh
   git clone https://github.com/parmsam/posit-conf-2025-chat
   cd posit-conf-2025-chat
   ```

2. **Run the ragnar store setup script:**
   - `01-ragnar-store.R`: Processes and stores the scraped data in a format suitable for the app.

   You can run these scripts in your R environment:
   ```r
   source('01-ragnar-store.R')
   ```

3. **(Optional) Run additional scripts:**
   - `02-ellmer-chat.R`: Additional processing or features for the chat app (see script for details).

4. **Run the app:**
   - Launch the chat application with:
   ```r
   source('app.R')
   ```

## General Implementation

- **Data Collection:** The `00-scrape-webpages.R` script scrapes and collects data from specified web sources.
- **Data Processing:** The `01-ragnar-store.R` script processes the scraped data and stores it in a structured format for efficient access by the app.
- **App Launch:** The `app.R` script launches the interactive chat application, using the processed data.

## Requirements
- R (latest version recommended)
- Required R packages (see script headers for package requirements)

## Notes
- Make sure to run the scripts in order for the app to function correctly.
- For more details, see comments within each script.

---

For questions or contributions, please open an issue or submit a pull request.
