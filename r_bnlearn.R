# setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn")
library(bnlearn)
library(dplyr)

# ~~~~~~~~~~~~~~~~~
# Load dataset ----
# ~~~~~~~~~~~~~~~~~
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

# ~~~~~~~~~~~~~~~~~~
# Single-select ----
# ~~~~~~~~~~~~~~~~~~
# Define single-select columns and create df_single, df_single_complete
single_select_cols <- c("age_grp", "city", "country", "gender", "educstat", "careerstg", "industry", "workcity", "salary", "typework", "sitework", "datarole", "sizeteam", "useai", "depwebsite") 

df_single <- df_model %>%
  select(all_of(single_select_cols)) %>%
  mutate(across(all_of(single_select_cols), as.factor)) 

str(df_single)

# Drop NAs to prevent bnlearn from crashing ----
# df_single_complete <- df_single[complete.cases(df_single), ]

# Check count rows after dropping NA to prevent bnlearn from crashing 
# nrow(df_single_complete)  # 191 rows out of 241, 21% loss
# nrow(df_single) #21% data loss not acceptable, do not use df_single_complete

# Impute using mode just for learning ----
# impute function
mode_impute <- function(x) {
  ux <- na.omit(x)
  if (length(ux) == 0) return(x)
  m <- names(sort(table(ux), decreasing = TRUE))[1]
  x[is.na(x)] <- m
  return(x)
}

# apply impute function
df_single_temp <- df_single %>%
  mutate(across(where(is.factor), ~ {
    x <- .
    x[is.na(x)] <- mode_impute(x)
    x
  }))



nrow(df_single_temp) # 241 rows preserved
str(df_single_temp)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Learn structure (Hill-Climbing) ----
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

bn_structure <- hc(df_single_temp)

# Fit conditional probability tables ----
bn_fit <- bn.fit(bn_structure, data = df_single, method = "bayes")

# Generate 1000 rows of synthetic data ----
synthetic_df <- rbn(bn_fit, n = 1000)

# Add the join column ----
synthetic_df <- synthetic_df %>%
  mutate(joincol = paste(age_grp,city, country, gender, educstat, careerstg, industry, workcity, salary, typework, sitework, datarole, sizeteam, useai, depwebsite, sep = "|"))

# ~~~~~~~~~~~~~~~~
# Multi-select----
# ~~~~~~~~~~~~~~~~
# Create multi-select df for joining later with synthetic dataset
multi_select_cols <- c("digitools", "successmethod", "restofrole", "ingestion", 
                       "transform", "warehs", "orchest", "busint", "reversetl",
                       "dataqual", "datacatalog", "cloudplat", "noncloudplat", 
                       "generaltools", "whatused", "hostedntbk", "hardware", 
                       "otherfb")

multi_select_cols <- c(multi_select_cols, "joincol")


df_multi <- df_model %>%
  mutate(joincol = paste(age_grp,city, country, gender, educstat, careerstg, industry, workcity, salary, typework, sitework, datarole, sizeteam, useai, depwebsite, sep = "|")) %>%
  select(all_of(multi_select_cols), ) %>%
  mutate(across(all_of(multi_select_cols), as.factor)) 
str(df_multi)

# ~~~~~~~~~~~~~~~~
# Try joining synthetic_df with df_multi ----
# ~~~~~~~~~~~~~~~~

synthetic_df_full_leftjoin <- left_join(synthetic_df, df_multi, by = "joincol") # empty table
synthetic_df_full_merge <- merge(synthetic_df, df_multi, by = "joincol") # multi-select cols are empty 

# Fuzzy join experiment - 240769 rows - not useful
synthetic_df_full_fuzzy <- fuzzyjoin::regex_left_join(synthetic_df, df_multi, by = "joincol")

# Check key overlap
common_keys <- intersect(synthetic_df$joincol,df_multi$joincol)
length(common_keys)  # 0 overlap

# Drop joincol since it is useless----
synthetic_df <- synthetic_df %>% select(-joincol)
df_multi <- df_multi %>% select(-joincol)

# ~~~~~~~~~~~~~~~~
# Check duplicates single-select ----
# ~~~~~~~~~~~~~~~~

# Tag source using unjoined synthetic_df and df_single
df_single_tagged <- df_single %>% mutate(source = "real") 
synthetic_df_tagged <- synthetic_df %>% mutate(source = "synthetic") %>% select(-joincol)

# Combine datasets (union)
combined_df <- bind_rows(df_single_tagged, synthetic_df_tagged)

# Create a composite column for counting duplicates later
combined_df <- combined_df %>%
  mutate(compositecol = paste(age_grp,city, country, gender, educstat, careerstg, industry, workcity, salary, typework, sitework, datarole, sizeteam, useai, depwebsite, sep = "|"))

# Count duplicates using composite column
dup_check <- combined_df %>%
  group_by(compositecol) %>%
  summarise(count = n(), sources = paste(unique(source), collapse = ","), .groups = "drop") %>%
  filter(count > 1 & sources == "real,synthetic")

print(dup_check)  # Success. No duplicates. Synthetic data are indistinguishable.

# ~~~~~~~~~~~~~~~
# KNN to approximate join, no intersection ----
# ~~~~~~~~~~~~~~~

library(FNN)

# 0. Back to old multi_select_cols definition without joincol
multi_select_cols <- c("digitools", "successmethod", "restofrole", "ingestion", "transform", "warehs", "orchest", "busint", "reversetl","dataqual", "datacatalog", "cloudplat", "noncloudplat", "generaltools", "whatused", "hostedntbk", "hardware", "otherfb")

# 1. Subset only the factor columns you care about
real_subset  <- df_model      %>% select(all_of(single_select_cols))
synth_subset <- synthetic_df %>% select(all_of(single_select_cols))

# 2. Stack them
combined <- bind_rows(real_subset, synth_subset)

# 3. One-hot encode once on the combined data
#    This creates a consistent set of dummy columns
combined_mm <- model.matrix(~ . - 1, data = combined, na.action = na.pass)

# 4. Split the design matrix back into real vs synthetic
n_real <- nrow(real_subset)
real_encoded  <- combined_mm[  1:n_real, , drop = FALSE]
synth_encoded <- combined_mm[(n_real+1):nrow(combined_mm), , drop = FALSE]

# 4a. Sanity check: no rows have been dropped
if (nrow(synth_encoded) != nrow(synthetic_df)) {
  stop(
    "Row mismatch: synth_encoded has ", nrow(synth_encoded),
    " rows but synthetic_df has ", nrow(synthetic_df),
    ". Check for rows with all-NA in single_select_cols."
  )
}

# 4b. Sanity check: same dummy columns for real vs synthetic
if (!identical(colnames(real_encoded), colnames(synth_encoded))) {
  stop(
    "Column mismatch between real_encoded and synth_encoded:\n",
    "Real cols:   ", paste(colnames(real_encoded), collapse = ", "), "\n",
    "Synthetic cols: ", paste(colnames(synth_encoded), collapse = ", ")
  )
}

# 5. Nearest-neighbor match
nn <- get.knnx(data = real_encoded, query = synth_encoded, k = 1)
matched_indices <- nn$nn.index[, 1]

# 6. Validate multi_select_cols against df_model
missing_cols <- setdiff(multi_select_cols, colnames(df_model))
if (length(missing_cols) > 0) {
  stop(
    "These multi_select_cols are not in df_model:\n  ",
    paste(missing_cols, collapse = ", ")
  )
}

valid_multi_cols <- intersect(multi_select_cols, colnames(df_model))

# 7. Pull the matched multi-response columns
matched_multi <- df_model[matched_indices, valid_multi_cols, drop = FALSE]

# 8. Bind multi-response columns back onto your synthetic_df
synthetic_df_matched <- bind_cols(synthetic_df, matched_multi)


# ~~~~~~~~~~~~~~~
# Simple 5 of 15 match to approximate join ----
# ~~~~~~~~~~~~~~~

library(dplyr)
# Reset cols to original without joincol
single_select_cols <- c("age_grp", "city", "country", "gender", "educstat", "careerstg", "industry", "workcity", "salary", "typework", "sitework", "datarole", "sizeteam", "useai", "depwebsite") 
multi_select_cols <- c("digitools", "successmethod", "restofrole", "ingestion", 
                       "transform", "warehs", "orchest", "busint", "reversetl",
                       "dataqual", "datacatalog", "cloudplat", "noncloudplat", 
                       "generaltools", "whatused", "hostedntbk", "hardware", 
                       "otherfb")

# 0. Parameters
threshold         <- 5
single_cols       <- single_select_cols       # length = 15
multi_cols        <- multi_select_cols        # your multi-response columns

# 1. Turn the values into characters for matching
real_ss  <- df_model      %>% 
  select(all_of(single_cols)) %>% 
  mutate(across(everything(), as.character))

synth_ss <- synthetic_df %>% 
  select(all_of(single_cols)) %>% 
  mutate(across(everything(), as.character))

# 2. For each synthetic row, find the best real match and its match count
match_info <- apply(synth_ss, 1, function(s_row) {
  # compute match counts across all real rows
  counts <- rowSums(real_ss == s_row, na.rm = TRUE)
  best  <- which.max(counts)
  c(best_idx = best, match_count = counts[best])
})

# transpose into a tibble
match_info <- as_tibble(t(match_info), .name_repair = "minimal") %>%
  mutate(across(everything(), as.integer)) %>%
  mutate(is_match = (match_count >= threshold))

# 3. Extract matched multi-response columns (or fill with NA if no match)
synthetic_df_matched <- synthetic_df %>%
  mutate(.synth_row = row_number()) %>%
  left_join(
    match_info %>%
      mutate(.synth_row = row_number()) %>%
      filter(is_match) %>%
      select(.synth_row, best_idx),
    by = ".synth_row"
  ) %>%
  mutate(best_idx = as.integer(best_idx)) %>%
  left_join(
    df_model %>%
      mutate(.real_row = row_number()) %>%
      select(.real_row, all_of(multi_cols)),
    by = c("best_idx" = ".real_row")
  ) %>%
  select(-.synth_row, -best_idx)

# Result:
# – synthetic_df_matched has original synthetic_df + matched multi-response columns where match_count ≥ threshold.
# – unmatched rows will have NA in the new multi-response fields.

# Check match_info and find best threshold value setting
matched_rows <- match_info %>%
  group_by(is_match) %>%
  summarise(count = n())
# threshold 7, matched 809
# threshold 6, matched 970
# threshold 5, matched 999

# export to csv ----
write.csv(df_model, "df_model.csv")
write.csv(synthetic_df_matched, "synthetic_data_matched.csv")

# ~~~~~~~~~~~~~~~~~~~~~~~~
# Frequency distributions ----
# ~~~~~~~~~~~~~~~~~~~~~~~~
library(dplyr)
library(tidyr)
library(ggplot2)

# Function to compute frequencies for one data frame
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
freq_model  <- get_freqs(df_model)
freq_synth  <- get_freqs(synthetic_df_matched)


# ggplot2 ----
library(dplyr)
library(tidyr)
library(ggplot2)

# 1. Combine and label
freq_combined <- bind_rows(
  df_model %>%    mutate(dataset = "Original"),
  synthetic_df_matched %>% mutate(dataset = "Synthetic")
)

# 2. Pivot and compute frequencies
freq_combined <- freq_combined %>%
  pivot_longer(
    cols      = -dataset,
    names_to  = "variable",
    values_to = "value"
  ) %>%
  group_by(dataset, variable, value) %>%
  summarise(
    count = n(),
    prop  = count / sum(count),
    .groups = "drop"
  )

# 3. Plot side-by-side bars, faceted by variable
ggplot(freq_combined, aes(x = value, y = prop, fill = dataset)) +
  geom_col(position = "dodge") +
  facet_wrap(~ variable, scales = "free_x") +
  labs(
    x    = NULL,
    y    = "Proportion",
    fill = "Dataset"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )



