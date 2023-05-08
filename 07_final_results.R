library(dplyr)
library(tidyr)
library(stringr)
library(stm)
library(ggplot2)
library(MatchIt)
library(quickmatch)
library(parameters)
library(see)

# Load in test data and training data
train <- read.csv("data/cleaned/train_case.csv") %>%
  mutate(
    treatment = ifelse(girls > 0, 1, 0),
    has_son = ifelse(sons > 0, 1, 0)
  )

test <- read.csv("data/cleaned/test_case.csv") %>%
  mutate(
    treatment = ifelse(girls > 0, 1, 0),
    has_son = ifelse(sons > 0, 1, 0)
  )

# Make data long based on paragraphs
train_long <- train %>%
  separate_longer_delim(opinion, delim = "\n") %>%
  mutate(
    word_count = str_count(opinion, pattern = "\\w+\\s+")
  ) %>%
  filter(word_count > 20) %>%
  group_by(casename) %>%
  mutate(
    id = row_number(casename)
  )

test_long <- test %>%
  filter(complete.cases(.) & !(area %in% c("housing", "sex discrimination"))) %>%
  separate_longer_delim(opinion, delim = "\n") %>%
  mutate(
    word_count = str_count(opinion, pattern = "\\w+\\s+")
  ) %>%
  filter(word_count > 20) %>%
  group_by(casename) %>%
  mutate(
    id = row_number(casename)
  )

# Process the data
process_train <- textProcessor(
  documents = train_long$opinion,
  metadata = train_long
)
process_test <- textProcessor(
  documents = test_long$opinion,
  metadata = test_long
)

out_train <- prepDocuments(
  process_train$documents,
  process_train$vocab,
  process_train$meta,
  lower.thresh = 40
)

# Based on how the stm package works I'll not remove words from this one since
# it's based on the training data vocab
out_test <- prepDocuments(
  process_test$documents,
  process_test$vocab,
  process_test$meta,
)

# Remove non-complete cases so analysis is smooth here.
complete_train <- train[complete.cases(train), ]

# Three observations are not in the areas that the test data had, so I'm going
# to remove them, along with doing the complete cases thing like above.
complete_test <- test[
  complete.cases(test) & !(test$area %in% c("housing", "sex discrimination")),
]

# Load in topic model
load("data/cleaned/topic_model.RData")

corpus_test <- alignCorpus(new = process_test, old.vocab = topic_fit$vocab)
ests <- fitNewDocuments(
  model = topic_fit,
  documents = corpus_test$documents,
  newData = corpus_test$meta,
  origData = process_train$meta,
  prevalence = ~ as.factor(circuit) + enbanc + as.factor(area) + is_gender_issue,
  prevalencePrior = "Covariate"
)

# Assign topic based on most probable
topics <- ests$theta %>%
  as.data.frame() %>%
  mutate(topic = names(.)[max.col(.)]) %>%
  select(topic)

test_long <- bind_cols(test_long, topics)

test_long$topic <- as.numeric(str_extract(test_long$topic, "[0-9]+"))
test_long$empathy <- ifelse(test_long$topic %in% c(13, 47, 48, 50, 51), 1, 0)
sum(test_long$empathy)

test_topics <- test_long %>%
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

test_topics[, -1] <- test_topics[, -1] / apply(test_topics[, -1], 1, sum)
test <- merge(test, test_topics, by = "casename")

test$empathy_prop <- test$topic_13 +
  test$topic_47 + test$topic_48 + test$topic_50 + test$topic_51

write.csv(test, "data/cleaned/test_final.csv", row.names = FALSE)

match_out <- matchit(
  treatment ~ is_gender_issue + republican + has_son + as.factor(race) + as.factor(religion),
  method = "quick",
  data = test
)

plot(summary(match_out))

matched_test <- match.data(match_out)

model <- lm(
  empathy_prop ~ treatment + is_gender_issue +
    as.factor(area) + republican + has_son + as.factor(race) + as.factor(religion) +
    progressive.vote + enbanc,
  data = matched_test,
  weights = matched_test$weights
)

theme_set(theme_modern())
effect_param <- model_parameters(model,  drop = "^as.factor")
effect_param$Parameter <- c(
  "Intercept", "Treatment (Daughter)", "Gender Issue", "Republican",
  "Judge Has a Son", "Progressive Vote", "En Banc Review"
)

plot(effect_param) +
  labs(title = "Effect of Having a Daughter on Empathy in Opinion Writing") +
  xlab("Change in Proportion of Case with Empathy") +
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_fill_identity(c("#a51417", "#005f85"))

ggsave("plots/results_figure.pdf", width = 9, height = 6, units = "in")
