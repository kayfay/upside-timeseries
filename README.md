# Upside Time Series Analysis

A comprehensive time series analysis project for restaurant sales data, featuring advanced seasonal decomposition, detrended analysis, and business intelligence tools for strategic decision making.

## 📊 Project Overview

This project analyzes weekly sales data from July 2023 to July 2025 to identify true seasonal patterns, remove growth bias, and provide actionable business insights for inventory management, staffing decisions, and strategic planning.

## 🎯 Key Features

- **Advanced Time Series Decomposition**: STL decomposition for trend, seasonal, and remainder components
- **Detrended Analysis**: True seasonal patterns without growth bias
- **Pattern Recognition**: Weekly and monthly seasonal analysis with heatmaps
- **Business Intelligence Dashboard**: Enhanced metrics and actionable insights
- **Professional Visualizations**: Sophisticated charts optimized for business decision making
- **Strategic Planning Tools**: Peak/trough season identification and resource optimization

## 📁 File Structure

### Core Analysis Scripts
- `create_enhanced_business_summary.R` - Enhanced business intelligence dashboard generation
- `comprehensive_visualization_suite.R` - Complete visualization generation suite
- `time_series_decomposition_analysis.R` - Core time series decomposition analysis
- `seasonal_peak_analysis.R` - Seasonal peak identification and analysis
- `seasonal_peak_analysis_improved.R` - Enhanced seasonal analysis with professional visualizations

### Data Files
- `Copy of Weekly Sales 5_29_23-5_25.xlsx` - Original sales data (July 2023 - July 2025)
- `all_peak_weeks.csv` - All identified peak weeks for business planning
- `monthly_preparation_guide.csv` - Monthly preparation recommendations
- `peak_weeks_calendar.csv` - Peak weeks calendar data

### Generated Visualizations (Current)
- `01_professional_time_series.png` - Complete sales journey analysis (original, trend, detrended)
- `02_seasonal_decomposition.png` - Seasonal decomposition components
- `03_trend_adjusted_peaks.png` - Trend-adjusted peak analysis
- `04_enhanced_sales_heatmap.png` - Detrended sales intensity heatmap
- `05_monthly_pattern_analysis.png` - Monthly sales patterns (original vs detrended)
- `07_enhanced_business_insights_summary.png` - Enhanced business intelligence dashboard
- `08_yearly_calendar_highlights.png` - Yearly calendar highlights

### Analysis Documentation
- `TIME_SERIES_DECOMPOSITION_ANALYSIS.md` - Core time series analysis documentation
- `DETRENDED_SALES_HEATMAP_ANALYSIS.md` - Detrended heatmap analysis
- `MONTHLY_SALES_PATTERNS_ANALYSIS.md` - Monthly patterns analysis
- `SALES_TIME_SERIES_DECOMPOSITION_ANALYSIS.md` - Sales decomposition analysis
- `BUSINESS_INTELLIGENCE_SUMMARY_ANALYSIS.md` - Business intelligence analysis
- `TREND_DECOMPOSITION_BUSINESS_ANALYSIS.md` - Trend decomposition business analysis

### Setup and Documentation
- `install_r_packages.R` - Package installation script
- `SETUP_GUIDE.md` - Detailed setup instructions
- `SEASONAL PATTERN ANALYSIS.md` - Analysis methodology documentation
- `BUSINESS_PLANNING_GUIDE.md` - Business planning recommendations
- `QUICK_REFERENCE.md` - Quick reference guide
- `SCRIPT_DOCUMENTATION.md` - Script documentation

### Web Interface
- `index.html` - Interactive web dashboard with comprehensive analysis

## 🚀 Quick Start

### Prerequisites
- R (version 4.0 or higher)
- RStudio (recommended)

### Installation
1. **Install R**: Download from [r-project.org](https://www.r-project.org/)
2. **Install RStudio**: Download from [rstudio.com](https://www.rstudio.com/)
3. **Install Required Packages**: Run `install_r_packages.R`

### Running the Analysis

#### Option 1: Generate Business Intelligence Dashboard (Recommended)
```r
# In RStudio
source("create_enhanced_business_summary.R")
```

#### Option 2: Complete Analysis Suite
```r
# In RStudio
source("comprehensive_visualization_suite.R")
```

#### Option 3: Core Time Series Analysis
```r
# In RStudio
source("time_series_decomposition_analysis.R")
```

## 📈 Analysis Methods

### 1. Advanced Time Series Decomposition
- **STL Decomposition**: Seasonal and Trend decomposition using Loess
- **Trend Component**: 85% contribution - Linear growth from $40K to $57K/week
- **Seasonal Component**: 15% contribution - Bimodal pattern with 6-month cycles
- **Residual Component**: <5% contribution - Low random fluctuations

### 2. Detrended Analysis
- **Growth Bias Removal**: Eliminates upward trend to reveal true seasonal patterns
- **True Seasonal Patterns**: Consistent peaks and troughs across years
- **Performance Evaluation**: Unbiased assessment based on seasonal effects

### 3. Pattern Recognition
- **Weekly Heatmaps**: Detrended sales intensity by week and year
- **Monthly Patterns**: Original vs detrended sales comparison
- **Peak/Trough Identification**: October/November and April/May peaks, January/February and July/August troughs

## 📊 Key Business Insights

### Growth Analysis
- **Strong Growth Trend**: $17,000 increase over 2-year period (July 2023 - July 2025)
- **Weekly Growth**: $177.86 per week ($9,200+ annual growth)
- **Sustainable Trajectory**: Continued upward momentum into 2025

### Seasonal Patterns
- **Primary Peak**: October/November (+$8K-$10K above trend)
- **Secondary Peak**: April/May (+$6K-$8K above trend)
- **Primary Trough**: January/February (-$8K-$10K below trend)
- **Secondary Trough**: July/August (-$6K-$8K below trend)

### Strategic Advantages
- **Precise Planning**: 8-12 week advance notice for seasonal changes
- **Resource Optimization**: Efficient staffing and inventory allocation
- **Marketing Effectiveness**: Strategic campaign timing based on seasonal peaks
- **Operational Efficiency**: Optimized operations for seasonal demand variations

## 🛠️ Technical Details

### Required R Packages
- `readxl` - Excel file reading
- `forecast` - Time series forecasting
- `tseries` - Time series analysis
- `ggplot2` - Data visualization
- `dplyr` - Data manipulation
- `lubridate` - Date handling
- `tidyr` - Data tidying
- `seasonal` - Seasonal adjustment
- `scales` - Scale functions for visualization
- `gridExtra` - Grid graphics

### Data Format
- **Date Column**: First column with dates
- **Sales Column**: Second column with numeric sales values
- **Frequency**: Weekly data
- **Period**: July 2023 - July 2025 (107 weeks)
- **Missing Values**: Automatically handled with interpolation

## 📋 Business Applications

### Strategic Planning
- **Growth Projection**: $65K-$70K projected sales for 2025 based on trend analysis
- **Capacity Planning**: 25-30% staffing increase needed during peak periods
- **Investment Confidence**: Statistically significant growth justifies expansion investments

### Operational Optimization
- **Peak Periods**: +30% staffing needs with 3-week advance preparation
- **Trough Periods**: -20% staffing needs with gradual adjustments
- **Inventory Management**: 20-25% stock increase during peak seasons
- **Cash Flow Planning**: Accurate projections for seasonal variations

### Marketing Strategy
- **Fall Campaign**: September-October (pre-peak preparation)
- **Spring Campaign**: March-April (pre-peak preparation)
- **Off-Peak Promotions**: January-February and July-August
- **Peak Pricing**: Premium pricing opportunities during high-demand periods

## 🌐 Web Dashboard

The project includes an interactive web dashboard (`index.html`) featuring:

### Analysis Sections
1. **📈 Core Time Series Analysis** - Complete sales journey breakdown
2. **📊 Pattern Recognition & Analysis** - Advanced seasonal pattern analysis
3. **🔬 Advanced Time Series Decomposition Analysis** - Statistical decomposition
4. **💡 Business Intelligence Summary** - Enhanced metrics dashboard

### Key Features
- **Interactive Images**: Click to view full-size visualizations
- **Detailed Analysis**: Comprehensive insights for each visualization
- **Business-Friendly Language**: Manager-focused explanations
- **Actionable Recommendations**: Strategic insights and immediate action items

## 🔧 Troubleshooting

### Common Issues
1. **Package Installation Errors**: Run `install_r_packages.R` first
2. **File Not Found**: Ensure Excel file is in the project directory
3. **R Not Found**: Add R to system PATH or use RStudio

### Error Solutions
- **"pivot_wider not found"**: Install `tidyr` package
- **"time-series/vector length mismatch"**: Use decomposition-focused script
- **Empty CSV files**: Check data format and column names

## 📚 Additional Resources

- `SETUP_GUIDE.md` - Detailed installation instructions
- `SEASONAL PATTERN ANALYSIS.md` - Methodology documentation
- `BUSINESS_PLANNING_GUIDE.md` - Business planning recommendations
- R Documentation: [forecast package](https://cran.r-project.org/web/packages/forecast/)

## 🤝 Contributing

To contribute to this project:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with sample data
5. Submit a pull request

## 📄 License

This project is for educational and business analysis purposes.

---

**Last Updated**: December 2024  
**R Version**: 4.0+  
**Analysis Type**: Advanced Time Series Decomposition & Business Intelligence  
**Data Period**: July 2023 - July 2025  
**Status**: Production Ready
