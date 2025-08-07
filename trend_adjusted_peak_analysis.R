# Trend-Adjusted Peak Week Analysis
# Addresses the issue of upward trends masking true seasonal patterns

# Load required libraries
library(readxl)
library(dplyr)
library(lubridate)
library(forecast)
library(tseries)
library(ggplot2)
library(tidyr)
library(purrr)
library(gridExtra)
library(RColorBrewer)

# Function to safely read Excel file
safe_read_excel <- function(file_path) {
  possible_paths <- c(
    file_path,
    "Copy of Weekly Sales 5_29_23-5_25.xlsx",
    file.path(getwd(), "Copy of Weekly Sales 5_29_23-5_25.xlsx"),
    file.path(dirname(getwd()), "Copy of Weekly Sales 5_29_23-5_25.xlsx")
  )
  
  for (path in possible_paths) {
    if (file.exists(path)) {
      cat("✓ Found file at:", path, "\n")
      return(read_excel(path))
    }
  }
  stop("Excel file not found in any expected location")
}

# Function to perform trend-adjusted peak analysis
perform_trend_adjusted_analysis <- function(ts_data) {
  cat("=== TREND-ADJUSTED PEAK WEEK ANALYSIS ===\n")
  cat("Addressing upward trend bias in seasonal pattern identification\n\n")
  
  # 1. Perform seasonal decomposition
  cat("1. Performing seasonal decomposition...\n")
  decomp <- stl(ts_data, s.window = "periodic")
  
  # Extract components
  seasonal_component <- decomp$time.series[, "seasonal"]
  trend_component <- decomp$time.series[, "trend"]
  remainder_component <- decomp$time.series[, "remainder"]
  
  # 2. Calculate trend characteristics
  cat("2. Analyzing trend characteristics...\n")
  trend_slope <- coef(lm(trend_component ~ seq_along(trend_component)))[2]
  trend_strength <- var(trend_component, na.rm = TRUE) / 
                   (var(trend_component, na.rm = TRUE) + var(remainder_component, na.rm = TRUE))
  
  cat("   Trend slope:", round(trend_slope, 2), "\n")
  cat("   Trend strength:", round(trend_strength, 3), "\n")
  
  if (trend_slope > 0) {
    cat("   ⚠️  UPWARD TREND DETECTED - This may bias peak identification!\n")
  }
  
  # 3. Create detrended series
  cat("3. Creating detrended series...\n")
  detrended_series <- ts_data - trend_component
  
  # 4. Identify peaks in both original and detrended data
  cat("4. Identifying peaks in original vs detrended data...\n")
  
  # Function to find peaks
  find_peaks <- function(series, threshold_percentile = 90) {
    threshold <- quantile(series, threshold_percentile/100, na.rm = TRUE)
    peaks <- which(series > threshold)
    return(data.frame(
      position = peaks,
      value = series[peaks],
      date = time(series)[peaks]
    ))
  }
  
  # Find peaks in original data
  original_peaks <- find_peaks(ts_data)
  detrended_peaks <- find_peaks(detrended_series)
  
  cat("   Original data peaks:", nrow(original_peaks), "\n")
  cat("   Detrended data peaks:", nrow(detrended_peaks), "\n")
  
  # 5. Compare peak distributions
  cat("5. Comparing peak distributions...\n")
  
  # Convert to dates for analysis
  original_peaks$date_obj <- as.Date(original_peaks$date)
  detrended_peaks$date_obj <- as.Date(detrended_peaks$date)
  
  # Monthly distribution
  original_monthly <- table(month(original_peaks$date_obj))
  detrended_monthly <- table(month(detrended_peaks$date_obj))
  
  cat("   Original peaks by month:\n")
  print(original_monthly)
  cat("   Detrended peaks by month:\n")
  print(detrended_monthly)
  
  # 6. Create comparison visualizations
  cat("6. Creating comparison visualizations...\n")
  
  # Plot 1: Original vs Detrended Series
  png("30_trend_adjusted_comparison.png", width = 1200, height = 800, res = 150)
  par(mfrow = c(2, 2))
  
  # Original series with peaks
  plot(ts_data, main = "Original Sales Data with Peaks", 
       ylab = "Sales", xlab = "Time", col = "blue")
  points(original_peaks$date, original_peaks$value, 
         col = "red", pch = 19, cex = 1.2)
  legend("topleft", legend = c("Sales", "Peaks"), 
         col = c("blue", "red"), pch = c(NA, 19), lty = c(1, NA))
  
  # Detrended series with peaks
  plot(detrended_series, main = "Detrended Sales Data with Peaks", 
       ylab = "Detrended Sales", xlab = "Time", col = "green")
  points(detrended_peaks$date, detrended_peaks$value, 
         col = "red", pch = 19, cex = 1.2)
  legend("topleft", legend = c("Detrended", "Peaks"), 
         col = c("green", "red"), pch = c(NA, 19), lty = c(1, NA))
  
  # Trend component
  plot(trend_component, main = "Trend Component", 
       ylab = "Trend", xlab = "Time", col = "purple", type = "l")
  
  # Monthly peak comparison
  months <- 1:12
  month_names <- month.abb
  original_counts <- as.numeric(original_monthly[match(months, names(original_monthly))])
  detrended_counts <- as.numeric(detrended_monthly[match(months, names(detrended_monthly))])
  original_counts[is.na(original_counts)] <- 0
  detrended_counts[is.na(detrended_counts)] <- 0
  
  barplot(rbind(original_counts, detrended_counts), 
          beside = TRUE, names.arg = month_names,
          main = "Peak Distribution by Month",
          ylab = "Number of Peaks", col = c("blue", "green"))
  legend("topleft", legend = c("Original", "Detrended"), 
         fill = c("blue", "green"))
  
  dev.off()
  
  # 7. Create detailed peak analysis
  cat("7. Creating detailed peak analysis...\n")
  
  # Combine peak information
  peak_comparison <- data.frame(
    date = c(original_peaks$date_obj, detrended_peaks$date_obj),
    value = c(original_peaks$value, detrended_peaks$value),
    type = c(rep("Original", nrow(original_peaks)), 
             rep("Detrended", nrow(detrended_peaks))),
    month = c(month(original_peaks$date_obj), month(detrended_peaks$date_obj)),
    year = c(year(original_peaks$date_obj), year(detrended_peaks$date_obj))
  )
  
  # Save peak comparison
  write.csv(peak_comparison, "trend_adjusted_peak_comparison.csv", row.names = FALSE)
  
  # 8. Create business insights
  cat("8. Generating business insights...\n")
  
  # Find months with most detrended peaks (true seasonal patterns)
  detrended_monthly_analysis <- data.frame(
    month = month_names,
    peak_count = detrended_counts,
    original_count = original_counts,
    difference = detrended_counts - original_counts
  )
  
  # Identify true seasonal peaks
  true_seasonal_months <- detrended_monthly_analysis$month[detrended_monthly_analysis$peak_count > 0]
  
  cat("   True seasonal peak months (detrended):", paste(true_seasonal_months, collapse = ", "), "\n")
  
  # Create business recommendations
  recommendations <- data.frame(
    insight = c(
      "Trend Bias Impact",
      "True Seasonal Peaks",
      "Business Planning",
      "Inventory Strategy"
    ),
    description = c(
      paste("Upward trend of", round(trend_slope, 2), "units/week may have masked early seasonal patterns"),
      paste("Focus on months:", paste(true_seasonal_months, collapse = ", ")),
      "Use detrended analysis for seasonal planning, original data for growth projections",
      "Prepare inventory for true seasonal peaks, not just recent high-sales periods"
    )
  )
  
  write.csv(recommendations, "trend_adjusted_recommendations.csv", row.names = FALSE)
  
  # 9. Create final visualization
  cat("9. Creating final trend-adjusted calendar...\n")
  
  png("31_trend_adjusted_calendar.png", width = 1400, height = 1000, res = 150)
  
  # Create calendar-style visualization
  par(mfrow = c(1, 2))
  
  # Original peaks calendar
  plot(1, 1, type = "n", xlim = c(0, 12), ylim = c(0, 5), 
       main = "Original Data Peak Distribution", 
       xlab = "Month", ylab = "Year", axes = FALSE)
  axis(1, at = 1:12, labels = month_names)
  axis(2, at = 1:4, labels = c("2021", "2022", "2023", "2024"))
  
  # Plot original peaks
  for (i in 1:nrow(original_peaks)) {
    x <- month(original_peaks$date_obj[i])
    y <- year(original_peaks$date_obj[i]) - 2020
    points(x, y, pch = 19, col = "red", cex = 2)
  }
  grid()
  
  # Detrended peaks calendar
  plot(1, 1, type = "n", xlim = c(0, 12), ylim = c(0, 5), 
       main = "Detrended Data Peak Distribution", 
       xlab = "Month", ylab = "Year", axes = FALSE)
  axis(1, at = 1:12, labels = month_names)
  axis(2, at = 1:4, labels = c("2021", "2022", "2023", "2024"))
  
  # Plot detrended peaks
  for (i in 1:nrow(detrended_peaks)) {
    x <- month(detrended_peaks$date_obj[i])
    y <- year(detrended_peaks$date_obj[i]) - 2020
    points(x, y, pch = 19, col = "green", cex = 2)
  }
  grid()
  
  dev.off()
  
  # 10. Summary report
  cat("\n=== TREND-ADJUSTED ANALYSIS SUMMARY ===\n")
  cat("Trend slope:", round(trend_slope, 2), "units/week\n")
  cat("Trend strength:", round(trend_strength, 3), "\n")
  cat("Original peaks found:", nrow(original_peaks), "\n")
  cat("Detrended peaks found:", nrow(detrended_peaks), "\n")
  cat("True seasonal months:", paste(true_seasonal_months, collapse = ", "), "\n")
  
  if (trend_slope > 0) {
    cat("\n⚠️  RECOMMENDATION: Use detrended analysis for seasonal planning!\n")
    cat("   The upward trend may have biased peak identification toward recent periods.\n")
  }
  
  return(list(
    trend_slope = trend_slope,
    trend_strength = trend_strength,
    original_peaks = original_peaks,
    detrended_peaks = detrended_peaks,
    true_seasonal_months = true_seasonal_months,
    peak_comparison = peak_comparison,
    recommendations = recommendations
  ))
}

# Main execution
cat("=== TREND-ADJUSTED PEAK WEEK ANALYSIS ===\n")
cat("Addressing upward trend bias in seasonal pattern identification\n\n")

# Read data
cat("Loading sales data...\n")
sales_data <- safe_read_excel("Copy of Weekly Sales 5_29_23-5_25.xlsx")

# Clean and prepare data
cat("Cleaning and preparing data...\n")
clean_data <- sales_data %>%
  filter(!is.na(`Weekly Gross Sales`)) %>%
  mutate(
    date = as.Date(`...1`),
    sales = as.numeric(`Weekly Gross Sales`)
  ) %>%
  select(date, sales) %>%
  arrange(date)

# Convert to time series
ts_data <- ts(clean_data$sales, frequency = 52, start = c(year(min(clean_data$date)), 1))

# Perform trend-adjusted analysis
results <- perform_trend_adjusted_analysis(ts_data)

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Generated files:\n")
cat("- 30_trend_adjusted_comparison.png (Original vs Detrended comparison)\n")
cat("- 31_trend_adjusted_calendar.png (Peak distribution calendars)\n")
cat("- trend_adjusted_peak_comparison.csv (Detailed peak data)\n")
cat("- trend_adjusted_recommendations.csv (Business recommendations)\n") 