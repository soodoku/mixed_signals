## Mixed Signals: Quality Assessments Across Platforms

setwd(githubdir)
setwd("mixed_signals/")

library(tidyverse)
library(rvest)
library(stringr)
library(ggplot2)
library(ggcorplot)
library(goji)
library(tidyr)
library(gridExtra)

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

df = data.frame(n_movies = nrow(movie_subs) -colSums(is.na(cbind(movie_subs[, ratings], movie_subs$p_google_likes))))
df$platform <- rownames(df)

ggplot(df, aes(x = reorder(platform, n_movies), y = n_movies)) + 
    geom_bar(stat="identity") +
    coord_flip() +
    theme_minimal() + 
    xlab("") + 
    scale_y_continuous(breaks = round(seq(0, max(df$n_movies), by = 1000), 1))
ggsave(file = "figs/n_movies.png")

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

## Other Insights

# Reviews over time
# Let's create an average score per movie using the 3 common
movie_subs$rotten_tomatoes_rating01 <- zero1(movie_subs$rotten_tomatoes_rating)
movie_subs$IMDb_rating01            <- zero1(movie_subs$IMDb_rating)
movie_subs$p_google_likes01         <- zero1(movie_subs$p_google_likes)

movie_subs$avg_rating <- with(movie_subs, rowMeans(cbind(rotten_tomatoes_rating01, IMDb_rating01, p_google_likes01)))

ggplot(movie_subs, aes(release_year, avg_rating)) +
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
	  plot.margin = unit(c(0, 1, 0, 0), "cm")) + 
      scale_x_continuous(breaks = round(seq(min(movie_subs$release_year, na.rm = T), max(movie_subs$release_year, na.rm = T), by = 10), 1)) + 
      scale_y_continuous(breaks = round(seq(min(movie_subs$avg_rating, na.rm = T), max(movie_subs$avg_rating, na.rm = T), by = .1), 1))

ggsave(file = "figs/rating_over_time.png")

# Over time ratings by platform
movie_subs$id <- 1:nrow(movie_subs)
rating_long <- gather(movie_subs[, c("id", "maturity_rating", "genre", "release_year", "IMDb_rating01", "rotten_tomatoes_rating01", "p_google_likes01")], platform, rating, IMDb_rating01:p_google_likes01, factor_key=TRUE)

ggplot(rating_long, aes(release_year, rating, colour = platform)) +
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
	  plot.margin = unit(c(0, 1, 0, 0), "cm")) + 
      scale_x_continuous(breaks = round(seq(min(movie_subs$release_year, na.rm = T), max(movie_subs$release_year, na.rm = T), by = 10), 1)) + 
      scale_y_continuous(breaks = round(seq(min(movie_subs$avg_rating, na.rm = T), max(movie_subs$avg_rating, na.rm = T), by = .1), 1))

ggsave(file = "figs/rating_over_time_by_platform.png")

## Correlation over time

# Round to nearest decade
movie_subs$decade <- round(movie_subs$release_year/10)*10

time_corr <- movie_subs %>%
     select("decade", "IMDb_rating", "rotten_tomatoes_rating", "p_google_likes") %>%
     group_by(decade) %>%
     filter(!is.na(decade)) %>%
     summarise(rotten_imdb   = round(cor(IMDb_rating, rotten_tomatoes_rating, use = "pairwise.complete.obs"), 2), 
               rotten_google = round(cor(rotten_tomatoes_rating, p_google_likes, use = "pairwise.complete.obs"), 2), 
               imdb_google   = round(cor(IMDb_rating, p_google_likes, use = "pairwise.complete.obs"), 2),
               n = n(),
               n_rotten_imdb = sum(!is.na(rotten_tomatoes_rating) & !is.na(IMDb_rating)),
               n_rotten_goog = sum(!is.na(rotten_tomatoes_rating) & !is.na(p_google_likes)),
               n_imdb_goog   = sum(!is.na(IMDb_rating) & !is.na(p_google_likes)))

png("figs/time_corr.png", height = 35*nrow(maturity_corr), width = 90*ncol(maturity_corr))
grid.table(time_corr)
dev.off()

# Ratings by maturity ratings
# Let's just do the diff.
movie_subs$rotten_imdb_diff   <- movie_subs$rotten_tomatoes_rating01 - movie_subs$IMDb_rating01
movie_subs$rotten_google_diff <- movie_subs$rotten_tomatoes_rating01 - movie_subs$p_google_likes01
movie_subs$imdb_google_diff   <- movie_subs$IMDb_rating01 - movie_subs$p_google_likes01

movie_subs %>%
     select(maturity_rating, rotten_imdb_diff, rotten_google_diff, imdb_google_diff) %>%
     group_by(maturity_rating) %>%
     filter(maturity_rating %in% c("G", "PG", "PG-13", "R")) %>%
     summarise(rotten_imdb   = mean(rotten_imdb_diff, na.rm = T), 
               rotten_google = mean(rotten_google_diff, na.rm = T),
               imdb_google   = mean(imdb_google_diff, na.rm = T))

maturity_corr <- movie_subs %>%
     select("maturity_rating", "IMDb_rating", "rotten_tomatoes_rating", "p_google_likes") %>%
     group_by(maturity_rating) %>%
     filter(maturity_rating %in% c("G", "PG", "PG-13", "R")) %>%
     summarise(rotten_imdb   = round(cor(IMDb_rating, rotten_tomatoes_rating, use = "pairwise.complete.obs"), 2), 
               rotten_google = round(cor(rotten_tomatoes_rating, p_google_likes, use = "pairwise.complete.obs"), 2), 
               imdb_google   = round(cor(IMDb_rating, p_google_likes, use = "pairwise.complete.obs"), 2),
               n = n(),
               n_rotten_imdb = sum(!is.na(rotten_tomatoes_rating) & !is.na(IMDb_rating)),
               n_rotten_goog = sum(!is.na(rotten_tomatoes_rating) & !is.na(p_google_likes)),
               n_imdb_goog   = sum(!is.na(IMDb_rating) & !is.na(p_google_likes))) %>%
       arrange(-n)

png("figs/maturity_corr.png", height = 35*nrow(maturity_corr), width = 90*ncol(maturity_corr))
grid.table(maturity_corr)
dev.off()

# Ratings by genre
table(movie_subs$genre)[order(table(movie_subs$genre))]

movie_subs %>%
     select(genre, rotten_imdb_diff, rotten_google_diff, imdb_google_diff) %>%
     group_by(genre) %>%
     filter(genre %in% c("Romance/Rom-com", "Romance/Drama", "Action/Thriller", "Drama", "PG-13", "Horror/Thriller", "Comedy/Romance", "Drama/Romance", "Family/Comedy", "Comedy", "Thriller/Drama")) %>%
     summarise(rotten_imdb   = mean(rotten_imdb_diff, na.rm = T), 
               rotten_google = mean(rotten_google_diff, na.rm = T),
               imdb_google   = mean(imdb_google_diff, na.rm = T))

genre_corr <- movie_subs %>%
     select(genre, "IMDb_rating", "rotten_tomatoes_rating", "p_google_likes") %>%
     group_by(genre) %>%
     filter(genre %in% c("Romance/Rom-com", "Romance/Drama", "Action/Thriller", "Drama", "PG-13", "Horror/Thriller", "Comedy/Romance", "Drama/Romance", "Family/Comedy", "Comedy", "Thriller/Drama")) %>%
     summarise(rotten_imdb   = round(cor(IMDb_rating, rotten_tomatoes_rating, use = "pairwise.complete.obs"), 2), 
               rotten_google = round(cor(rotten_tomatoes_rating, p_google_likes, use = "pairwise.complete.obs"), 2), 
               imdb_google   = round(cor(IMDb_rating, p_google_likes, use = "pairwise.complete.obs"), 2),
               n = n(),
               n_rotten_imdb = sum(!is.na(rotten_tomatoes_rating) & !is.na(IMDb_rating)),
               n_rotten_goog = sum(!is.na(rotten_tomatoes_rating) & !is.na(p_google_likes)),
               n_imdb_goog   = sum(!is.na(IMDb_rating) & !is.na(p_google_likes))) %>%
       arrange(-n)

png("figs/genre_corr.png", height = 35*nrow(genre_corr), width = 90*ncol(genre_corr))
grid.table(genre_corr)
dev.off()
