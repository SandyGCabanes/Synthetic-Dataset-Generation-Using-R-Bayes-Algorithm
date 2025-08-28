# setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn_full/no_blacklist_run")


# ~~~~~~~~~~~~~~~~~
# Load dataset ----
# ~~~~~~~~~~~~~~~~~
library(bnlearn)
library(dplyr)
df <- read.csv("dataset_full.csv")

df_full <- df %>%
  mutate(age_grp = cut(
    age,
    breaks = c(-Inf, 19, 25, 30, 35, 40, 45, 50, 55, Inf),
    labels = c("<19", "20–24", "25–29", "30–34", "35–39", "40–44", "45–49", "50–54", "55+"),
    right = FALSE,
    include.lowest = TRUE
  ))
df_full <- as.data.frame(df_full)
df_full <- select(df_full, -Timestamp, -resp_id, -age, -bestproject, -agegrp)
str(df_full$age_grp)

# all cols ----
all_cols <- names(df_full) 
all_cols_factor <- as.factor(all_cols)

# Basic exploration
str(df_full)
summary(df_full)

# ~~~~~~~~~~~~~~~~~~
# Pre-process ----
# ~~~~~~~~~~~~~~~~~~
# UTF-8 encoding, fill in missing with "CODEASBLANK", change to factors
df_full <- df_full %>%
  mutate(across(
    where(is.character),
    ~ iconv(.x, from = "", to = "UTF-8")   # normalize encoding
  )) %>%
  mutate(across(
    where(is.character),
    ~ replace(.x, trimws(.x) == "" | is.na(.x), "CODEASBLANK") 
  )) %>%
  mutate(across(everything(), as.factor)) # change to factors

summary(df_full)
str(df_full)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Learn structure (Hill-Climbing) ----
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 

# Learn structure ----
bn_structure <- hc(df_full, restart = 5)

# Nodes, arcs, scores, graphs
# Get names of nodes 
nodes(bn_structure)
writeLines(nodes(bn_structure), "nodes.txt")
# To get the Arcs (relationships) in the network structure:
arcs(bn_structure)

# To get only the Directed Arcs:
directed.arcs(bn_structure)

# To get only the Undirected Arcs (if any):
undirected.arcs(bn_structure)

# Get the scores of the learned stucture 
score(bn_structure, data = df_full, type = "bic")

# A simpler plotting function for smaller networks:
plot.bn(bn_structure)

# To see the 'test' used by the learning algorithm (e.g., "bic" for hc):
bn_structure$learning$test

# To see the 'ntests' (number of score comparisons) performed during learning:
bn_structure$learning$ntests
# Fit conditional probability tables ----
bn_fit <- bn.fit(bn_structure, data = df_full, method = "bayes")

# Generate same rows of synthetic data ----
syn_df_full <- rbn(bn_fit, n = nrow(df_full))

# Explore syn data 
str(syn_df_full)
summary(syn_df_full)

# ~~~~~~~~~~~~~~~~
# Check duplicates ----
# ~~~~~~~~~~~~~~~~

# Tag and combine ----
# Tag source using unjoined synthetic_df and df_single
df_full_tagged<- df_full %>% mutate(source = "real") 
syn_df_full_tagged <- syn_df_full %>% mutate(source = "synthetic") 

# Combine datasets (union)
bindrows_df <- bind_rows(df_full_tagged, syn_df_full_tagged)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Count duplicates using composite factors----
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Create a composite column of all factors
all_factors <- bindrows_df %>% select(where(is.factor))
bindrows_df_factors <- bindrows_df %>%
  mutate(combinedfactors = do.call(paste, c(all_factors, sep = "|")))
dup_check_full <- bindrows_df_factors %>%
  group_by(combinedfactors) %>%
  summarise(
    count = n(),
    sources = paste(unique(source), collapse = ","),
    count_real = sum(source == "real"),
    count_synthetic = sum(source == "synthetic"),
    .groups = "drop"
  ) %>%
  filter(count > 1 & sources == "real,synthetic")

# export dup_check to csv ----
write.csv(dup_check_full, "dup_check_full.csv")
print(dup_check_full) # 


# export df to csv ----
write.csv(df_full, "df_full.csv")
write.csv(syn_df_full, "syn_df_full.csv")

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
freq_df_full  <- get_freqs(df_full)
freq_syn_df_full  <- get_freqs(syn_df_full)

# Combine and label ----
freq_combined_full <- bind_rows(
  freq_df_full %>% mutate(dataset = "Original"),
  freq_syn_df_full %>% mutate(dataset = "Synthetic")
)

# export plotting table to csv ----
write.csv(freq_combined_full, "freq_combined_full.csv")

