# Replace every instance of power with horsepower
# using previous search
# Move cursor over word to replace
# Hit * to search
# :%s//horsepower
data <- mtcars |>
  mutate(eng_pwr = case_when(
    hp >= 180 ~ "Lots of power",
    hp < 180 & hp > 96.5 ~ "Moderate power",
    hp < 96.5 ~ "Low power",
  ))

ggplot(data, aes(x = hp, y = mpg, color = eng_pwr)) +
  geom_point()
