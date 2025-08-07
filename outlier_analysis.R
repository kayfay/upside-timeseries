# Outlier Analysis - Highlighting Specific Outlier
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
required_packages <- c("readxl", "forecast", "tseries", "ggplot2", "dplyr", "lubridate")
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
  
  # Data quality checks
  cat("Missing dates:", sum(is.na(clean_data$date)), "\n")
  cat("Missing sales:", sum(is.na(clean_data$sales)), "\n")
  
  if (any(clean_data$sales < 0, na.rm = TRUE)) {
    cat("⚠ Warning: Found negative sales values\n")
  }
  
  cat("Cleaned data dimensions:", dim(clean_data), "\n")
  cat("Date range:", as.character(min(clean_data$date)), "to", as.character(max(clean_data$date)), "\n")
  cat("Sales range:", min(clean_data$sales, na.rm = TRUE), "to", max(clean_data$sales, na.rm = TRUE), "\n")
  
  return(clean_data)
}

# Function to identify and highlight outliers
identify_outliers <- function(clean_data) {
  cat("=== OUTLIER IDENTIFICATION ===\n")
  
  # Find the specific outlier value
  target_outlier <- 69127.86
  outlier_rows <- which(abs(clean_data$sales - target_outlier) < 0.01)  # Allow for small rounding differences
  
  if (length(outlier_rows) > 0) {
    cat("✓ Found target outlier value:", target_outlier, "\n")
    cat("Date of outlier:", as.character(clean_data$date[outlier_rows[1]]), "\n")
    cat("Row index:", outlier_rows[1], "\n")
    
    # Get context (before and after)
    context_start <- max(1, outlier_rows[1] - 5)
    context_end <- min(nrow(clean_data), outlier_rows[1] + 5)
    
    cat("\nContext around outlier (5 weeks before and after):\n")
    context_data <- clean_data[context_start:context_end, ]
    print(context_data)
    
    return(list(
      outlier_date = clean_data$date[outlier_rows[1]],
      outlier_value = clean_data$sales[outlier_rows[1]],
      outlier_index = outlier_rows[1],
      context_data = context_data
    ))
  } else {
    cat("✗ Target outlier value", target_outlier, "not found\n")
    cat("Checking for similar values...\n")
    
    # Find closest values
    differences <- abs(clean_data$sales - target_outlier)
    closest_idx <- which.min(differences)
    closest_value <- clean_data$sales[closest_idx]
    closest_date <- clean_data$date[closest_idx]
    
    cat("Closest value found:", closest_value, "on", as.character(closest_date), "\n")
    cat("Difference:", abs(closest_value - target_outlier), "\n")
    
    return(list(
      outlier_date = closest_date,
      outlier_value = closest_value,
      outlier_index = closest_idx,
      context_data = clean_data[max(1, closest_idx-5):min(nrow(clean_data), closest_idx+5), ]
    ))
  }
}

# Function to create outlier visualization
create_outlier_plots <- function(clean_data, outlier_info) {
  cat("=== CREATING OUTLIER VISUALIZATIONS ===\n")
  
  # 1. Time series plot with highlighted outlier
  par(mfrow = c(2, 2))
  
  # Main time series plot
  plot(clean_data$date, clean_data$sales, 
       main = "Sales Time Series with Outlier Highlighted",
       xlab = "Date", ylab = "Sales", 
       type = "l", col = "blue", lwd = 1)
  
  # Highlight the outlier
  points(outlier_info$outlier_date, outlier_info$outlier_value, 
         col = "red", pch = 19, cex = 2)
  
  # Add annotation
  text(outlier_info$outlier_date, outlier_info$outlier_value, 
       paste("Outlier:", round(outlier_info$outlier_value, 2)), 
       pos = 3, col = "red", cex = 0.8)
  
  # 2. Boxplot to show outlier position
  boxplot(clean_data$sales, main = "Sales Distribution with Outlier",
          ylab = "Sales", col = "lightblue")
  points(1, outlier_info$outlier_value, col = "red", pch = 19, cex = 1.5)
  text(1, outlier_info$outlier_value, "Outlier", pos = 3, col = "red", cex = 0.8)
  
  # 3. Context plot (zoomed in around outlier)
  context_start <- max(1, outlier_info$outlier_index - 10)
  context_end <- min(nrow(clean_data), outlier_info$outlier_index + 10)
  context_data <- clean_data[context_start:context_end, ]
  
  plot(context_data$date, context_data$sales,
       main = "Context Around Outlier (10 weeks)",
       xlab = "Date", ylab = "Sales",
       type = "l", col = "blue", lwd = 1)
  
  # Highlight outlier in context
  points(outlier_info$outlier_date, outlier_info$outlier_value,
         col = "red", pch = 19, cex = 2)
  
  # Add trend line to show if it's part of a pattern
  abline(lm(sales ~ as.numeric(date), data = context_data), 
         col = "green", lwd = 2, lty = 2)
  
  # 4. Histogram with outlier highlighted
  hist(clean_data$sales, main = "Sales Distribution Histogram",
       xlab = "Sales", col = "lightblue", breaks = 20)
  
  # Add vertical line for outlier
  abline(v = outlier_info$outlier_value, col = "red", lwd = 3)
  text(outlier_info$outlier_value, par("usr")[4] * 0.9, 
       "Outlier", col = "red", cex = 0.8, srt = 90)
  
  par(mfrow = c(1, 1))
  
  # 5. Detailed analysis plot
  cat("\nCreating detailed outlier analysis...\n")
  
  # Calculate statistics
  mean_sales <- mean(clean_data$sales, na.rm = TRUE)
  sd_sales <- sd(clean_data$sales, na.rm = TRUE)
  outlier_z_score <- (outlier_info$outlier_value - mean_sales) / sd_sales
  
  cat("Sales Statistics:\n")
  cat("- Mean:", round(mean_sales, 2), "\n")
  cat("- Standard Deviation:", round(sd_sales, 2), "\n")
  cat("- Outlier Z-Score:", round(outlier_z_score, 2), "\n")
  cat("- Outlier is", round(outlier_z_score, 1), "standard deviations from mean\n")
  
  # Create summary plot
  plot(clean_data$date, clean_data$sales,
       main = paste("Outlier Analysis: ", as.character(outlier_info$outlier_date)),
       xlab = "Date", ylab = "Sales",
       type = "l", col = "blue", lwd = 1)
  
  # Add mean line
  abline(h = mean_sales, col = "green", lwd = 2, lty = 2)
  
  # Add standard deviation bands
  abline(h = mean_sales + sd_sales, col = "orange", lwd = 1, lty = 3)
  abline(h = mean_sales - sd_sales, col = "orange", lwd = 1, lty = 3)
  abline(h = mean_sales + 2*sd_sales, col = "red", lwd = 1, lty = 3)
  abline(h = mean_sales - 2*sd_sales, col = "red", lwd = 1, lty = 3)
  
  # Highlight outlier
  points(outlier_info$outlier_date, outlier_info$outlier_value,
         col = "red", pch = 19, cex = 2)
  
  # Add legend
  legend("topleft", 
         legend = c("Sales", "Mean", "±1 SD", "±2 SD", "Outlier"),
         col = c("blue", "green", "orange", "red", "red"),
         lwd = c(1, 2, 1, 1, NA),
         lty = c(1, 2, 3, 3, NA),
         pch = c(NA, NA, NA, NA, 19),
         cex = 0.8)
  
  # Add annotation
  text(outlier_info$outlier_date, outlier_info$outlier_value,
       paste("Outlier:", round(outlier_info$outlier_value, 0), "\nZ-score:", round(outlier_z_score, 1)),
       pos = 3, col = "red", cex = 0.8)
}

# Function to analyze outlier impact
analyze_outlier_impact <- function(clean_data, outlier_info) {
  cat("=== OUTLIER IMPACT ANALYSIS ===\n")
  
  # Remove outlier and compare statistics
  data_without_outlier <- clean_data[clean_data$sales != outlier_info$outlier_value, ]
  
  cat("Statistics comparison:\n")
  cat("With outlier:\n")
  cat("- Mean:", round(mean(clean_data$sales, na.rm = TRUE), 2), "\n")
  cat("- Median:", round(median(clean_data$sales, na.rm = TRUE), 2), "\n")
  cat("- SD:", round(sd(clean_data$sales, na.rm = TRUE), 2), "\n")
  
  cat("\nWithout outlier:\n")
  cat("- Mean:", round(mean(data_without_outlier$sales, na.rm = TRUE), 2), "\n")
  cat("- Median:", round(median(data_without_outlier$sales, na.rm = TRUE), 2), "\n")
  cat("- SD:", round(sd(data_without_outlier$sales, na.rm = TRUE), 2), "\n")
  
  # Calculate impact
  mean_impact <- mean(clean_data$sales, na.rm = TRUE) - mean(data_without_outlier$sales, na.rm = TRUE)
  sd_impact <- sd(clean_data$sales, na.rm = TRUE) - sd(data_without_outlier$sales, na.rm = TRUE)
  
  cat("\nOutlier impact:\n")
  cat("- Mean difference:", round(mean_impact, 2), "\n")
  cat("- SD difference:", round(sd_impact, 2), "\n")
  cat("- Percentage impact on mean:", round(mean_impact / mean(data_without_outlier$sales, na.rm = TRUE) * 100, 2), "%\n")
  
  # Check if it's the highest value
  if (outlier_info$outlier_value == max(clean_data$sales, na.rm = TRUE)) {
    cat("✓ This is the highest sales value in the dataset\n")
  }
  
  # Check if it's the lowest value
  if (outlier_info$outlier_value == min(clean_data$sales, na.rm = TRUE)) {
    cat("✓ This is the lowest sales value in the dataset\n")
  }
  
  # Find other high values for comparison
  high_values <- clean_data[clean_data$sales > quantile(clean_data$sales, 0.95, na.rm = TRUE), ]
  cat("\nOther high values (top 5%):\n")
  print(high_values[order(high_values$sales, decreasing = TRUE), ])
}

# Main analysis function
run_outlier_analysis <- function() {
  tryCatch({
    cat("=== OUTLIER ANALYSIS FOR VALUE 69127.86 ===\n\n")
    
    # Load and validate data
    sales_data <- safe_read_excel("Copy of Weekly Sales 5_29_23-5_25.xlsx")
    clean_data <- validate_and_clean_data(sales_data)
    
    # Identify the specific outlier
    outlier_info <- identify_outliers(clean_data)
    
    # Create visualizations
    create_outlier_plots(clean_data, outlier_info)
    
    # Analyze impact
    analyze_outlier_impact(clean_data, outlier_info)
    
    # Save results
    cat("=== SAVING RESULTS ===\n")
    saveRDS(list(
      outlier_info = outlier_info,
      clean_data = clean_data
    ), "outlier_analysis.rds")
    
    # Export outlier details
    outlier_df <- data.frame(
      Date = as.character(outlier_info$outlier_date),
      Sales_Value = outlier_info$outlier_value,
      Row_Index = outlier_info$outlier_index,
      stringsAsFactors = FALSE
    )
    write.csv(outlier_df, "outlier_details.csv", row.names = FALSE)
    cat("✓ Outlier details exported to CSV\n")
    
    # Export context data
    write.csv(outlier_info$context_data, "outlier_context.csv", row.names = FALSE)
    cat("✓ Context data exported to CSV\n")
    
    cat("✓ Analysis completed successfully\n")
    
    # Summary
    cat("\n=== OUTLIER SUMMARY ===\n")
    cat("Date:", as.character(outlier_info$outlier_date), "\n")
    cat("Value:", outlier_info$outlier_value, "\n")
    cat("This analysis shows when and how this outlier occurred in your sales data.\n")
    
  }, error = function(e) {
    cat("\n✗ CRITICAL ERROR:", e$message, "\n")
    cat("Please check your data and try again.\n")
  })
}

# Run the outlier analysis
run_outlier_analysis() 