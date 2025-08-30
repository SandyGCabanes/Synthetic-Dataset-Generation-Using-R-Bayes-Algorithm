# Synthetic Data Generation & Validation Workflow Using R's bnlearn Package and Distribution Plots

## Objective  
Turn sensitive survey responses into **privacy‑safe synthetic datasets** while keeping the statistical patterns intact.  
The goal: allow analysis, sharing, and portfolio demonstration **without exposing any respondent’s real data**.

---

## Action from Results  
- Share the synthetic dataset outputs publicly without any privacy risk.
- Add to workflow for the next wave of surveys in the Data Engineering Pilipinas group.
  
---

## Outputs  
- **Side‑by‑side frequency distribution plots** for every column, comparing original vs synthetic data.  
- **HTML reports** produced for quick visual inspection, can be saved as pdf. No need to open R to see the results.
- [Distribution Plots of Original and Synthetic Data](full_n774.pdf)

---

## Background  
Raw survey data often contains **personally identifiable or sensitive information** (e.g., salary).  
Directly sharing it — even internally — can breach trust or compliance rules.  
This workflow uses a **Bayesian network approach** (`bnlearn` in R) to model relationships between variables, then generates synthetic records that mimic the original dataset’s structure and distributions.  
You can read more about bnlearn here: [bnlearn documentation](https://www.bnlearn.com/documentation/)

---

## Process  
1. **Load & Preprocess**  
   - Read raw survey CSV, already cleaned of identifiers.  
   - Create an `age_grp` factor from numeric age.  
   - Remove non‑modeling columns.  
   - Normalize text encoding and replace blanks with `"CODEASBLANK"`.  
   - Convert all variables to factors for modeling consistency.

2. **Model & Synthesize**  
   - Learn Bayesian network structure via **Hill‑Climbing**. [Bayesian network graph](bn_network_graph.PNG)
   - Fit conditional probability tables.  
   - Generate synthetic datasets with the same number of rows as the originals. 

3. **Audit for Privacy**  
   - Tag datasets as `real` or `synthetic`.  
   - Combine and check for **exact record matches** across all factor combinations.
   - Interventions to further reduce similarity of synthetic data to raw data. (Work in progress.)
   - Export duplication check as csv file.
   - Export both cleaned raw df and synthetic df as csv files for frequency distribution plots.

4. **Frequency Distributions**  
   - Compute per‑variable counts and proportions for both real and synthetic datasets.  
   - Combine into a single table for plotting.
   - Export combined long table of frequencies as csv.

5. **Visualization & Export**  
   - Loop through all variables, generating **side‑by‑side bar plots** (Original vs Synthetic).  
   - Save plots as PNGs and embed in an **HTML report** for easy review.  
 



---
