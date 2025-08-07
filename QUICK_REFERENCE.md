# Quick Reference Guide

## 🚀 Getting Started (5 Minutes)

### 1. Install R and RStudio
- Download R: https://cran.r-project.org/
- Download RStudio: https://posit.co/download/rstudio-desktop/

### 2. Run the Analysis
```r
# In RStudio, open and run:
source("install_r_packages.R")
source("time_series_decomposition_focused.R")
```

### 3. Get Business Intelligence
```r
# For peak week analysis:
source("seasonal_peak_analysis.R")
```

## 📊 What You'll Get

### Core Analysis
- **12-week sales forecast** with confidence intervals
- **Best model** (AIC: 1977.718) using decomposition + ARIMA
- **Model diagnostics** and validation

### Business Intelligence
- **Peak weeks** for inventory and staffing planning
- **Monthly preparation guide** with timelines
- **Professional visualizations** for presentations

## 🎯 Key Business Insights

### Top Peak Weeks
| Week | Average Sales | Preparation Start |
|------|---------------|-------------------|
| 19   | $60,281       | 3 weeks before    |
| 9    | $59,710       | 3 weeks before    |
| 10   | $58,547       | 3 weeks before    |

### Seasonal Patterns
- **Peak Months**: March, April, May (Spring)
- **Peak Quarters**: Q1, Q2 (January-June)
- **Preparation**: Begin 3 weeks before peak weeks

## 📁 File Quick Reference

### Essential Scripts
- `time_series_decomposition_focused.R` - **Best forecasting** (recommended)
- `seasonal_peak_analysis.R` - **Business intelligence**
- `improved_visualizations.R` - **Professional charts**

### Key Outputs
- `sales_forecast.csv` - **12-week forecasts**
- `peak_weeks_calendar.csv` - **Peak week planning**
- `monthly_preparation_guide.csv` - **Monthly preparation**

### Visualizations
- `02_sales_heatmap_improved.png` - **Sales performance heatmap**
- `03_peak_weeks_timeline_enhanced.png` - **Peak weeks timeline**
- `08_peak_weeks_calendar.png` - **Professional calendar**

## ⚡ Quick Commands

### Windows Users
```bash
# Double-click to run
run_improved_analysis.bat
```

### RStudio Users
```r
# Install packages (first time only)
source("install_r_packages.R")

# Run best analysis
source("time_series_decomposition_focused.R")

# Get business intelligence
source("seasonal_peak_analysis.R")

# Create professional charts
source("improved_visualizations.R")
```

### Command Line Users
```bash
# Windows PowerShell
Rscript time_series_decomposition_focused.R
Rscript seasonal_peak_analysis.R
```

## 🔧 Common Issues & Solutions

### "Package not found"
```r
source("install_r_packages.R")
```

### "File not found"
```r
# Check working directory
getwd()
# Should show: "C:/Users/allen/Documents/GitHub/upside-timeseries"
```

### "R not found"
- Install R from https://cran.r-project.org/
- Add R to system PATH during installation

## 📈 Business Applications

### Inventory Management
- **Stock up** 3 weeks before peak weeks
- **Monitor** weeks 19, 9, 10 for highest demand
- **Plan** for 20% increase during peak periods

### Staffing Decisions
- **Hire** 6 weeks before peak periods
- **Train** 2 weeks before peak weeks
- **Schedule** extra hours during peak weeks

### Marketing Strategy
- **Launch campaigns** 3 weeks before peak weeks
- **Focus** on March-May for highest impact
- **Budget** 25% more for peak months

## 📋 Action Items Checklist

### Before Peak Week
- [ ] **4 weeks**: Start inventory planning
- [ ] **3 weeks**: Launch marketing campaigns
- [ ] **2 weeks**: Schedule additional staff
- [ ] **1 week**: Final inventory check

### During Peak Week
- [ ] Monitor performance closely
- [ ] Adjust staffing as needed
- [ ] Track inventory consumption

### After Peak Week
- [ ] Analyze actual vs. predicted performance
- [ ] Update forecasts with new data
- [ ] Plan for next peak period

## 🎨 Customization Quick Tips

### Change Forecast Period
```r
# In any script, find and change:
forecast_periods <- 12  # Change to desired weeks
```

### Adjust Peak Sensitivity
```r
# In peak analysis scripts:
peak_threshold <- overall_mean + (1.5 * overall_sd)  # More conservative
peak_threshold <- overall_mean + (0.5 * overall_sd)  # More aggressive
```

### Modify Chart Resolution
```r
# In visualization scripts:
png("output.png", width = 1200, height = 800, res = 150)
```

## 📞 Support & Resources

### Documentation
- `README.md` - Complete project overview
- `SETUP_GUIDE.md` - Detailed installation instructions
- `SCRIPT_DOCUMENTATION.md` - Script-by-script documentation
- `SEASONAL PATTERN ANALYSIS.md` - Methodology details

### External Resources
- R Documentation: https://cran.r-project.org/manuals.html
- Forecast Package: https://cran.r-project.org/web/packages/forecast/
- RStudio Help: Built-in help system

### Troubleshooting
1. Check `README.md` for common solutions
2. Verify R and package installation
3. Ensure correct working directory
4. Check file permissions and paths

---

**Need Help?** Check the full documentation in `README.md` and `SETUP_GUIDE.md`

**Last Updated**: January 2025  
**Version**: 1.0  
**Status**: Production Ready 