---

# Synthetic Data Generation & Validation Workflow Using R's bnlearn Package and Distribution Plots

## Objective  
Turn sensitive survey responses into **privacy‑safe synthetic datasets** while keeping the statistical patterns intact.  
The goal: allow analysis, sharing, and portfolio demonstration **without exposing any respondent’s real data**.

---

## Action from Results  
- **Two synthetic datasets** generated: one for respondents **with salary data**, one **without**.  
- **Side‑by‑side frequency distribution plots** for every column, comparing original vs synthetic data.  
- **HTML reports** produced for quick visual inspection — no need to open R to see the results.  
- Ready‑to‑share outputs for stakeholders, hiring managers, or public repos without privacy risk.

---

## Background  
Raw survey data often contains **personally identifiable or sensitive information** (e.g., salary).  
Directly sharing it — even internally — can breach trust or compliance rules.  
This workflow uses a **Bayesian network approach** (`bnlearn` in R) to model relationships between variables, then generates synthetic records that mimic the original dataset’s structure and distributions.  
By splitting the dataset into **salary** and **no‑salary** subsets, we can tailor synthesis and analysis for each case.

---

## Process  
1. **Load & Preprocess**  
   - Read raw survey CSV, already cleaned of identifiers.  
   - Create an `age_grp` factor from numeric age.  
   - Remove non‑modeling columns.  
   - Normalize text encoding and replace blanks with `"CODEASBLANK"`.  
   - Convert all variables to factors for modeling consistency.

2. **Split Dataset**  
   - **Salary subset**: respondents with valid salary entries.  
   - **No‑salary subset**: respondents without salary data. Empty columns deleted to prevent crashing.

3. **Model & Synthesize**  
   - Learn Bayesian network structure via **Hill‑Climbing**.  
   - Fit conditional probability tables.  
   - Generate synthetic datasets with the same number of rows as the originals. (Projection to 1000s in progress.)

4. **Audit for Privacy**  
   - Tag datasets as `real` or `synthetic`.  
   - Combine and check for **exact record matches** across all factor combinations.
   - Interventions to further reduce similarity of synthetic data to raw data. (Work in progress.)

5. **Frequency Distributions**  
   - Compute per‑variable counts and proportions for both real and synthetic datasets.  
   - Combine into a single table for plotting.

6. **Visualization & Export**  
   - Loop through all variables, generating **side‑by‑side bar plots** (Original vs Synthetic).  
   - Save plots as PNGs and embed in an **HTML report** for easy review.  
   - Export CSVs for synthetic datasets and frequency tables.

---

## Outputs  
- **`df_sal.csv` / `df_nosal.csv`** — cleaned, factorized original subsets.  
- **`syn_df_sal.csv` / `syn_df_nosal.csv`** — synthetic datasets.  
- **`freq_combined.csv` / `freq_combined_ns.csv`** — frequency tables for plotting.  
- **`all_plots.html` / `all_plots_ns.html`** — interactive HTML reports with per‑variable distribution comparisons.  
- **PNG plot files** — stored in temp directories during HTML generation.

---
