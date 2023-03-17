# Use the last searched word to replace
# Place cursor over word, hit `*`
#:%s//horsepower
data <- mtcars |>
  mutate(eng_pwr = case_when(
    hp >= 180 ~ "Lots of power",
    hp < 180 & hp > 96.5 ~ "Moderate power",
    hp <  96.5 ~ "Low power",
  ))

ggplot(data, aes(x = hp, y = mpg, color = eng_pwr)) +
  geom_point()
