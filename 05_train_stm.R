library(dplyr)
library(tidyr)
library(stringr)
library(stm)
library(ggplot2)
library(lubridate)
library(MatchIt)
library(quickmatch)

train <- read.csv("data/cleaned/train_case.csv") %>%
  mutate(
    treatment = ifelse(girls > 0, 1, 0)
  )

df <- train %>%
  separate_longer_delim(opinion, delim = "\n") %>%
  mutate(
    word_count = str_count(opinion, pattern = "\\w+\\s+")
  ) %>%
  filter(word_count > 20) %>%
  group_by(casename) %>%
  mutate(
    id = row_number(casename)
  )

# plotRemoved(processed$documents, lower.thresh = seq(0, 100, by = 10))

processed <- textProcessor(documents = df$opinion, metadata = df)
out <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh = 40)

# This took me about 40 min so be warned
# storage <- searchK(
#   out$documents,
#   out$vocab,
#   K = c(30, 40, 50, 60, 65, 70),
#   prevalence = ~as.factor(circuit) + enbanc + as.factor(area) + is_gender_issue,
#   data = meta,
#   init.type = "LDA",
#   cores = 10, # Cores need to be set according to your computer.
#   seed = 12345
# )
#
# save(storage, file = "data/cleaned/topics_diagnose.RData")

# 60 topics seems about right for now?
# plot(storage)

topic_fit <- stm(
  documents = out$documents,
  vocab = out$vocab,
  K = 60,
  prevalence = ~as.factor(circuit) + enbanc + as.factor(area) + is_gender_issue,
  max.em.its = 200,
  data = out$meta,
  init.type = "LDA",
  seed = 12345
)

plot(topic_fit)

# save(topic_fit, file = "data/cleaned/topic_model.RData")
load("data/cleaned/topic_model.RData")

# labelTopics(topic_fit, c(59))
# findThoughts(topic_fit, texts = df$opinion, n = 5, topics = 60)$docs[[1]]
treat_df <- df[complete.cases(df), ]
processed <- textProcessor(documents = treat_df$opinion, metadata = treat_df)
treat <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh = 40)

new <- alignCorpus(new = treat, old.vocab = topic_fit$vocab)
ests <- fitNewDocuments(
  model = topic_fit,
  documents = new$documents,
  newData = new$meta,
  origData = out$meta,
  prevalence = ~as.factor(circuit) + enbanc + as.factor(area) + is_gender_issue,
  prevalencePrior = "Covariate"
)

model <- estimateEffect(
  c(13) ~ treatment,
  stmobj = topic_fit,
  metadata = out$meta,
  uncertainty = "Global"
)

topics <- ests$theta %>%
  as.data.frame() %>%
  mutate(topic = names(.)[max.col(.)]) %>%
  select(topic)

treat_df <- bind_cols(treat_df, topics)

treat_df$topic <- as.numeric(str_extract(treat_df$topic, "[0-9]+"))
treat_df$empathy <- ifelse(treat_df$topic %in% c(13, 47, 48, 50, 51), 1, 0)
sum(treat_df$empathy)

treat_long <- treat_df %>%
  group_by(casename, topic) %>%
  summarise(topic_weight = sum(word_count)) %>%
  ungroup() %>%
  pivot_wider(
    names_from = topic,
    names_prefix = "topic_",
    names_sort = TRUE,
    values_from = topic_weight,
    values_fill = 0
  )

treat_long[, -1] <- treat_long[, -1] / apply(treat_long[,-1], 1, sum)

train <- merge(train, treat_long, by = "casename")

train$empathy_prop <- train$topic_13 + train$topic_47 + train$topic_48 + train$topic_50 + train$topic_51

match_out <- matchit(
  treatment ~ is_gender_issue + republican + sons + race + religion,
  method = "quick",
  distance = "mahalanobis",
  data = train
)

plot(summary(match_out))

matched_train <- match.data(match_out)

summary(lm(
  empathy_prop ~ treatment + is_gender_issue + as.factor(circuit) + as.factor(area) + republican + sons + race + religion + progressive.vote,
  data = matched_train,
  weights = matched_train$weights
  )
)

train$date <- as_date(train$date)
plot(train$date, train$topic_3)

## Results figures
## Main results Plot
# Example Documents
# Hand Code validation
# Shaded map based on circuits