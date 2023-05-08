library(dplyr)
library(tidyr)
library(stringr)
library(stm)

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

# I don't use excel so I'm just gonna input them all here lol

labels <- c(
  34, 36, 14, 17, 38, 10, 51, 56, 9,  12,
  4,  5,  51, 44, 44, 34, 26, 53, 18, 57,
  49, 54, 13, 55, 46, 42, 16, 59, 37, 4,
  8,  37, 55, 47, 12, 30, 1,  58, 42, 5,
  49, 9,  27, 37, 36, 9,  55, 55, 10, 49
)

to_label$topic_validate <- labels
write.csv(to_label, "data/cleaned/hand_validate.csv", row.names = FALSE)

to_label <- to_label[-43,]

processed <- textProcessor(documents = to_label$opinion, metadata = to_label)
validate <- prepDocuments(processed$documents, processed$vocab, processed$meta)
new <- alignCorpus(new = validate, old.vocab = topic_fit$vocab)
ests <- fitNewDocuments(
  model = topic_fit,
  documents = new$documents,
  newData = new$meta,
  origData = out$meta,
  prevalence = ~as.factor(circuit) + enbanc + as.factor(area) + is_gender_issue,
  prevalencePrior = "Covariate"
)

topics <- ests$theta %>%
  as.data.frame() %>%
  mutate(topic = names(.)[max.col(.)]) %>%
  select(topic)
to_label <- bind_cols(to_label, topics)

to_label$topic <- as.numeric(str_extract(to_label$topic, "[0-9]+"))

# Ayye 28.57% aint good for hand coded validation.
sum(to_label$topic == to_label$topic_validate) / nrow(to_label)

# But the general topics I labelled them as match up, so I need fewer
# topics and probably more text to stabilize topics.