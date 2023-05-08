library(dplyr)
library(tidyr)
library(ggplot2)
library(usmap)

circuits <- us_map("states")
df <- read.csv("data/cleaned/test_final.csv") %>%
  group_by(circuit) %>%
  summarise(empathy = mean(empathy_prop) * 100)

circuits_split <- circuits %>%
  mutate(
    x = case_when(
      # 1st District
      abbr %in% c("ME", "NH", "MA", "RI") ~ .$x + 300000,
      # 2nd District
      abbr %in% c("CT", "NY", "VT") ~ .$x + 0,
      # 3rd District
      abbr %in% c("PA", "NJ", "DE") ~ .$x + 200000,
      # 4th District
      abbr %in% c("WV", "VA", "NC", "SC", "MD") ~ .$x + 600000,
      # 5th Circuit
      abbr %in% c("TX", "LA", "MS") ~ .$x - 500000,
      # 6th Circuit
      abbr %in% c("MI", "OH", "KY", "TN") ~ .$x + 0,
      # 7th Circuit
      abbr %in% c("WI", "IN", "IL") ~ .$x - 500000,
      # 8th Circuit
      abbr %in% c("ND", "SD", "NE", "MN", "IA", "MO", "AR") ~ .$x - 900000,
      # 9th Circuit
      abbr %in% c("WA", "OR", "ID", "MT", "CA", "NV", "AZ", "AK", "HI") ~ .$x - 1500000,
      # 10th Circuit
      abbr %in% c("UT", "WY", "CO", "NM", "KS", "OK") ~ .$x - 900000,
      # 11th Circuit
      abbr %in% c("AL", "GA", "FL") ~ .$x + 300000,
      .default = .$x
    ),
    y = case_when(
      # 1st District
      abbr %in% c("ME", "NH", "MA", "RI") ~ .$y + 500000,
      # 2nd District
      abbr %in% c("CT", "NY", "VT") ~ .$y + 400000,
      # 3rd District
      abbr %in% c("PA", "NJ", "DE") ~ .$y + 200000,
      # 4th District
      abbr %in% c("WV", "VA", "NC", "SC", "MD") ~ .$y + 0,
      # 5th Circuit
      abbr %in% c("TX", "LA", "MS") ~ .$y - 300000,
      # 6th Circuit
      abbr %in% c("MI", "OH", "KY", "TN") ~ .$y + 0,
      # 7th Circuit
      abbr %in% c("WI", "IN", "IL") ~ .$y + 100000,
      # 8th Circuit
      abbr %in% c("ND", "SD", "NE", "MN", "IA", "MO", "AR") ~ .$y + 700000,
      # 9th Circuit
      abbr %in% c("WA", "OR", "ID", "MT", "CA", "NV", "AZ", "AK", "HI") ~ .$y + 200000,
      # 10th Circuit
      abbr %in% c("UT", "WY", "CO", "NM", "KS", "OK") ~ .$y + 100000,
      # 11th Circuit
      abbr %in% c("AL", "GA", "FL") ~ .$y - 300000,
      .default = .$y
    ),
    circuit = case_when(
      # 1st District
      abbr %in% c("ME", "NH", "MA", "RI") ~ "1",
      # 2nd District
      abbr %in% c("CT", "NY", "VT") ~ "2",
      # 3rd District
      abbr %in% c("PA", "NJ", "DE") ~ "3",
      # 4th District
      abbr %in% c("WV", "VA", "NC", "SC", "MD") ~ "4",
      # 5th Circuit
      abbr %in% c("TX", "LA", "MS") ~ "5",
      # 6th Circuit
      abbr %in% c("MI", "OH", "KY", "TN") ~ "6",
      # 7th Circuit
      abbr %in% c("WI", "IN", "IL") ~ "7",
      # 8th Circuit
      abbr %in% c("ND", "SD", "NE", "MN", "IA", "MO", "AR") ~ "8",
      # 9th Circuit
      abbr %in% c("WA", "OR", "ID", "MT", "CA", "NV", "AZ", "AK", "HI") ~ "9",
      # 10th Circuit
      abbr %in% c("UT", "WY", "CO", "NM", "KS", "OK") ~ "10",
      # 11th Circuit
      abbr %in% c("AL", "GA", "FL") ~ "11",
      # DC
      abbr %in% c("DC") ~ "DC",
      .default = NA
    ),
    empathy = case_when(
      # 1st District
      abbr %in% c("ME", "NH", "MA", "RI") ~ df$empathy[df$circuit == "1"],
      # 2nd District
      abbr %in% c("CT", "NY", "VT") ~ df$empathy[df$circuit == "2"],
      # 3rd District
      abbr %in% c("PA", "NJ", "DE") ~ df$empathy[df$circuit == "3"],
      # 4th District
      abbr %in% c("WV", "VA", "NC", "SC", "MD") ~ df$empathy[df$circuit == "4"],
      # 5th Circuit
      abbr %in% c("TX", "LA", "MS") ~ df$empathy[df$circuit == "5"],
      # 6th Circuit
      abbr %in% c("MI", "OH", "KY", "TN") ~ df$empathy[df$circuit == "6"],
      # 7th Circuit
      abbr %in% c("WI", "IN", "IL") ~ df$empathy[df$circuit == "7"],
      # 8th Circuit
      abbr %in% c("ND", "SD", "NE", "MN", "IA", "MO", "AR") ~ df$empathy[df$circuit == "8"],
      # 9th Circuit
      abbr %in% c("WA", "OR", "ID", "MT", "CA", "NV", "AZ", "AK", "HI") ~ df$empathy[df$circuit == "9"],
      # 10th Circuit
      abbr %in% c("UT", "WY", "CO", "NM", "KS", "OK") ~ df$empathy[df$circuit == "10"],
      # 11th Circuit
      abbr %in% c("AL", "GA", "FL") ~ df$empathy[df$circuit == "11"],
      # DC
      abbr %in% c("DC") ~ df$empathy[df$circuit == "DC"],
      .default = NA
    )
  )

circuit_labs <- circuits_split %>%
  group_by(circuit) %>%
  summarise(
    x = mean(x),
    y = mean(y) + 100000
  )
circuit_labs$y[11] <- 200000
circuit_labs$circuit <- c(
  "1st", "10th", "11th", "2nd", "3rd", "4th",
  "5th", "6th", "7th", "8th", "9th", "DC"
)

circuit_labs$circuit <- paste0(circuit_labs$circuit, ": ", round(df$empathy, 2), "%")

ggplot(circuits_split, aes(x = x, y = y, group = group, fill = empathy)) +
  geom_polygon(color = "black") +
  coord_fixed(ratio = 1) +
  theme_void() +
  geom_label(
    data = circuit_labs,
    aes(
      label = circuit,
      group = "circuit"
    ),
    fill = "white",
    size = 3
  ) +
  labs(
    fill = "Prop. of Case\n(Percent)",
    title = "Average Proportion of Empathy in Cases",
    subtitle = "(Per Circuit)"
  ) +
  scale_fill_gradient(
    low = "#C4D6DF",
    high = "#005f85"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

ggsave("plots/map_summary.pdf", width = 9, height = 6, units = "in")
