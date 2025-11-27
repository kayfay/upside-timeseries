# Export Weekly Sales Data as JSON for Dashboard Week Analyzer
# This script loads the weekly sales data and exports it as JSON
# for use in the JavaScript-based Week Analyzer feature

library(dplyr)
library(jsonlite)

# Helper function to safely handle errors
safe <- function(expr, default = NULL) {
  tryCatch(expr, error = function(e) {
    message(sprintf("Error: %s", e$message))
    return(default)
  })
}

# Infer weekly time series from a data frame
infer_weekly_ts <- function(df) {
  if (is.null(df) || nrow(df) < 8) return(NULL)
  
  # Try to find date column
  date_cols <- c("date", "Date", "DATE", "week", "Week", "WEEK", "period", "Period")
  date_col <- NULL
  for (col in date_cols) {
    if (col %in% names(df)) {
      date_col <- col
      break
    }
  }
  
  if (is.null(date_col)) {
    # Try first column if it looks like dates
    first_col <- names(df)[1]
    test_date <- safe(as.Date(df[[1]][1]), default = NULL)
    if (!is.null(test_date)) {
      date_col <- first_col
    }
  }
  
  if (is.null(date_col)) return(NULL)
  
  # Try to find value column
  value_cols <- c("value", "Value", "VALUE", "sales", "Sales", "SALES", 
                  "revenue", "Revenue", "REVENUE", "amount", "Amount", "AMOUNT")
  value_col <- NULL
  for (col in value_cols) {
    if (col %in% names(df)) {
      value_col <- col
      break
    }
  }
  
  if (is.null(value_col)) {
    # Try numeric columns
    numeric_cols <- sapply(df, is.numeric)
    if (sum(numeric_cols) > 0) {
      value_col <- names(df)[which(numeric_cols)[1]]
    }
  }
  
  if (is.null(value_col)) return(NULL)
  
  # Convert dates
  dates <- safe(as.Date(df[[date_col]]), default = NULL)
  if (is.null(dates)) {
    dates <- safe(lubridate::parse_date_time(df[[date_col]], orders = c("ymd", "mdy", "dmy")), default = NULL)
  }
  
  if (is.null(dates) || sum(!is.na(dates)) < 8) return(NULL)
  
  # Create output
  out <- data.frame(
    date = dates,
    value = as.numeric(df[[value_col]])
  ) %>%
    dplyr::filter(!is.na(date), !is.na(value)) %>%
    dplyr::arrange(date)
  
  if (nrow(out) < 8) return(NULL)
  
  return(out)
}

# Load sales data
load_sales_data <- function() {
  # Env override
  op_file <- Sys.getenv("OP_FILE", unset = NA_character_)
  op_sheet <- Sys.getenv("OP_SHEET", unset = NA_character_)
  if (!is.na(op_file) && nzchar(op_file) && file.exists(op_file)) {
    message(sprintf("Reading OP_FILE: %s", op_file))
    ext <- tolower(tools::file_ext(op_file))
    if (ext %in% c("xlsx","xls","xlsm")) {
      if (!requireNamespace("readxl", quietly = TRUE)) {
        stop("readxl package required for Excel files")
      }
      if (!is.na(op_sheet) && nzchar(op_sheet)) {
        df <- safe(readxl::read_excel(op_file, sheet = op_sheet), default = NULL)
        out <- safe(infer_weekly_ts(df), default = NULL)
        if (!is.null(out) && nrow(out) >= 8) return(out)
      }
      sheets <- safe(readxl::excel_sheets(op_file), default = NULL)
      if (!is.null(sheets)) {
        for (s in sheets) {
          df <- safe(readxl::read_excel(op_file, sheet = s), default = NULL)
          out <- safe(infer_weekly_ts(df), default = NULL)
          if (!is.null(out) && nrow(out) >= 8) return(out)
        }
      }
      df <- safe(readxl::read_excel(op_file), default = NULL)
      out <- safe(infer_weekly_ts(df), default = NULL)
      if (!is.null(out) && nrow(out) >= 8) return(out)
    } else if (ext %in% c("csv","txt")) {
      if (!requireNamespace("readr", quietly = TRUE)) {
        stop("readr package required for CSV files")
      }
      df <- safe(readr::read_csv(op_file, show_col_types = FALSE), default = NULL)
      out <- safe(infer_weekly_ts(df), default = NULL)
      if (!is.null(out) && nrow(out) >= 8) return(out)
    }
  }

  # Try common file names
  for (path in c("Copy of Weekly Sales 5_29_23-5_25.xlsx","weekly_sales.xlsx","sales.xlsx","weekly_sales.csv","sales.csv")) {
    if (file.exists(path)) {
      if (requireNamespace("readxl", quietly = TRUE) && grepl("\\.xlsx?$", path, ignore.case = TRUE)) {
        sheets <- safe(readxl::excel_sheets(path), default = NULL)
        if (!is.null(sheets)) {
          for (s in sheets) {
            df <- safe(readxl::read_excel(path, sheet = s), default = NULL)
            out <- safe(infer_weekly_ts(df), default = NULL)
            if (!is.null(out) && nrow(out) >= 8) return(out)
          }
        }
        df <- safe(readxl::read_excel(path), default = NULL)
        out <- safe(infer_weekly_ts(df), default = NULL)
        if (!is.null(out) && nrow(out) >= 8) return(out)
      } else if (requireNamespace("readr", quietly = TRUE) && grepl("\\.csv$", path, ignore.case = TRUE)) {
        df <- safe(readr::read_csv(path, show_col_types = FALSE), default = NULL)
        out <- safe(infer_weekly_ts(df), default = NULL)
        if (!is.null(out) && nrow(out) >= 8) return(out)
      }
    }
  }
  
  stop("No usable weekly time series found. Set OP_FILE to your file path and optionally OP_SHEET, OP_DATE_COL, OP_VALUE_COL.")
}

# Load the data
message("Loading sales data...")
sales_weekly <- load_sales_data()

if (is.null(sales_weekly) || nrow(sales_weekly) < 8) {
  stop("Failed to load sufficient data")
}

message(sprintf("Successfully loaded %d weeks of data", nrow(sales_weekly)))

# Ensure dates are in proper format
sales_weekly$date <- as.Date(sales_weekly$date)

# Sort by date
sales_weekly <- sales_weekly %>%
  dplyr::arrange(date) %>%
  dplyr::filter(!is.na(date), !is.na(value))

# Calculate additional statistics for the full dataset
full_stats <- list(
  mean = mean(sales_weekly$value, na.rm = TRUE),
  median = median(sales_weekly$value, na.rm = TRUE),
  sd = sd(sales_weekly$value, na.rm = TRUE),
  min = min(sales_weekly$value, na.rm = TRUE),
  max = max(sales_weekly$value, na.rm = TRUE),
  q25 = quantile(sales_weekly$value, 0.25, na.rm = TRUE),
  q75 = quantile(sales_weekly$value, 0.75, na.rm = TRUE),
  start_date = min(sales_weekly$date),
  end_date = max(sales_weekly$date),
  total_weeks = nrow(sales_weekly)
)

# Create JSON output
output <- list(
  data = sales_weekly,
  statistics = full_stats,
  metadata = list(
    export_date = Sys.Date(),
    export_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    version = "1.0"
  )
)

# Write JSON file
json_output <- toJSON(output, pretty = TRUE, auto_unbox = TRUE, date_format = "iso")
write(json_output, "weekly_sales_data.json")

message(sprintf("Successfully exported %d weeks of data to weekly_sales_data.json", nrow(sales_weekly)))
message(sprintf("Date range: %s to %s", min(sales_weekly$date), max(sales_weekly$date)))
message(sprintf("Average weekly sales: $%.2f", full_stats$mean))
message(sprintf("Standard deviation: $%.2f", full_stats$sd))


