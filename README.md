# Synthetic Data Generation & Validation Workflow Using R's bnlearn package

## Objective
Create reliable synthetic survey data that protects privacy while maintaining analytical value. R's bnlearn package uses Bayesian

## Action from Results
Leverage tuning reports and interactive dashboards to choose synthesis settings offering the best balance between disclosure risk and data quality. Detect and correct multi-select response inconsistencies to ensure dependable insights and stakeholder confidence.

## Background
Synthetic data lets analysts explore sensitive datasets without exposing real respondents. Multi-select survey responses are especially tricky to replicate, risking inaccurate representation in summaries and visualizations. This workflow combines automated tuning with targeted validation to safeguard both privacy and data fidelity.
This uses an alternative package called bnlearn, whose engine uses Bayesian conditional probabilities. 

## Process
- Use single-select columns subset to construct the model.
- Use 5 out 15 column matching between raw dataset and synthetic dataset.
- If a match is found, insert the multi-select column values from raw to synthetic.
- View the distributions of synthetic vs. raw and evaluate 

## Expected Output
- Synthetic dataset with single-select columns indistinguishable from raw dataset.
- Frequency distributions 

---

Designed for analysts who value transparency, reproducibility, and practical insights—this workflow empowers you to produce synthetic data you can trust.
