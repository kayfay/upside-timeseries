# Time Series Decomposition Analysis
# Professional analysis with trend, seasonal, and residual components
# Generates: 03_trend_adjusted_peaks.png

# Load required libraries
library(readxl)
library(dplyr)
library(lubridate)
library(ggplot2)
library(forecast)
library(tidyr)
library(purrr)
library(gridExtra)
library(RColorBrewer)

# Function to perform comprehensive time series decomposition
perform_time_series_decomposition <- function(clean_data) {
  cat("Performing time series decomposition analysis...\n")
  
  # Create time series object
  ts_data <- ts(clean_data$sales, 
                frequency = 52,  # Weekly data
                start = c(year(min(clean_data$date)), 
                         week(min(clean_data$date))))
  
  # Perform decomposition
  decomposition <- decompose(ts_data, type = "additive")
  
  # Extract components
  trend <- as.numeric(decomposition$trend)
  seasonal <- as.numeric(decomposition$seasonal)
  residual <- as.numeric(decomposition$random)
  
  # Create comprehensive results
  decomposition_results <- list(
    original = clean_data$sales,
    trend = trend,
    seasonal = seasonal,
    residual = residual,
    dates = clean_data$date,
    ts_object = ts_data,
    decomposition = decomposition
  )
  
  cat("✓ Time series decomposition completed\n")
  return(decomposition_results)
}

# Function to calculate decomposition statistics
calculate_decomposition_stats <- function(decomp_results) {
  cat("Calculating decomposition statistics...\n")
  
  # Trend analysis
  trend_data <- data.frame(
    date = decomp_results$dates,
    trend = decomp_results$trend
  ) %>% filter(!is.na(trend))
  
  # Linear trend model
  trend_model <- lm(trend ~ as.numeric(date), data = trend_data)
  trend_summary <- summary(trend_model)
  
  # Seasonal strength
  seasonal_variance <- var(decomp_results$seasonal, na.rm = TRUE)
  total_variance <- var(decomp_results$original, na.rm = TRUE)
  seasonal_strength <- seasonal_variance / total_variance
  
  # Residual analysis
  residuals_clean <- decomp_results$residual[!is.na(decomp_results$residual)]
  residual_stats <- list(
    mean = mean(residuals_clean),
    sd = sd(residuals_clean),
    skewness = moments::skewness(residuals_clean),
    kurtosis = moments::kurtosis(residuals_clean)
  )
  
  # Component contributions
  trend_contribution <- abs(mean(decomp_results$trend, na.rm = TRUE))
  seasonal_contribution <- mean(abs(decomp_results$seasonal), na.rm = TRUE)
  residual_contribution <- mean(abs(residuals_clean))
  
  total_contribution <- trend_contribution + seasonal_contribution + residual_contribution
  
  stats <- list(
    trend_model = trend_model,
    trend_summary = trend_summary,
    trend_slope = coef(trend_model)[2],
    trend_r_squared = trend_summary$r.squared,
    seasonal_strength = seasonal_strength,
    residual_stats = residual_stats,
    component_contributions = list(
      trend_pct = trend_contribution / total_contribution * 100,
      seasonal_pct = seasonal_contribution / total_contribution * 100,
      residual_pct = residual_contribution / total_contribution * 100
    )
  )
  
  cat("✓ Decomposition statistics calculated\n")
  return(stats)
}

# Function to create professional decomposition visualization
create_decomposition_visualization <- function(decomp_results, stats) {
  cat("Creating professional decomposition visualization...\n")
  
  # Prepare data for plotting
  plot_data <- data.frame(
    date = decomp_results$dates,
    original = decomp_results$original,
    trend = decomp_results$trend,
    detrended = decomp_results$seasonal + decomp_results$residual
  )
  
  # Create the main plot
  p <- ggplot(plot_data, aes(x = date)) +
    # Original sales (blue dashed)
    geom_line(aes(y = original, color = "Original Sales"), 
              linetype = "dashed", linewidth = 1.2, alpha = 0.8) +
    # Trend component (green solid)
    geom_line(aes(y = trend, color = "Trend Component"), 
              linewidth = 1.5) +
    # Detrended sales (red solid)
    geom_line(aes(y = detrended, color = "Detrended Sales"), 
              linewidth = 1.2) +
    # Color scale
    scale_color_manual(
      values = c(
        "Original Sales" = "#3498db",
        "Trend Component" = "#27ae60", 
        "Detrended Sales" = "#e74c3c"
      ),
      name = "Component"
    ) +
    # Scales
    scale_y_continuous(
      labels = scales::comma,
      breaks = seq(0, 60000, by = 10000),
      limits = c(0, 60000)
    ) +
    scale_x_date(
      date_breaks = "3 months",
      date_labels = "%b %Y"
    ) +
    # Labels and title
    labs(
      title = "Sales Time Series: Original vs Detrended",
      subtitle = paste(
        "Trend: $", format(round(stats$trend_slope * 365), big.mark = ","), "/year | ",
        "Seasonal Strength: ", round(stats$seasonal_strength * 100, 1), "%"
      ),
      x = "Date",
      y = "Sales ($)",
      caption = "Detrended data removes trend bias to reveal true seasonal patterns"
    ) +
    # Theme
    theme_minimal() +
    theme(
      plot.title = element_text(size = 24, face = "bold", color = "#2c3e50", hjust = 0.5),
      plot.subtitle = element_text(size = 16, color = "#6c757d", hjust = 0.5),
      plot.caption = element_text(size = 12, color = "#6c757d", hjust = 0.5),
      axis.text = element_text(size = 12, color = "#495057"),
      axis.title = element_text(size = 14, face = "bold", color = "#2c3e50"),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.title = element_text(size = 12, face = "bold", color = "#2c3e50"),
      legend.text = element_text(size = 11, color = "#495057"),
      legend.position = "bottom",
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      panel.grid.major = element_line(color = "#ecf0f1", linewidth = 0.5),
      panel.grid.minor = element_blank()
    )
  
  # Save the plot
  ggsave("03_trend_adjusted_peaks.png", p, 
         width = 16, height = 10, dpi = 300, bg = "white")
  
  cat("✓ Created decomposition visualization: 03_trend_adjusted_peaks.png\n")
  return(p)
}

# Function to generate comprehensive analysis report
generate_decomposition_report <- function(decomp_results, stats) {
  cat("Generating comprehensive analysis report...\n")
  
  # Calculate key metrics
  trend_growth <- stats$trend_slope * 365  # Annual growth
  trend_growth_pct <- (trend_growth / mean(decomp_results$original, na.rm = TRUE)) * 100
  
  # Peak and trough analysis
  seasonal_data <- data.frame(
    date = decomp_results$dates,
    seasonal = decomp_results$seasonal
  ) %>% filter(!is.na(seasonal))
  
  seasonal_data$month <- month(seasonal_data$date)
  seasonal_data$quarter <- quarter(seasonal_data$date)
  
  # Monthly seasonal patterns
  monthly_patterns <- seasonal_data %>%
    group_by(month) %>%
    summarise(
      avg_seasonal = mean(seasonal, na.rm = TRUE),
      seasonal_sd = sd(seasonal, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    arrange(desc(avg_seasonal))
  
  # Quarterly patterns
  quarterly_patterns <- seasonal_data %>%
    group_by(quarter) %>%
    summarise(
      avg_seasonal = mean(seasonal, na.rm = TRUE),
      .groups = 'drop'
    )
  
  # Create report data
  report_data <- list(
    trend_analysis = list(
      annual_growth = trend_growth,
      annual_growth_pct = trend_growth_pct,
      r_squared = stats$trend_r_squared,
      slope = stats$trend_slope
    ),
    seasonal_analysis = list(
      strength = stats$seasonal_strength,
      monthly_patterns = monthly_patterns,
      quarterly_patterns = quarterly_patterns
    ),
    residual_analysis = stats$residual_stats,
    component_contributions = stats$component_contributions
  )
  
  # Save report data
  saveRDS(report_data, "time_series_decomposition_report.rds")
  
  cat("✓ Generated comprehensive analysis report\n")
  return(report_data)
}

# Function to create additional diagnostic plots
create_diagnostic_plots <- function(decomp_results, stats) {
  cat("Creating diagnostic plots...\n")
  
  # Residual analysis plot
  residuals_clean <- decomp_results$residual[!is.na(decomp_results$residual)]
  dates_clean <- decomp_results$dates[!is.na(decomp_results$residual)]
  
  # Residuals over time
  p1 <- ggplot(data.frame(date = dates_clean, residual = residuals_clean), 
               aes(x = date, y = residual)) +
    geom_line(color = "#3498db", alpha = 0.7) +
    geom_hline(yintercept = 0, color = "#e74c3c", linetype = "dashed") +
    labs(title = "Residuals Over Time", x = "Date", y = "Residual") +
    theme_minimal()
  
  # Residual histogram
  p2 <- ggplot(data.frame(residual = residuals_clean), aes(x = residual)) +
    geom_histogram(fill = "#3498db", alpha = 0.7, bins = 30) +
    labs(title = "Residual Distribution", x = "Residual", y = "Frequency") +
    theme_minimal()
  
  # Q-Q plot
  p3 <- ggplot(data.frame(residual = residuals_clean), aes(sample = residual)) +
    stat_qq(color = "#3498db") +
    stat_qq_line(color = "#e74c3c") +
    labs(title = "Q-Q Plot of Residuals", x = "Theoretical Quantiles", y = "Sample Quantiles") +
    theme_minimal()
  
  # Combine plots
  combined_plot <- grid.arrange(p1, p2, p3, ncol = 3)
  
  # Save diagnostic plots
  ggsave("03_decomposition_diagnostics.png", combined_plot, 
         width = 18, height = 6, dpi = 300, bg = "white")
  
  cat("✓ Created diagnostic plots: 03_decomposition_diagnostics.png\n")
}

# Main analysis function
run_complete_decomposition_analysis <- function() {
  cat("=== TIME SERIES DECOMPOSITION ANALYSIS ===\n\n")
  
  # Load existing data
  if (file.exists("seasonal_peak_analysis.rds")) {
    analysis_data <- readRDS("seasonal_peak_analysis.rds")
    clean_data <- analysis_data$clean_data
    cat("✓ Loaded existing analysis data\n")
  } else {
    cat("No existing analysis found. Please run the main analysis first.\n")
    stop("Run seasonal_peak_analysis.R first")
  }
  
  # Perform decomposition
  decomp_results <- perform_time_series_decomposition(clean_data)
  
  # Calculate statistics
  stats <- calculate_decomposition_stats(decomp_results)
  
  # Create visualization
  main_plot <- create_decomposition_visualization(decomp_results, stats)
  
  # Generate report
  report_data <- generate_decomposition_report(decomp_results, stats)
  
  # Create diagnostic plots
  create_diagnostic_plots(decomp_results, stats)
  
  # Print summary
  cat("\n=== DECOMPOSITION ANALYSIS SUMMARY ===\n")
  cat("✓ Annual Growth Rate: $", format(round(stats$trend_slope * 365), big.mark = ","), "\n")
  cat("✓ Seasonal Strength: ", round(stats$seasonal_strength * 100, 1), "%\n")
  cat("✓ Trend R-squared: ", round(stats$trend_r_squared, 3), "\n")
  cat("✓ Component Contributions:\n")
  cat("  - Trend: ", round(stats$component_contributions$trend_pct, 1), "%\n")
  cat("  - Seasonal: ", round(stats$component_contributions$seasonal_pct, 1), "%\n")
  cat("  - Residual: ", round(stats$component_contributions$residual_pct, 1), "%\n")
  
  cat("\n=== FILES GENERATED ===\n")
  cat("✓ 03_trend_adjusted_peaks.png (Main decomposition visualization)\n")
  cat("✓ 03_decomposition_diagnostics.png (Diagnostic plots)\n")
  cat("✓ time_series_decomposition_report.rds (Analysis report data)\n")
  
  cat("\n=== ANALYSIS COMPLETED ===\n")
  
  return(list(
    decomposition = decomp_results,
    statistics = stats,
    report = report_data,
    plot = main_plot
  ))
}

# Run the analysis if script is executed directly
if (!interactive()) {
  results <- run_complete_decomposition_analysis()
} 