setwd("C:/Users/sandy/Google_workspace/_google_sheets_survey/dep_annual_survey_2024/synthesized_data_using_r/github_bnlearn_full/n774_restart5a")

# Importing packages
library(bnlearn)
library(igraph)
library(ggraph)

# Loading the bn object 
load("bn_structure.RData")

# Converting the bn object to a graphNEL object
# graph_nel <- bnlearn::as.graphnel(bn_structure)

# Converting the graphNEL object to an igraph object
ig <- as.igraph(bn_structure)

# Proceeding with plotting using ggraph

ggraph(ig, layout = 'nicely') + 
  geom_edge_link(aes(label = paste0(from, " -> ", to)),
                 arrow = arrow(length = unit(4, 'mm')), 
                 end_cap = circle(6, 'mm')) +
  geom_node_point(size = 5) + 
  geom_node_text(aes(label = name), repel = TRUE) +
  theme_void()