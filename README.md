# Upside Timeseries Analysis 📈

A robust, production-grade R pipeline for analyzing retail sales time series data. This project automates the workflow from data ingestion to scientific analysis and editorial-style business reporting.

## 🚀 Features

- **Automated Data Pipeline**: Intelligent inference of weekly time series from raw Excel data (`R/data.R`).
- **Advanced Modeling**: STL decomposition, ARIMA forecasting, and structural change point detection (`R/analysis.R`).
- **Data Journalism**: "FiveThirtyEight"-style visualizations and dashboards (`R/viz.R`, `R/reporting.R`).
- **Modular Architecture**: Clean separation of concerns (Data, Logic, Viz) for maintainability.

## 📂 Project Structure

```
upside-timeseries/
├── R/                      # Core Modules
│   ├── data.R              # Data loading & cleaning
│   ├── analysis.R          # Statistical modeling (STL, ARIMA)
│   ├── viz.R               # Scientific plotting & themes
│   ├── reporting.R         # Business dashboard generation
│   └── utils.R             # Helper functions
├── create_scientific_analysis_fixed.R  # Main orchestration script
├── create_enhanced_business_summary.R  # Business report driver
└── tests/                  # Unit tests
```

## 🛠️ Usage

### 1. Run the Full Scientific Pipeline
Generates detailed diagnostics, time series decomposition, and a markdown report.

```r
source("create_scientific_analysis_fixed.R")
```

**Outputs:**
- `09_tldr_science_dashboard.png`
- `13_forecast_sarima.png`
- `SCIENTIFIC_ANALYSIS_REPORT.md`

### 2. Run the Business Summary
Generates a high-level executive dashboard.

```r
source("create_enhanced_business_summary.R")
```

**Output:**
- `07_enhanced_business_insights_summary.png`

## 📊 Methodology
The pipeline applies a rigorous statistical approach:
1.  **Imputation**: Fills missing weeks and values using LOCF/NOCB.
2.  **STL Decomposition**: Separates Trend, Seasonality, and Remainder.
3.  **Anomaly Detection**: Uses IQR on residuals to find outliers.
4.  **Forecasting**: Auto-ARIMA with seasonality support.

## 🤝 Contributing
Please ensure all new logic is placed in the appropriate `R/` module. Run tests before submitting.
