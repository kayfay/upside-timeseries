# R Script Documentation

## Overview

This document provides detailed documentation for all R scripts in the Upside Time Series Analysis project, including their purpose, functionality, inputs, outputs, and usage instructions.

## Core Analysis Scripts

### 1. `time_series_comprehensive.R`

**Purpose**: Complete time series analysis comparing multiple modeling approaches

**Key Features**:
- SARIMA modeling with automatic parameter selection
- STL decomposition + ARIMA modeling
- Model comparison using AIC
- Comprehensive diagnostics and validation
- 12-week forecasting with confidence intervals

**Inputs**:
- Excel file: `Copy of Weekly Sales 5_29_23-5_25.xlsx`
- Date column (first column)
- Sales column (second column)

**Outputs**:
- `sales_forecast.csv` - Forecasted values with confidence intervals
- `best_arima_model.rds` - Best performing model
- Multiple PNG visualizations
- Console output with model diagnostics

**Usage**:
```r
source("time_series_comprehensive.R")
```

**Best For**: Comparing different modeling approaches and understanding model performance

---

### 2. `time_series_decomposition_focused.R`

**Purpose**: Optimized analysis using decomposition + ARIMA approach (recommended)

**Key Features**:
- STL decomposition for trend, seasonal, and remainder components
- ARIMA modeling on remainder component
- Component-wise forecasting and recombination
- Superior AIC performance (1977.718)
- Robust error handling and validation

**Inputs**:
- Excel file: `Copy of Weekly Sales 5_29_23-5_25.xlsx`
- Date column (first column)
- Sales column (second column)

**Outputs**:
- `sales_forecast.csv` - Forecasted values with confidence intervals
- `best_arima_model.rds` - Best performing model
- Multiple PNG visualizations
- Console output with detailed analysis

**Usage**:
```r
source("time_series_decomposition_focused.R")
```

**Best For**: Best forecasting accuracy and production use

---

### 3. `seasonal_peak_analysis.R`

**Purpose**: Business intelligence tool for identifying peak sales weeks

**Key Features**:
- Peak week identification using statistical thresholds
- Seasonal pattern analysis (weekly, monthly, quarterly)
- Business preparation recommendations
- Professional visualizations
- CSV exports for business planning

**Inputs**:
- Excel file: `Copy of Weekly Sales 5_29_23-5_25.xlsx`
- Date column (first column)
- Sales column (second column)

**Outputs**:
- `peak_weeks_calendar.csv` - Peak weeks for business planning
- `monthly_preparation_guide.csv` - Monthly preparation recommendations
- `all_peak_weeks.csv` - All identified peak weeks
- `seasonal_peak_analysis.rds` - Analysis results
- Multiple PNG visualizations

**Usage**:
```r
source("seasonal_peak_analysis.R")
```

**Best For**: Business planning, inventory management, and staffing decisions

---

### 4. `seasonal_peak_analysis_improved.R`

**Purpose**: Enhanced version with professional visualizations and improved graphics

**Key Features**:
- All features from `seasonal_peak_analysis.R`
- Improved heatmap with professional color palette
- Enhanced timeline with better labels and annotations
- Professional calendar visualization
- Summary table visualization
- Higher resolution images (150 DPI)

**Inputs**:
- Excel file: `Copy of Weekly Sales 5_29_23-5_25.xlsx`
- Date column (first column)
- Sales column (second column)

**Outputs**:
- All outputs from `seasonal_peak_analysis.R`
- `02_sales_heatmap_improved.png` - Cleaner heatmap
- `03_peak_weeks_timeline_enhanced.png` - Better timeline
- `08_peak_weeks_calendar.png` - Professional calendar
- `09_peak_weeks_summary.png` - Summary table

**Usage**:
```r
source("seasonal_peak_analysis_improved.R")
```

**Best For**: Professional presentations and business reports

---

### 5. `improved_visualizations.R`

**Purpose**: Standalone script for creating improved visualizations from existing data

**Key Features**:
- Uses existing analysis data (`seasonal_peak_analysis.rds`)
- Creates only the improved visualizations
- No full analysis - visualization only
- Quick execution for chart generation

**Inputs**:
- `seasonal_peak_analysis.rds` - Existing analysis results
- Required R packages: `readxl`, `dplyr`, `lubridate`, `tidyr`

**Outputs**:
- `02_sales_heatmap_improved.png` - Cleaner heatmap
- `03_peak_weeks_timeline_enhanced.png` - Better timeline
- `08_peak_weeks_calendar.png` - Professional calendar
- `09_peak_weeks_summary.png` - Summary table

**Usage**:
```r
source("improved_visualizations.R")
```

**Best For**: Quick visualization generation without full analysis

---

## Utility Scripts

### 6. `install_r_packages.R`

**Purpose**: Install and load all required R packages

**Key Features**:
- Installs missing packages automatically
- Loads all required packages
- Error handling for package installation
- Comprehensive package list

**Required Packages**:
- `readxl` - Excel file reading
- `forecast` - Time series forecasting
- `tseries` - Time series analysis
- `ggplot2` - Data visualization
- `dplyr` - Data manipulation
- `lubridate` - Date handling
- `tidyr` - Data tidying
- `seasonal` - Seasonal adjustment
- `gridExtra` - Advanced plotting
- `RColorBrewer` - Color palettes

**Usage**:
```r
source("install_r_packages.R")
```

**Best For**: Initial setup and package management

---

### 7. `outlier_analysis.R`

**Purpose**: Detailed analysis of outliers and extreme values

**Key Features**:
- Outlier detection using multiple methods
- Visualization of outliers
- Impact analysis on forecasting
- Recommendations for outlier handling

**Inputs**:
- Excel file: `Copy of Weekly Sales 5_29_23-5_25.xlsx`

**Outputs**:
- Outlier analysis report
- Visualizations of outliers
- Recommendations for data handling

**Usage**:
```r
source("outlier_analysis.R")
```

**Best For**: Data quality assessment and outlier investigation

---

## Batch and Helper Files

### 8. `run_improved_analysis.bat`

**Purpose**: Windows batch file for automated script execution

**Key Features**:
- Automatic R installation detection
- Multiple R version support
- Error handling and user guidance
- One-click execution

**Usage**:
```bash
# Double-click the file or run from command line
run_improved_analysis.bat
```

**Best For**: Windows users who prefer one-click execution

---

### 9. `run_improved_analysis.R`

**Purpose**: Simple wrapper script for running the improved analysis

**Key Features**:
- Simple execution wrapper
- Error handling
- Progress reporting

**Usage**:
```r
source("run_improved_analysis.R")
```

**Best For**: Quick execution of the full improved analysis

---

## Script Comparison Matrix

| Script | Purpose | Analysis | Visualizations | Business Intelligence | Best For |
|--------|---------|----------|----------------|----------------------|----------|
| `time_series_comprehensive.R` | Complete analysis | ✅ Full | ✅ Basic | ❌ No | Model comparison |
| `time_series_decomposition_focused.R` | Optimized forecasting | ✅ Focused | ✅ Basic | ❌ No | Best forecasting |
| `seasonal_peak_analysis.R` | Business intelligence | ✅ Peak analysis | ✅ Good | ✅ Full | Business planning |
| `seasonal_peak_analysis_improved.R` | Enhanced BI | ✅ Peak analysis | ✅ Professional | ✅ Full | Professional reports |
| `improved_visualizations.R` | Visualization only | ❌ No | ✅ Professional | ❌ No | Quick charts |

## Error Handling and Troubleshooting

### Common Issues and Solutions

#### 1. Package Installation Errors
**Error**: `could not find function "pivot_wider"`
**Solution**: Run `install_r_packages.R` first

#### 2. File Access Errors
**Error**: `File not found`
**Solution**: Check file path and working directory

#### 3. Memory Issues
**Error**: `cannot allocate vector of size`
**Solution**: Close other applications or reduce data size

#### 4. Vector Length Mismatch
**Error**: `time-series/vector length mismatch`
**Solution**: Use `time_series_decomposition_focused.R`

### Debugging Tips

1. **Check Working Directory**:
   ```r
   getwd()
   list.files()
   ```

2. **Verify Package Installation**:
   ```r
   library(readxl)
   library(forecast)
   ```

3. **Test File Access**:
   ```r
   file.exists("Copy of Weekly Sales 5_29_23-5_25.xlsx")
   ```

4. **Check Data Structure**:
   ```r
   data <- read_excel("Copy of Weekly Sales 5_29_23-5_25.xlsx")
   str(data)
   head(data)
   ```

## Performance Considerations

### Execution Time Estimates
- **Basic Analysis**: 30-60 seconds
- **Comprehensive Analysis**: 2-5 minutes
- **Peak Analysis**: 1-2 minutes
- **Improved Visualizations**: 30-60 seconds

### Memory Requirements
- **Minimum**: 2GB RAM
- **Recommended**: 4GB+ RAM
- **Large Datasets**: 8GB+ RAM

### Optimization Tips
1. Close other applications during analysis
2. Use `improved_visualizations.R` for quick chart generation
3. Run scripts during off-peak hours
4. Consider data sampling for very large datasets

## Customization Options

### Modifying Forecast Horizon
```r
# In any script, change this variable
forecast_periods <- 12  # Change to desired number of weeks
```

### Adjusting Peak Thresholds
```r
# In peak analysis scripts
peak_threshold <- overall_mean + (1.5 * overall_sd)  # More conservative
peak_threshold <- overall_mean + (0.5 * overall_sd)  # More aggressive
```

### Changing Visualization Settings
```r
# In visualization scripts
png("output.png", width = 1200, height = 800, res = 150)  # Adjust resolution
```

---

**Last Updated**: January 2025  
**R Version**: 4.0+  
**Total Scripts**: 9  
**Documentation Status**: Complete 