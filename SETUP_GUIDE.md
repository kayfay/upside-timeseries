# Time Series Analysis Setup Guide

## 🚀 Quick Start

**Recommended Method: RStudio (Most Reliable)**
1. Open RStudio
2. Open `run_analysis_manual.R`
3. Click "Source" or press `Ctrl+Shift+Enter`
4. View results at `index.html`

**Alternative: Command Line (If R is in PATH)**
```bash
Rscript run_analysis_manual.R
```

> **Note:** If `Rscript` is not recognized, use RStudio instead.

## 📋 Prerequisites

### Required Software
- **R** (version 4.0 or higher)
- **RStudio** (recommended for ease of use)
- **Excel file**: `Copy of Weekly Sales 5_29_23-5_25.xlsx`

### Required R Packages
The script will automatically install these packages:
- `readxl` - Excel file reading
- `dplyr` - Data manipulation
- `lubridate` - Date handling
- `forecast` - Time series forecasting
- `tseries` - Time series analysis
- `ggplot2` - Professional plotting
- `tidyr` - Data reshaping
- `purrr` - Functional programming
- `gridExtra` - Plot arrangement
- `RColorBrewer` - Color palettes
- `scales` - Plot scaling

## 🎯 How to Run the Analysis

### Option 1: RStudio (Recommended)
1. **Open RStudio**
2. **Open the script**: File → Open File → `run_analysis_manual.R`
3. **Run the analysis**: Click "Source" button or press `Ctrl+Shift+Enter`
4. **View results**: Open `index.html` in your web browser

### Option 2: Command Line (If R is in PATH)
```bash
Rscript run_analysis_manual.R
```

### Option 3: One-Click R Script
1. **Double-click** `run_analysis_manual.R`
2. **Or** right-click → "Open with" → RStudio

## 📊 What You'll Get

### Generated Files
- **7 Professional Visualizations** (PNG format):
  - `01_professional_time_series.png` - Core time series with trend analysis
  - `02_seasonal_decomposition.png` - Trend, seasonal, and remainder components
  - `03_trend_adjusted_peaks.png` - Peak identification with trend adjustment
  - `04_enhanced_sales_heatmap.png` - Monthly sales patterns heatmap
  - `05_monthly_pattern_analysis.png` - Monthly comparison analysis
  - `06_sales_forecast.png` - ARIMA forecasting with confidence intervals
  - `07_business_insights_summary.png` - Advanced statistical insights

### Website Dashboard
- **`index.html`** - Professional web dashboard with all visualizations
- **Advanced statistical analysis** for each visualization
- **Business insights** and recommendations
- **Interactive design** with hover effects

### Data Files
- `visualization_summaries.rds` - Detailed statistical summaries
- `detrended_sales_data.csv` - Processed data with trend components

## 🔧 Troubleshooting

### Common Issues

**1. "Rscript not recognized"**
- **Solution**: Use RStudio instead
- Open `run_analysis_manual.R` in RStudio and click "Source"

**2. "Excel file not found"**
- **Solution**: Ensure `Copy of Weekly Sales 5_29_23-5_25.xlsx` is in the same folder as the scripts

**3. "Missing values in object" (Fixed)**
- **Solution**: The script now automatically handles missing values with interpolation
- This error has been resolved in the latest version

**4. "Package not found"**
- **Solution**: The script automatically installs required packages
- If manual installation needed: `install.packages(c("readxl", "dplyr", "lubridate", "forecast", "tseries", "ggplot2", "tidyr", "purrr", "gridExtra", "RColorBrewer", "scales"))`

**5. "Permission denied"**
- **Solution**: Run RStudio as administrator or ensure write permissions in the folder

### Testing Your Setup
Run `test_script_execution.R` in RStudio to verify your environment:
```r
source('test_script_execution.R')
```

This will check:
- Required files are present
- Package availability
- Working directory setup

## 📁 Project Structure

```
upside-timeseries/
├── 📊 Data
│   └── Copy of Weekly Sales 5_29_23-5_25.xlsx
├── 🔧 Core Scripts
│   ├── run_analysis_manual.R                 # Main runner script
│   ├── comprehensive_visualization_suite.R   # Core analysis & visualizations
│   ├── update_website_with_summaries.R       # Website update script
│   └── test_script_execution.R               # Environment test script
├── 📈 Analysis Scripts
│   ├── time_series_comprehensive.R           # Advanced time series analysis
│   ├── time_series_decomposition_focused.R   # Decomposition-focused analysis
│   ├── seasonal_peak_analysis.R              # Seasonal peak identification
│   ├── trend_adjusted_peak_analysis.R        # Trend-adjusted analysis
│   └── outlier_analysis.R                    # Outlier detection
├── 🎨 Output Files
│   ├── index.html                            # Professional web dashboard
│   ├── 01_professional_time_series.png       # Core time series plot
│   ├── 02_seasonal_decomposition.png         # Decomposition analysis
│   ├── 03_trend_adjusted_peaks.png           # Trend-adjusted peaks
│   ├── 04_enhanced_sales_heatmap.png         # Sales heatmap
│   ├── 05_monthly_pattern_analysis.png       # Monthly patterns
│   ├── 06_sales_forecast.png                 # Forecasting
│   ├── 07_business_insights_summary.png      # Business insights
│   └── archive_old_graphs/                   # Archived previous versions
├── 📚 Documentation
│   ├── README.md                             # Project overview
│   ├── SETUP_GUIDE.md                        # This guide
│   ├── BUSINESS_PLANNING_GUIDE.md            # Business recommendations
│   ├── SCRIPT_DOCUMENTATION.md               # Detailed script reference
│   └── QUICK_REFERENCE.md                    # Quick reference guide
└── 📋 Utilities
    └── install_r_packages.R                  # Package installation
```

## 🎯 Script Comparison

| Script | Purpose | Key Features | Best For |
|--------|---------|--------------|----------|
| `run_analysis_manual.R` | **Main Runner** | One-click execution, error handling, auto-updates website | **Primary execution method** |
| `comprehensive_visualization_suite.R` | **Core Analysis** | 7 professional visualizations, detrended data, advanced stats | **Complete analysis** |
| `time_series_comprehensive.R` | **Advanced Analysis** | SARIMA + Decomposition comparison, detailed diagnostics | **In-depth analysis** |
| `time_series_decomposition_focused.R` | **Decomposition Focus** | STL decomposition, component forecasting | **Seasonal analysis** |
| `seasonal_peak_analysis.R` | **Peak Identification** | Seasonal peak detection, business planning | **Business preparation** |
| `trend_adjusted_peak_analysis.R` | **Trend Adjustment** | Detrended peak analysis, bias correction | **Accurate seasonal planning** |

## 🚀 Next Steps

1. **Run the Analysis**: Use RStudio to execute `run_analysis_manual.R`
2. **View Results**: Open `index.html` in your web browser
3. **Review Insights**: Check `BUSINESS_PLANNING_GUIDE.md` for recommendations
4. **Customize**: Modify scripts as needed for your specific requirements

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Run `test_analysis.R` to verify your setup
3. Ensure all files are in the same directory
4. Use RStudio for the most reliable execution

---

**Last Updated**: Latest version includes detrended data analysis, advanced statistics, and professional web dashboard with detailed insights. 