df <- read.csv("data/uncleaned/cases_plain.csv")
df_filtered <- subset(df, !is.na(df$opinion_author))
nrow(df_filtered)
df$opinion_author

df$is_gender_issue <- ifelse(
  df$area %in% c("employment", "Title IX", "pregnancy", "abortion", "reproductive rights"),
  1,
  0
)
sum(df$is_gender_issue == 0)
