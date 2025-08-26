# setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn_salary_split")


# ~~~~~~~~~~~~~~~~~
# Load dataset ----
# ~~~~~~~~~~~~~~~~~
library(bnlearn)
library(dplyr)
df <- read.csv("dataset_sub.csv")

df_model <- df%>%
  mutate(age_grp = cut(
    age,
    breaks = c(19, 25, 30, 35, 40, 45, 50, 55, Inf),
    labels = c("20-25", "26-30", "31-35", "36-40", "41-45", "46-50", "51-55", "Above 55"),
    right = FALSE,
    include.lowest = TRUE
  ))
df_model <- as.data.frame(df_model)
df_model <- select(df_model, -Timestamp, -id, -age, -bestproject)
str(df_model$age_grp)

# Basic exploration
str(df_model)
summary(df_model)

# all cols ----
all_cols <- names(df_model) 
all_cols_factor <- as.factor(all_cols)

# ~~~~~~~~~~~~~~~~~~
# Salary df ----
# ~~~~~~~~~~~~~~~~~~
# Filter salary subset, fill in missing with "CODEASBLANK", change to factors
df_sal <- df_model %>%
  filter(salary != "" & salary != "NA") %>%
  mutate(across(
    where(is.character),
    ~ iconv(.x, from = "", to = "UTF-8")   # normalize encoding
  )) %>%
  mutate(across(
    where(is.character),
    ~ replace(.x, trimws(.x) == "" | is.na(.x), "CODEASBLANK") 
  )) %>%
  mutate(across(everything(), as.factor)) # change to factors

summary(df_sal)
str(df_sal)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Learn structure (Hill-Climbing) ----
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

bn_structure <- hc(df_sal)

# Fit conditional probability tables ----
bn_fit <- bn.fit(bn_structure, data = df_sal, method = "bayes")

# Generate same rows of synthetic data ----
syn_df_sal <- rbn(bn_fit, n = nrow(df_sal))

# Explore syn data 
str(syn_df_sal)
summary(syn_df_sal)

# ~~~~~~~~~~~~~~~~
# Check duplicates ----
# ~~~~~~~~~~~~~~~~

# Tag and combine ----
# Tag source using unjoined synthetic_df and df_single
df_sal_tagged<- df_sal %>% mutate(source = "real") 
syn_df_sal_tagged <- syn_df_sal %>% mutate(source = "synthetic") 

# Combine datasets (union)
combined_df <- bind_rows(df_sal_tagged, syn_df_sal_tagged)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Count duplicates using composite factors----
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Create a composite column of all factors
all_factors <- combined_df %>% select(where(is.factor))
combined_df_factors <- combined_df %>%
  mutate(compositefactors = do.call(paste, c(all_factors, sep = "|")))
dup_check_factors <- combined_df_factors %>%
  group_by(compositefactors) %>%
  summarise(
    count = n(),
    sources = paste(unique(source), collapse = ","),
    count_real = sum(source == "real"),
    count_synthetic = sum(source == "synthetic"),
    .groups = "drop"
  ) %>%
  filter(count > 1 & sources == "real,synthetic")

print(dup_check_factors) # 21 of 143 rows 
# These duplicated rows will be manually edited to remove the similarity to raw data.


# export df to csv ----
write.csv(df_sal, "df_sal.csv")
write.csv(syn_df_sal, "syn_df_sal.csv")

# ~~~~~~~~~~~~~~~~~~~~~~~~
# Frequency distributions ----
# ~~~~~~~~~~~~~~~~~~~~~~~~
library(dplyr)
library(tidyr)
library(ggplot2)

# Pivot longer and group_by variable for long table function
get_freqs <- function(df) {
  df %>%
    pivot_longer(
      cols      = everything(),
      names_to  = "variable",
      values_to = "value"
    ) %>%
    group_by(variable, value) %>%
    summarise(
      count       = n(),
      prop        = n() / nrow(df),
      .groups     = "drop"
    ) %>%
    arrange(variable, desc(count))
}

# Apply to both
freq_dfsal  <- get_freqs(df_sal)
freq_syndfsal  <- get_freqs(syn_df_sal)

# Combine and label ----
freq_combined <- bind_rows(
  freq_dfsal %>% mutate(dataset = "Original"),
  freq_syndfsal %>% mutate(dataset = "Synthetic")
)

# export plotting table to csv ----
write.csv(freq_combined, "freq_combined.csv")

