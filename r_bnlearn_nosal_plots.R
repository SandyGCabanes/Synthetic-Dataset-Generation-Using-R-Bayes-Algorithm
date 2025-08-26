# setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn_nosalary_split")


# ~~~~~~~~~~~~~~~~~
# Load dataset ----
# ~~~~~~~~~~~~~~~~~
library(dplyr)
df_nosal <- read.csv("df_nosal.csv")
syn_df_nosal <- read.csv("syn_df_nosal.csv")

df_nosal <- as.data.frame(df_nosal) %>%
  select(-X) %>%
  mutate(across(everything(), as.factor))
syn_df_nosal <- as.data.frame(syn_df_nosal) %>%
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

# Apply to both ----
freq_dfnosal  <- get_freqs(df_nosal)
freq_syndfnosal  <- get_freqs(syn_df_nosal)


# ~~~~~~~~~~~~
# ggplot2 ----
# ~~~~~~~~~~~~
# Step-by-step diagnostics

# 1. freq_combined_ns ----
library(dplyr)

freq_combined_ns <- bind_rows(
  freq_dfnosal %>%    mutate(dataset = "Original"),
  freq_syndfnosal %>% mutate(dataset = "Synthetic")
)

str(freq_combined_ns)   
summary(freq_combined_ns)

# 2. single column first ----

colvals <- names(syn_df_nosal)
plot_value <- freq_combined_ns %>%
  filter (variable == colvals[1]) 

print(plot_value)

# 3. plot of single variable ----
library(ggplot2)

ggplot(plot_value, aes(x = value, y = prop, fill = dataset)) +
  geom_col(position = "dodge") +
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
library(htmltools)

present_vars <- unique(freq_combined_ns$variable)
idx <- which(colvals %in% present_vars)

png_dir <- file.path(tempdir(), "plots_dir_ns")
if (!dir.exists(png_dir)) dir.create(png_dir, recursive = TRUE)

plot_divs <- list(
  tags$h1("All Variable Distributions"),
  tags$p(sprintf("Total variables plotted: %d", length(idx)))
)

for (i in idx) {
  plot_value <- freq_combined_ns %>%
    filter(variable == colvals[i])
  
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
  
  img_file <- file.path(png_dir, paste0("plot_ns_", i, ".png"))
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

output_file <- "all_plots_ns.html"
htmltools::save_html(page, file = output_file)
cat("Wrote HTML to:", normalizePath(output_file), "\n")
cat("PNG images in:", png_dir, "\n")

# Check memory usage ----

objs <- ls(envir = .GlobalEnv)
sizes <- sapply(objs, function(x) object.size(get(x)))
sizes_df <- data.frame(
  object = objs,
  size_MB = round(sizes / 1024^2, 2)
)
sizes_df[order(-sizes_df$size_MB), ]

sessionInfo()$otherPkgs

# Detach html package ----
detach("package:htmltools", unload = TRUE)



