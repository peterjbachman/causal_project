library(dplyr)

test <- read.csv("data/cleaned/test_case.csv") %>%
  mutate(
    treatment = ifelse(girls > 0, 1, 0)
  )

df <- test %>%
  separate_longer_delim(opinion, delim = "\n") %>%
  mutate(
    word_count = str_count(opinion, pattern = "\\w+\\s+")
  ) %>%
  filter(word_count > 20) %>%
  group_by(casename) %>%
  mutate(
    id = row_number(casename)
  )

set.seed(12345)
to_label <- df[sample(1:nrow(df), size = 50, replace = FALSE), ]
to_label$topic_validate <- NA

write.csv(to_label, "data/cleaned/hand_validate.csv", row.names = FALSE)
