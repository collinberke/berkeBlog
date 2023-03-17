library(tidyverse)

# Find each occurance of 'orange', and replace it with 'apple'
# g - replace in the current line only
# % - replace on all lines
# :%s/orange/apple/g
basket1 <- c("orange", "banana", "orange", "strawberry")
basket2 <- c("orange", "banana", "orange", "strawberry")

# Useful to refactor code efficiently
#:%s/power/horsepower
#:%s/data/cars_data
data <- mtcars |>
  mutate(eng_pwr = case_when(
    hp >= 180 ~ "Lots of power",
    hp < 180 & hp > 96.5 ~ "Moderate power",
    hp <  96.5 ~ "Low power",
  ))

ggplot(data, aes(x = hp, y = mpg, color = eng_pwr)) +
  geom_point()
