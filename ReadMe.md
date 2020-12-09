## Mixed Signals: Quality Assessments Across Platforms

![Guardians](goog.png)

Is the difference between ratings for Guardians of Galaxy the norm? To check that, I estimated the correlation between ratings for [movies that earned the most (unadjusted for inflation) on the domestic box office](https://www.filmsite.org/boxoffice.html). (Presumably variation in ratings for top 100 is smaller than if we had the entire sample. And that means the correlation is estimated over a small range. It is also likely that lots of people rated these movies so the measures are likely precise.)

The correlation between metacritic and rotten tomatoes is just .48. The correlation between imdb and google ratings is just .33. The highest correlation is surprisingly between rotten tomatoes and imdb ratings. 

|             | imdb | rotten | metacritic | google |
|-------------|------|--------|------------|--------|
| imdb        | 1.00 | 0.74   | 0.36       | 0.33   |
| rotten      | 0.74 | 1.00   | 0.48       | 0.23   |
| metacritic  | 0.36 | 0.48   | 1.00       | 0.18   |
| google      | 0.33 | 0.23   | 0.18       | 1.00   |


### License
Released under [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/).
