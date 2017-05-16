# imdb-series

A dataset to analyse user ratings given in IMDB to episodes of some popular series. Code is in R. And the code to generate your version of it.

## Analysing series

Go for `data/series_from_imdb.csv` and decide which series/episode is better. 

## Fetching the data / more data yourself

### Dependencies 

You'll need `tidyverse` and `rvest`.

### Runnnig

Run `get_series_data.R`. It will fetch ratings for every episode of the series in `series_urls.csv` and save the result in `data/series_from_imdb.csv`. 