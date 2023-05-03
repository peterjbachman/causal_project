library(dplyr)
library(stringr)
library(stringdist)
library(lubridate)

df <- read.csv("data/uncleaned/cases_plain.csv") %>%
  group_by(casename) %>%
  # Fuzzy match since names from the Sen and Glynn Data varies slightly from
  # the Caselaw Opinions
  mutate(
    match = stringdist(str_extract(capsnames, "\\w+\\b"), opinion_author),
  ) %>%
  ungroup() %>%
  mutate(
    date = ymd(paste(year, month, day)),
    is_gender_issue = ifelse(
      area %in% c(
        "employment",
        "Title IX",
        "pregnancy",
        "abortion",
        "reproductive rights"
      ),
      1,
      0
    )
  ) %>%
  # Matches in the opinion author is at max one character different.
  filter(match <= 1) %>%
  # Keep important variables
  select(
    c(
      "casename",
      "circuit",
      "date",
      "is_gender_issue",
      "area",
      "enbanc",
      "femplaintiff",
      "capsnames",
      "vote",
      "republican",
      "birth",
      "child",
      "girls",
      "sons",
      "songerID",
      "race",
      "religion",
      "progressive.vote",
      "opinion"
    )
  )

# Impute the one case where the error failed
df$date[df$casename == "Walden v. Georgia-Pacific Corp."] <- ymd("1997-09-26")

write.csv(df, file = "data/cleaned/cleaned_cases.csv", row.names = FALSE)
