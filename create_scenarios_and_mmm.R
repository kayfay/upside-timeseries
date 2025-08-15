# Scenario Simulator and MMM (Template)

suppressPackageStartupMessages({
  pkgs <- c("tidyverse")
  for (p in pkgs) if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  lapply(pkgs, function(p) suppressPackageStartupMessages(library(p, character.only = TRUE)))
})

# Simple what-if based on elasticity
simulate_price_change <- function(base_sales, price_change_pct, elasticity = -1.2) {
  # pct change in Q ≈ elasticity * pct change in price
  base_sales * (1 + elasticity * price_change_pct)
}

base_sales <- 50000
scenarios <- tibble::tibble(
  scenario = c("Price -5%","Price -10%","Price +5%","Price +10%"),
  price_change = c(-0.05, -0.10, 0.05, 0.10)
) %>%
  mutate(expected_sales = simulate_price_change(base_sales, price_change))

md <- c(
  "# Scenario Planning & MMM",
  "",
  "## What-if: Price Scenarios",
  sprintf("- Base sales: $%s.", scales::comma(base_sales)),
  paste0("- ", paste0(scenarios$scenario, ": $", scales::comma(round(scenarios$expected_sales)), collapse = "\n- ")),
  "",
  "## MMM",
  "- Template: Fit Bayesian MMM (e.g., using PyMC or Stan via cmdstanr/brms) with adstock and saturation to estimate ROAS and optimize spend.",
  "- This repository focuses on R; for a full MMM, we’ll integrate brms/cmdstanr next.",
  "",
  "## Plain-English Summary",
  "- Scenarios show how sales might change if you adjust price; elasticity converts price changes into expected demand shifts.",
  "- MMM helps split credit across channels and budgets so you spend where it works best."
)
writeLines(md, "SCENARIOS_MMM_REPORT.md")
cat("Created SCENARIOS_MMM_REPORT.md (placeholder content)\n")


