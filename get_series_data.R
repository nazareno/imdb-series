library(tidyverse)

source("R/imdb_series.R")

series_to_fetch = read_csv("series_urls.csv")

for(i in seq(1, NROW(series_to_fetch), by = 4)){
    series_data = series_to_fetch %>% 
        slice(i:min(i + 4, NROW(series_to_fetch))) %>% 
        group_by(series_name) %>% 
        do(tryCatch(get_all_episodes(.$imdb_id), 
                    error = function(e) data.frame(NA)))
    series_data %>% 
        select(-2) %>% 
        write_csv(paste0("data/series_from_imdb-", i, ".csv"))
}

files = list.files("./data/", "^series_from_imdb-", full.names = TRUE)
there_should_be = floor(NROW(series_to_fetch) / 4)
if(length(files) != there_should_be){
    message("Not all series were fetch. There should be ", there_should_be, " files, but there are ", length(files))
} else {
    all_data = tibble(file = files) %>% 
        group_by(file) %>% 
        do(read_csv(.$file)) %>% 
        ungroup()
    all_data %>% 
        select(-1, -20) %>%
        filter(complete.cases(.)) %>% 
        mutate(link = paste0("http://www.imdb.com", link)) %>% 
        select(series_name, series_ep, season, season_ep, url = link, everything()) %>% 
        unique() %>% 
        write_csv("data/series_from_imdb.csv")
}
    
