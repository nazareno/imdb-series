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
        do(read_csv(.$file, 
                    col_types = cols(
                        series_name = col_character(),
                        Episode = col_character(),
                        UserRating = col_double(),
                        UserVotes = col_number(),
                        series_ep = col_integer(),
                        link = col_character(),
                        r1 = col_double(),
                        r10 = col_double(),
                        r2 = col_double(),
                        r3 = col_double(),
                        r4 = col_double(),
                        r5 = col_double(),
                        r6 = col_double(),
                        r7 = col_double(),
                        r8 = col_double(),
                        r9 = col_double(),
                        season = col_integer(),
                        season_ep = col_integer()
                    ))) %>% 
        ungroup()
    all_data %>% 
        select(-1, -20) %>%
        filter(complete.cases(.)) %>% 
        mutate(link = paste0("http://www.imdb.com", link)) %>% 
        select(series_name, series_ep, season, url = link, everything()) %>% 
        unique() %>% 
        write_csv("data/series_from_imdb.csv")
}
    
