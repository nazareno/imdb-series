get_episode_ratings = function(url){
    require("dplyr")
    require("tidyr")
    require("rvest")
    #print(url)
    # message(paste("Getting", url))
    ratings = read_html(url) %>% 
        html_node("table") %>% 
        html_table(fill=TRUE)
    names(ratings) = c("Rating", "Percentage", "Votes")
    ratings %>% 
        mutate(Votes = as.numeric(gsub(",", "", Votes)), 
               Rating = paste0("r", Rating), 
               Percentage = Votes / sum(Votes)) %>% 
        select(-Votes) %>%
        spread(key = Rating, value = Percentage) %>% 
        return()
}

get_all_episodes = function(series_imdb_id) {
  require("dplyr")
  require("tidyr")
  require("rvest")
  require("purrr")
  
  # Get existing seasons
  title_url = paste0("http://www.imdb.com/title/", series_imdb_id, "/?ref_=ttep_ql_4")
  base_page = read_html(title_url) 
  
  seasons = base_page %>% 
    html_node("#title-episode-widget") %>% 
    html_node(".seasons-and-year-nav") %>% 
    html_nodes("div:nth-child(4)") %>% 
    html_nodes("a") %>% 
    html_attr("href")
  
  # Get episodes for each season
  episodes = tibble()
  for (season in seasons) {
    season_base_page = paste0("http://www.imdb.com", season) %>% 
      read_html()
    
    season_number = season_base_page %>% 
      html_node("#episodes_content > .seasonAndYearNav") %>%
      html_node("#bySeason") %>% 
      html_node(xpath="//option[@selected]") %>% 
      html_attr("value")
    
    episode_number = season_base_page %>% 
      html_node("#episodes_content > .clear > .eplist") %>% 
      html_nodes(".list_item") %>% 
      html_nodes(".info") %>% 
      html_nodes("meta") %>% 
      html_attr("content")
    
    episode_name = season_base_page %>% 
      html_node("#episodes_content > .clear > .eplist") %>% 
      html_nodes("div.list_item") %>% 
      html_nodes("div > strong") %>% 
      html_node("a") %>% 
      html_attr("title")
    
    episode_rating = season_base_page %>% 
      html_node("#episodes_content > .clear > .eplist") %>% 
      html_nodes("div") %>% 
      html_nodes("div.info") %>% 
      html_nodes("div.ipl-rating-widget") %>% 
      html_nodes("div.ipl-rating-star.small") %>% 
      html_nodes("span.ipl-rating-star__rating") %>% 
      html_text()
    if (length(episode_rating) == 0) {
      episode_rating = NA
    }
    
    episode_votes = season_base_page %>% 
      html_node("#episodes_content > .clear > .eplist") %>% 
      html_nodes("div") %>% 
      html_nodes("div.info") %>% 
      html_nodes("div.ipl-rating-widget") %>% 
      html_nodes("div.ipl-rating-star.small") %>% 
      html_nodes("span.ipl-rating-star__total-votes") %>% 
      html_text()
    if (length(episode_votes) == 0) {
      episode_votes = NA
    } else {
      episode_votes = gsub("\\(|\\)|,", "", episode_votes)
    }
    
    series_name = season_base_page %>% 
      html_node("#main") %>% 
      html_node(".subpage_title_block") %>% 
      html_node(".parent") %>% 
      html_node("h3") %>% 
      html_node("a") %>% 
      html_text()
    
    season_episodes = season_base_page %>% 
      html_node("#episodes_content > .clear > .eplist") %>% 
      html_nodes("div") %>% 
      html_nodes("div > strong") %>% 
      html_node("a") %>% 
      html_attr("href") %>% 
      as_tibble()
    
    # Filter only episodes that were displayed on TV
    if (count(season_episodes) > length(episode_rating)) {
      season_episodes = season_episodes %>% 
        filter(row_number() <= length(episode_rating))
      episode_name = episode_name[1:length(episode_rating)]
      episode_number = episode_number[1:length(episode_rating)]
    }
    
    season_episodes = season_episodes %>% 
      mutate(
        series_name = series_name,
        Episode = episode_name,
        url = paste0("http://www.imdb.com", value),
        season = as.numeric(season_number),
        season_ep = as.numeric(episode_number),
        UserRating = episode_rating,
        UserVotes = episode_votes
      ) %>% 
      select(-value)
    
    episodes = rbind(episodes, season_episodes)
  }

  episodes = episodes %>% 
    arrange(season, season_ep) %>% 
    mutate(series_ep = row_number()) %>% 
    filter(UserVotes > 0)
  
  episode_ratings = episodes %>% 
    mutate(rating_link = paste0(gsub("\\?(.*)", "", url), "ratings")) %>% 
    pull(rating_link) %>%
    map(get_episode_ratings)
  episode_ratings = do.call(rbind, episode_ratings)
  
  episodes = episodes %>% 
    cbind(episode_ratings) %>% 
    select(series_name, Episode, series_ep, season, season_ep, url, UserRating, UserVotes, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10)
  
  return(episodes)
}