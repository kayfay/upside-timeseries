# Install Required R Packages for Time Series Analysis
# Run this script after installing R

# List of required packages
required_packages <- c(
  "readxl",      # For reading Excel files
  "forecast",    # For ARIMA modeling and forecasting
  "tseries",     # For time series tests
  "ggplot2",     # For plotting
  "dplyr",       # For data manipulation
  "lubridate",   # For date handling
  "seasonal"     # For seasonal analysis
)

# Function to install packages
install_packages <- function(packages) {
  for(package in packages) {
    cat("Installing", package, "...\n")
    tryCatch({
      install.packages(package, dependencies = TRUE)
      cat("✓", package, "installed successfully\n")
    }, error = function(e) {
      cat("✗ Error installing", package, ":", e$message, "\n")
    })
  }
}

# Install all packages
cat("=== INSTALLING REQUIRED R PACKAGES ===\n")
install_packages(required_packages)

cat("\n=== INSTALLATION COMPLETE ===\n")
cat("You can now run the time series analysis scripts:\n")
cat("1. time_series_analysis_fixed.R - Basic analysis\n")
cat("2. time_series_analysis_enhanced.R - Comprehensive analysis\n") 