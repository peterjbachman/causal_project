df <- read.csv("data/uncleaned/cases_plain.csv")

# Remove cases without a female plaintiff similar to Glynn and Sen 2014\
# Remove cases without a specific author as well.
df <- subset(df, femplaintiff == 1 & per_curiam == "False")
df$is_gender_issue <- ifelse(
  df$area %in% c("employment", "Title IX", "pregnancy", "abortion", "reproductive rights"),
  1,
  0
)

# Set up training and test dataset
# Evenly split data by gender and non-gender issues
set.seed(12345)
df$training[df$is_gender_issue == 1] <- sample(c(0, 1), replace = TRUE)
df$training[df$is_gender_issue == 0] <- sample(c(0, 1), replace = TRUE)

test <- df[df$training == 0, ]
train <- df[df$training == 1, ]

# Write the training and test data
write.csv(test, "data/cleaned/test_case.csv")
write.csv(train, "data/cleaned/train_case.csv")
