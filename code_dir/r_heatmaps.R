# setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn_full/n774_restart0_with_loops")

library(dplyr)
library(ggplot2)

df_full <- read.csv("df_full.csv")


# Compute counts by educstat and salary
freq_real <- df_full %>%
  count(educstat, salary) %>%
  ungroup()

# Plot heatmap for real data
p_real <- ggplot(freq_real, aes(x = educstat, y = factor(salary), fill = n)) +
  geom_tile(color = "white", size = 0.2) +
  scale_fill_gradient(low = "lightblue", high = "steelblue", name = "Count") +
  coord_fixed(ratio = 1) +
  labs(
    title = "Real Data: Salary vs Education Status",
    x     = "Education Status",
    y     = "Salary"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid   = element_blank()
  )

print(p_real)







# Read in synthetic data
syn_df_full_deduped <- read.csv("syn_df_full_deduped.csv")

# Compute counts by educstat and salary
freq_syn <- syn_df_full_deduped %>%
  count(educstat, salary) %>%
  ungroup()

# Plot heatmap for synthetic data
p_syn <- ggplot(freq_syn, aes(x = educstat, y = factor(salary), fill = n)) +
  geom_tile(color = "white", size = 0.1) +
  scale_fill_gradient(low = "violet", high = "darkviolet", name = "Count") +
  coord_fixed(ratio = 1) +
  labs(
    title = "Synthetic Data: Salary vs Education Status",
    x     = "Education Status",
    y     = "Salary"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid   = element_blank()
  )

print(p_syn)
