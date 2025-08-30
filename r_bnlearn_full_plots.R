# setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn_full/no_blacklist_run")


# ~~~~~~~~~~~~~~~~~
# Load dataset ----
# ~~~~~~~~~~~~~~~~~
library(dplyr)
df_full <- read.csv("df_full.csv")
syn_df_full <- read.csv("syn_df_full.csv")

df_full <- as.data.frame(df_full) %>%
  select(-X) %>%
  mutate(across(everything(), as.factor))
syn_df_full <- as.data.frame(syn_df_full) %>%
  select(-X) %>%
  mutate(across(everything(), as.factor))



# ~~~~~~~~~~~~~~~~~~~~~~~~
# Frequency distributions ----
# ~~~~~~~~~~~~~~~~~~~~~~~~
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

# Apply to both original and synthetic ----
freq_df_full  <- get_freqs(df_full)
freq_syn_df_full  <- get_freqs(syn_df_full)


# ~~~~~~~~~~~~
# ggplot2 ----
# ~~~~~~~~~~~~
# Step-by-step diagnostics

# 1. freq_combined_full ----
library(dplyr)

freq_combined_full <- bind_rows(
  freq_df_full %>%    mutate(dataset = "Original"),
  freq_syn_df_full %>% mutate(dataset = "Synthetic")
)

str(freq_combined_full)   
summary(freq_combined_full)  

# 2. single column first ----

colvals <- names(syn_df_full)
plot_value <- freq_combined_full %>%
  filter (variable == colvals[1]) 

print(plot_value)

# 3. plot of single variable ----
library(ggplot2)

ggplot(plot_value, aes(x = value, y = prop, fill = dataset)) +
  geom_col(position = "dodge") +
  scale_x_discrete( labels = function(x) str_trunc(x, width = 25, side = "right", ellipsis = "…") ) +
  labs(
    title = paste("Distribution of", colvals[1]),
    x     = colvals[1],
    y     = "Proportion",
    fill  = "Dataset"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# 4. loop over colvals[1] ... colvals[length(colvals)] html plots----

library(dplyr)
library(ggplot2)
library(htmltools)   # For html plots
library(stringr)

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
  axis_font_size <- if (max_label_len > 25) 6 else 10
  
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
    tags$img(src = img_file, style = "width:100%; height:auto;")
  )
}

# 5. html plots ----


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

output_file <- "all_plots_full.html"
htmltools::save_html(page, file = output_file)
cat("Wrote HTML to:", normalizePath(output_file), "\n")
cat("PNG images in:", png_dir, "\n")


# Detach html package ----
detach("package:htmltools", unload = TRUE)

print("Print the html file as pdf (Optional)")



