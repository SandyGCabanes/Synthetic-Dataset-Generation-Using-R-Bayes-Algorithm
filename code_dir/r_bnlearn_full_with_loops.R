# setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn_full/n774_restart0_with_loops")


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

# All cols 
all_cols <- names(df_full) 
all_cols_factor <- as.factor(all_cols)





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

write.csv(df_full, "df_full.csv")



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Optimize the BN run for a specific duplicate count ----
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Define the target number of duplicates ----
target_duplicates <- 20

# Set a counter to prevent infinite loops ----
run_count <- 0
max_runs <- 2000 # Increased to 2000

# Initialize duplicated_real, min_duplicates ----
duplicated_real <- 0
min_duplicates <- Inf
best_run_data <- NULL






# Fixed section ~~~~~~~~~~~----

# 1. Learn structure once ----
bn_structure <- hc(df_full)
print("Bayesian Network structure learned once outside the loop.")

# 2. Fit conditional probability tables once ----
bn_fit <- bn.fit(bn_structure, data = df_full, method = "bayes")
saveRDS(bn_fit, "bn_fit.rds")
saveRDS(bn_structure, "bn_structure.rds")
saveRDS(nodes, "nodes.rds")
saveRDS(arcs, "arcs.rds")
print("Bayesian Network fit completed once outside the loop.")





# Loop section ~~~~~~~~~~~~----

# Start a while loop that runs until the target is met or max_runs is reached
while (duplicated_real != target_duplicates && run_count < max_runs) {
  
  # Increment the run counter
  run_count <- run_count + 1
  print(paste("Attempt number:", run_count))
  
  # Set a different seed for each run
  set.seed(run_count)
  
  # 3. Generate new synthetic data in each loop iteration ----
  syn_df_full <- rbn(bn_fit, n = nrow(df_full))
  
  # 4. Add unique, non-overlapping row_ids and tags ----
  df_full_tagged <- df_full %>% 
    mutate(row_id = row_number() + 10000, source = "real")
  syn_df_full_tagged <- syn_df_full %>% 
    mutate(row_id = row_number() + 20000, source = "synthetic")
  
  # 5. Combine datasets ----
  bindrows_df <- bind_rows(df_full_tagged, syn_df_full_tagged)
  
  # 6. Count duplicates using composite factors ----
  bindrows_df_factors <- bindrows_df %>%
    mutate(combinedfactors = do.call(paste, c(select(., where(is.factor), -source), sep = "|")))
  
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
  
  # Create dup_check_full_with_ids ----
  dup_check_full_with_ids <- bindrows_df_factors %>%
    right_join(dup_check_full, by = "combinedfactors") %>%
    group_by(combinedfactors, count, sources, count_real, count_synthetic) %>%
    summarise(
      row_ids = paste(row_id, collapse = ","),
      .groups = "drop"
    )
  
  # Mutate row_id real and row_id_syn ----
  dup_check_full_with_ids <- dup_check_full_with_ids %>%
    mutate(
      row_id_real = sapply(strsplit(row_ids, ","), function(ids) {
        paste(ids[as.numeric(ids) >= 10001 & as.numeric(ids) <= 19999], collapse = ",")
      }),
      row_id_syn = sapply(strsplit(row_ids, ","), function(ids) {
        paste(ids[as.numeric(ids) >= 20001], collapse = ",")
      })
    ) %>%
    select(-row_ids)
  
  # Update the duplicated_real value
  duplicated_real <- sum(dup_check_full_with_ids$count_real)
  
  # Print the result of the current run
  print(paste("Duplicates found in this run:", duplicated_real))
  
  # Check if current run is better, update minimum ----
  # Dup_check_full is finalized with dup_check_full_with_ids
  # Best_run_data saved as list for 
  if (run_count == 1 || duplicated_real < min_duplicates) {
    min_duplicates <- duplicated_real
    best_run_data <- list(
      dup_check_full = dup_check_full_with_ids,
      syn_df_full = syn_df_full,
      syn_df_full_tagged = syn_df_full_tagged,
      seed = run_count
    )
    print(paste("New minimum duplicates found:", min_duplicates))
  }
}

# Final output after the loop

# if (duplicated_real == target_duplicates) {
#   print("Target number of duplicates reached!")
#   # Export the final dataframes
#   write.csv(best_run_data$dup_check_full, "dup_check_full_with_ids.csv")
#   write.csv(df_full, "df_full.csv")
#   write.csv(best_run_data$syn_df_full, "syn_df_full.csv")
#   print(paste("The seed that reached the target was:", best_run_data$seed))
# } else {
#   print(paste("Could not reach the target number of duplicates within the maximum number of runs. The best result was", min_duplicates, "duplicates."))
#   # Export the best result found
#   write.csv(best_run_data$dup_check_full, "dup_check_full_with_ids.csv")
#   write.csv(df_full, "df_full.csv")
#   write.csv(best_run_data$syn_df_full, "syn_df_full.csv")
# }


# Final outputs after the loop
if (duplicated_real == target_duplicates) {
  print("Target number of duplicates reached!")
  print(paste("The seed that reached the target was:", best_run_data$seed))
} else {
  print(paste("Could not reach the target number of duplicates within the maximum number of runs. The best result was", min_duplicates, "duplicates with seed", best_run_data$seed))
}

# Export the best results found
write.csv(best_run_data$dup_check_full, "dup_check_full_with_ids.csv", row.names = FALSE)
write.csv(df_full, "df_full.csv", row.names = FALSE)
write.csv(best_run_data$syn_df_full, "syn_df_full.csv", row.names = FALSE)
write.csv(best_run_data$syn_df_full_tagged, "syn_df_full_tagged.csv", row.names = FALSE )



