# Business Summary Driver
# Generates the editorial dashboard using the modular pipeline

# Load modules
source("R/utils.R")
source("R/data.R")
source("R/analysis.R")
source("R/reporting.R")

# Ensure packages
ensure_packages(c("tidyverse", "readxl", "lubridate", "scales", "zoo", "gridExtra", "ggtext", "showtext"))
library(magrittr)

message("Generating Business Summary...")

# 1. Load Data
sales_weekly <- load_sales_data()
if (is.null(sales_weekly)) stop("No data found.")
sales_weekly <- preprocess_data(sales_weekly)

# 2. Basic Analysis for Metrics
ts_data <- ts(sales_weekly$value, frequency = 52)
decomp <- perform_decomposition(ts_data, sales_weekly)
stats <- calculate_diagnostics(ts_data, decomp$residual)

# 3. Calculate Business Metrics
# (Refactoring note: This logic was previously hardcoded strings)
metrics <- list(
  total_weeks = nrow(sales_weekly),
  avg_sales = mean(sales_weekly$value),
  growth_rate = (tail(sales_weekly$value, 1) - head(sales_weekly$value, 1)) / nrow(sales_weekly),
  seasonal_strength = 1 - var(decomp$residual) / var(decomp$seasonal + decomp$residual),
  volatility = sd(sales_weekly$value) / mean(sales_weekly$value),
  is_stationary = stats$adf$p.value < 0.05
)

# 4. Generate Dashboard
generate_business_dashboard(metrics)

# 5. Export Data for Web Frontend
export_dashboard_json(metrics, sales_weekly)

message("Business summary generated: 07_enhanced_business_insights_summary.png")
message("Frontend data exported: dashboard_data.json")
