# Seasonal Peak Analysis - Identifying High Sales Weeks
# Business Preparation Tool
# Senior Data Scientist Approach

# Function to safely load packages
safe_load_package <- function(package_name) {
  tryCatch({
    library(package_name, character.only = TRUE)
    cat("✓", package_name, "loaded successfully\n")
    return(TRUE)
  }, error = function(e) {
    cat("✗ Error loading", package_name, ":", e$message, "\n")
    cat("Please run: install.packages('", package_name, "')\n")
    return(FALSE)
  })
}

# Load required libraries
cat("=== LOADING REQUIRED PACKAGES ===\n")
required_packages <- c("readxl", "forecast", "tseries", "ggplot2", "dplyr", "lubridate", "tidyr")
package_status <- sapply(required_packages, safe_load_package)

if (!all(package_status)) {
  stop("Some required packages could not be loaded. Please install missing packages first.")
}

# Function to safely read Excel file
safe_read_excel <- function(file_path) {
  tryCatch({
    # Use the correct absolute path
    correct_path <- "C:/Users/allen/Documents/GitHub/upside-timeseries"
    
    # Try multiple ways to find the file
    possible_paths <- c(
      file.path(correct_path, file_path),
      file_path,
      file.path(getwd(), file_path),
      file.path(dirname(getwd()), file_path)
    )
    
    file_found <- FALSE
    actual_path <- NULL
    
    for (path in possible_paths) {
      if (file.exists(path)) {
        file_found <- TRUE
        actual_path <- path
        cat("✓ Found file at:", path, "\n")
        break
      }
    }
    
    if (!file_found) {
      cat("✗ File not found. Tried these paths:\n")
      for (path in possible_paths) {
        cat("  -", path, "\n")
      }
      stop("File not found: ", file_path)
    }
    
    data <- read_excel(actual_path)
    cat("✓ Excel file loaded successfully\n")
    return(data)
  }, error = function(e) {
    cat("✗ Error reading Excel file:", e$message, "\n")
    stop("Please check if the file exists and is not corrupted")
  })
}

# Function to validate and clean data
validate_and_clean_data <- function(data) {
  cat("=== DATA VALIDATION ===\n")
  
  if (nrow(data) == 0) stop("Data is empty")
  
  cat("Data dimensions:", dim(data), "\n")
  cat("Column names:", paste(names(data), collapse = ", "), "\n")
  
  # Remove rows with all NA values
  all_na_rows <- apply(data, 1, function(x) all(is.na(x)))
  if (any(all_na_rows)) {
    cat("Found", sum(all_na_rows), "rows with all NA values. Removing them...\n")
    data <- data[!all_na_rows, ]
    cat("Data dimensions after removing NA rows:", dim(data), "\n")
  }
  
  # Identify columns by data types
  col_types <- sapply(data, class)
  cat("Column types:", paste(col_types, collapse = ", "), "\n")
  
  # Find date column (POSIXct or Date)
  date_col_idx <- which(sapply(data, function(x) any(class(x) %in% c("POSIXct", "POSIXt", "Date"))))
  if (length(date_col_idx) > 0) {
    date_col <- names(data)[date_col_idx[1]]
    cat("Identified date column:", date_col, "\n")
  } else {
    date_col <- names(data)[grep("date|Date|DATE|week|Week|WEEK|time|Time|TIME", names(data))]
    if (length(date_col) > 0) {
      date_col <- date_col[1]
      cat("Identified date column by name:", date_col, "\n")
    } else {
      date_col <- names(data)[1]
      cat("Using first column as date:", date_col, "\n")
    }
  }
  
  # Find numeric column for sales
  numeric_col_idx <- which(sapply(data, is.numeric))
  if (length(numeric_col_idx) > 0) {
    sales_col <- names(data)[numeric_col_idx[1]]
    cat("Identified numeric sales column:", sales_col, "\n")
  } else {
    sales_col <- names(data)[grep("sales|Sales|SALES|amount|Amount|AMOUNT|revenue|Revenue|REVENUE|value|Value|VALUE|gross|Gross|GROSS", names(data))]
    if (length(sales_col) > 0) {
      sales_col <- sales_col[1]
      cat("Identified sales column by name:", sales_col, "\n")
    } else {
      sales_col <- names(data)[2]
      cat("Using second column as sales:", sales_col, "\n")
    }
  }
  
  # Create clean dataset
  clean_data <- data %>%
    select(date = !!sym(date_col), sales = !!sym(sales_col)) %>%
    filter(!is.na(date) & !is.na(sales)) %>%
    arrange(date)
  
  if (nrow(clean_data) < 10) {
    stop("Insufficient data for time series analysis. Need at least 10 observations.")
  }
  
  # Convert date to proper format
  tryCatch({
    if (inherits(clean_data$date, "POSIXct")) {
      clean_data$date <- as.Date(clean_data$date)
      cat("✓ Converted POSIXct to Date\n")
    } else {
      clean_data$date <- as.Date(clean_data$date)
      cat("✓ Date conversion successful\n")
    }
  }, error = function(e) {
    cat("✗ Error converting dates:", e$message, "\n")
    stop("Date conversion failed")
  })
  
  # Convert sales to numeric
  tryCatch({
    clean_data$sales <- as.numeric(clean_data$sales)
    cat("✓ Sales conversion to numeric successful\n")
  }, error = function(e) {
    cat("✗ Error converting sales to numeric:", e$message, "\n")
    stop("Sales data must be numeric")
  })
  
  # Add week information
  clean_data <- clean_data %>%
    mutate(
      year = lubridate::year(date),
      week_of_year = lubridate::week(date),
      month = lubridate::month(date),
      day_of_week = lubridate::wday(date, label = TRUE),
      quarter = lubridate::quarter(date)
    )
  
  cat("Cleaned data dimensions:", dim(clean_data), "\n")
  cat("Date range:", as.character(min(clean_data$date)), "to", as.character(max(clean_data$date)), "\n")
  cat("Sales range:", min(clean_data$sales, na.rm = TRUE), "to", max(clean_data$sales, na.rm = TRUE), "\n")
  
  return(clean_data)
}

# Function to analyze seasonal patterns
analyze_seasonal_patterns <- function(clean_data) {
  # cat("=== SEASONAL PATTERN ANALYSIS ===\n")
  
  # 1. Weekly pattern analysis
  # cat("1. Weekly Pattern Analysis:\n")
  weekly_stats <- clean_data %>%
    group_by(week_of_year) %>%
    summarise(
      avg_sales = mean(sales, na.rm = TRUE),
      median_sales = median(sales, na.rm = TRUE),
      max_sales = max(sales, na.rm = TRUE),
      min_sales = min(sales, na.rm = TRUE),
      count = n(),
      .groups = 'drop'
    ) %>%
    arrange(desc(avg_sales))
  
  # cat("Top 10 highest average sales weeks:\n")
  # print(head(weekly_stats, 10))
  
  # 2. Monthly pattern analysis
  # cat("\n2. Monthly Pattern Analysis:\n")
  monthly_stats <- clean_data %>%
    group_by(month) %>%
    summarise(
      avg_sales = mean(sales, na.rm = TRUE),
      median_sales = median(sales, na.rm = TRUE),
      max_sales = max(sales, na.rm = TRUE),
      min_sales = min(sales, na.rm = TRUE),
      count = n(),
      .groups = 'drop'
    ) %>%
    arrange(desc(avg_sales))
  
  # cat("Monthly sales averages:\n")
  # print(monthly_stats)
  
  # 3. Quarterly pattern analysis
  # cat("\n3. Quarterly Pattern Analysis:\n")
  quarterly_stats <- clean_data %>%
    group_by(quarter) %>%
    summarise(
      avg_sales = mean(sales, na.rm = TRUE),
      median_sales = median(sales, na.rm = TRUE),
      max_sales = max(sales, na.rm = TRUE),
      min_sales = min(sales, na.rm = TRUE),
      count = n(),
      .groups = 'drop'
    ) %>%
    arrange(desc(avg_sales))
  
  # cat("Quarterly sales averages:\n")
  # print(quarterly_stats)
  
  # 4. Day of week pattern (if available)
  # cat("\n4. Day of Week Pattern Analysis:\n")
  day_stats <- clean_data %>%
    group_by(day_of_week) %>%
    summarise(
      avg_sales = mean(sales, na.rm = TRUE),
      median_sales = median(sales, na.rm = TRUE),
      count = n(),
      .groups = 'drop'
    ) %>%
    arrange(desc(avg_sales))
  
  # cat("Day of week sales averages:\n")
  # print(day_stats)
  
  return(list(
    weekly_stats = weekly_stats,
    monthly_stats = monthly_stats,
    quarterly_stats = quarterly_stats,
    day_stats = day_stats
  ))
}

# Function to identify peak weeks
identify_peak_weeks <- function(clean_data, seasonal_stats) {
  # cat("=== PEAK WEEK IDENTIFICATION ===\n")
  
  # Calculate overall statistics
  overall_mean <- mean(clean_data$sales, na.rm = TRUE)
  overall_sd <- sd(clean_data$sales, na.rm = TRUE)
  
  # cat("Overall sales statistics:\n")
  # cat("- Mean:", round(overall_mean, 2), "\n")
  # cat("- Standard Deviation:", round(overall_sd, 2), "\n")
  
  # Identify peak weeks (above 1 standard deviation)
  peak_threshold <- overall_mean + overall_sd
  # cat("- Peak threshold (mean + 1 SD):", round(peak_threshold, 2), "\n")
  
  # Find all peak weeks
  peak_weeks <- clean_data %>%
    filter(sales >= peak_threshold) %>%
    arrange(desc(sales))
  
  # cat("\nFound", nrow(peak_weeks), "peak weeks (sales >= threshold)\n")
  
  # Group peak weeks by week of year to find seasonal patterns
  peak_week_patterns <- peak_weeks %>%
    group_by(week_of_year) %>%
    summarise(
      peak_count = n(),
      avg_peak_sales = mean(sales, na.rm = TRUE),
      max_peak_sales = max(sales, na.rm = TRUE),
      years_with_peaks = n_distinct(year),
      .groups = 'drop'
    ) %>%
    arrange(desc(peak_count))
  
  # cat("\nPeak week patterns (weeks with highest frequency of peaks):\n")
  # print(head(peak_week_patterns, 10))
  
  # Identify consistent peak weeks (appear in multiple years)
  consistent_peaks <- peak_week_patterns %>%
    filter(years_with_peaks >= 2) %>%
    arrange(desc(years_with_peaks), desc(avg_peak_sales))
  
  # cat("\nConsistent peak weeks (appear in 2+ years):\n")
  # print(consistent_peaks)
  
  # Find the highest performing weeks
  top_performing_weeks <- seasonal_stats$weekly_stats %>%
    filter(avg_sales >= overall_mean) %>%
    arrange(desc(avg_sales))
  
  # cat("\nTop performing weeks (above average):\n")
  # print(head(top_performing_weeks, 15))
  
  return(list(
    peak_weeks = peak_weeks,
    peak_week_patterns = peak_week_patterns,
    consistent_peaks = consistent_peaks,
    top_performing_weeks = top_performing_weeks,
    peak_threshold = peak_threshold
  ))
}

# Function to create seasonal visualizations
create_seasonal_plots <- function(clean_data, seasonal_stats, peak_analysis) {
  # cat("=== CREATING SEASONAL VISUALIZATIONS ===\n")
  
  # Save all plots to files
  # 1. Weekly pattern plot
  png("01_weekly_pattern.png", width = 800, height = 600, res = 100)
  par(mfrow = c(2, 2))
  
  # Weekly average sales
  plot(seasonal_stats$weekly_stats$week_of_year, 
       seasonal_stats$weekly_stats$avg_sales,
       main = "Average Sales by Week of Year",
       xlab = "Week of Year", ylab = "Average Sales",
       type = "l", col = "blue", lwd = 2)
  
  # Add threshold line
  abline(h = peak_analysis$peak_threshold, col = "red", lty = 2, lwd = 2)
  legend("topleft", legend = c("Average Sales", "Peak Threshold"), 
         col = c("blue", "red"), lwd = c(2, 2), lty = c(1, 2))
  
  # 2. Monthly pattern plot
  plot(seasonal_stats$monthly_stats$month, 
       seasonal_stats$monthly_stats$avg_sales,
       main = "Average Sales by Month",
       xlab = "Month", ylab = "Average Sales",
       type = "b", col = "green", lwd = 2, pch = 19)
  
  # 3. Peak week frequency
  barplot(peak_analysis$peak_week_patterns$peak_count[1:20],
          names.arg = peak_analysis$peak_week_patterns$week_of_year[1:20],
          main = "Peak Week Frequency (Top 20)",
          xlab = "Week of Year", ylab = "Number of Peak Weeks",
          col = "orange")
  
  # 4. Quarterly pattern
  plot(seasonal_stats$quarterly_stats$quarter, 
       seasonal_stats$quarterly_stats$avg_sales,
       main = "Average Sales by Quarter",
       xlab = "Quarter", ylab = "Average Sales",
       type = "b", col = "purple", lwd = 2, pch = 19)
  
  dev.off()
  
  # 5. Heatmap
  png("02_sales_heatmap.png", width = 800, height = 600, res = 100)
  # Create heatmap-style plot
  weekly_data <- clean_data %>%
    group_by(year, week_of_year) %>%
    summarise(avg_sales = mean(sales, na.rm = TRUE), .groups = 'drop')
  
  # Plot heatmap using base R reshape
  tryCatch({
    # Try using tidyr if available
    weekly_wide <- weekly_data %>%
      pivot_wider(names_from = year, values_from = avg_sales)
    
    if (ncol(weekly_wide) > 2) {
      heatmap_data <- as.matrix(weekly_wide[, -1])
      rownames(heatmap_data) <- weekly_wide$week_of_year
      
      heatmap(heatmap_data, 
              main = "Sales Heatmap by Week and Year",
              xlab = "Year", ylab = "Week of Year",
              col = colorRampPalette(c("white", "yellow", "red"))(100))
    }
  }, error = function(e) {
    # Fallback to base R reshape
    # cat("Using base R reshape for heatmap...\n")
    weekly_wide <- reshape(weekly_data, 
                          idvar = "week_of_year", 
                          timevar = "year", 
                          direction = "wide")
    
    if (ncol(weekly_wide) > 2) {
      heatmap_data <- as.matrix(weekly_wide[, -1])
      rownames(heatmap_data) <- weekly_wide$week_of_year
      
      heatmap(heatmap_data, 
              main = "Sales Heatmap by Week and Year",
              xlab = "Year", ylab = "Week of Year",
              col = colorRampPalette(c("white", "yellow", "red"))(100))
    }
  })
  dev.off()
  
  # 6. Peak week timeline with proper month labels
  png("03_peak_weeks_timeline.png", width = 1000, height = 600, res = 100)
  plot(peak_analysis$peak_weeks$date, peak_analysis$peak_weeks$sales,
       main = "Peak Weeks Timeline",
       xlab = "Date", ylab = "Sales",
       pch = 19, col = "red", cex = 1.2,
       xaxt = "n")  # Suppress default x-axis
  
  # Add regular sales for comparison
  points(clean_data$date, clean_data$sales, 
         pch = 16, col = "blue", cex = 0.5)
  
  # Add threshold line
  abline(h = peak_analysis$peak_threshold, col = "red", lty = 2, lwd = 2)
  
  # Create custom x-axis with month labels
  date_range <- range(c(clean_data$date, peak_analysis$peak_weeks$date))
  month_breaks <- seq(as.Date(paste0(format(date_range[1], "%Y-%m"), "-01")),
                      as.Date(paste0(format(date_range[2], "%Y-%m"), "-01")),
                      by = "month")
  
  # Add x-axis with month labels
  axis(1, at = month_breaks, 
       labels = format(month_breaks, "%b %Y"),
       las = 2, cex.axis = 0.8)
  
  # Add grid lines for better readability
  abline(v = month_breaks, col = "lightgray", lty = 3)
  
  legend("topleft", legend = c("Regular Sales", "Peak Weeks", "Peak Threshold"), 
         col = c("blue", "red", "red"), pch = c(16, 19, NA), 
         lty = c(NA, NA, 2), lwd = c(NA, NA, 2))
  dev.off()
  
  # 7. Individual plots for better quality
  # Weekly pattern only
  png("04_weekly_pattern_only.png", width = 800, height = 600, res = 100)
  plot(seasonal_stats$weekly_stats$week_of_year, 
       seasonal_stats$weekly_stats$avg_sales,
       main = "Average Sales by Week of Year",
       xlab = "Week of Year", ylab = "Average Sales",
       type = "l", col = "blue", lwd = 3)
  abline(h = peak_analysis$peak_threshold, col = "red", lty = 2, lwd = 2)
  legend("topleft", legend = c("Average Sales", "Peak Threshold"), 
         col = c("blue", "red"), lwd = c(3, 2), lty = c(1, 2))
  dev.off()
  
  # Monthly pattern only
  png("05_monthly_pattern_only.png", width = 800, height = 600, res = 100)
  plot(seasonal_stats$monthly_stats$month, 
       seasonal_stats$monthly_stats$avg_sales,
       main = "Average Sales by Month",
       xlab = "Month", ylab = "Average Sales",
       type = "b", col = "green", lwd = 3, pch = 19, cex = 1.5)
  dev.off()
  
  # Peak week frequency only
  png("06_peak_week_frequency.png", width = 800, height = 600, res = 100)
  barplot(peak_analysis$peak_week_patterns$peak_count[1:20],
          names.arg = peak_analysis$peak_week_patterns$week_of_year[1:20],
          main = "Peak Week Frequency (Top 20)",
          xlab = "Week of Year", ylab = "Number of Peak Weeks",
          col = "orange", border = "darkorange")
  dev.off()
  
  # Quarterly pattern only
  png("07_quarterly_pattern_only.png", width = 800, height = 600, res = 100)
  plot(seasonal_stats$quarterly_stats$quarter, 
       seasonal_stats$quarterly_stats$avg_sales,
       main = "Average Sales by Quarter",
       xlab = "Quarter", ylab = "Average Sales",
       type = "b", col = "purple", lwd = 3, pch = 19, cex = 1.5)
  dev.off()
}

# Function to generate business recommendations
generate_business_recommendations <- function(peak_analysis, seasonal_stats) {
  # cat("=== BUSINESS RECOMMENDATIONS ===\n")
  
  # Get top 5 consistent peak weeks
  top_peaks <- head(peak_analysis$consistent_peaks, 5)
  
  # cat("TOP 5 PEAK WEEKS TO PREPARE FOR:\n")
  # cat("================================\n")
  
  # for (i in 1:nrow(top_peaks)) {
  #   week_num <- top_peaks$week_of_year[i]
  #   avg_sales <- top_peaks$avg_peak_sales[i]
  #   years_count <- top_peaks$years_with_peaks[i]
  #   
  #   # Convert week number to approximate date
  #   approx_date <- as.Date("2024-01-01") + (week_num - 1) * 7
  #   
  #   cat(i, ". Week", week_num, "(", format(approx_date, "%B %d"), ")\n")
  #   cat("   - Average peak sales:", round(avg_sales, 0), "\n")
  #   cat("   - Appeared in", years_count, "years\n")
  #   cat("   - Preparation needed: 2-3 weeks before\n\n")
  # }
  
  # Monthly recommendations
  # cat("MONTHLY PREPARATION SCHEDULE:\n")
  # cat("============================\n")
  
  monthly_peaks <- seasonal_stats$monthly_stats %>%
    filter(avg_sales > mean(seasonal_stats$monthly_stats$avg_sales)) %>%
    arrange(desc(avg_sales))
  
  # for (i in 1:nrow(monthly_peaks)) {
  #   month_num <- monthly_peaks$month[i]
  #   month_name <- month.name[month_num]
  #   avg_sales <- monthly_peaks$avg_sales[i]
  #   
  #   cat(month_name, ":\n")
  #   cat("  - Average sales:", round(avg_sales, 0), "\n")
  #   cat("  - Start preparation:", month.name[max(1, month_num - 1)], "\n\n")
  # }
  
  # Quarterly recommendations
  # cat("QUARTERLY PREPARATION SCHEDULE:\n")
  # cat("==============================\n")
  
  # for (i in 1:nrow(seasonal_stats$quarterly_stats)) {
  #   quarter <- seasonal_stats$quarterly_stats$quarter[i]
  #   avg_sales <- seasonal_stats$quarterly_stats$avg_sales[i]
  #   
  #   cat("Q", quarter, ":\n")
  #   cat("  - Average sales:", round(avg_sales, 0), "\n")
  #   cat("  - Peak months:", paste(month.name[((quarter-1)*3+1):(quarter*3)], collapse = ", "), "\n\n")
  # }
  
  # Specific recommendations
  # cat("SPECIFIC BUSINESS ACTIONS:\n")
  # cat("=========================\n")
  
  # Find the highest peak week
  highest_peak_week <- peak_analysis$consistent_peaks$week_of_year[1]
  highest_avg_sales <- peak_analysis$consistent_peaks$avg_peak_sales[1]
  
  # cat("1. HIGHEST PEAK WEEK (Week", highest_peak_week, "):\n")
  # cat("   - Increase inventory by", round(highest_avg_sales * 0.2, 0), "units\n")
  # cat("   - Schedule extra staff 2 weeks before\n")
  # cat("   - Prepare marketing campaigns 3 weeks before\n\n")
  
  # Calculate preparation timeline
  # cat("2. PREPARATION TIMELINE:\n")
  # cat("   - 4 weeks before: Start inventory planning\n")
  # cat("   - 3 weeks before: Begin marketing campaigns\n")
  # cat("   - 2 weeks before: Schedule additional staff\n")
  # cat("   - 1 week before: Final inventory check\n")
  # cat("   - Peak week: Monitor performance closely\n\n")
  
  # Risk assessment
  # cat("3. RISK ASSESSMENT:\n")
  # cat("   - Peak weeks appear", round(mean(peak_analysis$consistent_peaks$years_with_peaks), 1), "times on average\n")
  # cat("   - Consistency level:", round(nrow(peak_analysis$consistent_peaks) / 52 * 100, 1), "% of weeks\n")
  # cat("   - Prepare for", nrow(peak_analysis$consistent_peaks), "peak weeks annually\n")
}

# Main analysis function
run_seasonal_peak_analysis <- function() {
  tryCatch({
    # cat("=== SEASONAL PEAK ANALYSIS FOR BUSINESS PREPARATION ===\n\n")
    
    # Load and validate data
    sales_data <- safe_read_excel("Copy of Weekly Sales 5_29_23-5_25.xlsx")
    clean_data <- validate_and_clean_data(sales_data)
    
    # Analyze seasonal patterns
    seasonal_stats <- analyze_seasonal_patterns(clean_data)
    
    # Identify peak weeks
    peak_analysis <- identify_peak_weeks(clean_data, seasonal_stats)
    
    # Create visualizations and save all images
    create_seasonal_plots(clean_data, seasonal_stats, peak_analysis)
    
    # Generate business recommendations (commented out text output)
    generate_business_recommendations(peak_analysis, seasonal_stats)
    
    # Save results
    # cat("=== SAVING RESULTS ===\n")
    saveRDS(list(
      seasonal_stats = seasonal_stats,
      peak_analysis = peak_analysis,
      clean_data = clean_data
    ), "seasonal_peak_analysis.rds")
    
    # Export peak week details
    peak_weeks_export <- peak_analysis$consistent_peaks %>%
      mutate(
        approx_date = as.Date("2024-01-01") + (week_of_year - 1) * 7,
        month_name = format(approx_date, "%B"),
        preparation_start = format(approx_date - 21, "%B %d")
      )
    
    write.csv(peak_weeks_export, "peak_weeks_calendar.csv", row.names = FALSE)
    # cat("✓ Peak weeks calendar exported to CSV\n")
    
    # Export monthly preparation guide
    monthly_guide <- seasonal_stats$monthly_stats %>%
      mutate(
        month_name = month.name[month],
        preparation_month = month.name[pmax(1, month - 1)],
        is_peak_month = avg_sales > mean(avg_sales)
      )
    
    write.csv(monthly_guide, "monthly_preparation_guide.csv", row.names = FALSE)
    # cat("✓ Monthly preparation guide exported to CSV\n")
    
    # Export all peak weeks for detailed analysis
    write.csv(peak_analysis$peak_weeks, "all_peak_weeks.csv", row.names = FALSE)
    # cat("✓ All peak weeks exported to CSV\n")
    
    # cat("✓ Analysis completed successfully\n")
    
    # Summary
    # cat("\n=== ANALYSIS SUMMARY ===\n")
    # cat("Identified", nrow(peak_analysis$consistent_peaks), "consistent peak weeks\n")
    # cat("Top peak week: Week", peak_analysis$consistent_peaks$week_of_year[1], "\n")
    # cat("Average peak sales:", round(mean(peak_analysis$consistent_peaks$avg_peak_sales), 0), "\n")
    # cat("Use the exported CSV files for detailed business planning.\n")
    
    cat("✓ Analysis completed! Generated 7 PNG images and 3 CSV files.\n")
    
  }, error = function(e) {
    cat("\n✗ CRITICAL ERROR:", e$message, "\n")
    cat("Please check your data and try again.\n")
  })
}

# Run the seasonal peak analysis
run_seasonal_peak_analysis() 