# setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn_full/n774_restart0_with_loops")

# ~~~~~~~~~~~~~~~~~~~
# Load libraries ----
# ~~~~~~~~~~~~~~~~~~~
library(dplyr)
library(stringr)

library(tidyr) # Frequency distributions
library(ggplot2) # Plots of distributions
library(htmltools) # Plots of distributions

# ~~~~~~~~~~~~~~~~~~~~
# Pre-process data----
# ~~~~~~~~~~~~~~~~~~~~
df_full <- read.csv("df_full.csv", stringsAsFactors = TRUE)
syn_df_full_tagged <- read.csv("syn_df_full_tagged.csv", stringsAsFactors = TRUE)
dup_check_full_with_ids <- read.csv("dup_check_full_with_ids.csv", stringsAsFactors = TRUE)
all_factors <- df_full %>% select(where(is.factor))

# # clean up X column if forgot to use row.names = FALSE
# df_full <- df_full %>% select(-any_of("X"))
# syn_df_full <- syn_df_full %>% select(-any_of("X"))
# dup_check <- dup_check %>% select(-any_of("X"))

# Drop all the rows in row_id_syn from syn_df_full
# Convert the comma-separated strings to a single numeric vector of IDs
row_ids_to_delete <- dup_check_full_with_ids %>%
  pull(row_id_syn) %>%
  str_split(pattern = ",", simplify = TRUE) %>%
  as.vector() %>%
  as.numeric()

# Drop all the rows in row_ids_to_delete from syn_df_full_tagged
syn_df_full_deduped <- syn_df_full_tagged %>%
  filter(!row_id %in% row_ids_to_delete) %>%
  select(-row_id, -source)

# Export to csv
write.csv(syn_df_full_deduped, "syn_df_full_deduped.csv", row.names = FALSE)







# ~~~~~~~~~~~~~~~~~~~~~~~~
# Frequency distributions ----
# ~~~~~~~~~~~~~~~~~~~~~~~~

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

# Apply to both original and synthetic ----
freq_df_full  <- get_freqs(df_full)
freq_syn_df_full  <- get_freqs(syn_df_full_deduped)



# Freq_combined_full ----

freq_combined_full <- bind_rows(
  freq_df_full %>%    mutate(dataset = "Original"),
  freq_syn_df_full %>% mutate(dataset = "Synthetic")
)

write.csv(freq_combined_full, "freq_combined_full.csv")






# Define colvals ----

colvals <- names(syn_df_full_deduped)

# Loop over colvals[1] ... colvals[length(colvals)] html plots----

present_vars <- unique(freq_combined_full$variable)
idx <- which(colvals %in% present_vars)

png_dir <- file.path(getwd(), "plots_dir")
if (!dir.exists(png_dir)) dir.create(png_dir, recursive = TRUE)

plot_divs <- list(
  tags$h1("All Variable Distributions"),
  tags$p(sprintf("Total variables plotted: %d", length(idx)))
)

for (i in idx) {
  plot_value <- freq_combined_full %>%
    filter(variable == colvals[i])
  
  # convert the x-label as string for truncation
  plot_value$value <- str_trunc(as.character(plot_value$value), width = 25, side = "right")
  
  # Find the longest label length for this variable
  max_label_len <- max(nchar(as.character(plot_value$value)), na.rm = TRUE)
  
  # Decide font size based on threshold
  axis_font_size <- if (max_label_len > 25) 3 else 8
  
  p <- ggplot(plot_value, aes(x = value, y = prop, fill = dataset)) +
    geom_col(position = "dodge", na.rm = TRUE) +
    labs(
      title = paste("Distribution of", colvals[i]),
      x = colvals[i],
      y = "Proportion",
      fill = "Dataset"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, size = axis_font_size)
    )
  
  img_file <- file.path(png_dir, paste0("plot_", i, ".png"))

  ggsave(img_file, plot = p, width = 8, height = 4.5, dpi = 150)
  
  plot_divs[[length(plot_divs) + 1]] <- tags$div(
    class = "plot-block",
    tags$h2(colvals[i]),
    # tags$img(src = img_file, style = "width:100%; height:auto;")
  )
}

# Html plots ----

page <- tags$html(
  tags$head(
    tags$meta(charset = "UTF-8"),
    tags$title("All Variable Distributions"),
    tags$style(HTML("
      body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
              margin: 16px auto; max-width: 1100px; line-height: 1.35; }
      h1 { margin-bottom: 8px; }
      h2 { margin: 24px 0 8px; font-size: 1.1rem; color: #333; }
      .plot-block { margin: 0 0 28px 0; padding-bottom: 8px; border-bottom: 1px solid #eee; }
      img { display: block; margin: auto; }
    "))
  ),
  tags$body(
    do.call(tagList, plot_divs)
  )
)

output_file <- "all_plots_original_synthetic_deduped.html"
htmltools::save_html(page, file = output_file)
cat("Wrote HTML to:", normalizePath(output_file), "\n")
cat("PNG images in:", png_dir, "\n")


print("Print the html file as pdf (Optional)")
