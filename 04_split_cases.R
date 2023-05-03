df <- read.csv("data/cleaned/cleaned_cases.csv")

# Set up training and test dataset
# Evenly split data by gender and non-gender issues
set.seed(12345)
df$training[df$is_gender_issue == 1] <- sample(c(0, 1), nrow(df[df$is_gender_issue == 1, ]), replace = TRUE)
df$training[df$is_gender_issue == 0] <- sample(c(0, 1), nrow(df[df$is_gender_issue == 0, ]), replace = TRUE)

test <- df[df$training == 0, ]
train <- df[df$training == 1, ]

# Write the training and test data
write.csv(test, "data/cleaned/test_case.csv", row.names = FALSE)
write.csv(train, "data/cleaned/train_case.csv", row.names = FALSE)
