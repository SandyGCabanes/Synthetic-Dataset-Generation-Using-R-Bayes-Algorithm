# setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn_full/n774_restart0_with_loops")

library(dplyr)
library(ggplot2)

df_full <- read.csv("df_full.csv")


# Plot stacked columns for actual data
df_full_stacked <- df_full %>% 
  filter(salary != "CODEASBLANK") %>%
  filter(educstat != "CODEASBLANK")

actual_sal_educ <- ggplot(df_full_stacked, aes(x = factor(salary), fill = educstat)) +
  geom_bar(color = "white", size = 0.2) +
  labs(
    title = "ACTUAL DATA: Salary and Education Status",
    x     = "Salary",
    y     = "Count",
    fill  = "Education Status"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid   = element_blank()
  )

print(actual_sal_educ)





# Read in synthetic data
syn_df_full_deduped <- read.csv("syn_df_full_deduped.csv")


# Plot stacked columns for synthetic data
syn_df_full_stacked <- syn_df_full_deduped %>% 
  filter(salary != "CODEASBLANK") %>%
  filter(educstat != "CODEASBLANK")

synth_sal_educ <- ggplot(syn_df_full_stacked, aes(x = factor(salary), fill = educstat)) +
  geom_bar(color = "white", size = 0.2) +
  labs(
    title = "SYNTHETIC DATA: Salary and Education Status",
    x     = "Salary",
    y     = "Count",
    fill  = "Education Status"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid   = element_blank()
  )

print(synth_sal_educ)

