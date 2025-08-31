# setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn_full/n774_restart5a")

# ~~~~~~~~~~~~~~
# Load arcs ----
# ~~~~~~~~~~~~~~

library(dplyr)
library(visNetwork)
library(base)

arcs_df_txt<- read.csv("arcs.txt")
dim(arcs_df_txt)  

# Save bn_structure from .RData
save(bn_structure, file = "bn_structure.RData")
load("bn_structure.RData")  # Don't assign a variable

# Get arcs from bn_structure
arcs_matrix <- bn_structure$arcs
arcs_df_bn <- data.frame(arcs_matrix)
dim(arcs_df_bn)

# Compare the two
identical(arcs_df_txt, arcs_df_bn)

# Or check first few rows
head(arcs_df_txt)
head(arcs_df_bn)

# Choose the bn version
arcs_df <- arcs_df_bn
rm(arcs_df_txt, arcs_df_bn)

# Define nodes ----
nodes <- data.frame(
  id = unique(c(arcs_df$from, arcs_df$to)),
  label = unique(c(arcs_df$from, arcs_df$to))
)

# Define edges ----
edges <- data.frame(
  from = arcs_df$from,
  to = arcs_df$to,
  arrows = "to"
)

# Create network ----
vn <- visNetwork(nodes, edges) %>%
  visOptions(highlightNearest = TRUE) %>%
  visLayout(randomSeed = 123)
vn

# Open Plot, Save the network as screenshot ----
