# Seasonal Peak Analysis - Improved Visualizations
# Business Preparation Tool with Professional Graphics

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
required_packages <- c("readxl", "forecast", "tseries", "ggplot2", "dplyr", "lubridate", "tidyr", "gridExtra", "RColorBrewer")
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
  
  day_stats <- clean_data %>%
    group_by(day_of_week) %>%
    summarise(
      avg_sales = mean(sales, na.rm = TRUE),
      median_sales = median(sales, na.rm = TRUE),
      count = n(),
      .groups = 'drop'
    ) %>%
    arrange(desc(avg_sales))
  
  return(list(
    weekly_stats = weekly_stats,
    monthly_stats = monthly_stats,
    quarterly_stats = quarterly_stats,
    day_stats = day_stats
  ))
}

# Function to identify peak weeks
identify_peak_weeks <- function(clean_data, seasonal_stats) {
  # Calculate overall statistics
  overall_mean <- mean(clean_data$sales, na.rm = TRUE)
  overall_sd <- sd(clean_data$sales, na.rm = TRUE)
  
  # Identify peak weeks (above 1 standard deviation)
  peak_threshold <- overall_mean + overall_sd
  
  # Find all peak weeks
  peak_weeks <- clean_data %>%
    filter(sales >= peak_threshold) %>%
    arrange(desc(sales))
  
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
  
  # Identify consistent peak weeks (appear in multiple years)
  consistent_peaks <- peak_week_patterns %>%
    filter(years_with_peaks >= 2) %>%
    arrange(desc(years_with_peaks), desc(avg_peak_sales))
  
  # Find the highest performing weeks
  top_performing_weeks <- seasonal_stats$weekly_stats %>%
    filter(avg_sales >= overall_mean) %>%
    arrange(desc(avg_sales))
  
  return(list(
    peak_weeks = peak_weeks,
    peak_week_patterns = peak_week_patterns,
    consistent_peaks = consistent_peaks,
    top_performing_weeks = top_performing_weeks,
    peak_threshold = peak_threshold
  ))
}

# Function to create improved heatmap
create_improved_heatmap <- function(clean_data) {
  # Create weekly data for heatmap
  weekly_data <- clean_data %>%
    group_by(year, week_of_year) %>%
    summarise(avg_sales = mean(sales, na.rm = TRUE), .groups = 'drop') %>%
    arrange(year, week_of_year)
  
  # Create a complete grid of weeks and years
  all_years <- unique(weekly_data$year)
  all_weeks <- 1:52
  
  complete_grid <- expand.grid(
    year = all_years,
    week_of_year = all_weeks
  ) %>%
    left_join(weekly_data, by = c("year", "week_of_year")) %>%
    mutate(avg_sales = ifelse(is.na(avg_sales), 0, avg_sales))
  
  # Create heatmap matrix
  heatmap_matrix <- complete_grid %>%
    pivot_wider(names_from = year, values_from = avg_sales) %>%
    arrange(week_of_year)
  
  # Convert to matrix for plotting
  plot_matrix <- as.matrix(heatmap_matrix[, -1])
  rownames(plot_matrix) <- heatmap_matrix$week_of_year
  
  # Create improved heatmap
  png("02_sales_heatmap_improved.png", width = 1200, height = 800, res = 150)
  
  # Set up the plot
  par(mar = c(8, 8, 6, 4))
  
  # Create color palette
  color_palette <- colorRampPalette(c("#FFFFFF", "#FFEDA0", "#FED976", "#FEB24C", "#FD8D3C", "#FC4E2A", "#E31A1C", "#BD0026", "#800026"))(100)
  
  # Create heatmap
  heatmap(plot_matrix,
          main = "Sales Performance Heatmap by Week and Year",
          xlab = "Year",
          ylab = "Week of Year",
          col = color_palette,
          scale = "none",
          margins = c(8, 8),
          cexRow = 1.2,
          cexCol = 1.2,
          cex.main = 2,
          cex.lab = 1.5)
  
  dev.off()
  
  return(plot_matrix)
}

# Function to create enhanced timeline with better labels
create_enhanced_timeline <- function(clean_data, peak_analysis) {
  png("03_peak_weeks_timeline_enhanced.png", width = 1400, height = 800, res = 150)
  
  # Set up the plot with better margins
  par(mar = c(10, 8, 6, 4))
  
  # Create the main plot
  plot(peak_analysis$peak_weeks$date, peak_analysis$peak_weeks$sales,
       main = "Peak Sales Weeks Timeline",
       xlab = "", ylab = "Sales ($)",
       pch = 21, col = "red", bg = "red", cex = 2,
       xaxt = "n", yaxt = "n",
       ylim = c(0, max(clean_data$sales) * 1.1))
  
  # Add regular sales for comparison
  points(clean_data$date, clean_data$sales, 
         pch = 16, col = "lightblue", cex = 0.8, alpha = 0.6)
  
  # Add threshold line
  abline(h = peak_analysis$peak_threshold, col = "red", lty = 2, lwd = 3)
  
  # Create custom x-axis with month labels
  date_range <- range(c(clean_data$date, peak_analysis$peak_weeks$date))
  month_breaks <- seq(as.Date(paste0(format(date_range[1], "%Y-%m"), "-01")),
                      as.Date(paste0(format(date_range[2], "%Y-%m"), "-01")),
                      by = "month")
  
  # Add x-axis with month labels
  axis(1, at = month_breaks, 
       labels = format(month_breaks, "%b %Y"),
       las = 2, cex.axis = 1.2, font = 2)
  
  # Add y-axis with better formatting
  axis(2, at = pretty(clean_data$sales), 
       labels = format(pretty(clean_data$sales), big.mark = ","),
       cex.axis = 1.2, font = 2)
  
  # Add grid lines for better readability
  abline(v = month_breaks, col = "lightgray", lty = 3)
  abline(h = pretty(clean_data$sales), col = "lightgray", lty = 3)
  
  # Add enhanced legend
  legend("topleft", 
         legend = c("Regular Sales", "Peak Weeks", "Peak Threshold"),
         col = c("lightblue", "red", "red"), 
         pch = c(16, 21, NA),
         pt.bg = c(NA, "red", NA),
         lty = c(NA, NA, 2), 
         lwd = c(NA, NA, 3),
         cex = 1.5,
         bg = "white",
         box.col = "black",
         box.lwd = 2)
  
  # Add peak week annotations
  top_peaks <- peak_analysis$peak_weeks %>%
    arrange(desc(sales)) %>%
    head(5)
  
  for (i in 1:nrow(top_peaks)) {
    text(top_peaks$date[i], top_peaks$sales[i] + max(clean_data$sales) * 0.05,
         paste("Week", top_peaks$week_of_year[i], "\n", format(top_peaks$sales[i], big.mark = ",")),
         cex = 1, font = 2, col = "darkred")
  }
  
  dev.off()
}

# Function to create professional calendar visualization
create_professional_calendar <- function(peak_analysis) {
  if (nrow(peak_analysis$consistent_peaks) == 0) {
    cat("No consistent peak weeks found for calendar visualization\n")
    return()
  }
  
  # Prepare calendar data
  calendar_data <- peak_analysis$consistent_peaks %>%
    mutate(
      approx_date = as.Date("2024-01-01") + (week_of_year - 1) * 7,
      month_name = format(approx_date, "%B"),
      month_num = lubridate::month(approx_date),
      day_of_month = lubridate::day(approx_date),
      preparation_start = format(approx_date - 21, "%B %d"),
      sales_formatted = format(round(avg_peak_sales), big.mark = ",")
    ) %>%
    arrange(month_num, day_of_month)
  
  # Create calendar visualization
  png("08_peak_weeks_calendar.png", width = 1600, height = 1200, res = 150)
  
  # Set up the plot
  par(mar = c(2, 2, 4, 2))
  
  # Create a 12-month calendar layout
  months <- month.name
  layout(matrix(1:12, nrow = 3, ncol = 4, byrow = TRUE))
  
  for (month_idx in 1:12) {
    month_name <- months[month_idx]
    month_data <- calendar_data %>% filter(month_num == month_idx)
    
    # Create empty plot for the month
    plot(1, 1, type = "n", 
         xlim = c(1, 31), ylim = c(1, 7),
         main = month_name,
         xlab = "", ylab = "",
         axes = FALSE,
         cex.main = 2, font.main = 2)
    
    # Add day labels
    day_labels <- c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
    for (i in 1:7) {
      text(0.5, i, day_labels[i], cex = 1.2, font = 2, pos = 2)
    }
    
    # Get the first day of the month and number of days
    first_day <- as.Date(paste("2024", month_idx, "01", sep = "-"))
    days_in_month <- lubridate::days_in_month(first_day)
    start_weekday <- lubridate::wday(first_day)
    
    # Draw calendar grid
    for (day in 1:days_in_month) {
      row <- ceiling((day + start_weekday - 1) / 7)
      col <- ((day + start_weekday - 2) %% 7) + 1
      
      # Check if this day has peak week data
      peak_info <- month_data %>% 
        filter(day_of_month == day)
      
      if (nrow(peak_info) > 0) {
        # Draw peak week box
        rect(col - 0.4, row - 0.4, col + 0.4, row + 0.4, 
             col = "red", border = "darkred", lwd = 2)
        text(col, row, paste(day, "\nPEAK", sep = ""), 
             cex = 0.8, font = 2, col = "white")
        
        # Add sales info
        text(col, row - 0.3, paste("$", peak_info$sales_formatted[1]), 
             cex = 0.6, font = 2, col = "white")
      } else {
        # Draw regular day box
        rect(col - 0.4, row - 0.4, col + 0.4, row + 0.4, 
             col = "lightgray", border = "gray")
        text(col, row, day, cex = 0.8)
      }
    }
    
    # Add month summary if there are peak weeks
    if (nrow(month_data) > 0) {
      total_peaks <- nrow(month_data)
      avg_sales <- mean(month_data$avg_peak_sales)
      text(16, 6.5, paste("Peak Weeks:", total_peaks), 
           cex = 1, font = 2, col = "red", pos = 4)
      text(16, 6, paste("Avg Sales: $", format(round(avg_sales), big.mark = ",")), 
           cex = 0.8, font = 2, col = "red", pos = 4)
    }
  }
  
  # Add overall title
  mtext("2024 Peak Sales Weeks Calendar", 
        side = 3, line = -2, outer = TRUE, 
        cex = 2.5, font = 2, col = "darkred")
  
  dev.off()
  
  # Also create a summary table visualization
  png("09_peak_weeks_summary.png", width = 1200, height = 800, res = 150)
  
  par(mar = c(8, 8, 6, 4))
  
  # Create summary table
  summary_data <- calendar_data %>%
    select(Month = month_name, 
           `Peak Week` = week_of_year,
           `Avg Sales` = sales_formatted,
           `Years with Peaks` = years_with_peaks,
           `Preparation Start` = preparation_start)
  
  # Create table visualization
  plot(1, 1, type = "n", 
       xlim = c(0, 6), ylim = c(0, nrow(summary_data) + 2),
       main = "Peak Weeks Summary",
       xlab = "", ylab = "",
       axes = FALSE,
       cex.main = 2, font.main = 2)
  
  # Draw table headers
  headers <- c("Month", "Peak Week", "Avg Sales", "Years", "Prep Start")
  for (i in 1:length(headers)) {
    rect(i-0.5, nrow(summary_data) + 0.5, i+0.5, nrow(summary_data) + 1.5, 
         col = "darkred", border = "black")
    text(i, nrow(summary_data) + 1, headers[i], 
         cex = 1.2, font = 2, col = "white")
  }
  
  # Draw table data
  for (row in 1:nrow(summary_data)) {
    for (col in 1:ncol(summary_data)) {
      rect(col-0.5, row-0.5, col+0.5, row+0.5, 
           col = ifelse(row %% 2 == 0, "lightgray", "white"), 
           border = "gray")
      text(col, row, as.character(summary_data[row, col]), 
           cex = 1, font = 1)
    }
  }
  
  dev.off()
}

# Function to create all improved visualizations
create_improved_visualizations <- function(clean_data, seasonal_stats, peak_analysis) {
  cat("Creating improved visualizations...\n")
  
  # 1. Improved heatmap
  create_improved_heatmap(clean_data)
  
  # 2. Enhanced timeline
  create_enhanced_timeline(clean_data, peak_analysis)
  
  # 3. Professional calendar
  create_professional_calendar(peak_analysis)
  
  # 4. Individual plots (keeping the good ones)
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

# Main analysis function
run_improved_analysis <- function() {
  tryCatch({
    cat("=== IMPROVED SEASONAL PEAK ANALYSIS ===\n\n")
    
    # Load and validate data
    sales_data <- safe_read_excel("Copy of Weekly Sales 5_29_23-5_25.xlsx")
    clean_data <- validate_and_clean_data(sales_data)
    
    # Analyze seasonal patterns
    seasonal_stats <- analyze_seasonal_patterns(clean_data)
    
    # Identify peak weeks
    peak_analysis <- identify_peak_weeks(clean_data, seasonal_stats)
    
    # Create improved visualizations
    create_improved_visualizations(clean_data, seasonal_stats, peak_analysis)
    
    # Save results
    saveRDS(list(
      seasonal_stats = seasonal_stats,
      peak_analysis = peak_analysis,
      clean_data = clean_data
    ), "seasonal_peak_analysis_improved.rds")
    
    # Export peak week details
    peak_weeks_export <- peak_analysis$consistent_peaks %>%
      mutate(
        approx_date = as.Date("2024-01-01") + (week_of_year - 1) * 7,
        month_name = format(approx_date, "%B"),
        preparation_start = format(approx_date - 21, "%B %d")
      )
    
    write.csv(peak_weeks_export, "peak_weeks_calendar_improved.csv", row.names = FALSE)
    
    # Export monthly preparation guide
    monthly_guide <- seasonal_stats$monthly_stats %>%
      mutate(
        month_name = month.name[month],
        preparation_month = month.name[pmax(1, month - 1)],
        is_peak_month = avg_sales > mean(avg_sales)
      )
    
    write.csv(monthly_guide, "monthly_preparation_guide_improved.csv", row.names = FALSE)
    
    # Export all peak weeks for detailed analysis
    write.csv(peak_analysis$peak_weeks, "all_peak_weeks_improved.csv", row.names = FALSE)
    
    cat("✓ Improved analysis completed! Generated 9 PNG images and 3 CSV files.\n")
    cat("✓ New files include:\n")
    cat("  - 02_sales_heatmap_improved.png (cleaner heatmap)\n")
    cat("  - 03_peak_weeks_timeline_enhanced.png (better labels)\n")
    cat("  - 08_peak_weeks_calendar.png (professional calendar)\n")
    cat("  - 09_peak_weeks_summary.png (summary table)\n")
    
  }, error = function(e) {
    cat("\n✗ CRITICAL ERROR:", e$message, "\n")
    cat("Please check your data and try again.\n")
  })
}

# Run the improved analysis
run_improved_analysis() 