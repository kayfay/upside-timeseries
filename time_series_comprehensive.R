# Comprehensive Time Series Analysis
# Multiple Approaches: SARIMA vs Decomposition + ARIMA
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

# Function to detect seasonality and recommend approach
analyze_seasonality <- function(ts_data) {
  cat("=== SEASONALITY ANALYSIS AND APPROACH RECOMMENDATION ===\n")
  
  tryCatch({
    # Seasonal decomposition
    decomp <- stl(ts_data, s.window = "periodic")
    
    # Calculate seasonal strength
    seasonal_component <- decomp$time.series[, "seasonal"]
    trend_component <- decomp$time.series[, "trend"]
    remainder_component <- decomp$time.series[, "remainder"]
    
    # Seasonal strength (0-1 scale)
    seasonal_strength <- var(seasonal_component, na.rm = TRUE) / 
                        (var(seasonal_component, na.rm = TRUE) + var(remainder_component, na.rm = TRUE))
    
    cat("Seasonal strength:", round(seasonal_strength, 3), "\n")
    
    # Check for changing seasonality
    seasonal_variance <- var(seasonal_component, na.rm = TRUE)
    trend_variance <- var(trend_component, na.rm = TRUE)
    remainder_variance <- var(remainder_component, na.rm = TRUE)
    
    # Calculate component proportions
    total_variance <- seasonal_variance + trend_variance + remainder_variance
    seasonal_prop <- seasonal_variance / total_variance
    trend_prop <- trend_variance / total_variance
    remainder_prop <- remainder_variance / total_variance
    
    cat("Component proportions:\n")
    cat("- Trend:", round(trend_prop, 3), "\n")
    cat("- Seasonal:", round(seasonal_prop, 3), "\n")
    cat("- Remainder:", round(remainder_prop, 3), "\n")
    
    # Recommend approach
    cat("\n=== APPROACH RECOMMENDATION ===\n")
    
    if (seasonal_strength > 0.6) {
      cat("✓ Strong seasonality detected (", round(seasonal_strength, 3), ")\n")
      cat("RECOMMENDATION: Use SARIMA approach\n")
      cat("REASON: Strong, consistent seasonal patterns are best handled by SARIMA\n")
      recommended_approach <- "SARIMA"
    } else if (seasonal_strength > 0.3) {
      cat("✓ Moderate seasonality detected (", round(seasonal_strength, 3), ")\n")
      cat("RECOMMENDATION: Try both approaches and compare\n")
      cat("REASON: Moderate seasonality can work well with either method\n")
      recommended_approach <- "BOTH"
    } else {
      cat("✓ Weak seasonality detected (", round(seasonal_strength, 3), ")\n")
      cat("RECOMMENDATION: Use regular ARIMA or decomposition approach\n")
      cat("REASON: Weak seasonality may not need seasonal modeling\n")
      recommended_approach <- "ARIMA"
    }
    
    # Plot decomposition
    plot(decomp, main = "Seasonal Decomposition")
    
    return(list(
      decomp = decomp,
      seasonal_strength = seasonal_strength,
      seasonal_prop = seasonal_prop,
      trend_prop = trend_prop,
      remainder_prop = remainder_prop,
      recommended_approach = recommended_approach,
      seasonal_component = seasonal_component,
      trend_component = trend_component,
      remainder_component = remainder_component
    ))
    
  }, error = function(e) {
    cat("✗ Error in seasonal analysis:", e$message, "\n")
    return(NULL)
  })
}

# Function to fit SARIMA model (Approach 1)
fit_sarima_model <- function(ts_data) {
  cat("=== APPROACH 1: SARIMA MODELING ===\n")
  cat("This approach handles seasonality automatically within the model\n\n")
  
  tryCatch({
    # Auto SARIMA
    cat("Fitting Auto SARIMA...\n")
    sarima_model <- auto.arima(ts_data, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
    
    cat("✓ SARIMA model fitted successfully\n")
    cat("Model:", sarima_model$arma, "\n")
    cat("AIC:", round(AIC(sarima_model), 2), "\n")
    
    # Model diagnostics
    cat("\nSARIMA Model Diagnostics:\n")
    checkresiduals(sarima_model)
    
    # Ljung-Box test
    ljung_result <- Box.test(residuals(sarima_model), type = "Ljung-Box")
    cat("Ljung-Box test p-value:", round(ljung_result$p.value, 4), "\n")
    if (ljung_result$p.value > 0.05) {
      cat("✓ Residuals appear to be white noise\n")
    } else {
      cat("✗ Residuals are not white noise\n")
    }
    
    return(list(
      model = sarima_model,
      aic = AIC(sarima_model),
      ljung_pvalue = ljung_result$p.value
    ))
    
  }, error = function(e) {
    cat("✗ Error in SARIMA modeling:", e$message, "\n")
    return(NULL)
  })
}

# Function to fit decomposition + ARIMA model (Approach 2)
fit_decomposition_model <- function(ts_data, seasonality_info) {
  cat("=== APPROACH 2: DECOMPOSITION + ARIMA MODELING ===\n")
  cat("This approach separates components and models the remainder\n\n")
  
  if (is.null(seasonality_info)) {
    cat("✗ Cannot proceed without seasonal decomposition\n")
    return(NULL)
  }
  
  tryCatch({
    # Extract components
    trend <- seasonality_info$trend_component
    seasonal <- seasonality_info$seasonal_component
    remainder <- seasonality_info$remainder_component
    
    cat("Components extracted:\n")
    cat("- Trend component\n")
    cat("- Seasonal component\n")
    cat("- Remainder component\n\n")
    
    # Model the remainder with ARIMA
    cat("Fitting ARIMA to remainder component...\n")
    remainder_model <- auto.arima(remainder, seasonal = FALSE)
    
    cat("✓ ARIMA model fitted to remainder\n")
    cat("Model:", remainder_model$arma, "\n")
    cat("AIC:", round(AIC(remainder_model), 2), "\n")
    
    # Model diagnostics
    cat("\nDecomposition Model Diagnostics:\n")
    checkresiduals(remainder_model)
    
    # Ljung-Box test
    ljung_result <- Box.test(residuals(remainder_model), type = "Ljung-Box")
    cat("Ljung-Box test p-value:", round(ljung_result$p.value, 4), "\n")
    if (ljung_result$p.value > 0.05) {
      cat("✓ Residuals appear to be white noise\n")
    } else {
      cat("✗ Residuals are not white noise\n")
    }
    
    return(list(
      trend = trend,
      seasonal = seasonal,
      remainder = remainder,
      remainder_model = remainder_model,
      aic = AIC(remainder_model),
      ljung_pvalue = ljung_result$p.value
    ))
    
  }, error = function(e) {
    cat("✗ Error in decomposition modeling:", e$message, "\n")
    return(NULL)
  })
}

# Function to compare approaches
compare_approaches <- function(sarima_result, decomposition_result) {
  cat("=== APPROACH COMPARISON ===\n")
  
  comparison_df <- data.frame(
    Approach = c("SARIMA", "Decomposition + ARIMA"),
    AIC = c(
      ifelse(!is.null(sarima_result), sarima_result$aic, NA),
      ifelse(!is.null(decomposition_result), decomposition_result$aic, NA)
    ),
    Ljung_Box_pvalue = c(
      ifelse(!is.null(sarima_result), sarima_result$ljung_pvalue, NA),
      ifelse(!is.null(decomposition_result), decomposition_result$ljung_pvalue, NA)
    ),
    Residuals_White_Noise = c(
      ifelse(!is.null(sarima_result), sarima_result$ljung_pvalue > 0.05, NA),
      ifelse(!is.null(decomposition_result), decomposition_result$ljung_pvalue > 0.05, NA)
    ),
    stringsAsFactors = FALSE
  )
  
  cat("Model comparison:\n")
  print(comparison_df)
  
  # Determine best approach
  if (!is.null(sarima_result) && !is.null(decomposition_result)) {
    if (sarima_result$aic < decomposition_result$aic) {
      cat("\n✓ SARIMA approach has lower AIC\n")
      best_approach <- "SARIMA"
    } else {
      cat("\n✓ Decomposition approach has lower AIC\n")
      best_approach <- "DECOMPOSITION"
    }
  } else if (!is.null(sarima_result)) {
    best_approach <- "SARIMA"
  } else if (!is.null(decomposition_result)) {
    best_approach <- "DECOMPOSITION"
  } else {
    best_approach <- "NONE"
  }
  
  return(list(
    comparison = comparison_df,
    best_approach = best_approach
  ))
}

# Function to generate forecasts
generate_forecasts <- function(ts_data, sarima_result, decomposition_result, best_approach) {
  cat("=== FORECASTING ===\n")
  
  forecast_periods <- 12
  
  if (best_approach == "SARIMA" && !is.null(sarima_result)) {
    cat("Generating SARIMA forecasts...\n")
    forecast_result <- forecast(sarima_result$model, h = forecast_periods)
    
    # Plot forecast
    plot(forecast_result, main = "SARIMA Forecast (Next 12 Weeks)",
         xlab = "Time", ylab = "Sales")
    
  } else if (best_approach == "DECOMPOSITION" && !is.null(decomposition_result)) {
    cat("Generating Decomposition forecasts...\n")
    
    # Get the frequency of the time series
    freq <- frequency(ts_data)
    cat("Time series frequency:", freq, "\n")
    cat("Time series length:", length(ts_data), "\n")
    cat("Forecast periods requested:", forecast_periods, "\n")
    
    # Forecast trend (simple linear extrapolation)
    tryCatch({
      trend_forecast <- seq(tail(decomposition_result$trend, 1), 
                           tail(decomposition_result$trend, 1) + 
                           mean(diff(decomposition_result$trend)) * forecast_periods,
                           length.out = forecast_periods)
      cat("Trend forecast length:", length(trend_forecast), "\n")
    }, error = function(e) {
      cat("✗ Error in trend forecast:", e$message, "\n")
      # Use simple linear extrapolation as fallback
      trend_forecast <- rep(tail(decomposition_result$trend, 1), forecast_periods)
      cat("Using fallback trend forecast\n")
    })
    
    # Use seasonal pattern for forecast - ensure correct length
    seasonal_pattern <- decomposition_result$seasonal[1:freq]
    cat("Seasonal pattern length:", length(seasonal_pattern), "\n")
    
    # Repeat seasonal pattern to match forecast length
    seasonal_forecast <- rep(seasonal_pattern, ceiling(forecast_periods/freq))[1:forecast_periods]
    cat("Seasonal forecast length:", length(seasonal_forecast), "\n")
    
    # Forecast remainder
    tryCatch({
      remainder_forecast <- forecast(decomposition_result$remainder_model, h = forecast_periods)
      cat("Remainder forecast length:", length(remainder_forecast$mean), "\n")
    }, error = function(e) {
      cat("✗ Error in remainder forecast:", e$message, "\n")
      # Use zero forecast as fallback
      remainder_forecast <- list(mean = rep(0, forecast_periods))
      cat("Using zero remainder forecast as fallback\n")
    })
    
    # Ensure all components have the same length
    min_length <- min(length(trend_forecast), length(seasonal_forecast), length(remainder_forecast$mean))
    cat("Using minimum length for combination:", min_length, "\n")
    
    # Combine components with matching lengths
    combined_forecast <- trend_forecast[1:min_length] + 
                        seasonal_forecast[1:min_length] + 
                        remainder_forecast$mean[1:min_length]
    
    # Create forecast object
    forecast_result <- list(
      mean = combined_forecast,
      lower = matrix(combined_forecast * 0.9, ncol = 2),
      upper = matrix(combined_forecast * 1.1, ncol = 2)
    )
    
    cat("Final forecast length:", length(combined_forecast), "\n")
    
    # Plot forecast
    plot(ts_data, main = "Decomposition Forecast (Next 12 Weeks)",
         xlab = "Time", ylab = "Sales")
    
    # Add forecast line with correct time points
    forecast_time_points <- time(ts_data)[length(ts_data)] + (1:min_length)/frequency(ts_data)
    lines(forecast_time_points, combined_forecast, col = "red", lwd = 2)
    
  } else {
    cat("✗ Cannot generate forecasts - no valid model\n")
    return(NULL)
  }
  
  # Print forecast summary
  cat("Forecast summary:\n")
  print(forecast_result$mean)
  
  return(forecast_result)
}

# Main analysis function
run_comprehensive_analysis <- function() {
  tryCatch({
    cat("=== COMPREHENSIVE TIME SERIES ANALYSIS ===\n")
    cat("Comparing SARIMA vs Decomposition + ARIMA Approaches\n\n")
    
    # Load and validate data
    sales_data <- safe_read_excel("Copy of Weekly Sales 5_29_23-5_25.xlsx")
    clean_data <- validate_and_clean_data(sales_data)
    ts_data <- create_time_series(clean_data)
    
    # Preprocessing
    preprocessed <- preprocess_data(ts_data)
    
    # Seasonality analysis and approach recommendation
    seasonality_info <- analyze_seasonality(preprocessed$transformed)
    
    # Fit both approaches
    sarima_result <- fit_sarima_model(preprocessed$transformed)
    decomposition_result <- fit_decomposition_model(preprocessed$transformed, seasonality_info)
    
    # Compare approaches
    comparison <- compare_approaches(sarima_result, decomposition_result)
    
    # Generate forecasts with best approach
    forecast_result <- generate_forecasts(preprocessed$transformed, 
                                        sarima_result, 
                                        decomposition_result, 
                                        comparison$best_approach)
    
    # Save results
    cat("=== SAVING RESULTS ===\n")
    saveRDS(list(
      sarima_result = sarima_result,
      decomposition_result = decomposition_result,
      comparison = comparison,
      seasonality_info = seasonality_info,
      preprocessed = preprocessed
    ), "comprehensive_analysis.rds")
    
    # Export comparison to CSV
    write.csv(comparison$comparison, "approach_comparison.csv", row.names = FALSE)
    
    # Export forecasts
    if (!is.null(forecast_result)) {
      forecast_length <- length(forecast_result$mean)
      forecast_df <- data.frame(
        Period = 1:forecast_length,
        Point_Forecast = forecast_result$mean,
        stringsAsFactors = FALSE
      )
      write.csv(forecast_df, "comprehensive_forecast.csv", row.names = FALSE)
      cat("Exported", forecast_length, "forecast periods to CSV\n")
    }
    
    cat("✓ Results saved successfully\n")
    
    # Summary
    cat("\n=== ANALYSIS SUMMARY ===\n")
    cat("1. Seasonal strength:", round(seasonality_info$seasonal_strength, 3), "\n")
    cat("2. Recommended approach:", seasonality_info$recommended_approach, "\n")
    cat("3. Best performing approach:", comparison$best_approach, "\n")
    cat("4. Forecast horizon: 12 weeks\n")
    
    cat("\n=== KEY INSIGHTS ===\n")
    cat("• SARIMA: Handles seasonality automatically, good for strong patterns\n")
    cat("• Decomposition: Separates components, good for changing seasonality\n")
    cat("• Both approaches provide valid forecasts with different assumptions\n")
    cat("• Choose based on your data characteristics and business needs\n")
    
  }, error = function(e) {
    cat("\n✗ CRITICAL ERROR:", e$message, "\n")
    cat("Please check your data and try again.\n")
  })
}

# Run the comprehensive analysis
run_comprehensive_analysis() 