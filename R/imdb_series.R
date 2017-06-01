get_episode_ratings = function(url){
    require("dplyr")
    require("tidyr")
    require("rvest")
    ratings_url = paste0("http://www.imdb.com/", url, "ratings")
    # message(paste("Getting", ratings_url))
    ratings = read_html(ratings_url) %>% 
        html_node("table") %>% 
        html_table(fill=TRUE)
    names(ratings) = c("Votes", "Percentage", "Rating")
    ratings[-1,] %>% 
        mutate(Votes = as.numeric(Votes), 
               Rating = paste0("r", Rating), 
               Percentage = Votes / sum(Votes)) %>% 
        select(-Votes) %>%
        spread(key = Rating, value = Percentage) %>% 
        return()
}

get_all_episodes = function(series_imdb_id){
    require("dplyr")
    require("tidyr")
    require("rvest")
    
    title_url = paste0("http://www.imdb.com/title/", series_imdb_id, "/epdate?ref_=ttep_ql_4")
    base_page = read_html(title_url) 
    
    episodes = base_page %>% 
        html_node("#tn15content") %>% 
        html_node("table") %>% 
        html_table(fill=TRUE) %>% 
        select(-5) %>% 
        as.tibble() %>% 
        mutate(UserVotes = as.character(UserVotes))
    
    links = base_page %>% 
        html_node("#tn15content") %>% 
        html_node("table") %>% 
        html_nodes("td") %>% 
        html_nodes("a") %>% 
        html_attr("href")
    
    episode_data = tibble(link = links) %>% 
        filter(!grepl("vote", links))
    
    episode_ratings = episode_data %>% 
        group_by(link) %>% 
        do(get_episode_ratings(.$link)) 
    
    episodes_full = left_join(episodes %>% mutate(series_ep = 1:NROW(episodes)), 
                              episode_ratings %>% ungroup() %>% mutate(series_ep = 1:NROW(episode_ratings))) %>% 
        mutate(imdb_id = sprintf("%.2f", `#`)) %>% 
        separate(imdb_id, into = c("season", "imdb_ep")) %>% 
        select(-imdb_ep) %>% 
        group_by(season) %>% 
        mutate(season_ep = 1:n())
    
    return(episodes_full)
}    
