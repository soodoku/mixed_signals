## Mixed Signals: Quality Assessments Across Platforms

setwd(githubdir)
setwd("mixed_signals/")

library(tidyverse)
library(rvest)
library(stringr)
library(ggplot2)
library(ggcorplot)

# Load manually collected data
movies <- read_csv("data/movies.csv")

## Get it from Harvard Dataverse
##  
movie_all <- read_csv("data/movie_data_1950_2020.csv")

# Extract Ratings
# read_html(movie_all$kp_whole_page_html[[1]]) %>% html_nodes(".NY3LVe") %>% html_text()

movie_all$ratings_list <- NA

for(i in 1:nrow(movie_all)){
	if (movie_all$kp_whole_page_html[i] != "[]") {
		dat <- read_html(movie_all$kp_whole_page_html[i])
		dat2 <- dat %>% html_nodes(".NY3LVe") %>% html_text()
		movie_all$ratings_list[i] <- list(dat2)
	}

	else {
		movie_all$ratings_list[i] <- NA
	}
}

matcher <- function(x, strmatch) {
	res <- NA
	res_match <- grep(strmatch, x, value = T)
	if (!is_empty(res_match)) {
		res <- gsub(strmatch, "", res_match)
	}
	res
}

movie_all$vudu_rating            <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/5Vudu"))))
movie_all$letterboxd_rating      <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/5Letterboxd"))))
movie_all$fandor_rating          <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/5Fandor"))))
movie_all$film_affinity_rating   <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/10FilmAffinity"))))
movie_all$trakt_rating           <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "[[:punct:]]Trakt|[[:punct:]]Trakt.tv"))))
movie_all$apple_rating           <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/5Download iTunes from Apple"))))
movie_all$class_movie_rating     <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/10Classic Movie Hub"))))
movie_all$ringos_rating          <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/10RingosTrack"))))
movie_all$french_films_rating    <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/5French Films"))))
movie_all$original_film_rating   <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/5Original Film Art"))))
movie_all$allmovie_rating        <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/10AllMovie"))))
movie_all$bluray_rating          <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/10Blu-ray.com"))))
movie_all$movie_insider_rating   <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/5Movie Insider"))))
movie_all$reelviews_rating       <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/5Reelviews"))))
movie_all$indie_wire_rating      <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/5IndieWire"))))
movie_all$IMDb_rating            <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "/10IMDb"))))
movie_all$rotten_tomatoes_rating <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "%Rotten Tomatoes"))))
movie_all$meta_critic_rating     <- as.numeric(unlist(sapply(movie_all$ratings_list, function(x) matcher(x, "%Metacritic"))))

movie_all$p_google_likes <- as.numeric(gsub("%", "", movie_all$p_google_likes))

ratings <- names(movie_all)[grep("_rating", names(movie_all))]
movie_subs <- movie_all %>%
	select("title", "subtitle", "release_year",
		   "genre", "duration", 
		   ratings, "p_google_likes", 
		   "box_office", "release_date", "directors", "awards", "film_series", "producers", "budget")

write_csv(movie_subs, file = "data/movie_all_subset.csv")

# Analyses
ratings <- ratings[!grepl(paste0("maturity_rating", collapse = "|"), ratings)]

# Total n 
nrow(movie_subs) -colSums(is.na(cbind(movie_subs[, ratings], movie_subs$p_google_likes)))

# Platforms with 100 or more ratings
ratings_100 <- c(ratings, "p_google_likes")[nrow(movie_subs) - colSums(is.na(cbind(movie_subs[, ratings], movie_subs$p_google_likes))) >= 100]
length(ratings_100)

# Correlation Table
pearson_cormat_100 <- cor(cbind(movie_subs[, ratings_100]), use = "pairwise.complete.obs")
median(pearson_cormat_100[upper.tri(pearson_cormat_100, diag = F)], na.rm = T)

spearman_cormat_100 <- cor(cbind(movie_subs[, ratings_100]), use = "pairwise.complete.obs", method ="spearman")
median(spearman_cormat_100[upper.tri(spearman_cormat_100, diag = F)], na.rm = T)

# Platforms with 50 or more ratings
ratings_50 <- c(ratings, "p_google_likes")[nrow(movie_subs) - colSums(is.na(cbind(movie_subs[, ratings], movie_subs$p_google_likes))) >= 50]

# Correlation Table
pearson_cormat_50 <- cor(cbind(movie_subs[, ratings_50]), use = "pairwise.complete.obs")
median(pearson_cormat_50[upper.tri(pearson_cormat_50, diag = F)], na.rm = T)

spearman_cormat_50 <- cor(cbind(movie_subs[, ratings_50]), use = "pairwise.complete.obs", method ="spearman")
median(spearman_cormat_50[upper.tri(spearman_cormat_50, diag = F)], na.rm = T)

# Pearson's Correlation Plot
ggcorrplot(pearson_cormat_100, type = "lower",
   outline.col = "white",
   lab = T,
   ggtheme = ggplot2::theme_void,
   colors = c("#6D9EC1", "white", "#E46726"))
ggsave(file = "figs/pearson-corplot.png")

# Spearman's Correlation Plot
ggcorrplot(spearman_cormat_100, type = "lower",
   outline.col = "white",
   lab = T,
   ggtheme = ggplot2::theme_void,
   colors = c("#6D9EC1", "white", "#E46726"))
ggsave(file = "figs/spearman-corplot.png")

# Loess
ggplot(movie_subs, aes(release_year, rotten_tomatoes_rating)) +
  geom_point(alpha = .05) +
  geom_smooth(method = "loess") + 
  theme_minimal() +
  theme(panel.grid.major = element_line(color="#e1e1e1",  linetype = "dotted"),
	  panel.grid.minor = element_blank(),
	  legend.position  ="bottom",
	  legend.key      = element_blank(),
	  legend.key.width = unit(1, "cm"),
	  axis.title   = element_text(size = 10, color = "#555555"),
	  axis.text    = element_text(size = 10, color = "#555555"),
	  axis.ticks.y = element_blank(),
	  axis.title.x = element_text(vjust = -1, margin = margin(10, 0, 0, 0)),
	  axis.title.y = element_text(vjust = 1),
	  axis.ticks   = element_line(color = "#e3e3e3", size = .2),
	  plot.margin = unit(c(0, 1, 0, 0), "cm"))

