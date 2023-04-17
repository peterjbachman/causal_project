
df <- read.csv("data/uncleaned/glynn_sen_daughters_by_case_1.csv")
df <- subset(df, femplaintiff == 1)

sum(df$girls[!(df$area %in% c("abortion", "employment", "pregnancy", "reproductive rights", "Title IX"))] > 0, na.rm = TRUE)
nrow(test[test$girls > 0,])

test <- df[!(df$area %in% c("abortion", "employment", "pregnancy", "reproductive rights", "Title IX")), ]
sum(test$girls == 0, na.rm = TRUE)
