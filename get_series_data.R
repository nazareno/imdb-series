library(tidyverse)
library(rvest)

source("R/imdb_series.R")

series_to_fetch = read_csv("series_urls.csv")

series_data = series_to_fetch %>% 
    group_by(series_name) %>% 
    do(get_all_episodes(.$imdb_id))

series_data %>% 
    select(-2) %>% 
    write_csv("data/series_from_imdb.csv")
