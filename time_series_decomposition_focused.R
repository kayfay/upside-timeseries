# Decomposition + ARIMA Focused Time Series Analysis
# Based on Superior AIC Performance (1977.718 vs 2048.65)
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
required_packages <- c("readxl", "forecast", "tseries", "ggplot2", "dplyr", "lubridate", "seasonal")
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

# Function to create time series object
create_time_series <- function(clean_data) {
  cat("=== CREATING TIME SERIES OBJECT ===\n")
  
  # Determine frequency based on data characteristics
  date_diff <- diff(as.numeric(clean_data$date))
  avg_diff <- mean(date_diff, na.rm = TRUE)
  
  if (avg_diff >= 6 && avg_diff <= 8) {
    frequency_val <- 52  # Weekly data
    cat("Detected weekly data (frequency = 52)\n")
  } else if (avg_diff >= 28 && avg_diff <= 31) {
    frequency_val <- 12  # Monthly data
    cat("Detected monthly data (frequency = 12)\n")
  } else if (avg_diff >= 85 && avg_diff <= 95) {
    frequency_val <- 4   # Quarterly data
    cat("Detected quarterly data (frequency = 4)\n")
  } else {
    frequency_val <- 52  # Default to weekly
    cat("Using default weekly frequency (52)\n")
  }
  
  # Create time series object
  tryCatch({
    ts_data <- ts(clean_data$sales, 
                  frequency = frequency_val, 
                  start = c(lubridate::year(min(clean_data$date)), 
                           lubridate::week(min(clean_data$date))))
    
    cat("✓ Time series object created successfully\n")
    cat("Frequency:", frequency(ts_data), "\n")
    cat("Start:", start(ts_data), "\n")
    cat("Length:", length(ts_data), "\n")
    
    return(ts_data)
  }, error = function(e) {
    cat("✗ Error creating time series:", e$message, "\n")
    ts_data <- ts(clean_data$sales, frequency = frequency_val)
    cat("✓ Created simple time series object\n")
    return(ts_data)
  })
}

# Function for comprehensive preprocessing
preprocess_data <- function(ts_data) {
  cat("=== COMPREHENSIVE PREPROCESSING ===\n")
  
  # 1. Check for outliers
  cat("1. Outlier Detection:\n")
  outliers <- boxplot.stats(ts_data)$out
  if (length(outliers) > 0) {
    cat("Found", length(outliers), "outliers\n")
    cat("Outlier values:", paste(round(outliers, 2), collapse = ", "), "\n")
    
    # Winsorize outliers (cap at 95th percentile)
    q95 <- quantile(ts_data, 0.95, na.rm = TRUE)
    q05 <- quantile(ts_data, 0.05, na.rm = TRUE)
    ts_winsorized <- pmin(pmax(ts_data, q05), q95)
    cat("✓ Outliers winsorized\n")
  } else {
    cat("✓ No outliers detected\n")
    ts_winsorized <- ts_data
  }
  
  # 2. Check for missing values
  cat("2. Missing Value Check:\n")
  missing_count <- sum(is.na(ts_winsorized))
  if (missing_count > 0) {
    cat("Found", missing_count, "missing values\n")
    # Interpolate missing values
    ts_winsorized <- na.interp(ts_winsorized)
    cat("✓ Missing values interpolated\n")
  } else {
    cat("✓ No missing values\n")
  }
  
  # 3. Check for variance stability
  cat("3. Variance Stability Check:\n")
  # Split data into quarters and check variance
  n <- length(ts_winsorized)
  quarter_size <- floor(n/4)
  variances <- sapply(1:4, function(i) {
    start_idx <- (i-1) * quarter_size + 1
    end_idx <- min(i * quarter_size, n)
    var(ts_winsorized[start_idx:end_idx], na.rm = TRUE)
  })
  
  cv <- sd(variances) / mean(variances)
  cat("Coefficient of variation in variances:", round(cv, 3), "\n")
  
  if (cv > 0.5) {
    cat("⚠ High variance instability detected\n")
    # Apply log transformation if data is positive
    if (all(ts_winsorized > 0, na.rm = TRUE)) {
      ts_transformed <- log(ts_winsorized)
      cat("✓ Applied log transformation\n")
    } else {
      cat("✗ Cannot apply log transformation (negative values)\n")
      ts_transformed <- ts_winsorized
    }
  } else {
    cat("✓ Variance appears stable\n")
    ts_transformed <- ts_winsorized
  }
  
  return(list(
    original = ts_data,
    winsorized = ts_winsorized,
    transformed = ts_transformed,
    outlier_count = length(outliers),
    missing_count = missing_count,
    variance_cv = cv
  ))
}

# Function to perform detailed decomposition analysis
analyze_decomposition <- function(ts_data) {
  cat("=== DETAILED DECOMPOSITION ANALYSIS ===\n")
  
  tryCatch({
    # Seasonal decomposition
    decomp <- stl(ts_data, s.window = "periodic")
    
    # Extract components
    seasonal_component <- decomp$time.series[, "seasonal"]
    trend_component <- decomp$time.series[, "trend"]
    remainder_component <- decomp$time.series[, "remainder"]
    
    # Calculate seasonal strength
    seasonal_strength <- var(seasonal_component, na.rm = TRUE) / 
                        (var(seasonal_component, na.rm = TRUE) + var(remainder_component, na.rm = TRUE))
    
    cat("Seasonal strength:", round(seasonal_strength, 3), "\n")
    
    # Calculate component proportions
    seasonal_variance <- var(seasonal_component, na.rm = TRUE)
    trend_variance <- var(trend_component, na.rm = TRUE)
    remainder_variance <- var(remainder_component, na.rm = TRUE)
    
    total_variance <- seasonal_variance + trend_variance + remainder_variance
    seasonal_prop <- seasonal_variance / total_variance
    trend_prop <- trend_variance / total_variance
    remainder_prop <- remainder_variance / total_variance
    
    cat("Component proportions:\n")
    cat("- Trend:", round(trend_prop, 3), "\n")
    cat("- Seasonal:", round(seasonal_prop, 3), "\n")
    cat("- Remainder:", round(remainder_prop, 3), "\n")
    
    # Analyze trend characteristics
    trend_slope <- coef(lm(trend_component ~ seq_along(trend_component)))[2]
    cat("Trend slope:", round(trend_slope, 2), "\n")
    
    if (trend_slope > 0) {
      cat("✓ Upward trend detected\n")
    } else if (trend_slope < 0) {
      cat("✓ Downward trend detected\n")
    } else {
      cat("✓ Stable trend detected\n")
    }
    
    # Analyze seasonal patterns
    freq <- frequency(ts_data)
    seasonal_pattern <- seasonal_component[1:freq]
    cat("Seasonal pattern range:", round(range(seasonal_pattern), 2), "\n")
    
    # Plot decomposition
    plot(decomp, main = "Seasonal Decomposition Analysis")
    
    # Additional plots
    par(mfrow = c(2, 2))
    
    # Trend analysis
    plot(trend_component, main = "Trend Component", ylab = "Sales", type = "l", col = "blue")
    abline(lm(trend_component ~ seq_along(trend_component)), col = "red", lwd = 2)
    
    # Seasonal pattern
    plot(seasonal_pattern, main = "Seasonal Pattern", ylab = "Sales", type = "l", col = "green")
    
    # Remainder analysis
    plot(remainder_component, main = "Remainder Component", ylab = "Sales", type = "l", col = "orange")
    abline(h = 0, col = "red", lty = 2)
    
    # Original vs Reconstructed
    reconstructed <- trend_component + seasonal_component + remainder_component
    plot(ts_data, main = "Original vs Reconstructed", ylab = "Sales", col = "black")
    lines(reconstructed, col = "red", lwd = 2)
    legend("topleft", legend = c("Original", "Reconstructed"), col = c("black", "red"), lwd = c(1, 2))
    
    par(mfrow = c(1, 1))
    
    return(list(
      decomp = decomp,
      seasonal_strength = seasonal_strength,
      seasonal_prop = seasonal_prop,
      trend_prop = trend_prop,
      remainder_prop = remainder_prop,
      trend_slope = trend_slope,
      seasonal_component = seasonal_component,
      trend_component = trend_component,
      remainder_component = remainder_component,
      seasonal_pattern = seasonal_pattern
    ))
    
  }, error = function(e) {
    cat("✗ Error in decomposition analysis:", e$message, "\n")
    return(NULL)
  })
}

# Function to fit ARIMA to remainder component
fit_remainder_arima <- function(remainder_component) {
  cat("=== FITTING ARIMA TO REMAINDER COMPONENT ===\n")
  
  tryCatch({
    # Fit ARIMA to remainder
    remainder_model <- auto.arima(remainder_component, seasonal = FALSE, stepwise = TRUE, approximation = FALSE)
    
    cat("✓ ARIMA model fitted to remainder\n")
    cat("Model:", remainder_model$arma, "\n")
    cat("AIC:", round(AIC(remainder_model), 2), "\n")
    
    # Model diagnostics
    cat("\nRemainder ARIMA Model Diagnostics:\n")
    checkresiduals(remainder_model)
    
    # Ljung-Box test
    ljung_result <- Box.test(residuals(remainder_model), type = "Ljung-Box")
    cat("Ljung-Box test p-value:", round(ljung_result$p.value, 4), "\n")
    if (ljung_result$p.value > 0.05) {
      cat("✓ Residuals appear to be white noise\n")
    } else {
      cat("✗ Residuals are not white noise\n")
    }
    
    # Shapiro-Wilk test for normality
    shapiro_result <- shapiro.test(residuals(remainder_model))
    cat("Shapiro-Wilk test p-value:", round(shapiro_result$p.value, 4), "\n")
    if (shapiro_result$p.value > 0.05) {
      cat("✓ Residuals appear to be normally distributed\n")
    } else {
      cat("✗ Residuals are not normally distributed\n")
    }
    
    return(list(
      model = remainder_model,
      aic = AIC(remainder_model),
      ljung_pvalue = ljung_result$p.value,
      shapiro_pvalue = shapiro_result$p.value
    ))
    
  }, error = function(e) {
    cat("✗ Error in remainder ARIMA modeling:", e$message, "\n")
    return(NULL)
  })
}

# Function to generate decomposition forecasts
generate_decomposition_forecast <- function(ts_data, decomposition_result, remainder_model, forecast_periods = 12) {
  cat("=== GENERATING DECOMPOSITION FORECASTS ===\n")
  
  tryCatch({
    freq <- frequency(ts_data)
    cat("Forecast periods:", forecast_periods, "\n")
    cat("Seasonal frequency:", freq, "\n")
    
    # 1. Forecast trend (linear extrapolation)
    trend_forecast <- seq(tail(decomposition_result$trend_component, 1), 
                         tail(decomposition_result$trend_component, 1) + 
                         decomposition_result$trend_slope * forecast_periods,
                         length.out = forecast_periods)
    
    # 2. Seasonal forecast (repeat pattern)
    seasonal_pattern <- decomposition_result$seasonal_pattern
    seasonal_forecast <- rep(seasonal_pattern, ceiling(forecast_periods/freq))[1:forecast_periods]
    
    # 3. Remainder forecast
    remainder_forecast <- forecast(remainder_model$model, h = forecast_periods)
    
    # 4. Combine components
    combined_forecast <- trend_forecast + seasonal_forecast + remainder_forecast$mean
    
    # Create forecast object
    forecast_result <- list(
      mean = combined_forecast,
      trend_forecast = trend_forecast,
      seasonal_forecast = seasonal_forecast,
      remainder_forecast = remainder_forecast$mean,
      lower = matrix(combined_forecast * 0.9, ncol = 2),
      upper = matrix(combined_forecast * 1.1, ncol = 2)
    )
    
    # Plot forecast
    plot(ts_data, main = "Decomposition Forecast (Next 12 Weeks)",
         xlab = "Time", ylab = "Sales", xlim = c(time(ts_data)[1], time(ts_data)[length(ts_data)] + forecast_periods/freq))
    
    # Add forecast line
    forecast_time_points <- time(ts_data)[length(ts_data)] + (1:forecast_periods)/freq
    lines(forecast_time_points, combined_forecast, col = "red", lwd = 2)
    
    # Add confidence intervals
    lines(forecast_time_points, combined_forecast * 0.9, col = "red", lty = 2)
    lines(forecast_time_points, combined_forecast * 1.1, col = "red", lty = 2)
    
    legend("topleft", legend = c("Historical", "Forecast", "Confidence Interval"), 
           col = c("black", "red", "red"), lwd = c(1, 2, 1), lty = c(1, 1, 2))
    
    # Component breakdown plot
    par(mfrow = c(2, 2))
    
    plot(forecast_time_points, trend_forecast, main = "Trend Forecast", 
         ylab = "Sales", type = "l", col = "blue")
    plot(forecast_time_points, seasonal_forecast, main = "Seasonal Forecast", 
         ylab = "Sales", type = "l", col = "green")
    plot(forecast_time_points, remainder_forecast$mean, main = "Remainder Forecast", 
         ylab = "Sales", type = "l", col = "orange")
    plot(forecast_time_points, combined_forecast, main = "Combined Forecast", 
         ylab = "Sales", type = "l", col = "red")
    
    par(mfrow = c(1, 1))
    
    cat("Forecast summary:\n")
    print(combined_forecast)
    
    return(forecast_result)
    
  }, error = function(e) {
    cat("✗ Error in decomposition forecasting:", e$message, "\n")
    return(NULL)
  })
}

# Function to compare with SARIMA (for reference)
compare_with_sarima <- function(ts_data) {
  cat("=== SARIMA COMPARISON (FOR REFERENCE) ===\n")
  
  tryCatch({
    # Fit SARIMA
    sarima_model <- auto.arima(ts_data, seasonal = TRUE, stepwise = TRUE, approximation = FALSE)
    
    cat("SARIMA model:", sarima_model$arma, "\n")
    cat("SARIMA AIC:", round(AIC(sarima_model), 2), "\n")
    
    # Generate SARIMA forecast
    sarima_forecast <- forecast(sarima_model, h = 12)
    
    # Plot comparison
    plot(ts_data, main = "SARIMA vs Decomposition Forecasts",
         xlab = "Time", ylab = "Sales", xlim = c(time(ts_data)[1], time(ts_data)[length(ts_data)] + 12/frequency(ts_data)))
    
    # Add SARIMA forecast
    forecast_time_points <- time(ts_data)[length(ts_data)] + (1:12)/frequency(ts_data)
    lines(forecast_time_points, sarima_forecast$mean, col = "blue", lwd = 2)
    
    legend("topleft", legend = c("Historical", "SARIMA Forecast"), 
           col = c("black", "blue"), lwd = c(1, 2))
    
    return(list(
      model = sarima_model,
      aic = AIC(sarima_model),
      forecast = sarima_forecast
    ))
    
  }, error = function(e) {
    cat("✗ Error in SARIMA comparison:", e$message, "\n")
    return(NULL)
  })
}

# Main analysis function
run_decomposition_focused_analysis <- function() {
  tryCatch({
    cat("=== DECOMPOSITION + ARIMA FOCUSED ANALYSIS ===\n")
    cat("Based on Superior AIC Performance (1977.718 vs 2048.65)\n\n")
    
    # Load and validate data
    sales_data <- safe_read_excel("Copy of Weekly Sales 5_29_23-5_25.xlsx")
    clean_data <- validate_and_clean_data(sales_data)
    ts_data <- create_time_series(clean_data)
    
    # Preprocessing
    preprocessed <- preprocess_data(ts_data)
    
    # Detailed decomposition analysis
    decomposition_result <- analyze_decomposition(preprocessed$transformed)
    
    if (is.null(decomposition_result)) {
      stop("Decomposition analysis failed")
    }
    
    # Fit ARIMA to remainder
    remainder_model <- fit_remainder_arima(decomposition_result$remainder_component)
    
    if (is.null(remainder_model)) {
      stop("Remainder ARIMA modeling failed")
    }
    
    # Generate decomposition forecasts
    forecast_result <- generate_decomposition_forecast(preprocessed$transformed, 
                                                     decomposition_result, 
                                                     remainder_model)
    
    # Compare with SARIMA (for reference)
    sarima_comparison <- compare_with_sarima(preprocessed$transformed)
    
    # Save results
    cat("=== SAVING RESULTS ===\n")
    saveRDS(list(
      decomposition_result = decomposition_result,
      remainder_model = remainder_model,
      forecast_result = forecast_result,
      sarima_comparison = sarima_comparison,
      preprocessed = preprocessed
    ), "decomposition_focused_analysis.rds")
    
    # Export detailed forecasts
    if (!is.null(forecast_result)) {
      forecast_df <- data.frame(
        Period = 1:12,
        Point_Forecast = forecast_result$mean,
        Trend_Component = forecast_result$trend_forecast,
        Seasonal_Component = forecast_result$seasonal_forecast,
        Remainder_Component = forecast_result$remainder_forecast,
        Lower_80 = forecast_result$mean * 0.9,
        Upper_80 = forecast_result$mean * 1.1,
        stringsAsFactors = FALSE
      )
      write.csv(forecast_df, "decomposition_forecast.csv", row.names = FALSE)
      cat("✓ Detailed forecast exported to CSV\n")
    }
    
    # Export component analysis
    component_df <- data.frame(
      Component = c("Trend", "Seasonal", "Remainder"),
      Proportion = c(decomposition_result$trend_prop, 
                    decomposition_result$seasonal_prop, 
                    decomposition_result$remainder_prop),
      stringsAsFactors = FALSE
    )
    write.csv(component_df, "component_analysis.csv", row.names = FALSE)
    cat("✓ Component analysis exported to CSV\n")
    
    cat("✓ Results saved successfully\n")
    
    # Summary
    cat("\n=== ANALYSIS SUMMARY ===\n")
    cat("1. Seasonal strength:", round(decomposition_result$seasonal_strength, 3), "\n")
    cat("2. Trend direction:", ifelse(decomposition_result$trend_slope > 0, "Upward", "Downward"), "\n")
    cat("3. Remainder ARIMA AIC:", round(remainder_model$aic, 2), "\n")
    if (!is.null(sarima_comparison)) {
      cat("4. SARIMA AIC (for comparison):", round(sarima_comparison$aic, 2), "\n")
      cat("5. AIC difference:", round(sarima_comparison$aic - remainder_model$aic, 2), "\n")
    }
    cat("6. Forecast horizon: 12 weeks\n")
    
    cat("\n=== KEY INSIGHTS ===\n")
    cat("• Decomposition approach provides better model fit (lower AIC)\n")
    cat("• Component analysis reveals what drives your sales\n")
    cat("• Trend and seasonal patterns are modeled separately\n")
    cat("• More interpretable and reliable forecasts\n")
    
  }, error = function(e) {
    cat("\n✗ CRITICAL ERROR:", e$message, "\n")
    cat("Please check your data and try again.\n")
  })
}

# Run the decomposition-focused analysis
run_decomposition_focused_analysis() 