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
# NoSalary df ----
# ~~~~~~~~~~~~~~~~~~
# Filter no-salary subset, fill in missing with "CODEASBLANK", change to factors
df_nosal <- df_model %>%
  filter(!(salary != "" & salary != "NA")) %>%
  mutate(across(
    where(is.character),
    ~ iconv(.x, from = "", to = "UTF-8")   # normalize encoding
  )) %>%
  mutate(across(
    where(is.character),
    ~ replace(.x, trimws(.x) == "" | is.na(.x), "CODEASBLANK") 
  )) %>%
  mutate(across(everything(), as.factor)) # change to factors

summary(df_nosal)
str(df_nosal)

# ~~~~~~~~~~~~~~~~~~~~~~~~
# Remove useless cols ----
# ~~~~~~~~~~~~~~~~~~~~~~~~
cols_remove <- c("careerstg", "worksame", "workcity", "salary", "typework", "sitework", "datarole", "restofrole", "sizeteam", "ingestion", "transform", "warehs", "orchest", "busint", "reversetl", "dataqual", "datacatalog", "cloudplat", "noncloudplat", "successmethod")

df_nosal_model <- df_nosal %>% 
  select(-all_of(cols_remove))


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Learn structure (Hill-Climbing) ----
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

bn_structure <- hc(df_nosal_model)

# Fit conditional probability tables ----
bn_fit <- bn.fit(bn_structure, data = df_nosal_model, method = "bayes")

# Generate same rows of synthetic data ----
syn_df_nosal <- rbn(bn_fit, n = nrow(df_nosal_model))

# Explore syn data 
str(syn_df_nosal)
summary(syn_df_nosal)

# ~~~~~~~~~~~~~~~~
# Check duplicates ----
# ~~~~~~~~~~~~~~~~

# Tag and combine ----
# Tag source using unjoined synthetic_df and df_single
df_nosal_tagged<- df_nosal_model %>% mutate(source = "real") 
syn_df_nosal_tagged <- syn_df_nosal %>% mutate(source = "synthetic") 

# Combine datasets (union)
combined_df_ns <- bind_rows(df_nosal_tagged, syn_df_nosal_tagged)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Count duplicates using composite factors----
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Create a composite column of all factors
all_factors <- combined_df_ns %>% select(where(is.factor))
combined_df_ns_factors <- combined_df_ns %>%
  mutate(compositefactors = do.call(paste, c(all_factors, sep = "|")))
dup_check_factors_ns <- combined_df_ns_factors %>%
  group_by(compositefactors) %>%
  summarise(
    count = n(),
    sources = paste(unique(source), collapse = ","),
    count_real = sum(source == "real"),
    count_synthetic = sum(source == "synthetic"),
    .groups = "drop"
  ) %>%
  filter(count > 1 & sources == "real,synthetic")

print(dup_check_factors_ns) # 21 of 98 rows duplicated.
# These duplicated rows will be manually edited to remove similarity to raw data.


# export df to csv ----
write.csv(df_nosal, "df_nosal.csv")
write.csv(syn_df_nosal, "syn_df_nosal.csv")

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
freq_dfnosal  <- get_freqs(df_nosal)
freq_syndfnosal  <- get_freqs(syn_df_nosal)

# Combine and label ----
freq_combined_ns <- bind_rows(
  freq_dfnosal %>% mutate(dataset = "Original"),
  freq_syndfnosal %>% mutate(dataset = "Synthetic")
)


# export freq_combined_ns to csv ----
write.csv(freq_combined_ns, "freq_combined_ns.csv")
