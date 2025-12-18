# Scientific Time Series Analysis - Orchestration Script
# Refactored for modularity and maintainability

# 1. Load Modules
source("R/utils.R")
source("R/data.R")
source("R/analysis.R")
source("R/viz.R")
source("R/reporting.R") # New module for business summary

# 2. Setup
required_packages <- c(
  "tidyverse", "readxl", "lubridate", "scales",
  "zoo", "broom", "forecast", "tseries", "changepoint", "patchwork", "rlang",
  "ggtext", "showtext", "gridExtra" # Added for business summary
)
ensure_packages(required_packages)
library(magrittr)

# 3. Data Loading
message("Loading sales data...")
sales_weekly <- load_sales_data()
if (is.null(sales_weekly)) stop("Failed to load data.")

sales_weekly <- preprocess_data(sales_weekly)

# 4. Audit
audit <- list(
  num_weeks = nrow(sales_weekly),
  start_date = min(sales_weekly$date, na.rm = TRUE),
  end_date = max(sales_weekly$date, na.rm = TRUE),
  missing_values = sum(is.na(sales_weekly$value)),
  num_duplicates = nrow(sales_weekly) - nrow(dplyr::distinct(sales_weekly, date))
)

# 5. Analysis
message("Performing STL decomposition...")
ts_data <- ts(sales_weekly$value, frequency = 52)
decomp_df <- perform_decomposition(ts_data, sales_weekly)

message("Detecting anomalies...")
anomalies_res <- detect_anomalies(decomp_df)

message("Fitting forecast model...")
forecast_res <- fit_forecast_model(ts_data)
model_info <- if (is.list(forecast_res$model)) forecast_res$model$arma else "Simple Benchmark"

message("Calculating diagnostics...")
stats <- calculate_diagnostics(ts_data, decomp_df$residual)

# 6. Visualization & Reporting (Scientific)
message("Generating scientific plots...")
p_tldr <- plot_tldr(decomp_df)
p_forecast <- plot_forecast(decomp_df, forecast_res)

ggsave("09_tldr_science_dashboard.png", p_tldr, width = 12, height = 8, dpi = 300)
ggsave("13_forecast_sarima.png", p_forecast, width = 12, height = 8, dpi = 300)

message("Genering scientific report...")
report_md <- generate_report_markdown(
  audit = audit,
  model_info = paste(model_info, collapse = ", "),
  anomaly_count = length(anomalies_res$anomalies),
  cp_count = length(anomalies_res$change_points),
  stats = stats
)
writeLines(report_md, "SCIENTIFIC_ANALYSIS_REPORT.md")

# 7. Visualization & Reporting (Business)
message("Generating business highlights...")
# Calculate derived metrics for the business report
metrics <- list(
  total_weeks = nrow(sales_weekly),
  avg_sales = mean(sales_weekly$value),
  growth_rate = (tail(sales_weekly$value, 1) - head(sales_weekly$value, 1)) / nrow(sales_weekly), # Simple linear approx
  seasonal_strength = 1 - var(decomp_df$residual) / var(decomp_df$seasonal + decomp_df$residual),
  volatility = sd(sales_weekly$value) / mean(sales_weekly$value),
  is_stationary = stats$adf$p.value < 0.05
)

generate_business_dashboard(metrics)

message("Analysis complete!")
