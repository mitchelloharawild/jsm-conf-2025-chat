# JSM 2025 chat app

This repository contains a chat application built for [JSM 2025](https://ww2.amstat.org/meetings/jsm/2025/). The project is implemented in R and consists of several scripts and an interactive app. This app is **NOT** officially affiliated with JSM. It's just something I made to make the massive program easier to interact with. It uses agenda data scraped from the conference website.

## General Implementation

- **Data Collection:** The `00-scrape-webpages.R` script scrapes and collects data from specified web sources.
- **Data Processing:** The `01-ragnar-store.R` script processes the scraped data and stores it in a structured format for efficient access by the app.
- **App Launch:** The `app.R` script launches the interactive chat application, using the processed data.

For questions or contributions, please open an issue or submit a pull request.

## Acknowledgments

Thanks for [@parmsam](https://github.com/parmsam/) for creating the original posit::conf(2025) chat app, of which this app simply replaces the underlying RAG data to be suitable for JSM 2025.
