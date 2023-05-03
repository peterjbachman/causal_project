library(dplyr)
library(tidyr)
library(stringr)
library(stm)

train <- read.csv("data/cleaned/train_case.csv") %>%
  select(c("casename", "circuit", "cite", "area", "enbanc", "opinion", "opinion_author", "is_gender_issue"))

df <- train %>%
  separate_longer_delim(opinion, delim = "\n") %>%
  mutate(
    word_count = str_count(opinion, pattern = "\\w+\\s+")
  ) %>%
  filter(word_count > 20) %>%
  group_by(cite) %>%
  mutate(
    id = row_number(cite)
  )

processed <- textProcessor(documents = df$opinion, metadata = df)
out <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh = 20)
docs <- out$documents
vocab <- out$vocab
meta <- out$meta

plotRemoved(processed$documents, lower.thresh = seq(1, 200, by = 5))

storage <- searchK(
  out$documents,
  out$vocab,
  K = c(29:51),
  prevalence = ~as.factor(circuit) + enbanc + as.factor(area) + as.factor(opinion_author) + is_gender_issue,
  data = meta,
  cores = 10
)

save(storage, file = "data/cleaned/test_topics.RData")

# 30 topics seems about right for now?
plot(storage)

topic_fit <- stm(
  documents = out$documents,
  vocab = out$vocab,
  K = 30,
  prevalence = ~as.factor(circuit) + enbanc + as.factor(area) + as.factor(opinion_author) + is_gender_issue,
  max.em.its = 100,
  data = out$meta,
  init.type = "LDA",
)


topic_select <- selectModel(
  out$documents,
  out$vocab,
  K = 30,
  prevalence = ~as.factor(circuit) + enbanc + as.factor(area) + as.factor(opinion_author) + is_gender_issue,
  max.em.its = 1000,
  data = out$meta,
  runs = 20,
  seed = 12345,
  init.type = "LDA",
)
save(topic_select, file = "data/cleaned/topic_model.RData")

plotModels(topic_select, pch = c(1:4), legend.position = "bottomright")
selected_model <- topic_select$runout[[3]]
save(selected_model, file = "data/cleaned/final_model.RData")

labelTopics(selected_model, c(15))

findThoughts(selected_model, texts = df$opinion, n = 10, topics = 15)$docs[[1]]
plot(selected_model, type = "perspectives", topics = c(8, 15))
